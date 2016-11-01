package gin_file;
 
 use strict;
 use stefans_libs::tableHandling;
 
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
 
 sub new{
 
 	my ( $class, $fileName ) = @_;
 
 	my ( $self, $data );
 
 	$self = {
 		data => $data,
 		tableHandling => tableHandling->new(),
 		affyID => undef,
 		id => undef
   	};
 
   	bless $self, $class  if ( $class eq "gin_file" );
 
 	$self->AddFile($fileName) if ( defined $fileName);
   	return $self;
 
 }
 
 sub AddFile{
 	my ( $self, $file ) = @_;
 	open ( IN, "<$file") or die "could not open file $file\n";
 	
 	my ( $line, $linesOfInterest, @values);
 	$line = 0;
 	while ( <IN> ){
 		## here the problems start:
 		## overview over the file contents:
 		
 		#HEADER:
 		#Version=2
 		#Arrays=HG-U133A
 		#NURLS=0
 		#
 		#DATA:
 		#<tab> separated file (only three with data in the HU-U133A chip)
 		#
 		#Probe Set
 		#Description
 		#Sequence Type
 		#
 		#
 		#Probe Set -> <Probe Set ID>
 		#Description -> U48705 /FEATURE=mRNA /DEFINITION=HSU48705 Human receptor tyrosine kinase DDR gene, complete cds
 		#Description -> Cluster Incl. X72631:H.sapiens mRNA encoding Rev-ErbAalpha /cds=UNKNOWN /gb=X72631 /gi=732801 /ug=Hs.211606 /len=2335
 		#
 		#Sequence Type -> Gene
 		#Sequence Type -> mRNA
 		
 		$line ++;
 		chomp $_;
 		if ( $line == 1){
 			die "file $file is not a .gin file!\n" unless ( $_ =~ m/Version=([\.\d]+)/ );
 			$self->{version} = $1;
 			next;
 		}
 		if ( $line == 2){
 			die "file $file is not a .gin file!\n" unless ( $_ =~ m/Arrays=(.+)/);
 			$self->{array} = $1;
 			next;
 		}
 		next if ( $line == 3);
 		if ( $line == 4){
 			$linesOfInterest = $self->{tableHandling}->identify_columns_of_interest_bySearchHash(
 				$_,
 				$self->{tableHandling}->createSearchHash( "Probe Set", "Description")
 			);
 			next;
 		}
 		my ($tag, $entry) = geneInfo->new($self->{tableHandling}->get_column_entries_4_columns($_, $linesOfInterest));
 		$self->{data}->{$tag} = $entry;
 	}
 }
 
 sub getKEGG_Link_4_affyID{
 	my ( $self, $affyID) = @_;
 	return undef unless ( defined $self->{$affyID});
 	return $self->{$affyID}->getKegg_Link();
 }
 
 sub getNCBI_Link_4_affyID{
 	my ( $self, $affyID) = @_;
 	return undef unless ( defined $self->{$affyID});
 	return $self->{$affyID}->getNCBI_Link();
 }
 
 sub getGeneCards_Link_4_affyID{
 	my ( $self, $affyID) = @_;
 	return undef unless ( defined $self->{$affyID});
 	return $self->{$affyID}->getGeneCards_Link();
 }
 
 1;
