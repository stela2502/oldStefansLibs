package haplotypeList;

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

sub new {

	my ( $class, $hash ) = @_;

	my ($self);

	$self = {
		start      => undef,
		end        => undef,
		haplotypes => undef,
		dataMatrix => undef,
		rsIDs      => undef,
		complement => { 'a' => 'T', 'c' => 'G', 'g' => 'C', 't' => 'A' }
	};

	bless $self, $class if ( $class eq "haplotypeList" );

	$self->Start( $hash->{start} );
	$self->End( $hash->{end} );
	$self->addRS_list(
		$hash->{haplotypeNames},
		$hash->{haplotypeMatrix},
		$hash->{rsIDs}
	);

	return $self;

}

sub Start {
	my ( $self, $value ) = @_;
	$self->{start} = $value if ( defined $value );
	return $self->{start};
}

sub End {
	my ( $self, $value ) = @_;
	$self->{end} = $value if ( defined $value );
	return $self->{end};
}

sub match2region {
	my ( $self, $start, $end ) = @_;
	return 0 unless ( defined $start );
	unless ( defined $end ) {
		return ( $self->End >= $start && $self->Start <= $start );
	}
	else {
		return ( $self->End >= $start && $self->Start <= $end );
	}
	return 0;
}

sub addRS_list {
	my ( $self, $nameArray, $dataMatrix, $rsIDs ) = @_;
	## we have to convert the rs_list to a haplotape list!!
	## 1. macht eigentlich keinen Sinn, falls @$rsList == 1;
	## 2. haplotype List ist eigentlich nur eine transponierte rsList mit eindeutigen genotyp calls!
	warn
"we are deleting the old haplotype information in haplotypeList -> addRS_list \n"
	  if ( defined $self->{haplotypes} );
	die
"haplotypeList addRS_list absolutely needs an array of haplotypeNames ($nameArray) \n"
	  unless ( ref($nameArray) eq "ARRAY" );
	die
"haplotypeList addRS_list absolutely needs a matrix of haplotype nucleotode calls ($dataMatrix) \n"
	  unless ( ref($dataMatrix) eq "ARRAY"
		&& ref( @$dataMatrix[0] ) eq "ARRAY" );
	die
	  "haplotypeList addRS_list absolutely needs an array of rsIDs ($rsIDs) \n"
	  unless ( ref($rsIDs) eq "ARRAY" && @$rsIDs[0] =~ m/rs\d+/ );
	my $temp;
	for ( my $i = 0 ; $i < @$dataMatrix ; $i++ ) {
		$temp = @$dataMatrix[$i];
		die
"we have a mismatch between the amount of haplotypeNames and the amount of haplotype nucleotode calls in line $i(rs @$rsIDs[$i]) \n",
		  join( ",", @$nameArray ), "\n", join( ",", @$temp ), "\n"
		  if ( @$nameArray != @$temp );
		die "we have no rsID for data line $i (", join( ",", @$temp ), ")\n"
		  unless ( defined @$rsIDs[$i] );
	}

	$self->{haplotypes} = $self->{rsIDs} = $self->{dataMatrix} = undef;
	$self->Haplotype_names($nameArray);
	$self->RS_IDs($rsIDs);
	$self->{dataMatrix} = $dataMatrix;
	return 1;
}

sub getRS_possibilities {
	my ( $self, $rsID ) = @_;
	my ( $lineID, $hash, $matrixPart, @rsIDs );
	@rsIDs  = $self->RS_IDs();
	$lineID = -1;
	foreach my $my_rsID (@rsIDs) {
		$lineID++;
		last if ( $rsID eq $my_rsID );
	}
	die
"haplotypeList getRS_possibilities: the rsID $rsID was not found in this dataset (",
	  join( ",", (@rsIDs) ), "\n"
	  if ( $lineID == @rsIDs );
	$matrixPart = $self->{dataMatrix}[$lineID];
	foreach (@$matrixPart) {
		$hash->{$_} = 1;
	}
	return ( keys %$hash );
}

