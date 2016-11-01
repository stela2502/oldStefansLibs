package oligo2dna_register;

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
use warnings;
use stefans_libs::database::variable_table;
use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use stefans_libs::database::genomeDB;

use stefans_libs::database::system_tables::loggingTable;
use File::HomeDir;
use base ('variable_table');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A table to describe oligo2DNA tables. Mainly to keep the connection to the genome.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class oligo2dna_register.

=cut

sub new {

	my ( $class, $database_name, $debug ) = @_;

	unless ( defined $database_name ) {
		$database_name = 'genomeDB';
		warn "$class:new -> we had no databaseName -> set to $database_name\n";
	}

	my ($self);

	$self = {
		'dbh'           => root::getDBH( 'root',              $database_name ),
		'database_name' => $database_name,
		'debug'         => $debug,
		'tempDir'       => File::HomeDir->my_home() . "/temp",
		'logging'       => loggingTable->new( $database_name, $debug )
	};

	bless $self, $class if ( $class eq "oligo2dna_register" );

	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type{
	return "database_name";
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "oligo2dna_register";
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'foreign_table',
			'type' => 'VARCHAR (40)',
			'NULL' => '0',
			'description' =>
			  'the foreign table - info where to look for the foreign_id',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'foreign_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
'the foreign id - leeding to further info about the oligo2dna table',
			'needed' => ''
		}
	);

	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'genome_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
			  'the genome ID is needed to interprete the oligo hits',
			'data_handler' => 'genomeDB',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the table_baseString of the real oligo2DNA DB',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'UNIQUES'} },
		[ 'foreign_table', 'foreign_id', 'genome_id' ]
	);
	push( @{ $hash->{'INDICES'} }, ['table_baseString'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'foreign_table', 'foreign_id', 'genome_id' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'data_handler'}->{'genomeDB'} =
	  genomeDB->new( $self->{database_name}, $self->{'debug'} );
	$self->{'downstream_data_handler'}->{'oligo2dnaDB'} =
	  oligo2dnaDB->new( $self->{dbh}, $self->{debug} );

	return $dataset;
}

sub get_upstream_handlers {
	my ($self) = @_;
	use stefans_libs::database::nucleotide_array;
	return $self->{'upstream_handler'}
	  if ( defined $self->{'upstream_handler'} );
	$self->{'upstream_handler'}->{'nucleotide_array'} =
	  nucleotide_array->new( $self->{'database_name'}, $self->{'debug'} );

	return $self->{'upstream_handler'};
}


sub get_base_tableString_handler_4_table_row {
	my ( $self, $data_row ) = @_;
	Carp::confess(
		ref($self)
		  . ":get_base_tableString_handler_4_table_row -> we need an hash at function call, not '$data_row'\n"
	) unless ( ref($data_row) eq "HASH" );
	return undef unless ( defined $data_row->{'table_baseString'} );
	## set the table base name for the oligo2dnaDB
	$self->{'downstream_data_handler'}->{'oligo2dnaDB'} =
	  oligo2dnaDB->new( $self->{dbh}, $self->{debug} );

	$self->{'downstream_data_handler'}->{'oligo2dnaDB'}
	  ->TableBaseName( $data_row->{'table_baseString'} );
	## init the oligoDB for the oligo2dnaDB
	$self->{'downstream_data_handler'}->{'oligo2dnaDB'}->{'data_handler'}
	  ->{'oligoDB'} =
	  $self->{'downstream_data_handler'}->{'oligo2dnaDB'}->{''} =
	  $self->Get_upstream_handler_4_tableName( $data_row->{'foreign_table'} )
	  ->Get_OligoDB_for_ID( $data_row->{'foreign_id'} );

	## init the oligoDB for the genome interface
	my $genomeInterface =
	  $self->{'data_handler'}->{'genomeDB'}
	  ->GetDatabaseInterface_for_genomeID( $data_row->{'genome_id'} );
	$genomeInterface =
	  $genomeInterface->{'data_handler'}->{'gbFileTable'}
	  ->makeMaster($genomeInterface);

	$self->{'downstream_data_handler'}->{'oligo2dnaDB'}->{'data_handler'}
	  ->{'gbFileTable'} = $genomeInterface;

#	print ref($self).":get_base_tableString_handler_4_table_row -> we tried to make the gbFeaturesTable a master table - did we succeed?\n".
#		root::get_hashEntries_as_string($genomeInterface,5,"the new genome interface ($genomeInterface):")."\n";
#	die;
#  ->TableBaseName( $genomeInterface->TableBaseName() );

	return $self->{'downstream_data_handler'}->{'oligo2dnaDB'};
}

