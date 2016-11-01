package oligoDB;

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
use stefans_libs::fastaDB;
use stefans_libs::database::variable_table;
use base qw(fastaDB variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store and get the oligo sequences of an nucleotide array.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class oligoDB.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless ( defined $dbh );

	my $self;

	$self = {
		dbh             => $dbh,
		debug           => $debug,
		data            => my $data,
		entries         => 0,
		accs            => [],
		actual_position => undef
	};

	bless $self, $class if ( $class eq "oligoDB" );
	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}   = [];
	$hash->{'UNIQUES'}   = [];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'oligo_name',
			'type' => 'VARCHAR (40)',
			'NULL' => '0',
			'description' =>
			  'this value will be the accession number of the oligo',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'sequence',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the oligo sequence - no checks!',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['oligo_name'] );
	$hash->{'ENGINE'}           = 'InnoDB';
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['oligo_name']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	return $dataset;
}

=head2 AddDataset

Add data to a oligoDB database. The function needs the baseName of the right table.
In this information, the corresponding array is coded.
In addition to the baseName, we need an object of the class stefans_libs::fastaDB is needed.
You can look at the class oligoDB as the database addition to the class fastaDB.

=cut

sub this_AddDataset {
	my ( $self, $fastaDB ) = @_;
	my $tableName = $self->TableName();

	die ref($self),
	  ":AddDataset -> we need to know the table name (not '$tableName')"
	  unless ( defined $tableName );
	Carp::confess( ref($self),
":AddDataset -> we need a object of the class stefans_libs::fastaDB to store it in the database (not '$fastaDB')\n"
	) unless ( ref($fastaDB) eq "fastaDB" || defined @{ $self->{accs} }[0] );

	if ( $fastaDB->isa("fastaDB") ) {
		$self->{data}    = $fastaDB->{data};
		$self->{accs}    = $fastaDB->{accs};
		$self->{entries} = $fastaDB->{entries};
	}

	$self->_create_insert_statement();

	if ( $self->{debug} ) {
		print ref($self),
":AddDataset -> in debug mode - no data will be entered, but we would do that:\n";
		$self->_get_SearchHandle( { 'search_name' => 'insert' } );
		while ( my ( $acc, $seq ) = $self->get_next() ) {
			last unless ( defined $acc );
			print $self->_getSearchString( "insert", $acc, $seq ), "\n";
		}
	}
	else {
		my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
		while ( my ( $acc, $seq ) = $self->get_next() ) {
			last unless ( defined $acc );
			$sth->execute( $acc, $seq );
		}
	}
	return 1;
}

sub count_linked_array_values_tables{
	my ($self) = @_;
	return 0 unless (ref($self->{'data_handler'}->{'oligo_array_values'}) eq "ARRAY");
	return scalar( @{$self->{'data_handler'}->{'oligo_array_values'}} );
}

sub Add_oligo_array_values_Table {
	my ( $self, $tableName, $tableBaseName, $sample_lable ) = @_;

	#$tableName = '' unless ( defined $tableName);
	#$tableBaseName = '' unless ( defined  $tableBaseName );
	unless ( ref( $self->{'data_handler'}->{'oligo_array_values'} ) eq "ARRAY" )
	{
		push(
			@{ $self->{'table_definition'}->{'variables'} },
			{
				'name'         => 'id',
				'data_handler' => 'oligo_array_values',
				'type'         => 'INTEGER',
				'description'  => "this is an artefact of process $$",
				'NULL'         => 0
			}
		);
		$self->{'data_handler'}->{'oligo_array_values'} = [];
	}

	my $oligo_array_values;
	foreach $oligo_array_values (
		@{ $self->{'data_handler'}->{'oligo_array_values'} } )
	{
		if ( defined  $tableName){
			if ( $oligo_array_values->TableName() eq $tableName ){
			return $oligo_array_values
		}
		}
		if ( defined $tableBaseName){
			if ( $oligo_array_values->{'_tableName'} eq $tableBaseName ){
			return $oligo_array_values
		}
		}
	}

	$oligo_array_values =
	  oligo_array_values->new( $self->{'dbh'}, $self->{'debug'} );
	$oligo_array_values->linked_table_name( $self->TableName() );
	$oligo_array_values->Sample_Lable ( $sample_lable );
	if ( defined $tableBaseName ) {
		$oligo_array_values->TableName($tableBaseName);
	}
	elsif ( defined $tableName ) {
		$oligo_array_values->{'_tableName'} = $tableName;
	}

	$oligo_array_values->{'FOREIGN_TABLE_NAME'} = $self->TableName();
	@{ $self->{'data_handler'}->{'oligo_array_values'} }[scalar(@{ $self->{'data_handler'}->{'oligo_array_values'} })]=
		$oligo_array_values;
	#Carp::confess( "I know we had some errors - this is just for the tracking of the error!\n".root::get_hashEntries_as_string ($oligo_array_values, 3, "And to see what is in the \$oligo_array_values: "));
	return $oligo_array_values;
}