sub getHaplotype {
	my ( $self, $haplotypeName ) = @_;

	return $self->{store}->{$haplotypeName}
	  if ( defined $self->{store}->{$haplotypeName} );
	my ( @haplotypes, $rowID, $array, $matrix, @rsIDs, $rsDataArray );
	@rsIDs      = $self->RS_IDs();
	@haplotypes = $self->Haplotype_names();
	$rowID      = -1;
	foreach my $haplotype (@haplotypes) {
		$rowID++;
		last if ( $haplotypeName eq $haplotype );
	}
	die
"haplotypeList getHaplotype: the haplotype $haplotypeName was not in this dataset (",
	  join( ",", @haplotypes ), ")\n"
	  if ( $rowID == @haplotypes );

	$matrix = $self->{dataMatrix};
	for ( my $i = 0 ; $i < @$matrix ; $i++ ) {    #  $rsDataArray (@$matrix) {
		$rsDataArray = @$matrix[$i];
		$array->{ $rsIDs[$i] } = @$rsDataArray[$rowID];
	}
	$self->{store}->{$haplotypeName} = $array;
	return $array;
}

sub containsRSids {
	my ( $self, $rsIDs ) = @_;
	foreach my $rsID (@$rsIDs) {
		return 1 if ( defined $self->{rs2id}->{$rsID} );
	}
	return 0;
}

sub getPossHaplotypes_as_tabSeparatedList_string {
	my ( $self, $possHaplotypes, $personArray ) = @_;
	my ( $string, $printables, $lastRepStr, $data, $used, $bestRSlist, $temp );
	
	## we want to have a list of haplotypes that correspond to the reported smaller parts
	
	$printables = $self->getPrintableHaplotypeConfiguration( $possHaplotypes, $personArray );
	# data structure:
	# personArray (of { <bigHaplotype> => [ <smallHaplotype>, <matchingString>, <rsList>] } )
	# in the log file, we want to know which <smallHaplotype> corresponds to which <bigHaplotype>
	
	
	## find the longest <rsList>
	$bestRSlist = [];
	for ( my $i = 0 ; $i < @$printables ; $i++ ) {
		$data = @$printables[$i];
		foreach my $repStr ( keys %$data ) {
			$temp = $data->{$repStr}[2];
			$bestRSlist = $temp if ( @$temp > @$bestRSlist);
		}
	}
	
	$string = "";
	$string .= "reported haplotype\t->\tHapMap halotype\n";
	$string .= join( "\t", (@$bestRSlist) ) ."\t->\t" . join( "\t", $self->RS_IDs() ) . "\n";
	
	
	for ( my $i = 0 ; $i < @$printables ; $i++ ) {
		$data = @$printables[$i];
		foreach my $repStr ( sort keys %$data ) {
			next if ($used->{$data->{$repStr}[0]});
			$used->{$data->{$repStr}[0]} = 1;
			if ( $lastRepStr eq $repStr ) {
				$string .= join( "\t",split ("", $self->_getString_rel2Array ($bestRSlist, $data->{$repStr}[2], "" )));
				$string .= "\t->";
				$string .= 
				join( "\t",
					( " ", ( split( "", $repStr ) ) ) )
				  . "\n";
			}
			else {
				$string .= join( "\t", (split ("", $self->_getString_rel2Array ($bestRSlist, $data->{$repStr}[2], $data->{$repStr}[1] ) ) ) );
				$string .= "\t->";
				$string .= 
				join( "\t",
					( " ", ( split( "", $repStr ) ) ) )
				  . "\n";
			}
			$lastRepStr = $repStr;
		}
	}
	return $string;
}

sub _getString_rel2Array{
	my ( $self, $bestRSlist, $actualRSlist, $string ) = @_;
	my ($hash, @StrArray);
	@StrArray = split ( "", $string);
	for (my $i = 0; $i < @$actualRSlist; $i++){
		$hash -> {@$actualRSlist[$i]} = $StrArray[$i];
	}
	$string = "";
	foreach ( @$bestRSlist ){
		if ( defined $hash->{$_} ){
		$string .= $hash->{$_}
		}
		else{
			$string .= " ";
		}
	}
	return $string;
}

