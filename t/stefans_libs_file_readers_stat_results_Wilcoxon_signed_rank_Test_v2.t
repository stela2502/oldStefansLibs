#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_v2' }
use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2 = stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2 -> new();
is_deeply ( ref($stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2) , 'stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2', 'simple test of function stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2 -> new()' );

my ( $file, $path );
$path = $plugin_path . "/data";
$path = "t/$path" unless ( -d $path );
$file = "$path/Wilcox_Result_v2.xls";

$stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2->read_file ( $file );
is_deeply ($stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2->Lines (), 7, 'read file' );

$value = $stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2->get_line_asHash(0);
is_deeply ( $value->{'fold change'}, 0.616707800654232, "Fold change column has been created" );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";


