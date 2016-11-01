#! /usr/bin/perl

use strict;
use stefans_libs::statistics::new_histogram;
use stefans_libs::statistics::HMM::marcowChain;
use stefans_libs::gbFile::gbFeature;
use stefans_libs::gbFile;
use stefans_libs::histogram;

use Getopt::Long;

my ( $infile, $n, $length, $p_cutoff, $help, $gbFile );

Getopt::Long::GetOptions(
	"-infile=s"            => \$infile,
	"-rounds=s"            => \$n,
	"-min_region_length=s" => \$length,
	"-p_cutoff=s"          => \$p_cutoff,
	"-help"                => \$help,
	"-gbFile=s"            => \$gbFile
) or die &helpString();

die &helpString() if ($help);

die &helpString()
  unless ( defined $infile );

$p_cutoff = 0.9 unless ( defined $p_cutoff );
$n        = 10  unless ( defined $n );
$length   = 200 unless ( defined $length );

sub helpString {
	return
"the script will try to identify enhancer and promoter elements soly on the basis of nucleosome
positioning data created by the model published in Kaplan et al. 2008 PMID:19092803
 
command line options for statistical test:

   -infile          : the name of the table file
   -rounds          : number of HMM iterations to run
   -min_region_length: the minimal length of the expected promoter tregions
   -p_cutoff        : the cutoff value of each bp in a promoter region 
   -use_model       : the HMM model to use
   -gbFile          : a gbFile, that should be used to add the interesting regions

";
}

my ( $model, $marcowLine, $f0, $f1, $_1a1, $_1a0, $a0, $a1, $phi0, $phi1, $Pd0,
	$Pd1, $gbFile_obj, $histo, $temp );
open( IN, "<$infile" ) or die "could not open input file '$infile'\n";

$gbFile_obj = gbFile->new($gbFile) if defined($gbFile);
warn "no gbFile! $gbFile" unless ( defined $gbFile );

$histo = histogram->new();

$a1   = 1e-5;    ##probability that a enhancer/promoter element continues
$_1a1 = 1 - $a1;
$a0 =
  1e-2;    ## probability that a bp is NOT part of enhancer/promoter element
$_1a0 = 1 - $a1;
$phi1 =
  1e-5
  ; ##probability that the first bp in a sequence is part of e enhancer/promoter element
$phi0 = 1 - $phi1;
$Pd1  = $Pd0 =
  1e-6;    ## probability, that any given bp is the last in a marcow chain

	$_1a0 = log ($_1a0);
	$a0 = log($a0);
	$a1 = log ( $a1);
	$_1a1 = log ( $_1a1);
	$phi1 = log ( $phi1);
	$phi0 = log ( $phi0);
	$Pd0 = log ( $Pd0);
	$Pd1 = log ( $Pd1); 
	

while (<IN>) {
	$model      = &createDataModel($_);
	$marcowLine = marcowChain->new(2);
	$temp = $marcowLine->addValueArray( $model->{start}, $model->{probability_array} );
	$histo->AddDataArray($model->{probability_array},100);
	$histo->writeHistogram("distributionOfProbabilities_perBP.txt");
	
	$histo->AddDataArray($temp,100);
	$histo->writeHistogram("distributionOfProbabilities_per5BP.txt");
		
	( $f0, $f1 ) = createNewProbDistr();

	$marcowLine->addProbabilityFunction_F0($f0);
	$marcowLine->addProbabilityFunction_F1($f1);
	for ( my $i = 0.05 ; $i < $n ; $i++ ) {
		$f0->printHistogram2file("f0_iteration_$i");
		$f1->printHistogram2file("f1_iteration_$i");

		$marcowLine->CalculateForwardProbability( $_1a0, $a0, $a1, $_1a1, $phi0,
			$phi1 );
		$marcowLine->CalculateBackwardProbability( $_1a0, $a0, $a1, $_1a1, $Pd0,
			$Pd1 );
		$marcowLine->CalculateTotalProbabilityFromStartToEnd();
		$marcowLine->print_enriched_regions( $p_cutoff, $length,
"putativePromoterRegions_HMM_iteration$i-CHR$model->{CHR}-$model->{start}-$model->{end}.csv"
		);

		$marcowLine->CalculateProbOfTransitions( $_1a0, $a0, $a1, $_1a1 );
		( $a1, $a0, $_1a1, $_1a0, $phi0, $phi1, $Pd0, $Pd1 ) =
		  &ReestimateMarkowModel($marcowLine);
		&PrintReestimate( $a1, $a0, $_1a1, $_1a0, $phi0, $phi1, $Pd0, $Pd1,
			$i );

#		my $hash = $marcowLine->getProbabilityHash();
#		my $hash_H0 = $marcowLine->getProbabilityHash_H0();
#		my $hash_ori = $marcowLine->getValuesHash();
#		open (OUT, ">finalOUT$i.csv");
#		print OUT "position [bp]\tvalue\tprobability H1\tprobability H0\n";
#		foreach my $bp (sort {$a <=> $b} keys %$hash ){
#			print OUT "$bp\t$hash_ori->{$bp}\t",exp($hash->{$bp}),"\t",exp($hash_H0->{$bp}),"\n";
#		}
#		close (OUT);

	}
	unless ($gbFile) {
		$marcowLine->print_enriched_regions( $p_cutoff, $length,
"putativePromoterRegions_CHR$model->{CHR}-$model->{start}-$model->{end}.csv"
		);
	}
	else {
		$gbFile_obj->Features(
			$marcowLine->print_enriched_regions(
				$p_cutoff,
				$length,
"putativePromoterRegions_CHR$model->{CHR}-$model->{start}-$model->{end}.csv"
			)
		);
		$gbFile_obj->WriteAsGB_toFile("gbFile_with_enhancers.gb");
	}
}