sub RS_IDs {
	my ( $self, $rsIDs ) = @_;

	if ( ref($rsIDs) eq "ARRAY" ) {
		$self->{rsIDs} = $rsIDs;
		$self->{rs2id} = my $rs2id;

		for ( my $i = 0 ; $i < @$rsIDs ; $i++ ) {
			$self->{rs2id}->{ @$rsIDs[$i] } = $i;
		}
	}

	my $temp = $self->{rsIDs};
	return @$temp;
}

sub _ID_4_RS {
	my ( $self, $rsID ) = @_;
	return $self->{rs2id}->{$rsID};
}

sub Haplotype_names {
	my ( $self, $haplotypes ) = @_;
	$self->{haplotypes} = $haplotypes if ( ref($haplotypes) eq "ARRAY" );
	my $temp = $self->{haplotypes};
	return @$temp;
}

sub _Haplotype_matches2_genotypeCallHash {
	my ( $self, $haplotype, $genoTypeCallArray ) = @_;

	foreach my $rsID ( keys %$genoTypeCallArray ) {
		next unless ( defined $genoTypeCallArray->{$rsID}[0] );
		unless (
			(
				   $genoTypeCallArray->{$rsID}[0] eq $haplotype->{$rsID}
				|| $genoTypeCallArray->{$rsID}[1] eq $haplotype->{$rsID}
			)
			|| !defined $genoTypeCallArray->{$rsID}[1]
		  )
		{

#print "problem! neither $genoTypeCallArray->{$rsID}[0] nor $genoTypeCallArray->{$rsID}[1] equals to $haplotype->{$rsID} ($rsID) \n";
			return 0;
		}
	}
	return 1;
}

sub _Haplotype_matches2_alleleHash {
	my ( $self, $haplotype, $alleleHash ) = @_;

	foreach my $rsID ( keys %$alleleHash ) {
		next unless ( defined $alleleHash->{$rsID} );
		unless ( $alleleHash->{$rsID} eq $haplotype->{$rsID}
			|| $alleleHash->{$rsID} eq "-" )
		{

#print
#"problem! _Haplotype_matches2_alleleHash $alleleHash->{$rsID} != $haplotype->{$rsID} ($rsID) \n";
			return 0;
		}
	}
	return 1;
}

sub _getPossibleMatches_4_personHaplotypeHash {
	my ( $self, $rsID_2_bpValues, $stillPossibleHaplotypes ) = @_;
	my ( @haplotypes, @return, $haplotypeDatHash, $informative, $otherAllele,
		$hash, $temp, @evaluatedAlleles );
	@haplotypes = $self->Haplotype_names();

	unless ( defined @$stillPossibleHaplotypes ) {
		## if we get no list of haplotypes to use, we have to take all that are possible!
		@$stillPossibleHaplotypes = @haplotypes;
	}

	foreach my $haplotype_name (@$stillPossibleHaplotypes) {
		$haplotypeDatHash = $self->getHaplotype($haplotype_name);
		## the $haplotypeDatHash has the structure { <rsID> => <nucleotide> }
		push( @return, $haplotype_name )
		  if (
			$self->_Haplotype_matches2_genotypeCallHash(
				$haplotypeDatHash, $rsID_2_bpValues
			)
		  );
	}
	print "we get the possible haplotypes @return\n";
	@$stillPossibleHaplotypes = @return;

	foreach my $haplotype_name (@$stillPossibleHaplotypes) {

		$haplotypeDatHash = $self->getHaplotype($haplotype_name);
		next
		  if (
			defined $hash->{ $self->possibleHaplotype2string($haplotypeDatHash)
			} );
		$otherAllele =
		  $self->_subtract_putativeAllele_from_genotypeHash( $haplotypeDatHash,
			$rsID_2_bpValues );
		if ( defined $hash->{ $self->possibleHaplotype2string($otherAllele) } )
		{
			print "we already anayzed haplotype ",
			  $self->possibleHaplotype2string($otherAllele), "\n";
			next;
		}

		print "is the other allele ",
		  $self->possibleHaplotype2string($otherAllele),
		  "in respect to the allele ",
		  $self->possibleHaplotype2string($haplotypeDatHash), "in the list?\n";
		## $otherAllele is of the same type as $haplotypeDatHash, but it represents the other allele
		## in $rsID_2_bpValues in respect to $haplotypeDatHash
		## therefore we have to select all possible alleles from the total of possible alleles that
		## are compatible with $otherAllele
		## if we get some alleles in @informative, we have a putative pair of alleles in that person
		$informative =
		  $self->compare_allele_2_possibleHaplotypes( $otherAllele,
			$stillPossibleHaplotypes );
		$temp = @$informative;
		print "we got $temp resulting alleles!\n";
		if ( $temp > 0 ) {
			$hash->{ $self->possibleHaplotype2string($haplotypeDatHash) } =
			  $informative;
		}
		else {
			$hash->{ $self->possibleHaplotype2string($haplotypeDatHash) } =
			  ["no other allel possible"];
		}
		print "Result: ", $self->possibleHaplotype2string($haplotypeDatHash),
		  " = (@$informative)\n";
	}
	print
"did anything go complelety wrong in _getPossibleMatches_4_personHaplotypeHash?\n";
	foreach my $_haplo ( keys %$hash ) {
		$temp = $hash->{$_haplo};
		print "$_haplo -> ", join( ";", @$temp ), "\n";
	}
	return $hash;
}

