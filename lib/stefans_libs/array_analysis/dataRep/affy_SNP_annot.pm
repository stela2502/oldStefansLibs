package affy_SNP_annot;

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

use stefans_libs::array_analysis::dataRep::affy_SNP_annot::alleleFreq;
use stefans_libs::array_analysis::dataRep::affy_geneotypeCalls::rs_dataset;

sub new {

	my ( $class, $filename, $debug ) = @_;

	my ( $self, $rsHash, $affyID, $positionHash );

	$self = {
		tableHandling         => tableHandling->new(','),
		debug                 => $debug,
		changeLineSeparatorTo => '","',
		positionHash          => $positionHash,
		header                => undef,
		table                 => [],
		rsID                  => $rsHash,
		affyID                => $affyID,
		allelFreq             => [],
		complement => { 'a' => 'T', 'c' => 'G', 'g' => 'C', 't' => 'A' }
	};

	bless $self, $class if ( $class eq "affy_SNP_annot" );
	$self->AddFile($filename) if ( defined $filename );
	return $self;

}

sub AddToDatabase {
	my ( $self, $database_obj ) = @_;
	Carp::confess(
		ref($self)
		  . ":AddToDatabase ->sorry, but I need a affy_SNP_info database object to add to the database"
	) unless ( ref($database_obj) eq "affy_SNP_info" );
	$database_obj->_create_insert_statement();
	my $sth = $database_obj->_get_SearchHandle( { 'search_name' => 'insert' } );
	my @insertDataset = ();
	for ( my $i = 0 ; $i < @{ $self->{'rsID'} } ; $i++ ) {

		#	 rsID VARCHAR(20) NOT NULL,
		#    major_nucleotide char(1) NOT NULL,
		#    minor_nulceotide char(1) NOT NULL,
		#    CEPH_ma FLOAT NOT NULL,
		#    Han_Chinese_ma FLOAT NOT NULL,
		#    Japanese_ma float NOT NULL,
		#    Yoruba_ma float NOT NULL,

		@insertDataset = (
			@{ $self->{'affyID'} }[$i],
			@{ $self->{'rsID'} }[$i],
			$self->allele_a_4_ID( @{ $self->{'rsID'} }[$i] ),
			$self->allele_b_4_ID( @{ $self->{'rsID'} }[$i] ),
			$self->alleleFrequencies( @{ $self->{'rsID'} }[$i] )->getMajorFreq_4_popID( 'CEPH' ),
			$self->alleleFrequencies( @{ $self->{'rsID'} }[$i] )->getMajorFreq_4_popID( 'Han Chinese' ),
			$self->alleleFrequencies( @{ $self->{'rsID'} }[$i] )->getMajorFreq_4_popID( 'Japanese' ),
			$self->alleleFrequencies( @{ $self->{'rsID'} }[$i] )->getMajorFreq_4_popID( 'Yoruba' )
		);
		$sth->execute(@insertDataset)
		  or Carp::confess(
			ref($self),
			":AddToDatabase -> we got a database error for query '",
			$database_obj->_getSearchString( 'insert', @insertDataset ),
			";'\n"
			  . "And here are the database errors:\n"
			  . $self->{dbh}->errstr()
		  );
	}
}

sub get_rs_datasets_list_4_rsList {
	my ( $self, $list ) = @_;
	my ( @return, $id );
	foreach (@$list) {
		unless ( defined $self->{rsID}->{$_} ) {
			warn "no information for rsNumber $_ ( $self->{rsID}->{$_} )\n";
			next;
		}

		$id = $self->{rsID}->{$_};
		push(
			@return,
			rs_dataset->new(
				{
					rsID   => $_,
					affyID => $self->{table}->[$id]
					  ->[ $self->{header}->{'Probe Set ID'} ],
					major => $self->allele_a_4_ID($id),
					minor => $self->allele_b_4_ID($id),
					'chr' =>
					  $self->{table}[$id][ $self->{header}->{'Chromosome'} ],
					'position' => $self->{table}[$id]
					  [ $self->{header}->{'Physical Position'} ],
					onStrand =>
					  $self->{table}[$id][ $self->{header}->{'Strand'} ]

				}
			)
		);
	}

	return \@return;
}

