#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::file_readers::PPI_text_file' }

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs_file_readers_PPI_text_file->new();
is_deeply( ref($test_object), 'stefans_libs_file_readers_PPI_text_file',
	'simple test of function stefans_libs_file_readers_PPI_text_file -> new()'
);

my ($infile);
$infile = "t/data/PPI.xls" if ( -f "t/data/PPI.xls" );
$infile = "data/PPI.xls"   if ( -f "data/PPI.xls" );

die "Sorry, but I can not find my test infile\n" unless ( -f $infile );
$test_object = stefans_libs_file_readers_PPI_text_file->new();
$test_object->read_file($infile);

$value = $test_object->expand( ['M6PR'] );
is_deeply(
	$value,
	[
		sort
		  qw/FUCA2 AP1GBP1 SKAP2 VAMP3 NOX3 SNAP91 EPDR1 REM1 GNPTG ESR1 TGM1 IGFALS SNAP29 CTSG GZMH BDKRB1 CTSZ RSPO4 STS PGRMC1 GLA CORO1A HMOX2 CTSH TG PLAT PPP2CB NEFM MAN2B1 TGFB1 M6PRBP1 HAS1 GCDH INSL3 USF2 ERF TFR2 MEST RPS6KB1 C1QBP CPD NAGLU M6PR/
	],
	"we can expand a gene list"
);

$value = $test_object->expand( ['M6PR'], [ qw/FUCA2 AP1GBP1 SKAP2 VAMP3 NOX3 SNAP91 EPDR1 REM1 GNPTG RAG1 RAG2/]);
is_deeply(
	$value,
	[
		sort
		  qw/FUCA2 AP1GBP1 SKAP2 VAMP3 NOX3 SNAP91 EPDR1 REM1 GNPTG M6PR/
	],
	"we can expand a gene list and get only genes we are interested in"
);

## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
