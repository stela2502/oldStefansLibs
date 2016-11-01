package importHyb;
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
 
=for comment
 
 This document is in Pod format.  To read this, use a Pod formatter,
 like "perldoc perlpod".
 
=head1 NAME
 stefans_libs::importHyb
 
=head1 DESCRIPTION
 
 importHyb is the part of the libary, that manages the import of the NimbleGene hybridisation and enrichemnt value data.
 
=head2 Depends on
 
 L<stefans_libs::gbFile>
 
 L<stefans_libs::database::dataset::oligo_array_values>
 
 L<stefans_libs::database_old::array_GFF>
 
 L<stefans_libs::database::antibodyTable>
 
 L<stefans_libs::database_old::cellTypeDB>
 
 L<stefans_libs::database_old::hybInfoDB>
 
 L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::pairFile>
 
 L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile>
 
 L<stefans_libs::database_old::designDB>
 
 L<stefans_libs::designImporter>
 
 =head2 Provides
 
 L<AddAllDataInPath|"AddAllDataInPath">
 
 L<AddData|"AddData">
 
 #L<GetOligoIDs|"GetOligoIDs">
 
 L<interface_designID|"interface_designID">
 
 L<GetPairFiles|"GetPairFiles">
 
 L<GetGFF_Files|"GetGFF_Files">
 
 L<GetDesignFile|"GetDesignFile">
 
 L<userInterface|"userInterface">
 
 L<GetSampleInfo|"GetSampleInfo">
 
=head1 METHODS
 
=head2 new
 
 =head3 arguments
 
 none
 
=head 3 return value
 
 A new object of the class importHyb.
 
=cut
 
use strict;
use stefans_libs::gbFile;
use stefans_libs::database::dataset::oligo_array_values;
use stefans_libs::database_old::array_GFF;
use stefans_libs::database::antibodyTable;
use stefans_libs::database_old::cellTypeDB;
use stefans_libs::database_old::hybInfoDB;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::pairFile;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::database_old::designDB;
use stefans_libs::designImporter;
 
 sub new {
 
     my ( $class) = @_;
 
     my (
         %NimbleInfo, %HybValues, $cellTypeDB, $hybInfo,
         $gffFile,    $pairFile,  $antibodyDB, $dbh , $designDB
     );
     my $array_Hyb = array_Hyb->new();
     my $array_GFF = array_GFF->new();
     $antibodyDB = antibodyDB->new;
     $cellTypeDB = cellTypeDB->new();
     $hybInfo    = hybInfoDB->new();
     $gffFile    = gffFile->new();
     $pairFile   = pairFile->new();
     $designDB = designDB->new();
 
     my $self = {
 		noDataAdd  => "no data add",
         array_Hyb  => $array_Hyb,
         array_GFF  => $array_GFF,
         antibodyDB => $antibodyDB,
         cellTypeDB => $cellTypeDB,
         nimbleInfo => \%NimbleInfo,
         gffFile    => $gffFile,
         designDB => $designDB,
         pairFile   => $pairFile,
         hybInfo    => $hybInfo,
         dbh        => $dbh,
         hybValues  => \%HybValues,
         cy3        => "532",
         cy5        => "635",
 
         #        mode       => "test",
 #        path => $path
     };
 
     bless( $self, 'importHyb' );
 #    print "importHyb -> new() returns $self\n";
     return $self;
 }
 
