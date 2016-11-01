package oligo2dnaDB;

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

use stefans_libs::database::variable_table;
use stefans_libs::database::genomeDB::gbFilesTable;

use base ('variable_table');
use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::database::nucleotide_array::oligo2dnaDB

=head1 DESCRIPTION

A database interface to store the location of a oligo on a genome.
Normally, one table is created for one array type. 
If you want to store other oligo information in this database you have to take care.
The sequence information for the oligos is not stored in this database. 
The sequence information is stored using the database::oligosDB libraray.
This is mainly due to the fact, that you can match the oligos against multiple genomes. 
Storing the sequences in this database would store the information multiple times. 

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless (  ref($dbh) eq "DBI::db" );

	my $self;

	$self = {
		dbh          => $dbh,
		debug        => $debug,
		'select_all' => "",
		'select_all_inRange' =>
"select oligo_name, gbFile_id, start, sameOrientation, OligoHitCount from database where gbFile_id IN ( LIST ) order by gbFile_id, start",

	};

	bless( $self, $class ) if ( $class eq "oligo2dnaDB" );
	$self->init_tableStructure();
	return $self;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}   = [];
	$hash->{'UNIQUES'}   = [ [ 'start', 'oligo_id', 'gbFile_id' ] ];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'oligo_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
			  'a link to the oligoDB table - we do no checks in this class!',
			'data_handler' => 'oligoDB',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the start of this oligo on the gbFile in bp',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'length',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the oligo length',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chromosome_name',
			'type'        => 'VARCHAR (2)',
			'NULL'        => '0',
			'description' => 'the chromosome name',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chr_start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the start in bp on the chromosome',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'sameOrientation',
			'type'        => 'BOOLEAN',
			'NULL'        => '0',
			'description' => 'the orientation relative to the gbFile',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'gbFile_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
			  'a link to the gbFiles table - we do no checks in this class!',
			'data_handler' => 'gbFileTable',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'OligoHitCount',
			'type' => 'TINYINT',
			'NULL' => '1',
			'description' =>
			  'how many times does this oligo match to the genome',
			'needed' => ''
		}
	);
	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'oligo_id', 'start', 'gbFile_id' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'data_handler'}->{'gbFileTable'} =
	  gbFilesTable->new( $self->{dbh}, $self->{debug} );

	$self->{'data_handler'}->{'oligoDB'} = undef;
	## oligoDB->new( $self->{dbh}, $self->{debug} );

	#$self->{_propagateTableName_to} = [ $self->{'data_handler'}->{'oligoDB'} ];
	return $dataset;
}

sub Add_2_result_ROIs{
	my ( $self, @data) = @_;
	return $self->{'data_handler'}->{'gbFileTable'}->Add_2_result_ROIs ( @data );
}

sub set_gbFilesTable_name {
	my ( $self, $name ) = @_;
	return undef unless ( defined $name );
	return $self->{'data_handler'}->{'gbFileTable'}->TableName($name);
}

sub my_check_dataset {
	my ( $self, $dataset ) = @_;
	## OK - we have a problem here....
	## we need to know the table base string for the gbFiles table
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . ":check_dataset -> we need the tableBase string for the gbFilesTable ('gbFiles_base_string')\n"
	  unless ( defined $dataset->{'gbFiles_base_string'} );
	$self->{'error'} .=
	  ref($self)
	  . ":check_dataset -> we need a dataset, that is created during a nucleotides_array::_match_to_genome call ('data')\n"
	  unless ( defined $dataset->{'data'} );

	return 1 unless ( $self->{'error'} =~ m/\w/ );
	root::print_hashEntries( $dataset, 4, ref($self) . ":we have errors\n" );
	return 0;
}

