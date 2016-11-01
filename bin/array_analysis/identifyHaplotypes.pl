#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::dataRep::affy_geneotypeCalls;
use stefans_libs::array_analysis::dataRep::hapMap_phase;
use Getopt::Long;

## here we want to identfy haplotypes bases on affy SNP array experiments
## therefore, we have to read in hapmap data for each chromosome -> could be a little complicated...
## this step should definitely be deligated to a database!
## Included in the hapmap data is a list of known haplotypes - I am wondering, if that list is complete ;-)
## against these haplotypes we want to match the known SNP data for that genetc region.
## I would expect, that we can identify the most probable haplotypes based on a affy 500K SNP array!

my ( $PhaseData, $LD_data, $outfile, $gene_of_interest, $SNP_array_results,
	$SNP_array_rsInfo, $help, $debug );

Getopt::Long::GetOptions(
	"-SNP_array_results=s" => \$SNP_array_results,
	"-SNP_array_rsInfo=s"  => \$SNP_array_rsInfo,
	"-phaseData=s"         => \$PhaseData,
	"-LD_data=s"           => \$LD_data,
	"-gene_of_interest=s"  => \$gene_of_interest,
	"-outfile=s"           => \$outfile,
	"-help"                => \$help,
	"-debug"               => \$debug
) or die "you made a simple mistake\n" & helpString();

die "there is a missing value!\n\$SNP_array_results = $SNP_array_results\n",
  "\$SNP_array_rsInfo = $SNP_array_rsInfo\n", "\$PhaseData = $PhaseData\n",
  "\$LD_data = $LD_data\n", "\$gene_of_interest = $gene_of_interest\n",
  &helpString()
  unless ( -f $SNP_array_results
	&& -f $SNP_array_rsInfo
	&& -f $PhaseData
	&& -f $LD_data
	&& defined $gene_of_interest );

die "we need an outfile!\n", &helpString() unless ( defined $outfile );

die &helpString() if ($help);

sub helpString {
	return "
command line switches for identfyHaplotypes.pl:

  -SNP_array_results :the output file from the affymetrix power tools 'apt-probeset-genotype' sript
  -SNP_array_rsInfo  :the lib file containing the rsInformation (also in affy format)
  -phaseData         :haplotype data from the HapMap project; acutual in 02.2009:
                      http://ftp.hapmap.org/phasing/2009-02_phaseIII/HapMap3_r2/CEU/UNRELATED/
                      We need the data for the chromosome where the gene specified by gene_of_interest is located
  -LD_data           :the linkage information again from the HapMap project; actual in 02.2009:
                      http://ftp.hapmap.org/recombination/2008-03_rel22_B36/rates/
                      We need the data for the chromosome where the gene specified by gene_of_interest is located
  -gene_of_interest  :the 'gene symbol' describing the gene of interest 
                      (';' separated list of genes on the same chromosome)
  -outfile           :the name of the outfile (<tab> separated table)
  -help              :print this help
  -debug		     :do not evaluate the array data, just take the saved temp files
"
}

my (
	$affy_genotypeCall, $SNP_cluster, $HaploTypeList,  $rsIDs,
	$hapMap_phase,      @geneNames,   $possHaplotypes, $i,
	$peoplePrinted,     $temp
);

@geneNames = split( ";", $gene_of_interest );

print "we got the genes of interest (@geneNames)\n" if ($debug);

$affy_genotypeCall =
  affy_geneotypeCalls->new( $SNP_array_results, $SNP_array_rsInfo );

print "affy_genotypeCall object is ready to use!\n" if ($debug);

$hapMap_phase = hapMap_phase->new( $PhaseData, $LD_data );

print "hapMap_phase object is ready to use!\n" if ($debug);

unless ( -f $outfile ) {
	open( OUT, ">$outfile" )
	  or die "printPossibleHaplotypes could not create file $outfile\n$!\n";
}
else {
	open( OUT, ">>$outfile" )
	  or die "printPossibleHaplotypes could not create file $outfile\n$!\n";
}

unless ( -f "$outfile.log"){
	open ( LOG, ">$outfile.log") or die "printPossibleHaplotypes could not create file $outfile.log\n$!\n";
}
else{
	open( LOG, ">>$outfile.log" )
	  or die "printPossibleHaplotypes could not create file $outfile.log\n$!\n";
}

foreach my $gene (@geneNames) {
	$rsIDs = $affy_genotypeCall->getRSids_4_geneName($gene);
	print "For the gene $gene e got the rsIDs (@$rsIDs)\n" if ($debug);
	$HaploTypeList = $hapMap_phase->getHaplotypes_4_rsList($rsIDs);
	root::print_hashEntries( $HaploTypeList, 5,
		"the Haplotype List for gene $gene" )
	  if ($debug);
	$i = 1;
	foreach my $haplo (@$HaploTypeList) {

		$SNP_cluster =
		  $affy_genotypeCall->get_SNP_cluster_4_rsIDs( [ $haplo->RS_IDs() ] );

		unless ( defined $peoplePrinted ) {
			$peoplePrinted = 1;
			print OUT "genetic region\t",
			  join( "\t", $SNP_cluster->get_Person_array() ),"\n";
		}

		print "the $i. SNP_cluster for gene $gene\n" if ($debug);
		$SNP_cluster->print()                        if ($debug);

		$possHaplotypes = $haplo->getPossibleHaplotypes($SNP_cluster);
		root::print_hashEntries( $possHaplotypes, 5,
			"the posssible Haplotypes for SNP_cluster $i (gene $gene)" )
		  if ($debug);
		$temp = $gene . " " . $haplo->Start() . "-" . $haplo->End() . "\t";
		print OUT "$temp",
			$haplo->getTableString_4_haploTypeList(
				$possHaplotypes, [$SNP_cluster->get_Person_array()] ),
		  "\n";
		print LOG "possible haplotypes for $temp\n";
		print LOG $haplo->getPossHaplotypes_as_tabSeparatedList_string( $possHaplotypes, [$SNP_cluster->get_Person_array()]  );
		
		##$haplo->printPossibleHaplotypes( $possHaplotypes, $outfile );
		$i++;
	}
}
close ( OUT );
close ( LOG );
print "We should be ready by now - hopefully all is OK!\n";
print "If you want further info use the -debug command line switch!\n";

