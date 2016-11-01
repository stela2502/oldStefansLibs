#! /usr/bin/perl -w

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

=head1 get_binding_features_relative_to_gbFeatures.pl

A tool originally used to select the amount of TF-binding sites downstream of all genes.

To get further help use 'get_binding_features_relative_to_gbFeatures.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::flexible_data_structures::data_table;
my $VERSION = "1.1.0";

my (
	$help,                    $debug,
	$organism,                $fixed_gbFeatureTag,
	$fixed_gbFeature_name,    $variable_gbFeatureTag,
	$variable_gbFeature_name, $downstream,
	$upstream,                $outfile
);

Getopt::Long::GetOptions(
	"-organism=s"                => \$organism,
	"-fixed_gbFeature_tag=s"     => \$fixed_gbFeatureTag,
	"-fixed_gbFeature_name=s"    => \$fixed_gbFeature_name,
	"-variable_gbFeature_tag=s"  => \$variable_gbFeatureTag,
	"-variable_gbFeature_name=s" => \$variable_gbFeature_name,
	"-downstream_distance=s"     => \$downstream,
	"-upstream_distance=s"       => \$upstream,
	"-outfile=s"                 => \$outfile,
	"-help"                      => \$help,
	"-debug"                     => \$debug
);

if ($help) {
	print helpString();
	exit;
}

if ( !defined $fixed_gbFeatureTag ) {
	print helpString("we need the fixed_gbFeature_tag");
	exit;
}
if ( !defined $fixed_gbFeature_name ) {
	warn
"we will analyze all features with the tag $fixed_gbFeatureTag - no further restriction!\n";
}

if ( !defined $variable_gbFeatureTag ) {
	print helpString("we need the variable_gbFeatureTag");
	exit;
}
if ( !defined $variable_gbFeature_name ) {
	warn
"we will analyze all dependant features with the tag $variable_gbFeatureTag - no further selection!\n";
}
if ( !defined $downstream ) {
	print helpString("we need the downstream_distance");
	exit;
}
if ( !defined $upstream ) {
	print helpString("we need the upstream_distance");
	exit;
}

my (
	$database, $fixed_featureList, $result_str,  $sql_gbFile_id,
	$sth,      $max_gbFile_id,     $data,        $VAR_DATASETS,
	$var_data, $gbFeature_f,       $gbFeature_v, $one_result,
	$results,  $data_table, $temp_dataset, $temp
);

## get the genome DB interface...
$database =
  genomeDB->new( undef, $debug )->GetDatabaseInterface_for_Organism($organism);
unless ( ref($database) eq "gbFeaturesTable" ) {
	warn helpString(
"we did not get a genome interface using the organism string '$organism' ("
		  . ref($database)
		  . ")\n" );
	exit;
}

$data_table = data_table->new();

$sql_gbFile_id = $database->create_SQL_statement(
	{
		'search_columns' => ['chromosomesTable.id'],
		'order_by'       => [ [ 'my_value', '-', 'chromosomesTable.id' ] ],
		'limit'          => 'limit 1'
	}
);
$sql_gbFile_id =~ s/\?//;

$sth = $database->{'dbh'}->prepare($sql_gbFile_id);
unless ( $sth->execute() ) {
	Carp::confess( "We have not got a result for query '$sql_gbFile_id;'\n"
		  . $database->{'dbh'}->errstr()
		  . "\n" );
}
($max_gbFile_id) = $sth->fetchrow_array();

print "we got $max_gbFile_id gbFiles\n";
my @ready = ( 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9 );

