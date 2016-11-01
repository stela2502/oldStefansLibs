#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Address_Parser' }

my ( $value, @values, $exp );
my $stefans_libs_Address_Parser = stefans_libs_Address_Parser -> new();
is_deeply ( ref($stefans_libs_Address_Parser) , 'stefans_libs_Address_Parser', 'simple test of function stefans_libs_Address_Parser -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


