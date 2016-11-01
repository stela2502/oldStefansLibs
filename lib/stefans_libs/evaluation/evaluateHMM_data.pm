package evaluateHMM_data;
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
use stefans_libs::database_old::fileDB;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::root;
use stefans_libs::gbFile;
use stefans_libs::evaluation::tableLine;
use stefans_libs::evaluation::summaryLine;
use stefans_libs::NimbleGene_config;

sub new {

    my ($class) = @_;

    my (
        $self,            %HMM,      %GB,         $dbh,
        $gbFile,          $root,     %Auswertung, %eval,
        %arrayResolution, %segments, $NimbleGene_config
    );
    $root              = root->new();
    $dbh               = $root->getDBH("NimbleGene_Arrays") or die $_;
    $gbFile            = gbFile::new("gbFile");
    $NimbleGene_config = NimbleGene_config->new();

    $self = {
        segmentCount      => \%segments,
        root              => $root,
        dbh               => $dbh,
        HMM               => \%HMM,
        NimbleGene_config => $NimbleGene_config,
        array_resolution  => \%arrayResolution,
        gbData            => \%GB,
        gbFile            => $gbFile,
        evaluation        => \%eval,
        auswertung        => \%Auswertung
    };

    bless( $self, $class ) if ( $class eq "evaluateHMM_data" );
    return $self;
}

=head2 AddData_HMM

=head3 atributes

[0]: absolute location of a singnalMap formated data file

=head3 method

This method uses the lib gffFile to import the enriched regions
as defined by the gffFile->getEnrichedRegions with a cuoff value of NimbleGene_config::CutoffValue().

The enriched regions are stored in $self->{HMM}->{atribute[0]}

=cut

sub AddData_HMM {
    ## hier wird ein File mit Statistischen Werten übergeben!

    my ( $self, $filename ) = @_;

    my ( $importer, $data, $fileHash, $name, $path, $parsedHMMfile, $temp );

    $importer = gffFile->new();

    $data     = $importer->getEnrichedRegions($filename, NimbleGene_config::CutoffValue());

    unless ( defined $self->{array_resolution}->{ $data->{info}->{designID} } )
    {
        print "Importing the array coverage setting cutoff value to '0'\n";
      #  print "Cutoff Value = ",$importer->getEnrichedRegions($filename, 0),"\n";
        $self->{array_resolution}->{ $data->{info}->{designID} } =
          $importer->getEnrichedRegions( $filename, 0 );
        print "Setting cutoff value to '0.99'\n";
    }

     

#	$name     = $self->{root}->getPureSequenceName($filename);
#    $parsedHMMfile = $self->ParseHMM_filename( $name->{filename} );
    $self->{designID} = $data->{info}->{designID};

    $self->{HMM}->{  $data->{info}->{filename} } = $data
      ; #{ antibody => $ak, celltype => $ct, organism => $org, data => resultItemList};

    return $self->{  $data->{info}->{filename} };
    ## in $self->{$name} ist jetzt ein Hash mit den Infos des HMM-Daten-Files und den
    ## Angereicherten Regionen in Form eines Arrays aus gbFeatures
}

=head2 Add_gbData

=head2 atributes

none

=head2 method

The HMM data enriched regions are stored in $self->{HMM}->{$HMM_Filename}->{$gbFilename}.
Foreach gbFilename the feature Information is imported using gbFile->addGbfile().
the gbFeature array is stored in $self->{gbData}->{$gbFilename}.

=head3 return values

1

=cut

sub Add_gbData {
    my ($self) = @_;

    my (
        %GB,        $HMM_data,     $gbData,   $fileameHMM, $filenameGB,
        $sth,       $filenameData, $HMM_Data, $gbFile,     $preamble,
        @ChIP_Info, $features,     $sequence, $length,     $seqFile,
        $temp,      $tag,          $importer
    );

	$importer = fileDB->new();
	
    $HMM_data = $self->{HMM};

    foreach $fileameHMM ( keys %$HMM_data ) {
        print "Adding File Info for file $fileameHMM\n";
        $HMM_Data = $HMM_data->{$fileameHMM};
        foreach $filenameGB ( keys %$HMM_Data ) {
            next if ( defined $self->{gbData}->{$filenameGB} || $filenameGB eq "info");
            print "Importing GB Data for file $filenameGB\n";
            $seqFile = undef;
            ( $preamble, $features, $sequence, $length ) =
              $self->{gbFile}->AddGbfile(
                $importer->SelectMatchingFileLocation(
                    $self->{designID}, $filenameGB 
                )
              );
            $tag = @$features;
            print "$tag features for file $filenameGB\n";# (",
              #$importer->getMatchingFileLocation(
              #  $filenameGB, $self->{designID}
              #),
              #", array ref = $features)\n";
            $self->{gbData}->{$filenameGB} = $features;
        }
    }
    return 1;
}