sub this_AddDataset {
	my ( $self, $dataset ) = @_;
	## the dataset looks like that:
	##{ <oligoID> => [ {
	##   'gbFile_version' => <the acc as stored in the gbFiles table in the acc column>,
	##   'gbFile_id' => <the ID of the gbFile as described in the gbFile Tables and the chromosomes tables>
	##   'start_on_gbFile' => <the start on this gbFile>,
	##   'chromosomalOrientation' => <a boolean value if sense (1) or antisense (0) to this file>
	##  } ]
	## }
	die $self->{'error'} unless ( $self->my_check_dataset($dataset) );
	$self->{'data_handler'}->{'gbFileTable'}
	  ->TableName( $dataset->{'gbFiles_base_string'} );
	my ( $amount, $values, $dataset_2 );

	$self->create() unless ( $self->tableExists( $self->TableName() ) );
	$self->_create_insert_statement();
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	
	foreach my $oligoName ( keys %{ $dataset->{data} } ) {

		$amount = scalar( @{ $dataset->{data}->{$oligoName} } );
		foreach $values ( @{ $dataset->{data}->{$oligoName} } ) {
			$values->{'OligoHitCount'} = $amount;
			$values->{'oligo'}->{'oligo_name'} = $oligoName;
			print "Lets see - do we want to insert $values".root::get_hashEntries_as_string ($values, 3, " ");
			unless ( $sth->execute( @{ $self->_get_search_array($values) } ) ) {
			##unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
		Carp::confess(
			ref($self),
			":AddConfiguration -> we got a database error for query '",
			$self->_getSearchString(
				'insert', @{ $self->_get_search_array($dataset) }
			),
			";'\n",
			root::get_hashEntries_as_string(
				$dataset, 4,
				"the dataset we tried to insert into the table structure:"
			  )
			  . "And here are the database errors:\n"
			  . $self->{dbh}->errstr()
		);
	}
			print "FINALLY! ", ref($self) 
			  . ": we add a oligo value!::"
			  . root::get_hashEntries_as_string( $values, 2,
				"the values to add:" );
		}
	}
	return 1;
}

=head2 get_oligoPositions_in_region

=head3 atributes 

  [0]:  a array of gbFileIDs
  [1]: the startting position on the first gbFile
  [2]: the end position on the last gbFile 
  
=head2 return value

A hash of the structure 
{ 
	<gbFile_id> => [ 
	[$oligo_name, $start_onFile, $sameOrientation, $OligoHitCount] ,
	...
	]
}

=cut

sub _getResults_type {
	my ( $self, $resultsType ) = @_;
	if ( $resultsType eq "SignalMap" ) {
		return {
			'search_columns' => [
				'chromosome',         'chromosomesTable.chr_start',
				'oligoDB.oligo_name', 'oligoDB.sequence',
				'oligo2dnaDB.start'
			]
		};
	}
	if ( $resultsType eq "match_2_gbFile" ) {
		return {
			'search_columns' => [
				'gbFilesTable.id',  'oligoDB.oligo_name',
				'oligoDB.sequence', 'oligo2dnaDB.start'
			  ]

		};
	}
	Carp::confess(
		ref($self)
		  . ":_getResults_type -> the results type $resultsType has not been defined!\n"
	);
}

sub Add_oligo_array_values_Table {
	my ( $self, $table_name , $notUsed, $sample_lable ) = @_;
	unless ( ref( $self->{'data_handler'}->{'oligoDB'} ) eq "oligoDB" ) {
		Carp::confess(
			ref($self)
			  . "::Add_oligo_array_values_Table -> we have no data_handler (self->{'data_handler'} -> {'oligoDB'})!"
		);
	}
	return $self->{'data_handler'}->{'oligoDB'}
	  ->Add_oligo_array_values_Table($table_name, $notUsed, $sample_lable);
}

sub Sample_Lables{
	my ( $self) = @_;
	return $self->{'data_handler'}->{'oligoDB'}->Sample_Lables();
}

sub AsInterface{
	my ( $self ) = @_;
	## I need to check, whether we have some data in 'us'
	my $data = $self->get_data_table_4_search({
 	'search_columns' => [ref($self).'.id'],
 	'limit' => "limit 1"
 	})->get_line_asHash(0);
 	unless ( defined $data){
 		return $self->{'data_handler'}->{'oligoDB'}
 	}
 	return $self;
}

sub get_gbFeature_for_id_pair {
	my ( $self, $id1, $id2 ) = @_;
	my ( $gbFeature, $rv, $start, $end );
	$rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				'oligo_name',                  'oligo2dnaDB.start',
				'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start',
				'oligo2dnaDB.gbFile_id'
			],
			'where' => [ [ 'oligo2dnaDB.id', '=', 'my_value' ] ]
		},
		[ $id1, $id2 ]
	);
	if ( @$rv != 2){
	warn ref($self)."::get_gbFeature_for_id_pair ( $id1, $id2 ) -> we did not get the expected two datasets for query \n'$self->{'complex_search'};'\n"
	;
	return 0, 0;
	}
	$gbFeature =
	  gbFeature->new( 'misc_region', @{@$rv[0]}[1]."..".@{@$rv[1]}[1] );
	$gbFeature->AddInfo( 'note',
		"region between oligo @{@$rv[0]}[0] and @{@$rv[1]}[0] on chromosome @{@$rv[1]}[2] "
		  . (@{ @$rv[0] }[1] + @{ @$rv[0] }[3]) . '..'
		  . (@{ @$rv[1] }[1] + @{ @$rv[1] }[3])
		  . "; gbFile_id = @{@$rv[0]}[4]" );
	return $gbFeature, @{@$rv[0]}[4];
}

