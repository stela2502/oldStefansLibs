#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::plot::simpleWhiskerPlot' }
## test for new

my ( $value, @values, $exp );
my $barGraph = simpleWhiskerPlot->new();
is_deeply( ref($barGraph), 'simpleWhiskerPlot', 'could get the object' );
my $im = $barGraph->_createPicture( { 'x_res' => 600, 'y_res' => 400 } );
is_deeply( ref($im), "GD::SVG::Image", "we get an Image object" );
my $color = $barGraph->{color};
is_deeply( ref($color), "color", "and the color object was created correctly" );

my $test_data = {
	'name' => 'NHD',
	'data' => {
		'A/A' => [ 1, 2, 3, 2, 4, 3, 2, 1, 3, 4, 2 ],
		'A/B' => [ 7, 8, 6, 7, 8, 6, 5, 4, 6, 9, 1 ],
		'B/B' => [ 1, 2, 3, 4, 9, 0, 8, 7, 5, 4, 10 ],
	},
	'order_array'  => [ 'A/A', 'A/B', 'B/B' ],
	'color'        => $color->{'green'},
	'border_color' => $color->{'green'}
};
is_deeply( $barGraph->AddDataset($test_data),
	1, "it seams as if we could add a dataset" );



$test_data = {
	'name' => 'T2D',
	'data' =>,
	{
		'A/B' => {
			'upper'  => '8',
			'min'    => '1',
			'lower'  => '6',
			'max'    => '9',
			'median' => '6.5'
		},
		'A/A' => {
			'upper'  => '3.5',
			'min'    => '1',
			'lower'  => '2',
			'max'    => '4',
			'median' => '2.5'
		},
		'B/B' => {
			'upper'  => '8.5',
			'min'    => '0',
			'lower'  => '3',
			'max'    => '10',
			'median' => '4.5'
		}
	},
	'order_array'  => [ 'A/A', 'A/B', 'B/B' ],
	'color'        => $color->{'blue'},
	'border_color' => $color->{'grey'}
};

is_deeply( $barGraph->AddDataset($test_data),
	1, "it seams as if we could add a dataset (2)" );


$barGraph->AddDataset($test_data);
is_deeply(
	$barGraph->Ytitle('expression [min, lower quantil median upper quantil max]'),
	'expression [min, lower quantil median upper quantil max]',
	'we have set the Y title'
);
is_deeply(
	$barGraph->Xtitle('expression of gene XY'),
	'expression of gene XY',
	'we have set the X title'
);

$barGraph->plot(
	{
		'x_res'   => 600,
		'y_res'   => 400,
		'outfile' => '/home/stefan/test_whisker_plot',
		'x_min'   => 50,
		'x_max'   => 550,
		'y_min'   => 20,                                # oben
		'y_max'   => 340,                               # unten
		'mode'    => 'landscape',
	}
);

#print "\$exp = " . root->print_perl_var_def( $test_data->{'data'} ) . ";\n";