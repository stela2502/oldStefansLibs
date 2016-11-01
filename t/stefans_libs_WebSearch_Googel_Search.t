#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::WebSearch::Googel_Search' }

my ( $value, @values, $exp );
my $stefans_libs_WebSearch_Googel_Search = stefans_libs_WebSearch_Googel_Search -> new();
is_deeply ( ref($stefans_libs_WebSearch_Googel_Search) , 'stefans_libs_WebSearch_Googel_Search', 'simple test of function stefans_libs::WebSearch::Googel_Search -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


$value = $stefans_libs_WebSearch_Googel_Search -> search_for  ( 'rs8026735');

is_deeply ( scalar(@$value), 2, "we got the expected amount of links" );