sub remove_all_oligo_array_values_Tables {
	my ($self) = @_;
	unless ( ref( $self->{' data_handler '}->{' oligoDB '} ) eq "oligoDB" ) {
		Carp::confess(
			ref($self)
			  . "::Add_oligo_array_values_Table -> we have no data_handler (self->{'
			  data_handler '} -> {' oligoDB '})!"
		);
	}
	return $self->{' data_handler '}->{
		' oligoDB
			  '
	  }->remove_all_oligo_array_values_Tables();
}

sub get_oligos {
	my ( $self, $dataset, $resultsType ) = @_;

	$self->{' error '} = '';
	my $query_hash = $self->_getResults_type($resultsType);
	my $return;

	if (   defined $dataset->{' chromosome '}
		&& defined $dataset->{' start '}
		&& defined $dataset->{' end '} )
	{
		$query_hash->{' where '} = [
			[
				[
					' oligo2dnaDB . chr_start ', ' + ', ' oligo2dnaDB . length '
				],
				' >=
			  ',
				' my value '
			],
			[ ' oligo2dnaDB . chr_start ',       ' <= ', ' my value ' ],
			[ ' oligo2dnaDB . chromosome_name ', ' = ',  ' my value ' ]
		];
		return $self->getArray_of_Array_for_search(
			$query_hash,         $dataset->{' start '},
			$dataset->{' end '}, $dataset->{' chromosome '}
		);

	}
	elsif ( defined $dataset->{' chromosome '} ) {
		$query_hash->{' where '} =
		  [ [ ' oligo2dnaDB . chromosome_name ', ' = ', ' my value ' ] ];
		return $self->getArray_of_Array_for_search( $query_hash,
			$dataset->{' chromosome '} );
	}
	elsif (defined $dataset->{' gbFile_id '}
		&& defined $dataset->{' start '}
		&& defined $dataset->{' end '} )
	{
		$query_hash->{' where '} = [
			[ ' oligo2dnaDB . gbFile_id ', ' = ',  ' my value ' ],
			[ ' oligo2dnaDB . start ',     ' >= ', ' my value ' ],
			[ ' oligo2dnaDB . start ',     ' < ',  ' my value ' ],
		];
		return $self->getArray_of_Array_for_search(
			$query_hash,
			$dataset->{' gbFile_id '},
			defined $dataset->{' start '},
			defined $dataset->{' end '}
		);
	}
	elsif ( defined $dataset->{' gbFile_id '} ) {
		$query_hash->{' where '} =
		  [ [ ' oligo2dnaDB . gbFile_id ', ' = ', ' my value ' ] ];
		return $self->getArray_of_Array_for_search( $query_hash,
			$dataset->{' gbFile_id '} );
	}
	elsif ( defined $dataset->{' gbFeature_id '} ) {
		$query_hash->{' where '} = [
			[ ' oligo2dnaDB . start ',  ' > ', ' gbFeaturesTable . start ' ],
			[ ' oligo2dnaDB . start ',  ' < ', ' gbFeaturesTable . end ' ],
			[ ' gbFeaturesTable . id ', ' = ', ' my value ' ]
		];
		return $self->getArray_of_Array_for_search( $query_hash,
			$dataset->{' gbFeature_id '} );
	}
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$dataset, 3, ":get_oligos -> we could not use your query hash:"
		  )
	);
}

=head2 GetOligoLocationArray

=head3 atributes

[0]: the design string as accepted by L<::databases::designDB/"SelectId_ByArrayDesignString">

[1]: the filename MySQL entry name as returned by L<::root/"getPureSequenceName">

=head3 return values

The reference to a array of hashes with the stucture [ { Oligo_ID => NimbleGene oligoID, Oligo_start => start position in basepair on the sequence file,
Oligo_end => end position in basepair on the sequence file, FileID => the internal file id of the genbank formated chromosomal region, Sequence => the oligo sequence } ]

=cut

