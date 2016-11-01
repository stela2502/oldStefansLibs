package designImporter;
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
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile;
use stefans_libs::database_old::designDB;
use stefans_libs::NimbleGene_config;
use stefans_libs::sequence_modification::blastResult;
use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use stefans_libs::chromosome_ripper::seq_contig;
use stefans_libs::chromosome_ripper::gbFileMerger;
use stefans_libs::database_old::fileDB;
use stefans_libs::gbFile;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::designImporter

=head1 DESCRIPTION

The class designImporter is used to import NimbleGene Array Designs into a MySQL Database.

=head2 Depends on

the NCBI megablast program
 
L<::nimbleGeneFiles::ndfFile>, 

L<::database::designDB>, 

L<::NimbleGene_config>,

L<::sequence_modification::blastResult>,

L<::database::nucleotide_array::oligo2dnaDB>,

L<::chromosome_ripper::seq_contig>,

L<::chromosome_ripper::gbFileMerger>,

L<::database::fileDB> and

L<::gbFile>.


=head2 Provides

L<AddDesign|"AddDesign">,

L<DoBlast4designString|"DoBlast4designString">,

L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles">,

L<createFastaDB|"createFastaDB">.


=head1 METHODS

=head2 new

designImporter->new() returns a new designImporter object.

=cut

sub new {
    my ($class) = @_;

    my (
        $self,         $blastResult, $designDB,  $oligo2dnaDB, $seq_contig,
        $gbFileMerger, $fileDB,      $oligo2DNA, $ndfFile
    );

    $blastResult  = blastResult->new();
    $oligo2DNA    = oligo2dnaDB->new();
    $designDB     = designDB->new();
    $ndfFile      = ndfFile->new();
    $seq_contig   = seq_contig->new;
    $gbFileMerger = gbFileMerger->new;
    $fileDB       = fileDB->new;

    $self = {
        blastResult  => $blastResult,
        oligo2DNA    => $oligo2DNA,
        designDB     => $designDB,
        ndfFile      => $ndfFile,
        seq_contig   => $seq_contig,
        gbFileMerger => $gbFileMerger,
        fileDB       => $fileDB
    };

    bless( $self, $class ) if ( $class eq "designImporter" );

    return $self;
}

=head2 AddDesign

This Method uses L<::database::fileDB> to check if the chromosomal regions that
are represented on this 'ChIP on chip' array are already extracted from the NCBI genome database.
If these files are not found it first invoces the method L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles">,
second adds all filenames found in the text file arguments[7] together with the newly created chromosomal representations to the fileBD 
using the L<database::fileDB/"insertData">
and finally invoces the method L<DoBlast4designString|"DoBlast4designString">.

=head3 arguments

[0]: the array design identification string

[1]: described in L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles"> atribute[0]

[2]: described in L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles"> atribute[1]

[3]: described in L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles"> atribute[2]

[4]: described in L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles"> atribute[3]

[5]: described in L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles"> atribute[4]

[6]: described in L<ChromosomalRegions2SeqFiles|"ChromosomalRegions2SeqFiles"> atribute[5]

[7]: The path to a txt formated file with the location of additional 
genbank formated sequences that have to be used for the ChIP evaluation. This variable can be undefined.

=cut

sub AddDesign {
    my (
        $self,                  $DesignString,
        $array_designInfo,      $seq_contig_file,
        $NCBI_Genome_Build,     $Organism,
        $path2NCBI_Chromosomes, $group_label,
        $listWithAdditionalSequences
      )
      = @_;

    my (
        $blastLines, $fastaDB,  $fastaData, $designDB,
        $tempDir,    $fileList, $temp
    );

    $tempDir = NimbleGene_config::TempPath();

    unless ( $self->{fileDB}->DataExists($DesignString) ) {
        print
"File references could not be found in the Database!\nCreating gbFiles and putting the references into the database\n";
        my $outpath = NimbleGene_config::DataPath();
        $outpath = "$outpath/Files/$DesignString";

        $fileList =
          $self->ChromosomalRegions2SeqFiles( $array_designInfo,
            $seq_contig_file, $NCBI_Genome_Build, $Organism,
            $path2NCBI_Chromosomes, $group_label, $outpath );
        print "Crated these files:\n";
        foreach my $temp (@$fileList) {
            print "$temp\n";
        }
        $self->{fileDB}->insertData( $DesignString, $fileList );    #
        if ( open( Add, "<$listWithAdditionalSequences" ) ) {
            while (<Add>) {
                chomp $_;
                my @temp = ($_);
                $self->{fileDB}->insertData( $DesignString, \@temp );
            }
        }

        $self->DoBlast4designString($DesignString);
        return 1;
    }
    return 0;

}




=head2 DoBlast4designString

This method matches the oligos on the 'ChIP on chip' array to the genbank formated files representing the 'ChIP on chip' array.

=head3 depends on
 
The NCBI megablast program as it is used for sequence matching.

=head3 arguments

[0] = The 'ChIP on chip' array design string as accepted by L<database::fileDB/"SelectFiles_ByDesignId">.

=head3 method

(1) the blast formated oligo database is created by the method L<createFastaDB|"createFastaDB">

(2) the genbank formated sequence files that represent the 'ChIP on chip' array design are located 
by the method SelectFiles_ByDesignId in L<stefans_libs::database_old::fileDB/"SelectFiles_ByDesignId">.

(3) a megablast search foreach genbank file is initiated

