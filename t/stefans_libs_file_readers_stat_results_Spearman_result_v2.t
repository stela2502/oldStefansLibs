#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::stat_results::Spearman_result_v2' }

my ( $value, @values, $exp );
my $stefans_libs_file_readers_stat_results_Spearman_result_v2 = stefans_libs_file_readers_stat_results_Spearman_result_v2 -> new();
is_deeply ( ref($stefans_libs_file_readers_stat_results_Spearman_result_v2) , 'stefans_libs_file_readers_stat_results_Spearman_result_v2', 'simple test of function stefans_libs_file_readers_stat_results_Spearman_result_v2 -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


