#!/usr/bin/perl
#  Copyright (C) 2008 Stefan Lang

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
use strict;

use stefans_libs::gbFile;
use stefans_libs::sequence_modification::primerList;
use stefans_libs::sequence_modification::blastResult;
use Getopt::Long;

my (
	$input,               $DB,           $outdir,
	$prime_mismatch,      $sens,         $maxMismatch,
	$minPercIdent,        $DoIMGTsearch, $minLength,
	$maxGapOpen,          $blastOutput,  $gbFile,
	$blastDB_translation, $deepSeq_runID
);

Getopt::Long::GetOptions(
	'outdir=s'                    => \$outdir,
	'Blast_minLength=s'           => \$minLength,
	'db=s'                        => \$DB,
	'Blast_wordsize=s'            => \$sens,
	'Blast_maxMismatch=s'         => \$maxMismatch,
	'Blast_minPercent_Identity=s' => \$minPercIdent,
	'Blast_maxGapOpen=s'          => \$maxGapOpen,
	'useBlastOutput=s'            => \$blastOutput,
	'mode=s'                      => \$DoIMGTsearch,
	'blastDB_infos=s'             => \$blastDB_translation,
	'deepSeq_runID=s'             => \$deepSeq_runID,
	'input=s'                     => \$input,
	'5prime_mismatch'             => \$prime_mismatch
) or die helpText();

die helpText() unless ( defined $input );

&printVariables(
	$input,     $DB,          $outdir,       $prime_mismatch,
	$sens,      $maxMismatch, $minPercIdent, $DoIMGTsearch,
	$minLength, $maxGapOpen,  $blastOutput
);

if ( $DoIMGTsearch eq "deepSequencing"){
	die "mode deepSequencing additionally need a ssake info file (-blastDB_infos) "
		,"and a ID for the deep sequencing run (-deepSeq_runID)\n"
		if  (!( defined $blastDB_translation && defined $deepSeq_runID ));
}

## correct the settings:

if ( $DoIMGTsearch eq "addPrimer" ) {
	$maxGapOpen   = 0   unless ( defined $maxGapOpen );
	$sens         = 8   unless ( defined($sens) );
	$minPercIdent = 100 unless ( defined $minPercIdent );
	print
"addPrimer: min. primer length = $minLength, maxGapOpen = $maxGapOpen, minPercIdent = $minPercIdent\n";
}
else {
	unless ( defined $DB ) {
		warn "almost all modes need a DB file!\n\tbut we got none!!\n";
		$DB = "/Users/stefanlang/PhD/Libs_new_structure/IMGT/out.fasta";
	}
}

$outdir       = "~/IgH-Locus/1_Erg/" unless ( defined($outdir) );
$sens         = 40                   unless ( defined($sens) );
$maxMismatch  = 20                   unless ( defined($maxMismatch) );
$minPercIdent = 85                   unless ( defined($minPercIdent) );
$DoIMGTsearch = "doIMGTsearch"       unless ( defined($DoIMGTsearch) );

$maxGapOpen = 5   unless ( defined $maxGapOpen );
$minLength  = 200 unless ( defined $minLength );

system("mkdir -p $outdir");

my @FEATURES = (
	"V-EXON",    "C-REGION",  "J-REGION",  "D-REGION",
	"CH1",       "CH2",       "CH3",       "CH4",
	"CH5",       "CH6",       "CH7",       "CH8",
	"CH-S",      "M",         "M1",        "M2",
	"V-NONAMER", "V-HEXAMER", "J-NONAMER", "J-HEXAMER",
	"EX1",       "EX2",       "EX3",       "EX4",
	"exon",
);    #,"DONOR-SPLICE","ACCEPTOR-SPLICE");

my $tempDir = "/Mass/temp";
my $binPath = "/home/stefan/IgH-Locus/bin/";

system("mkdir -p $tempDir") unless ( -d $tempDir );

## execute the search

