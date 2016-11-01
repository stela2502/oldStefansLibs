#! /usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use Test::More tests => 40;
BEGIN { use_ok 'stefans_libs::statistics::HMM' }
## test for new
use stefans_libs::statistics::HMM::state_values;

my $home = File::HomeDir->my_home();

sub log2 {
	my ($value) = @_;
	return log($value) / log(2);
}

sub ScaleSumToOne {
	my ( $data, $logscale ) = @_;

	my ($i);

	die "test ScaleSumToOne no data present!" unless ( defined $data );

	$i = 0;
	if ( !defined $logscale ) {
		while ( my ( $key, $value ) = each %$data ) {
			$i += $value unless ( $key =~ m/ARRAY/ );
		}
		foreach my $value ( values %$data ) {
			$value = $value / $i;
		}
		$i = 0;
		while ( my ( $key, $value ) = each %$data ) {
			$i += $value unless ( $key =~ m/ARRAY/ );
		}
	}
	else {
		while ( my ( $key, $value ) = each %$data ) {
			$i += exp($value) unless ( $key =~ m/ARRAY/ );
		}
		foreach my $value ( values %$data ) {
			$value = log( exp($value) / $i );
		}
		$i = 0;
		while ( my ( $key, $value ) = each %$data ) {
			$i += exp($value) unless ( $key =~ m/ARRAY/ );
		}
	}
	$i = &ScaleSumToOne() unless ( $i > 0.99999 && $i < 1.000001 );
	return $data;
}

sub formatValue {
	my ( $value, $digits ) = @_;
	$digits = 2 unless ( defined $digits );
	if ( ref($value) eq "HASH" ) {
		foreach my $val ( values %$value ) {
			$val = formatValue( $val, $digits );
		}
		return $value;
	}
	elsif ( ref($value) eq "ARRAY" ) {
		for ( my $i = 0 ; $i < @$value ; $i++ ) {
			@$value[$i] = formatValue( @$value[$i], $digits );
		}
		return $value;
	}
	else {
		$value = 0 unless ( defined $value);
		return sprintf( "%." . $digits . "e", $value );
		return sprintf( "%.1e", $value ) if ( $digits == 1 );
		return sprintf( "%.2e", $value ) if ( $digits == 2 );
		die "use either 1 or 2 digits at HMM.t formatValue $!\n";
	}
}
my $hmm = HMM->new(1);

is_deeply( ref($hmm), "HMM", "simple test for object name eq 'HMM'" );

my ( $value, @values );
@values = ( log(5), log(8) );

$value = $hmm->Add2Logs(@values);

is_deeply( exp($value), 13, "Add2Logs" );

my @iceCreame =
  qw( 2 3 3 2 3 2 3 2 2 3 1 3 3 1 1 1 2 1 1 1 3 1 2 1 1 1 2 3 3 2 3 2 2 );

## check the states

my $C = state_values->new("C");
my $H = state_values->new("H");
my $R = state_values->new("R");

$value = $hmm->_check_and_prepareStates( [ $C, $H ] );

is_deeply(
	$value,
	"you have to set the startProbability for state C\n",
	"simple test for state_values integrity(startProbability)"
);

$C->{startProbability} = 0.5;
$H->{startProbability} = 0.5;
$R->{startProbability} = 0.5;

$value = $hmm->_check_and_prepareStates( [ $C, $H ] );
is_deeply(
	$value,
	"you have to set the endProbability for state C\n",
	"simple test for state_values integrity(endProbability)"
);

$C->{endProbability} = 0.1;
$H->{endProbability} = 0.1;
$R->{endProbability} = 0.1;

$value = $hmm->_check_and_prepareStates( [ $C, $H ] );
is_deeply(
	$value,
	"you have to set the probability for a change from C to C\n",
	"simple test for state_values integrity(probability for a change of states)"
);

$C->probability_for_change_to_state( "H", 0.1 );
$C->probability_for_change_to_state( "C", 0.8 );
$C->probability_for_change_to_state( "R", 0.1 );

