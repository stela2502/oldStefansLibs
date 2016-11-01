#! /usr/bin/perl -w

#  Copyright (C) 2010-06-07 Stefan Lang

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

=head1 test_for_T2D_predictive_value.pl

A first script to test for the possibillity of a SNP to predict for T2D out come.

To get further help use 'test_for_T2D_predictive_value.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::array_analysis::correlatingData::SpearmanTest;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,     $debug,            $database, $phenotype_file,
	$T2D_name, @other_phenotypes, $outfile,  $phenotype_column
);

Getopt::Long::GetOptions(
	"-phenotype_file=s"      => \$phenotype_file,
	"-T2D_name=s"            => \$T2D_name,
	"-other_phenotypes=s{,}" => \@other_phenotypes,
	"-outfile=s"             => \$outfile,
	"-phenotype_column=s"    => \$phenotype_column,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $phenotype_file ) {
	$error .= "the cmd line switch -phenotype_file is undefined!\n";
}
unless ( defined $T2D_name ) {
	$error .= "the cmd line switch -T2D_name is undefined!\n";
}
unless ( defined $other_phenotypes[0] ) {
	$error .= "the cmd line switch -other_phenotypes is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $phenotype_column ) {
	$phenotype_column = 'rs_id';
	$warn .= "We have set the phenotype_column tp 'rs_id'\n";
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
 command line switches for test_for_T2D_predictive_value.pl

   -phenotype_file       :<please add some info!>
   -T2D_name       :<please add some info!>
   -other_phenotypes       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>
   -phenotype_column       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'test_for_T2D_predictive_value.pl';
$task_description .= " -phenotype_file $phenotype_file"
  if ( defined $phenotype_file );
$task_description .= " -T2D_name $T2D_name" if ( defined $T2D_name );
$task_description .= ' -other_phenotypes ' . join( ' ', @other_phenotypes )
  if ( defined $other_phenotypes[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -phenotype_column $phenotype_column"
  if ( defined $phenotype_column );

print "my cmd:\n$task_description\n";
## Do whatever you want!

my ( $phenotype_table, $stat_test );
$phenotype_table = data_table->new();
$phenotype_table->read_file($phenotype_file);
$phenotype_table->createIndex($phenotype_column);
$stat_test = SpearmanTest->new();
for ( my $i = 0 ; $i < @other_phenotypes ; $i++ ) {
	&estimate_effect_of_genotype_on_phenotype(
		$phenotype_table->get_line_asHash($phenotype_table->get_rowNumbers_4_columnName_and_Entry( $phenotype_column, $other_phenotypes[$i] )),
		$phenotype_table->get_line_asHash($phenotype_table->get_rowNumbers_4_columnName_and_Entry( $phenotype_column, $T2D_name )),
		$phenotype_column
	);
}

=head2 estimate_effect_of_genotype_on_phenotype

The function will group the samples into genotypes (AA, AB, BB) and will then 
calculate a 'easy' statistics on the dataset, a linear correlation (pearson).
Hope that will help!

=cut

sub estimate_effect_of_genotype_on_phenotype {
	my ( $genotype_hash, $phenotype_hash, $description_key ) = @_;
	
#	die root::get_hashEntries_as_string ($genotype_hash, 3, "genotype_hash").
#	root::get_hashEntries_as_string ($phenotype_hash, 3, "phenotype_hash")."\n";
	
	my $matrix = __get_affection_matrix( $genotype_hash, $phenotype_hash,
		$description_key );
	## now I want to calculate the difference from the expected
	
	my ( $p_T2D, $sum_NHD, $sum_T2D );
	$sum_NHD = $sum_T2D = 0;
	foreach (qw(AA AB BB)) {
		$sum_NHD += $matrix->{$_}->{'NHD'};
		$sum_T2D += $matrix->{$_}->{'T2D'};
	}
	$p_T2D = $sum_T2D / ( $sum_NHD + $sum_T2D );
	my $return = { 'AA' => 0, 'AB' => 0, 'BB' => 0 };
	foreach (qw(AA AB BB)) {
#		print "we calculate $_:\n".
#		"$p_T2D * ( $matrix->{$_}->{'NHD'} + $matrix->{$_}->{'T2D'} ) -
#		  $matrix->{$_}->{'T2D'}\n";
		$return->{$_} =
		  $p_T2D * ( $matrix->{$_}->{'NHD'} + $matrix->{$_}->{'T2D'} ) -
		  $matrix->{$_}->{'T2D'};
	}
	
	print "stat test for $phenotype_hash->{$description_key}:\n"
	  . "AA\tAB\tBB\n"
	  . "$return->{'AA'}\t$return->{'AB'}\t$return->{'BB'}\n"
	  . "p value\traw_value\trho\n";
	my $data = $stat_test->_calculate_spearmanWeightFit_statistics( [ 1, 2, 3 ],
		[ $return->{'AA'}, $return->{'AB'}, $return->{'BB'} ] )
	  . "\n";
	print $data. "\n";
	my @data = split( "\t", $data );
	$return->{'p_value'}   = $data[0];
	$return->{'raw_value'} = $data[1];
	$return->{'rho'}       = $data[2];
	return $return;
}

sub __get_affection_matrix {
	my ( $genotype_hash, $phenotype_hash, $description_key ) = @_;
	my $genotype_groups =
	  &__determine_genotype_groups( $genotype_hash, $description_key );
	my ($matrix);
	$matrix = {
		'AA' => { 'NHD' => 0, 'T2D' => 0 },
		'AB' => { 'NHD' => 0, 'T2D' => 0 },
		'BB' => { 'NHD' => 0, 'T2D' => 0 }
	};
	while ( my ( $key, $value ) = each %$phenotype_hash ) {
		next unless ( defined $value );
		next unless ( $value =~ /\d/ );
		if ( $genotype_groups->{'AA'}->{$key} ) {
			if ( $value == 1 ) {
				$matrix->{'AA'}->{'NHD'}++;
			}
			else {
				$matrix->{'AA'}->{'T2D'}++;
			}
		}
		elsif ( $genotype_groups->{'AB'}->{$key} ) {
			if ( $value == 1 ) {
				$matrix->{'AB'}->{'NHD'}++;
			}
			else {
				$matrix->{'AB'}->{'T2D'}++;
			}
		}
		elsif ( $genotype_groups->{'BB'}->{$key} ) {
			if ( $value == 1 ) {
				$matrix->{'BB'}->{'NHD'}++;
			}
			else {
				$matrix->{'BB'}->{'T2D'}++;
			}
		}
	}
	return $matrix;
}

sub __determine_genotype_groups {
	my ( $genotype_hash, $description_key ) = @_;
	my ( $data, $major, $minor );
	
	while ( my ( $key, $value ) = each %$genotype_hash ) {
		next if ( $key eq $description_key );
		next if ( $value eq "/" );
		#print " key '$key' is not '$description_key'\n";
		$data->{$value} = {} unless ( ref( $data->{$value} ) eq "HASH" );
		$data->{$value}->{$key} = 1;
		unless ( $value =~ m/(\w)\/(\w)/ ) {
			Carp::confess(
"Sorry, but the genotype $key ($value) does not have the right format (A/B)\n"
			);
		}
		else {
			unless ( $1 eq $2 ) {
				$major = $1;
				$minor = $2;
			}
		}
	}
	unless ( defined $data->{"$major/$major"} ) {
		Carp::confess(
			"sorry, but we could not determine major and minor allele! ($major , $minor)\n");
	}
	my $return = {
		'AA' => $data->{"$major/$major"},
		'BB' => $data->{"$minor/$minor"},
		'AB' => $data->{"$major/$minor"}
	};
	#print root::get_hashEntries_as_string ($return, 3, "__determine_genotype_groups will return");
	return $return;
}