=head2 Create_EnrichedRegionsMatchingToGBdata

=head3 Method

Foreach hybridization type (Organism,CellType,AB,designID) a new table is created using the $self->InitTable method.
Each list of enriched region is added to the table osing the $self->AddHMMtoTable method.
The global data table is stored as $self->{globalDataTable}.

=head3 return value

The reference to the global data table is returned. The structure of that data table is
$table = {$HybType => { $gbFile => { $gbFeatureStart => tableLine object } } }.

=cut

sub Create_EnrichedRegionsMatchingToGBdata {
    my ($self) = @_;
    my ( $HMM, $table, $parsedHMMfile, $string, $HMM_File );

    $HMM = $self->{HMM};

    foreach $HMM_File ( sort keys %$HMM ) {
        ## Hier muss ein neuer table für jeden Typ der HMM Auswertung angelegt werden
        $parsedHMMfile = $self->ParseHMM_filename($HMM_File);
        $string        =
"$parsedHMMfile->{Organism}!$parsedHMMfile->{CellType}!$parsedHMMfile->{AB}!$parsedHMMfile->{designID}";
        $table->{$string} =
          $self->InitTable(
            $self->{array_resolution}->{ $parsedHMMfile->{designID} } )
          unless ( defined $table->{$string} );
        ## Alle HMM Regionen, die nicht in ein Feature Treffen sind in dieser Tabelle nicht mehr eingetragen!
        $self->AddHMMtoTable( $table->{$string}, $HMM->{$HMM_File}, $HMM_File );
    }
    $self->{globalDataTable} = $table;
    return $table;
}

sub CreateOutputPath {
    my ($self) = @_;

    my ( $path, $today );
    $path  = $self->{NimbleGene_config}->DataPath();
    $today = $self->{root}->Today();
    $path  = "$path/Tabellaric_Report/$today";
    $self->{root}->CreatePath($path);
    return $path;
}