$H->probability_for_change_to_state( "H", 0.8 );
$H->probability_for_change_to_state( "C", 0.1 );
$H->probability_for_change_to_state( "R", 0.1 );

$R->probability_for_change_to_state( "H", 0.1 );
$R->probability_for_change_to_state( "C", 0.1 );
$R->probability_for_change_to_state( "R", 0.8 );

$value = $hmm->_check_and_prepareStates( [ $C, $H ] );
is_deeply(
	$value,
	"no probabilityFunction available!\n",
"simple test for state_values integrity(state_values->{probabilityFunction} is not defined!!)"
);

my $probC = {
	1 => log 0.7,
	2 => log 0.2,
	3 => log 0.1
};

my $probH = {
	1 => log 0.1,
	2 => log 0.2,
	3 => log 0.7
};

my $probR = {
	1 => log 0.1,
	2 => log 0.8,
	3 => log 0.1
};

$C->createFixedDataset($probC);
$H->createFixedDataset($probH);
$R->createFixedDataset($probR);

$value = $hmm->_check_and_prepareStates( [ $C, $H, $R ] );
is_deeply(
	[ $value, $hmm->{error} ],
	[ undef,  undef ],
	"finally everything went well (no errors)"
);

my ( $C_save, $H_save );

$C_save = $C->export();
$H_save = $H->export();
## recover using $C->import_from_line_array([split("\n", $C_save)]);

#print "two possible state_value strings:\n1:\n$C_save\n2:\n$H_save\n";

my @hashes;
for ( my $i = 0 ; $i < @iceCreame ; $i++ ) {
	if ( $i < 31 ) {
		push( @hashes,
			{ iceCones => $iceCreame[$i], day => $i, month => 'january' } );
	}
	else {
		push( @hashes,
			{ iceCones => $iceCreame[$i], day => $i, month => 'february' } );
	}
}

$hmm->CalculateHMM(
	{
		states       => [ $C, $H, $R ],
		'values'     => [@hashes],
		'value_tag'  => 'iceCones',
		'path'       => "$home/temp",
		'file_base'  => "test_HMM_InternalStates",
		'iterations' => 10
	}
);
$C->import_from_line_array( [ split( "\n", $C_save ) ] );
$H->import_from_line_array( [ split( "\n", $H_save ) ] );

$value = $hmm->initMarcowChains( { 'values' => [@hashes] } );

is_deeply(
	$hmm->{error},
	"the class has changed! we need a value_tag and order_tags\n",
	"error if a array of hashes without an value_tag is given"
);

$value = $hmm->initMarcowChains(
	{ states => [ $C, $H ], 'values' => [@hashes], value_tag => 'iceCones' } );

is_deeply( scalar(@$value), 1,
"HMM initMarcowChains with an array of hashes and the right value_tag returns one marcow chain"
);

is_deeply( scalar( @{ @$value[0]->{'values'} } ),
	33, "in addition the right amount of data inserted!" );

my $sorter = SORTER->new();

$value = $hmm->initMarcowChains(
	{
		states     => [ $C, $H ],
		'values'   => [@hashes],
		value_tag  => 'iceCones',
		order_tags => ['month']
	}
);

is_deeply(
	$hmm->{error},
"together with an oder_tag, we need the info how to split the dataset into marcow lines! (splitFunction)\n",
	"with an order_tag and without splitFunction we get the right error"
);

$value = $hmm->initMarcowChains(
	{
		states        => [ $C, $H ],
		'values'      => [@hashes],
		value_tag     => 'iceCones',
		order_tags    => ['month'],
		splitFunction => $sorter
	}
);

is_deeply( $hmm->{error}, undef,
	"with an order_tag and with a splitFunction we get the no error" );

is_deeply( scalar(@$value), 2, "we get the expected two marcow chains" );

$C = undef;
$H = undef;
$C = state_values->new("C");
$H = state_values->new("H");

$C->{startProbability} = 0.5;
$H->{startProbability} = 0.5;

