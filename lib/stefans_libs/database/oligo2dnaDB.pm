package oligo2dnaDB;
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
use stefans_libs::root;
use stefans_libs::database::fileDB;
use stefans_libs::database::designDB;
use stefans_libs::NimbleGene_config;
use stefans_libs::histogram;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::chromosome_ripper::gbFileMerger

=head1 DESCRIPTION

This class is used to create the sequence files corresponding to the NimbleGene array design.
It uses the NimbleGene array design order file and a downloaded version of the NCBI genome version on which the array sdesign is based.

=head2 Depends on

L<::root>

L<::NimbleGene_config>

L<::database::fileDB>

L<::database::designDB>

=head2 Provides

L<CreateDB|"CreateDB">

L<insertData|"insertData">

L<GetOligoLocationArray|"GetOligoLocationArray">

L<DataExists|"DataExists">

L<GetInfoID|"GetInfoID">

=head1 METHODS

=head2 new

=head3 arguments

none

=head 3 return value

A new object of the class gbFileMerger.

=cut

sub new {

    my ($class) = @_;

    my ( $self, $dbh, $root, $fileDB, $NimbleGene_config, $designDB, %oligoData );

    $root              = root->new();
    $fileDB            = fileDB->new();
    $designDB          = designDB->new();
    $NimbleGene_config = NimbleGene_config->new();
    $dbh               = $root->getDBH( $NimbleGene_config->{database} );

    $self = {
        root              => $root,
        dbh               => $dbh,
        designDB          => $designDB,
        oligoData         => \%oligoData,
        NimbleGene_config => $NimbleGene_config,
        fileDB            => $fileDB
    };

    bless( $self, $class ) if ( $class eq "oligo2dnaDB" );
    return $self;
}

=head2 CreateDB

