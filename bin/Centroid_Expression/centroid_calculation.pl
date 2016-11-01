#! /usr/bin/perl -w

#  Copyright (C) 2010-12-10 Stefan Lang

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

=head1 centroid_calculation.pl

A script to read an expression array dataset and calculate the mean centroid for a set of genes.

To get further help use 'centroid_calculation.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::affymetrix_expression_result;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $expression_data, @genes, $outfile, @p4cS,
	$random_sets );

Getopt::Long::GetOptions(
	"-expression_data=s" => \$expression_data,
	"-genes=s{,}"        => \@genes,
	"-outfile=s"         => \$outfile,
	"-p4cS=s{,}"         => \@p4cS,
	"-random_sets=s"     => \$random_sets,
	"-help"              => \$help,
	"-debug"             => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $expression_data ) {
	$error .= "the cmd line switch -expression_data is undefined!\n";
}
unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $p4cS[0] ) {
	$error .= "the cmd line switch -p4cS is undefined!\n";
}
unless ( defined $random_sets ) {
	$random_sets = 0;
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
 command line switches for centroid_calculation.pl

   -expression_data  :the expression estimates file
   -genes            :the genes of interest (GOI) as list or file
   -outfile          :the outfile containing only the GoI and the centroid values
   -p4cS             :the pattern to select the sample columns
   -random_sets      :how manny centroids do you want to create on a random gene set
   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/centroid_calculation.pl';
$task_description .= " -expression_data $expression_data"
  if ( defined $expression_data );
$task_description .= ' -genes ' . join( ' ', @genes ) if ( defined $genes[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -p4cS '" . join( "' '", @p4cS ) . "'"
  if ( defined $p4cS[0] );
$task_description .= " -random_sets $random_sets" if ( defined $random_sets );

open( LOG, ">$outfile.log" )
  or die "I could not create the log file '$outfile.log'\n$!\n";
print LOG $task_description . "\n";
close(LOG);

my ( $affy_expr_results, $genes_hash, $all_genes );

if ( -f $genes[0] ) {
	open( IN, "<$genes[0]" ) or die "could not open the file $genes[0]\n$!\n";
	while (<IN>) {
		chomp($_);
		foreach ( split ( /\s/, $_ ) ) { 
			$genes_hash->{$_} = 1;
		}
	}
}
else {
	foreach (@genes) {
		$genes_hash->{$_} = 1;
	}
}

my $affy_expr_results_orig =
  stefans_libs_file_readers_affymetrix_expression_result->new();
$affy_expr_results_orig->p4cS(@p4cS);
$affy_expr_results_orig->read_file($expression_data);
$all_genes = $affy_expr_results_orig->getAsArray('Gene Symbol');

my ( $mean, $hash, $array, $sample_ids );
$affy_expr_results =
  $affy_expr_results_orig->select_where( 'Gene Symbol',
	sub { return 1 if ( $genes_hash->{ $_[0] } ); return 0; } );
$affy_expr_results->p4cS(@p4cS);

my $normalized = $affy_expr_results->_copy_without_data();

for ( my $i = 0 ; $i < @{ $affy_expr_results->{'data'} } ; $i++ ) {
	$sample_ids =  [ $affy_expr_results->Header_Position('samples') ];
	
	$array = [
			@{ @{ $affy_expr_results->{'data'} }[$i] }
			  [ @$sample_ids ]
		];
	$array = 	root->normalize($array);
	$hash = $affy_expr_results->get_line_asHash($i);
	for ( my $a = 0; $a < @$sample_ids; $a ++ ){
		print "we set the value for column '".@{$affy_expr_results->{'header'}}[$a]."' to  @$array[$a]\n";
		$hash->{ @{$affy_expr_results->{'header'}}[@$sample_ids[$a]] } = @$array[ $a ];
	}
	$normalized->AddDataset($hash);
}

my $centroid;

$centroid = { 'Gene Symbol' => 'mean_centroid' };
foreach ( @{ $affy_expr_results->Samples } ) {
	$centroid->{$_} = root->mean( $normalized->getAsArray($_) );
}
$normalized->AddDataset($centroid);
$normalized->write_file($outfile);
my $rand_centroids = data_table->new();
my ( $rand_data, $count, $gene_count );
$gene_count = scalar( keys %$genes_hash );
$count      = 1;
$rand_centroids->Add_header_Array(
	[ 'Probe Set ID', 'Gene Symbol', @{ $affy_expr_results->Samples } ] );

for ( my $i = 0 ; $i < $random_sets ; $i++ ) {
	##get random gene set
	$genes_hash = &get_X_random_genes( $gene_count, $all_genes );
	$rand_data =
	  $affy_expr_results_orig->select_where( 'Gene Symbol',
		sub { return 1 if ( $genes_hash->{ $_[0] } ); return 0; } );
	$centroid = {
		'Gene Symbol'  => 'RandCent' . sprintf( "%05d", $count ),
		'Probe Set ID' => $count
	};
	$count++;
	foreach ( @{ $affy_expr_results->Samples } ) {
		$centroid->{$_} = root->mean( $rand_data->getAsArray($_) );
		Carp::confess(
			    $rand_data->AsString()
			  . "\nwe look at sample $_ ($centroid->{$_})\n"
			  . root::get_hashEntries_as_string(
				$genes_hash, 3, "and here is the selection hash"
			  )
		) if ( $centroid->{$_} eq "No Values" );
	}
	print "$count\n" if ( ( $count % 100 ) == 0 );
	$rand_centroids->AddDataset($centroid);
}

$rand_centroids->write_file( $outfile . "_$random_sets" . "_random_centroids" );

sub get_X_random_genes {
	my ( $x, $possible_genes ) = @_;
	my $return = {};
	my $number = scalar(@$possible_genes);
	while ( scalar( keys %$return ) < $x ) {
		$return->{ @$possible_genes[ int( rand($number) ) ] } = 1;
	}

	#print "we selected the genes ".(join(" ", keys %$return))."\n";
	return $return;
}