sub GetOligoLocationArray {
	my ( $self, $design, $filename ) = @_;
	my ( $sth, $rv, $fileID, $designID );
	die ref($self)
	  . ":GetOligoLocationArray -> this function needs recoding!!\n";
	return $self->{oligoData}->{"$design$filename"}
	  if ( defined $self->{oligoData}->{"$design$filename"} );

	#    print "GetOligoLocationArray $design, $filename \n";
	$designID = $self->{designDB}->SelectId_ByArrayDesignString($design);

	if ( defined $filename ) {
		$fileID = $self->{fileDB}->SelectMatchingFileID( $designID, $filename );
		$rv =
" Select Oligo_ID, Oligo_start, Oligo_end, FileID, Sequence, OligoHitCount 
          from Oligo2DNA 
          where DesignString = \"$designID\" && FileID = $fileID 
          order by FileID, Oligo_start";
	}
	else {
		$rv =
" Select Oligo_ID, Oligo_start, Oligo_end, FileID, Sequence , OligoHitCount
        from Oligo2DNA 
        where DesignString = \"$designID\" 
        order by FileID, Oligo_start";
	}

	#print "filename = $filename\nGetOligoLocationArray $rv;\n";
	$sth = $self->{dbh}->prepare($rv);
	$sth->execute();

	#    return $sth->fetchall_hashref(' ID ');
	$self->{oligoData}->{"$design$filename"} = $sth->fetchall_arrayref();
	return $self->{oligoData}->{"$design$filename"};

}

sub writeTileMap_input_data {
	my ( $self, $chipID, $outFile ) = @_;
	my ( $data, $line );
	$data = $self->GetOligoLocationArray($chipID);

	#	open (OUT, ">$oufFile") or die "Konnte File $outFile nicht anlegen!\n";

	#	for (my $i = 0; $i < @$data; $i++) {
	#		$line = @$data[$i];
	#		print OUT "@$line[0]\t@$line[
}

sub IdentifyMultiHitOligos {
	my ( $self, $design ) = @_;
	my ( $oligoData, $oligoCountHash, $histogram, $sth );
	$oligoData = $self->GetOligoLocationArray($design);

	foreach my $olgioArray (@$oligoData) {
		$oligoCountHash->{ @$olgioArray[0] } = 0
		  unless ( defined $oligoCountHash->{ @$olgioArray[0] } );
		$oligoCountHash->{ @$olgioArray[0] }++;
	}
	$histogram = histogram->new();
	$histogram->AddDataArray($oligoCountHash);

#    print "Histogram in /Mass/ArrayData/Evaluation/oligoOcurrance_simple.csv speichern\n";
	$histogram->writeHistogram("oligoOcurrance_simple.csv");

	$sth =
	  $self->{dbh}
	  ->prepare("Update Oligo2DNA Set OligoHitCount = ? where Oligo_ID = ? ")
	  or die $self->{dbh}->errstr();
	while ( my ( $oligoID, $oligoCount ) = each %$oligoCountHash ) {
		$sth->execute( $oligoCount, "$oligoID" ) or die $sth->errstr();
	}

	#    print "Fertig!\n";
}

=head2 DataExists

=head3 atributes

[0]: the design string as accepted by L<::databases::designDB/"SelectId_ByArrayDesignString">

[1]: the filename MySQL entry name as returned by L<::root/"getPureSequenceName">

=head3 return value

true if the table Oligo2DNA has at least 100 entries for this design and this chromosomal region, otherwise false

=cut

sub DataExists {
	my ( $self, $design, $filename ) = @_;
	my ( $rv, $sth, $designID, $fileID );

	$designID = $self->{designDB}->SelectId_ByArrayDesignString($design);

	if ( defined $filename ) {
		$fileID = $self->{fileDB}->SelectFiles_ByDesignId($designID);
		$rv =
" Select * from Oligo2DNA where DesignString = \"$designID\" && FileID = $fileID->{$filename}->{ID} limit 100"
		  if ( defined $filename );
	}
	else {
		$rv =
" Select * from Oligo2DNA where DesignString = \"$designID\" limit 100";
	}
	$sth = $self->{dbh}->prepare($rv) or die $self->{dbh}->errstr();
	$rv  = $sth->execute()            or die $sth->errstr();
	return $rv == 100;
}

=head2 GetInfoID

See L<databases::hybInfoDB/"SelectID_ByHybInfo">

=cut

sub GetInfoID {
	my ( $self, $NimbleGeneID, $antibody ) = @_;

	## Possible search variants = NimbleID + Used Antibody or NimbleID + Marker (Cy3 || Cy5)
#    print "Array_Hyb searches for self->{hybInfoDB}->SelectID_ByHybInfo($NimbleGeneID, $antibody)\n";
	return $self->{hybInfoDB}->SelectID_ByHybInfo( $NimbleGeneID, $antibody );
}

1;
