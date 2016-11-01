#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok
	  'stefans_libs::file_readers::CoExpressionDescription::KEGG_results';
}

my ( $test_object, $value, $exp, @values );
$test_object =
  stefans_libs::file_readers::CoExpressionDescription::KEGG_results->new();
is_deeply(
	ref($test_object),
	'stefans_libs::file_readers::CoExpressionDescription::KEGG_results',
'simple test of function stefans_libs::file_readers::CoExpressionDescription::KEGG_results -> new()'
);

$value = $test_object->AddDataset(
	{
		'kegg_pathway.id'        => 0,
		'matched genes'          => 1,
		'pathway_name'           => 2,
		'Gene Symbols'           => 3,
		'max_count'              => 4,
		'bad_entries'            => 5,
		'hypergeometric p value' => 6,
	}
);
is_deeply( $value, 1, "we could add a sample dataset" );

my $test_file;
$test_file = "data/KEGG_result.test.txt";
$test_file = "t/data/KEGG_result.test.txt"   if ( -f "t/data/KEGG_result.test.txt" );

die "sorry I have no test data file!" unless ( -f $test_file);
$test_object -> read_file($test_file);
is_deeply ( [$test_object->Header_Position( 'plottable')], [2,1,6] , "we have recovered the plottable subset");

$value = $test_object -> get_significant_pathway_names();

is_deeply ( $value , [ 'Maturity onset diabetes of the young', 'Type II diabetes mellitus', 'Progesterone-mediated oocyte maturation'], "get_significant_pathway_names");


## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