if ( !defined $blastOutput ) {

	print "No old blast results -> blast search is executed\n";

	if ( $DoIMGTsearch eq "deepSequencing" ) {
		print
		  "\n\nDeep Sequencing Date in $DB is converted to blast DB using\n\t",
		  "formatdb -p F -i $DB -o T -V -n $tempDir/primers.fasta\n";
		system("formatdb -p F -i $DB -o T -V -n $tempDir/primers.fasta");
		$DB = "$tempDir/primers.fasta";
	}

	if ( $DoIMGTsearch eq "addPrimer" ) {
		my $primerList = primerList->new();
		my $primers    = $primerList->AddPrimerList($DB);
		open( PrimerDB, ">$tempDir/primers.fasta" )
		  or die "Konnte primerDB nicht anlegen $tempDir/primers.fasta!\n";
		foreach my $temp (@$primers) {
			next unless ( defined $temp );

			#next if ( $temp =~ m/^#/ );
			print PrimerDB $temp->AsFasta();
		}
		system("formatdb -p F -i $tempDir/primers.fasta -o T -V");
		$DB = "$tempDir/primers.fasta";
	}

	if ( "BlastHit AllBlastHits Sequences" =~ m/$DoIMGTsearch/ ) {
		system("cp $DB $tempDir/primers.fasta");
		system("formatdb -p F -i $tempDir/primers.fasta -o T -V");
		$DB = "$tempDir/primers.fasta";
	}

	if ( $DoIMGTsearch eq "Sequences" ) {
		$minPercIdent = 94;
	}

	$gbFile = gbFile->new();
	$gbFile->AddGbfile($input);
	$gbFile->WriteAsFasta("$tempDir/input.fasta");

	print
"megablast -W $sens -m 8 -D 3 -i $tempDir/input.fasta -d $DB -o $tempDir/blast.tabel\n";
	system(
"megablast -W $sens -m 8 -D 3 -i $tempDir/input.fasta -d $DB -o $tempDir/blast.tabel"
	);
	$blastOutput = "$tempDir/input.fasta";
}
else {
	print "We use the old blast output '$blastOutput'\n";
	$gbFile = gbFile->new();
	$gbFile->AddGbfile($input);
}

my $blastResult = blastResult->new();
$blastResult->{'5prime_mismatch'} = $prime_mismatch;

if ( $DoIMGTsearch eq 'deepSequencing' ) {
	print "convert4.pl tries to create a new fastaDB object from file '$DB'\n";
	$blastResult->FastaDB($DB);
	$blastResult->SSAKE_ClusterInfo($blastDB_translation);
	$blastResult->{deepSeq_runID} = $deepSeq_runID;
}

$blastResult->readBlastResults( $blastOutput, $minLength, $minPercIdent,
	$maxGapOpen, $DoIMGTsearch );

$blastResult->Print_results($DoIMGTsearch);
$gbFile = $blastResult->AddBlastResultsToFile( $gbFile, $DoIMGTsearch );

my ( $name, $path ) = $gbFile->getPureSequenceName();

$gbFile->WriteAsGB("$path/modified/$name.gb");

print "Fertig\nDatei $path/modified/$name.gb geschrieben.\n";

sub helpText {

	my @print;
	@print = (
		"\nconvert command line options:\n",
		"  -input <gb file>   = this gb file is used as query file for BLAST\n",
		"                       and the Blast results are added to it\n",
"  -outdir <dir>      = directory to print the files default to gbFile_Path/modified\n",
		"  -db <fasta formated database> \n",
		"                     = databse with infos for the BLAST search\n",
		"  -Blast_wordsize    = length of the minimal initial BLAST match\n",
		"  -Blast_maxMismatch = maximal allowed mismatch for one BLAST match\n",
		"  -Blast_minPercent_Identity\n",
"                     = only Blast Hits with a higher percent match value are used\n",
"  -Blast_minLength   = blast hit has to be equal or lager than minLength\n",
"  -Blast_maxGapOpen  = maximum count of gaps allowed in one Blast hit\n",
		"  -useBlastOutput    = use the given blast results\n",
"  -deepSeq_runID = the ID of the deep sequencing run mandatory for a deep sequencing evaluation (!)\n",
"  -mode              = mode in which the matching algorithm should work.\n",
		"                       possible vales are: \n",
		"                       'addPrimer' \n",
"                           SPECIAL db is a fasta formated list of primers\n",
		"                       'BlastHit' \n",
"                          SPECIAL db is a fasta formated list of primers\n",
"                          Only the best Blast hit in respect to the e_value is used\n",
		"                       'Sequences' \n",
"                          SPECIAL db is a fasta formated list of primers\n",
"                          possible problems with masked repeats up to 10bp are ignored\n",
"                          Only the best Blast hit in respect to the e_value is used\n",
		"                       'AllBlastHits'\n",
"                          the same as 'BlastHit' but Blast Hit selection by maxMismatch and minPercent_Identity\n",
		"                       'doIMGTsearch' \n",
		"                          most probably broken - not used for years\n",
		"                       'deepSequencing' \n",
"                          try to create overlapping regions covered with matches to defined expressed gene structures\n",
		"                          experimental!\n"
	);
	return join( "", @print );
}

sub printVariables {
	my $i = 0;
	foreach my $variable (@_) {
		print "\tvariable $i = $variable\n";
		$i++;
	}
}