=head2 AddAllDataInPath
 
 AddAllDataInPath is the main method to import the NimbleGene Array data.
 
 =head3 arguments
 
 path: the path to the NimbleGene array data (the base Directory where SampleKey.txt lies in.
 
=head3 method
 
 All types of array data are handled.
 The method L<GetDesignFile|"GetDesignFile"> handles the array design data stored in the path $path/DesignFiles/,
 the method L<GetSampleInfo|"GetSampleInfo"> handles the SampleKey.txt file,
 the method L<GetGFF_Files|"GetGFF_Files"> handles the NimbleGene enrichment factors (gff) in the path $path/GFF/ and
 the method L<GetPairFiles|"GetPairFiles"> handles the NimbleGene hybridization values in the path $path/PairData/.
 Finaly all information is stored with the method L<AddData|"AddData">.
 
 
=head3 return value 
 
 This method always retruns '1'.
 
=cut
 
 sub AddAllDataInPath {
 
     my ( $self, $path ) = @_;
 
     my ( @eintraege, $entry, $subpath_Pair, $subpath_GFF, @files, $infofile,
         $value, $key , $subpath_Design );
 
     opendir( PATH, $path )
       or die
 "Fehlermeldung: $!\nBitte geben sie Das Verzeichnis in dem die Array Daten liegen mit an!\n";
 
 	warn "Copy these files on a local hard disk or make shure, that these files are accessible during each evaluation process!\n";
 	
     @eintraege = readdir(PATH);
 
     closedir(PATH);
 
     $subpath_Pair = $subpath_GFF = $infofile = $path;
     print "Inhalte des pfades $path\n";
     print "self = $self\n";
     $self->{path} = $path;
     foreach $entry (@eintraege) {
 
         #     print "$entry\n";
         $subpath_Design = "$path/$entry/" if ( $entry =~ m/DesignFiles/ );
         $subpath_Pair = "$path/$entry/" if ( $entry =~ m/PairData/ );
         $subpath_GFF  = "$path/$entry/" if ( $entry =~ m/GFF/ );
         $infofile     = "$path/$entry"  if ( $entry =~ m/SampleKey/ );
     }
 
     $self->GetDesignFile($subpath_Design);
 
     $self->GetSampleInfo($infofile) if ( defined $infofile );
 
     $self->GetGFF_Files($subpath_GFF) if ( defined $subpath_GFF );
 
     $self->GetPairFiles($subpath_Pair) if ( defined $subpath_Pair );
 
 	root::print_hashEntries($self,5,"Dump of all my info prior to the $self->AddData step!\n");
 	
     $self->AddData();
 
     return 1;
 }
 
=head2 AddData
 
 AddData imports the hybridization and enrichemnt values from the NimbleGene provided text files into the local database.
 For the hybridization values it calls L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::pairFile/"GetData"> to import the array hybridization values and
 L<stefans_libs::database::dataset::oligo_array_values/"insertData"> to store the hybridization values into the database.
 For the enrichment factors if calls L<stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile/"GetData"> to import the enrichment factors and
 L<stefans_libs::database_old::array_GFF/"insertData"> to store the values into the database.
 
=cut
 
 sub AddData {
     my $self = shift;
     my ( $data, $NimbleIDs, $nimbleID );
 
     $NimbleIDs = $self->{nimbleInfo};
 	
 	#die "The method importHyb->AddData() is no longer valid!\n",
 	#"The MySQL database is no longer needed to stor the actual values in it!\n",
 	#"The method has to be changed to store the absolute locations of the pair- and enrichment files!\n";
     
  	foreach $nimbleID ( keys %$NimbleIDs ) {
 
         ## Add Cy5 Values
         if ( $self->{array_Hyb}
             ->DataExists( $self->{nimbleInfo}->{$nimbleID}->{Cy5}, "cy5" ) )
         {
             print
 "Daten fuer ChIP Nr. $nimbleID pairFile Cy5  wurden offensichtlich schon eingegeben!\nAbbruch\n";
         }
         
         else {
             $self->{array_Hyb}
               ->insertData( $self->{nimbleInfo}->{$nimbleID}->{Cy5},
                  undef , "nimblegene", $self->{nimbleInfo}->{$nimbleID}->{Cy5_File} );
         }
 		#next if (defined $self->{noDataAdd});
 
         ## Add Cy3 Values
         if ( $self->{array_Hyb}
             ->DataExists( $self->{nimbleInfo}->{$nimbleID}->{Cy3}, "cy3" ) )
         {
             print
 "Daten für ChIP Nr. $nimbleID pairFile Cy3  wurden offensichtlich schon eingegeben!\nAbbruch\n";
         }
         else {
             $self->{array_Hyb}
               ->insertData( $self->{nimbleInfo}->{$nimbleID}->{Cy3},
                 undef , "nimblegene", $self->{nimbleInfo}->{$nimbleID}->{Cy3_File} );
         }
 
 		
         ## Add GFF Values
         if ( $self->{array_GFF}
             ->DataExists( $self->{nimbleInfo}->{$nimbleID}->{Cy3} ) )
         {
             print
 "Daten für ChIP Nr. $nimbleID GFF  wurden offensichtlich schon eingegeben!\nAbbruch\n";
         }
         else {
             $self->{array_GFF}
               ->insertData( $self->{nimbleInfo}->{$nimbleID}->{Cy3},
                 undef, "nimblegene", $self->{nimbleInfo}->{$nimbleID}->{GFF_File} );
         }
 
     }
 }
 
=head2 GetPairFiles
 
 This method uses the internal data hash $self->{nimbleInfo} to recieve the NimbleGene array IDs
 and searches the $path/PairData/ for hybridization files containing these NimbleGene IDs in the
 filename. It also resolves the labeling state (cy3 or cy5) and stores the complete filename in the
 $self->{nimbleInfo}->{$nimbleID}->{Cy[35]_File} hash value.
 
=cut
 
 sub GetPairFiles {
     my ( $self, $path ) = @_;
     my ( @eintraege, $eintrag, $NimbleIds, $key );
 
     opendir( Pair_PATH, $path ) or die "$self->GetPairFiles Path - Probleme '$path'\n";
     @eintraege = readdir(Pair_PATH);
     closedir(Pair_PATH);
 
     $NimbleIds = $self->{nimbleInfo};
 
     foreach $eintrag (@eintraege) {
         ## Pattern matching!!
         foreach my $nimbleID ( keys %$NimbleIds ) {
             if ( $eintrag =~ m/$nimbleID/ ) {
                 if ( $eintrag =~ m/$self->{cy3}/ ) {
                     $self->{nimbleInfo}->{$nimbleID}->{Cy3_File} =
                       "$path$eintrag";
                 }
                 elsif ( $eintrag =~ m/$self->{cy5}/ ) {
                     $self->{nimbleInfo}->{$nimbleID}->{Cy5_File} =
                       "$path$eintrag";
                 }
             }
         }
     }
 }
 
=head2 GetGFF_Files
 
 This method uses the internal data hash $self->{nimbleInfo} to recieve the NimbleGene array IDs
 and searches the $path/GFF/ for gff files containing these NimbleGene IDs in the
 filename. It stores the complete filename in the
 $self->{nimbleInfo}->{$nimbleID}->{GFF_File} hash value.
 
=cut
 
 
 sub GetGFF_Files {
     my ( $self, $path ) = @_;
 
     my ( @eintraege, $eintrag, $NimbleIds, $key );
 
     opendir( GFF_PATH, $path ) or die "$self->GetGFF_Files Path - Probleme '$path'\n";
     @eintraege = readdir(GFF_PATH);
     closedir(GFF_PATH);
 
     $NimbleIds = $self->{nimbleInfo};
 
     foreach $eintrag (@eintraege) {
         ## Pattern matching!!
         foreach $key ( keys %$NimbleIds ) {
             if ( $eintrag =~ m/$key/ ) {
                 $self->{nimbleInfo}->{$key}->{GFF_File} = "$path$eintrag";
             }
         }
     }
 }
=head2 GetDesignFile
 
 This method simply searchs for the NimbleGene ndf file, that contains the oligo sequences
 and stores this file in the $self->{designFile} hash value.
 
=cut
 
 sub GetDesignFile {
     my ( $self, $path) = @_;
     my ( @eintraege, $eintrag, $Design, $key );
     opendir( GFF_PATH, $path ) or die "$self->GetDesignFile Path - Probleme '$path'\n";
     @eintraege = readdir(GFF_PATH);
     closedir(GFF_PATH);
     $Design = $self->{designFile};
 
     foreach $eintrag (@eintraege) {
          $self->{designFile} = "$path$eintrag" if ( $eintrag =~ m/ChIP\.ndf/);
     }
 }
 
=head2 userInterface
 
 This method is called to interprete the SampleKey.txt file.
 The layout of this interface has to be improved, but most probably it should be replaced by a GUI.
 
 The function in short: foreach hybridization type (cy3 or cy5) you have to specify the antibody and the celltype,
 that has been used for this experiment. You get a list of known celltypes or known antibodys where you have to specify
 the ID of the antibody or celltype that was used in this experiment.
 If the used antibody or celltype is presented in the list you have to insert a new entry into the database giving the 'n' character.
  
=cut
 
 sub userInterface {
     my ( $self, $what, $line, $nimbleID ) = @_;
 
     my ( $temp, $Id, $key, $antibodyDB,@line );
     @line = split("\t",$line);
 
     if ( $what eq "AB" ) {
         print 
           "**   User Help Required!   \n",
 "** could you please specify whih Antibody has been used to precipitate here? \n";
         $antibodyDB = $self->{antibodyDB}->GetAllAntibodyInfosByID();
         print "** Possible antibodys:\n";
         print "** ID\tSpecificity";
         foreach my $ID ( sort keys %$antibodyDB ) {
             print
               "$antibodyDB->{$ID}->{ID}\t$antibodyDB->{$ID}->{Specificity}\n"
               if ( defined $antibodyDB->{$ID} );
         }
         print
 #"  $line **\n",
 "** LINE-INFOS: $line[7]\t$line[8]\t$line[9]**\n",
 "** Antibody-ID (p = Abbruch , n = neue Info eingebn): \n";
         $Id = undef;
         $Id = <STDIN>;
         chop $Id;
         $self->intefaceAdd( $what, $nimbleID ) if ( $Id eq "n" );
         die if ( $Id eq "q" );
         if ( defined $antibodyDB->{$Id} ) {
             return $antibodyDB->{$Id}->{Specificity};
 
 #              $self->{nimbleInfo}->{$nimbleID}->{AntibodyID} = $Id;
 #              $self->{nimbleInfo}->{$nimbleID}->{Specificity} =  $antibodyDB->{$Id}->{Specificity};
         }
         else {
             return $self->userInterface( $what, $line, $nimbleID );
         }
 
         #        return $self->{nimbleInfo}->{$nimbleID}->{Specificity};
     }
     if ( $what eq "Cell" ) {
         print "-- User Help Required! \n",
           "-- could you please specify whitch Celltype has been used?\n";
         my ( $cellTypeDB, $rv, $ID );
         $cellTypeDB = $self->{cellTypeDB}->GetAllCellInfosByID();
         print "Possible Celltypes:\n";
         print "ID\tOrganism\tCelltype\n";
         foreach $ID ( sort keys %$cellTypeDB ) {
             print
 "$cellTypeDB->{$ID}->{ID}\t$cellTypeDB->{$ID}->{Organism}\t$cellTypeDB->{$ID}->{Celltype}\n";
         }
         print
 "------------------------------------------------------------------\n",
 #"-- $line --\n",
 "-- LINE-INFOS: $line[7]\t$line[8]\t$line[9]\n",
 "-- Zelltype-ID (q = Abbruch, n = neue Info eingeben):\n";
         $Id = undef;
         $Id = <STDIN>;
         die if ( $Id =~ m/q/ );
 
         $self->intefaceAdd( $what, $nimbleID ) if ( $Id =~ m/n/ );
 
         chop $Id;
         if ( defined $cellTypeDB->{$Id} ) {
 
             #               $self->{nimbleInfo}->{$nimbleID}->{Cell} = $Id;
             print "---------------------------------------------\n",
 "-- used $cellTypeDB->{$Id}->{Celltype} , $cellTypeDB->{$Id}->{Organism} --\n",
               "---------------------------------------------\n";
             return $cellTypeDB->{$Id}->{Celltype},
               $cellTypeDB->{$Id}->{Organism};
 
 #               $self->{nimbleInfo}->{$nimbleID}->{Celltype} = $cellTypeDB->{$Id}->{Celltype};
 #               $self->{nimbleInfo}->{$nimbleID}->{Organism} = $cellTypeDB->{$Id}->{Organism};
 #               print "-------------------\n",
 #                     "-- Added ID $Id! --\n",
 #                     "-------------------\n";
         }
         else {
             return $self->userInterface( $what, $line, $nimbleID );
         }
 
         #        return 1;
     }
 }
 
 sub intefaceAdd {
     my ( $self, $what, $nimbleID ) = @_;
 
     my ( $temp, $spez, $herst, $orderID );
     if ( $what eq "AB" ) {
         print "Bitte Geben geben Sie die Spezifität an\n";
         $spez = undef;
         $spez = <STDIN>;
         chop $spez;
         print "Bitte Geben geben Sie den Hersteller an:\n";
         $herst = undef;
         $herst = <STDIN>;
         chop $herst;
         print "Bitte Geben geben Sie den ProduktID ein:\n";
         $orderID = undef;
         $orderID = <STDIN>;
         chop $orderID;
 
         while ( !( $temp =~ m/[yYnNjJ]/ ) ) {
             print
 "sind diese Angaben korrekt?(J/N)\nSpezifität = $spez\tHersteller = $herst\tProduktID = $orderID\n";
             $temp = undef;
             $temp = <STDIN>;
         }
         if ( $temp =~ m/[nN]/ ) {
             $self->intefaceAdd( $what, $nimbleID );
             return;
         }
         $self->{antibodyDB}->insertData( $herst, $orderID, $spez );
         $self->{nimbleInfo}->{$nimbleID}->{AntibodyID} =
           $self->{antibodyDB}->SelectId_BySpecificity($spez);
         return;
     }
     if ( $what eq "Cell" ) {
         my ( $celltype, $organism );
         print "Bitte Geben geben Sie den Organismus an\n";
         $organism = undef;
         $organism = <STDIN>;
         chop $organism;
         print "Bitte Geben geben Sie den Zelltyp an:\n";
         $celltype = undef;
         $celltype = <STDIN>;
         chop $celltype;
 
         while ( !( $temp =~ m/[yYnNjJ]/ ) ) {
             print
 "sind diese Angaben korrekt?(J/N)\nOrganismus = $organism\tZelltyp = $celltype\n";
             $temp = undef;
             $temp = <STDIN>;
         }
         if ( $temp =~ m/[nN]/ ) {
             $self->intefaceAdd( $what, $nimbleID );
             return;
         }
         $self->{cellTypeDB}->insertData( $celltype, $organism );
         $self->{nimbleInfo}->{$nimbleID}->{Cell} =
           $self->{cellTypeDB}->SelectID_ByCellType( $celltype, $organism );
         return;
     }
 }
 
=head2 GetSampleInfo
 
 GetSampleInfo reads the 'SampleKey.txt' line per line and tries to recieve the experimental conditions for this experiment.
 If user interaction is needed the method L<userInterface|"userInterface"> or L<interface_designID|"interface_designID"> is called.
 
 If the NimbleGene 'ChIP on chip' design is not yet imported, the function L<stefans_libs::designImporter/"AddDesign"> is called.
 The information for this functio is recieved by the method L<interface_designID|"interface_designID">.
 
=cut
 
 sub GetSampleInfo {
 
     my ( $self, $infofile ) = @_;
     my (
         $temp,     @line,       $i,          $type,     $dye,
         $Design,   $Identifier, $nimbleID,   $antibody, $celltype,
         $organism, $Marker,     $DesignName, $templateType
     );
     open( INFO, "<$infofile" )
       or die "Konnte File $infofile nicht öffnen!\n";
     print "opened $infofile\n";
 
     while (<INFO>) {
         chomp $_;
         next if ( $_ =~ m/^#/);
         $nimbleID = $antibody = $celltype = $organism = $Marker = $DesignName =
           $templateType = undef;
         @line = split( "\t", $_ );
         if ( $self->{mode} eq "test" ) {
             $i = 0;
             foreach $temp (@line) {
                 print $i++, "  -> $temp; ";
             }
             print "\n";
         }
 
         $templateType = "TOTAL"        if ( $_ =~ m/TOTAL/ );
         $templateType = "EXPERIMENTAL" if ( $_ =~ m/EXPERIMENTAL/ );
 
         if ( int( $line[1] ) ) {
             print "NumbleGene ID(?) = $line[1]\n";
             $nimbleID = $line[1];
 
             unless ( defined $self->{nimbleInfo}->{ $line[1] } ) {
                 my %temp;
                 $self->{nimbleInfo}->{ $line[1] } = \%temp;
             }
 #            print "Step1;\n";
 
             #              print "GetSampleInfo: -> $line[1], $line[2]\n";
             foreach $temp (@line) {
                 $DesignName = $temp if ( $temp =~ m/ChIP/ );
                 $Marker     = $temp if ( $temp =~ m/Cy[35]/ );
                 $Identifier = $temp if ( $temp =~ m/SOM\d*/ );
             }
 #            print "Step2\n";
 #            $self->{nimbleInfo}->{"$line[1]"}->{$dye} = {
 #                NimbleID    => "$line[1]",
 #                Dye         => "$dye",
 #                DesignName  => "$Design",
 #                SampleLable => "$Identifier",
 #                Type        => "$type"
 #            };
 #            print "Step3\n";
             if ( $_ =~ m/EXPERIMENTAL/ ) {
                 print "EXPERIMENTAL\n";
                 $antibody =
                   $self->userInterface( "AB", join( "\t", @line ), $line[1] );
                 ( $celltype, $organism ) =
                   $self->userInterface( "Cell", join( "\t", @line ), $line[1] );
             }
             if ( $_ =~ m/TOTAL/ ) {
                 print "INPUT\n";
                 $antibody = "INPUT";
                 ( $celltype, $organism ) =
                   $self->userInterface( "Cell", join( "\t", @line ), $line[1] );
 
 #                $self->{nimbleInfo}->{"$line[1]"}->{$dye}->{Specificity} = "INPUT";
             }
 #            print "Final\n";
             while ( ! ( defined $self->{nimbleInfo}->{$nimbleID}->{$Marker})){
  #            print "HybInfo->insertData \$nimbleID, \$Marker, \$antibody, \$celltype, \$organism, ",
  #               "\$templateType, \$DesignName = $nimbleID, $Marker, $antibody, $celltype, $organism, ",
  #               "$templateType, $DesignName\n";
 
             $self->{nimbleInfo}->{$nimbleID}->{$Marker} =
               $self->{hybInfo}
               ->insertData( $nimbleID, $Marker, $antibody, $celltype, $organism,
                 $templateType, $DesignName );
 
 #            print "Inset is ready $self->{nimbleInfo}->{$nimbleID}->{$Marker}\n";
 
             ## falls $self->{nimbleInfo}->{$nimbleID}->{$Marker} jestz keine Zahl ist, sondern einer der folgenden Strings
             ## ist was falsch gelaufen (!) der jeweilige Eintrag wurde dann nicht in der Datenbank gefunden!
             ## antibody celltype design
             ## antibody und celltype dürften ja eigentlich nicht mehr auftreten, das design könnte uns aber noch passieren
 
 #            print "importHyb got $self->{nimbleInfo}->{$nimbleID}->{$Marker}\n";
 
             if ( $self->{nimbleInfo}->{$nimbleID}->{$Marker} eq "design" ) {
                 my $designImporter = designImporter->new();
                 $self->{nimbleInfo}->{$nimbleID}->{$Marker} = undef;
                 warn "das Design wurde noch nicht eingegeben!\n";
                 $designImporter->AddDesign($self->interface_designID($DesignName));
             }
            } 
             
         }
         else { print "Not Used Infos: $_;\n"; }
     }
     close(INFO);
     return $self;
 }
  
=head2 interface_designID
 
 This method is used to insert the array design information into the database.
 
 The whole program is based on locally stored ncbi genome data. From this genome data the 
 regions which are represented on the 'ChIP on chip' array are extracted so you easily can insert
 your own information into these files as i.e. regulative regions unknown to the genome project.
 Therefor you have to download the NCBI genome data from L<ftp://ftp.ncbi.nih.gov/genomes/>.
 All the information needet for the array design import are stored in the NCBI genome data
 . Simply answer the questions. 
 
 The import algorithm lies in L<stefans_libs::database_old::designDB/"insertData">
 
=cut
 
 sub interface_designID {
 
     my ( $self, $DesignName ) = @_;
     ## Nead to read the genomeBuild,  the personal identifier, the array_designInfo file,
     ## the NCBI seq_contig_file, the path2NCBI_Chromosomes, the Organism and the wanted NCBI group_label 
 
     my ( $genomeBuild, $identifier, $array_designInfo, $seq_contig_file, $Organism, $path2NCBI_Chromosomes, $group_label, $listWithAdditionalSequences );
 
     while ( ! ( defined $genomeBuild)){
     print
 "Bitte geben sie die Genom Version an, auf der das Array-Design basiert!\n";
     $genomeBuild = <STDIN>;
     chomp $genomeBuild;
     $genomeBuild = undef if ( $genomeBuild eq "");
     }
 
     while ( ! ( defined $identifier )){
     print "Bitte geben sie ihre persönliche Nummer das Array Design an\n   ";
     $identifier = <STDIN>;
     chomp $identifier;
     $identifier = undef if ( $identifier eq "");
     }
 
     while ( ! ( defined $array_designInfo)){
     print "Bitte geben sie die absolute Position des ArrayDesign Files an, das sie auch an NimbleGene geschickt haben:\n";
     $array_designInfo = <STDIN>;
     chomp $array_designInfo;
     $array_designInfo = undef if ( $array_designInfo eq "");
     }
 
     while ( ! ( defined $seq_contig_file)){
     print "Bitte geben sie die absolute Position der NCBI seq_contig.mp Datei an, die zu dem Genome Build $genomeBuild gehört\n";
     $seq_contig_file = <STDIN>;
     chomp $seq_contig_file;
     $seq_contig_file = undef if ( $seq_contig_file eq "");
     }
 
     while ( ! ( defined $Organism)){
     print "Bitte geben sie den Organismus an\n";
     $Organism = <STDIN>;
     chomp $Organism;
     $Organism = undef if ( $Organism eq "");
     }
 
     while ( ! ( defined $path2NCBI_Chromosomes )){
     print "Bitte geben sie den absoluten Pfad zu den NCBI Chromosom-Daten an\n";
     $path2NCBI_Chromosomes = <STDIN>;
     chomp $path2NCBI_Chromosomes;
     $path2NCBI_Chromosomes = undef if ( $path2NCBI_Chromosomes eq "");
     }
 
     while ( ! ( defined $group_label)){
     print "Bitte geben sie die Sequenz Gruppe an, von der die Sequenzen stammen sollen (NCBI group_label z.B. C57BL/6J)\n";
     $group_label = <STDIN>;
     chomp $group_label;
     $group_label = undef if ($group_label eq"");
     }
 
     while ( ! ( defined $listWithAdditionalSequences)){
     print "Falls Sie eine Liste mit zusätzlichen Files besitzen, die ebenfalls mit dem Array-Design \n",
           "ausgewertet werden soll geben Sie sie bitte hier an:\n";
     $listWithAdditionalSequences = <STDIN>;
     chomp $listWithAdditionalSequences;
     $listWithAdditionalSequences = undef if ( $listWithAdditionalSequences eq "");
     }
 
     print "Die Genom Version = $genomeBuild\npersönliche Design Nummer = $identifier\n",
           "absolute Position des ArrayDesign Files = $array_designInfo\n",
           "Die NCBI seq_contig.mp Datei = $seq_contig_file\n",
           "Der Organismus = $Organism\n",
           "Der absoluten Pfad zu den NCBI Chromosom-Daten = $path2NCBI_Chromosomes\n",
           "Die NCBI Sequenz Gruppe = $group_label\n",
           "Die zusätzliche Datei = $listWithAdditionalSequences\n";
     print "Stimmen diese Werte?\n";
 
     my $test = <STDIN>;
     chomp $test;
 
     unless ( $test eq "" || $test =~ m/^[Jj]/ ) {
         return $self->interface_designID();
     }
     print
       " Design ID für Array Design $DesignName, $genomeBuild, $identifier = ";
     $test =
       $self->{designDB}->insertData( $identifier, $genomeBuild, $DesignName, -1, $self->{designFile} );
     print "$test\n";
 
     return $DesignName, $array_designInfo, $seq_contig_file,
         $genomeBuild, $Organism, $path2NCBI_Chromosomes, $group_label, $listWithAdditionalSequences;
 
 }
 1;