sub get_rs_datasets_list_4_geneName {
	my ( $self, $geneName, $upstream, $downstream ) = @_;

	$upstream   = 50000 unless ( defined $upstream );
	$downstream = 50000 unless ( defined $downstream );

	die
	  "sorry, but we absolutely need every value for:\n",
"\$geneName = $geneName, \$upstream =$upstream, \$downstream = $downstream\n"
	  unless ( defined $geneName && defined $upstream && defined $downstream );
	my ( $chr, $start, $end );
	unless ( defined $self->{geneHash}->{$geneName} ) {
		warn
"sorry, gene $geneName is not in the dataset ( $self, get_rs_datasets_list_4_geneName)";
		return ["not in the affymetrix SNP information file!"];
	}
	return $self->get_rs_datasets_list_4_ChromosomalPosition(
		$self->{geneHash}->{$geneName}->{'chromosme'},
		$self->{geneHash}->{$geneName}->{start} - $upstream,
		$self->{geneHash}->{$geneName}->{end} + $downstream
	);
}

sub get_rs_datasets_list_4_ChromosomalPosition {
	my ( $self, $chr_id, $start, $end ) = @_;
	die
"sorry, but we absolutely need every value for:\nchr_id = $chr_id\nstart = $start\nend = $end\n"
	  unless ( defined $chr_id && defined $start && defined $end );
	my ( @return, $positions, $id, @remove );
	$positions = $self->{positionHash}->{$chr_id};

	foreach my $location ( sort { $a <=> $b } ( keys %$positions ) ) {
		next unless ( $location >= $start && $location <= $end );
		$id = $positions->{$location};
		push(
			@return,
			rs_dataset->new(
				{
					rsID => $self->{table}->[$id]
					  ->[ $self->{header}->{'dbSNP RS ID'} ],
					affyID => $self->{table}->[$id]
					  ->[ $self->{header}->{'Probe Set ID'} ],
					major => $self->allele_a_4_ID($id),
					minor => $self->allele_b_4_ID($id),
					'chr' =>
					  $self->{table}[$id][ $self->{header}->{'Chromosome'} ],
					'position' => $self->{table}[$id]
					  [ $self->{header}->{'Physical Position'} ],
					onStrand =>
					  $self->{table}[$id][ $self->{header}->{'Strand'} ]

				}
			)
		);
	}
	return \@return;
}

sub getAffyIDarray_4_rsList {
	my ( $self, $list ) = @_;

	my ( @return, @ids, $temp, $i, @remove );
	$temp = $self->{affyID};
	@ids  = ( keys %$temp );
	$i    = 0;
	foreach (@$list) {
		unless ( defined $self->{rsID}->{$_} ) {
			warn "no information for rsNumber $_ ( $self->{rsID}->{$_} )\n";
			push( @remove, $i++ );
			next;
		}
		push( @return,
			$self->{table}->[ $self->{rsID}->{$_} ]
			  ->[ $self->{header}->{'Probe Set ID'} ] );
		$i++;
	}
	if ( defined $remove[0] ) {
		print "\n\n";
		print
" we remove a list of rsValues from the rsValues List, as we got no info for those! Namely:\n";
		for ( my $i = @remove - 1 ; $i >= 0 ; $i-- ) {
			print splice( @$list, $i + 1, 1 ), "\t";
		}
		print "finished\n\n";
	}
	return \@return;
}

sub getSNP_nulc_info_4_rsList {
	my ( $self, @list ) = @_;
	if ( ref( $list[0] ) eq "ARRAY" ) {
		my $temp = $list[0];
		@list = @$temp;
	}
	my (@return);
	foreach (@list) {
		next unless ( defined $self->_getTableID($_) );
		my @temp = ( $self->allele_a_4_ID($_), $self->allele_b_4_ID($_), $_ );
		push( @return, \@temp );
	}
	return \@return;
}

sub getRSids_4_geneName {
	my ( $self, $geneName ) = @_;
	return undef unless ( defined $geneName );

	return $self->{$geneName} if ( defined $self->{$geneName} );

	my ( @geneInfo, $table, @data, $n );
	$n     = 0;
	$table = $self->{table};
	for ( my $i = 0 ; $i < @$table ; $i++ ) {

#print
#"we try to fin the <$geneName> info in the cell 'Associated Gene' at position ",
#		  $self->{header}->{'Associated Gene'}, "\n", "and get '",
#		  @$table[$i]->[ $self->{header}->{'Associated Gene'} ], "'\n";
		@geneInfo =
		  split( " // ",
			@$table[$i]->[ $self->{header}->{'Associated Gene'} ] );

		#print "we search 4 gene $geneName in cell entry $geneInfo[4]\n";
		#		  join( " , ", @geneInfo ), "\n";
		if ( $geneInfo[4] eq $geneName ) {
			push( @data, @$table[$i]->[ $self->{header}->{'dbSNP RS ID'} ] );
			$n++;
		}
	}
	if ( $n == 0 ) {
		warn "we did not find the gene $geneName in the Array lib file\n";

		#my ( @temp, $temp );
		#$temp = $self->{header};
		#@temp = ( keys %$temp );
		#		print "is 'Associated Gene' in the list ( @temp ) ? \n";
	}

	#print "$n rsIDs 4 gene $geneName\n";
	$self->{$geneName} = \@data;
	return $self->{$geneName};
}

