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

=head1 extract_oligos_fromm_NimbleGene_GFF_file.pl

A script to search NimbleGene GFF oligo files and an oligo2DNA table file to identify the location 
of oligos in any genome. The oligo2DNA table hast to be genome specific.

To get further help use 'extract_oligos_fromm_NimbleGene_GFF_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo;

use stefans_libs::database::array_dataset;

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,                  $debug,          $database,
	$GFF_file,              $olgio2DNA_file, $outfile,
	$cutoff,                $organism_tag,   @array_datasets_groupA,
	@array_datasets_groupB, $genome_version, $array_identifier
);

Getopt::Long::GetOptions(
	"-GFF_file=s"                    => \$GFF_file,
	"-olgio2DNA_file=s"              => \$olgio2DNA_file,
	"-outfile=s"                     => \$outfile,
	"-cutoff=s"                      => \$cutoff,
	"-organism_tag=s"                => \$organism_tag,
	"-genome_version=s"              => \$genome_version,
	"-array_identifier=s"            => \$array_identifier,
	"-array_dataset_ids_groupA=s{,}" => \@array_datasets_groupA,
	"-array_dataset_ids_groupB=s{,}" => \@array_datasets_groupB,
	"-help"                          => \$help,
	"-debug"                         => \$debug,
	"-database=s"                    => \$database
);

my $error   = '';
my $warning = '';

unless ( defined $GFF_file ) {
	$error .= 'the cmd line switch -GFF_file is undefined!';
}
unless ( defined $olgio2DNA_file ) {
	$error .= 'the cmd line switch -olgio2DNA_file is undefined!';
}
unless ( defined $outfile ) {
	$error .= 'the cmd line switch -outfile is undefined!';
}
unless ( defined $cutoff ) {
	$error .= 'the cmd line switch -cutoff is undefined!';
}
unless ( defined $array_datasets_groupA[0] ) {
	$error .= 'the cmd line switch -array_dataset_ids_groupA is undefined!';
}
unless ( defined $array_datasets_groupB[0] ) {
	$warning .= 'the cmd line switch  array_dataset_ids_groupB is undefined!';
}

if ( $warning =~ m/\w/ ) {
	warn $warning . "But we can do without this information!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 
 This script is a dirty hack to get the results from the MeDip chip exeriments as fast as possible.
 Once the database supports the results of the Wilcox over two serach results,
 this script has to be updated to use only the database and not the nimblegene info files!!
 
 command line switches for extract_oligos_fromm_NimbleGene_GFF_file.pl

   -GFF_file       :the NimbleGene GFF file containing the oligo informations
   -olgio2DNA_file :the NimbleGene Signalmap genome info file
   -outfile        :the file where the results table should be stored
   -cutoff         :the cutoff to apply to the GFF values ( >= cutoff will be used)
   -array_identifier : the name of the nimblegene Array as it is stored in the database

   -array_dataset_ids_groupA : the array dataset ids that were used for the one group
   -array_dataset_ids_groupB : the array dataset ids, that were used for the second group
   
   -help           :print this help
   -debug          :verbose output

";
}

my (
	$gffFile,  $oligo_Data,      $oligoLocations,
	$genomeDB, $genomeInterface, $temp,
	$var,      $array,           @data
);

