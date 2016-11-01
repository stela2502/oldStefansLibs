#! /usr/bin/perl

use strict;
use stefans_libs::gbFile;
use stefans_libs::fastaDB;
use Getopt::Long;

my ( $output, $dataFile, $upstreamSpace, $downstreamSpace, $bindingSite );
my ( @seq, $start, $end, $matching, @returnStrings );
my ( $featureArray, $fastaDB, $acc, $temp, $seq );
my $true = 1 == 1;

# implementation of a search hash for iupac nucleotide codes against acgt
# iupac info site: http://www.bioinformatics.org/sms/iupac.html

	my $matchHash = {
		'a' => {'a' => $true },
		'c' => {'c' => $true },
		'g' => {'g' => $true },
		't' => {'t' => $true },
		'm' => {'a' => $true, 'c' => $true },
		'r' => { 'a' => $true, 'g' => $true},
		'w' => { 'a' => $true, 't' => $true},
		's' => { 'c' => $true, 'g' => $true},
		'y' => { 'c' => $true, 't' => $true},
		'k' => { 'g' => $true, 't' => $true},
		'v' => { 'a' => $true, 'c' => $true, 'g' => $true},
		'h' => { 'a' => $true, 'c' => $true, 't' => $true},
		'd' => { 'a' => $true, 'g' => $true, 't' => $true},
		'b' => { 'c' => $true, 'g' => $true, 't' => $true},
		'x' => { 'a' => $true, 'c' => $true, 'g' => $true, 't' => $true},
		'n' => { 'a' => $true, 'c' => $true, 'g' => $true, 't' => $true}
	};
	my $complement = {
		'a' => 't',
		't' => 'a',
		'c' => 'g',
		'g' => 'c'
	};
	
Getopt::Long::GetOptions(
	"-output=s"          => \$output,
	"-gb_database=s"     => \$dataFile,
	"-upstreamSpace=s"   => \$upstreamSpace,
	"-downstreamSpace=s" => \$downstreamSpace,
	"-bindingSite=s"     => \$bindingSite
) or die &helpString();

die &helpString() unless ( defined $bindingSite );

sub helpString {
	return
"createListFromReadTable.pl returns a tab separated list of all table entries
	
	-output              :the file to store the results in
	-gb_database         :the location of the genbank formated genome
	-upstreamSpace       :the space upstream of the transcription start site that should be evaluated [bp]
	                      default = 2000bp
	-downstreamSpace     :the space downstream of the transcription start site that should be evaluated [bp]
	                      default = 200bp
    -bindingSite         :the sequence of the binding sites to be identified (IUPAC code)
	";
}

my ( @gbArray, @gbFile_array );

my @bindingSite = split( "", $bindingSite );
foreach my $base (@bindingSite) {
	die
"char $base in binding site is not compatible with the IUPAC code for DNA!\n"
	  unless ( lc($base) =~ m/[acgtmrwsykvhdbxn]/ );
}
unless ( defined $output ){
	$output = "$dataFile.output";
}

$upstreamSpace   = 2000 unless ( defined $upstreamSpace );
$downstreamSpace = 200  unless ( defined($downstreamSpace) );

$output = "$output.-$upstreamSpace.to.+$downstreamSpace";

open( IN, "<$dataFile" )
  or die "CRITICAL ERROR:\n\tcould not open gbData file $dataFile\n";
open( OUT, ">$output" ) or die "could not create file $output\n";
open( OUTsummary , ">$output.summary" ) or die "could not open file $output.summary\n";

print OUTsummary "number of binding sites in promoter\tgene name\n";

while (<IN>) {
	unless ( $_ =~ m!//! ) {
		## data line!
		push( @gbArray, $_ );
	}
	else {
		## end of a gbEntry
		push( @gbArray, $_ );
		$temp = "$output.temp";
		open (TEMP, ">$temp" ) or die "could not create temp file $temp\n";
		print TEMP @gbArray;
		#print "Ge Start with the evaluation\n";
		close ( TEMP );
		@gbArray = ();
		#print "DEBUG gbFile written to temp file $temp\n";
		&evaluateGBfile( gbFile->new( $temp ) );
	}
}
system ( "rm $output.temp" );

close(OUT);
close(IN);
close (OUTsummary);

sub evaluateGBfile {
	my $gbFile = shift;
	print "DEBUG the gbFile has been read\n";
	my @temp = ("mRNA");
	my $i;
	$featureArray = $gbFile->SelectMatchingFeatures_by_Tag( \@temp );
	foreach my $gbFeature (@$featureArray) {
		$temp = $gbFeature->Name();
		#print "DEBUG we got a mRNA for gene $temp\n";
		$i = 0;
		if ( defined( $gbFeature->IsComplement() ) ) {
			$acc =
"$temp promoter (-$upstreamSpace to +$downstreamSpace) (complement!)";
			$seq = $gbFile->Get_SubSeq(
				$gbFeature->ExprStart() - $downstreamSpace,
				$gbFeature->ExprStart() + $upstreamSpace
			);
		}
		else {
			$acc = "$temp promoter (-$upstreamSpace to +$downstreamSpace)";

			$seq = $gbFile->Get_SubSeq(
				$gbFeature->ExprStart() - $upstreamSpace,
				$gbFeature->ExprStart() + $downstreamSpace
			);
		}
		print "DBUG: evaluate the promotor of gene $temp\n";
		@temp = &evaluateSeq( $seq, @bindingSite );
		print OUT "search for $bindingSite in promotor of gene $temp\n";
		$i = @temp;
		if ( $i > 0){
			print OUTsummary "$i\t$temp\n";
		}
		print OUT join ("\n", @temp),"\n";

		#$fastaDB->addEntry( $acc, $seq );
	}
	$gbFile = undef;
}

sub evaluateSeq {
	my ( $seq, @bindingSite ) = @_;

	@seq           = split( "", $seq );
	$matching      = 0;
	@returnStrings = ();

	for ( my $i = 0 ; $i < @seq ; $i++ ) {
		$start = $i if ( $matching == 0 );
		if ( &match_IUPACbase_to_base( @bindingSite[$matching], @seq[$i] ) ) {
			$matching++;
		}
		else {
			$matching = 0;
		}
		if ( $matching == @bindingSite ) {    ## complete match!
			push( @returnStrings, "\t match $start..$i" );
			$matching = 0;
		}
	}
	for ( my $i = @seq - 1 ; $i >= 0 ; $i-- ) {
		$start = $i if ( $matching == 0 );
		if (
			&match_IUPACbase_to_base(
				@bindingSite[$matching], &complement( @seq[$i] )
			)
		  )
		{
			$matching++;
		}
		else {
			$matching = 0;
		}
		if ( $matching == @bindingSite ) {    ## complete match!
			push( @returnStrings, "\t match complement($i..$start)" );
			$matching = 0;
		}
	}
	return @returnStrings;
}

sub complement {
	my ($base) = @_;

	return $complement->{$base};
}

sub match_IUPACbase_to_base {
	my ( $IUPACbase, $base ) = @_;

	die "not an IUPAC base ($IUPACbase)\n" unless ( defined $matchHash->{ lc($IUPACbase) } );
	
	return $matchHash->{ lc($IUPACbase) } -> {$base};
	
	my $match = $matchHash->{ lc($IUPACbase) };
	#return 1 == 1 if ( lc($base) =~ m/$match/ );
	if ( lc($base) =~ m/$match/ ) {
		#print "got a match! base $base matches to $match\n";
		return 1 == 1;
	}
	#print "NO match! base $base matches to $match\n";
	return 1 == 0;
}
