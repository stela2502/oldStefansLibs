#! /usr/bin/perl
use strict;
use warnings;
use FindBin;
use Digest::MD5 qw(md5_hex);

use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::external_files' }

my $external_files = external_files -> new( root::getDBH(), 1);
is_deeply ( ref($external_files) , 'external_files', 'simple test of function external_files -> new()' );

$external_files->create();

## we want to store a simple file using the database
## the file is ./data/A_initial_grant_description.txt

my $dataPath = "$FindBin::Bin/data/";
is_deeply($external_files->AddDataset ( { 'filename' => "$dataPath/A_initial_grant_description.txt", 'filetype' => 'text_document', 'mode' => 'text'} ), 1, "hopefully we were able to store the file");

my $value = $external_files->get_fileHandle( {'id' => 1} );
is_deeply(ref($value),"GLOB", "we got a filehandle for the file_id 1");

$value = $external_files->get_fileHandle( {'filename' => "A_initial_grant_description.txt"} );
is_deeply(ref($value),"GLOB", "we got a filehandle for the filename 'A_initial_grant_description.txt'");
is_deeply(md5_hex(join ("", <$value>) ), "422020e66ebc64f60cc278405e50e7aa", "and the file was not changed!" );

is_deeply($external_files->AddDataset ( { 'filename' => "$dataPath/test_bin_file.dta", 'filetype' => 'text_document', 'mode' => 'binary'} ), 2, "I could upload a binary file!");
$value = $external_files->get_fileHandle( {'filename' => "test_bin_file.dta"} );
is_deeply(ref($value),"GLOB", "we got a filehandle for the filename 'test_bin_file.dta'");
binmode $value ;
open ( OUT, ">$dataPath/test.dta" );
binmode OUT ;
foreach ( <$value> ){
	print OUT $_;
}
close OUT;

my @values = qx(md5sum $dataPath/test.dta);
$value = join("" ,@values);
@values = split( / +/ ,$value);
my $result = $values[0];
@values = qx(md5sum $dataPath/test_bin_file.dta);
$value = join("" ,@values);
@values = split( / +/ ,$value);
$value = $values[0];
is_deeply($result, $value ,"Huray - we could copy a binary file!" );

## test for new

