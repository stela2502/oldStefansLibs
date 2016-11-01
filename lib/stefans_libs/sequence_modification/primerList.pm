package primerList;
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
use stefans_libs::sequence_modification::primer;
use stefans_libs::root;

sub new{

   my ( $class ) = @_;

   my ( $self, %primer, $dbh, $sth, $sth_add, $sth_tw, $root, $sth_all, $sth_update) ;

   $root = root->new();
   $dbh = $root->getDBH("Primer") or die $_;
   $sth = $dbh->prepare("select * from primer where Name = ? ") or die $dbh->errstr;
   $sth_add = $dbh->prepare("insert into primer (TW,  Name, Sequenz) values ( ?, ? , ?)") or die $dbh->errstr();
   $sth_tw = $dbh->prepare("select * from primer where TW = ? ") or die $dbh->errstr;
   $sth_all = $dbh->prepare ( "select * from primer") or die $dbh->errstr;
   $sth_update = $dbh->prepare ( "update primer set TW = ? where  Name= \"?\"") or die $dbh->errstr;

   $self = {
     dbh => $dbh,
     sth_select => $sth,
     sth_add => $sth_add,
     sth_select_tw => $sth_tw,
	 sth_select_all => $sth_all,
	 sth_update => $sth_update,
     primerList => \%primer
   };

   bless ( $self, $class) if ( $class eq "primerList");

   return $self;
}


sub CreateDB {
    my ($self) = @_;
    $self->{dbh}->do("DROP TABLE IF EXISTS primer")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
	CREATE TABLE primer (
	  ID smallint(5) unsigned NOT NULL auto_increment,
	  TW varchar(6) NOT NULL default 'null',
	  Name varchar(25) NOT NULL default 'Null',
	  Sequenz varchar(80) NOT NULL default '0',
	  UNIQUE KEY ID (ID)
	) ENGINE=MyISAM AUTO_INCREMENT=3889 DEFAULT CHARSET=latin1;
    " ) or die $self->{dbh}->errstr();
    return 1;
}


sub getAs_scv{
	my ( $self ) = @_;
	my $sth = $self->{dbh}->prepare("Select * from PCR") or die $self->{dbh}->errstr();
    my $rv = $sth->execute();
    return undef unless ($rv > 0);
    my $return = $sth->fetchall_hashref("ID");
    my @IDs = keys ( %$return);
    my $string = "";
    $rv = $return->{$IDs[0]};
    my @columns = (keys %$rv);
    foreach my $column_tag (@columns){
    	$string = "$string$column_tag\t";
    }
    chop $string;
    $string = "$string\n";
    foreach my $id ( sort {$a<=> $b} keys %$return){
    	$rv = $return->{$id};
    	foreach my $column_tag (@columns){
    		$string = "$string$rv->{$column_tag}\t";
    	}
    	chop $string;
 		$string = "$string\n";
    }
    return $string;
}

sub GetPrimer{

   my ( $self, $primername) = @_;

   print "Try to return primer $primername\n";

   my ( $primerList, $rv, $primer ) ;

   chomp $primername;
   $primername = $1 if ( $primername =~ m/lcl.(.*)/ );
	$primername = substr($primername,0,25) if (length($primername) > 25 );
   #
	print "primername changed to $primername\n";

   $primerList = $self->{primerList};

   foreach my $key (keys %$primerList){
     return $primerList->{$key} if ( $key =~ m/$primername/ );
   }
   #$primername = "\"$primername\"";
   if ( $primername =~ m/TW(\d+)/){
     $rv =  $self->{sth_select_tw}->execute($1) ;
     #print "GetPrimer TW$1\n";
     return undef if ($rv < 1);
     $primer = primer->new($self->{sth_select_tw}->fetchall_hashref('ID'));
   }
   elsif ($primername =~ m/^(\d+)$/){
   	print "we search for TW$_ in primer db\n";
   	$rv =  $self->{sth_select_tw}->execute($1) ;
   	if ($rv < 1){
   		print "But we did not find it!\n";
   		return undef;
   	}
   	$primer = primer->new($self->{sth_select_tw}->fetchall_hashref('ID'));
   }
   else{
     $rv = $self->{sth_select}->execute($primername) ;
     return undef if ($rv < 1);
     $primer = primer->new($self->{sth_select}->fetchall_hashref('ID'));
   }
   #foreach my $temp (keys %$primer){
   #  print "\t$temp\t$primer->{$temp}\n";
   #}

   $primerList->{$primer->{name}} = $primer;
   return $primer;
}

sub setTW4_primername{
	my ( $self, $TW, $primername ) = @_;
	
	my ( $return );
	if ( defined $TW && defined $primername ){
		$return= $self->{sth_update}->execute( $TW, $primername );
		warn "$self setTW4_primername db call returned error:\n$return" if ( defined $return);
		print "The TW number was set to $TW for Primer $primername\n";
	}
	return 1;
}

sub AddPrimer{

   my ( $self, $sequence, $name, $tw ) = @_;

   my $primer;
   $tw = 0 unless (defined  $tw);
   $primer = $self->GetPrimer($name);
   
   if ( ! defined $primer ){
      $self->{sth_add}->execute($tw, $name, $sequence) unless ( $name =~ m/^>/);
   }
   elsif ( $primer->TW() == 0 ){
   		$self->{sth_update}->execute($name, $tw);
   		$primer->TW($tw);
   }
   	return 1;
}

sub AddPrimerList{
	
	my ( $self, $primerListFile ) = @_;
	
	my ( @data, @return, $sequence, $tw, $name, $primerDB);
	$primerDB = 1 == 1;
	
	open ( DATA, "<$primerListFile") or $primerDB = 1 == 0 ; #die "AddPrimerList braucht ein 'primerListFile'!\n";
	warn "PrimerList got no list file!\n" unless ($primerDB);
	
	if ( $primerDB ) {
		
		while ( <DATA>){
			chop $_;
			$tw = $name = $sequence = undef;
			next if ( $_ =~ m/^#/);
			@data = split ("\t", $_);
			if (@data < 2 ){
				@data = split (" +", $_);
			}
			next unless ( $data[0] =~ m/[\w\d]*/);
			$name = $data[0];
			my $primer = $self->GetPrimer($data[0]);
			unless (defined $primer ) {
				$sequence = lc($data[1]) if ( $data[1] =~ m/[AGCTagct]+/);
				$tw = $data[1] if ( $data[1] =~ m/\d+/);
				$sequence = $data[2] if ( $data[2] =~ m/[AGCTagct]+/);
				next unless ( defined $sequence);
				$self->AddPrimer($sequence,$name, $tw);
				$primer = $self->GetPrimer($data[0]);
			}
			#print $primer->AsFasta();
			push (@return, $primer); 
		}
	}
	else {
		my ( $temp, $hash, $rv, $primer_db );
		$rv = $self->{sth_select_all}->execute();
		#print "$rv primer in the database\n";
		if ($rv < 1){
			print "command $self->{sth_select_all} did not return any results!\n";
			return undef;
		}
		$primer_db = $self->{sth_select_all}->fetchall_hashref('ID');
		foreach my $ID ( keys %$primer_db ){
			#$temp = $primer_db->{$ID};
			print "primer ID = $ID\n";
			push (@return, primer->new( {primer => $primer_db->{$ID}} ));
		}
	}
	return \@return;

}

   
1;
