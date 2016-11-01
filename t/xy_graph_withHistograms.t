#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::plot::xy_graph_withHistograms' }
## test for new
my $xy_graph_withHistograms = xy_graph_withHistograms->new();
is_deeply( ref($xy_graph_withHistograms), 'xy_graph_withHistograms', 'new' );

my @X = (
	-1,9, 1,   2,   3,   4,   5,   6,   7,   8,   9,   0,   1.3, 2.3, 3.3, 4.3,
	5.3, 6.3, 7.3, 8.3, 9.3, 0.3, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5,
	9.5, 0.5, 1.4, 2.4, 3.4, 4.4, 5.4, 6.4, 7.4, 8.4, 9.4, 0.4
);
my @Y = (
	0,9, 7.5, 8.5, 9.5, 0.5, 1.4, 2.4, 3.4, 4.4, 5.4, 6.4, 7.4, 8.4, 9.4, 0.4,
	1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 2.3, 3.3, 4.3, 5.3, 6.3, 7.3, 8.3, 9.3,
	0.3, 1,   2,   3,   4,   5,   6,   7,   8,   9,   0,   1.3
);
unlink ( "/home/stefan_l/temp/xy_graph_withHistograms.svg" ) if ( -f "/home/stefan_l/temp/xy_graph_withHistograms.svg");

$xy_graph_withHistograms->plotData(
	[ \@X, \@Y ],
	"/home/stefan_l/temp/xy_graph_withHistograms",
	600, 400
);
is_deeply( -f "/home/stefan_l/temp/xy_graph_withHistograms.svg",
	1, "plot the data" );
## test for plotData