sub WriteTable {
    my ( $self, $table_filename ) = @_;

    my (
        $table,          $HMM,       $HMM_File,      $temp,
        $header_written, $header,    $sum,           $data,
        $data_array,     $string,    $summary,       $result_line,
        $hit_tag,        $gene_tag,  $segment_Array, $Filename,
        $tag,            $ChIP_Info, @ChIP_Info,     $count,
        $parsedHMMfile,  @Temp,      $fileInfo,      $summaryLable
    );

    $table = $self->Create_EnrichedRegionsMatchingToGBdata();
    ## in dieser Tabelle sind alle gbFeatures eingetragen, die in dieser Analyse gefunden werden können.
    ## {Organism!CellType!Antibody}->{gbFilename}->{bpStart}->|tableLine|
    ## Die gbFeatures, die in der Analyse gefunden wurden sind schon markiert

    $HMM = $self->{HMM};

    ## Alle Daten Tabellarisch ausgeben:

    $fileInfo = $self->{root}->getPureSequenceName($table_filename);
    $fileInfo->{path} = $self->CreateOutputPath();

    $table_filename = "$fileInfo->{path}/$fileInfo->{MySQL_entry}";

    open( TABLE, ">$table_filename.csv" )
      or die "konnte $table_filename.csv nicht anlegen!\n";

    open( Auswertung_Summary, ">$table_filename.summary_evaluation.csv" )
      or die
      "konnte file $table_filename.percentual_evaluation.csv nicht anlegen!\n";

#    print TABLE
#"Organism\tCelltype\tAntibody\tfilename\tgbFeature name\tgbFeature tag\tHMM Hit Identifier\tgbFeature start\tgbFeature end\tIterations 1->n\n";
    foreach my $HMM_File_type ( keys %$table ) {

        $HMM_File = $table->{$HMM_File_type};
        @Temp     = split( "!", $HMM_File_type );

        #        @Temp     = split( " ", $Temp[ @Temp - 1 ] );
        ## $HMM_File_type is in the type Organism!CellType!Antibody!DesignID

        foreach my $filename ( keys %$HMM_File ) {
            $temp = $HMM_File->{$filename};
            foreach my $line ( values %$temp ) {
                next unless ( ref($line) eq "tableLine" );

                $data_array =
                  $line->GetActivationState()
                  ; ## aktivierungsDaten zu jedem eingetragenen HMM Auswertungsschritt!

                unless ( defined $header_written ) {
                    ## Header eintragen!
					my $string;
                    print TABLE $line->HeaderFirstTime();
					$string = $line->SummaryHeaderFirstTime();
					if ( defined $string){
						print Auswertung_Summary $string;
						$header_written = 1;
					}
                }    ## Header eingetragen!
                print TABLE $line->PrintBySummary();
                print Auswertung_Summary $line->PrintFirstTime();

                ## alle Daten für TABLE und Auswertung_Summary wurden ausgegeben!

                ## Prozentuale Auswertung erstellen für alle Ig- und TCR-Segmente
                #$gene_tag = $line->IsIg_gene();
				#print "does that match? @$data_array[0]->{Ig_type} should equal $gene_tag\n";
                if ( defined  @$data_array[0] && @$data_array[0]->{Ig_type} )
                {

                    $data      = @$data_array[0];
                    @ChIP_Info = (
                        $data->{organism}, $data->{celltype},
                        $data->{antibody}, $data->{gbFilename}, $Temp[@Temp-1] ## designID 
                    );
                    next if ( $data->{gbFilename} =~ m/TCRA-D/);
                    $summaryLable = join( "!", @ChIP_Info );

                    $summary = $data->{summary_data};

                    if ( defined $summary && @$summary > 0 ) {
                        $count = @$summary;
                        unless ( defined $sum->{ $summaryLable } ) {
                            print "new summaryLine reference = ",
                              join( ":", @ChIP_Info ), "\n";

                            $sum->{ $summaryLable } = summaryLine->new(
                                $data->{organism}, $data->{celltype},
                                $data->{antibody}, $data->{gbFilename},
                                $count
                            );
                        }
                        $sum->{ $summaryLable }->AddData($data_array);
                    }
                }
            }
        }
    }
    close(TABLE);
    print "Daten als $table_filename.csv geschrieben\n";

    close(Auswertung_Summary);
    print
      "Summary Daten als $table_filename.summary_evaluation.csv geschrieben\n";

    ## Auswertung der Tabellarischen Ig Daten schreiben
    my ( $tcra );

    open( Auswertung, ">$table_filename.percentual_evaluation.csv" )
      or die
      "konnte file $table_filename.percentual_evaluation.csv nicht anlegen!\n";

    $header = @ChIP_Info = undef;

    $tcra = 0;
    print Auswertung
      "how many segments were analyzed in the ChIP Array experiment?\n";

    $temp = $self->{segmentCount};
    $data_array = undef;

    foreach my $summaryLable ( sort keys %$sum ) {
        @ChIP_Info = split("!",$summaryLable);

        unless ( defined $data_array->{"$ChIP_Info[@ChIP_Info - 1]"}){
           my %temp;
           $data_array->{"$ChIP_Info[@ChIP_Info - 1]"} = \%temp;
        }
        $data_array->{"$ChIP_Info[@ChIP_Info - 1]"}->{header} = $sum->{$summaryLable}->SummaryHeader() 
            unless (defined $data_array->{"$ChIP_Info[@ChIP_Info - 1]"}->{header} );
        next if ( defined $data_array->{"$ChIP_Info[@ChIP_Info - 1]"}->{$sum->{$summaryLable}->{gbFilename}});
        $data_array->{"$ChIP_Info[@ChIP_Info - 1]"}->{$sum->{$summaryLable}->{gbFilename}} = $sum->{$summaryLable}->SummaryData();
    }
    foreach my $designID (keys %$data_array){
        print Auswertung "DesignID Nr. $designID\n";
        print Auswertung $data_array->{$designID}->{header};
        $temp = $data_array->{$designID};
        foreach my $filename (sort keys %$temp){
            print Auswertung $temp->{$filename} unless ( $filename eq "header");
        }
    } 

    foreach $summaryLable ( sort keys %$sum ) {
        @ChIP_Info = split("!",$summaryLable);
        print "Auswertung schreiben für ",join(", ",@ChIP_Info),"\n";
        if ( $tcra == 0 ) {
            print Auswertung $sum->{$summaryLable}->PrintHelp();
            print Auswertung $sum->{$summaryLable}->PrintHeader();

            #            print $sum->{$string}->PrintHelp();
            #            print $sum->{$string}->PrintHeader();

        }
        $tcra++;
        $data = $sum->{$summaryLable}->PrintData();
        print Auswertung $data->{V};
        if ( $summaryLable =~ m/TCRG/ && $tcra < keys %$sum ){
            print Auswertung "\n";
            print Auswertung $sum->{$summaryLable}->PrintHeader();
        }
    }

    $tcra = 0;
    print Auswertung "\n\n";
    foreach $summaryLable ( sort keys %$sum ) {
        if ( $tcra == 0 ) {
            print Auswertung $sum->{$summaryLable}->PrintHeader();
        }
        $tcra++;
        $data = $sum->{$summaryLable}->PrintData();
        print Auswertung $data->{D};
        if ( $summaryLable =~ m/TCRG/ && $tcra < keys %$sum ){
            print Auswertung "\n";
            print Auswertung $sum->{$summaryLable}->PrintHeader();
        }
    }

    $tcra = 0;
    print Auswertung "\n\n\n";
    foreach $summaryLable ( sort keys %$sum ) {
        if ( $tcra == 0 ) {
            print Auswertung $sum->{$summaryLable}->PrintHeader();
        }
        $tcra++;
        $data = $sum->{$summaryLable}->PrintData();
        print Auswertung $data->{J};
        if ( $summaryLable =~ m/TCRG/ && $tcra < keys %$sum ){
            print Auswertung "\n";
            print Auswertung $sum->{$summaryLable}->PrintHeader();
        }
    }

    close(Auswertung);
    print
      "Auswertung als $table_filename.percentual_evaluation.csv gesichert.\n";

}

