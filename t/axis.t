#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;
BEGIN { use_ok 'stefans_libs::plot::axis' }
## test for new

my $axis = axis->new( 'x' , 100, 200 , 'no title', 'min' );
is_deeply( ref($axis), "axis", "new");
is_deeply($axis -> min_value ( 0 ), 0, "set min value");
is_deeply($axis -> max_value ( 10 ), 10, "set max value");

is_deeply($axis -> defineAxis(), -10, "define Axis (x)");
is_deeply($axis ->resolveValue(5), 150, "resolve_value");


$axis = axis->new( 'y' , 100, 200 , 'no title', 'min' );
is_deeply($axis -> min_value ( 0 ), 0, "set min value");
is_deeply($axis -> max_value ( 10 ), 10, "set max value");

is_deeply($axis -> defineAxis(), 10, "define Axis (y)");
is_deeply($axis ->resolveValue(5), 150, "resolve_value");


$axis = axis->new( 'y' , 100, 1600 , 'no title', 'min' );
is_deeply($axis -> min_value ( 0 ), 0, "set min value");
is_deeply($axis -> max_value ( 200 ), 200, "set max value");

is_deeply($axis -> defineAxis(), 7.5, "define Axis (y)");
is_deeply($axis ->resolveValue(5), 1562, "resolve_value");