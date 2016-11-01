#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use stefans_libs::array_analysis::correlatingData;
BEGIN { use_ok 'stefans_libs::MyProject::GeneticAnalysis::Model' }

my ( $value, @values, $exp );
my $stefans_libs_MyProject_GenetcAnalysis_Model =
  stefans_libs_MyProject_GeneticAnalysis_Model->new(
	{ 'SNPs' => [ 1, 2, 4, 7 ], 'max_subjects' => 100, 'phenotype' => 'T2D' },
	 chi_square->new(  ));
is_deeply(
	ref($stefans_libs_MyProject_GenetcAnalysis_Model),
	'stefans_libs_MyProject_GeneticAnalysis_Model',
'simple test of function stefans_libs_MyProject_GenetcAnalysis_Model -> new()'
);

foreach ( 1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1, 1, 2, 2, 2 ) {
	$stefans_libs_MyProject_GenetcAnalysis_Model->addKey_value( 'A', $_ );
}
foreach ( 1, 1, 1, 1, 2 ) {
	$stefans_libs_MyProject_GenetcAnalysis_Model->addKey_value( 'X', $_ );
}
foreach ( 2, 2, 2, 2, 2 ) {
	$stefans_libs_MyProject_GenetcAnalysis_Model->addKey_value( 'Y', $_ );
}
foreach ( 1, 2, 2, 2, 1, 1, 2, 2, 1, 1, 1, 2, 2, 2, 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 1, 1, 2, 2, 2 ) {
	$stefans_libs_MyProject_GenetcAnalysis_Model->addKey_value( 'B', $_ );
}

is_deeply( $stefans_libs_MyProject_GenetcAnalysis_Model->Max()->{'key'},
	'B', "max" );
is_deeply( $stefans_libs_MyProject_GenetcAnalysis_Model->Max()->{'n'},
	51, "max n" );
is_deeply( $stefans_libs_MyProject_GenetcAnalysis_Model->Min()->{'key'},
	'A', "min" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