sub ParseHMM_filename {
    my ( $self, $filename, $what ) = @_;
    my ( @temp, $data,     $temp );

    print "ParseHMM_filename $filename\n";

    @temp = split( "-", $filename );
    $data->{AB} = $temp[0];    ## immer

    #    $temp             = $temp[1];
    $data->{CellType} = $temp[1];
    $data->{Organism} = $temp[2];
    $data->{designID} = $1
      if ( $filename =~ m/(\d\d\d\d-\d\d-\d\d_RZPD\d\d\d\d_MM\d_ChIP)/ );
    $data->{Iteration} = $1 if ( $filename =~ m/IterationNr\.?(\d+)/ );

    #    $data->{AB} = "$data->{AB}" if ( defined $temp );

    #    $data->{Organism} = "Mus musculus";

    foreach $temp ( keys %$data ) {
        print "$temp -> $data->{$temp}\n";
    }

    return $data->{Organism}, $data->{CellType}, $data->{AB}, $data->{Iteration}
      if ( $what eq "array" );
    return $data;
}

sub initAuswertung {
    my ( $self, $filename ) = @_;
    my ( $organism, $celltype, $antibody, $designID, @temp, $iteration, $temp );
    ## alle rel. Informationen aus dem HMM Dateinamen extrahieren

    #    print "NEU NEU NEU NEU NEU NEU NEU\n";
    #    print "$filename\n";

    ( $organism, $celltype, $antibody, $iteration ) =
      $self->ParseHMM_filename($filename);

    unless ( defined $self->{auswertung}->{$organism} ) {    ## level 1
        my %temp;
        $self->{auswertung}->{$organism} = \%temp;
    }
    unless ( defined $self->{auswertung}->{$organism}->{$antibody} )
    {                                                        ## level 2
        my %temp;
        $self->{auswertung}->{$organism}->{$antibody} = \%temp;
    }
    unless (
        defined $self->{auswertung}->{$organism}->{$antibody}->{$celltype} )
    {                                                        ##level 3
        my %temp;
        $self->{auswertung}->{$organism}->{$antibody}->{$celltype} = \%temp;
    }
    unless (
        defined $self->{auswertung}->{$organism}->{$antibody}->{$celltype}
        ->{$iteration} )
    {
        my %temp;
        $self->{auswertung}->{$organism}->{$antibody}->{$celltype}
          ->{$iteration} = \%temp;
    }
    ## hier sollen die einzelenen Daten eingetragen werden!
    ## Datenstruktur bis jetzt:
    ## $self->{auswertung}->{$organism}->{$antibody}->{$celltype}->{$iteration}
    ## dazu kommt noch:
    ## ->{Ig_type}->{['[VDJ]_prozentAngereichert','[VDJ]_anzahlAngereichert','[VDJ]_anzahl']}
    print
"Init Auswertung: \$self->{auswertung}->{$organism}->{$antibody}->{$celltype}->{$iteration};\n";
    return $self->{auswertung}->{$organism}->{$antibody}->{$celltype}
      ->{$iteration};
}

