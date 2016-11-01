package cellTypeDB;
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
use stefans_libs::NimbleGene_config;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

::database::cellTypeDB

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Cells where all celltype informations are stored.

=head2 Depends on

L<::root>

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<GetAllCellInfosByID|"GetAllCellInfosByID">

L<SelectCellType_ByID|"SelectCellType_ByID">

L<SelectID_ByCellType|"SelectID_ByCellType">


=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class array_GFF

=cut


sub new {

    my ( $class, $line, $what ) = @_;

    my ( $self, $root, $dbh, %hash, %array, $NimbleGene_config );
    $root = root->new();
    $NimbleGene_config = NimbleGene_config->new();
    $dbh  = $root->getDBH($NimbleGene_config->{database});

    $self = {
        dbh        => $dbh,
        root       => $root,
        NimbleGene_config => $NimbleGene_config,
          usedData => \%hash,
        usedData_byID => \%array

    };

    bless( $self, $class ) if ( $class eq "cellTypeDB" );
    return $self;
}

=head2 CreateDB

Creates a new table to store the used celltypes information.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;
    $self->{dbh}->do("DROP TABLE IF EXISTS `Cells`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
        CREATE TABLE `Cells` (
          `ID` int(11) NOT NULL auto_increment,
          `Organism` varchar(20) NOT NULL default '0',
          `Celltype` varchar(20) NOT NULL default '0',
          UNIQUE KEY `id` (`ID`),
          UNIQUE `single` (`Organism`, `Celltype`)
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();
    return 1;
}

=head2 DataExists

=head3 atributes

[0]: the cellType as string or if [1] is undefined the celltype id

[1]: the organism as string or the undefined value

=head3 retrun values

true if the celltype was defined or false if it was not defined.

=cut

sub DataExists {
    my ( $self, $cellType, $organism ) = @_;
#	$cellType = "" unless ( defined $cellType);
#	$organism = "" unless ( defined $organism);
    return 1 == 1 if ( defined $self->{usedData}->{"$cellType$organism"} );
    return 1 == 1 if ( defined $self->{usedData_byID}->{$cellType} );

    my ( $sth, $rv );

      if ( defined $organism ){
    $sth =
      $self->{dbh}->prepare(
"Select * from Cells where Celltype = \"$cellType\" && Organism = \"$organism\""
      );
#    print 
#"Select * from Cells where Celltype = \"$cellType\" && Organism = \"$organism\";\n";
    }

    unless ( defined $organism ){
        $sth = $self->{dbh}->prepare("Select * from Cells where ID = $cellType ");
#        print "Select * from Cells where ID = $cellType ;\n";
    
    }
    $rv = $sth->execute() or die $sth->srrest();
#    print "DataExists rv = $rv\n";
    if ( $rv > 0 ) {
        $rv = $sth->fetchrow_hashref();
        if ( defined $organism ) {
            $self->{usedData}->{"$rv->{Celltype}$rv->{Organism}"} = $rv;
            $self->{usedData_byID}->{ $rv->{ID} } = $rv;
        }
        unless ( defined $organism ) {
            $self->{usedData_byID}->{$cellType} = $rv;
            $self->{usedData}->{ "$rv->{Celltype}$rv->{Organism}" } = $rv;
        }
        return 1 == 1;
    }
    return 1 == 0;
}

=head2 GetAllCellInfosByID

=head3 atributes 

none

=head3 retrun values

a reference to a hash of hashes with the structure { tableLineID => { ID => tableLineID ,Organism => organism string ,Celltype = celltype string}}

=cut

sub GetAllCellInfosByID{
    my ( $self) = @_;
    my ( $sth, $rv);
    $sth = $self->{dbh}->prepare("Select * from Cells") or die $self->{dbh}->errstr();
    $rv = $sth->execute();
    return undef unless ( $rv > 0);
    return $sth->fetchall_hashref("ID");
}

=head2 insertData

=head3 atributes

[0]: the celltype string

[1]: the organism string

=head3 retrun values

true if the data exists after the insert

=cut

sub insertData {
    my ( $self, $cellType, $organism ) = @_;
    die "bitte cellType und organism angeben" unless ( @_ == 3 );

    unless ( $self->DataExists( $cellType, $organism ) ) {
        $self->{dbh}->do(
"Insert into Cells ( Organism, Celltype) values ( \"$organism\", \"$cellType\" ) "
          )
          or die $self->{dbh}->errstr();
    }
    return $self->DataExists( $cellType, $organism );
}

=head2 SelectCellType_ByID

=head3 atributes

[0]: the celltype id (internal table line id)

=head3 return value

a reference to a hash with the structure { cellType => celltype string, organism => organism string }

=cut

sub SelectCellType_ByID {
    my ( $self, $ID ) = @_;
    my $hash;
    $hash = {
        cellType => $self->{usedData_byID}->{$ID}->{Celltype},
        organism => $self->{usedData_byID}->{$ID}->{Organism}
      }
      if ( $self->DataExists($ID) );
    return $hash;
}

=head2 SelectID_ByCellType

=head3 atributes

[0]: the celltype string

[1]: the organism string

=head3 return value

the celltype internal table line id or the undefined value

=cut

sub SelectID_ByCellType {
    my ( $self, $cellType, $organism ) = @_;
    return $self->{usedData}->{"$cellType$organism"}->{ID}
      if ( $self->DataExists( $cellType, $organism ) );
    return undef;
}

1;
