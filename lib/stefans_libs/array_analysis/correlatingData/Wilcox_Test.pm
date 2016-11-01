package Wilcox_Test;

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
use base "stat_test" ;
use strict;

sub new {

	my ( $class, $R ) = @_;

	my ($self);
	unless ( defined $R ) {
		$R = Statistics::R->new();
	}

	$R->{'START_CMD'} = "$R->{R_BIN} --slave --vanilla --gui=X11";

	$self = {
		tableHandling => tableHandling->new(),
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0,
		match2number  => '(\d?\.?\d+)'
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );
	bless $self, $class if ( $class eq "Wilcox_Test" );

	return $self;

}

sub getReport {
	my ($self) = @_;
	my ($report);
	$report = "Wilcox_Test object $self\n";
	$report .= "group 1 ($self->{groupLabel_1})\t"
	  . join( "\t", @{ $self->{groupTags_1} } ) . "\n";
	$report .= "group 2 ($self->{groupLabel_2})\t"
	  . join( "\t", @{ $self->{groupTags_2} } ) . "\n";
	$report .= "performed tests\t$self->{statTest}\n";

	return $report;
}

sub AddGroupingHash {
	my ( $self, $hash ) = @_;

	my ( @groupTags, $temp );
	unless ( defined %$hash ) {
		die "Wilcox_Test -> AddGroupingHash got no grouping hash!!\n";
		return 0;
	}
	@groupTags = ( keys %$hash );
	die
"The only thing a wikcox test can do is compare two groups - not (@groupTags) !!\n"
	  if ( !@groupTags == 2 );
	## all data has to come from the test line!
	## but we have to define the groups!!!
	$self->{'groupTags_1'}  = $hash->{ $groupTags[0] };
	$self->{'groupLabel_1'} = $groupTags[0];
	$self->{'groupTags_2'}  = $hash->{ $groupTags[1] };
	$self->{'groupLabel_2'} = $groupTags[1];

	$temp = $self->{'groupTags_1'};
	unless ( defined @$temp[0] ) {
		root::print_hashEntries( $hash, 5, "the data set that made us die" );
		die "died, because group groupTags_1 had no entries\n";
	}
	$temp = $self->{'groupTags_2'};
	unless ( defined @$temp[0] ) {
		root::print_hashEntries( $hash, 5, "the data set that made us die" );
		die "died, because group groupTags_2 had no entries\n";
	}

	return 1;
}

sub getTest_result {
	my ( $self, $line, $statTests_per_TableLine ) = @_;
	unless ( defined $self->{'groupPositions_1'} ) {
		die
"The group positions are missing! use $self -> processTableHeader to add this data set!\n";
	}
	$self->TestreinitR($statTests_per_TableLine);
	my @data1 =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'groupPositions_1'} );
	my @data2 =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'groupPositions_2'} );
	my @info =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'infoPos'} );
	my ( @real_1, @real_2, @real_3);
	for ( my $i = 0; $i < @data1;$i ++ ){
		if ( $data1[$i] =~ m/\d/ && $data2[$i] =~ m/\d/ ){
			push ( @real_1, $data1[$i]);
			push ( @real_2, $data2[$i]);
			push ( @real_3, $info[$i]);
		}
	}
	return
	    join( "\t", @info ) . "\t"
	  . $self->_calculate_wilcox_statistics( \@real_1, \@real_2 ) . "\t"
	  . join( "\t",
		( $self->{'groupLabel_1'}, @data1, $self->{'groupLabel_2'}, @data2 ) )
	  . "\n";
}

sub SET_pairedTest {
	my ( $self, $boolean ) = @_;
	if ($boolean) {
		$self->{'__pairedTest'} = "paired = TRUE";
	}
	else {
		$self->{'__pairedTest'} = "paired = FALSE";
	}
	return $self->{'__pairedTest'};
}