sub getChromosome_PositionArray_4_rsList {
	my ( $self, @list ) = @_;
	if ( ref( $list[0] ) eq "ARRAY" ) {
		my $temp = $list[0];
		@list = @$temp;
	}
	my ( @return, $id );
	print
"DEBUG we will return the values for array positions $self->{header}->{'Chromosome'} and $self->{header}->{'Physical Position'}\n";
	foreach (@list) {
		$id = $self->_getTableID($_);
		unless ( defined $id ) {
			warn "we have no table line 4 rsID $_\n";
			next;
		}
		push(
			@return,
			{
				'chr' => $self->{table}[$id][ $self->{header}->{'Chromosome'} ],
				'position' =>
				  $self->{table}[$id][ $self->{header}->{'Physical Position'} ]
			}
		);
	}
	return \@return;
}

sub AddFile {
	my ( $self, $file ) = @_;
	open( IN, "<$file" )
	  or die "affy_SNP_annot::AddFile could not open file $file:\n$!\n";
	my ( $lineCount, $matrix, $geneName );
	$matrix    = $self->{table};
	$lineCount = 0;
	my ( $use, $notUse );
	$use    = 1 == 1;
	$notUse = 1 == 0;
	my $searchHash = {
		"Probe Set ID"                                => $use,
		"Affy SNP ID"                                 => $notUse,
		"dbSNP RS ID"                                 => $use,
		"Chromosome"                                  => $use,
		"Physical Position"                           => $use,
		"Strand"                                      => $use,
		"ChrX pseudo-autosomal region 1"              => $use,
		"Cytoband"                                    => $notUse,
		"Flank"                                       => $notUse,
		"Allele A"                                    => $use,
		"Allele B"                                    => $use,
		"Associated Gene"                             => $use,
		"Genetic Map"                                 => $notUse,
		"Microsatellite"                              => $notUse,
		"Fragment Enzyme Type Length Start Stop"      => $notUse,
		"Allele Frequencies"                          => $use,
		"Heterozygous Allele Frequencies"             => $notUse,
		"Number of individuals/Number of chromosomes" => $notUse,
		"In Hapmap"                                   => $notUse,
		"Strand Versus dbSNP"                         => $use,
		"Copy Number Variation"                       => $notUse,
		"Probe Count"                                 => $notUse,
		"ChrX pseudo-autosomal region 2"              => $notUse,
		"In Final List"                               => $notUse,
		"Minor Allele"                                => $notUse,
		"Minor Allele Frequency"                      => $notUse,
		"% GC"                                        => $notUse
	};

	while (<IN>) {
		next if ( $_ =~ m/^#/ );
		chomp $_;

		#$_ =~ s/ *" *//g;

		unless ( defined $self->{header} ) {
			my $temp;
			$_ =~ s/ *" *//g;
			$self->{header} = $temp;

			$use =
			  $self->{tableHandling}
			  ->identify_columns_of_interest_bySearchHash( $_, $searchHash );
			my @header =
			  $self->{tableHandling}->get_column_entries_4_columns( $_, $use );
			for ( my $i = 0 ; $i < @header ; $i++ ) {
				$self->{header}->{ $header[$i] } = $i;
			}
			print "Maybe the desaster is starting here:\n\t@header\n"
			  if ( $self->{debug} );
			$self->{tableHandling}->{line_separator} =
			  $self->{changeLineSeparatorTo};
			next;
		}
		my @line =
		  $self->{tableHandling}->get_column_entries_4_columns( $_, $use );
		push( @$matrix, \@line );
		foreach my $entry (@line) {
			## remove " !
			$entry = $1 if ( $entry =~ m/ *"? *(.+) *"? */ );
		}

		## create the search hash for the by rsID search
		$self->{rsID}->{ $line[ $self->{header}->{'dbSNP RS ID'} ] } =
		  $lineCount;

		## create the search hash for the by chr region search
		$self->{positionHash}->{ $line[ $self->{header}->{'Chromosome'} ] } =
		  my $chr_temp
		  unless (
			defined $self->{positionHash}
			->{ $line[ $self->{header}->{'Chromosome'} ] } );
		$self->{positionHash}->{ $line[ $self->{header}->{'Chromosome'} ] }
		  ->{ $line[ $self->{header}->{'Physical Position'} ] } = $lineCount;

		## create the search hash for the gene name search...
		$geneName =
		  $self->_extractGeneName(
			$line[ $self->{header}->{"Associated Gene"} ] );
		unless ( defined $self->{geneHash}->{$geneName} ) {
			$self->{geneHash}->{$geneName} = {
				chromosme => $line[ $self->{header}->{'Chromosome'} ],
				start     => $line[ $self->{header}->{'Physical Position'} ],
				end       => $line[ $self->{header}->{'Physical Position'} ]
			};
		}
		$self->{geneHash}->{$geneName}->{start} =
		  $line[ $self->{header}->{'Physical Position'} ]
		  if ( $>{geneHash}->{$geneName}->{start} >
			$line[ $self->{header}->{'Physical Position'} ] );
		$self->{geneHash}->{$geneName}->{end} =
		  $line[ $self->{header}->{'Physical Position'} ]
		  if ( $>{geneHash}->{$geneName}->{end} <
			$line[ $self->{header}->{'Physical Position'} ] );

		## create the search hash for the by affyID search
		$self->{affyID}->{ $line[ $self->{header}->{'Probe Set ID'} ] } =
		  $lineCount;
		$lineCount++;
	}
	close(IN);
	return 1;
}

sub _extractGeneName {
	my ( $self, $string ) = @_;
	return undef unless ( defined $string );
	my @data = split( "//", $string );
	$data[11] =~ s/ //g;
	return $data[11];
}

sub NCBI_ID_4_ID {
	my ( $self, $rsID ) = @_;

	my $id = $self->_getTableID($rsID);

	my $geneInfo = $self->{table}->[$id];
	return "rsID not in dataset" unless ( defined @$geneInfo );

	foreach (
		split( "//", $geneInfo->[ $self->{header}->{'Associated Gene'} ] ) )
	{
		$_ = _removeStringSep( $_, '"' );
		return $_ if ( $_ =~ m/\w\w_\d+/ );
	}
	return "NCBI ID could not be found! ($geneInfo->{'Associated Gene'})";
}

sub _getTableID {
	my ( $self, $rsID ) = @_, my $id;
	$id = $self->{rsID}->{$rsID};
	$id = $self->{affyID}->{$rsID} unless ( defined $id );
	$id = $rsID unless ( defined $id );
	die "no table line ID found for id $rsID\n"
	  unless ( defined $self->{table}->[$id] );

	return $id;
}

sub allele_a_4_ID {
	my ( $self, $rsID ) = @_;
	my $id = $self->_getTableID($rsID);

	print "we get the value ",
	  $self->{table}->[$id]->[ $self->{header}->{'Allele A'} ],
	  " for id $rsID\n";

	return $self->{table}->[$id]->[ $self->{header}->{'Allele A'} ]
	  if ( $self->_sameAsHapmap($rsID) );
	return $self->{complement}
	  ->{ lc( $self->{table}->[$id]->[ $self->{header}->{'Allele A'} ] ) };
}

sub _sameAsHapmap {
	my ( $self, $rsID ) = @_;
	my $id = $self->_getTableID($rsID);
	print "same as Hapmap!  "
	  if ( "+" eq $self->{table}->[$id]->[ $self->{header}->{'Strand'} ] );
	print "complements to hapmap!  "
	  unless ( "+" eq $self->{table}->[$id]->[ $self->{header}->{'Strand'} ] );
	return ( "+" eq $self->{table}->[$id]->[ $self->{header}->{'Strand'} ] );
}

sub allele_b_4_ID {
	my ( $self, $rsID ) = @_;
	my $id = $self->_getTableID($rsID);
	return $self->{table}->[$id]->[ $self->{header}->{'Allele B'} ]
	  if ( $self->_sameAsHapmap($rsID) );

	return $self->{complement}
	  ->{ lc( $self->{table}->[$id]->[ $self->{header}->{'Allele B'} ] ) };

	#return $self->{table}->[$id]->[ $self->{header}->{'Allele B'} ];
}

sub alleleFrequencies {
	my ( $self, $rsID ) = @_;
	my $id = $self->_getTableID($rsID);
	return $self->{allelFreq}[$id] if ( defined $self->{allelFreq}[$id] );
	$self->{allelFreq}[$id] = alleleFreq->new(
		$self->{table}[$id][ $self->{header}->{'Allele Frequencies'} ] );
	return $self->{allelFreq}[$id];
}

sub _removeStringSep {
	my ( $self, $string, $sep ) = @_;
	return $1 if ( $string =~ m/$sep(.+)$sep/ );
	return $string;
}

1;
