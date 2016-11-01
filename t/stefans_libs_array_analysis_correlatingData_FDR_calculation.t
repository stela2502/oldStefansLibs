#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::array_analysis::correlatingData::FDR_calculation' }

my ( $value, @values, $exp );
my $stefans_libs_array_analysis_correlatingData_FDR_calculation = stefans_libs_array_analysis_correlatingData_FDR_calculation -> new();
is_deeply ( ref($stefans_libs_array_analysis_correlatingData_FDR_calculation) , 'stefans_libs_array_analysis_correlatingData_FDR_calculation', 'simple test of function stefans_libs_array_analysis_correlatingData_FDR_calculation -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


