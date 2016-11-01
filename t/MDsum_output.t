#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::MDsum_output' }

my $MDsum_output = MDsum_output -> new();
is_deeply ( ref($MDsum_output) , 'MDsum_output', 'simple test of function MDsum_output -> new()' );

## test for new
my $datafile ;
$datafile= "data/MDsum_output.txt"   if ( -f "data/MDsum_output.txt" );
$datafile = "t/data/MDsum_output.txt" if ( -f "t/data/MDsum_output.txt" );

die "Sorry, but we do not have the sample dataset we need to perform our tests..." unless ( defined $datafile );

is_deeply( $MDsum_output->readFile($datafile), 1, "no error while reading the file");
#print root::get_hashEntries_as_string ( $MDsum_output, 7, " ");
my $expected = "Motif 1: Wid 6; Score 5.193; Sites 4; Con TGGTTG; RCon CAACCA
********************************
#position\tA\tC\tG\tT\tCon\trCon\tDeg\trDeg
1\t0.44\t0.36\t42.07\t57.13\tT\tA\tK\tM
2\t0.44\t0.36\t98.75\t0.44\tG\tC\tG\tC
3\t0.44\t0.36\t98.75\t0.44\tG\tC\tG\tC
4\t0.44\t0.36\t0.36\t98.84\tT\tA\tT\tA
5\t0.44\t0.36\t0.36\t98.84\tT\tA\tT\tA
6\t15.95\t30.30\t30.30\t23.44\tC\tG\tS\tS
>calc_id_7_it_4_Chr3_id=4906_118469205..118469705H_POL2_mean=1.2013346  Len 500 Site #1 r 417
TGGTTT
>calc_id_7_it_4_Chr3_id=4906_118469205..118469705H_POL2_mean=1.2013346  Len 500 Site #2 r 368
TGGTTT
>calc_id_7_it_4_Chr3_id=4906_118469205..118469705H_POL2_mean=1.2013346  Len 500 Site #3 r 316
TGGTTA
>calc_id_7_it_4_Chr3_id=4906_118469205..118469705H_POL2_mean=1.2013346  Len 500 Site #4 r 268
TGGTTT
********************************
";

is_deeply( [split("\n",$MDsum_output->AsString()) ],[split( "\n",  $expected ) ], "we can get the dataset as string");