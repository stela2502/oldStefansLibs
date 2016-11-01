#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::dataRep::affy_geneotypeCalls;
use stefans_libs::tableHandling;
use stefans_libs::root;

use Getopt::Long;

my (
	$outfile,           $rsList_File,       $calls_file,
	$infoFile,          $help,              $debug,
	@chromosomalRegion, $chromosomalRegion, @geneOfInterest
);

Getopt::Long::GetOptions(
	"-outfile=s"            => \$outfile,
	"-infoList_file=s"      => \$rsList_File,
	"-chromosomal_region=s" => \$chromosomalRegion,
	"-genesOfInterest=s{,}" => \@geneOfInterest,
	"-affy_callFile=s"      => \$calls_file,
	"-affy_info_file=s"     => \$infoFile,
	"-debug"                => \$debug,
	"-help"                 => \$help
	
) or die &helpString("we have a problem here!");

@chromosomalRegion = split( ";", $chromosomalRegion );

die &helpString("no file? \n$rsList_File\n$calls_file\n$outfile")
  unless ( -f $infoFile && defined $outfile && -f $calls_file );

die &helpString("no infoFile AND no chromosomalRegion AND no gene of interest")
  unless ( ( -f $rsList_File )
	|| ( @chromosomalRegion == 3 )
	|| defined $geneOfInterest[0] );

die &helpString("you called for help?") if ($help);

sub helpString {
	my $start = shift;
	if ($debug) {
		return "$start
 	affy_callFile      = $calls_file
 	affy_info_file     = $infoFile
 	infoList_file      = $rsList_File
 	chromosomal_region = $chromosomalRegion
 	genesOfInterest	   = @geneOfInterest
 	outfile            = $outfile
 	debug              = $debug
 	", "
 command line switches for createPhaseInputFiles:
 
   -affy_callFile  :the file containing the affy genotype calls
   -affy_info_file :the affay info file for this array
   -infoList_file  :the file containing a list of rsIDs
   -chromosomal_region :the location of the SNPs (<chr_id>;<start>;<end>)
   -genesOfInterest : the gene you are interested in ( normally we take +/- 50kb) 
   -outfile        :the outfile where the SNP infos will be stored to
   -help           :print this help
   -debug		  :verbose output
 ";
	}
	return "
 command line switches for createPhaseInputFiles:
 
   -affy_callFile  :the file containing the affy genotype calls
   -affy_info_file :the affay info file for this array
   -infoList_file  :the file containing a list of rsIDs (name = rsID)
   -chromosomal_region :the location of the SNPs (<chr_id>;<start>;<end>)
   -genesOfInterest : the gene you are interested in ( normally we take +/- 50kb)
   -outfile        :the outfile where the SNP infos will be stored to
   -help           :print this help
   -debug		  :verbose output
 ";
}

my ( @rsList, $matrix, $rsID, $affyGenotypeCalls, $tableHandling, $columnID );
$tableHandling = tableHandling->new( "\t", $debug );
$affyGenotypeCalls = affy_geneotypeCalls->new( $calls_file, $infoFile, $debug );


if ( -f $rsList_File ) {
	open( IN, "<$rsList_File" )
	  or die "could not open \$genList_file $rsList_File\n$!\n";
	while (<IN>) {
		chomp $_;
		unless ( defined $columnID ) {
			$columnID =
			  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
				{ 'rsID' => 1 == 1 } );
			die "we could not identify a column using the header rsID in line\n$_"
				unless ( defined $columnID);
			next;
		}
		($rsID) = $tableHandling->get_column_entries_4_columns( $_, $columnID );
		print "we add rsID $rsID\n" if ($debug);
		push( @rsList, $rsID ) unless ( "@rsList" =~ m/$rsID/ );
	}
	close(IN);

	$matrix = $affyGenotypeCalls->getSampleGeneotypeTable_4_rsIDs( \@rsList );
}

elsif ( defined $chromosomalRegion[0] ) {
	$matrix =
	  $affyGenotypeCalls->getSampleGeneotypeTable_4_chromosomePosition(
		@chromosomalRegion);
}

elsif ( defined $geneOfInterest[0] ) {
	foreach my $geneOfInterest (@geneOfInterest) {
		$matrix =
		  $affyGenotypeCalls->getSampleGeneotypeTable_4_geneName(
			$geneOfInterest, 50000, 50000 );
		open( OUT, ">$outfile-$geneOfInterest.csv" )
		  or die "could not create outfile $outfile-$geneOfInterest.csv\n$!\n";
		print OUT "@$matrix";
		close(OUT);
	}
	$matrix = undef;
}

if ( defined $matrix ) {
	print "We got the final matrix:\n" if ($debug);
	root::print_hashEntries( $matrix, 3, "lets see:" ) if ($debug);

	open( OUT, ">$outfile" ) or die "could not create outfile $outfile\n$!\n";
	print OUT "@$matrix";
	close(OUT);
}

open( LOG, ">$outfile.log" ) or die "could not create log file $outfile.log\n";
print LOG "Command line option to printGenotypeList.pl
 	affy_callFile      = $calls_file
 	affy_info_file     = $infoFile
 	infoList_file      = $rsList_File
 	chromosomal_region = $chromosomalRegion
 	genesOfInterest	   = @geneOfInterest
 	outfile            = $outfile
 	debug              = $debug\n";
close(LOG);

print "genotype informations were written to the file $outfile\n";
