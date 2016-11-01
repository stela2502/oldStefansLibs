#! /usr/bin/perl -w

#  Copyright (C) 2010-09-01 Stefan Lang

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

=head1 calculate_statistics_4_chromosomal_region.pl

A script to read from a PHASE outfile the chromosome information and from a DGI phenotype file the phenotype information to try to identify a chromosomal region, that is associated with the phenotype.

To get further help use 'calculate_statistics_4_chromosomal_region.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::MyProject::PHASE_outfile;
use stefans_libs::MyProject::Allele_2_Phenotype_correlator;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @PHASE_files, @phenotype_files, $outfile);

Getopt::Long::GetOptions(
	 "-PHASE_files=s{,}"    => \@PHASE_files,
	 "-phenotype_files=s{,}"    => \@phenotype_files,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $PHASE_files[0]) {
	$error .= "the cmd line switch -PHASE_files is undefined!\n";
}
unless ( defined $phenotype_files[0]) {
	warn "I set the phenotype file to '/home/stefan_l/Diabetes_Postdoc/_My_Projects/Project_With_Petter/starting/Connection_Groups_results/DGI_phenotypes/phenotypes_T2D_all_samples_all_sexes.txt' as you have given me none!\n";
	$phenotype_files[0] = "/home/stefan_l/Diabetes_Postdoc/_My_Projects/Project_With_Petter/starting/Connection_Groups_results/DGI_phenotypes/phenotypes_T2D_all_samples_all_sexes.txt";
	#$error .= "the cmd line switch -phenotype_files is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for calculate_statistics_4_chromosomal_region.pl

   -PHASE_files       :<please add some info!> you can specify more entries to that
   -phenotype_files       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'calculate_statistics_4_chromosomal_region.pl';
$task_description .= ' -PHASE_files '.join( ' ', @PHASE_files ) if ( defined $PHASE_files[0]);
$task_description .= ' -phenotype_files '.join( ' ', @phenotype_files ) if ( defined $phenotype_files[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);

my ( $PHASE_outfile, $Allele_2_Phenotype_correlator, $Phase_file, $pheno_file, $result, $figure_file  );
open (LOG, ">$outfile.log" ) or die "could not create the log file $outfile.log\n$!\n";
print LOG "CMD:\n$task_description\n";
close ( LOG );
open ( OUT , ">$outfile" ) or die "could not create the outfile $outfile\n$!\n";

my (@temp, $outpath, $PHASE_name, $detailed_data_table, $min) ;
@temp = split( "/", $outfile);
pop(@temp);
$outpath = join("/",@temp);

print  OUT "phase_file\tphenotype_file\tmode\tp value\tstat_value\torder of freedom\n";

foreach $Phase_file ( @PHASE_files ){
	next unless ( -f $Phase_file );
	@temp = split( "/", $Phase_file);
	$PHASE_name  = pop(@temp);
	$PHASE_name =~ s/\.\w+$//;
	$PHASE_outfile = PHASE_outfile->new($debug);
	$PHASE_outfile->read_file ( $Phase_file );
	foreach $pheno_file ( @phenotype_files ){
		next unless ( -f $pheno_file );
		if ( ref($Allele_2_Phenotype_correlator) =~ m/\w/){
			$Allele_2_Phenotype_correlator = Allele_2_Phenotype_correlator ->new($Allele_2_Phenotype_correlator->{'R'}, $debug)
		}
		else {
			$Allele_2_Phenotype_correlator = Allele_2_Phenotype_correlator ->new(undef, $debug);
		}
		$Allele_2_Phenotype_correlator ->create_plots("$outpath/$PHASE_name");
		$Allele_2_Phenotype_correlator -> read_file ( $pheno_file );
		($result, $figure_file, $detailed_data_table) = $Allele_2_Phenotype_correlator -> calculate_4_grouping_hash ( $PHASE_outfile );
		foreach ( qw/combination dominant recessive/){
			print OUT "$Phase_file\t$pheno_file\t$_\t$result->{$_}\n";
			print "$Phase_file\t$pheno_file\t$_\t$result->{$_}\n";
		}
		if ( defined $figure_file){
			print "we have a significant dataset plotted to $figure_file\n";
		}
		if ( defined $detailed_data_table){
			@temp = split( "/", $pheno_file );
			print "we have written some statistical values to file $outfile"."_$temp[@temp-1] \n";
			$detailed_data_table -> Sort_by( [['mode','lexical'],['NHD','antiNumeric']])->print2file ($outfile."_$temp[@temp-1]" );
			$min = 100;
			foreach ( @{$detailed_data_table->get_column_entries('p_value')} ) {
				next if ( $_ eq ""  );
				$min = $_ if ( $min > $_ );
				
			}
			if ( $min < 0.05 ){
					open ( PPP, ">$outfile"."_$temp[@temp-1]-best_p_value" ) or die "could not open p_value outfile!\n";
					print PPP $min;
					close ( PPP );
			}
			print "our best p_value = $min\n";
			last;
			print "we have written some statistical values to file $outfile"."_$temp[@temp-1] \n";
		}
	}
}

close ( OUT );
print "Data was saved as $outfile\n";
