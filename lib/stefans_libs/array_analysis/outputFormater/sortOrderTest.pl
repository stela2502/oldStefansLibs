#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::outputFormater::arraySorter;
use stefans_libs::root;

my (@array, @a,@b,@c,@d,@e, @f, @sortOrders);

@a = ( 1, 4, "A");
@b = ( 1, 5, "B");
@c = ( 1, 4, "A");
@d = ( 2, 5, "B");
@e = ( 2, 4, "A");
@f = ( 2, 4, "B");

@array = ( \@a, \@b, \@c, \@d,\@f,\@e);

root::print_hashEntries(\@array, 2, "the initial matrix:" );

@sortOrders = ( { position => 1, type => 'numeric' }, { position => 2, type => 'lexical' }, { position => 0, type => 'numeric' } );

root::print_hashEntries( \@sortOrders, 2, "the sort order:");

@array = arraySorter::sortArrayBy( \@sortOrders, @array );

root::print_hashEntries(\@array, 2, "the matrix after the sort:" );

