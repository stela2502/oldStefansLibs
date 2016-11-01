#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::array_analysis::correlatingData::QQplot' }

my ( $value, @values, $exp );
my $stefans_libs_array_analysis_correlatingData_QQplot = stefans_libs_array_analysis_correlatingData_QQplot -> new();
is_deeply ( ref($stefans_libs_array_analysis_correlatingData_QQplot) , 'stefans_libs_array_analysis_correlatingData_QQplot', 'simple test of function stefans_libs_array_analysis_correlatingData_QQplot -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