sub printReport {
	my ($self) = @_;
	return $self->_getLinkageInfo()
	  ->Print( $self->{'downstream_data_handler'} );
}

sub getDescription {
	my ($self) = @_;
	return
"This class is a \\textit{MASTER TABLE} class that stores additional information about oligo2dnaDB tables. 
	This class has to be used as interface to create and recieve oligo2dna data structures.
	\n\n";
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	my $use = 0;
	foreach my $upstream_Handler ( values %{ $self->get_upstream_handlers() } )
	{
		$use = 1
		  if ( $upstream_Handler->TableName() eq $dataset->{'foreign_table'} );
	}
	$self->{'error'} .=
	  ref($self)
	  . ":DO_ADDITIONAL_DATASET_CHECKS -> we can not create a reverse connection to foreign_table $dataset->{'foreign_table'}"
	  unless ($use);
	return 1;
}

sub Get_upstream_handler_4_tableName {
	my ( $self, $tableName ) = @_;
	return -1 unless ( defined $tableName );
	foreach ( values %{ $self->get_upstream_handlers() } ) {
		return $_ if ( $tableName eq $_->TableName() );
	}
	return undef;
}

sub get_Array_Lib_Interface {
	my ( $self, $otherInfo, $genome_hash ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	    ref($self)
	  . ":get_Array_Lib_Interface -> I miss the \$otherInfo->{'id'}\n"
	  . "please tell the maintainer of this lib, that this was an error on the way through the lib (just before that function call!)\n"
	  unless ( defined $otherInfo->{'id'} );
	$self->{'error'} .=
	    ref($self)
	  . ":get_Array_Lib_Interface -> I miss the \$otherInfo->{'describing_table_name'}\n"
	  . "please tell the maintainer of this lib, that the was an error on the way through the lib (just before that function call!)\n"
	  unless ( defined $otherInfo->{'describing_table_name'} );
	## we can stop right here if we have an erorr!
	return undef if ( $self->{'error'} =~ m/\w/ );
	my ( $genomeHandle, $upstream_handler, $oligoDB );

	$upstream_handler =
	  $self->Get_upstream_handler_4_tableName(
		$otherInfo->{'describing_table_name'} );
	$oligoDB = $upstream_handler->Get_OligoDB_for_ID( $otherInfo->{'id'} );
	$self->{'error'} .= $upstream_handler->{'error'};

	unless ( defined $genome_hash->{'id'}
		|| defined $genome_hash->{'organism_tag'} )
	{
		## oops - we have to check whether we have matched this oligoDB to any genome....
		my $table_rows = $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['genome_id'],
				'where'          => [
					[ ref($self) . ".foreign_id",    "=", "my value" ],
					[ ref($self) . ".foreign_table", "=", "my value" ]
				],
				'order_by' => ['genome_id']
			},
			$otherInfo->{'id'},
			$otherInfo->{'describing_table_name'}
		);
		$genome_hash->{'id'} = @{ @$table_rows[ @$table_rows - 1 ] }[0];
	}

	$genomeHandle =
	  $self->{'data_handler'}->{'genomeDB'}
	  ->getGenomeHandle_for_dataset($genome_hash);
	$genomeHandle = $genomeHandle->get_rooted_to('gbFilesTable');
	$self->{'error'} .= $self->{'data_handler'}->{'genomeDB'}->{'error'};

	## OK - we need to identify the table_baseString for this specific oligo2dnaDB instance...
	my $oligo2dnaDB = oligo2dnaDB->new( $self->{dbh}, $self->{debug} );
	$oligo2dnaDB->TableName(
		$self->__create_table_baseString( $genomeHandle, $otherInfo ) );
	$oligo2dnaDB->{'data_handler'}->{'gbFileTable'} =
	  $genomeHandle->get_rooted_to("gbFilesTable");
	$oligo2dnaDB->{'data_handler'}->{'oligoDB'} = $oligoDB;
	return $oligo2dnaDB;
}

