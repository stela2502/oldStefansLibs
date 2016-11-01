#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use stefans_libs::root;
BEGIN { use_ok 'stefans_libs::array_analysis::correlatingData::SpearmanTest' }
## test for new
my ( $value, $exp );
my $spearman = SpearmanTest->new();
is_deeply( ref($spearman), 'SpearmanTest', 'new' );

$value = $spearman->_calculate_spearmanWeightFit_statistics(
	[
7.18, 7.01, 7.17, 7.1, 7.01, 7.18, 7.07, 7.33, 7.36, 7.04, 7.12, 7.02, 7.37, 7.28, 7.21, 7.29, 7, 7.02, 7.23, 7.07, 7.24, 7.11, 7.21, 7.24, 7.3, 7.37, 7, 7.03, 7.04, 7.09, 7.16, 7.24, 7.06, 7.33, 6.94, 7.16, 6.94, 7.15, 6.92, 7.29, 7.18, 7.38, 7.16
	],
	[
6.45, 6.69, 7.06, 6.5, 6.86, 6.47, 6.58, 7.02, 7.19, 6.86, 6.88, 6.9, 6.89, 6.79, 6.75, 6.99, 6.64, 6.59, 6.51, 6.39, 6.81, 6.73, 6.53, 6.78, 6.82, 6.72, 7.02, 6.86, 5.8, 6.79, 6.83, 6.54, 6.54, 6.79, 7.08, 7.05, 6.89, 6.38, 6.73, 6.56, 6.68, 6.64, 6.86
	]
);
is_deeply ( $value, "0.9998\t13244.5\t-3.781147e-05", 'R square very small');
$value = $spearman->_calculate_spearmanWeightFit_statistics(
	[
	1,2,3,4,5,6,7,8,9,10
	],
	[
	9,10,8,7,6,5,4,3,2,1
	]
);
is_deeply( $value , "2.2e-16\t328\t-0.9878788", 'P very samll');

