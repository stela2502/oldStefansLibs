#! /usr/bin/perl -w

#  Copyright (C) 2011-02-10 Stefan Lang

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

=head1 identify_best_model.pl

takes a convert_PHASE_infile_To_Sample_Keys.pl result file and calculates the best genetic model for a given set of SNPs.

To get further help use 'identify_best_model.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::MyProject::ModelBasedGeneticAnalysis;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,           $debug,           $database,
	$infile,         $outfile,         $control_infile,
	$number_of_SNPs, $max_sample_size, $phenotype, $model_t
);

Getopt::Long::GetOptions(
	"-infile=s"          => \$infile,
	"-outfile=s"         => \$outfile,
	"-number_of_SNPs=s"  => \$number_of_SNPs,
	"-max_sample_size=s" => \$max_sample_size,
	"-phenotype=s"       => \$phenotype,
	"-control_infile=s"  => \$control_infile,
	"-model=s"           => \$model_t,
	"-help"              => \$help,
	"-debug"             => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $number_of_SNPs ) {
	$error .= "the cmd line switch -number_of_SNPs is undefined!\n";
}
unless ( defined $max_sample_size ) {
	$error .= "the cmd line switch -max_sample_size is undefined!\n";
}
unless ( defined $phenotype ) {
	$error .= "the cmd line switch -phenotype is undefined!\n";
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
 command line switches for identify_best_model.pl

   -infile         :the training data
   -control_infile :the control dataset to check the best results in
   -outfile        :the basic outfile (we will also create a log and allModels.txt)
   -number_of_SNPs   :How many SNPs should a at max add to the model?
   -max_sample_size  :How big the sample size should be?
   -phenotype        :which phenotype column to take to analyze the data?
   -model            :an optional model, that will either transform 
                      2 & 3 into 5 (recessive) or
                      1 & 2 into 4 (dominant)
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/identify_best_model.pl';
$task_description .= " -infile $infile"   if ( defined $infile );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -number_of_SNPs $number_of_SNPs"
  if ( defined $number_of_SNPs );
$task_description .= " -max_sample_size $max_sample_size"
  if ( defined $max_sample_size );
$task_description .= " -phenotype $phenotype" if ( defined $phenotype );
$task_description .= " -control_infile $control_infile"
  if ( defined $control_infile );
$task_description .= " -model $model_t" if ( defined $model_t);

## Do whatever you want!
open( LOG, ">$outfile.log" )
  or die "Sorry, but I could not create the log file $outfile.log\n$!\n";
print LOG $task_description;
close(LOG);

my $data_handler = stefans_libs_MyProject_ModelBasedGeneticAnalysis->new($model_t);
$data_handler->read_file($infile);

#print "Do we have read some data?\n".join(",",@{@{$data_handler->{'data'}}[0]} )."\n";

unless ($debug) {
	$data_handler->calculate_all_models(
		{
			'SNP_count'    => $number_of_SNPs,
			'max_subjects' => $max_sample_size,
			'phenotype'    => $phenotype
		}
	);
}
else {
	$data_handler->create_model(
		{
			'SNPs'         => [ 1, 4, 5, 7, 8, 9 .. 13 ],
			'max_subjects' => $max_sample_size,
			'phenotype'    => $phenotype
		}
	);
}

open( OUTFILE, ">$outfile" ) or die "I could not open the outfile $outfile\n$!\n";

print OUTFILE "Best protective model bottom up:\n";
my $model = $data_handler->get_best_protective_model();
print OUTFILE $data_handler->{'best_protective_model'} -> _print_this ();
#print OUT &print_model($model);

print OUTFILE "Best disease model bottom up\n";
$model = $data_handler->get_best_predictive_model();
print OUTFILE $data_handler->{'best_predictive_model'} -> _print_this ();
#print OUT &print_model($model);


open( OUT, ">$outfile.allModels.txt" )
  or die "I could not create the allModels.txt outfile\n$!\n";
print OUT $data_handler->print();
close(OUT);

sub print_model {
	my ($model) = @_;
	## that is a hash 'key' => '', 'mean' => 0, 'n' => 0, 'std' => 0
	return "No model hash!\n" unless ( ref($model) eq "HASH" );
	return
"SNPs = $model->{'SNPs'}; key = $model->{'key'}; mean = $model->{'mean'}; n = $model->{'n'}; p_value = $model->{'p_value'}\n";
}

## if we have a $control_infile, we should check the best correlating samples!
if ( -f $control_infile ) {
	open( OUT, ">$outfile.control_analysis_RISK" )
	  or die "I could not create the control analysis!\n$!\n";
	my $control_data = stefans_libs_MyProject_ModelBasedGeneticAnalysis->new($model_t);
	$control_data->read_file($control_infile);
	$control_data->create_model(
		$data_handler->{'best_predictive_model'}->{'info'} );
	$control_data->get_best_predictive_model();
	print OUT $control_data->print();
	print OUTFILE "TEST predeictive MODEL - redo\n";
	print OUTFILE $control_data->{'best_predictive_model'} -> print();
	close(OUT);
	open( OUT, ">$outfile.control_analysis_PROTECTIVE" )
	  or die "I could not create the control analysis!\n$!\n";
	my $control_data_2 =
	  stefans_libs_MyProject_ModelBasedGeneticAnalysis->new($model_t);
	$control_data_2->read_file($control_infile);
	$control_data_2->create_model(
		$data_handler->{'best_protective_model'}->{'info'} );
	$control_data_2->get_best_protective_model();
	print OUTFILE "TEST protective MODEL - redo\n";
	print OUTFILE $control_data_2->{'best_protective_model'} -> print();
	print OUT $control_data_2->print();
	close(OUT);
}

close ( OUTFILE );
