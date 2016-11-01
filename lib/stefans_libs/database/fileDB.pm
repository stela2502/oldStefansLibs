package fileDB;
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
use stefans_libs::NimbleGene_config;
use stefans_libs::database::designDB;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

:fileDB

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Files where the location of all
genbank formated chromosomal regions that are represented by the array design are stored.

=head2 Depends on

L<database::hybInfoDB>

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class fileDB

=cut


sub new {

    my ($class) = @_;

    my ( $self, $dbh, $root, %hash, %array, $NimbleGene_config, $designDB );

    $root              = root->new();
    $NimbleGene_config = NimbleGene_config->new();
    $dbh               = $root->getDBH( $NimbleGene_config->{database} );
    $designDB          = designDB->new();

    $self = {
        root              => $root,
        dbh               => $dbh,
        NimbleGene_config => $NimbleGene_config,
        designDB          => $designDB,
        usedData          => \%hash,
        usedData_byID     => \%array
    };

    bless( $self, $class ) if ( $class eq "fileDB" );
    return $self;
}

=head2 CreateDB

Creates a new table to store the alsolute location of the genbank formated chromosomal regions that are represented by the array design.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;
    $self->{dbh}->do("DROP TABLE IF EXISTS `Files`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
	CREATE TABLE `Files` (
	  `ID` int(11) NOT NULL auto_increment,
	  `fileName` varchar(160) NOT NULL default '',
	  `DesignID` int(11) default NULL,
	  KEY `ID` (`ID`),
          UNIQUE `single` (`fileName`, `DesignID`),
	  KEY `Sequence_name` (`fileName`),
          Key `DesignID` (`DesignID`)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();
    return 1;
}

=head2 DataExists

=head3 atributes

[0]: either the NimbleGene design string or the internal table line id

=head3 return values

true if the design is found in the Files table or false if it is not found

=cut

sub DataExists {
    my ( $self, $design ) = @_;

    return 1 == 1 if ( defined $self->{usedData}->{$design} );
    return 1 == 1 if ( defined $self->{usedData_byID}->{$design} );
	unless (defined  $design){
		$design = NimbleGene_config::DesignID();
	}
    my ( $sth, $rv, $designID );
    $designID = $design;
    if ( $design =~ m/\d\d\d\d-\d\d-\d\d_RZPD\d\d\d\d_MM\d_ChIP/ ) {    ## design string!
#        print "fileDB DataExists got a designString $design\n";
        $designID = $self->{designDB}->SelectId_ByArrayDesignString($design);
#        print "ID = $designID\n";
    }

    $sth =
      $self->{dbh}
      ->prepare("Select * from Files where DesignID = $designID ");
    $rv = $sth->execute();
    if ( $rv > 0 ) {
#        print "fileDB DataExists got $rv entiers\n";
        $rv = $sth->fetchall_hashref("fileName");
        if ( $designID == $design ) {
#            print "Got a DesignID!\n";
            $self->{usedData_byID}->{$design} = $rv;
        }
        else {
#            print "Got a DesignString!\n";
            $self->{usedData_byID}->{$designID} = $rv;
#            print "\$self->{usedData_byID}->{$designID} = $rv;\n";
            $self->{usedData}->{$design}        = $rv;
#            print "\$self->{usedData}->{$design}        = $rv;\n";
        }
        return 1 == 1;
    }
    return 1 == 0;

}

=head2 insertData

=head3 atributes

[0]: the NimbleGene design string

[1]: the reference to a array containing a list of filenames as returned by L<chromosome_ripper::gbFileMerger/"Create_GBfiles"> 

=head3 return value

true if data exists after the insertion, false if not

=cut

sub insertData {
    my ( $self, $design, $fileList ) = @_;

    my ( $sth, $designID );

    $designID = $design;
    if ( $design =~ m/\w/ ) {    ## design string!
        $designID = $self->{designDB}->SelectId_ByArrayDesignString($design);
    }
    $sth =
      $self->{dbh}->prepare(
        "insert into Files (fileName , DesignID ) values ( ?, $designID ) ")
      or die $self->{dbh}->errstr();

    foreach my $filename (@$fileList) {
        $sth->execute("$filename") or die $sth->errstr();
    }
    return $self->DataExists($design);
}

sub SelectMatchingFileID {
  my ( $self, $designID, $FileString ) = @_;

  my ( $fileHash );

  if ( $FileString =~m/\// ){
     my @temp = split("/",$FileString);
     $FileString = $temp[@temp - 1];
     @temp = split ('.',$FileString);
     $FileString = $temp[0];
  }

  $fileHash = $self->SelectFiles_ByDesignId($designID);

  foreach my $filename (keys  %$fileHash){
       return $fileHash->{$filename}->{ID} if ( $filename =~ m/$FileString/);
  }

}


sub SelectMatchingFileLocation {
  my ( $self, $designID, $FileString ) = @_;

  my ( $fileHash );

  if ( $FileString =~m/\// ){
     my @temp = split("/",$FileString);
     $FileString = $temp[@temp - 1];
     @temp = split ('.',$FileString);
     $FileString = $temp[0];
  }

  $fileHash = $self->SelectFiles_ByDesignId($designID);

  foreach my $filename (keys  %$fileHash){
	#	print "fileDB SelectMatchingFileLocation file in DB = $filename\n";
       return $filename if ( $filename =~ m/$FileString/);
  }
  return undef;
}

=head2 SelectFiles_ByDesignId

=head3 atributes 

[0]: the internal design id

=head3 retrun value

a reference to a hash of hashes with the structure { gbFilename => { ID => internale table line id, fileName => gbFilename, DesignID => the internale table line id from the Designs table}}

=cut

sub SelectFiles_ByDesignId {
    my ( $self, $ID ) = @_;
    my ($data);
    if ( $self->DataExists($ID) ) {
        if ( defined $self->{usedData_byID}->{$ID} ) {
#              print "Files found in usedData_byID by ID $ID\n";
              return $self->{usedData_byID}->{$ID};
        }
        elsif ( defined $self->{usedData}->{$ID} ){
#              my ( $test, $key, $id);
#              $id = $self->{usedData}->{$ID};
#              foreach $key ( keys %$id){
#                print "$key\n";
#              }
#              print "Files found in usedData by DesignString $ID\n";
              return $self->{usedData}->{$ID};
        }
    }
    print "No Files for Design $ID\n";
    return undef;
}

1;
