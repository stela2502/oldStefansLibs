#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { use_ok 'stefans_libs::root' }

my $root = root->new();

is_deeply( ref($root), "root", "we can create an object" );

is_deeply( $root->Latex_Label('test_812734182754'),
	'test812734182754', "Latex_Label works" );

my ( $value, @values, $exp );
$value = root->normalize( [ 1, 2, 3, 4, 5, 4, 3, 2, 1, 2, 3, 4, 5 ] );
$exp = [
	-1.477098, -0.738549, 0.000000,  0.738549,  1.477098, 0.738549,
	0.000000,  -0.738549, -1.477098, -0.738549, 0.000000, 0.738549,
	1.477098
];
my $i = 0;
foreach (@$value) {
	if ( $_ == 0){
		$values[$i++] = 0 ;
		next;
	}
	
	$values[$i++] = sprintf('%.6f', $_) ;
	
}

is_deeply( \@values, $exp, "nomalize" );
