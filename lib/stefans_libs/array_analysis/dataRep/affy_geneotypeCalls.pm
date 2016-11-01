package affy_geneotypeCalls;
 
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
 use stefans_libs::tableHandling;
 use stefans_libs::array_analysis::dataRep::affy_SNP_annot;
 use stefans_libs::array_analysis::dataRep::affy_geneotypeCalls::SNP_cluster;
 use stefans_libs::root;
 
 sub new {
 
 	my ( $class, $callFile, $infoFile, $debug ) = @_;
 
 	my ( $self, @matrix, $affiID );
 
 	$self = {
 		header_array => undef,
 		tableHandling => tableHandling->new(),
 		debug => $debug,
 		affyID        => $affiID,
 		table         => \@matrix
 	};
 
 	bless $self, $class if ( $class eq "affy_geneotypeCalls" );
 
 	$self->AddFile($callFile)     if ( defined $callFile );
 	$self->AddInfoFile($infoFile) if ( defined $infoFile );
 	return $self;
 
 }
 
 sub AddFile {
 	my ( $self, $file ) = @_;
 	open( IN, "<$file" )
 	  or die "could not open file $file in affy_geneotypeCalls->addFile\n$!\n";
 	my ( $table, $line );
 	$table = $self->{table};
 	$line  = 0;
 	
 	while (<IN>) {
 		next if ( $_ =~ m/^#/ );
 		chomp $_;
 		unless ( defined $self->{header} ) {
 			my $header = 0;
 			$self->{header} = my $temp;
 			my @header = split( "\t", $_ );
 			foreach (@header) {
 				$self->{header}->{$_} = $header++;
 			}
 			$self->{header_array} = \@header;
 			next;
 		}
 		my @line = split( "\t", $_ );
 		push( @$table, \@line );
 		$self->{affyID}->{ $line[0] } = $line++;
 	}
 	close(IN);
 	return 1;
 }
 
 sub AddInfoFile {
 	my ( $self, $infoFile ) = @_;
 	$self->{infoFile} = affy_SNP_annot->new($infoFile);
 	return 1;
 }
 
 sub getRSids_4_geneName {
 	my ( $self, $geneName ) = @_;
 	die "no SNP infos available\n" unless ( defined $self->{infoFile} );
 	return $self->{infoFile}->getRSids_4_geneName($geneName);
 }
 
 sub getSampleGeneotypeTable_4_rsIDs{
 	my ( $self, $rsList) = @_;
 
 	my ( $rs_dataset_list, @return, $string, $header_written);
 	
 	
 	$rs_dataset_list = $self->{infoFile}->get_rs_datasets_list_4_rsList( $rsList );
 	#print "\tpossibly the rsList got restricted? (@$rsList)\n\ns";
 	$self->addGenotypeMatrix_2_rs_list($rs_dataset_list);
 	#push (@return, @$rs_dataset_list[0]->getPersonHeader_withRS_column() );
 	foreach ( @$rs_dataset_list ){
 		#print "we hopeully get a rs_dataset: $_\n";
 		#root::print_hashEntries( $_, 3, "data set:");
 		$string = $_->getGenotypeCalls_withRS_column();
 		#print "??? -> $string";
 		if ( defined $string && ! defined $header_written){
 			$header_written = 1;
 			$return[0] = $_->getPersonHeader_withRS_column()."\n" ;
 		}
 		push (@return, $string );
 	}
 	return \@return;
 }
 
 sub getSampleGeneotypeTable_4_geneName{
 	my ( $self, $geneName, $upstream, $downstream ) = @_;
 	
 	my ( $rs_dataset_list, $string, $header_written, @return );
 	$rs_dataset_list = $self->{infoFile}->get_rs_datasets_list_4_geneName( $geneName, $upstream, $downstream );
 	$self->addGenotypeMatrix_2_rs_list($rs_dataset_list);
 	
  	foreach ( @$rs_dataset_list ){
 		#print "we hopeully get a rs_dataset: $_\n";
 		#root::print_hashEntries( $_, 3, "data set:");
 		$string = $_->getGenotypeCalls_withRS_column();
 		#print "??? -> $string";
 		if ( defined $string && ! defined $header_written){
 			$header_written = 1;
 			$return[0] = $_->getPersonHeader_withRS_column()."\n" ;
 		}
 		push (@return, $string );
 	}
 	return \@return;
 }
 
 sub getSampleGeneotypeTable_4_chromosomePosition{
 	my ( $self, $chr_id, $start, $end ) = @_;
 
 	my ( $rs_dataset_list, @return, $string, $header_written);
 	
 	
 	$rs_dataset_list = $self->{infoFile}->get_rs_datasets_list_4_ChromosomalPosition( $chr_id, $start, $end );
 	#print "\tpossibly the rsList got restricted? (@$rsList)\n\ns";
 	$self->addGenotypeMatrix_2_rs_list($rs_dataset_list);
 	#push (@return, @$rs_dataset_list[0]->getPersonHeader_withRS_column() );
 	foreach ( @$rs_dataset_list ){
 		#print "we hopeully get a rs_dataset: $_\n";
 		#root::print_hashEntries( $_, 3, "data set:");
 		$string = $_->getGenotypeCalls_withRS_column();
 		#print "??? -> $string";
 		if ( defined $string && ! defined $header_written){
 			$header_written = 1;
 			$return[0] = $_->getPersonHeader_withRS_column()."\n" ;
 		}
 		push (@return, $string );
 	}
 	return \@return;
 }
 
 
 sub printPhaseInputFileList_4_rsIDs {
 	my ( $self, $rsList, $fileBase ) = @_;
 	my @rsList = @$rsList;
 	if ( ref( $rsList[0] ) eq "ARRAY" ) {
 		my $temp = $rsList[0];
 		@rsList = @$temp;
 	}
 	my ( $locationList, $lastChr, @list );
 	## possibly the rsIDs are separated over several chromosomes!
 	$locationList =
 	  $self->{infoFile}->getChromosome_PositionArray_4_rsList( \@rsList );
 	$lastChr = @$locationList[0]->{'chr'};
 
 	for ( my $i = 0 ; $i < @$locationList ; $i++ ) {
 		if ( @$locationList[$i]->{'chr'} eq $lastChr ) {
 			push( @list, $rsList[$i] );
 		}
 		else {
 			open( OUT, "$fileBase-Chr$lastChr.txt" )
 			  or die "could not create $fileBase-Chr$lastChr.txt\n$!\n";
 			print OUT $self->getPhaseInput_4_rsList( \@list );
 			close(OUT);
 			@list    = ();
 			$lastChr = @$locationList[$i]->{'chr'};
 		}
 	}
 	open( OUT, ">$fileBase.txt" ) or die "could not create $fileBase.txt\n$!\n";
 	print OUT $self->getPhaseInput_4_rsList( \@list );
 	close(OUT);
 	return 1;
 
 }
 
 sub transposeMatrix {
 	my ( $self, $matrix ) = @_;
 	my ( @new, $temp );
 	foreach my $lineArray (@$matrix) {
 		for ( my $i = 0 ; $i < @$lineArray ; $i++ ) {
 			unless ( defined $new[$i] ) {
 				my @temp;
 				$new[$i] = \@temp;
 			}
 			$temp = $new[$i];
 			push( @$temp, @$lineArray[$i] );
 		}
 	}
 	return \@new;
 }
 
 sub addGenotypeMatrix_2_rs_list {
 	my ( $self, $rs_list ) = @_;
 	my ($hash, $array, @persons);
 
 	#push ( @return, $self->{header_array});
 	my $persons = $self->{header_array};
 	@persons = @$persons;
 	shift ( @persons );
 	
 	foreach (@$rs_list) {
 		if ( $_ eq "not in the affymetrix SNP information file!"){
 			warn "me have a missing dataset!\n";
 			next;
 		}
 		unless ( $_->isOnArray() ){
 			warn "data set $_ ( rsID =",$_->rsID(),") is not on the array!\n";
 			$hash->{$_->rsID()} = [];
 			next;
 		}
 		$array = $self->{table}->[$self->{affyID}->{$_->AffyID()} ];
 		shift ( @$array);
 		$_->addGeneotypeCalls(\@persons, $array);
 		#push( @return, $self->{table}->[ $self->{affyID}->{$_} ] );
 	}
 	
 	return 1;
 	#return \@return;
 }
 
=head2 getReportHash
 
=head3 atributes
 
 	an array of rsIDs to be selected from the SNP array data set
 
=head3 return value
 
 	a referece to an SNP_cluster
 	 
=cut
 
 sub get_SNP_cluster_4_rsIDs {
 	my ($self, $rsList) = @_;
 
 	die
 	  "affy_genotypeCalls getPhaseInput_4_rsList: we need the rs info first!\n"
 	  unless ( defined $self->{infoFile} );
 	
 	my ( $rs_dataset_list );
 	
 	$self->{arraySorter} = arraySorter->new() unless ( defined $self->{arraySorter});
 	
 	$rs_dataset_list = $self->{infoFile}->get_rs_datasets_list_4_rsList( $rsList );
 	$self->addGenotypeMatrix_2_rs_list($rs_dataset_list);
 
 	return SNP_cluster->new( $rs_dataset_list, $self->{arraySorter} );
 }
 
 sub getPhaseInput_4_rsList{
 	my ( $self, @rsList) = @_;
 	my $snpCluster = $self->get_SNP_cluster_4_rsIDs(@rsList);
 	return $snpCluster -> getAsPhaseInputString();
 }
 
 1;
 