sub ReestimateMarkowModel {
	my ($marcowChain) = @_;

	my (
		$T,          $a,            $rv,         $G_H1_to_H0, $F1,
		$F0,         $G_H0_to_H0,   $G_H1_to_H1, $G_H0_to_H1, $P_H0,
		$P_H1,       @f1,           @f0,         @oligoCount, $temp,
		@G_H1_to_H0, @G_H0_to_H0,   @G_H1_to_H1, @G_H0_to_H1, @P_H0,
		@P_H1,       $countInRange, $low,        $high,       $Pd0,
		$phi0,       $phi1,         $Pd1
	);

	## Reestimate F1 and F0

	$G_H1_to_H0 = $G_H0_to_H0 = $G_H1_to_H1 = $G_H0_to_H1 = $P_H0 = $P_H1 =
	  $Pd0 = $phi0 = $phi1 = 0;

	print "\t\t start of Reestimation\n";
	$P_H1       = $marcowChain->SumOf("p_H1");
	$P_H0       = $marcowChain->SumOf("p_H0");
	$G_H1_to_H0 = $marcowChain->SumOf("G_H1_to_H0");
	$G_H0_to_H0 = $marcowChain->SumOf("G_H0_to_H0");
	$G_H1_to_H1 = $marcowChain->SumOf("G_H1_to_H1");
	$G_H0_to_H1 = $marcowChain->SumOf("G_H0_to_H1");
	$Pd0        = $marcowChain->last_pH0();
	$Pd1        = $marcowChain->last_pH1();
	$phi0       = $marcowChain->first_pH0();
	$phi1       = $marcowChain->first_pH1();

	$marcowChain->{F1}->Reestimate();
	$marcowChain->{F0}->Reestimate();

	$marcowChain->ReestimateProbabilityFunctions();

	$marcowChain->{F1}->finalizeReestimation();
	$marcowChain->{F0}->finalizeReestimation();
	$marcowChain->{F1}->ScaleSumToOne();
	$marcowChain->{F0}->ScaleSumToOne();

	print "HMM problem ScaleSumToOne F1() returned undef!\n"
	  unless ( defined $marcowChain->{F1} );
	print "HMM problem ScaleSumToOne F0() returned undef!\n"
	  unless ( defined $marcowChain->{F0} );

#root::print_hashEntries($self->{f1},4,"$self->ReestimateMarkowModel the new probability function f1\n");
#root::print_hashEntries($self->{f0},4,"$self->ReestimateMarkowModel the new probability function f0\n");

	$marcowChain->{F1}->LogTheHash();
	$marcowChain->{F0}->LogTheHash();

	## Reestimate a0, 1-a0, a1, 1-a1

	my $_1a0 = $G_H0_to_H0 - $P_H0;    # probability that the H0->H0
	my $a0   = $G_H1_to_H0 - $P_H1;    # probability that the H0->H1
	my $a1   = $G_H0_to_H1 - $P_H0;    # probability that the H1->H1
	my $_1a1 = $G_H1_to_H1 - $P_H1;    # probability that the H1->H1

	$Pd0  = $Pd0 - $P_H0;
	$Pd1  = $Pd1 - $P_H1;

	return ( $a1, $a0, $_1a1, $_1a0, $phi0, $phi1, $Pd0, $Pd1 );
}

sub PrintReestimate {
	my ( $a1, $a0, $_1a1, $_1a0, $phi0, $phi1, $Pd0, $Pd1, $iteration ) = @_;

	my $temp = "probability_reestimation_$iteration.csv";

	open( Reestimate, ">$temp" )
	  or die "konnte $temp nicht anlegen!\n";

	print Reestimate "P(H0->H0)\t", exp($_1a0), "\n", "P(H0->H1)\t", exp($a0),
	  "\n", "P(H1->H0)\t", exp($a1), "\n", "P(H1->H1)\t", exp($_1a1), "\n";
	close Reestimate;
}

sub createDataModel {
	my ($line) = @_;
	my ( $model, $temp, @array );
	chomp $line;
	( $model->{CHR}, $model->{start}, $model->{end}, $temp ) =
	  split( "\t", $line );
	return undef unless ( $temp =~ m/;/ );
	@array = split( ";", $temp );
	$model->{probability_array} = \@array;
	$model->{Length}            = @array;
	return $model;
}

sub createNewProbDistr {
	my ( $f0, $f1 );

	$f0 = new_histogram->new();
	$f1 = new_histogram->new();
	$f0->Category_steps(20);
	$f1->Category_steps(20);
	$f1->Max(1);
	$f0->Max(1);
	$f1->Min(0);
	$f0->Min(0);

	for ( my $i = 0.01 ; $i < 1 ; $i += 0.01 ) {
		$f0->AddValue($i);
		$f1->AddValue($i);
		$f1->AddValue($i) if ( $i < 0.2);
		$f1->AddValue($i) if ( $i < 0.4);
		$f0->AddValue($i) if ( $i > 0.4 );
		$f0->AddValue($i) if ( $i > 0.8 );
	}
	$f0->ScaleSumToOne();
	$f1->ScaleSumToOne();
	$f0->LogTheHash();
	$f1->LogTheHash();
	return ( $f0, $f1 );
}