sub _subtract_putativeAllele_from_genotypeHash {
	my ( $self, $putativeAllele, $rsID_2_bpValues ) = @_;
	my ($otherAllele);
	foreach my $rsID ( keys %$rsID_2_bpValues ) {
		next unless ( defined $rsID_2_bpValues->{$rsID}[0] );

		$otherAllele->{$rsID} = $rsID_2_bpValues->{$rsID}[0]
		  if ( $rsID_2_bpValues->{$rsID}[1] eq $putativeAllele->{$rsID} );
		$otherAllele->{$rsID} = $rsID_2_bpValues->{$rsID}[1]
		  if ( $rsID_2_bpValues->{$rsID}[0] eq $putativeAllele->{$rsID} );
	}
	return $otherAllele;
}

sub compare_allele_2_possibleHaplotypes {
	my ( $self, $allele, $haplotidesArray ) = @_;

	my ( $haplotypeDatHash, $good, @possibleHaplotypes, $alleleString );
	@possibleHaplotypes = ( $self->possibleHaplotype2string($allele) );
	$alleleString       = $self->possibleHaplotype2string($allele);
	foreach my $haplotype_name (@$haplotidesArray) {
		$haplotypeDatHash = $self->getHaplotype($haplotype_name);
		$good             = $self->possibleHaplotype2string($haplotypeDatHash);
		next if ( $good eq $alleleString );
		push( @possibleHaplotypes, $good )
		  if (
			$self->_Haplotype_matches2_alleleHash( $haplotypeDatHash, $allele )
			&& ( !"@possibleHaplotypes" =~ m/$good/ ) );
	}
	return \@possibleHaplotypes;
}

sub possibleHaplotype2string {
	my ( $self, $haplotypeDataHash ) = @_;
	my $string = "";
	my $id2rs  = $self->{rsIDs};

	foreach my $rsID (@$id2rs) {
		if ( defined $haplotypeDataHash->{$rsID} ) {
			$string .= $haplotypeDataHash->{$rsID};
		}
		else {
			$string .= '-';
		}
	}
	return $string;
}

sub printGenotypeHash {
	my ( $self, $genotypeHash ) = @_;
	my $id2rs = $self->{rsIDs};
	my ( $string1, $string2 );
	$string1 = $string2 = '';

	foreach (@$id2rs) {
		if ( defined $genotypeHash->{$_}[0] ) {
			$string1 .= $genotypeHash->{$_}[0];
			$string2 .= $genotypeHash->{$_}[1];
		}
		else {
			$string1 .= "$genotypeHash->{$_}[0]-";
			$string2 .= "$genotypeHash->{$_}[1]-";
		}
	}
	print "\tstate1 $string1\n\tstate2 $string2\n";
	return 1;
}

