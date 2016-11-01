#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::Figure' }

my $Figure = Figure -> new();
is_deeply ( ref($Figure) , 'Figure', 'simple test of function Figure -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


## test for new

