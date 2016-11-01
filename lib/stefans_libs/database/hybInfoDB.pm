package hybInfoDB;
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
use stefans_libs::database::antibodyDB;
use stefans_libs::database::cellTypeDB;
use stefans_libs::database::designDB;
use stefans_libs::NimbleGene_config;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

database::designDB

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table HybInfo where all the different hybridization descriptions are stored.

=head2 Depends on

L<::NimbleGene_config>

L<::root>

L<database::antibodyDB>

L<database::cellTypeDB>

L<database::designDB>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<GetInfoID_forHybType|"GetInfoID_forHybType">

L<GetInfoIDs_forHybType|"GetInfoIDs_forHybType">

L<SelectHybInfo_ByID|"SelectHybInfo_ByID">

L<SelectID_ByHybInfo|"SelectID_ByHybInfo">


=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class hybInfoDB

=cut


sub new {

    my ( $class ) = @_;

    my ( $self, $root, $dbh, %hash, %array, $antibody, $celltype, $design, $NimbleGene_config );

    $root     = root->new();
    $NimbleGene_config = NimbleGene_config->new();
    $dbh      = $root->getDBH($NimbleGene_config->{database});
    $antibody = antibodyDB->new();
    $celltype = cellTypeDB->new();
    $design   = designDB->new();

    $self = {
        dbh           => $dbh,
        root          => $root,
        NimbleGene_config => $NimbleGene_config,
        antibodyDB    => $antibody,
        cellTypeDB    => $celltype,
        designDB      => $design,
        usedData      => \%hash,
        usedData_byID => \%array
    };

    bless( $self, $class ) if ( $class eq "hybInfoDB" );
    return $self;
}

sub printReport{
	my ( $self ) = @_;
	my ($hyb);
	my $data = $self->getAllByNimbleID();
	#root::print_hashEntries($data,4,"is that the complete infor list for the HybInfo db?\n");
	
	print "NimbleGene HybID\tArray Design\tCy5 cell type\tCy5 precipitated by\tCy5 DNA type\tCy3 cell type\tCy3 precipitated by\t\tCy3 DNA type\n" ;
	foreach my $NimbleGeneID (sort {$a <=> $b } keys %$data){
		$hyb = $data->{$NimbleGeneID};
		print "$NimbleGeneID\t$hyb->{cy3}->{ArrayDesign}\t$hyb->{cy5}->{Celltype}\t$hyb->{cy5}->{Antibody}\t$hyb->{cy5}->{TemplateType}\t",
		"$hyb->{cy3}->{Celltype}\t$hyb->{cy3}->{Antibody}\t$hyb->{cy3}->{TemplateType}\n";
	}

}
=head2 CreateDB