sub get_downstreamTable {
	my ( $self, $hash ) = @_;
	Carp::confess(
		ref($self)
		  . "::get_downstreamTable -> we need an hash containing either 'tableName' or 'base_tableName' to construct the table handler!\n"
	) unless ( ref($hash) eq "HASH" );
	return $self->Add_oligo_array_values_Table( $hash->{'tableName'} )
	  if ( defined $hash->{'tableName'} );
	return $self->Add_oligo_array_values_Table( undef,
		$hash->{'tableBaseName'} )
	  if ( defined $hash->{'tableBaseName'} );
	Carp::confess(
		ref($self)
		  . "::get_downstreamTable -> we need an hash containing either 'tableName' or 'tableBaseName' to construct the table handler!\n"
	);
}

sub Sample_Lables{
	my ( $self) = @_;
	my @sample_lables;
	foreach my $oligo_array_values (
		@{ $self->{'data_handler'}->{'oligo_array_values'} } )
	{
		push ( @sample_lables, $oligo_array_values->Sample_Lable() );
		## This only works if the sample lable was known while creating the data structure.
		## 3rd value with $self->Add_oligo_array_values_Table had to be set!!
	}
	return @sample_lables;
}

sub remove_all_oligo_array_values_Tables {
	my ($self) = @_;
	for (
		my $i = 0 ;
		$i < @{ $self->{'table_definition'}->{'variables'} } ;
		$i++
	  )
	{
		if (
			defined @{ $self->{'table_definition'}->{'variables'} }[$i]
			->{'data_handler'}
			&& ( @{ $self->{'table_definition'}->{'variables'} }[$i]
				->{'data_handler'} eq 'oligo_array_values' )
		  )
		{
			@{ $self->{'table_definition'}->{'variables'} }[$i] = undef;
		}
	}
	$self->{'data_handler'}->{'oligo_array_values'} = undef;
	return 1;
}

sub Get_as_fastaDB {
	my ( $self, $baseName ) = @_;
	return $self if ( defined @{ $self->{'acc'} }[0] );
	$self->{'select_all'} = $self->create_SQL_statement(
		{
			'search_columns' =>
			  [ ref($self) . '.oligo_name', ref($self) . '.sequence' ],
			'order_by' => [ ref($self) . '.id' ]
		}
	) unless ( defined $self->{'select_all'} );

#print ref($self)."::Get_as_fastaDB -> we have created the sql statement '$self->{'select_all'}'\n";
	my $sth = $self->_get_SearchHandle(
		{ 'baseName' => $baseName, 'search_name' => 'select_all' } );
	if ( $self->{debug} ) {
		print ref($self),
":Get_as_fastaDB -> we are in debug mode - we show you the sql query:\n";
		print "'" . $self->_getSearchString('select_all') . ";'\n";
	}

	my ( $acc, $seq );
	$sth->execute();
	$sth->bind_columns( \$acc, \$seq );
	while ( $sth->fetch() ) {
		$self->addEntry( $acc, $seq );
		Carp::confess(
			"we got an error while reading the oligos from the database ",
			$self->TableName(), ":\n$self->{error}" )
		  if ( $self->{error} =~ m/\w/ );
	}
	$self->{actual_position} = 0;
	$self->{data_fetched}    = 1;
	return $self;
}

sub reset_getNext_acc {
	my ($self) = @_;

#Carp::confess ref($self).":reset_getNext_acc \$self->{actual_position} = $self->{actual_position}\n";
	unless ( $self->{data_fetched} ) {
		$self->Get_as_fastaDB();
	}
	$self->{actual_position} = 0;
	return 1;
}

sub getNext_acc {
	my ($self) = @_;
	$self->reset_getNext_acc() unless ( $self->{data_fetched} );
	my $ret = @{ $self->{accs} }[ $self->{actual_position}++ ];
	return $ret;
}

sub minLength {
	my ($self) = @_;
	return $self->{min_length} if ( defined $self->{min_length} );
	$self->{min_length} = length( $self->{data}->{ @{ $self->{accs} }[0] } );
	my $length;
	for ( my $i = 1 ; $i < @{ $self->{accs} } ; $i++ ) {
		$length = length( $self->{data}->{ @{ $self->{accs} }[$i] } );
		$self->{min_length} = $length if ( $length < $self->{min_length} );
	}
	return $self->{min_length};
}

1;
