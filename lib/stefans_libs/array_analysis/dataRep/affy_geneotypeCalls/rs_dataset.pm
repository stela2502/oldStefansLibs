package rs_dataset;

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
#use warnings;

sub new {

	my ( $class, $hash ) = @_;

	#,$rsID, $genotypedPersons, $genotypeCalls
	my ($self);
	die "rs_dataset needs at least a rsID upon initialization!\n"
	  unless ( defined $hash->{rsID} );
	$self = {
		genotypedPersons => undef,
		genotypeCalls    => undef,
		major            => $hash->{major},
		minor            => $hash->{minor},
		affyID			 => $hash->{affyID},
		rs_id            => $hash->{rsID},
		'chr'			 => $hash->{'chr'},
		'position'		 => $hash->{'position'},
		strand			 => $hash->{'onStrand'}
	};

	bless $self, $class if ( $class eq "rs_dataset" );
	$self->addGeneotypeCalls( $hash->{genotypedPersons}, $hash->{genotypeCalls} )
	  if ( defined $hash->{genotypedPersons} && defined $hash->{genotypeCalls}  );
	return $self;

}

sub print{
	my ( $self ) = @_;
	print "$self: $self->{rs_id} ($self->{strand}) at chr $self->{chr} pos $self->{position} with nucl $self->{major}/$self->{minor} and affyID $self->{affyID}\n";
	print $self->getPersonHeader_withRS_column(),"\n";
	my $calls = $self->{genotypeCalls};
	print "\t",join("\t",@$calls),"\n";
	print $self->getGenotypeCalls_withRS_column();
	return 1;
}

sub getUniqueGenotypeCalls{
	my ( $self ) = @_;
	## the user wants us to report only those person data 
	## sets where we have either a 0 or a 2 -> sure calls
	
}

sub rsID{
	my ( $self, $rsID) = @_;
	$self->{rs_id} = $rsID if ( defined $rsID && $rsID =~ m/^rs\d+$/ );
	return $self->{rs_id};
}

sub AffyID{
	my ( $self, $affyID) = @_;
	$self->{affyID} = $affyID if ( defined $affyID);
	return $self->{affyID}; 
}

sub getPersonHeader_withRS_column{
	my ( $self) = @_;
	my $temp = $self->{genotypedPersons};
	return join("\t", ('rs id', @$temp));
}

sub getGenotypeCalls_withRS_column{
	my ( $self ) = @_;
	my $string;
	return undef unless ( $self->with_genotypeCalls());
	my $genotypeTags = $self->getGenotypeTagArray();
	$string = $self->rsID();
	#root::print_hashEntries( @$genotypeTags , 4, "what is in the array \@genotypeTags for rsID $string??");
	foreach my $array (@$genotypeTags) {
		 if ( defined @$array[0]){
		$string .= "\t@$array[0]/@$array[1]";
		 }
		 elsif ( "AGCTagct" =~ m/$array/){
		 $string .= "\t$array";
		 }
		 else{
		 	$string .= "\tna";
		 }
	}
	return $string."\n";
}

sub with_genotypeCalls{
	my ( $self) = @_;
	my $temp = $self->{genotypeCalls};
	return 1 if ( defined @$temp[0] );
	return 0;
}

sub getGenotypeCallArray_4_personID{
	my ( $self, $personID ) = @_;
	my ( $id, @personIDs, $calls );
	@personIDs = $self->GenotypedPersons();
	$id = 0;
	for ( $id = 0; $id < @personIDs; $id++){
		last if ( $personIDs[$id] eq $personID);
	}
	return $self->getGenotypeCall_4_id ( $id );
}

sub getGenotypeCall_4_id{
	my ( $self, $id, $noCallString ) = @_;
	my $call = $self->{genotypeCalls}[$id];
	return undef unless ( defined $call);
			my @string;
	if ( $call > -1 && $call < 2 ){
		$string[0] = $self->{major};
	}
	elsif ( $call  == 2 ) {
		$string[0] = $self->{minor};
	}
	elsif ( $call  == -1 ) {
		$string[0] = $noCallString;
	}
	
	
	if ( $call > 0 && $call < 3 ){
		$string[1] = $self->{minor};
	}
	elsif ( $call  == 0 ) {
		$string[1] = $self->{major};
	}
	elsif ( $call  == -1 ) {
		$string[1] = $noCallString;
	}
	return \@string;
}

sub getGenotypeTagArray{
	my ( $self, $noCallString ) =@_;
	
	my ( @return);
	my $calls = $self->{genotypeCalls};
	
	for( my $id = 0; $id < @$calls; $id ++) {
	push (@return, $self->getGenotypeCall_4_id($id, $noCallString));
	}
	#print "getGenotypeTagArray returns the array ( @string ) for call $table->{$personID}[$i]\n";
	
	return \@return;	
}

sub isOnArray{
	my $self = shift;
	return 1 if ( defined $self->{affyID} );
	return 0;
}

sub GenotypedPersons {
	my ( $self, $array ) = @_;
	$self->{genotypedPersons} = $array if ( defined @$array[0] );
	my $temp = $self->{genotypedPersons};
	return @$temp;
}

sub addGeneotypeCalls {
	my ( $self, $personArray, $callArray ) = @_;
	die "addGeneotypeCalls no data! ( $personArray, $callArray )\n"
	  unless ( defined @$callArray[0] );
	my @persons = $self->GenotypedPersons($personArray);
	for ( my $i = 0 ; $i < @persons ; $i++ ) {
		die "dataset for genotyped Person $persons[$i] is missing\n"
		  unless ( defined @$callArray[$i] );
	}
	$self->{genotypeCalls} = $callArray;
	return @$callArray;
}



1;
