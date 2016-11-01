#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok
'stefans_libs::MyProject::Gene_SNP_descritpion_table::rsID_based_SNP_2_gene_description';
}

my ( $test_object, $value, $exp, @values );
$test_object =
  stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description
  ->new();
is_deeply(
	ref($test_object),
'stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description',
'simple test of function stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description -> new()'
);

$value = $test_object->AddDataset(
	{
		'rsID'                        => 'rs10954984',
		'Correlating genes (p value)' => 'TCF7L2 (1)'
	}
);
is_deeply( $value, 1, "we could add a sample dataset" );

$test_object->Add_Closest_genes( 'H_sapiens') ;

#print "\$exp = ".root->print_perl_var_def( $test_object-> get_line_asHash ( 0 ) ).";\n";
$exp = {
  'gene end' => '568789',
  'gene start' => '561420',
  'rs position' => '549939',
  'Correlating genes (p value)' => 'TCF7L2 (1)',
  'distance SNP to gene' => '11481',
  'cis gene' => 'LOC100128750',
  'rsID' => 'rs10954984'
};

is_deeply ( $test_object-> get_line_asHash ( 0 ), $exp, "we hot the right first line");
is_deeply ( scalar(@{$test_object->{'data'}}),1, "And we get only one line" );


## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