for ( my $gbFile_id = 1 ; $gbFile_id <= $max_gbFile_id ; $gbFile_id++ ) {
	if ( $gbFile_id / $max_gbFile_id > $ready[0] ) {
		print $ready[0] * 100
		  . "% of the gbFiles in the database have been processed\n";
		shift(@ready);
	}
	if ( defined $fixed_gbFeature_name ) {
		$data = $database->getArray_of_Array_for_search(
			{
				'search_columns' => ['gbFeaturesTable.gbString'],
				'where'          => [
					[ 'gbFeaturesTable.gbFile_id', '=', 'my_value' ],
					[ 'gbFeaturesTable.tag',       '=', 'my_value' ],
					[ 'gbFeaturesTable.name',      '=', 'my_value' ]
				],
				'order_by' => ['gbFeaturesTable.start'],
			},
			$gbFile_id,
			$fixed_gbFeatureTag,
			$fixed_gbFeature_name
		);
	}
	else {
		$data = $database->getArray_of_Array_for_search(
			{
				'search_columns' => ['gbFeaturesTable.gbString'],
				'where'          => [
					[ 'gbFeaturesTable.gbFile_id', '=', 'my_value' ],
					[ 'gbFeaturesTable.tag',       '=', 'my_value' ]
				],
				'order_by' => ['gbFeaturesTable.start'],
			},
			$gbFile_id,
			$fixed_gbFeatureTag
		);
	}
	print "we have got "
	  . scalar(@$data)
	  . " fixed gbFeatures for gbFile $gbFile_id\n";
	unless ( ref( @$data[0] ) eq "ARRAY" ) {
		warn
"we did not get any values for the search $database->{'complex_search'}\n";
		next;
	}
	;    ## if we do not find what we want we do not need to do anything!
	if ( defined $variable_gbFeature_name ) {
		$var_data = $database->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ 'gbFeaturesTable.start', 'gbFeaturesTable.gbString' ],
				'where' => [
					[ 'gbFeaturesTable.gbFile_id', '=', 'my_value' ],
					[ 'gbFeaturesTable.tag',       '=', 'my_value' ],
					[ 'gbFeaturesTable.name',      '=', 'my_value' ]
				],
				'order_by' => ['gbFeaturesTable.start'],
			},
			$gbFile_id,
			$variable_gbFeatureTag,
			$variable_gbFeature_name
		);
	}
	else {
		$var_data = $database->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ 'gbFeaturesTable.start', 'gbFeaturesTable.gbString' ],
				'where' => [
					[ 'gbFeaturesTable.gbFile_id', '=', 'my_value' ],
					[ 'gbFeaturesTable.tag',       '=', 'my_value' ]
				],
				'order_by' => ['gbFeaturesTable.start'],
			},
			$gbFile_id,
			$variable_gbFeatureTag
		);
	}
	print "we have got "
	  . scalar(@$var_data)
	  . " variable gbFeatures for gbFile $gbFile_id\n";
	unless ( scalar(@$var_data) >0 ){
		print "we did not get a search result for the search '\n".$database->{'complex_search'}.";'\n";
	}
	next unless ( ref( @$var_data[0] ) eq "ARRAY" );
	$VAR_DATASETS = undef;
	foreach my $var (@$var_data) {
		my $gbF = gbFeature->new( 'nix', '1..2' );
		$gbF->parseFromString( @$var[1] );
		$VAR_DATASETS->{ @$var[0] } = $gbF;
		## now we need to identfy all possible headers for the results:
		## Gene Symbo
		my @header = (
			'Gene Symbol',
			'start on its gbFile',
			'orientation of expression',
			'amount of close by variable_gbFeatures',
			'list of distances to the start of the gene'
		);
		## and possibly some other headers (if we have added some mean values to a region)
		## NO that will be added to the complex column!
#		foreach my $tag ( sort keys %{ $gbF->INFORMATION() } ) {
#			push( @header, $tag )
#			  if ( $tag =~ m/_mean$/ || $tag =~ m/_n$/ || $tag =~ m/_std$/ );
#		}
		foreach my $tag (@header) {
			$data_table->Add_2_Header($tag);
		}
		$data_table->createIndex('Gene Symbol');
	}
	foreach my $fixed (@$data) {
		$gbFeature_f = undef;
		$gbFeature_f = gbFeature->new( 'nix', '1..2' );
		$gbFeature_f->parseFromString( @$fixed[0] );
		if ( defined $gbFeature_f->IsComplement() ) {
#print " the gene ".$gbFeature_f->Name()." is in antisene orientation (".$gbFeature_f->IsComplement().")\n";
			$one_result = &identify_features_in_region(
				$gbFeature_f->ExprStart() - $downstream,
				$gbFeature_f->ExprStart() + $upstream
			);
		}
		else {
			$one_result = &identify_features_in_region(
				$gbFeature_f->ExprStart() - $upstream,
				$gbFeature_f->ExprStart() + $downstream
			);
		}
		$data_table->Add_Dataset(
			{
				'Gene Symbol'               => $gbFeature_f->Name(),
				'start on its gbFile'       => $gbFeature_f->ExprStart(),
				'orientation of expression' => $gbFeature_f->IsComplement(),

			}
		  )
		  unless (
			scalar(
				$data_table->getLines_4_columnName_and_Entry(
					'Gene Symbol', $gbFeature_f->Name()
				)
			) > 0
		  );
		$temp_dataset = {};
		$temp_dataset ->{'list of distances to the start of the gene'} = '';
		foreach $gbFeature_v (@$one_result) {
			$temp = $gbFeature_v->Start() - $gbFeature_f->ExprStart();
			if ( $gbFeature_v->IsComplement eq "complement"){
				$temp = - $temp;
			}
			$temp_dataset ->{'list of distances to the start of the gene'} .= "$temp bp..";
			foreach my $tag (sort keys %{$gbFeature_v->INFORMATION()}){
				if ( $tag =~ m/_mean$/ || $tag =~ m/_n$/ || $tag =~ m/_std$/ ){
					$temp_dataset ->{'list of distances to the start of the gene'} .= 
					 "$tag=".@{$gbFeature_v->AddInfo($tag)}[0]."..";
				}
			}
			chop($temp_dataset ->{'list of distances to the start of the gene'});
			chop($temp_dataset ->{'list of distances to the start of the gene'});
			$temp_dataset ->{'list of distances to the start of the gene'} .= ";";
		}
		unless ( scalar (@$one_result) > 0){
			print "we do not have "
		}
		chop($temp_dataset ->{'list of distances to the start of the gene'});
	
		$data_table -> Add_dataset_for_entry_at_index  (
			$temp_dataset, $gbFeature_f->Name(), 'Gene Symbol'
		);
	}
	last if ( $debug && $gbFile_id == 5 );
}

