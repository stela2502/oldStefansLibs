#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::plot::Chromosomes_plot' }
my ( $value, @values, $expected, $root);

$root = root->new();
$root->NoTestConnection(1);

my $Chromosomes_plot = Chromosomes_plot->new( $root->getDBH());
is_deeply ( ref($Chromosomes_plot), 'Chromosomes_plot', 'new');
$Chromosomes_plot ->chromosomal_resolution ( 100 );
$value = $Chromosomes_plot->_process_chromosomes_arrays( [140, '11'],[240, '1'] );
is_deeply( $value, 1, 'create the chromosomes dataset');
$value = $Chromosomes_plot->_getDatasets();
$expected = { 'upper' => [ chromosomal_histogram->new('1'), chromosomal_histogram->new('11')] , 'lower' => [] };
@{$expected ->{'upper'}}[0]->{'min'} = 0;
@{$expected ->{'upper'}}[0]->{'max'} = 240;
@{$expected ->{'upper'}}[1]->{'min'} = 0;
@{$expected ->{'upper'}}[1]->{'max'} = 140;
@{$expected ->{'upper'}}[0]->initialize( 100 );
@{$expected ->{'upper'}}[1]->initialize( 100 );
$value = $value ->{'data'};
is_deeply( $value, $expected ,'the internal dataset');

my $data = { '1' => [ 9,9,9,14,14,14,24,24,201,201,201,201], '11' => [ 9,9,9,14,14,14,24,24,24,24,101,110,101]};
foreach my $chr_name ( keys %$data ){
	$Chromosomes_plot->Add_Data_4_chromosome( $chr_name, $data->{$chr_name});
}
$value = $Chromosomes_plot->_getDatasets();
$value = $value ->{'data'};
$expected = [[0,100,8],[100,200,0],[200,300,4]];
#print root::get_hashEntries_as_string (@{$value->{'upper'}}[0]->getAsDataMatrix(), 3, "the data matrix ");
is_deeply (@{$value->{'upper'}}[0]->getAsDataMatrix(), $expected, 'data for chr 1');
$expected = [[0,100,10],[100,200,3]];
is_deeply (@{$value->{'upper'}}[1]->getAsDataMatrix(), $expected, 'data for chr 2');

$Chromosomes_plot->plot({
	'x_res' => 600,
	'y_res' => 400,
	'y_min' => 20,
	'y_max' => 380,
	'x_min' => 40,
	'x_max' => 580,
	'outfile' => "/home/stefan_l/temp/Chromosomes_plot"
});