Creates a new table to store the hybridization information foreach array hybridization used.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;

    $self->{dbh}->do("DROP TABLE IF EXISTS `HybInfo`")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
     CREATE TABLE `HybInfo` (
       `ID` int(11) NOT NULL auto_increment,
       `NimbleGen_Id` varchar(20) NOT NULL default '',
       `Marker` varchar(5) NOT NULL default '',
       `TemplateType` varchar(10) default NULL,
       `Celltype_ID` int(11) default NULL,
       `Antibody_ID` int(11) default NULL,
       `ArrayDesignId` int(11) NOT NULL default '0',
       UNIQUE KEY `ID` (`ID`),
       UNIQUE `single` (`NimbleGen_Id`,`Marker`),
       KEY `NimbleGen` (`NimbleGen_Id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1
  " ) or die $self->{dbh}->errstr();

    return 1;

}

=head2 DataExists

=head3 atributes

[0]: the NimbleGene Array Id

[1]: the DNA labeling dye (cy3 or cy5) or the antibody specificity string

=head3 retrun value

true if the hybridization is found in the table or false if it is not found

=cut

sub DataExists {
    my ( $self, $nimbleID, $Marker ) = @_;

    return 1 == 1 if ( defined $self->{usedData_byID}->{$nimbleID} );
    return 1 == 1 if ( defined $self->{usedData}->{"$nimbleID$Marker"} );
#    die "hybInfo->DataExists bitte nach nimbleID und Marker|antibody_spec suchen!\n" unless (defined $Marker);

    my ( $sth, $rv, $celltype, $organism, $design, $antibody, $marker );

    if ( lc($Marker) =~ m/cy[53]/){
          $rv =  "Select * from HybInfo where NimbleGen_Id = $nimbleID && Marker = \"$Marker\" ";
    }
    elsif($Marker =~m/\w/) { ## offensichtlich soll nach nimblegeneID und Antibody gesucht werden!
       $marker = $self->{antibodyDB}->SelectId_BySpecificity($Marker);
       $rv =  "Select * from HybInfo where NimbleGen_Id = $nimbleID && Antibody_ID = $marker"; 
    }
    unless (defined $Marker) {
       $rv = " Select * from HybInfo where ID = $nimbleID ";
    }
    $sth =
      $self->{dbh}->prepare( $rv) or die $self->{dbh}->errstr(); 

#    print "DataExists uses :\n$rv;\n";

    $rv = $sth->execute();
    if ( $rv > 0 ) {
        $rv       = $sth->fetchrow_hashref();
        $nimbleID = $rv->{NimbleGen_Id};
#        $Marker   = $rv->{Marker};
        $self->{usedData}->{"$nimbleID$Marker"} = $rv;
        $self->{usedData_byID}->{ $rv->{ID} } = $rv;
        return 1 == 1;
    }
    return 1 == 2 if (defined $Marker);
 
    $rv = " Select * from HybInfo where NimbleGen_Id = $nimbleID ";
    $sth =
      $self->{dbh}->prepare( $rv) or die $self->{dbh}->errstr();
    $rv = $sth->execute();
    if ( $rv > 0 ) {
        $rv       = $sth->fetchrow_hashref();
        $nimbleID = $rv->{NimbleGen_Id};
#        $Marker   = $rv->{Marker};
        $self->{usedData}->{"Nimble:$nimbleID"} = $rv;
#        print "Got only one NimbleGeneID!! $nimbleID\n$rv->{ID}";
        
        $self->{usedData_byID}->{ $rv->{ID} } = $rv;
        return 1 == 1;
    }

    return 1 == 0;
}

=head2 GetInfoID_forHybType

Each array hybridization contains two diferent DNA samples. Each of these samples has its own hybridization id, but
this method returns only one of these two.
Use this method if you need
only one id ,for example to store the enrichment factors for one 'ChIP on chip' experiment.

=head3 atributes

See L<GetInfoIDs_forHybType|"GetInfoIDs_forHybType">

=head3 return value

the internal table line id for this specific habridization

=cut

sub GetInfoID_forHybType{
    my ($self, $specificity, $celltype, $organism, $design ) = @_;
    my ($rv);
    $rv = $self->GetInfoIDs_forHybType($specificity, $celltype, $organism, $design );
    return @$rv[0];
}

=head2 GetInfoIDs_forHybType

=head3 atributes

[0]: the antibody string as accepted by L<database::antibodyDB/"SelectId_BySpecificity">

[1]: the celltype string as accepted by L<database::cellTypeDB/"SelectID_ByCellType">

[2]: the organism string as accepted by L<database::cellTypeDB/"SelectID_ByCellType">

[3]: the design string as accepted by L<database::designDB/"SelectId_ByArrayDesignString">

=head3 return value

the reference to a array containing the HybInfo table line id«s matching to the search parameters

=cut

sub GetInfoIDs_forHybType{
    my ($self, $specificity, $celltype, $organism, $design ) = @_;
    my ($rv, $celltypeID, $antibodyID, $orgnismID, $designID, $sth);


    unless ( $design =~ m/\w/ ){
        $designID = $design;
    }
    else {
        $designID =
          $self->{designDB}->SelectId_ByArrayDesignString($design);
        die "$self: Design $design wurde nicht in der Datenbank gefunden!\n"
          unless ( defined $designID );
    }
    $antibodyID = $self->{antibodyDB}->SelectId_BySpecificity($specificity);
    die "$self: Antibody -$specificity- wurde nicht in der Datenbank gefunden!\n"
      unless ( defined $antibodyID );
    $celltypeID =
      $self->{cellTypeDB}->SelectID_ByCellType( $celltype, $organism );
    die
"$self: Zelltyp $celltype + $organism wurde nicht in der Datenbank gefunden!\n"
    unless ( defined $celltypeID );

#    print "GetInfoIDs_forHybType : $specificity, $celltype, $organism, $design \n",
#          "=> $antibodyID, $celltypeID, $designID\n",
#          "Select ID from HybInfo where Antibody_ID = $antibodyID && Celltype_ID = $celltypeID && ArrayDesignId = $designID;\n"; 
    $sth = $self->{dbh}->prepare("Select ID from HybInfo where Antibody_ID = $antibodyID && Celltype_ID = $celltypeID && ArrayDesignId = $designID " )
        or die $self->{dbh}->errstr();

    $rv = $sth->execute() or die $sth->errstr();
    return undef unless ( $rv > 0);
    $rv = $sth->fetchall_arrayref();
    my @return; 
    foreach my $temp (@$rv){
      push( @return, @$temp[0]);
    }
    return \@return;
}


=head2 insertData

=head3 atributes

[0]: the NimbleGene id

[1]: the DNA labeling marker (cy3 or cy5)

[2]: the antibody specificity as accepted by L<database::antibodyDB/"SelectId_BySpecificity">

[3]: the celltype as accepted by L<database::cellTypeDB/"SelectID_ByCellType">

[4]: the organism string as accepted by L<database::cellTypeDB/"SelectID_ByCellType">

[5]: the template type (experimental or input) as defined in the NimbleGene SampleKey.txt file

[6]: the design string as accepted by L<database::designDB/"SelectId_ByArrayDesignString">

=head3 return values

true if the array hybridization was found in the table after insertion, false if not 

=cut

sub insertData {
    my ( $self, $nimbleID, $Marker, $specificity, $celltype, $organism,
        $TemplateType, $array_Design )
      = @_;

    my ( $antibodyID, $celltypeID, $designID );
    
    unless ( $self->DataExists( $nimbleID, $Marker ) ) {
        die
"insertData benÃ¶tigt nimbleID, Marker, specificity, celltype, organism, TemplateType und array_Design Informationen!\n"
          unless ( @_ == 8 );
#        print "insertData test for antibody = $specificity\n";
        $antibodyID = $self->{antibodyDB}->SelectId_BySpecificity($specificity);
        return "antibody"
          unless ( defined $antibodyID );

#        print "insertData test for celltype = $celltype, organism = $organism\n";
        $celltypeID =
          $self->{cellTypeDB}->SelectID_ByCellType( $celltype, $organism );
        return "celltype"
          unless ( defined $celltypeID );

#        print "insertData test for array_Design = $array_Design\n";
        $designID =
          $self->{designDB}->SelectId_ByArrayDesignString($array_Design);
        return "design"
          unless ( defined $designID );
#        print "Insert into HybInfo ( NimbleGen_Id, Marker, TemplateType, Celltype_ID, Antibody_ID, ArrayDesignId )",
#              " values ( $nimbleID, \"$Marker\", \"$TemplateType\", $celltypeID, $antibodyID, $designID);\n ";

        $self->{dbh}->do( "
              Insert into HybInfo ( NimbleGen_Id, Marker, TemplateType, Celltype_ID, Antibody_ID, ArrayDesignId )
              values ( $nimbleID, \"$Marker\", \"$TemplateType\", $celltypeID, $antibodyID, $designID) "
          )
          or die $self->{dbh}->errstr();
        $self->DataExists( $nimbleID, $Marker );
    }

#    return $self->{usedData_byID}->{$nimbleID}->{ID} if ( defined $self->{usedData_byID}->{$nimbleID} );
#    print "insertData return value 1 = $self->{usedData}->{\"$nimbleID$Marker\"}->{ID}\n";
#    return $self->{usedData}->{"$nimbleID$Marker"}->{ID} if ( defined $self->{usedData}->{"$nimbleID$Marker"} );
#    print "insertData return value 2 = ",$self->SelectID_ByHybInfo( $nimbleID, $Marker ),"\n";
    return $self->SelectID_ByHybInfo( $nimbleID, $Marker );
}

sub selectHybInfosForDesignID_byHybID{

  my ( $self, $designID )= @_;
  die "Bitte eine DisignID angeben (selectHybIdForDesignID)!" unless (defined $designID );

  my ( $sth, $rv, $hash);

  $designID =
          $self->{designDB}->SelectId_ByArrayDesignString($designID);
  $sth = $self->{dbh}->prepare("select * from HybInfo where ArrayDesignId = $designID ") or die $self->{dbh}->errstr();
  $rv = $sth-> execute();
  if ( $rv > 0 ){
    return $sth-> fetchall_hashref("ID");
  }
  warn "No Hybridizations for $designID!\n";
  return undef;
}

=head2 SelectHybInfo_ByID

=head3 atributes

[0]: the HybInfo table line id

=head3 retrun values

a hashref with the sturcture {ID => the intername HybInfo table line id, 
NimbleGen_Id => the NimbleGene 'Chip on chip' experiment id, Marker => the DNA labeling color (cy3 or cy5), 
TemplateType => the template type as defined in the NimbleGene SampleKey.txt file, 
Celltype_ID => as returned from L<database::cellTypeDB/"SelectID_ByCellType">, 
Antibody_ID => as returned from L<database::antibodyDB/"SelectId_BySpecificity">,
ArrayDesignId => as returned from L<database::designDB/"SelectId_ByArrayDesignString"> }
=cut

sub SelectHybInfo_ByID {
    my ( $self, $ID ) = @_;
#    print "SelectHybInfo_ByID $ID\n";
    return $self->{usedData_byID}->{$ID}
      if ( defined $self->{usedData_byID}->{$ID} );
    if ( $self->DataExists($ID) ) {
        return $self->{usedData_byID}->{$ID};
    }
    return undef;
}

sub getInfo4NimbleGeneID{
	my ( $self, $nimbleGeneID) = @_;
	my $data = $self->getAllByNimbleID();
	my ($celltype, $antibody, $i );
	$celltype = $data->{$nimbleGeneID}->{experiment}->{Celltype};
	$antibody = $data->{$nimbleGeneID}->{experiment}->{Antibody};
	$i = 0;
	foreach my $Id (sort {$a <=> $b} keys %$data){
		$i ++ if ( $data->{$Id}->{experiment}->{Celltype} eq $celltype &&
			 $data->{$Id}->{experiment}->{Antibody} eq $antibody);
		last if ( $Id == $nimbleGeneID );
	}
	return "$celltype $antibody #$i";
}

sub getAllByNimbleID {
   my ( $self) = @_;

   my ( $rv, $sth, $return , $id, $nimbleID, $marker, $templateType, $celltypeID, $antibodyID, $designID );

   $sth  = $self->{dbh}->prepare("
      Select ID, NimbleGen_Id, Marker, TemplateType, Celltype_ID, Antibody_ID, ArrayDesignId from HybInfo 
   ") or die $self->{dbh}->errstr() ;

   $rv = $sth->execute();
   return undef if ( $rv < 1);
   
   $sth->bind_columns(\$id, \$nimbleID, \$marker, \$templateType, \$celltypeID, \$antibodyID, \$designID );

   while ( $sth->fetch){
     unless ( defined $return->{$nimbleID}){
       my ($temp, %cy5, %cy3);
       $temp = { cy3 => \%cy3, cy5 => \%cy5 , total => undef, experimental => undef};
       $return->{$nimbleID} = $temp;
     }
     $return->{$nimbleID}->{lc($marker)}->{ID} = $id;
     $return->{$nimbleID}->{lc($marker)}->{NimbleGen_Id} = $nimbleID;
     $return->{$nimbleID}->{lc($marker)}->{Marker} = $marker;
     $return->{$nimbleID}->{lc($marker)}->{TemplateType} = $templateType;
     $rv = $self->{cellTypeDB}->SelectCellType_ByID($celltypeID);
	 #$rv->{organism} = "" unless ( defined $rv->{organism} );
	 #$rv->{cellType} = "" unless ( defined $rv->{cellType} );
     $return->{$nimbleID}->{lc($marker)}->{Celltype} = "$rv->{organism}:$rv->{cellType}";
     $return->{$nimbleID}->{lc($marker)}->{Antibody} = $self->{antibodyDB}->SelectSpecificity_ByID($antibodyID);
     $return->{$nimbleID}->{lc($marker)}->{ArrayDesign} = $self->{designDB}->SelectArrayDesignString_ById($designID);
     $return->{$nimbleID}->{total} = $return->{$nimbleID}->{lc($marker)} 		if ( lc($return->{$nimbleID}->{lc($marker)}->{TemplateType}) eq "total" );
     $return->{$nimbleID}->{experiment} = $return->{$nimbleID}->{lc($marker)} 	if ( lc($return->{$nimbleID}->{lc($marker)}->{TemplateType}) eq "experiment");
   }

   return $return; 
}

=head2 SelectID_ByHybInfo

=head3 atributes

See L<DataExists,"DataExists">

=head3 return value

the internal HybInfo table line id for the specified hybridization

=cut

sub SelectID_ByHybInfo {
    my ( $self, $nimbleID, $Marker ) = @_;

#    my $data = $self->{usedData};
#    print "usedData\n";
#    foreach my $key (%$data){
#      print "$key -> $data->{$key}\n";
#    }

#    print "SelectID_ByHybInfo search for $nimbleID, $Marker\n";
    if ( defined $Marker){
    return $self->{usedData}->{"$nimbleID$Marker"}->{ID}
      if ( defined $self->{usedData}->{"$nimbleID$Marker"} );

    if ( $self->DataExists( $nimbleID, $Marker ) ) {
        return $self->{usedData}->{"$nimbleID$Marker"}->{ID}
           if ( defined $self->{usedData}->{"$nimbleID$Marker"} ); 
    }
    }
    my $temp =  $self->SelectHybInfo_ByID($nimbleID);
    return $temp->{ID} if ( defined $temp->{ID});
    $temp = $self->{usedData}->{"Nimble:$nimbleID"};
    return $temp->{ID} if ( defined $temp->{ID});
    return undef;
}

1;