unless ( -f "$outfile.$cutoff.oligoIDs" ) {
	$gffFile = gffFile->new();

	$oligo_Data = $gffFile->GetData( $GFF_file, 'preserve_structure_new' );
	$temp = $var = 0;
	my @good_data;
	foreach $array (@$oligo_Data) {
		if ( @$array[5] >= $cutoff ) {
			push( @good_data, $array );
			$temp++;
		}
		else {
			$var++;
		}
	}
	open( OUT, ">$outfile.$cutoff.oligoIDs" )
	  or die "I coudl not create the temp file $outfile.oligoIDs\n";
	print OUT "#cutoff=$cutoff\n";
	print OUT "#passed=$var\n";
	print OUT "#rejected=$temp\n";
	print OUT "#oligoID\t-log10(p_value)\n";
	foreach $array (@good_data) {
		print OUT join( "\t", @$array ) . "\n";
	}
	close(OUT);
	$oligo_Data = \@good_data;

	print
"After applying the cutoff $cutoff we have $var oligos left in the dataset, $temp oligos were removed\n";
}
else {
	my @line;
	open( IN, "<$outfile.$cutoff.oligoIDs" );
	while (<IN>) {
		unless ( defined $temp ) {
			next if ( $_ =~ m/^#cutoff/ );
			$var  = $1 if ( $_ =~ m/^#passed=(\d+)/ );
			$temp = $1 if ( $_ =~ m/^#rejected=(\d+)/ );
		}
		next if ( $_ =~ m/^#/ );
		chomp($_);
		@line = split( "\t", $_ );
		push( @$oligo_Data, [@line] );
	}
	print
"we have recovered a saved intermediate ($outfile.$cutoff.oligoIDs) and identified $var oligos to use!\n";
}

## now we need to set up the position identification
my ($result);
unless ( -f "$outfile.$cutoff.nearby_genes" ) {

	my $Nimblegene_GeneInfo = Nimblegene_GeneInfo->new($debug);

	$Nimblegene_GeneInfo->GetData($olgio2DNA_file);

	$result = $Nimblegene_GeneInfo->get_closeby_gene_PROMOTER_MODE($oligo_Data);
	open( OUT, ">$outfile.$cutoff.nearby_genes" )
	  or die "could not create the temp file '$outfile.$cutoff.nearby_genes'\n";
	print OUT "#oligoID\t-log10(p_value)\tGene Symbol\n";
	foreach my $oligo ( sort keys %$result ) {
		foreach my $gene ( @{ $result->{$oligo} } ) {
			print OUT "$oligo\t$gene\n";
		}
	}
	close(OUT);
}
else {
	open( IN, "<$outfile.$cutoff.nearby_genes" )
	  or die "could not open the tem file '$outfile.$cutoff.nearby_genes'\n";
	my @line;
	while (<IN>) {
		next if ( $_ =~ m/^#/ );
		chomp($_);
		@line = split( "\t", $_ );
		$result->{"$line[0]\t$line[1]"} = []
		  unless ( defined $result->{"$line[0]\t$line[1]"} );
		push( @{ $result->{"$line[0]\t$line[1]"} }, $line[2] );
	}
	close(IN);
}

## now we need to add the men and std of the two groups to the file
my ( $rv, $dataInterfaceA, $dataInterfaceB, $array_dataset, $nucleotoide_lib,
	$lastHeader );

$array_dataset = array_dataset->new( root::getDBH('root'), 0 );
$nucleotoide_lib = nucleotide_array->new();
$dataInterfaceA =
  $nucleotoide_lib->Get_OligoDB_for_ID(
	$nucleotoide_lib->getID_for_identifier($array_identifier) );
$dataInterfaceB =
  $nucleotoide_lib->Get_OligoDB_for_ID(
	$nucleotoide_lib->getID_for_identifier($array_identifier) );

unless ( -f "$outfile.$cutoff.with_mens_oligo_enrichment" ) {

	my $rv = $array_dataset->getArray_of_Array_for_search(
		{
			'search_columns' => ['array_dataset.table_baseString'],
			'where'          => [ [ 'array_dataset.id', '=', 'my_value' ] ]
		},
		\@array_datasets_groupA
	);

	foreach $array (@$rv) {
		$dataInterfaceA->Add_oligo_array_values_Table( @$array[0] );
	}

	$rv = $array_dataset->getArray_of_Array_for_search(
		{
			'search_columns' => ['array_dataset.table_baseString'],
			'where'          => [ [ 'array_dataset.id', '=', 'my_value' ] ]
		},
		\@array_datasets_groupB
	);

	foreach $array (@$rv) {
		$dataInterfaceB->Add_oligo_array_values_Table( @$array[0] );
	}

	my (
		$meanA,      $stdA,     $meanB, $stdB, $root,
		$new_result, @oligoIDs, $A,     $B,    $oligoID
	);
	$root = root->new();
	foreach my $oligo ( sort keys %$result ) {
		@data = split( "\t", $oligo );
		push( @oligoIDs, $data[0] );
	}

	$rv = $dataInterfaceA->getArray_of_Array_for_search(
		{
			'search_columns' =>
			  [ 'oligoDB.oligo_name', 'oligo_array_values.value' ],
			'where' => [ [ 'oligoDB.oligo_name', '=', 'my_value' ] ]
		},
		\@oligoIDs
	);
	foreach my $array (@$rv) {
		$oligoID = shift(@$array);
		print "we have the oligoId $oligoID\n";
		( $meanA, $temp, $stdA ) = $root->getStandardDeviation($array);
		$A->{$oligoID} = [ $meanA, $stdA ];
	}
	$rv = $dataInterfaceB->getArray_of_Array_for_search(
		{
			'search_columns' =>
			  [ 'oligoDB.oligo_name', 'oligo_array_values.value' ],
			'where' => [ [ 'oligoDB.oligo_name', '=', 'my_value' ] ]
		},
		\@oligoIDs
	);
	foreach my $array (@$rv) {
		$oligoID = shift(@$array);
		( $meanB, $temp, $stdB ) = $root->getStandardDeviation($array);
		$B->{$oligoID} = [ $meanB, $stdB ];
	}
	foreach my $oligo ( sort keys %$result ) {
		@data = split( "\t", $oligo );
		$oligoID =
		  join( "\t",
			( $oligo, @{ $A->{ $data[0] } }, @{ $B->{ $data[0] } } ) );
		$new_result->{$oligoID} = $result->{$oligo};
		print
"we got a new data key '$oligoID' pointing to the array $new_result->{$oligo}\n";
	}
	$result = $new_result;
	open( OUT, ">$outfile.$cutoff.with_mens_oligo_enrichment" )
	  or die
"could not create the temp file '$outfile.$cutoff.with_mens_oligo_enrichment'\n";
	$lastHeader =
	    "#oligoID\t-log10(p_value)\t MeDIP mean groupA (n="
	  . scalar(@array_datasets_groupA)
	  . ")\tstd groupA\tMeDIP mean groupB (n="
	  . scalar(@array_datasets_groupB)
	  . ")\tstd groupB\tGene Symbol";
	print OUT $lastHeader . "\n";
	foreach my $oligo ( sort keys %$result ) {
		foreach my $gene ( @{ $result->{$oligo} } ) {
			print OUT "$oligo\t$gene\n";
		}
	}
	close(OUT);
}
else {
	open( IN, "<$outfile.$cutoff.with_mens_oligo_enrichment" )
	  or die "could not open '$outfile.$cutoff.with_mens_oligo_enrichment'\n";
	$result = {};
	my ( @line, $key );
	while (<IN>) {
		if ( $_ =~ m/^#/ ) {
			chomp($_);
			$lastHeader = $_;
			next;
		}
		chomp($_);
		@line = split( "\t", $_ );
		$key = join( "\t",
			( $line[0], $line[1], $line[2], $line[3], $line[4], $line[5] ) );
		$result->{$key} = [] unless ( defined $result->{$key} );
		push( @{ $result->{$key} }, $line[6] );
	}
	close(IN);
}

## AND now we need to add the expression data to the results.

## 1. We need the gene names you want to get info about
my ( @genes, $gene );
foreach $rv ( sort keys %$result ) {
	$array = $result->{$rv};
	foreach $gene (@$array) {
		push( @genes, $gene );
	}
}

## 2. we need to get our sample descriptions!!
#my ( $rv, $dataInterfaceA, $dataInterfaceB, $array_dataset, $nucleotoide_lib );
#
#$array_dataset = array_dataset->new( root::getDBH('root'), 0 );
#$nucleotoide_lib = nucleotide_array->new();
#$dataInterfaceA =
#  $nucleotoide_lib->Get_OligoDB_for_ID(
#	$nucleotoide_lib->getID_for_identifier($array_identifier) );
#$dataInterfaceB =
#  $nucleotoide_lib->Get_OligoDB_for_ID(
#	$nucleotoide_lib->getID_for_identifier($array_identifier) );

my ( @sample_lables_A, @sample_lables_B );
$rv = $array_dataset->getArray_of_Array_for_search(
	{
		'search_columns' => ['samples.sample_lable'],
		'where'          => [ [ 'array_dataset.id', '=', 'my_value' ] ],
	},
	\@array_datasets_groupA
);
foreach $array (@$rv) {
	push( @sample_lables_A, @$array[0] );
}

$rv = $array_dataset->getArray_of_Array_for_search(
	{
		'search_columns' => ['samples.sample_lable'],
		'where'          => [ [ 'array_dataset.id', '=', 'my_value' ] ],
	},
	\@array_datasets_groupB
);
foreach $array (@$rv) {
	push( @sample_lables_B, @$array[0] );
}

use stefans_libs::database::expression_estimate;
use stefans_libs::array_analysis::correlatingData::Wilcox_Test;
my ( $expression_estimate, $expression_interface, $A, $B, $root );
$expression_estimate = expression_estimate->new( '', $debug );

$A = $B = undef;

$expression_interface = $expression_estimate->GetInterface(
	[ [ 'sample_lable', '=', 'my_value' ] ],
	[ \@sample_lables_A ]
);
$A = $expression_interface->getExpression_values_4_genes( \@genes );

$expression_estimate = expression_estimate->new( root::getDBH('root'), $debug );
$expression_interface = $expression_estimate->GetInterface(
	[ [ 'sample_lable', '=', 'my_value' ] ],
	[ \@sample_lables_B ] 
);
$B = $expression_interface->getExpression_values_4_genes( \@genes );
my $statistics = Wilcox_Test->new();

## we need to check for a paired test!

my $sampleTable = sampleTable->new( root::getDBH('root'),$debug);
$rv = $sampleTable->getArray_of_Array_for_search({
 	'search_columns' => [ref($sampleTable).".subject_id"],
 	'where' => [['sample_lable', '=', 'my_value']],
 	'order_by' => [ref($sampleTable).".id"],
},\@sample_lables_B);

my $foo;
$temp = $foo = '';

foreach $array ( @$rv) {
	$temp .= " ".@$array[0];
}

$rv = $sampleTable->getArray_of_Array_for_search({
 	'search_columns' => [ref($sampleTable).".subject_id"],
 	'where' => [['sample_lable', '=', 'my_value']],
 	'order_by' => [ref($sampleTable).".id"],
},\@sample_lables_A);

foreach $array ( @$rv) {
	$foo .= " ".@$array[0];
}
if ( $foo eq $temp){
	$statistics->SET_pairedTest ( 1 ) ;
	print "\tExpression values will be compared in paired mode!\n";
}
else {
	print "Sorry, but we have no paired data for the expression \ngroupA: $foo\ngroupB: $temp\n";
}


my ( $mean, $std, $p_value, $r_square, $unused );
$root = root->new();
open( OUT, ">$outfile.$cutoff.with_expression_data" )
  or die " could not create '$outfile.$cutoff.with_expression_data'\n";
print OUT $lastHeader
  . "\tWilcox p_value\tmean group A\t std group A\tmean group B\t std group B\n";

foreach $rv ( sort keys %$result ) {
	$array = $result->{$rv};
	for ( my $i = 0 ; $i < @$array ; $i++ ) {
		if ( defined $A->get_expression_4_gene( @$array[$i] ) ) {
			## we have expression data for these genes!
			$temp = '';
			( $p_value, $unused, $r_square ) = split(
				"\t",
				$statistics->_calculate_wilcox_statistics(
					$A->get_expression_4_gene( @$array[$i] ),
					$B->get_expression_4_gene( @$array[$i] )
				)
			);
			$temp = "@$array[$i]\t$p_value";
			( $mean, $unused, $std ) =
			  $root->getStandardDeviation( $A->get_expression_4_gene( @$array[$i] ) );
			$temp .= "\t$mean\t$std";
			( $mean, $unused, $std ) =
			  $root->getStandardDeviation( $B->get_expression_4_gene( @$array[$i] ) );
			$temp .= "\t$mean\t$std";
			@$array[$i] = $temp;
		}
		print OUT $rv . "\t" . @$array[$i] . "\n";
	}
}
close(OUT);
print
"the final data should reside in the file '$outfile.$cutoff.with_expression_data'\n";