sub Match_oligoDB_to_Genome {
	my ( $self, $otherInfo, $genome_hash ) = @_;
	## $nucleotideArray_hash == a hash that could be used to import the nucleotideArray into the database

	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . ":Match_oligoDB_to_Genome -> we need the ID for the other dataset!\n"
	  unless ( defined $otherInfo->{'id'} );
	$self->{'error'} .=
	  ref($self)
	  . ":Match_oligoDB_to_Genome -> we need the describing_table_name for the other dataset!\n"
	  unless ( defined $otherInfo->{'describing_table_name'} );

	Carp::complain( $self->{'error'} ) if ( $self->{error} =~ m/\w/ );

	##print on error:
#	print ref($self)
#	  . ":Match_oligoDB_to_Genome we had an error here:\n"
#	  . "\$otherInfo = $otherInfo \n"
#	  . "\$otherInfo->{'describing_table_name'} = $otherInfo->{'describing_table_name'}\n"
#	  . "\$otherInfo->{'id'} = $otherInfo->{'id'}\n";
	my $oligoDB =
	  $self->Get_upstream_handler_4_tableName(
		$otherInfo->{'describing_table_name'} )
	  ->Get_OligoDB_for_ID( $otherInfo->{'id'} );

	my $genomeHandle =
	  $self->{'data_handler'}->{'genomeDB'}
	  ->getGenomeHandle_for_dataset($genome_hash);

	## we crteated a data structure ($oligoData) that looks like that:
	##{ <oligoID> => [ {
	##   'gbFile_version' => <the acc as stored in the gbFiles table in the acc column>,
	##   'start_on_gbFile' => <the start on this gbFile>,
	##   'chromosomalOrientation' => <a boolean value if sense (1) or antisense (0) to this file>
	##  } ]
	## }
	# print ref($self),":_match_to_genome -> and now the matching is over\n";

	my ( $tableBaseName, $id ) =
	  $self->{'data_handler'}->{'genomeDB'}
	  ->select_tableBasename_and_genomeID($genome_hash);

	my $dataset = {
		'genome'     => { 'id' => $genomeHandle->{'genomeID'} },
		'foreign_id' => $otherInfo->{'id'},
		'foreign_table'       => $otherInfo->{'describing_table_name'},
		'oligoData'           => {},
		'gbFiles_base_string' => $tableBaseName,
		'table_baseString' =>
		  $self->__create_table_baseString( $genomeHandle, $otherInfo ),
		'oligoDB' => $oligoDB
	};

	#$dataset->{'just a test'} = [ 1, 2, 3, 4, 5, 6, 7 ];

#	root::print_hashEntries( $dataset, 4,
#		"we try to add this dataset to a oligo2dnaDB" );
	## does that oligoData exist?
	if ( defined $self->_return_unique_ID_for_dataset($dataset) ) {
		warn ref($self)
		  . ":Match_oligoDB_to_Genome -> it seams as if this dataset has already beed imported!\nSTOP\n";
		return 0;
	}
	$dataset->{'oligoData'} = $self->_match2genome( $oligoDB, $genomeHandle );
	if ( open( OUT, ">SAVE_STORAGE_oligoi_match.txt" ) ) {
		my $i = 0;
		print OUT
"oligoID\tstart on gbFile\tgbFile_id\toligo length\tchromosome_name\tchr_start\tchromosomalOrientation\thit count\n";
		foreach my $oligoID ( keys %{ $dataset->{'oligoData'} } ) {
			$i = scalar( @{ $dataset->{'oligoData'}->{$oligoID} } );
			foreach my $entryHash ( @{ $dataset->{'oligoData'}->{$oligoID} } ) {
				print OUT
				  "$oligoID\t$entryHash->{'start'}\t$entryHash->{'length'}\t"
				  . "$entryHash->{'chromosome_name'}\t$entryHash->{'chr_start'}\t$entryHash->{'gbFile_id'}\t$entryHash->{'sameOrientation'}\t$i\n";

			}
		}
		close(OUT);
	}

	$self->AddDataset($dataset);
	system( "tar -cf archiv" . root::Toaday() . ".tar *.fa* *.blastResult" );
	system( "bzip2 archiv" . root::Toaday() . ".tar" );
	return 1;
}

sub __create_table_baseString {
	my ( $self, $genomeHandle, $otherInfo ) = @_;
	$self->{'error'} ||= '';
	$self->{'error'} .=
	    ref($self)
	  . "::__create_table_baseString we expect the \$genomeHandle to be a object of class 'gbFilesTable' or 'gbFeaturesTable', but it ids of class '"
	  . ref($genomeHandle) . "'\n"
	  unless ( ref($genomeHandle) eq "gbFilesTable"
		or ref($genomeHandle) eq "gbFeaturesTable" );
	$self->{'error'} .=
	  ref($self)
	  . ":__create_table_baseString we need the \$genomeHandle->{'genomeID'} (\$genomeHandle = $genomeHandle) to create the tableBase name\n"
	  unless ( defined $genomeHandle->{'genomeID'} );
	$self->{'error'} .=
	  ref($self)
	  . ":__create_table_baseString we need the \$otherInfo->{'describing_table_name'} to create the tableBase name\n"
	  unless ( ref($otherInfo) eq "HASH"
		&& defined $otherInfo->{'describing_table_name'} );
	$self->{'error'} .=
	  ref($self)
	  . ":__create_table_baseString we need the \$otherInfo->{'id'} to create the tableBase name\n"
	  unless ( ref($otherInfo) eq "HASH" && defined $otherInfo->{'id'} );
	$self->__dieOnError();
	return
	    "G_"
	  . $genomeHandle->{'genomeID'} . "_"
	  . $otherInfo->{'describing_table_name'} . "_"
	  . $otherInfo->{'id'};

}

