#! /usr/bin/perl -w

#  Copyright (C) 2011-11-25 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 model_recombination.pl

This tool should be a simple statistical automat that does model VDJh recombination and the outcome.

To get further help use 'model_recombination.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::variable_table;
use stefans_libs::flexible_data_structures::data_table;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $prob_fam1, @settings, $rounds, $outfile );

Getopt::Long::GetOptions(
	"-prob_fam1=s"    => \$prob_fam1,
	"-rounds=s"       => \$rounds,
	"-outfile=s"      => \$outfile,
	"-selection=s{,}" => \@settings,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

###################################################
#### SETTINGS #####################################
###################################################
my $amp_04 = 3;     ## amplifikationsrate für 40% der produktiven VDJ's
my $amp_08 = 8;     ## amplifikationsrate für weitere 40% der produktiven VDJ's
my $amp_10 = 15;    ## amplifikationsrate für weitere 20% der produktiven VDJ's
my $default_rounds = 1e3;
###################################################
###################################################
###################################################

$amp_04 = $settings[0] if ( defined $settings[0] );
$amp_08 = $settings[1] if ( defined $settings[1] );
$amp_10 = $settings[2] if ( defined $settings[2] );

my $explains = {
	52 => "WT proB 1",

	35 => "TW proB 2",

	42 => "WT proB 3",

	86 => "KO proB 1",

	56 => "KO proB 2",

	153 => "KO proB 3",

};

my $exp = {};
foreach ( keys %$explains ) {
	for ( my $i = $_ - 4 ; $i <= $_ + 4 ; $i++ ) {
		$exp->{$i} = $explains->{$_};
	}
}
$explains = $exp;

unless ( defined $prob_fam1 ) {
	$error .= "the cmd line switch -prob_fam1 is undefined!\n";
}

unless ( defined $rounds ) {
	$rounds = $default_rounds;
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for model_recombination.pl

   -prob_fam1    :stepwidth to modify the fam1 probabillity
   -rounds       :overwrite the default rounds setting
   -outfile      :specify a outfile
   -selection    : 40% aplification rate (3) 40% amplification rate (8) 20% amplification rate (15)
   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/model_recombination.pl';
$task_description .= " -prob_fam1 $prob_fam1" if ( defined $prob_fam1 );
$task_description .= " -rounds $rounds"       if ( defined $rounds );
$task_description .= " -outfile $outfile"     if ( defined $outfile );
$task_description .= " -selection " . join( " ", @settings )
  if ( defined $settings[0] );
open( LOG, ">$outfile.log" ) or die "I could not create the log file\n$!\n";
print LOG $task_description;
close(LOG);

## Do whatever you want!

my $result = data_table->new();
if ( -f $outfile ) {
	$result->read_file($outfile);
}
else {
	foreach (
		'Time',
		'prob fam 1',
		'selection 40% 1',
		'selection 40% 2',
		'selection 20%',
		'double 0',
		'1 Allele rec',
		'2 Alleles rec',
		'Fam1 productive',
		'Fam2 productive',
		'Fam1 not productive',
		'Fam2 not productive',
		'fraction +/-',
		'match'
	  )
	{
		$result->Add_2_Header($_);
	}
}
my $matche_table = data_table->new();
if ( -f "$outfile.match.xls" ) {
	$matche_table->read_file("$outfile.match.xls");
}
else {
#Carp::confess ( "Hey - the file '$outfile.match.xls' does really not exist??");
	foreach (
		'selection 40% 1',
		'selection 40% 2',
		'selection 20%',
		'matches',
		values %$explains
	  )
	{
		$matche_table->Add_2_Header($_);
	}
}
my $done = 0;
my $amplicication_rates = {
	'J558_A' => 3,
	'J558_B' => 6,
	'j558_C' => 12,
	'other_A' => 1,
	'other_B' => 3,
	'other_C' => 6,
};

my ( $summary_result, $temp );
if ( scalar(@settings) == 3 ) {
	$summary_result = {
		'selection 40% 1' => $settings[0],
		'selection 40% 2' => $settings[1],
		'selection 20%'   => $settings[2],
	};
	$temp = 0;
	foreach (
		&calculate_for_selection( $settings[0], $settings[1], $settings[2] ) )
	{
		if ( defined $summary_result->{ $_->{'type'} } ) {
			$summary_result->{ $_->{'type'} } .= "; $_->{'probabillity'}";
			next;
		}
		$summary_result->{ $_->{'type'} } = $_->{'probabillity'};
		$temp++;
	}
	$summary_result->{'matches'} = $temp;
	$matche_table->AddDataset($summary_result);
	if ( $summary_result->{'matches'} == 6 ) {
		print "We are DONE!!\n";
		last ROOT;
	}
	print "done with $settings[0] - $settings[1] - $settings[2]\n";
}
else {
  ROOT: for ( my $a = 0 ; $a < 20 ; $a += 2 ) {
		for ( my $b = 0 ; $b < 40 ; $b += 2 ) {
			for ( my $c = 0 ; $c < 60 ; $c += 2 ) {
				$summary_result = {
					'selection 40% 1' => $a,
					'selection 40% 2' => $b,
					'selection 20%'   => $c,
				};
				$temp = 0;
				foreach ( &calculate_for_selection( $a, $b, $c ) ) {
					if ( defined $summary_result->{ $_->{'type'} } ) {
						$summary_result->{ $_->{'type'} } .=
						  "; $_->{'probabillity'}";
						next;
					}
					$summary_result->{ $_->{'type'} } = $_->{'probabillity'};
					$temp++;
				}
				$summary_result->{'matches'} = $temp;
				$matche_table->AddDataset($summary_result);
				print "done with $a - $b - $c\n";
				if ( $summary_result->{'matches'} == 6 ) {
					print "We are DONE!!\n";
					last ROOT;
				}
			}
		}
	}
}

$matche_table->write_file("$outfile.match.xls");
$result->write_file($outfile);

sub calculate_for_selection {
	my ( $amp_04, $amp_08, $amp_10 ) = @_;
	my @return;
	for ( my $i = $prob_fam1 ; $i < 0.51 ; $i += $prob_fam1 ) {
		push( @return, &calculate_4_fam1_prob($i) );
	}
	my $ok;
	foreach (@return) {
		$ok->{$_} = 1;
	}
	$done = 1 if ( scalar( ( keys %$ok ) ) == 6 );
	return @return;
}

sub calculate_4_fam1_prob {
	my $fam1 = shift;

	my $hash = {
		'Time' => DateTime::Format::MySQL->format_datetime(
			DateTime->now()->set_time_zone('Europe/Berlin')
		),
		'prob fam 1'          => $fam1,
		'selection 40% 1'     => $amp_04,
		'selection 40% 2'     => $amp_08,
		'selection 20%'       => $amp_10,
		'1 Allele rec'        => 0,
		'2 Alleles rec'       => 0,
		'double 0'            => 0,
		'Fam1 productive'     => 0,
		'Fam2 productive'     => 0,
		'Fam1 not productive' => 0,
		'Fam2 not productive' => 0,
		'fraction +/-'        => undef,
		'match'               => '',
	};
	my $data;
	my $rand;
	for ( my $i = 0 ; $i < $rounds ; $i++ ) {
		$data = &calc_one($fam1);
		unless ( defined $data ) {
			$hash->{'double 0'}++;
			next;
		}
		## now I add a random amplification step into the system
		$rand = rand();
		if ( $rand > 0.2 ) {
			&process_data( $hash, $data , $amp_04);

		}
		elsif ( $rand > 0.4 ) {
			&process_data( $hash, $data, $amp_08 );

		}
		elsif ( $rand > 0.8 ) {
			&process_data( $hash, $data, $amp_10 );
		}
		else {
			&process_data( $hash, $data, 'none' );
		}
	}
	my @match;
	$hash->{'Fam1 not productive'} = 1
	  if ( $hash->{'Fam1 not productive'} == 0 );
	$hash->{'fraction +/-'} = int(
		( $hash->{'Fam1 productive'} / $hash->{'Fam1 not productive'} ) * 100 )
	  / 100;
	if ( defined $explains->{ int( $hash->{'fraction +/-'} * 100 ) } ) {
		$hash->{'match'} = $explains->{ int( $hash->{'fraction +/-'} * 100 ) };
		print root::get_hashEntries_as_string ( $hash, 3,
			"this run ended like that:" );
		push( @match, { 'type' => $hash->{'match'}, 'probabillity' => $fam1 } );
	}

	#else {
	#print "No match to fraction "
	#  . int( $hash->{'fraction +/-'} * 100 ) . "\n";
	#}
	$result->AddDataset($hash);
	return (@match);
}

sub process_data {
	my ( $hash, $data, $type ) = @_;
	if ($type eq "none" ){
		&stuff_data(  $hash, $data );
		return;
	}
	if ( $data ->{'Fam1 productive'} == 1 ){
		## J558 Recombination!
		for ( my $i = 0; $i < $type; $i ++ ){
			&stuff_data(  $hash, $data );
		}	
	}
	else {		
		## other recombination
		for ( my $i = 0; $i < $type * 0.5 ; $i ++ ){
			&stuff_data(  $hash, $data );
		}
	}
	return 1;
}

sub stuff_data {
	my ( $hash, $data ) = @_;
	foreach (
		'1 Allele rec',
		'2 Alleles rec',
		'Fam1 productive',
		'Fam2 productive',
		'Fam1 not productive',
		'Fam2 not productive'
	  )
	{

		#warn "$_ not defined in data" unless ( defined $data->{$_});
		#warn "$_ not defined in hash" unless ( defined $hash->{$_});
		$hash->{$_} += $data->{$_};
	}
}

sub calc_one {
	my ($prob_fam1) = @_;
	my $hash = {
		'1 Allele rec'        => 0,
		'2 Alleles rec'       => 0,
		'Fam1 productive'     => 0,
		'Fam2 productive'     => 0,
		'Fam1 not productive' => 0,
		'Fam2 not productive' => 0
	};
	## choose a active family
	my $rand;
	$rand = rand();

	#print "$rand\n";
	if ( $rand > $prob_fam1 ) {
		$rand = rand();
		if ( $rand > 0.66 ) {
			$hash->{'Fam2 productive'}++;
			$hash->{'1 Allele rec'} = 1;
			return $hash;
		}
		else {
			$hash->{'Fam2 not productive'}++;
			$hash->{'1 Allele rec'} = 1;
		}
	}
	else {
		$rand = rand();
		if ( $rand > 0.66 ) {
			$hash->{'Fam1 productive'}++;
			$hash->{'1 Allele rec'} = 1;
			return $hash;
		}
		else {
			$hash->{'Fam1 not productive'}++;
			$hash->{'1 Allele rec'} = 1;
		}
	}

	#print "We check an other allele:\n";
	## The other allele
	$rand = rand();
	if ( $rand > $prob_fam1 ) {
		$rand = rand();
		if ( $rand > 0.66 ) {
			$hash->{'Fam2 productive'}++;
			$hash->{'2 Alleles rec'} = 1;
			return $hash;
		}
		else {
			$hash->{'Fam2 not productive'}++;
			$hash->{'2 Alleles rec'} = 1;
		}
	}
	else {
		$rand = rand();
		if ( $rand > 0.66 ) {
			$hash->{'Fam1 productive'}++;
			$hash->{'2 Alleles rec'} = 1;
			return $hash;
		}
		else {
			$hash->{'Fam1 not productive'}++;
			$hash->{'2 Alleles rec'} = 1;
		}
	}
	return undef;
	return $hash;
}