$C->{endProbability} = 0.1;
$H->{endProbability} = 0.1;

$C->probability_for_change_to_state( "H", 0.1 );
$C->probability_for_change_to_state( "C", 0.8 );

$H->probability_for_change_to_state( "H", 0.8 );
$H->probability_for_change_to_state( "C", 0.1 );

$probC = {
	1 => 0.7,
	2 => 0.2,
	3 => 0.1
};

$probH = {
	1 => 0.1,
	2 => 0.2,
	3 => 0.7
};

$C->createFixedDataset($probC);
$H->createFixedDataset($probH);

$C->_setLogState2(1);
$H->_setLogState2(1);

$value =
  $hmm->initMarcowChains( { states => [ $C, $H ], 'values' => [@iceCreame] } );

is_deeply( scalar(@$value), 1,
	"simple marcow Chain one array of values returns one marcow chain" );

is_deeply( scalar( @{ @$value[0]->{'values'} } ),
	33, "the right amount of data is also inserted!" );

## here we have to import the values from the eisner.hmm.xls sheet - do not expect them to be too correct!
## they do not use a log and I do not think excel is too correct...

my (
	$i,                  @data,               @forward_C,
	@forward_H,          @backward_C,         @backward_H,
	@totalProbThrough_C, @totalProbThrough_H, @totalProb,
	@prob_C,             @prob_H,             @C_to_H,
	@C_to_C,             @H_to_C,             @H_to_H,
	$filename
);

$filename = "../t/data/hmm_test_data_transposed.txt";
$filename = "t/data/hmm_test_data_transposed.txt"
  if ( -f "t/data/hmm_test_data_transposed.txt" );
unless ( -f $filename ) { system("ls -lh"); }
open( DATA, "<$filename" )
  or die "could not open HMM data file $filename\n";

@data = (<DATA>);
close(DATA);
for ( $i = 0 ; $i < @data ; $i++ ) {
	$data[$i] =~ s/,/\./g;
}
@forward_C = split( "\t", $data[0] );
shift @forward_C;
for ( $i = 0 ; $i < @forward_C ; $i++ ) {
	$forward_C[$i] = sprintf( "%.2e", $forward_C[$i] );
}
@forward_H = split( "\t", $data[1] );
shift @forward_H;
for ( $i = 0 ; $i < @forward_H ; $i++ ) {
	$forward_H[$i] = sprintf( "%.2e", $forward_H[$i] );
}
@backward_C = split( "\t", $data[2] );
shift @backward_C;
for ( $i = 0 ; $i < @backward_C ; $i++ ) {
	$backward_C[$i] = sprintf( "%.2e", $backward_C[$i] );
}
@backward_H = split( "\t", $data[3] );
shift @backward_H;
for ( $i = 0 ; $i < @backward_H ; $i++ ) {
	$backward_H[$i] = sprintf( "%.2e", $backward_H[$i] );
}
@totalProbThrough_C = split( "\t", $data[4] );
shift @totalProbThrough_C;
for ( $i = 0 ; $i < @totalProbThrough_C ; $i++ ) {
	$totalProbThrough_C[$i] = sprintf( "%.2e", $totalProbThrough_C[$i] );
}
@totalProbThrough_H = split( "\t", $data[5] );
shift @totalProbThrough_H;
for ( $i = 0 ; $i < @totalProbThrough_H ; $i++ ) {
	$totalProbThrough_H[$i] = sprintf( "%.2e", $totalProbThrough_H[$i] );
}
@totalProb = split( "\t", $data[6] );
shift @totalProb;
for ( $i = 0 ; $i < @totalProb ; $i++ ) {
	$totalProb[$i] = sprintf( "%.2e", $totalProb[$i] );
}
@prob_C = split( "\t", $data[7] );
shift @prob_C;
for ( $i = 0 ; $i < @prob_C ; $i++ ) {
	$prob_C[$i] = sprintf( "%.2e", $prob_C[$i] );
}
@prob_H = split( "\t", $data[8] );
shift @prob_H;
for ( $i = 0 ; $i < @prob_H ; $i++ ) {
	$prob_H[$i] = sprintf( "%.2e", $prob_H[$i] );
}
@C_to_H = split( "\t", $data[11] );

