#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { use_ok 'stefans_libs::gbFile' }
## test for new

my $gbFile = gbFile->new( undef, 1);

is_deeply ( ref($gbFile), "gbFile" , "simple check of function new");

my ( $value, @values);

$value = $gbFile->AddGbfile ( "t/data/hu_genome/originals/NT_113819.1.gb" ) if ( -f "t/data/hu_genome/originals/NT_113819.1.gb" );
$value = $gbFile->AddGbfile ( "data/hu_genome/originals/NT_113819.1.gb" ) if ( -f "data/hu_genome/originals/NT_113819.1.gb" );

is_deeply ( $gbFile->Version(), "NT_113819.1", "the gbFile->Version and the gbFile->AddGbfile functions");

$value = $gbFile->Get_SubSeq ( 0, 10 );

is_deeply ( $value, "GATCACATTT", "we get the right sub seq");