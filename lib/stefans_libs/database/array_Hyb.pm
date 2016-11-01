package array_Hyb;
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
use stefans_libs::nimbleGeneFiles::gffFile;
=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

::database::array_Hyb

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Array_Data_Hyb where all hybridization valuies are stored.

=head2 Depends on

L<::database::hybInfoDB>

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<GetInfoIDs_forHybType|"GetInfoIDs_forHybType">

L<GetInfoID|"GetInfoID">

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class array_Hyb

=cut

sub new {

	my ($class) = @_;

	my ( $self, $dbh, $root, $hybInfoDB, $NimbleGene_config, %data );

	$root              = root->new();
	$hybInfoDB         = hybInfoDB->new();
	$NimbleGene_config = NimbleGene_config->new();
	$dbh               = $root->getDBH( $NimbleGene_config->{database} );

	$self = {
		root              => $root,
		dbh               => $dbh,
		NimbleGene_config => $NimbleGene_config,
		data              => \%data,
		hybInfoDB         => $hybInfoDB
	};

	bless( $self, $class ) if ( $class eq "array_Hyb" );
	return $self;
}

=head2 CreateDB

Creates a new table to store the hybridization values foreach oligo.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
	my ($self) = @_;

	$self->{dbh}->do("DROP TABLE IF EXISTS `Array_File_Hyb`")
	  or die $self->{dbh}->errstr();
	$self->{dbh}->do( "
	CREATE TABLE `Array_File_Hyb` (
	  `ID` int(11) NOT NULL auto_increment,
	  `InfoID` int(11) NOT NULL default '0',
      `Orig_Enrichment_File` varchar(100) NOT NULL default '0',
      `New_Enrichment_File` varchar(100) default NULL,
	  PRIMARY KEY  (`ID`),
	  KEY `InfoID` (`InfoID`),
      UNIQUE `single` (`InfoID`,`Orig_Enrichment_File`)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();

	return 1;

}

=head2 insertData

=head3 atributes

[0]: the nimbleGeneID

[1]: either the antibody specificity or the DNA marker (cy3 or cy5)

[2]: 'nimblegene' or 'normalized'

[3]: reference to the data hash. The format depends on the atribute[2]:
'nimblegene': {OlgigoID => value} or 'normalized': [{pos , normalized => value, ID => OligoID}]

=cut

sub insertData {
	my ( $self, $NimbleGeneID, $antibody, $mode, $fileName ) = @_;
	## $mode = "nimblegene" || "normalized"
	my ( $rv, $sth, $return, $infoID );

	$infoID = $NimbleGeneID;
	$infoID = $self->GetInfoID( $NimbleGeneID, $antibody ) if ( defined $antibody);

	$rv =
"Insert into Array_File_Hyb (InfoID, Orig_Enrichment_File ) values ( $infoID , '$fileName')"
	  if ( $mode eq "nimblegene" );
	$rv = "Update Array_File_Hyb set New_Enrichment_File = '$fileName' where InfoID = $infoID "
	  if ( $mode eq "normalized" );
	
	die "Bitte entweder arrayGFF->insertData entweder 'normalized' oder 'nimblegene' mitgeben!\nNicht '$mode' at $self\n" unless ( defined $rv);
	
	$sth = $self->{dbh}->do($rv) or die $self->{dbh}->errstr();
	
	return 1;
}

=head2 GetInfoIDs_forHybType

See L<::database::hybInfoDB/"GetInfoIDs_forHybType">

=cut

sub GetInfoIDs_forHybType {
	my ( $self, $AB, $celltype, $organism, $designID ) = @_;
	print
"Array_Hyb - > GetInfoIDs_forHybType ($self, $AB, $celltype, $organism, $designID )\n";
	return $self->{hybInfoDB}
	  ->GetInfoIDs_forHybType( $AB, $celltype, $organism, $designID );
}

=head2 GetGFF_forInfoID

removed in revision 20!

=cut

sub GetHybValue_forInfoID {
	my $self = shift;
	die "$self-> GetHybValue_forInfoID: not longer supportet! removed in revision 20\n";
}

sub getFilename4InfoID{
	my ( $self, $InfoID, $mode ) = @_;
	
	my ($rv, $filename, $sth);
	$rv = "select Orig_Enrichment_File from Array_File_Hyb where InfoID = $InfoID"
	  if ( $mode eq "nimblegene" );
	$rv = "select New_Enrichment_File from Array_File_Hyb where InfoID = $InfoID"
	  if ( $mode eq "normalized" );
	$sth = $self->{dbh}->prepare($rv);
	$sth->execute();
	$filename  = $sth->fetch();
	return @$filename[0];		 
}

sub clearData {
	my ($self) = @_;
	my %temp;
	$self->{data} = undef;
	$self->{data} = \%temp;
}

=head2 DataExists

=head3 atributes

See L<database::hybInfoDB/"SelectID_ByHybInfo">

=head3 return values

true if more than 1000 values are stored in the database ore false if less than 1000 values are stored

=cut

sub DataExists {
	my ( $self, $NimbleGeneID, $antibody ) = @_;
	my ( $rv, $sth, $infoID );

	$infoID = $self->GetInfoID( $NimbleGeneID, $antibody );
	return 0 > 1 unless ( defined $infoID );
	$sth =
	  $self->{dbh}->prepare(
		"Select * from Array_File_Hyb where InfoID = $infoID")
	  or die $self->{dbh}->errstr();
	$rv = $sth->execute() or die $sth->errstr();
	my @fileInfos = stat($rv);
	unless ( defined $fileInfos[0] ) {
		$self->{dbh}->do("delete from Array_File_Hyb where InfoID = $infoID");
	}
	return defined($fileInfos[0]);
}

=head2 GetInfoID

See L<::database::hybInfoDB/"SelectID_ByHybInfo">

=cut

sub GetInfoID {
	my ( $self, $NimbleGeneID, $antibody ) = @_;

	## Possible search variants = NimbleID + Used Antibody or NimbleID + Marker (Cy3 || Cy5)
#    print "Array_Hyb searches for self->{hybInfoDB}->SelectID_ByHybInfo($NimbleGeneID, $antibody)\n";
	return $self->{hybInfoDB}->SelectID_ByHybInfo( $NimbleGeneID, $antibody );
}

1;