shift @C_to_H;
shift @C_to_H;
for ( $i = 0 ; $i < @C_to_H ; $i++ ) {
	$C_to_H[$i] = sprintf( "%.2e", $C_to_H[$i] );
}
@C_to_C = split( "\t", $data[9] );
shift @C_to_C;
shift @C_to_C;
for ( $i = 0 ; $i < @C_to_C ; $i++ ) {
	$C_to_C[$i] = sprintf( "%.2e", $C_to_C[$i] );
}
@H_to_C = split( "\t", $data[10] );
shift @H_to_C;
shift @H_to_C;
for ( $i = 0 ; $i < @H_to_C ; $i++ ) {
	$H_to_C[$i] = sprintf( "%.2e", $H_to_C[$i] );
}
@H_to_H = split( "\t", $data[12] );
shift @H_to_H;
shift @H_to_H;
for ( $i = 0 ; $i < @H_to_H ; $i++ ) {
	$H_to_H[$i] = sprintf( "%.2e", $H_to_H[$i] );
}

@$value[0]->CalculateForwardProbability();

$i    = @$value[0]->{forwardResults}->{C};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@forward_C], "forward values state 'C'" );

$i    = @$value[0]->{forwardResults}->{H};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@forward_H], "forward values state 'H'" );

@$value[0]->CalculateBackwardProbability();

$i    = @$value[0]->{backwardResults}->{C};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@backward_C], "backward values state 'C'" );

$i    = @$value[0]->{backwardResults}->{H};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@backward_H], "backward values state 'H'" );

@$value[0]->CalculateTotalProbabilityFromStartToEnd();

#$i = @$value[0]->{A_H}->{C};
#@data = ();
#foreach my $key ( @$i ){
#	push (@data, sprintf("%.2e", exp($key)));
#}
#is_deeply ( [@data], [@totalProbThrough_C], "Total prob of all paths from START to STOP that pass through state C after emitting the ice cream data to date and before emitting the rest of it.");
#
#$i = @$value[0]->{A_H}->{H};
#@data = ();
#foreach my $key ( @$i ){
#	push (@data, sprintf("%.2e", exp($key)));
#}
#is_deeply ( [@data], [@totalProbThrough_H], "Total prob of all paths from START to STOP that pass through state H after emitting the ice cream data to date and before emitting the rest of it.");

$i    = @$value[0]->{C};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@totalProb],
	"probability for either C or H from start to end" );

$i    = @$value[0]->{p_H}->{C};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@prob_C], "probability values state 'C'" );

$i    = @$value[0]->{p_H}->{H};
@data = ();
foreach my $key (@$i) {
	push( @data, sprintf( "%.2e", exp($key) ) );
}
is_deeply( [@data], [@prob_H], "probability values state 'H'" );

## the calculation has to be checked if the results of the reiteration are not correct!

## now we have recapitulated one $hmm->_calculateOneIteration() run!
## now we have to check the function ReestimateMarkowModel ....
## first set the debug entry in hmm

$hmm    = undef;
$hmm    = HMM->new(1);
@hashes = ();
for ( my $i = 0 ; $i < @iceCreame ; $i++ ) {
	push( @hashes, { iceCones => $iceCreame[$i], day => $i } );
}

#$hmm->CalculateHMM(
#	{
#		states     => [ $C, $H ],
#		'values'     => [@hashes],
#		'value_tag'  => 'iceCones',
#		'path'       => '/home/stefan_l/temp',
#		'file_base'  => "test_HMM_InternalStates",
#		'iterations' => 10
#	}
#);

$value = $hmm->initMarcowChains(
	{ states => [ $C, $H ], 'values' => [@hashes], value_tag => 'iceCones' } );

