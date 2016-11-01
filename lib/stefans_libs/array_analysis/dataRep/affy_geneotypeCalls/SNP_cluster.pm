package SNP_cluster;
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

sub new{

	my ( $class, $rs_dataset_list, $arraySorter ) = @_;

	my ( $self );
	
	die "SNP_cluster absolutely needs an array of rs_datasets at initializytion\n" 
		unless ( defined @$rs_dataset_list && ref(@$rs_dataset_list[0]) eq "rs_dataset");
	die "SNP_cluster absolutely needs an arraySorter at initialization\n" unless ( ref($arraySorter) eq "arraySorter");
	
	$self = {
		debug => 1==1,
		rs_dataset_list => $rs_dataset_list,
		arraySorter => $arraySorter
#		'position' => undef,
#		'major' => undef,
#		'minor' => undef,
#		'chr' => undef,
#		'humIDs' => undef,
#		'rs id' => undef,
#		'probeset_id' => undef
  	};

  	bless $self, $class  if ( $class eq "SNP_cluster" );
	
  	return $self;

}

sub compareWithHapmapDataSet{
	my ( $self, $hapMap_obj ) = @_;
	## @haplotypes = $hapMap_obj -> select_Haplotypes4rsList();
	
}

sub _getPositionInArray{
	my ( $self, $value, $array ) = @_;
	for ( my $i = 0; $i < @$array; $i ++){
		return $i if ( @$array[$i] eq $value );
	}
	return undef;
}

sub print{
	my ( $self, $state) = @_;
	
	my $matrix = $self->{rs_dataset_list};
	print "$self debug = $self->{debug}; arraySorter = $self->{arraySorter}\n";
	foreach (@$matrix){
		$_->print();
	}
	return 1;
}

sub get_Person_array{
	my ( $self ) = @_;
	return $self->{rs_dataset_list}[0]->GenotypedPersons();
}

sub get_RS_array{
	my ( $self ) = @_;
	
	if ( defined $self->{rsList} ) {
		my $temp = $self->{rsList};
		return @$temp;
	}
	my ( $data, @array);
	$data = $self->{rs_dataset_list};
	foreach ( @$data ) {
		push (@array, $_->rsID() );
	}
	$self->{rsList} = \@array;
	return @array;
}

sub get_rsHash_of_NuclPosArrays_4_Person{
	my ( $self, $personName ) = @_;
	my ($hash, @persons, $rs_datasets );
	$rs_datasets = $self->{rs_dataset_list};
	foreach (@$rs_datasets){
		$hash->{$_->rsID()} = $_->getGenotypeCallArray_4_personID($personName);
	}
	return $hash;
}

sub get_rsHash_of_NuclPosArrays_4_PersonID{
	my ( $self, $personID ) = @_;
	my ($hash, @persons, $rs_datasets );
	$rs_datasets = $self->{rs_dataset_list};
	foreach (@$rs_datasets){
		$hash->{$_->rsID()} = $_->getGenotypeCall_4_id($personID);
	}
	return $hash;
}


sub getAsPhaseInputString{
	my ( $self ) = @_;
	
	my ( $table, $string, $hash, $lineArray, $individuals, $temp, $rsIDs, $SNP_calls, @sortOrder);
	$string = "";
	$table = $self->{rs_dataset_list};
	@sortOrder = ( { 'position' => 'chr', 'type' => 'numeric'}, { 'position' => 'position', 'type' => 'numeric' });
	
	@$table = $self->{arraySorter}->sortHashListBy( \@sortOrder, @$table);

	#$self->print($table);
	
	die "everything has changed! befor use, this function has to be cleand up!\n";
	
	$hash = $self->createSearchableHash ( $table );
#	A 					->	C	C	C	A
#	B 					->	G	G	T	G
#	rs id 				->	rs17024559	rs10127888	rs10923928	rs17024584
#	chr 				->	1	1	1	1
#	position 			->	120292824	120299773	120307043	120312909
#	probeset_id 		->	SNP_A-2030294	SNP_A-1964464	SNP_A-4233281	SNP_A-2288138
#	sample_Nsp 1.CEL 	->	0	1	0	2
#	.
#	.
#	.

	$individuals = $self->{person_array};
	#print "person array = ( @$individuals )\n";
#	( sample_Nsp 1.CEL, ... )
	
	$string .= @$individuals."\n";
	$rsIDs = $hash->{'rs id'};
	$string .= @$rsIDs."\n";
	$temp = $hash->{position};
	$string .= "P ".join(" ", @$temp)."\n";
	foreach ( @$rsIDs ){
		$string .= "S";
	}
	$string .= "\n";
	
	for (my $personID = 0 ; $personID < @$individuals; $personID ++ ){
		#print "We try to use person ID @$individuals[$personID] \n";
		#print "as hash key to $hash->{@$individuals[$personID]}\n";
		$SNP_calls = $hash->{@$individuals[$personID]};
		$temp = @$individuals[$personID];
		$string .= "#".join("_", (split(" ", $temp)))."\n";
		## first line!
		for( my $SNP_i = 0; $SNP_i < @$SNP_calls; $SNP_i ++ ){
			if ( @$SNP_calls[$SNP_i] > -1 && @$SNP_calls[$SNP_i] < 2){
				$string .= $hash->{'A'}[$SNP_i]." ";
			}
			elsif( @$SNP_calls[$SNP_i] == 2 ){
				$string .= $hash->{'B'}[$SNP_i]." ";
			}
			elsif( @$SNP_calls[$SNP_i] == -1 ){
				$string .= "? ";
			}
		}
		$string .= "\n";
		
		## second line!
		for( my $SNP_i = 0; $SNP_i < @$SNP_calls; $SNP_i ++ ){
			if ( @$SNP_calls[$SNP_i] > 0 && @$SNP_calls[$SNP_i] < 3){
				$string .= $hash->{'B'}[$SNP_i]." ";
			}
			elsif( @$SNP_calls[$SNP_i] == 0 ){
				$string .= $hash->{'A'}[$SNP_i]." ";
			}
			elsif( @$SNP_calls[$SNP_i] == -1 ){
				$string .= "? ";
			}
		}
		$string .= "\n";
		
	}
	print "We have the return string \n$string";
	return $string;
}

1;
