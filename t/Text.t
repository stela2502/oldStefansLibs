#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::Text' }

my $Text = Text -> new();
is_deeply ( ref($Text) , 'Text', 'simple test of function Text -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


## test for new

