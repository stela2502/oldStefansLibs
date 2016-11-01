package antibodyDB;
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

::database::antibodyDB

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table antibody where all antibody informations are stored.

=head2 Depends on

L<::root>

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<GetAllAntibodyInfosByID|"GetAllAntibodyInfosByID">

L<SelectSpecificity_ByID|"SelectSpecificity_ByID">

L<SelectId_BySpecificity|"SelectId_BySpecificity">

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class antibodyDB

=cut

sub new {

    my ( $class ) = @_;

    my ( $self, $dbh, $root, %hash, %array, $NimbleGene_config );

    $root = root->new();
    $NimbleGene_config = NimbleGene_config->new();
    $dbh  = $root->getDBH($NimbleGene_config->{database});

    $self = {
        root          => $root,
        NimbleGene_config => $NimbleGene_config,
        dbh           => $dbh,
        usedData      => \%hash,
        usedData_byID => \%array
    };

    bless( $self, $class ) if ( $class eq "antibodyDB" );
    return $self;
}

=head2 CreateDB

Creates a new table to store the user provided antibody information.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;
    $self->{dbh}->do("DROP TABLE IF EXISTS `antibody`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
        CREATE TABLE `antibody` (
          `ID` int(11) NOT NULL auto_increment,
          `company` varchar(20) NOT NULL default '0',
          `OrderNumber` varchar(20) NOT NULL default '0',
          `Specificity` varchar(20) NOT NULL default '0',
          UNIQUE KEY `id` (`ID`),
          UNIQUE `single` (`company`,`OrderNumber`,`Specificity`)
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();
    return 1;
}

=head2 DataExists

=head3 atributes

[0]: the specificity. It can eiter be a string for the antibody specificity or a internal antibodyID

=head3 return values

returns a boolean value, true if the antibody is defined or false if it is not.
 
=cut

sub DataExists {
    my ( $self, $specificity ) = @_;
    return 1 == 1 if ( defined $self->{usedData}->{$specificity} );
    return 1 == 1 if ( defined $self->{usedData_byID}->{$specificity} );

    my ( $sth, $rv, $what );
    
    $what = "specificity" if ( $specificity  =~ m/\w/);
    $what = "ID"          if ($specificity  =~ m/^\d/ );

#    print "antibodyDB->DataExists $specificity => \$what = $what\n";

    $sth =
      $self->{dbh}
      ->prepare("Select * from antibody where Specificity = \"$specificity\" ")
      if ( $what eq "specificity" );
    $sth =
      $self->{dbh}->prepare("Select * from antibody where ID = $specificity ")
      if ( $what eq "ID" );
    $rv = $sth->execute();
    if ( $rv > 0 ) {
        $rv = $sth->fetchrow_hashref();
        if ( $what eq "specificity" ) {
            $self->{usedData}->{$specificity} = $rv;
            $self->{usedData_byID}->{ $rv->{ID} } = $rv;
        }
        if ( $what eq "ID" ) {
            $self->{usedData_byID}->{$specificity} = $rv;
            $self->{usedData}->{ $rv->{Specificity} } = $rv;
        }
        return 1 == 1;
    }
    if ( $specificity eq "INPUT" && $self->{stop} != 1){
       $self->{stop} = 1;
       $self-> insertData ("-","-", $specificity);
       return $self->DataExists($specificity);
    }
    return 1 == 0;
}

=head2 insertData

=head3 atributes

[0]: the name of the company which sells this antibody

[1]: the order number to order this antibody

[2]: the antibody specificity string

=head3 return value

returns a boolean value, true if the antibody is defined or false if it is not.

=cut

sub insertData {
    my ( $self, $company, $OrderNumber, $Specificity ) = @_;
    die "Bitte company, OrderNumber und Specificity angeben!\n"
      unless ( @_ == 4 );
    my ($sth);

    $sth =
      $self->{dbh}->prepare(
"insert into antibody (company, OrderNumber, Specificity ) values ( \"$company\", \"$OrderNumber\", \"$Specificity\" )"
      )
      or die $self->{dbh}->errstr();
    $sth->execute( )
      unless ( $self->DataExists($Specificity) );
    return $self->DataExists($Specificity);
}

=head2 GetAllAntibodyInfosByID

=head3 atributes

none

=head3 return value

returns a reference to a hash containing all antibody informations {ID, company, OrderNumber, Specificity}

=cut

sub GetAllAntibodyInfosByID{
    my ( $self) = @_;
    my ( $sth, $return, $rv);
    $sth = $self->{dbh}->prepare("Select * from antibody") or die $self->{dbh}->errstr();
    $rv = $sth->execute();
    return undef unless ($rv > 0);
    return $sth->fetchall_hashref("ID");
}

=head2 SelectSpecificity_ByID

=head3 atributes

[0]: internal antibody id (table line id)

=head3 return value

returns the antibody specificity or the undefined value if the antibody id was not found in the database
 
=cut

sub SelectSpecificity_ByID {
    my ( $self, $ID ) = @_;
    return $self->{usedData_byID}->{$ID}->{Specificity}
      if ( $self->DataExists($ID) );
    return undef;
}

=head2 SelectId_BySpecificity

=head3 atributes

[0]: the antibody specificity string

=head3 return value

returns the antibody id or the undefined value if the antibody id was not found in the database

=cut


sub SelectId_BySpecificity {
    my ( $self, $Specificity ) = @_;
    return $self->{usedData}->{$Specificity}->{ID}
      if ( $self->DataExists($Specificity) );
    return undef;
}

1;