sub AddHMMtoTable {
    ## $table = table-slide for one ChIP type; $HMM = hash {gbFilename}->gbFeatureArray; $HMM_info = HMM_data filename

    my ( $self, $table, $HMM, $HMM_info ) = @_;

    my ( $i, $hmm_parsed, $HMM_Data, $gbFilename, $gbFileSpecificTableSlide,
        $used, $tableLine_Start, $tableLine, $USED, $HMMfeature, $temp );

    $i = $USED = 0;

    $hmm_parsed = $self->ParseHMM_filename($HMM_info);

    foreach $gbFilename ( keys %$HMM ) {

        ## Für jeden HMM Datensatz testen, auf welchem gbFeature er trifft
		next if ( $gbFilename eq "info");
        $HMM_Data                 = $HMM->{$gbFilename};
        $gbFileSpecificTableSlide = $table->{$gbFilename};

        foreach $HMMfeature (@$HMM_Data) {
            $i++;
            $used = 0;

            #            print "!!!HMMfeature = $HMMfeature\n";
            foreach $tableLine_Start ( keys %$gbFileSpecificTableSlide ) {
                unless ( defined $gbFileSpecificTableSlide->{$tableLine_Start} ){
                   warn "gbFileSpecificTableSlide with key $tableLine_Start does not exist!!\n";
                   next;
                }
                $used++
                  if ( $gbFileSpecificTableSlide->{$tableLine_Start}->AddData( $hmm_parsed, $HMMfeature ) != 0 );

#                print "!!!tableLine_Start = $tableLine_Start\n";
#                $tableLine = $gbFileSpecificTableSlide->{$tableLine_Start};
#                next unless ( defined $tableLine ); ## das sollte eigentlich nie passieren!
#                $temp =  $tableLine->AddData( $hmm_parsed, $HMMfeature );
#                $used ++ if ( $temp != 0);

            }
            $USED++ if ( $used != 0 );
        }
    }
    print "AddHMMtoTable $HMM_info $i enriched regions, ", ( $USED / $i ) * 100,
      "% matched to gbFeatures\n";
}



=head2 InitTable

=head3 atributes

[0]: a reference to the absolute array coverage information as got by 
     plotGFF_Files_HMM->AddGFF_File using a cutoff value of 0 for HMM data 
     (all regions where Oligos bind get selected).

=head3 Method

A highly complex internal data structure is created. For each gbFile feature array a new
table->{gbFile} is created and each gbFeature that is covered by oligos is converted into
a object of the type tableLine.  

=head3 return values

The newly created hyb type specific table slide is returned.

=cut

sub InitTable {
    my ( $self, $Array_Coverage ) = @_;
    ## NEU!
    ## Table wird jetzt aus tableLine aufgebaut.
    ## Pro gbFeature eine TableLine
    
    warn "this method has to be changed!!!!!\n";

    my ( $gbData, $table, $filename, $fileData, $feature, $start,
        $arrayCoberage_FileData, $hmmCovered );

    $gbData = $self->{gbData};

    foreach $filename ( keys %$gbData ) {

        ## only gbFeatures that can in theory be found enriched with this Chip design are used
        if ( defined $Array_Coverage ) {
            $arrayCoberage_FileData = $Array_Coverage->{$filename};
            $fileData               = $gbData->{$filename};
            unless ( defined $table->{$filename} ) {
                my %temp;
                $table->{$filename} = \%temp;
            }
            foreach $feature (@$fileData) {
                foreach $hmmCovered (@$arrayCoberage_FileData) {
                    next unless ( ref($hmmCovered) eq "gbFeature");
                    if (
                        $feature->Match(
                            $hmmCovered->Start, $hmmCovered->End(), 0
                        )
                      )
                    {
                        $table->{$filename}->{ $feature->Start() } =
                          tableLine->new( $feature, $filename );
                        last;
                    }
                }
            }
        }
        else {
            warn
"all gbFeatures will be used - no check of chip coverage is performed!\n";
            $fileData = $gbData->{$filename};
            unless ( defined $table->{$filename} ) {
                my %temp;
                $table->{$filename} = \%temp;
            }

            foreach $feature (@$fileData) {
                $table->{$filename}->{ $feature->Start() } =
                  tableLine->new( $feature, $filename );
            }
        }
    }
    return $table;
}

sub getFileInfo {
    my ( $self, $file1 ) = @_;

    my ( @file, $ak, $org, $ct, $iteration );

    @file = split( "-", $file1 );

    if ( $file[1] eq "Rag" ) {
        $ak        = $file[0];
        $ct        = "$file[1]_$file[2]";
        $org       = $file[3];
        $iteration = $1 if ( $org =~ m/IterationNr(\d*)/ );
    }
    else {
        $ak        = $file[0];
        $ct        = $file[1];
        $org       = $file[2];
        $iteration = $1 if ( $org =~ m/IterationNr(\d*)/ );
    }

    @file = split( "_", $org );
    $org = "";
    foreach my $temp (@file) {
        $org = "$org$temp " unless ( $temp =~ m/Iteration/ );
    }
    return $ak, $ct, $org, $iteration;
}
1;