$hmm->_calculateOneIteration($value);

## do we have a problem with our state_values objects??

is_deeply( [ $C, $H ], $hmm->{states}, "the hmm states" );

$C->{probHist}->initReestimation();
$H->{probHist}->initReestimation();

#print "\nNOW and only NOW we want to reestimate the probability values!\n";

my $return = $hmm->ReestimateMarkowModel($value);

$i = @$value[0]->{'C to C'};
shift @$i;
for ( my $a = 0 ; $a < @$i ; $a++ ) { @$i[$a] = exp( @$i[$a] ) }
is_deeply(
	formatValue( $i,       1 ),
	formatValue( \@C_to_C, 1 ),
	"reestimate C to C transmission probabilites (array of values)"
);

$i = @$value[0]->{'C to H'};
shift @$i;
for ( my $a = 0 ; $a < @$i ; $a++ ) { @$i[$a] = exp( @$i[$a] ) }
formatValue( $i, 2 );
is_deeply(
	formatValue( $i,       2 ),
	formatValue( \@C_to_H, 2 ),
	"reestimate C to H transmission probabilites (array of values)"
);

$i = @$value[0]->{'H to C'};
shift @$i;
for ( my $a = 0 ; $a < @$i ; $a++ ) { @$i[$a] = exp( @$i[$a] ) }
is_deeply(
	formatValue( $i,       1 ),
	formatValue( \@H_to_C, 1 ),
	"reestimate H to C transmission probabilites (array of values)"
);

$i = @$value[0]->{'H to H'};
shift @$i;
for ( my $a = 0 ; $a < @$i ; $a++ ) { @$i[$a] = exp( @$i[$a] ) }
is_deeply(
	formatValue( $i,       2 ),
	formatValue( \@H_to_H, 2 ),
	"reestimate H to H transmission probabilites (array of values)"
);

$return = formatValue( $return, 1 );

$i = {
	'C to C'   => log(12.855),
	'C to H'   => log(1.6),
	'H to C'   => log(1.695),
	'H to H'   => log(15.85),
	'p_values' => {
		'C' => {
			1 => 9.931 / ( 9.931 + 3.212 + 1.537 ),
			2 => 3.212 / ( 9.931 + 3.212 + 1.537 ),
			3 => 1.537 / ( 9.931 + 3.212 + 1.537 )
		},
		'H' => {
			1 => 6.0e-02,
			2 => 4.2e-01,
			3 => 9.46339800724926 /
			  ( 1.06942172061572 + 7.78788485438246 + 9.46339800724926 )
		}
	},
	'old p_values' => {
		'C' => {
			1 => log(0.7),
			2 => log(0.2),
			3 => log(0.1)
		},
		'H' => {
			1 => log(0.1),
			2 => log(0.2),
			3 => log(0.7)
		}
	},
	'p_summary_values' => {
		'C' => 14.679,
		'H' => 18.321,
	},
	'reestimations' => {
		"C to C" => 8.8E-001,
		"C to H" => 9.1E-002,
		"H to C" => 1.1E-001,
		"H to H" => 8.7E-001
	}
};


$i = formatValue( $i, 1 );

is_deeply(
	formatValue( ScaleSumToOne( $return->{'p_values'}->{'H'} ), 1 ),
	formatValue( $i->{'p_values'}->{'H'},                       1 ),
	"probability function H"
);
is_deeply(
	formatValue( ScaleSumToOne( $return->{'p_values'}->{'C'} ), 1 ),
	formatValue( $i->{'p_values'}->{'C'},                       1 ),
	"probability function C"
);

is_deeply(
	formatValue( exp( $return->{'p_summary_values'}->{'H'} ), 1 ),
	formatValue( $i->{'p_summary_values'}->{'H'},             1 ),
	"summary probability H"
);
is_deeply(
	formatValue( exp( $return->{'p_summary_values'}->{'C'} ), 1 ),
	formatValue( $i->{'p_summary_values'}->{'C'},             1 ),
	"summary probability C"
);
is_deeply( $return->{'C to C'}, $i->{'C to C'}, "transition C -> C" );

