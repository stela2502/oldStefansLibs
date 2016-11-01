package SpearmanTest;

#  Copyright (C) 2008 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

use stefans_libs::array_analysis::correlatingData::stat_test;
@ISA = qw ( stat_test );

use strict;

sub new {

	my ($class, $R) = @_;

	my ($self);
	
	unless ( defined $R){
		$R = Statistics::R->new();
	}

	$self = {
		tableHandling => tableHandling->new(),
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0,
		match2number  => '(\d?\.?\d+)',
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

	bless $self, $class if ( $class eq "SpearmanTest" );

	return $self;

}

sub AddGroupingHash {
	my ( $self, $hash ) = @_;
	die "SpearmanTest absolutely needs a hash to work\n"
	  unless ( defined %$hash );
	my ( $temp, @corelatingValues );

	## here we have the problem, that we could have ties!
	## for the first I will simply add the tied value several times into the data array....

	$self->{corelatingValues} = \@corelatingValues;
	my @tags;
	foreach my $value ( keys %$hash ) {
		$temp = $hash->{$value};
		foreach my $tag (@$temp) {
			next if ( ref($tag) eq "ARRAY" );
			push( @corelatingValues, $value );
			push( @tags,$tag );
		}
	}
	$self->{groupTags} = \@tags;

	return 1;
}

sub getReport{
	my ( $self ) = @_;
	my ( $report);
	$report = "SpearmanTest object $self\n";
	$report .= "TAGS\t".join( "\t", @{$self->{groupTags}})."\n";
	$report .= "correlating values\t".join( "\t", @{$self->{corelatingValues}})."\n";
	$report .= "performed tests\t$self->{statTest}\n";
	
	return $report;
}


sub getTest_result {
	my ( $self, $line, $statTests_per_TableLine ) = @_;

	unless ( defined $self->{'groupPositions'} ) {
		die
"The group positions are missing! use $self -> processTableHeader to add this data set!\n";
	}
	$self->TestreinitR($statTests_per_TableLine);
	
	#my $temp = $self->{'groupPositions'};
	#print "we try to get the values of the columns (@$temp) \nis there any crap??\n";
	
	my @data =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'groupPositions'} );
	  
	#print "\n And got the data ( ";
	#root::print_hashEntries(@data,2,"there is crap!");
	#print " )\nis there any crap??\n";
	
	my @info =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'infoPos'} );

	my $return =  join( "\t", @info ) . "\t"
	  . $self->_calculate_spearmanWeightFit_statistics(
		$self->{corelatingValues}, \@data )
	  . "\t"
	  . join( "\t", @data ) . "\n";
	#die "SprearmanResult(2):\n$return";
	return $return;
}

sub processTableHeader {
	my ( $self, $line, $infoPos ) = @_;

	#print "$self - > processTableHeader (\n\tarray line $line, \n\t info pos array @$infoPos\n)\n";

# group Position contain all column numbers in the array file, that can be evaluated using out correlation dataset
# but there may be values in our correlating data set, that are not part of the array data set!
	$self->{'groupPositions'} =
	  $self->{tableHandling}->identify_columns_of_interest_bySearchHash( $line,
		$self->{tableHandling}->createSearchHash( $self->{'groupTags'} ) );
	$self->{'infoPos'} = $infoPos;

	my @data =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'groupPositions'} );
	## @data contains all the possible colmun headers contained in the array file and part of our correlating data set!
	# $self->{corelatingValues}
	# $self->{groupTags}
	my @newCorelatingValues;
	my $old_tagArray = $self->{groupTags};

	for ( my $i = 0 ; $i < @data ; $i++ ) {
		## we have to select only those correlating values that are in the array data and that can be evaluated!
		for ( my $a = 0 ; $a < @$old_tagArray ; $a++ ) {
			if ( @$old_tagArray[$a] eq $data[$i] ) {
				push (@newCorelatingValues, $self->{corelatingValues}->[$a]);
				last;
			}
		}
	}
	$self->{corelatingValues} = \@newCorelatingValues;
	$self->{groupTags}        = \@data;

	my @info =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'infoPos'} );

	my $return =
	    join( "\t", @info ) . "\t"
	  . $self->_calculate_spearmanWeightFit_statistics() . "\t"
	  .
	  join( "\t", @data ) . "\n";
	$return .= "correlating data set\t";
	for ( my $i = 1 ; $i < @info ; $i++ ) {
		$return .= "\t";
	}
	$return .= "\t\t\t";
	my $temp = $self->{'corelatingValues'};
	$return .= join( "\t", ( @$temp, "\n" ) );

	return $return;
}

sub _calculate_spearmanWeightFit_statistics {
	my ( $self, $referenceData, $actualData ) = @_;

	unless ( defined $referenceData ){
		#warn "we have no refernece data!\n";
		return "p value\tS\trho" ;
	}
	my ( @x, @y );
	for ( my $i = 0; $i < @$referenceData;$i ++ ){
		next unless ( defined @$referenceData[$i]);
		next unless ( defined @$actualData[$i] );
		if ( @$referenceData[$i] =~ m/\d/ && @$actualData[$i] =~ m/\d/){
		push ( @x , @$referenceData[$i]);
		push ( @y , @$actualData[$i]);
		}
	}
	
	$self->forceRunningR();
	
	my @string;
	@string = (
		"x<- c(",
		join( ',', @x ),
		")\ny<-c(",
		join( ',', @y ),
		")\nres <- cor.test( x,y,method='spearman')\n",
		"print ( res )"
	);
	my $cmd = join( '', @string );
	#print "R command:\n$cmd\n";
	$self->{'last_cmd'} = $cmd;
	$self->{R}->send($cmd);
	
	unless ( $self->{R}->is_started() ){
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	
	my $return = $self->{R}->read();
	$self->{lastR} = $return;
	my @return = split( "\n", $return );
	$return = join( " ", @return );
	#2.2e-16 
	my $p   = $1 if ( $return =~ m/p-value [=<] (\d?\.?\d+e?-?\d*)/ );
	my $s   = $1 if ( $return =~ m/S *= *([\d\.]+)/ );
	my $rho = $1 if ( $return =~ m/rho *(-?\d?\.?\d+e?-?\d*) *$/ );
	$self->{lastP} = $p;
	#print "Spreaman result(NEW): $return \n";# unless  ( defined $p );
	#print "p: $p\tspearman: $s\trho: $rho\n";
	#die;
	$return .="\n\n".join( ", ", @$referenceData);
	$return .="\n\n".join( ", ", @$actualData );
	
	unless ( defined $p){
		warn "we could not get the P_value from \n$return";
		$p = '';
	}
	unless ( defined $s){
		warn "we could not get the s_value from \n$return";
		$s = '';
	}
	unless ( defined $rho){
		warn "we could not get the rho from \n$return";
		$rho = '';
	}
	$self->{lastR} = $rho;
	
	return "$p\t$s\t$rho";
}

1;