=head2 INSERT_INTO_DOWNSTREAM_TABLES

Here we insert the oligo2dna datasets! 
In the future we might support multiple datasets in one oligo2dnaDB table (PCR oligos!), 
but at the moment each dataset is inserted into a new table.

=cut

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;
	$self->{'error'} .= '';
	$self->{'error'} .=
	  ref($self)
	  . ":INSERT_INTO_DOWNSTREAM_TABLES -> we have no usable oligo Data\n"
	  unless ( ref( $dataset->{'oligoData'} ) eq "HASH" );
	## create a table base name

	$self->{'error'} .=
	  ref($self)
	  . ":INSERT_INTO_DOWNSTREAM_TABLES -> we need a oligoDB to initialize the olig2dnaDB correctly!\n"
	  unless ( ref( $dataset->{'oligoDB'} ) eq "oligoDB" );

	my $oligo2dnaDB = oligo2dnaDB->new( $self->{dbh}, $self->{debug} );
	$oligo2dnaDB->{'data_handler'}->{'oligoDB'} = $dataset->{'oligoDB'};

	#	print ref($self)
	#	  . ":INSERT_INTO_DOWNSTREAM_TABLES -> I try to insert the hash "
	#	  . root::get_hashEntries_as_string(
	#		{
	#			'data'                => $dataset->{'oligoData'},
	#			'gbFiles_base_string' => $dataset->{'gbFiles_base_string'},
	#			'table_base_string' =>
	#			  $oligo2dnaDB->TableName( $dataset->{'table_baseString'} )
	#		},
	#		6,
	#		" into the table "
	#		  . $oligo2dnaDB->TableName( $dataset->{'table_baseString'} )
	#	  );

	$oligo2dnaDB->this_AddDataset(
		{
			'data'                => $dataset->{'oligoData'},
			'gbFiles_base_string' => $dataset->{'gbFiles_base_string'},
			'table_baseString' =>
			  $oligo2dnaDB->TableName( $dataset->{'table_baseString'} )
		}
	);
	return 1;
}

