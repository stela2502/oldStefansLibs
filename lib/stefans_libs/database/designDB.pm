package designDB;
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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

::database::designDB

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Design where all the different design descriptions are stored.

=head2 Depends on

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<SelectId_ByArrayDesignString|"SelectId_ByArrayDesignString">

L<SelectDesignFile_ById|"SelectDesignFile_ById">

L<SelectArrayDesignString_ById|"SelectArrayDesignString_ById">

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class designDB

=cut

sub new {

    my ($class) = @_;

    my ( $self, $dbh, $root, %hash, %array, $NimbleGene_config );

    $root = root->new();
    $NimbleGene_config = NimbleGene_config->new();
    $dbh  = $root->getDBH($NimbleGene_config->{database});

    $self = {
        root          => $root,
        dbh           => $dbh,
        NimbleGene_config => $NimbleGene_config,
        usedData      => \%hash,
        usedData_byID => \%array
    };

    bless( $self, $class ) if ( $class eq "designDB" );
    return $self;
}

=head2 CreateDB

Creates a new table to store the design information foreach design used.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;
    $self->{dbh}->do("DROP TABLE IF EXISTS `Design`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
	CREATE TABLE `Design` (
	  `ID` int(11) NOT NULL auto_increment,
	  `identifier` int(11) default NULL,
	  `NCBI_Mouse_GenomeBuild` varchar(11) default NULL,
	  `NimbleGenIdent` varchar(35) NOT NULL default '',
	  `Median_OligoDensityPer500bp_reg` int(11) NOT NULL default '0',
          `DesignFile` varchar(160) default NULL,
	  KEY `ID` (`ID`),
	  UNIQUE `NimbleGenIdent` (`NimbleGenIdent`),
          UNIQUE `identifier` (`identifier`)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();
    return 1;
}

=head2 DataExists

=head3 atributes

[0]: either the NimbleGene design string or the internal table line id

=head3 return values

true if the desig is found in the database or false if it is not found

=cut



sub DataExists {
    my ( $self, $design ) = @_;

    return 1 == 1 if ( defined $self->{usedData}->{$design} );
    return 1 == 1 if ( defined $self->{usedData_byID}->{$design} );

    my ( $sth, $rv, $what );
    $what = "ID";
    if ( $design =~ m/\d\d\d\d-\d\d-\d\d_RZPD\d\d\d\d_MM\d_ChIP/){
        $what = "NimbleGenIdent";
    }
#    $what = "NimbleGenIdent" if  ($design =~ m/\d\d\/ );
#    $what = "ID"             unless ( $design =~ m/\w/);

#    print "designDB DataExists \$what = $what ($design)\n";

    $sth =
      $self->{dbh}
      ->prepare("Select * from Design where NimbleGenIdent = \"$design\" ")
      if ( $what eq "NimbleGenIdent" );
    $sth = $self->{dbh}->prepare("Select * from Design where ID = $design ")
      if ( $what eq "ID" );
    $rv = $sth->execute();
    if ( $rv > 0 ) {
        $rv = $sth->fetchrow_hashref();
        if ( $what eq "NimbleGenIdent" ) {
            $self->{usedData}->{$design} = $rv;
            $self->{usedData_byID}->{ $rv->{ID} } = $rv;
        }
        if ( $what eq "ID" ) {
            $self->{usedData_byID}->{$design} = $rv;
            $self->{usedData}->{ $rv->{NimbleGenIdent} } = $rv;
        }
        return 1 == 1;
    }
    return 1 == 0;

}

=head2 insertData

=head3 atributes

[0]: depricated integer value 

[1]: the NCBI genome build version

[2]: the NimbleGene design string

[3]: the median oligo density over 500 bp genomic DNA for this array design or the undefined value

[4]: the absolute path to the NimbleGene array design file

=head3 return value

true if data exists after the instertion, false if not

=cut

sub insertData {
    my ( $self, $identifier, $NCBI_Mouse_GenomeBuild,
        $NimbleGenIdent, $Median_OligoDensityPer500bp_reg, $designFile )
      = @_;

    my ($sth);
    $Median_OligoDensityPer500bp_reg = -1 unless ( defined $Median_OligoDensityPer500bp_reg );
    print "insertData :\ninsert into Design (identifier , NCBI_Mouse_GenomeBuild, NimbleGenIdent, Median_OligoDensityPer500bp_reg, DesignFile )
     values ( $identifier, \"$NCBI_Mouse_GenomeBuild\", \"$NimbleGenIdent\", $Median_OligoDensityPer500bp_reg, \"$designFile\" );\n ";

    $sth = $self->{dbh}->do(
"insert into Design (identifier , NCBI_Mouse_GenomeBuild, NimbleGenIdent, Median_OligoDensityPer500bp_reg, DesignFile ) 
     values ( $identifier, \"$NCBI_Mouse_GenomeBuild\", \"$NimbleGenIdent\", $Median_OligoDensityPer500bp_reg, \"$designFile\" ) "
      )
      or die $self->{dbh}->errstr();
    return $self->DataExists($NimbleGenIdent);
}

=head2 SelectId_ByArrayDesignString

=head3 atributes

[0]: the NimbleGene array design string

=head3 return value

the internal table line id if the array design was foundin the database or the undefined value

=cut

sub SelectId_ByArrayDesignString {
    my ( $self, $NimbleGenIdent ) = @_;
    return $self->{usedData}->{$NimbleGenIdent}->{ID}
      if ( $self->DataExists($NimbleGenIdent) );
    return undef;

}

=head2 SelectDesignFile_ById

=head3 atributes

[0]: the design id (internal table line id)

=head retrun values

the absolute location of the array design file if the array table line was found in the database or the undefined value
=cut

sub SelectDesignFile_ById{
    my ( $self, $ID) = @_;
    return $self->{usedData_byID}->{$ID}->{DesignFile}
       if ( $self->DataExists($ID) );
    return undef;
}

=head2 SelectArrayDesignString_ById

=head3 atributes

[0]:  the design id (internal table line id)

=head3 return values

the NimbleGene arrays design string or the undefined value

=cut

sub SelectArrayDesignString_ById {
    my ( $self, $ID ) = @_;
    return $self->{usedData_byID}->{$ID}->{NimbleGenIdent}
      if ( $self->DataExists($ID) );
    return undef;

}

1;
