package KruskalWallisTest;

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
use base ('stat_test');
#@ISA = qw ( stat_test );

use strict;
use warnings;

sub new {

	my ($class, $R, $debug) = @_;

	my ($self);
	unless ( defined $R){
		$R = Statistics::R->new();
	}

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

	bless $self, $class if ( $class eq "KruskalWallisTest" );

	return $self;

}

sub getReport{
	my ( $self ) = @_;
	my ( $report);
	$report = "KruskalWallisTest object $self\n";
	$report .= "group 1 ($self->{groupLabel_1})\t".join( "\t", @{$self->{groupTags_1}})."\n";
	$report .= "group 2 ($self->{groupLabel_2})\t".join( "\t", @{$self->{groupTags_2}})."\n";
	$report .= "performed tests\t$self->{statTest}\n";
	
	return $report;
}

sub AddGroupingHash {
	my ( $self, $hash ) = @_;

	#hash structure: { tag => <ref to array of labels> };
	my (@groupTags, $error);
	
	unless ( defined %$hash ) {
		die "KruskalWallisTest -> AddGroupingHash got no grouping hash!!\n";
		return 0;
	}
	@groupTags = ( keys %$hash );
	die
"A KruskalWallisTest test should be used for more than two groups - not (@groupTags) !!\n"
	  if ( @groupTags < 2 );
	## all data has to come from the test line!
	## but we have to define the groups!!!
	my (@groupEntries);
	$self->{'groupLabels'} = \@groupEntries;
	$self->{'groupTags'}   = \@groupTags;
	
	$error = 0;
	foreach my $tag (@groupTags) {
		warn
		  "we do not have a group of matching data entries in $hash->{$tag}\n"
		  unless ( ref( $hash->{$tag} ) eq "ARRAY" );
		push( @groupEntries, $hash->{$tag} );
		my $temp = $hash->{$tag};
		$error = 1 if ( @$temp == 0);
		print
"add to \$self->{groupLabels} the array ref $temp to the array ( @$temp)\n" if ( $self->{'debug'});
	}
	if (@groupTags == 0 || $error ){
		root::print_hashEntries( $hash, 5, "the grouping hash that lead to the following error:");
		die "we encountered a serious problem in $self AddGroupingHash (no group labels)\n";
	}
	return 1;
}

sub getTest_result {
	my ( $self, $line, $statTests_per_TableLine ) = @_;
	my @arrayList = $self->getListOfArrayRefs4tableLine($line);
	$self->TestreinitR($statTests_per_TableLine);
	my @info =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'infoPos'} );
	my $testRes = $self->_kruskal_test(@arrayList);
	return undef if ( $self->error );
	return
	  join( "\t", @info ) . "\t"
	  . $testRes . "\t"
	  . $self->getTableString4ArrayOfArrayRefs(@arrayList) . "\n";
}

sub processTableHeader {
	my ( $self, $line, $infoPos ) = @_;

	my ( $entries, @positions );
	$entries = $self->{'groupLabels'};
	$self->{'groupPositions'} = \@positions;

	foreach my $arrayRef (@$entries) {
		if ( $self->{'debug'}){
		print "If we die here the array ref $arrayRef contains no data\n";
		print
		  "We try to select all columns that match the titles (@$arrayRef)\n";
		}
		push(
			@positions,
			$self->{tableHandling}->identify_columns_of_interest_bySearchHash(
				$line, $self->{tableHandling}->createSearchHash($arrayRef)
			)
		);

	}
	$self->{'infoPos'} = $infoPos;

	my @info =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $line, $self->{'infoPos'} );
	root::print_hashEntries( $self, 6,
		"object $self after processTableHeader" ) if ( $self->{debug});
	return
	  join( "\t", @info ) . "\t"
	  . $self->_kruskal_test() . "\t"
	  . $self->getTableString4ArrayOfArrayRefs(
		$self->getListOfArrayRefs4tableLine($line) )
	  . "\n";
}

sub getListOfArrayRefs4tableLine {
	my ( $self, $line ) = @_;
	## The arrays should contain the values of the columns stored in the arra of arrays $self->{'groupPositions'}!

	my $positions = $self->{'groupPositions'};
	Carp::confess(
"died in $self -> getListOfArrayRefs4tableLine as no groupPositions were defined \n")
	  unless ( defined @$positions );
	my @return;
	foreach my $positionArrayRef (@$positions) {
		my @temp =
		  $self->{tableHandling}
		  ->get_column_entries_4_columns( $line, $positionArrayRef );
		push( @return, \@temp );
	}
	return @return;
}

sub getTableString4ArrayOfArrayRefs {
	my ( $self, @array ) = @_;
	my ( $tagString, @tableLine, $arrayRef );
	$tagString = "group nr. ";
	for ( my $i = 0 ; $i < @array ; $i++ ) {
		$arrayRef = $array[$i];
		push( @tableLine, ( $tagString . $i. " (@{$self->{groupTags}}[$i])", @$arrayRef ) );
	}
	return join( "\t", @tableLine );
}

sub _kruskal_test {
	my ( $self, @groups ) = @_;
	## each value in the array @groups has to be a array ref to the a list
	## of values that should be used for the non parametric anova test calculated
	return "p-value\tchi-squared\tdegrees of freedom"
	  unless ( defined $groups[0] );
	my ( @temp, $result, $return );

	$self->forceRunningR();

	my $cmd =
	    $self->_createRlist_fromMultipleArrayRefs( "list", @groups ) . " \n"
	  . "result <- kruskal.test( list )\n"
	  . "print (result)\n";
	#print $cmd."\n";
	$self->{R}->send($cmd);

	unless ( $self->{R}->is_started() ){
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}

	$result = $self->{R}->read();
	$self->{lastR} = $return;
	#	print "result from the krustal.wallis test: \n$result\n";
	@temp = split( "\n", $result );
	$result = join( " ", @temp );
	
	$return->{'chi-squared'} = $1
	  if ( $result =~ m/chi-squared [=<] $self->{match2number}/ );
	$return->{'degrees of freedom'} = $1 if ( $result =~ m/df = (\d+)/ );
	$return->{'p-value'} = $1
	  if ( $result =~ m/p-value [=<] (\d?\.?\d+[eE]?-?\d*)/ );
	$self->{lastP} = $return->{'p-value'};
	return
	join ("\t", ($return->{'p-value'}, $return->{'chi-squared'}, $return->{'degrees of freedom'}));
}

1;