sub pairedTest {
	my ( $self, $testOption ) = @_;
	if ( defined $testOption ) {
		if ( $testOption =~ m/=/ ) {
			$self->{'__pairedTest'} = $testOption;
		}
	}
	$self->{'__pairedTest'} = "paired = FALSE"
	  unless ( defined $self->{'__pairedTest'} );
	return $self->{'__pairedTest'};
}

sub _calculate_wilcox_statistics {
	my ( $self, $referenceData, $actualData ) = @_;

	return "p value\tw\tfold change" unless ( defined $referenceData );
	my $input = "referenceData = ('".join(", ",@$referenceData)."') ,actualData =('".join(", ",@$actualData ) ."')";
	$self->forceRunningR();
	my @string;
	my ( @x, @y);
	for ( my $i = 0; $i < @$referenceData;$i ++ ){
		if ( @$referenceData[$i] =~ m/\d/ && @$actualData[$i] =~ m/\d/){
		push ( @x , @$referenceData[$i]);
		push ( @y , @$actualData[$i]);
		}
	}
	
	@string = (
		"x<- c(",
		join( ',', @x ),
		")\ny<-c(",
		join( ',', @y ),
		")\nres <- wilcox.test( x, y, exact = 0, "
		  . $self->pairedTest() . ")\n",
		"print ( res )"
	);
	my $cmd = join( '', @string );
	#warn $cmd."\n";
	$self->{R}->send($cmd);
	unless ( $self->{R}->is_started() ) {
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	my $return = $self->{R}->read();
	
	##print "Wilcox_test calculate: \n$return\n";
	## remove the line breaks
	my @return = split( "\n", $return );
	$return = join( " ", @return );
	$self->{lastR} = $return;
	## select the interesting information from the R results
	my $p = $1 if ( $return =~ m/p-value [=<] (\d?\.?\d+e?-?\d*)/ );

	#$return =~ m/(p-value *[=<] *................)/;
	unless ( defined $p ) {
		$self->{'error'} = "_calculate_wilcox_statistics( $input ) :\n\twe did not get a result for the cmd \n$cmd\n";
		$self->{lastP} = undef;
		return undef;
	}
	my $w = $1 if ( $return =~ m/[VW] *= *([\d\.]+)/ );
	unless ( defined $w ) {
		Carp::confess(
			ref($self)
			  . "we could not match 'W *= *([\\d\\.]+)' to '$return'\n" );
	}
	my $rho = $1 if ( $return =~ m/rho *(-?[\d\.]+) *$/ );

	my ( $conf_int_low, $conf_int_high, $difference ) = ( $1, $2, $3 )
	  if ( $return =~
m/confidence interval: *(-?\d+\.?[e\d-]+) +(-?\d+\.?[e\d-]+).*in location *(-?\d+\.?[e\d-]+)/
	  );
	$self->{lastP} = $p;
	$rho = root->mean($referenceData);
	$rho = 1E-20 if ($rho == 0);
	$rho = root->mean($actualData) / $rho;
	
	$self->add_2_log ($cmd."\n"."p=$p;W=$w;rho=$rho\n" );
	return "$p\t$w\t$rho";
}

sub processTableHeader {
	my ( $self, $line, $infoPos ) = @_;

	$self->{'groupPositions_1'} =
	  $self->{tableHandling}->identify_columns_of_interest_bySearchHash( $line,
		$self->{tableHandling}->createSearchHash( $self->{'groupTags_1'} ) );
	$self->{'groupPositions_2'} =
	  $self->{tableHandling}->identify_columns_of_interest_bySearchHash( $line,
		$self->{tableHandling}->createSearchHash( $self->{'groupTags_2'} ) );
	$self->{'infoPos'} = $infoPos;

	my @data1 =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'groupPositions_1'} );
	my @data2 =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'groupPositions_2'} );
	my @info =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'infoPos'} );

	return
	    join( "\t", @info ) . "\t"
	  . $self->_calculate_wilcox_statistics() . "\t"
	  . join( "\t", ( "group1->", @data1, "group2->", @data2 ) ) . "\n";
}

1;
