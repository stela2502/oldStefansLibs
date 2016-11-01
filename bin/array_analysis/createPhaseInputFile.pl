#! /usr/bin/perl

use strict;
use warnings;

use stefans_libs::array_analysis::dataRep::affy_geneotypeCalls;
use Getopt::Long;

my ( $outfileBase, $genList_file, $calls_file, $infoFile, $help, $debug);

Getopt::Long::GetOptions(
	"-phase_baseName=s"   => \$outfileBase,
	"-geneList_file=s"        => \$genList_file,
	"-affy_callFile=s"           => \$calls_file,
	"-affy_info_file=s"	=>\$infoFile,
	"-help"             => \$help
) or die &helpString();

die &helpString()
  unless ( -f $genList_file && defined $outfileBase && -f $calls_file && -f $infoFile );

die &helpString() if ($help);

sub helpString {
	return "
command line switches for createPhaseInputFiles:

  -affy_callFile  :the file containing the affy genotype calls
  -affy_info_file :the affay info file for this array
  -geneList_file  :the file containing a list of gene Names of interest
  -phase_baseName :a filename to use as a phase input base name
  -help           :print this help
  -debug		  :do not evaluate the array data, just take the saved temp files
"
}
my ( $rsList );
my $affyGenotypeCalls = affy_geneotypeCalls->new($calls_file, $infoFile);

open ( IN, "<$genList_file") or die "could not open \$genList_file $genList_file\n$!\n";
while ( <IN> ){
	chomp $_;
	print "we search for gene $_\n";
	$rsList = $affyGenotypeCalls->getRSids_4_geneName($_);
	 unless ( defined @$rsList[0]){
	warn "no rsIds for gene $_\n";
	next;
	 }
	print "we evaluate gene $_\n";
	$affyGenotypeCalls->printPhaseInputFileList_4_rsIDs($rsList, "$outfileBase-$_");
	
}
print "genotype informations were written to the files $outfileBase-* \n";
print "fertig\n";