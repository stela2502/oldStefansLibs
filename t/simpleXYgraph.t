#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::plot::simpleXYgraph' }

my $simpleXYgraph = simpleXYgraph->new();
#$simpleXYgraph->_createPicture ( { 'x_res' => 600, 'y_res' => 400});
is_deeply( ref($simpleXYgraph), 'simpleXYgraph', "we can get the object");

is_deeply($simpleXYgraph->AddDataset( { 'title' => 'just a test', 'x' => [ 1,2,3,4,5,6,7,8,9,10], 'y' => [ 10,9,8,7,6,5,4,3,2,1]}), 1,"we could add a dataset");
is_deeply($simpleXYgraph->X_Min(), 1, "X_min");
is_deeply($simpleXYgraph->X_Max(), 10, "X_max");
is_deeply($simpleXYgraph->Y_Min(), 1, "Y_min");
is_deeply($simpleXYgraph->Y_Max(), 10, "Y_max");

is_deeply($simpleXYgraph->AddDataset( { 'title' => 'dataset 2', 'x' => [ 10,9,8,7,6,5,4,3,2,1] , 'y' =>[ 10,9,8,7,6,5,4,3,2,1], 'stdAbw' => [ 0.3, 0.4, 0.12, 0.34, 0.23, 0.76, 0.63, 0.1, 0.12, 0.23] }), 1,"we could add a dataset");


$simpleXYgraph->plot({
	'x_res' => 600, 
	'y_res' => 400,
	'x_min' => 20,
	'x_max' => 580,
	'y_min' => 40,
	'y_max' => 380,
	'outfile' => '/home/stefan_l/simpleXYgraph'
}
);