(4) the full length oligo hits are recovered using the method readBlastResults in L<stefans_libs::sequence_modification::blastResult/"readBlastResults">
with minLength = 49, minPercIdent = 100, maxGapOpen = 0 and the DoIMGTsearch mode definition 'AllBlastHits'

(5) all valid oligo matches are inserte into the MySQL database using the method insertData in L<stefans_libs::database::nucleotide_array::oligo2dnaDB/"insertData">.

=cut

sub DoBlast4designString {
    my ( $self, $DesignString, $DesignString_Files ) = @_;
    my ( $fileList, @temp, $tempDir, $fastaDB, $fastaData, $temp, $blastLines );

    $tempDir = NimbleGene_config::TempPath();
    $fastaDB = "$tempDir/test.fasta";

    ## create DesignFile hash und fasta DB für BLAST
    print "creating fasta formated Oligo DB\n";
    $fastaData = $self->createFastaDB( $DesignString, $fastaDB );
    print "ready\n";


    ## Getting gbFiles from th DB
	$DesignString_Files =  $DesignString unless ( defined $DesignString_Files);
    $fileList = $self->{fileDB}->SelectFiles_ByDesignId($DesignString_Files);
    @temp     = keys %$fileList;
    $fileList = \@temp;

    ## Blast Seach
    foreach my $filename (@$fileList) {
        print "insert OligoData for filename $filename\n";
		if ( $self->{oligo2DNA} -> DataExists ($DesignString, $filename) ){
			print "oligo2dna data for gbFile $filename has already been inserted!\n";
			next;
		}
        ##create input file
        $temp = gbFile->new();
        $temp->AddGbfile($filename);

        $temp->WriteAsFasta( "$tempDir/input.fasta", $temp->Name() );
        ## Run BLAST
        print
"megablast -W 40 -m 8 -D 3 -i $tempDir/input.fasta -d $fastaDB -o $tempDir/blast.tabel\n";
        system(
"megablast -W 40 -m 8 -D 3 -i $tempDir/input.fasta -d $fastaDB -o $tempDir/blast.tabel"
        );
        ## Read BLAST results
        $blastLines =
          $self->{blastResult}
          ->readBlastResults( "$tempDir/blast.tabel", 49, 100, 0,
            "AllBlastHits" );
        ## insert BLAST results in DB
        $self->{oligo2DNA}
          ->insertData( $DesignString, $blastLines, $filename, $fastaData );
    }
    return 1;
}

=head2 ChromosomalRegions2SeqFiles

ChromosomalRegions2SeqFiles uses L<stefans_libs::chromosome_ripper::seq_contig> and L<stefans_libs::chromosome_ripper::gbFileMerger>
(1) extract the chromosme information from the NCBI genome data and
(2) uses the NimbleGene Array Design Instructions to create the genbank files

=head3 arguments

The arguments have to be issued in this exact sequence!

[0]: described in L<stefans_libs::chromosome_ripper::gbFileMerger/"Create_GBfiles">

[1]: described in L<stefans_libs::chromosome_ripper::seq_contig/"insertDataFile">

[2]: described in L<stefans_libs::chromosome_ripper::seq_contig/"insertDataFile">

[3]: described in L<stefans_libs::chromosome_ripper::seq_contig/"insertDataFile">

[4]: described in L<stefans_libs::chromosome_ripper::gbFileMerger/"Create_GBfiles">

[5]: described in L<stefans_libs::chromosome_ripper::gbFileMerger/"Create_GBfiles"> default is 'C57BL/6J'

[6]: described in L<stefans_libs::chromosome_ripper::gbFileMerger/"Create_GBfiles">

=head3 return value

See L<stefans_libs::chromosome_ripper::gbFileMerger/"Create_GBfiles">

=cut

sub ChromosomalRegions2SeqFiles {
    my ( $self, $array_designInfo, $seq_contig_file, $NCBI_Genome_Build,
        $Organism, $path2NCBI_Chromosomes, $group_label, $outpath )
      = @_;

    my ($fileList);

    $self->{seq_contig}
      ->insertDataFile( $seq_contig_file, $NCBI_Genome_Build, $Organism );

    $group_label = "C57BL/6J" unless ( defined $group_label );
    system("mkdir -p $outpath");

    return $self->{gbFileMerger}
      ->Create_GBfiles( $array_designInfo, $outpath, $group_label,
        $NCBI_Genome_Build, $path2NCBI_Chromosomes );
}

=head2 createFastaDB

=head3 atributes

[0]: the ChIP on chip design id as accepted by L<database::designDB/"SelectId_ByArrayDesignString">

[1]: the absolute filename to write the fasta formated oligo database to

=head3 method

createFastaDB uses the L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile/"SelectDesignFile_ById">
to extract the oligo sequence data from the NimbleGene design files
, L<stefans_libs::database_old::designDB> to find the NimbleGene DesignFile location and
L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile/"WriteAsFastaDB"> to save the fasta formated oligo database.

=head3 return values

See L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile/"WriteAsFastaDB">

=cut

sub createFastaDB {
    my ( $self, $DesignString, $fastaDB ) = @_;
    my ( $NDF_File, $designDB, $designFile, $fastaData );

    $NDF_File   = ndfFile->new();
    $designDB   = designDB->new();
    $designFile =
      $designDB->SelectDesignFile_ById(
        $designDB->SelectId_ByArrayDesignString($DesignString) );
    $fastaData = $self->{ndfFile}->WriteAsFastaDB( $designFile, $fastaDB );
    system("formatdb -p F -i $fastaDB -o T -V");

    return $fastaData;
}

1;
