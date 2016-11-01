package ROI_table;

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
use stefans_libs::database::system_tables::loggingTable;
use base 'variable_table';

sub new {
	my ( $class, $database, $debug ) = @_;

	my ($self);
	unless ( defined $database ) {
		warn "$class : we had to set the database name to 'genomeDB'\n";
		$database = "genomeDB";
	}
	my $dbh = root::getDBH( 'root' );

	die "we need the dbh at $class new \n" unless ( ref($dbh) eq "DBI::db" );

	$self = {
		debug      => $debug,
		'database' => $database,
		dbh        => $dbh,
	};

	bless $self, $class
	  if ( $class eq "ROI_table" );

	$self->init_tableStructure();
	$self->{'dbh'}->do("SET SQL_MODE = 'NO_UNSIGNED_SUBTRACTION'");

	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub makeMaster {
	my ( $self, $gbFiles_obj ) = @_;
	Carp::confess(
		ref($self)
		  . "::makeMaster absolutely needs an gbFilesTable object to work - not $gbFiles_obj"
	) unless ( ref($gbFiles_obj) eq "gbFilesTable" );
	foreach my $variableDef ( @{ $self->{'table_definition'}->{'variables'} } )
	{
		if ( $variableDef->{'name'} eq 'gbFile_id' ) {
			$variableDef->{'data_handler'} = 'gbFilesTable';
		}
	}
	$self->{'data_handler'}->{'gbFilesTable'} = $gbFiles_obj;
	$self->{'master'} = 1;
	$self->{'genomeID'} = $gbFiles_obj->{'genomeID'};
	return $self;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'} = [ ['tag'], ['name'], ['start'], ['end'] ];
	$hash->{'UNIQUES'} = [ ['md5_sum'] ];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gbFile_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tag',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'end',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gbString',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'loggingTable_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'loggingTable',
			'description'  => 'the connection to the logging table',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'CHAR (32)',
			'NULL'        => '0',
			'description' => 'A unique entry - md5_hash of the gbString',
			'needed'      => ''
		}
	);
	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'Group_to_MD5_hash'} = [ 'gbString', 'loggingTable_id' ];

	$self->{'UNIQUE_KEY'} = ['md5_sum']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	$self->{'data_handler'}->{'loggingTable'} =
	  loggingTable->new( $self->{database}, $self->{debug} );
	print
"ROI_table - we craeted an loggingTable object $self->{'data_handler'}->{'loggingTable'} \n";
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $dataset;
}

sub getClosestGene_4_ROI_id {
	my ( $self, $id ) = @_;

	Carp::confess(
		    ref($self)
		  . "::getClosestGene_4_ROI_id should not be used, as it does not calculate right and is horrably slow. "
		  . "A better solution is to select the relevant gbFeatures from the right genome_interface and then do a 'manual' comparison"
		  . " as shown in getClosestGene_for_SNP_ID.pl\n" );

	Carp::confess(
		ref($self)
		  . "::getClosestGene_4_ROI_id we need to be the master table to do that"
	) unless ( $self->{'master'} );

	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => ['gbFeaturesTable.gbString'],
			'where'          => [
				[
					[ 'gbFeaturesTable.start', '-', 'ROI_table.start' ], '<',
					'my_value'
				],
				[ 'gbFeaturesTable.tag', '=', 'my_value' ],
				[ 'ROI_table.id',        '=', 'my_value' ]

			],
			'order_by' => [
				[
					[ 'gbFeaturesTable.start', '-', 'ROI_table.start' ],
					'*',
					[ 'gbFeaturesTable.start', '-', 'ROI_table.start' ]
				]
			],
			'limit' => 'limit 1'
		},
		10000,
		'gene',
		$id
	);

	if ( defined @$rv[0] ) {
		my $gbFeature = gbFeature->new( 'gene', "1..2" );

		$gbFeature->parseFromString( @{ @$rv[0] }[0] );
		return $gbFeature;
	}
	else {
		return undef;
	}
	return undef;
}

sub getSequence_and_ROIobj_4_ROI_id {
	my ( $self, $id, $_3primeADD, $_5primeADD ) = @_;

	Carp::confess(
		ref($self)
		  . "::getClosestGene_4_ROI_id we need to be the master table to do that"
	) unless ( $self->{'master'} );
	my $complex = " substr( #1, #2 ";
	if ( defined $_3primeADD ) {
		$complex .= " - $_3primeADD ";
	}
	$complex .= ",sqrt( ( #2 -  #3";

	$complex .= " ) * ( #2 ";
	$complex .= "-  #3";
	$complex .= " ) )";
	if ( defined $_5primeADD ) {
		$complex .= " + $_5primeADD ";
	}
	if ( defined $_3primeADD ) {
		$complex .= " + $_3primeADD ";
	}
	$complex .= "), #4 ,#5 ,#6, #7, #8";

	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				'gbFilesTable.seq', 'ROI_table.start',
				'ROI_table.end',    'ROI_table.gbString',
				'ROI_table.tag',    'ROI_table.name',
				'ROI_table.start',  'ROI_table.end'
			],
			'where' => [
				[ 'ROI_table.id', '=', 'my_value' ]

			],
			'complex_select' => \$complex
		},
		$id
	);

	#print "we might get a result for search ".$self->{'complex_search'}."\n";
	unless ( ref( @$rv[0] ) eq "ARRAY" ) {
		print "the search $self->{complex_search} did not leed to an result!\n";

	}
	elsif ( defined @{ @$rv[0] }[0] ) {
		my $gbFeature = gbFeature->new( 'nix', '1..2' );
		if ( $gbFeature->parseFromString( @{ @$rv[0] }[1] ) ) {

		#print "we had no problem in parsing the data string @{ @$rv[0] }[1]\n";
			return @{ @$rv[0] }[0], $gbFeature;
		}
		else {
			print
			  "we had A PROBLEM in parsing the data string @{ @$rv[0] }[1]\n";
			$gbFeature = gbFeature->new(
				substr( @{ @$rv[0] }[2], length( @{ @$rv[0] }[2] ) - 14, 14 ),
				@{ @$rv[0] }[4] . ".." . @{ @$rv[0] }[5] );
			return @{ @$rv[0] }[0], $gbFeature;
		}

	}
	else {
		print "we could not get a result for search "
		  . $self->{'complex_search'} . "\n";
		return undef;
	}
	return undef;
}

=head2 get_ROI_obj_4_id

This function will return a gbFeature object describing the ROI and the gbFile_id or undef if the ROI id could not be found.

=cut

sub get_ROI_obj_4_id {
	my ( $self, $ROI_id ) = @_;
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => ['ROI_table.gbString','ROI_table.gbFile_id'],
			'where'          => [ [ 'ROI_table.id', '=', 'my_value' ] ],
		},
		$ROI_id
	);
	return undef unless ( ref(@$data[0]) eq "ARRAY");
	my $obj = gbFeature->new('nix', "1..2");
	$obj->parseFromString( @{ @$data[0] }[0]);
	return $obj, @{ @$data[0] }[1];
}

sub select_RIO_ids_for_ROI_tag {
	my ( $self, $ROI_tag ) = @_;
	return undef unless ( defined $ROI_tag );
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => ['ROI_table.id'],
			'where'          => [ [ 'ROI_table.tag', '=', 'my_value' ] ]
		},
		$ROI_tag
	);
	my @return;
	foreach (@$data) {
		push( @return, @$_[0] );
	}
	return \@return;
}

1;
