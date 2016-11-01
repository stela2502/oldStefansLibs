#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::file_readers::svg_pathway_description' }

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs_file_readers_svg_pathway_description->new();
is_deeply(
	ref($test_object),
	'stefans_libs_file_readers_svg_pathway_description',
'simple test of function stefans_libs_file_readers_svg_pathway_description -> new()'
);

$value = $test_object->AddDataset(
	{
		'key' => 0,
		'x1'  => 1,
		'x2'  => 2,
		'y1'  => 3,
		'y2'  => 4,
	}
);
is_deeply( $value, 1, "we could add a sample dataset" );

my $infile;
$infile = "data/Zeichnung.svg"   if ( -f "data/Zeichnung.svg" );
$infile = "t/data/Zeichnung.svg" if ( -f "t/data/Zeichnung.svg" );
die
"Sory, but the data file data/Zeichnung.svg or t/data/Zeichnung.svg could not be found!\n"
  unless ( defined $infile );

$test_object->read_file($infile);

is_deeply(
	$test_object->get_line_asHash(0),
	{
		'key' => 'gene_SLC2A2',
		'x1'  => 762,
		'x2'  => 762 + 156,
		'y1'  => 206,
		'y2'  => 206 + 83
	},
	"get the right values (0)"
);
## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
