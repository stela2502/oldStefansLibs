package array_GFF;
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
use stefans_libs::database::hybInfoDB;
use stefans_libs::NimbleGene_config;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

database::array_GFF

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Array_Data_GFF where all enrichment factors are stored.

=head2 Depends on

L<database::hybInfoDB>

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<GetInfoIDs_forHybType|"GetInfoIDs_forHybType">

L<GetGFF_forInfoID|"GetGFF_forInfoID">

L<GetInfoID|"GetInfoID">

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class array_GFF 

=cut


sub new {

   my ( $class ) = @_;

   my ( $self, $dbh, $root , $hybInfoDB, $NimbleGene_config);

   $root = root->new();
   $hybInfoDB = hybInfoDB->new();
   $NimbleGene_config = NimbleGene_config->new();
   $dbh  = $root->getDBH($NimbleGene_config->{database});

   $self = {
      root => $root,
      dbh  => $dbh,
      NimbleGene_config => $NimbleGene_config,
      hybInfoDB => $hybInfoDB
   };

   bless ($self , $class ) if ( $class eq "array_GFF");
   return $self;
}

=head2 CreateDB

Creates a new table to store the enrichment factors foreach oligo.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ( $self) = @_;

    $self->{dbh}->do("DROP TABLE IF EXISTS `Array_File_GFF`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
        CREATE TABLE `Array_File_GFF` (
          `ID` int(11) NOT NULL auto_increment,
          `InfoID` int(11) NOT NULL default '0',
          `Orig_Enrichment_File` varchar(100) NOT NULL default '0',
          `New_Enrichment_File` varchar(100) default NULL,
          PRIMARY KEY  (`ID`),
          KEY `InfoID` (`InfoID`),
          UNIQUE (`InfoID`)
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();

    return 1;

}

=head2 insertData

=head3 atributes

[0]: the nimbleGeneID

[1]: either the antibody specificity or the DNA marker (cy3 or cy5)

[2]: the absolute datafile location

[3]: 'nimblegene' or 'normalized'

=cut

sub insertData{
    my ( $self, $NimbleGeneID, $antibody, $mode, $dataFileString) = @_;
    ## $mode = "original" || "normalized"
    my ( $rv, $sth, $return, $infoID);
    
    $infoID = $NimbleGeneID;
	$infoID = $self->GetInfoID( $NimbleGeneID, $antibody ) if ( defined $antibody);

    $rv = "Insert into Array_File_GFF (InfoID, Orig_Enrichment_File ) values ( $infoID , '$dataFileString')" if ( lc($mode) eq "nimblegene");
    $rv = "Update Array_File_GFF set New_Enrichment_File = '$dataFileString' where InfoID = $infoID " if ( $mode eq "normalized" && $self->DataExists($NimbleGeneID, $antibody));
    die "You tried to insert a new data set even though you did not enter a original one!\nThat operation is not permitted\n" if ( $mode eq "normalized" && ! $self->DataExists($NimbleGeneID, $antibody));

    die "Bitte entweder arrayGFF->insertData entweder 'normalized' oder 'nimblegene' mitgeben!\nNicht '$mode' at $self\n" unless ( defined $rv); 


    $sth = $self->{dbh}->do($rv) or die $self->{dbh}->errstr();

    print "ready, insterted '$dataFileString' for InfoID  $infoID!\n";

    return  1;
}

=head2 GetInfoIDs_forHybType

See L<::database::hybInfoDB/"GetInfoIDs_forHybType">

=cut

sub GetInfoIDs_forHybType{
    my ( $self, $AB, $celltype, $organism, $designID ) = @_;
    return $self->{hybInfoDB}->GetInfoIDs_forHybType($AB, $celltype, $organism, $designID );
}

=head2 GetGFF_forInfoID

=head3 atributes

[0]: the hybridization Id that can be found with L<::database::hybInfoDB/"GetInfoIDs_forHybType">

[1]: either 'nimbleGFF_ID', 'nimbleGFF_OligoID', 'norm_ID' or 'norm_OligoID'

=head 3 return values

The return values are a reference to a hash and the total count of enries in tah hash.
The structure of the hash depends on the atribute[1], but it always looks like {key => value}. 
The keys can either be the OligoID if the atribute[1] contains '_OligoID' or the unique table line Id if the atribute[1] contains '_ID'.
The values can either be the original NimbleGene value if the atribute contains 'nimbleGFF' or the normalized value if the atribute[1] contains 'norm'.
=cut

sub GetGFF_forInfoID{
	die "not longer supportet! removed in revision 20\n";
}

sub getFilename4InfoID{
	my ($self, $infoID, $mode) = @_;
	
	my ($filename, $sth);
	
	$sth = $self->{dbh}->prepare("Select Orig_Enrichment_File from Array_File_GFF where InfoID = $infoID") if ( $mode eq 'nimblegene');
	$sth = $self->{dbh}->prepare("Select New_Enrichment_File from Array_File_GFF where InfoID = $infoID") if ( $mode eq 'normalized');
	
	$sth->execute();
	$filename = $sth->fetch();
	return @$filename[0];
}

=head2 DataExists

=head3 atributes

See L<database::hybInfoDB/"SelectID_ByHybInfo">

=head3 return values

true if more than 1000 values are stored in the database ore false if less than 1000 values are stored

=cut

sub DataExists{
    my ( $self, $NimbleGeneID, $antibody ) = @_;
    my ( $rv , $sth, $infoID );
	#`Orig_Enrichment_File` varchar(100) NOT NULL default '0',
    #     `New_Enrichment_File`
    $infoID = $NimbleGeneID;
    $infoID = $self->GetInfoID($NimbleGeneID, $antibody ) if ( defined $antibody);
    
    return 0 > 1 unless (defined $infoID);
    $sth = $self->{dbh}->prepare("Select Orig_Enrichment_File from Array_File_GFF where InfoID = $infoID") or die $self->{dbh}->errstr();
    $rv = $sth->execute() or die $sth->errstr();
    my @stats = stat($rv);
    unless ( defined $stats[0]){
    	$self->{dbh}->do("delete from Array_File_GFF where InfoID = $infoID");
    	return undef;
    }
    return 1;
}

=head2 GetInfoID

=head3 atributes

See L<::database::hybInfoDB/"SelectID_ByHybInfo">

=head return values

See L<database::hybInfoDB/"SelectID_ByHybInfo">

=cut

sub GetInfoID {
    my ( $self, $NimbleGeneID, $antibody ) = @_;

    ## Possible search variants = NimbleID + Used Antibody or NimbleID + Marker (Cy3 || Cy5)
    ## also possible $NimbleGeneID == InfoID

    return $self->{hybInfoDB}->SelectID_ByHybInfo($NimbleGeneID, $antibody);
}
    
1;
