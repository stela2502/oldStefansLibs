#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::array_dataset::Affy_SNP_array::affy_cell_flatfile' }

my ( $value, @values, $expected );

open ( TEXT, ">test.file" ) or die "Sorry, but I could not create the test file test.file\n$!\n";
$expected = "I just want to see if I can get these entries back!";
print TEXT $expected."\n";
close ( TEXT );
my $affy_cell_flatfile = affy_cell_flatfile->new( root::getDBH('root'), 0 );

$affy_cell_flatfile->AddDataset ( { 'file' => 'test.file', 'array_id' => 1 } );

print "we have removed our test file\n" if (unlink('test.file' ) == 1);

$value = $affy_cell_flatfile->get_fileHandle ( {'array_id' => 1 });

print "we got a file handle $value?\n";

while ( <$value> ){
	is_deeply ( $_, $expected."\n", "we can store and retrieve data using affy_cell_flatfile");
	last;
}

close ( $value );
