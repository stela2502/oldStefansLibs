#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
use File::HomeDir;

use stefans_libs::statistics::HMM::HMM_hypothesis;
use stefans_libs::statistics::HMM::probabilityFunction;
BEGIN { use_ok 'stefans_libs::statistics::HMM::UMS' }

my $home = File::HomeDir->my_home();

my $UMS = UMS -> new( 1 );
is_deeply ( ref($UMS) , 'UMS', 'simple test of function UMS -> new()' );

## test for new
my ( $value, @values);
## read in the data file
my $filename = "data/ums_realData_transposed.csv";
$filename = "t/data/ums_realData_transposed.csv" if ( -f "t/data/ums_realData_transposed.csv");
open (DATA ,"<$filename") or die "could not open filename $filename\n$!\n";
@values = ( <DATA> );
close ( DATA );

my ( @all, @more_than_08, @less_than_02, @hypos);
@all = split ( "\t" , $values [0]);
shift @all;
@more_than_08 = split ( "\t", $values [1]);
shift @more_than_08;
@less_than_02 = split ( "\t", $values [2]);
shift @less_than_02;

push ( @hypos, (HMM_hypothesis->new(),HMM_hypothesis->new() ) );

$hypos[0]->add_internalState_hypotheis({ 'name' => 'higher' , 'hypothesis' => {'more_than' => 0.8 }});
$hypos[1]->add_internalState_hypotheis({ 'name' => 'lower' , 'hypothesis' => { 'less_than' => 0.2 }});

$value = $UMS->get_stateValues_for_dataset( {data => [\@all, \@all ], hypothesies => \@hypos });

## the internal data structure
my $all_hist = probabilityFunction->new();
$all_hist -> CreateHistogram ( \@all, undef, 10);
$all_hist ->  removeNullstellen();
$all_hist ->  ScaleSumToOne();
is_deeply ( $UMS->{allHist}, $all_hist, "the internal data representation in the UMS obj." );

## $value hopefully contains two state_values objects\n
is_deeply ( scalar(@$value), 2, "amount of state_value objects");

## the name of the states
my $stateValuesByName;
$stateValuesByName->{@$value[0]->{name}}= @$value[0];
$stateValuesByName->{@$value[1]->{name}}= @$value[1];
is_deeply ( [sort ( keys %$stateValuesByName ) ],  ['higher', 'lower'], "state_value object names");


my $expected_0 = state_values->new('higher');
$expected_0 -> import_from_line_array ( [split "\n",
"name	higher
log_state	0
probability_for_change_to_state
probability distribution
logged	0
min	-2.43
max	3.92
category_steps	10
scale21	1
noNull	1
duringReestimation	0
data
-2.43	-1.795	-2.1125	0.00794491149604999
-1.795	-1.16	-1.4775	0.0343112449015848
-1.16	-0.525	-0.8425	0.156203868631034
-0.525	0.11	-0.2075	0.220824186928924
0.11	0.745	0.4275	0.245246161333803
0.745	1.38	1.0625	0.165825516582876
1.38	2.015	1.6975	0.0785844129651169
2.015	2.65	2.3325	0.0479139277915642
2.65	3.285	2.9675	0.0411595414949565
3.285	3.92	3.6025	7.86465986469931e-14
3.92	4.555	4.2375	0.0019862278740125
" ]);
my $expected_1 = state_values->new('higher');
$expected_1 -> import_from_line_array ( [split "\n",
"name	lower
log_state	0
probability_for_change_to_state
probability distribution
logged	0
min	-2.43
max	3.92
category_steps	10
scale21	1
noNull	1
duringReestimation	0
data
-2.43	-1.795	-2.1125	0.00846963229899565
-1.795	-1.16	-1.4775	0.0786156364482547
-1.16	-0.525	-0.8425	0.236731503972885
-0.525	0.11	-0.2075	0.270745456724196
0.11	0.745	0.4275	0.197151768956597
0.745	1.38	1.0625	0.133463869354021
1.38	2.015	1.6975	0.0423277022481217
2.015	2.65	2.3325	0.0157064776199589
2.65	3.285	2.9675	0.00677099817296522
3.285	3.92	3.6025	0.010016954203485
3.92	4.555	4.2375	5.19574272348929e-13
" ]);

@$value[0]->ProbabilityDistribution()->{title} = undef;
is_deeply(@$value[0], $expected_0, "state_values 'higher'"  );
@$value[1]->ProbabilityDistribution()->{title} = undef;
is_deeply(@$value[1], $expected_1, "state_values 'lower'"  );

$UMS->plot_states( $value, "$home/temp/ums_testScript_output" );