## here we need a SNP_cluster object!
## we return an hash with the structure person => @haplotypeSeqences

sub getPossibleHaplotypes {
	my ( $self, $SNP_cluster ) = @_;
	die "we did not get a SNP_cluster object!\n"
	  unless ( ref($SNP_cluster) eq "SNP_cluster" );

	my ( @personArray, $return, $genotypeHash );
	@personArray = $SNP_cluster->get_Person_array();
	foreach my $person (@personArray) {
		$genotypeHash =
		  $SNP_cluster->get_rsHash_of_NuclPosArrays_4_Person($person);
		print "we get a genotype hash for person $person:\n";
		$self->printGenotypeHash($genotypeHash);
		print "and compare it to the haplotypeList:\n", $self->print();
		my $possibleHaplotypes =
		  $self->_getPossibleMatches_4_personHaplotypeHash(
			$SNP_cluster->get_rsHash_of_NuclPosArrays_4_Person($person) );
		$return->{$person} = $possibleHaplotypes;
	}
	return $return;
}

sub print {
	my ( $self, $fileHandle ) = @_;
	my ( @haplotypeNames, $haplotype, $rsIDs );
	$rsIDs = $self->{rsIDs};

	if ( defined $fileHandle ) {
		print {$fileHandle}
		  "start $self->{start} end $self->{end}\npossible HaploTypes:\n";
		print {$fileHandle} "rsIDs: ", join( ";", @$rsIDs ), "\n";
		@haplotypeNames = $self->Haplotype_names();
		foreach my $haplotypeName (@haplotypeNames) {
			print {$fileHandle} "$haplotypeName\t",
			  $self->possibleHaplotype2string(
				$self->getHaplotype($haplotypeName) ), "\n";
		}
	}
	else {
		print "start $self->{start} end $self->{end}\npossible HaploTypes:\n";
		print "rsIDs: ", join( ";", @$rsIDs ), "\n";
		@haplotypeNames = $self->Haplotype_names();
		foreach my $haplotypeName (@haplotypeNames) {
			print "$haplotypeName\t", $self->possibleHaplotype2string(
				$self->getHaplotype($haplotypeName) ), "\n";
		}
	}

}

sub printPossibleHaplotypes {
	my ( $self, $possibleHaplotypes, $filename ) = @_;
	my ( $secondAlleles, $personInfo );
	if ( defined $filename ) {
		unless ( -f $filename ) {
			open( OUT, ">$filename" )
			  or die
			  "printPossibleHaplotypes could not create file $filename\n$!\n";
		}
		else {
			open( OUT, ">>$filename" )
			  or die
			  "printPossibleHaplotypes could not create file $filename\n$!\n";
		}
		$self->print(*OUT);
		print OUT $self->possibleHaplotypes2String($possibleHaplotypes), "\n";
		close(OUT);
		print "possible haplotypes written to $filename\n";
	}

	else {
		$self->print();
		print $self->possibleHaplotypes2String($possibleHaplotypes), "\n";
	}
}