is_deeply(
	formatValue( $return->{'C to H'}, 2 ),
	formatValue( $i->{'C to H'},      2 ),
	"transition C -> H"
);
is_deeply(
	formatValue( $return->{'H to H'}, 2 ),
	formatValue( $i->{'H to H'},      2 ),
	"transition H -> H"
);
is_deeply(
	formatValue( $return->{'H to C'}, 2 ),
	formatValue( $i->{'H to C'},      2 ),
	"transition H -> C"
);
is_deeply(
	formatValue( exp( $return->{'reestimations'}->{"C to C"} ), 1 ),
	formatValue( $i->{'reestimations'}->{"C to C"}, 1 ),
	"reestimation C to C"
);
is_deeply(
	formatValue( exp( $return->{'reestimations'}->{"C to H"} ), 1 ),
	formatValue( $i->{'reestimations'}->{"C to H"}, 1 ),
	"reestimation C to H"
);
is_deeply(
	formatValue( exp( $return->{'reestimations'}->{"H to C"} ), 1 ),
	formatValue( $i->{'reestimations'}->{"H to C"}, 1 ),
	"reestimation H to C"
);
is_deeply(
	formatValue( exp( $return->{'reestimations'}->{"H to H"} ), 1 ),
	formatValue( $i->{'reestimations'}->{"H to H"}, 1 ),
	"reestimation H to H"
);

## and now - some dice data
#die "no dice data\n$!\n";

#$filename = "data/random_dice.csv";
#$filename = "t/data/random_dice.csv" if ( -f "t/data/random_dice.csv");
#
#open (DATA, "<$filename") or die "could not open filename $filename\n";
#@data = ( <DATA>);
#close (DATA);
#chomp $data[0];
#@values = split ( "\t", $data[0]);
#
#$probC = {
#	1 => 1,
#	2 => 1,
#	3 => 1,
#	4 => 1,
#	5 => 1,
#	6 => 1
#};
#
#$probH = {
#	1 => 1,
#	2 => 1,
#	3 => 1,
#	4 => 1,
#	5 => 1,
#	6 => 1.2
#};
#
#$C = state_values->new( "OK");
#$H = state_values->new("gezinkt");
#
#$C->{startProbability} = 0.5;
#$H->{startProbability} = 0.5;
#$value = $C->probability_for_change_to_state( "gezinkt", 0.01 );
#$C->probability_for_change_to_state( "OK", 0.8 );
#$H->probability_for_change_to_state( "gezinkt", 0.8 );
#$H->probability_for_change_to_state( "OK", 0.01 );
#
#$C->{startProbability} = 0.5;
#$H->{startProbability} = 0.5;
#
#$C->{endProbability} = 0.1;
#$H->{endProbability} = 0.1;
#
#$C->createFixedDataset($probC);
#$H->createFixedDataset($probH);
#
#$C->Log_state(1);
#$H->Log_state(1);
#
#$hmm->CalculateHMM ({
#	'states' => [ $C, $H ],
#	'values' => \@values,
#	'path'       => '/home/stefan_l/temp',
#	'file_base'  => "test_HMM_Dice",
#	'iterations' => 10
#});
#
##$hmm->CalculateHMM(
##	{
##		states     => [ $C, $H ],
##		'values'     => [@hashes],
##		'value_tag'  => 'iceCones',
##		'path'       => '/home/stefan_l/temp',
##		'file_base'  => "test_HMM_InternalStates",
##		'iterations' => 10
##	}
##);

package SORTER;

sub new {
	my $self = {};
	bless $self, 'SORTER';
	return $self;
}

sub Sort {
	my ( $self, $old_value1, $value1 ) = @_;

	return 1 unless ( defined $old_value1 );
	return 1 unless ( defined $value1 );
	return 1 if ( !( $old_value1 eq $value1 ) );
	return 0;
}
1;