Creates a new table to store where the chip oligos match to the chromosomal regions represented on the chip.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;

    $self->{dbh}->do("DROP TABLE IF EXISTS `Oligo2DNA`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
	CREATE TABLE `Oligo2DNA` (
	  `ID` int(11) NOT NULL auto_increment,
	  `Oligo_ID` varchar(20) NOT NULL default '0',
	  `Oligo_start` int(11) NOT NULL default '0',
	  `Oligo_end` int(11) NOT NULL default '0',
          `Complement` BOOL default '0',
	  `FileID` int(11) NOT NULL default '0',
          `Sequence` varchar(50) NOT NULL ,
          `DesignString` varchar(35) NOT NULL default '0',
          `OligoHitCount` int(11) default 0,
	  PRIMARY KEY `ID` (`ID`),
          UNIQUE `single` (`Oligo_ID`, `Oligo_start`, `Oligo_end`, `FileID`),
	  KEY `Oligo_ID` (`Oligo_ID`),
	  KEY `File_ID` (`FileID`),
          KEY `DesignID` (`DesignString`)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();

    return 1;

}

=head2 insertData

=head3 arguments

[0]: the design string as accepted by L<::databases::designDB/"SelectId_ByArrayDesignString">

[1]: the reference to the blastResult list as returned by L<sequence_modification::blastResult/"readBlastResults">

[3]: the filename MySQL entry name as returned by L<::root/"getPureSequenceName">

[4]: the oligo sequence representation as returned by L<::nimbleGeneFiles::ndfFile/"GetAsFastaDB"> or L<::nimbleGeneFiles::ndfFile/"WriteAsFastaDB">

=cut

sub insertData {
    my ( $self, $design, $BlastList, $fileName, $sequenceInfoHash ) = @_;
    ## Possible search variants = NimbleID + Used Antibody or NimbleID + Marker (Cy3 || Cy5)
    ## Hier können entweder original Daten eingegeben werden oder Normalisierte Werte!
    ## $what = "original" || "normalized"
    my ( $rv, $sth, $return, $fileIDs, $blastLine, $designID );

    $designID = $self->{designDB}->SelectId_ByArrayDesignString($design);
    $fileIDs  = $self->{fileDB}->SelectFiles_ByDesignId($designID);

    die "CriticalError: no file infos for design $design\n"
      unless ( defined $fileIDs );

#    print "oligo2dnaDB insertData got \$design = $design, \$fileName = $fileName\n";

    $sth = $self->{dbh}->prepare(
"insert into Oligo2DNA ( Oligo_ID, Oligo_start, Oligo_end, FileID, Complement, DesignString, Sequence) 
        values ( ?, ?, ?, ?, ?, ?, ?)"
      )
      or die $self->{dbh}->errstr();
    foreach $blastLine (@$BlastList) {
        $rv = $blastLine->Complement();
        if ( $rv eq "complement" ) {
            $rv = 1;
        }
        else {
            $rv = 0;
        }
        $blastLine->{subjectID} = $1 if ( $blastLine->{subjectID} =~ m/(CHR\d+[RP]\d+)/ );
        $sth->execute(
            "$blastLine->{subjectID}",
            $blastLine->StartOnQueryFile(), $blastLine->EndOnQueryFile(),
            $fileIDs->{$fileName}->{ID},
            $rv, $designID, "$sequenceInfoHash->{$blastLine->{subjectID}}"
          )
          or die $sth->errstr();
    }
    return 1;
}

=head2 GetOligoLocationArray

=head3 atributes

[0]: the design string as accepted by L<::databases::designDB/"SelectId_ByArrayDesignString">

[1]: the filename MySQL entry name as returned by L<::root/"getPureSequenceName">

=head3 return values

The reference to a array of hashes with the stucture [ { Oligo_ID => NimbleGene oligoID, Oligo_start => start position in basepair on the sequence file,
Oligo_end => end position in basepair on the sequence file, FileID => the internal file id of the genbank formated chromosomal region, Sequence => the oligo sequence } ]

=cut

sub GetOligoLocationArray {
    my ( $self, $design, $filename ) = @_;
    my ( $sth, $rv, $fileID, $designID );

    return $self->{oligoData}->{"$design$filename"} if ( defined $self->{oligoData}->{"$design$filename"}); 

#    print "GetOligoLocationArray $design, $filename \n";
    $designID = $self->{designDB}->SelectId_ByArrayDesignString($design);

    if ( defined $filename ) {
        $fileID = $self->{fileDB}->SelectMatchingFileID($designID, $filename);
        $rv     =
        " Select `Oligo_ID`, `Oligo_start`, `Oligo_end`, `FileID`, `Sequence`, `OligoHitCount` 
          from Oligo2DNA 
          where DesignString = \"$designID\" && FileID = $fileID 
          order by `FileID`, `Oligo_start`";
    }
    else {
        $rv = 
        " Select `Oligo_ID`, `Oligo_start`, `Oligo_end`, `FileID`, Sequence , `OligoHitCount`
        from Oligo2DNA 
        where DesignString = \"$designID\" 
        order by `FileID`, `Oligo_start`";
    }

    #print "filename = $filename\nGetOligoLocationArray $rv;\n"; 
    $sth = $self->{dbh}->prepare($rv);
    $sth->execute();
#    return $sth->fetchall_hashref('ID'); 
    $self->{oligoData}->{"$design$filename"} = $sth->fetchall_arrayref();
    return $self->{oligoData}->{"$design$filename"};

}

sub writeTileMap_input_data{
	my ( $self, $chipID, $outFile ) = @_;
	my ( $data, $line );
	$data = $self->GetOligoLocationArray($chipID);
#	open (OUT, ">$oufFile") or die "Konnte File $outFile nicht anlegen!\n";
	
#	for (my $i = 0; $i < @$data; $i++) {
#		$line = @$data[$i];
#		print OUT "@$line[0]\t@$line[
}

sub IdentifyMultiHitOligos{
    my ( $self, $design) = @_;
    my ( $oligoData, $oligoCountHash, $histogram, $sth );
    $oligoData = $self->GetOligoLocationArray( $design);

    foreach my $olgioArray (@$oligoData){
       $oligoCountHash->{@$olgioArray[0]} = 0 unless ( defined $oligoCountHash->{@$olgioArray[0]});
       $oligoCountHash->{@$olgioArray[0]}++;
    }
    $histogram = histogram->new();
    $histogram->AddDataArray($oligoCountHash);
#    print "Histogram in /Mass/ArrayData/Evaluation/oligoOcurrance_simple.csv speichern\n";
    $histogram->writeHistogram("oligoOcurrance_simple.csv");

    $sth=$self->{dbh}->prepare ("Update Oligo2DNA Set OligoHitCount = ? where Oligo_ID = ? ") or die $self->{dbh}->errstr();
    while (my ($oligoID, $oligoCount) = each %$oligoCountHash ){
        $sth->execute($oligoCount, "$oligoID") or die $sth->errstr();
    }
#    print "Fertig!\n";
}

=head2 DataExists

=head3 atributes

[0]: the design string as accepted by L<::databases::designDB/"SelectId_ByArrayDesignString">

[1]: the filename MySQL entry name as returned by L<::root/"getPureSequenceName">

=head3 return value

true if the table Oligo2DNA has at least 100 entries for this design and this chromosomal region, otherwise false

=cut

sub DataExists {
    my ( $self, $design, $filename ) = @_;
    my ( $rv, $sth, $designID, $fileID );

    $designID = $self->{designDB}->SelectId_ByArrayDesignString($design);

    if ( defined $filename ) {
        $fileID = $self->{fileDB}->SelectFiles_ByDesignId($designID);
        $rv = 
        $rv     =
" Select * from Oligo2DNA where DesignString = \"$designID\" && FileID = $fileID->{$filename}->{ID} limit 100"
          if ( defined $filename );
    }
    else {
        $rv =
" Select * from Oligo2DNA where DesignString = \"$designID\" limit 100";
    }
    $sth = $self->{dbh}->prepare($rv) or die $self->{dbh}->errstr();
    $rv  = $sth->execute()            or die $sth->errstr();
    return $rv == 100;
}

=head2 GetInfoID

See L<databases::hybInfoDB/"SelectID_ByHybInfo">

=cut

sub GetInfoID {
    my ( $self, $NimbleGeneID, $antibody ) = @_;

    ## Possible search variants = NimbleID + Used Antibody or NimbleID + Marker (Cy3 || Cy5)
#    print "Array_Hyb searches for self->{hybInfoDB}->SelectID_ByHybInfo($NimbleGeneID, $antibody)\n";
    return $self->{hybInfoDB}->SelectID_ByHybInfo( $NimbleGeneID, $antibody );
}

1;