$data_table->print2file ( $outfile );

#&printResults($results);

sub printResults {
	my ($results) = @_;
	open( OUT, ">$outfile.log" ) or die "could not create outfile '$outfile'\n$!\n";
	print OUT "INFO\nvar_name\tvar_value\n";
	print OUT "organism\t$organism\n";
	print OUT "fixed_gbFeature_tag\t$fixed_gbFeatureTag\n";
	print OUT "fixed_gbFeature_name\t$fixed_gbFeature_name\n";
	print OUT "variable_gbFeature_tag\t$variable_gbFeatureTag\n";
	print OUT "variable_gbFeature_name\t$variable_gbFeature_name\n";
	print OUT "downstream_distance\t$downstream\n";
	print OUT "upstream_distance\t$upstream\n";
	print OUT "outfile\t$outfile\n";
	print OUT "resulting fixed_gbFeatures\t" . scalar( keys %$results ) . "\n";
	print OUT "\n";
	close ( OUT );
	return;
#	print OUT
#"Gene Symbol\tstart on its gbFile\tamount of close by variable_gbFeatures\tlist of distances to the start of the gene\n";
#
#	foreach my $Gene_Symbol ( sort keys %$results ) {
#		print OUT "$Gene_Symbol\t$results->{$Gene_Symbol}->{'position'}";
#		unless ( defined $results->{$Gene_Symbol}->{'complement'} ) {
#			foreach $gbFeature_v ( @{ $results->{$Gene_Symbol}->{'data'} } ) {
#				print OUT "\t"
#				  . $gbFeature_v->Name() . " ("
#				  . ( $gbFeature_v->Start() -
#					  $results->{$Gene_Symbol}->{'position'} )
#				  . ")";
#			}
#		}
#		else {
#			foreach $gbFeature_v ( @{ $results->{$Gene_Symbol}->{'data'} } ) {
#				print OUT "\t"
#				  . $gbFeature_v->Name() . " ("
#				  . ( $results->{$Gene_Symbol}->{'position'} -
#					  $gbFeature_v->Start() )
#				  . ")";
#			}
#		}
#		print OUT "\t";
#		foreach $gbFeature_v ( @{ $results->{$Gene_Symbol}->{'data'} } ) {
#			print OUT $gbFeature_v->getAsGB() . "; ";
#		}
#		print OUT "\n";
#	}
#	close(OUT);
#	print "results written to $outfile \n ";
}

sub identify_features_in_region {
	my ( $start, $end ) = @_;
	my @return;
	foreach my $pos ( sort { $a <=> $b } keys %$VAR_DATASETS ) {
		if ( $pos >= $start && $pos <= $end ) {
			push( @return, $VAR_DATASETS->{$pos} );
		}
		last if ( $pos >= $end );
	}
	return \@return;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = " " unless ( defined $errorMessage );
	return "
       $errorMessage command line switcches
       for get_binding_features_relative_to_gbFeatures . pl
	
	
	-organism             :the organism name as stored in the organism tables
	-fixed_gbFeature_tag  :the tag of the gbFeature where we want to analyze the
					       promoter region
	-fixed_gbFeature_name :the name of the gbFeature where we want to analyze the
					       promoter region 
	-variable_gbFeature_tag :the tag of the variable feature that will be searched
	                         for in the region relative to the start of the upper feature 
	-variable_gbFeature_name :the name of the variable feature 
	-downstream_distance  :the downstream distance to the fixed_gbFeature start in
					       the genome 
	-upstream_distance    :the upstrem distance to the fixed_gbFeature start in the
					       genome 
	-outfile              :the(optional) output file( if not set print to stdout ) 
	-help                 :print this help 
	-debug                :verbose output

";
}