sub _match2genome {
	my ( $self, $oligoDB, $genomeHandle ) = @_;

	$oligoDB->Get_as_fastaDB();    ## init the oligoDB data structure!
	my $minLength = $oligoDB->minLength();
	$minLength = int( $minLength * 0.98 );
	print ref($self)."::_match2genome getting the oligo values\n";
	$oligoDB->WriteAsFastaDB( $self->{tempDir} . "/oligos.fa" );
	if ( $self->{debug} ) {
		print ref($self), ":we got $oligoDB->{entries} oligos\n";
		print ref($self),
		  ":DEBUG!!! formatdb -p F -o T -i $self->{tempDir}/oligos.fa\n";
	}
	print ref($self)."::_match2genome using formatdb to create the blast db\n";
	system("formatdb -p F -o T -i $self->{tempDir}/oligos.fa ");

	unless ( -f "$self->{tempDir}/oligos.fa.nsi" ) {
		##perhaps we did not get the sequences?
		unless ( -f "$self->{tempDir}/oligos.fa" ) {
			warn "we did not get the fasta db '$self->{tempDir}/oligos.fa'\n";
			root::print_hashEnries( $oligoDB, 3, "entries in the oligo db:" );
		}
	}
	my (
		$chromosome, $start_on_chr, $gbFile, @line, $oligoData,
		$matches,    $cmd,          $sth,    $sql,  $rv
	);
	$sql = $genomeHandle->create_SQL_statement(
		{
			'search_columns' => [
				'chromosomesTable.chromosome', 'chromosomesTable.chr_start',
				'chromosomesTable.feature_name'
			],
			'where' => [ [ 'chromosomesTable.id', '=', 'my_value' ] ]
		}
	);
	$sth = $genomeHandle->{'dbh'}->prepare($sql);
	my $gbFile_id = 1;
	my $chromosomeTable_Read;
	print ref($self)."::_match2genome starting the real work...\n";
	while (1) {
		$chromosomeTable_Read = $genomeHandle->getArray_of_Array_for_search(
			{
				'search_columns' => [
					'chromosomesTable.chromosome',
					'chromosomesTable.chr_start',
					'chromosomesTable.feature_name'
				],
				'where' => [ [ 'chromosomesTable.id', '=', 'my_value' ] ]
			},
			$gbFile_id
		);
		print root::get_hashEntries_as_string ($chromosomeTable_Read, 3, "the \$chromosomeTable_Read ");
		#print "we analyze the gbFile ".$gbFile->Version."\n";
		last unless ( ref( @$chromosomeTable_Read[0] ) eq "ARRAY" );
		unless ( -f "$self->{tempDir}/@{@$chromosomeTable_Read[0]}[2].blastResult" ) {
			print "we process the gbFile version @{@$chromosomeTable_Read[0]}[2]\n";
			$gbFile = $genomeHandle->get_gbFile_for_gbFile_id($gbFile_id);
			unless ( defined $gbFile ) {
				last;
				next;
			}

			$cmd =
			    "megablast -W $minLength -m 8 -D 3 -i $self->{tempDir}/"
			  . @{@$chromosomeTable_Read[0]}[2]
			  . ".fa -d $self->{tempDir}/oligos.fa -o $self->{tempDir}/"
			  . @{@$chromosomeTable_Read[0]}[2]
			  . ".blastResult";
			warn "and now we try to access the file $self->{tempDir}/"
			  . @{@$chromosomeTable_Read[0]}[2]
			  . ".blastResult\n";

			warn "now we execute the megablast\n";
			$gbFile->WriteAsFasta(
				"$self->{tempDir}/" . $gbFile->Version() . ".fa",
				$gbFile->Version() );
			print ref($self), " we will execute: $cmd\n"
			  if ( $self->{debug} );
			system($cmd );
		}
		else {
			print "we have used the saved gbFile $self->{tempDir}/@{@$chromosomeTable_Read[0]}[2].blastResult\n";
		}
		## now we have to read in the blast result....
		$matches = 0;
		open( IN, "<$self->{tempDir}/@{@$chromosomeTable_Read[0]}[2].blastResult" )
		  or die "oops ", ref($self),
" we try to read in a blast result, but could not access the file $self->{tempDir}/"
		  . @{@$chromosomeTable_Read[0]}[2]
		  . ".blastResult\n";
		while (<IN>) {
			next if ( $_ =~ m/^ *#/ );
			chomp $_;
			@line = split( "\t", $_ );
			if (
				$line[2] == 100    # % sequence identity
				&& $line[3] == $oligoDB->length_for_acc( $line[1] )
			  )
			{
				## full length hit and no mismatch
				$matches++;
				$oligoData->{ $line[1] } = []
				  unless ( defined $oligoData->{ $line[1] } );
				my $hash = {
					'oligo' => { 'id' => $oligoDB->get_oligoID( $line[1] ) },
					'length'          => $oligoDB->length_for_acc( $line[1] ),
					'chromosome_name' => @{@$chromosomeTable_Read[0]}[0],
					'chr_start'       => @{@$chromosomeTable_Read[0]}[1] + $line[6],
					'start'           => $line[6],
					'gbFile' =>
					  { 'id' => $gbFile_id, 'acc' => @{@$chromosomeTable_Read[0]}[2] },
					'gbFile_id' => $gbFile_id
				};
				$hash->{'sameOrientation'} = 1
				  if ( $line[8] < $line[9] );
				$hash->{'sameOrientation'} = 0
				  if ( $line[8] > $line[9] );
				push( @{ $oligoData->{ $line[1] } }, $hash );
			}

#			elsif ( $line[2] == 100 && $line[3] > $oligoDB->length_for_acc( $line[1] )) {
#				Carp::confess ("we have an serious error in oligoDB->length_for_acc as we got ".$oligoDB->length_for_acc( $line[1] ).
#				" and the balst search returned $line[3] as length for the oligo hit ( $line[1] )!\n" );
#			}
#			elsif ( $self->{debug} ) {
#				print
#"we tried to use the line\n$_\n, but either !($line[2] == 100) or !( $line[3] == ",
#				  $oligoDB->length_for_acc( $line[1] ), "\n";
#			}
		}
		close(IN);

		$self->{'logging'}->set_log(
			{
				'programID'   => ref($self) . "->_match2genome()",
				'description' => "genomeID = "
				  . $genomeHandle->{'genomeID'}
				  . ", gbFile_id = $gbFile_id, version "
				  . @{ @$chromosomeTable_Read[0] }[2]
				  . " matches = $matches; command = '$cmd'"
			}
		) if ( defined $cmd);
		$gbFile_id++;

	}
	return $oligoData;
}

1;