sub getTableString_4_haploTypeList {
	my ( $self, $possibleHaplotypes, $personArray ) = @_;
	my ( $personInfo, @temp, $temp, @string, $alreadyUsed, @return );
	## we have to check for symmetry
	## And report all possible genotypes by another method
	## in addition - remove the not genotyped ones
	#	#ID		nnnXnnnnnnnnnnnnnnXnnnnXnnnn
	#	1	AGTGCACATGTTGAGTACTTCTCCCCAC		$firstAllele
	#	2	A--C----T--T--G---G--T-T----		@$temp
	#	3	AATGCACATGTTGAGTGCGCCTTTCCGT
	#	4	A--C----T--T--G---T--T-C----
	#		AGCGCACATGTTGAGTGCGCCTTTCCGT
	#		A--C----T--T--G---T--T-C----
	#		AGTGCACATGTTGAGTGCGCATTTCTGT
	#		A--C----T--T--G---T--T-C----
	#		AGTGCACATGTTGAGTGCGCCTTTCCGT
	#		A--C----T--T--G---T--T-C----
	#	4	AGCCTACGTGCTTGGCACTTCTCCCCAC
	#	3	A--G----T--T--G---G--T-T----
	#	2	AGCCCACGTGCTTGGTGCGCCTTTCTGT
	#	1	A--G----T--T--G---T--T-C----
	## I do not think, we can decide, whick genotype to select, as all reported probabilities are valid!
	## I have to come up with a probability to correlate the datasets afterwards with the uncertanty in haplotypes!

	my $infoArray =
	  $self->getPrintableHaplotypeConfiguration( $possibleHaplotypes,
		$personArray );

	foreach my $personReport (@$infoArray) {
		@string = ();
		foreach my $fullString ( keys %$personReport ) {
			$temp = $personReport->{$fullString};
			@temp = ( sort (@$temp[0], @$temp[1]) );
			next
			  if ( defined $alreadyUsed->{ $temp[0] }
				&& $alreadyUsed->{ $temp[0] } eq $temp[1] );
			push( @string, "$temp[0]/$temp[1]" );
		}
		push( @return, join( ";", @string ) );
	}
	return join( "\t", @return );
}

sub getPrintableHaplotypeConfiguration {
	my ( $self, $possibleHaplotypes, $personArray ) = @_;
	my ( $personInfo, @return, @firstAleles, $temp, @string );
	return $self->{PrintableHaplotypeConfiguration}
	  if ( defined $self->{PrintableHaplotypeConfiguration} );
	die
"getPrintableHaplotypeConfiguration needs to know which haplotypes to evaluate!\n"
	  unless ( defined $possibleHaplotypes && defined $personArray );
	foreach my $person (@$personArray) {
		$personInfo  = $possibleHaplotypes->{$person};
		@firstAleles = ( keys %$personInfo );

#warn "we have a serious problem person $person has no unique genotype (@firstAleles)"
#	if ( @firstAleles > 1 );
		my $return = {};
		push( @return, $return );
		foreach my $first (@firstAleles) {
			$temp = $personInfo->{$first};
			die
"that is not possible - we got more that one search haplotype ( @$temp )\n"
			  if ( @$temp > 1 );
			$return->{$first} =
			  [ $self->_restrict_haplotype_2_genotypedSNPs( $first, @$temp[0] )
			  ];
		}
	}
	$self->{PrintableHaplotypeConfiguration} = \@return;
	return \@return;
}

sub _restrict_haplotype_2_genotypedSNPs {
	my ( $self, $fullHaplotypeString, $genotyped_haplotypeString ) = @_;
	my ( @full, @part, $full, $part, @rsIDs );
	@full = split( "", $fullHaplotypeString );
	@part = split( "", $genotyped_haplotypeString );
	die
"we found a serious problem! ( $self , _restrict_haplotype_2_genotypedSNPs)\n"
	  if ( @full != @part );
	$full = $part = "";
	@rsIDs = $self->RS_IDs();
	
	for ( my $i = @full -1 ; $i > -1 ; $i-- ) {
		unless ( $part[$i] eq "-" ) {
			$full .= $full[$i];
			$part .= $part[$i];
		}
		else{
			print "no valid information for rsID ", splice (@rsIDs,$i-1,1 ), 
			" => rsID removed (_restrict_haplotype_2_genotypedSNPs)\n";
		}
	}
	return $full, $part, \@rsIDs;
}

sub possibleHaplotypes2String {
	my ( $self, $possibleHaplotypes ) = @_;
	my ( $string, $personInfo, $secondAlleles, $hash );
	$string = '';
	foreach my $person ( keys %$possibleHaplotypes ) {
		$personInfo = $possibleHaplotypes->{$person};
		$string .= "person $person\n";
		print "first allele\tother possible alleles\n";
		foreach my $haplo ( keys %$personInfo ) {
			$string .= "\t$haplo\t";
			$secondAlleles = $personInfo->{$haplo};
			$string .= join( "\t", @$secondAlleles ) . "\n";

		}
	}
	return $string;
}
1;
