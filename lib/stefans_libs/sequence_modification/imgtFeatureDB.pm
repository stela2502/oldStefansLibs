package imgtFeatureDB;
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
use stefans_libs::sequence_modification::imgtFile;

sub new {
    my ($class) = @_;

    my ( $self, $dbh_imgt ,%ID2acc, %acc2ID, $imgt, %ID2IMGT, $root);

    $root = root->new();
    $dbh_imgt = $root->getDBH("IMGT"); 

    $self = {
      root => $root, 
      dbh => $dbh_imgt,
      id2imgt => \%ID2IMGT,
	  ID2acc => \%ID2acc,
	  acc2ID => \%acc2ID
     };

    $self->{imgtTOgbk} = $imgt;
    bless( $self, $class ) if ( $class eq "imgtFeatureDB" );

    return $self;
}

sub CreateIMGTtoDB_Hash{
  my $self = shift;
  ## No need for that!
  my $dbh = $self->{root}->getDBH("gbk") or die $_;
  my $sth = $dbh->prepare("select * from imgt");
  $sth->execute;
  my ( $gbk, $imgt);
  $sth->bind_columns(\$gbk, \$imgt);
  while ( $sth->fetch){
    print "\"$gbk\" => \"$imgt\",\n";
  }
  return;
}

sub DataExists {
    my ($self) = @_;

    die "Funtion ist noch nicht implementiert!\n";

}

sub CreateTable {
    my ($self) = @_;

    $self->{dbh}->do("DROP TABLE IF EXISTS acc") or die $self->{dbh}->errstr;

    $self->{dbh}->do(
        "CREATE TABLE acc (
  Id int(11) NOT NULL auto_increment,
  acc varchar(20) NOT NULL default '',
  length int(11) NOT NULL default '0',
  acc_real varchar(20) NOT NULL default '',
  PRIMARY KEY  (Id),
  UNIQUE KEY ID (Id),
  KEY ACC (acc),
  KEY ACC_REAL (acc_real)
) ENGINE=MyISAM DEFAULT CHARSET=latin1"
      )
      or die $self->{dbh}->errstr;

    print "Table acc geloescht und neu angelegt!\n";

    $self->{dbh}->do("DROP TABLE IF EXISTS features")
      or die $self->{dbh}->errstr;
    $self->{dbh}->do(
        "CREATE TABLE features (
  Id int(11) NOT NULL default '0',
  name varchar(100) NOT NULL default '',
  tag varchar(100) NOT NULL default '',
  info varchar(100) NOT NULL default '',
  anfang int(11) NOT NULL default '0',
  ende int(11) NOT NULL default '0',
  KEY ID (Id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1"
      )
      or die $self->{dbh}->errstr;

    print "Table features geloescht und neu angelegt!\n";

    $self->{dbh}->do("DROP TABLE IF EXISTS imgt")
      or die $self->{dbh}->errstr;
    $self->{dbh}->do("CREATE TABLE imgt (
  imgt_tag varchar(100) NOT NULL default '',
  gbk_tag varchar(100) NOT NULL default '',
  PRIMARY KEY  (imgt_tag),
  UNIQUE KEY ID (imgt_tag),
  KEY IMGT_TAG (imgt_tag),
  KEY gbk_Tag (gbk_tag)
) ENGINE=MyISAM DEFAULT CHARSET=latin1")
      or die $self->{dbh}->errstr;

    return 1;

}

sub getAcc4ID{
	my ( $self, $ID) = @_;
	
	return $self->{ID4acc} ->{$ID} if ( defined $self->{ID4acc} ->{$ID});
	my ( $sth, $rv );
	$sth = $self->{dbh}->prepare("Select * from acc where Id = ?")
      or die $self->{dbh}->errstr;
	$rv = $sth->execute($ID) or die $sth->errstr;
	return undef if ( $rv < 1 );
	$rv = $sth->fetchrow_hashref();
	$self->{ID2acc} ->{$ID} = $rv->{acc};
	$self->{acc2ID} ->{$rv->{acc}} = $ID;
	return $rv->{acc};
}

sub getInfoID {

    my ( $self, $acc ) = @_;

    my ( $sth, $rv );
	return $self->{acc2ID}->{$acc} if (defined $self->{acc2ID} ->{$acc});
	
	$acc = $1 if ($acc =~ m/lcl.(.*)/ );
    $sth = $self->{dbh}->prepare("Select * from acc where acc = ?")
      or die $self->{dbh}->errstr;

    $rv = $sth->execute("$acc") or die $self->{dbh}->errstr;

    if ( $rv < 1 ) {
        $sth = $self->{dbh}->prepare("Select * from acc where acc_real = ?")
          or die $self->{dbh}->errstr;
        $rv = $sth->execute("$acc") or die $sth->errstr;
        return undef if ( $rv < 1 );
    }

    $rv = $sth->fetchrow_hashref();
	#print "imgtFeatureDB: Id for acc $acc = $rv->{Id}\n";
	$self->{ID2acc} ->{$rv->{Id}} = $acc;
	$self->{acc2ID} ->{$acc} = $rv->{Id};
    return $rv->{Id};

}

sub addData {
    my ($self) = @_;

    die "Funtion ist noch nicht implementiert!\n";

}

sub GetIMGT_entry_forACC {
    my ( $self, $acc ) = @_;
	
    return $self->GetIMGT_entry_forInfoID( $self->getInfoID($acc) );
}

sub GetIMGT_entry_forInfoID {
    my ( $self, $id ) = @_;
    my ( $sth, $rv, $imgtFile );

    return $self->{id2imgt}->{$id} if ( defined $self->{id2imgt}->{$id});

    $sth = $self->{dbh}->prepare("Select * from features where Id = ?")
      or die $self->{dbh}->errstr;

    $rv = $sth->execute($id) or die $sth->errstr;

    $imgtFile = imgtFile->new( $sth->fetchall_arrayref, $self->getAcc4ID($id) );

    $self->{id2imgt}->{$id} = $imgtFile;
    #print "imgtFeatureDB: Ich versuche jetzt das passende IMGT File auszugeben!\n";
    #$imgtFile->Print();
    return $self->{id2imgt}->{$id};

}

1;
