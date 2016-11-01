package variable_table;

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
use DateTime::Format::MySQL;
use stefans_libs::database::variable_table::linkage_info;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::root;

use Digest::MD5 qw(md5_hex);
use DateTime;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a base class for the variable tables. Includes methods to create the table name and methods to create the statement handles.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class variable_table.

=cut

sub new {
	my ($class, $debug) = @_;
	## this class can be used to print a dummy table info! but only for that purpose!!!!!

	my ( $hash, $self );
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "nucleotide_array_libs";
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'ONLYaTEST',
			'type' => 'VARCHAR (40)',
			'NULL' => '0',
			'description' =>
'this is no table definition, the class is a ORGANIZER class. See the description!',
			'needed' => '1'
		}
	);

	push( @{ $hash->{'UNIQUES'} }, ['ONLYaTEST'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['ONLYaTEST']
	  ; # add here the values you would take to select a single value from the database

	bless $self, $class;
	return $self;

}

=head2 BatchAddDataset

This function does almoast the same as AddDataset, but there are no checks - 
therefore you should not use it to add any dataset that spans several tables 
or does contain any column value that is created by the check_dataset function (timestamp, md5_sum, etc.).

But the speedup is tremendous!

=cut 

sub BatchAddDataset {
	my ( $self, $dataset ) = @_;
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	$self->{'error'} = '';
	## I will not check whether you have given me shit - I will just do the work - over and over again!
	$self->_create_insert_statement();
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
		Carp::confess(
			ref($self),
			":BatchAddDataset -> we got a database error for query '",
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
			  . "\nand the last search for a unique did not return the expected id!'$self->{'complex_search'}'\n"
			  . root::get_hashEntries_as_string(
				$self->_get_search_array($dataset), 3,
				"Using the search array: "
			  )
		);
	}
	$self->{'last_insert_stm'} =
	  $self->_getSearchString( 'insert',
		@{ $self->_get_search_array($dataset) } );
	return 1;
}

=head2 BatchAddTable

This function does almoast the same as AddDataset, but there are no checks - 
therefore you should not use it to add any dataset that spans several tables 
or does contain any column value that is created by the check_dataset function (timestamp, md5_sum, etc.).

But the speedup is tremendous!

=cut 

sub BatchAddTable {
	my ( $self, $data_table ) = @_;
	Carp::confess("Sorry, but you can only add a data table object here!\n")
	  unless ( $data_table->isa('data_table') );
	return 0 if ( $data_table->is_empty() );
	## Check once!
	Carp::confess(
		    "Sorry, but you can not add that table to the database table "
		  . ref($self)
		  . "\n$self->{'error'}\n" )
	  unless ( $self->check_dataset( $data_table->get_line_asHash(0) ) );
	my ( $sth, $dataset );
	$self->_create_insert_statement();
	$sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );

	for ( my $i = 0 ; $i < @{ $data_table->{'data'} } ; $i++ ) {
		$dataset = $data_table->get_line_asHash($i);
		unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
			Carp::confess(
				ref($self),
				":BatchAddTable -> we got a database error for query '",
				$self->_getSearchString(
					'insert', @{ $self->_get_search_array($dataset) }
				),
				";'\n",
				root::get_hashEntries_as_string(
					$dataset,
					4,
					"the dataset we tried to insert into the table structure:"
				  )
				  . "And here are the database errors:\n"
				  . $self->{dbh}->errstr()
				  . "\nand the last search for a unique did not return the expected id!'$self->{'complex_search'}'\n"
				  . root::get_hashEntries_as_string(
					$self->_get_search_array($dataset), 3,
					"Using the search array: "
				  )
			);
		}
		$self->{'last_insert_stm'} =
		  $self->_getSearchString( 'insert',
			@{ $self->_get_search_array($dataset) } );
	}
	return 1;
}

sub config {

	'dbh' => root::getDBH('root');

	#Carp::confess( "I got the args ".join(', ',@args) );
}

sub _tableNames {
	my ($self) = @_;
	return $self->{__tableNames}
	  if ( ref( $self->{__tableNames} ) eq "ARRAY"
		&& scalar( @{ $self->{__tableNames} } ) > 0 );
	my ( $name, $sql, $connection, $db_name );
	unless ( defined $self->{dbh} ) {
		Carp::confess(
			ref($self)
			  . "::_tableNames -> we do not have an usable database hendle!\n"
		);
	}
	( $self->{'connection'}, $db_name ) = root::getDBH_Connection()
	  unless ( ref( $self->{'connection'} ) eq "HASH" );
	$connection = $self->{'connection'};
	if ( $connection->{'driver'} eq "mysql" ) {
		$sql = "show tables";

		$self->{execute_table} = $self->{dbh}->prepare($sql)
		  unless ( defined $self->{execute_table} );
		$self->{execute_table}->execute()
		  or Carp::confess(
			    ref($self)
			  . "::_tableNames -> we could not execute $sql\n"
			  . $self->{'dbh'}->errstr() );
		$self->{execute_table}->bind_columns( \$name );
		$self->{__tableNames} = [];
		while ( $self->{execute_table}->fetch() ) {
			push( @{ $self->{__tableNames} }, $name );
		}
	}
	elsif ( $connection->{'driver'} eq "DB2" ) {
		$self->{__tableNames} =
		  [ $self->{'dbh'}
			  ->tables( { 'TABLE_SCHEM' => uc( $connection->{'dbuser'} ) } ) ];
	}

#warn ref($self),":_tableNames -> we have the table names ",join (", ", @{$self->{__tableNames}}),"\n";
	return $self->{__tableNames};
}

sub tableExists {
	my ( $self, $table_name ) = @_;
	my $name;
	return $self->{'check_ok'} if ( $self->{'check_ok'} && $self->TableName() eq  $table_name);
	if ( $self->{'connection'}->{'driver'} eq "DB2" ) {

		foreach $name ( @{ $self->_tableNames() } ) {

			#print "do we have a match ( $name eq " . '"'
			#  . uc( $self->{'connection'}->{'dbuser'} ) . '"."'
			#  . uc($table_name) . '"' . " )\n";
			return 1
			  if ('"'
				. uc( $self->{'connection'}->{'dbuser'} ) . '"."'
				. uc($table_name)
				. '"' eq uc($name) );
		}
	}
	elsif ( $self->{'connection'}->{'driver'} eq "mysql" ) {
		foreach $name ( @{ $self->_tableNames() } ) {
			if ( $table_name eq $name ) {
				$self->{'check_ok'} = 1;
				$self->update_structure();
				return 1;
			}
		}
	}
	else {
		Carp::confess(
			ref($self)
			  . " - variable_table::tableExists -> we do not support the db driver '$self->{'connection'}->{'dbuser'}'\n"
		);
	}

	return 0;
}

sub TableName {
	my ( $self, $baseName ) = @_;

#Carp::cluck( ref($self)."::TableName -> $self->{_tableName}\n");
#die if ( $self->{_tableName} eq "materialsTable");
#Carp::confess ( "Hej - where did you get from - I do not have a \$self object!\n" ) unless ( ref($self) =~ m/\w/ );
	unless ( defined $self->{'connection'} ) {
		my $temp;
		my $root = root->new();
		( $self->{'connection'}, $temp ) = $root->getDBH_Connection();
	}
	return $self->{_tableName} if ( defined $self->{_tableName} );

	unless ( defined $baseName ) {
		$baseName = $self->{tableBaseName};
		Carp::confess(
			ref($self)
			  . ":TableName -> we need a tableBase name to craete a specific table name\n"
		) unless ( defined $baseName );
	}
	elsif ( !defined $self->{tableBaseName} ) {
		$self->setTableBaseName($baseName);
	}
	$baseName .= "_" . ref($self);
	$baseName =~ s/\./_/g;
	$baseName =~ s/-/_/g;
	$baseName = uc($baseName) if ( $self->{'connection'}->{'driver'} eq "DB2" );
	$self->{'table_definition'}->{'table_name'} = $self->{_tableName} =
	  $baseName;
	return $baseName;
}

sub TableBaseName {
	my ( $self, $tableBaseName ) = @_;
	if ( defined $tableBaseName ) {
		$self->{'tableBaseName'} =
		  join( "_", ( split( " ", $tableBaseName ) ) );
		if ( defined $self->{'_propagateTableName_to'} ) {
			my $error = 0;
			unless ( ref( $self->{'tableBaseName'} ) eq "ARRAY" ) {
				die ref($self),
":setTableBaseName -> we got a wrong datastructure 'tableBaseName'!\n",
"we absolutely need an array of database interfaces we need to propagate the base name to\n",
				  "not $self-> {'tableBaseName'}!\n"
				  if ($error);
			}
			else {
				foreach ( @{ $self->{'_propagateTableName_to'} } ) {
					die ref($self),
":setTableBaseName -> the value we should propagate the table name to is not a child of variable_table\n"
					  unless ( $_->isa("variable_table") );
				}
			}
			foreach ( @{ $self->{'_propagateTableName_to'} } ) {
				$_->setTableBaseName($tableBaseName);
			}
		}
		$self->create() unless ( $self->tableExists( $self->TableName() ) );
	}
	return $self->{'tableBaseName'};
}

sub setTableBaseName {
	my ( $self, $tableBaseName ) = @_;
	my $name = $self->TableBaseName($tableBaseName);
	return 1 if ( defined $name );
	return 0;
}

sub _getSearchString {
	my ( $self, $search_name, @values ) = @_;
	my $str = $self->{$search_name};

	#print ref($self) . "_getSearchString - the initial string = $str\n";
	my $temp;
	foreach my $value (@values) {
		if ( $value =~ /^[\d\.E-]+$/ ) {
			warn
"one value too much for the search $search_name ( $value ) '$str'\n"
			  unless ( $str =~ s/\?/$value/ );
		}
		else {
			warn
"one value too much for the search $search_name ( $value ) '$str'\n"
			  unless ( $str =~ s/\?/'$value'/ );
		}
	}
	Carp::cluck(
		"we need more than ",
		scalar(@values) - 1,
		" values for the search $search_name\n"
		  . root::get_hashEntries_as_string( [@values], 3, "the dataset: " )
	) if ( $str =~ m/\?/ );
	return $str;
}

sub _dropTables_Like {
	my ( $self, $name ) = @_;
	my @dropped;
	foreach ( @{ $self->_tableNames() } ) {
		if ( $_ =~ m/$name/ ) {
			$self->{dbh}->do("drop table $_");
			push( @dropped, $_ );
		}
	}
	return \@dropped;
	$self->{__tableNames} = undef;
}

sub _get_SearchHandle {
	my ( $self, $hash ) = @_;

	# print "do we have an error here? $hash->{baseName} -> $tableName\n";

	unless ( defined $self->{"execute_$hash->{'search_name'}"} ) {
		if ( 0 ){ # $self->{ $hash->{'search_name'} } =~ m/database/ ) {
			my ($tableName);
			$tableName = $self->TableName( $hash->{baseName} );
			die
"you have to define the search template for search $$hash->{'search_name'} (in package ",
			  ref($self), ")\n"
			  unless ( defined $self->{ $hash->{'search_name'} } );

			$self->{ $hash->{'search_name'} } =~ s/database/$tableName/g;
		}
		elsif ( !defined $hash->{'search_name'} ) {
			$hash->{furtherSubstitutions} = $hash->{'search_name'};
			$hash->{'search_name'} = $hash->{baseName};
		}

		if ( scalar( keys %{ $hash->{furtherSubstitutions} } ) == 0 ) {

#print ref($self)
#  . "::_get_SearchHandle -> we do not have 'furtherSubstitutions' ($self->{ $hash->{'search_name'} })\n";
			$self->{"execute_$hash->{'search_name'}"} =
			  $self->{dbh}->prepare( $self->{ $hash->{'search_name'} } )
			  or
			  Carp::confess( "something went wrong! $self _get_SearchHandle!\n",
				$self->{dbh}->errstr() );
		}
		else {

#	print ref($self)
#	  . "::_get_SearchHandle -> we have 'furtherSubstitutions'!!!($self->{ $hash->{'search_name'} })\n";
			my ($local_search_str);
			$local_search_str = $self->{ $hash->{'search_name'} };
			while ( my ( $key, $value ) =
				each %{ $hash->{furtherSubstitutions} } )
			{
				$local_search_str =~ s/$key/$value/g;
			}
			$self->{"lastSearch_$hash->{'search_name'}"} = $local_search_str;

			#print ref($self)
			#  . "::_get_SearchHandle -> and we got $local_search_str\n";
			return $self->{dbh}->prepare($local_search_str)
			  or Carp::confess(
"something went wrong! $self _get_SearchHandle! ($local_search_str)\n",
				$self->{dbh}->errstr()
			  );

		}
	}
	return $self->{"execute_$hash->{'search_name'}"};
}

=head2 create_String

A function to create a table create string out of a hash of values.

=cut

sub create_String_mysql {
	my ( $self, $hash ) = @_;
	$self->{error} = "";

	$hash = $self->{'table_definition'} unless ( defined $hash );
	my $default_type = "VARCHAR(40)";

	unless ( defined $hash ) {
		$self->{error} .= ref($self)
		  . ":create_String can not work without a definition hash!\n";
	}
	unless ( defined $hash->{'table_name'} || $self->TableName() =~ m/\w/ ) {
		$self->{error} .=
		  ref($self) . ":create_String -> we need a 'table_name'!\n";
	}
	$hash->{'table_name'} = $self->TableName();
	my $string =
"CREATE TABLE $hash->{'table_name'} (\n\tid INTEGER UNSIGNED auto_increment,\n";
	unless ( ref( $hash->{'variables'} ) eq "ARRAY" ) {
		$self->{error} .= ref($self)
		  . ":create_String -> we need an array of 'variables' informations!\n";
	}
	else {
		foreach my $variable ( @{ $hash->{'variables'} } ) {
			$string .= $self->_construct_variableDef( 'mysql', $variable );
		}
		$string .= "\t PRIMARY KEY ( id ),\n";
	}

	if ( ref( $hash->{'INDICES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'INDICES'} } ) > 0 )
	{
		warn ref($self) . " we have an index array\n" if ( $self->{'debug'} );
		foreach my $uniques_array ( @{ $hash->{'INDICES'} } ) {
			if ( ref($uniques_array) eq "ARRAY" && @$uniques_array > 0 ) {
				warn ref($self)
				  . " and we have the index values ("
				  . join( ", ", @$uniques_array ) . ")\n"
				  if ( $self->{'debug'} );
				$string .=
				  "\tINDEX ( " . join( ", ", @$uniques_array ) . " ),\n";
			}
		}
	}
	if ( ref( $hash->{'UNIQUES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'UNIQUES'} } ) > 0 )
	{
		foreach my $uniques_array ( @{ $hash->{'UNIQUES'} } ) {
			if ( ref($uniques_array) eq "ARRAY" && @$uniques_array > 0 ) {
				$string .=
				  "\tUNIQUE ( " . join( ", ", @$uniques_array ) . ") ,\n";
			}
		}
	}
	if ( defined $hash->{'FOREIGN KEY'} ) {
		$string .=
		    "\tFOREIGN KEY ($hash->{'FOREIGN KEY'}->{'myColumn'}) "
		  . "References $hash->{'FOREIGN KEY'}->{'foreignTable'}"
		  . " ( $hash->{'FOREIGN KEY'}->{'foreignColumn'} ),\n";
		$string .= $hash->{'mysql_special'}
		  if ( defined $hash->{'mysql_special'} );
	}
	chop($string);
	chop($string);
	$string .= "\n)";
	if ( defined $hash->{'CHARACTER_SET'} ) {
		$string .= "DEFAULT CHARSET=$hash->{'CHARACTER_SET'} ";
	}
	if ( defined $hash->{'ENGINE'} ) {
		$string .= "ENGINE=$hash->{'ENGINE'}";
	}

	$string .= ";\n";
	return $string;
}

sub create_String_DB2 {
	my ( $self, $hash ) = @_;

	my ($unique_columns);
	$self->{error} = "";

	$hash = $self->{'table_definition'} unless ( defined $hash );
	my $default_type = "VARCHAR(40)";

	unless ( defined $hash ) {
		$self->{error} .= ref($self)
		  . ":create_String can not work without a definition hash!\n";
	}
	unless ( defined $hash->{'table_name'} || $self->TableName() =~ m/\w/ ) {
		$self->{error} .=
		  ref($self) . ":create_String -> we need a 'table_name'!\n";
	}
	my $string = '';
	$hash->{'table_name'} = $self->TableName();
	unless ( ref( $self->{'table_definition'}->{'FOREIGN KEY'} ) eq "HASH" ) {
		$string =
"CREATE TABLE $hash->{'table_name'} (\n\tID INTEGER generated always as identity,\n";
	}
	elsif ( $self->{'table_definition'}->{'FOREIGN KEY'}->{'myColumn'} ) {
		## we generate a foreign key table with the ID == foreign key - and that one has to be added during the insert statement!
		$string =
		  "CREATE TABLE $hash->{'table_name'} (\n\tID INTEGER NOT NULL,\n";
	}
	else {
		$string =
"CREATE TABLE $hash->{'table_name'} (\n\tID INTEGER generated always as identity,\n";
	}
	unless ( ref( $hash->{'variables'} ) eq "ARRAY" ) {
		$self->{error} .= ref($self)
		  . ":create_String -> we need an array of 'variables' informations!\n";
	}
	else {
		foreach my $variable ( @{ $hash->{'variables'} } ) {
			$string .= $self->_construct_variableDef( 'DB2', $variable );
		}
	}
	## we can't have the uniques inside the database
	## we have to take care of these for ourselve!
	## Therefore all unique will me changed to 'normal' keys and they will be checked using the check_dataset function.

	$unique_columns = {};
	if ( ref( $hash->{'UNIQUES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'UNIQUES'} } ) > 0 )
	{
		my $first = 1;
		$hash->{'do_unique_check'} = []
		  unless ( ref( $hash->{'do_unique_check'} ) eq "ARRAY" );
		foreach my $uniques_array ( @{ $hash->{'UNIQUES'} } ) {
			push( @{ $hash->{'INDICES'} },         $uniques_array );
			push( @{ $hash->{'do_unique_check'} }, $uniques_array );
		}
	}

	if ( defined $hash->{'FOREIGN KEY'}
		&& $hash->{'FOREIGN KEY'}->{'myColumn'} eq 'id' )
	{
		$string .=
		    "\tFOREIGN KEY ($hash->{'FOREIGN KEY'}->{'myColumn'}) "
		  . "References $hash->{'FOREIGN KEY'}->{'foreignTable'}"
		  . " ( $hash->{'FOREIGN KEY'}->{'foreignColumn'} ),\n"
		  . "\tUNIQUE ( id ),\n";
		$string .= $hash->{'mysql_special'}
		  if ( defined $hash->{'mysql_special'} );
	}
	elsif ( defined $hash->{'FOREIGN KEY'} ) {
		$string .=
		    "\tFOREIGN KEY ($hash->{'FOREIGN KEY'}->{'myColumn'}) "
		  . "References $hash->{'FOREIGN KEY'}->{'foreignTable'}"
		  . " ( $hash->{'FOREIGN KEY'}->{'foreignColumn'} ),\n"
		  . "\tUNIQUE ( $hash->{'FOREIGN KEY'}->{'myColumn'} ),\n";
		$string .= $hash->{'mysql_special'}
		  if ( defined $hash->{'mysql_special'} );
	}
	else {
		$string .= "\tconstraint prim_key PRIMARY KEY ( ID ),\n";
	}
	chop($string);
	chop($string);

	$string .= "\n)";
	my $temp;

# 	unless ( $hash->{'DISTRIBUTE BY'}
# 		|| ref( $hash->{'DISTRIBUTE BY'} ) eq "ARRAY" )
# 	{
# 		$temp = '';
# 		foreach my $key ( %$unique_columns ){
# 			$temp .= " $key," if ( $unique_columns->{$key} == @{ $hash->{'UNIQUES'} });
# 		}
# 		chop($temp);
#
# 		$string .= "DISTRIBUTE BY( $temp )"
# 		  if ( $temp =~ m/\w/ );
# 	}
# 	else {
# 		$string .=
# 		  "DISTRIBUTE BY (" . join( ", ", @{ $hash->{'DISTRIBUTE BY'} } ) . ")";
# 	}
	if ( defined $self->{'connection'}->{'add2craete'} ) {
		$string .= $self->{'connection'}->{'add2craete'} . ";";
	}
	$string .= ";\n";

	if ( ref( $hash->{'INDICES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'INDICES'} } ) > 0 )
	{
		warn ref($self) . " we have an index array\n" if ( $self->{'debug'} );
		foreach my $uniques_array ( @{ $hash->{'INDICES'} } ) {
			$temp = '';
			if ( ref($uniques_array) eq "ARRAY" && @$uniques_array > 0 ) {
				warn ref($self)
				  . " and we have the index values ("
				  . join( ", ", @$uniques_array ) . ")\n"
				  if ( $self->{'debug'} );
				$temp =
				    "CREATE INDEX ON "
				  . $self->TableName() . " ( "
				  . join( ", ", @$uniques_array ) . " );\n";
				$string .= $temp . "\n" unless ( $string =~ m/$temp/ );
			}
		}
	}
	return $string;
}

sub _construct_variableDef {
	my ( $self, $type, $variable ) = @_;

	$type = $self->{'connection'}->{'driver'} unless ( defined $type );

	my ($string);
	$string = '';
	unless ( ref($variable) eq "HASH" ) {
		$self->{error} .= ref($self)
		  . ":create_String -> each variable has to be a hash of values!\n";
		next;
	}
	unless ( defined $variable->{'name'} ) {
		$self->{error} .= ref($self)
		  . ":create_String -> the variable hash lacks an name entry!\n";
		next;
	}

	else {
		if ( $type eq "DB2" ) {
			$string .= "\t" . uc( $variable->{'name'} ) . " ";
		}
		else {
			$string .= "\t$variable->{'name'} ";
		}

	}

	unless ( defined $variable->{'type'} ) {
		Carp::confess(
			    ref($self)
			  . "::__construct_variableDef -> we have no variable type ($variable->{'type'})"
			  . " and therefore we can NOT generate the variable definition!\n"
		);
	}
	else {
		## we have to check, whether all supported database types support the same data types
		## here is the place to add some differences!
		if ( $variable->{'type'} eq "TEXT" ) {
			## DB2 does not support that! we have to declare that as CLOB
			if ( $type eq "DB2" ) {
				$string .= 'CLOB(65535) ';
			}
			else {
				$string .= 'TEXT ';
			}
		}
		elsif ( $variable->{'type'} eq 'TINYINT' ) {
			if ( $type eq "DB2" ) {
				$string .= 'SMALLINT ';
			}
			else {
				$string .= 'TINYINT ';
			}
		}
		elsif ( $variable->{'type'} eq "LONGTEXT" ) {
			## DB2 does not support that! we have to declare that as CLOB
			if ( $type eq "DB2" ) {
				$string .= 'CLOB(1073741823) ';
			}
			else {
				$string .= 'LONGTEXT ';
			}
		}
		elsif ( $variable->{'type'} =~ m/BOOLEAN/ ) {
			if ( $type eq "DB2" ) {
				$string .= 'SMALLINT ';
			}
			else {
				$string .= 'BOOLEAN ';
			}
		}
		elsif ( $variable->{'type'} =~ m/DATE/ ) {
			$string .= "VARCHAR(10) ";
		}
		elsif ( $variable->{'type'} =~ m/UNSIGNED/ ) {
			## This can only define an integer!!!!
			if ( $type eq "DB2" ) {
				$variable->{'type'} =~ s/UNSIGNED//;
				$string .= "$variable->{'type'} ";
			}
			else {
				$string .= "$variable->{'type'} ";
			}
		}
		else {
			$string .= "$variable->{'type'} ";
		}

	}
	unless ( $variable->{'NULL'} ) {
		$string .= "NOT NULL ";
	}
	$string .= ",\n";
}

sub _dropTable {
	my ( $self, $table_base_name ) = @_;

	my $sql = "DROP table " . $self->TableName($table_base_name);

	if ( $self->tableExists( $self->TableName($table_base_name) ) ) {

		$self->{dbh}->do($sql)
		  or Carp::confess(
			    ref($self)
			  . ":create -> we could not execute '$sql;'\n"
			  . $self->{dbh}->errstr() );
		$self->{'check_ok'} = 0;
	}

	if ( $self->{debug} ) {
		print ref($self), ":create -> we run $sql\n";
	}

	return 1;
}

=head2 create

This function is VERY dangerous, as it will drop existing tables!
If you need to do some other things - class specifically - you can overwrite the function
addInitialDataset(). This function will be executed with every create!

=cut 

sub create {
	my ( $self, $table_base_name ) = @_;

	## A DB2 CRETE STATEMENT:
	## CREATE TABLE DB_USER.TEST (
	##     ID BIGINT GENERATED ALWAYS AS IDENTITY,
	##     NAME VARCHAR (100)  NOT NULL ,
	##     TAG VARCHAR (20)  NOT NULL ,
	##     CONSTRAINT CC1253698510583 PRIMARY KEY ( ID) ,
	##     CONSTRAINT CC1253698521223 UNIQUE ( NAME)
	##  ) IN GENEXP_TS ;
	## COMMENT ON TABLE DB_USER.TEST IS 'just for test purpose';
	my ($sql);

	$self->_dropTable($table_base_name);

	if ( $self->{'connection'}->{'driver'} eq "mysql" ) {
		$sql = $self->create_String_mysql( $self->{'table_definition'} );
	}
	elsif ( $self->{'connection'}->{'driver'} eq "DB2" ) {
		$sql = $self->create_String_DB2( $self->{'table_definition'} );
	}
	else {
		Carp::confess(
			ref($self)
			  . " - variableTable -> we can not create a CREATE statement for this database driver '$self->{'connection'}->{'driver'}'\n"
		);
	}

	$self->{dbh}->do($sql)
	  or die ref($self),
	  ":create -> we have failed to execute $sql\n",
	  $self->{dbh}->errstr;

	$self->{__tableNames} = undef;
	$self->{'create_string'} = "$sql;";
	$self->addInitialDataset();
	return 1;
}

=head2 addInitialDataset

This function is called after the create table statement to insert some first datasets into the table.
It is used for all storage tables that have an empty list.

=cut

sub addInitialDataset {
	my ($self) = @_;
	return 1;
}

sub printReport {
	my ( $self, $further_dataHandlers, $filename_extension ) = @_;
	return $self->_getLinkageInfo()
	  ->Print( $further_dataHandlers, $filename_extension );
}

sub getDescription {
	my ( $self, $description ) = @_;
	$self->{'____description____'} = $description if ( defined $description );
	$self->{'____description____'} =
	    "please implement the function \\textbf{getDescription} in the class "
	  . ref($self)
	  . " to include a useful description of the class in this document!\n"
	  unless ( defined $self->{'____description____'} );
	return $self->{'____description____'};

}

sub create_SQL_statement {
	my ( $self, $hash ) = @_;
	my $linkage_info = $self->_getLinkageInfo();
	#print root::get_hashEntries_as_string ( $linkage_info , 5 , "the linkage info that is used to build up the SQL search:",100 );
	my $temp         = $linkage_info->create_SQL_statement($hash);
	$self->{'seletced_column_types'} = $linkage_info->{'seletced_column_types'};
	Carp::confess(
"The linkage info did send me a message - that will be the death penalty for the query '$temp'.\n"
		  . "the message = "
		  . $linkage_info->{'message'} )
	  if ( defined $linkage_info->{'message'} );
	return $temp;
}

sub LastSelect_Columns {
	my ( $self, $arrayRef ) = @_;
	if ( ref($arrayRef) eq "ARRAY" ) {
		$self->{'__lastColumnNames'} = $arrayRef;
	}
	elsif ( defined $arrayRef ) {
		Carp::confess(
			ref($self)
			  . ":LastSelect_Columns -> we can't handle that arrayRef: $arrayRef\n"
		);
	}
	return $self->{'__lastColumnNames'};
}

=head2 getArray_of_Array_for_search ( {
	'search_columns' => [],
	'where' => [ ['column_1', '<', 'column_2], ['column_3', '=', 'my_value] ],
	'complex_select' => 'RTFM',
	'order_by' => ['column_4'],
	'limit' => 'limit 10'
});

This function is the main data collector for my whole database interface. 
It creates a complex search uncluding all tables the actual table has connections to.
The functions automatically generates the SQL query using JOIN LEFT SQL statements.

In order to create those queries we need an hash with the following values:

=over 2

=item 'search_columns' An array of columnNames

The search columns has to be a list of column names, but one column name can either be the_pure_table_column_names, 
or the tables_handler_class_name.the_pure_table_column_name or the actual_table_name.the_pure_table_column_name.

=item 'where' An array ref of complex where clause(s)

A where clause is an array of three values. You can think of this array as a representation of  ['col_name' '=' 'value'].
At the moment, we support the connectors ( '=', '<', '>' ,'<=', '>=').
Both other parts of the equation can be either 

=over 2

=item - a bind value == the name of the column can NOT be found in the database structure

=item - a database column entry == the name of the column can be found in the database structure

The identification of column names is the same as for the 'search_columns' hash entry

=item - a small calculation that can be performed by the database

For this, the value has to be an array similar to the one described here, but the connectors can be one of ( '+', '-', '/' ,'*').
You have to take care, that this calculation can be performed!

=item an array of strings

This will be converted into a IN ( 'list_entry0', 'list entry 1', ... 'list entry n') SQL statement if the connector is '' (not defined).

=back

=item 'complex_select' An optional complex select statement

This complex select statement has to be given as reference to a scalar of the type 
"#1, #2, #3". The #X values will be substituted by the column names identified for the 'search_columns' entries.

=item 'order_by' a array of either column names or arrays, that in turn contain small sql calculation instructions

=back

In addition of that array the bind values need to be given.

The return values are the same as from DBI->fetchall_arrayref

=cut

sub getArray_of_Array_for_search {
	my ( $self, $hash, @bindValues ) = @_;

	#my ( $self, $sarch_columns, $where, $complex_select, @bindValues ) = @_;
	my $sth = $self->execute_for_search( $hash, @bindValues );
	my $return = $sth->fetchall_arrayref();

	my $sql = $self->{'complex_search'};

	#	print ref($self)
	#	  . ":getArray_of_Array_for_search we executed '$sql;' and we got "
	#	  . scalar(@$return)
	#	  . " results\n"
	#	  if ( $self->{'debug'} );
	$self->{'warn'} =
	  ref($self)
	  . ":getArray_of_Array_for_search did not get any return values for SQL query '$sql;'\n"
	  if ( !( ref( @$return[0] ) eq "ARRAY" ) && $self->{'debug'} );
	return $return;
}

=head2 get_data_table_4_search( {
	'search_columns' => [],
	'where' => [ ['column_1', '<', 'column_2], ['column_3', '=', 'my_value] ],
	'complex_select' => 'RTFM',
	'order_by' => ['column_4'],
	'limit' => 'limit 10'
});

The aruments of this function are the same as for getArray_of_Array_for_search.
This function will return a data_table object having the same column names as
you have specified in the search hash 'search_columns' array.

=cut

sub get_data_table_4_search {
	my ( $self, $hash, @bindValues ) = @_;

#Carp::confess ( "I did not get myselve as a hash! $self\n") if ( $self =~ m/action/);
	my $sth        = $self->execute_for_search( $hash, @bindValues );
	my $return     = $sth->fetchall_arrayref();
	my $data_table = data_table->new();
	$data_table->Add_db_result( $hash->{'search_columns'}, $return );
	return $data_table;
}

sub __dieOnError {
	my ($self) = @_;
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub GetType_4_varName {
	my ( $self, $varName ) = @_;
	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq $varName ) {
			return "digit" if ( $_->{'name'} eq 'id' );
			return "digit"
			  if ( "INTEGER UNSIGNED FLOAT DOUBLE TINYINT" =~ m/$_->{'type'}/ );
			return "char";
		}
	}
	return undef;
}

sub getArray_of_Hashes_for_search {
	my ( $self, $hash, @bindValues ) = @_;

	#my ( $self, $sarch_columns, $where, $complex_select, @bindValues ) = @_;
	my $sth = $self->execute_for_search( $hash, @bindValues );
	my $return = $sth->fetchall_hashref();

	my $sql = $self->{'complex_search'};
	foreach (@bindValues) {
		$sql =~ s/\?/$_/;
	}
	print ref($self)
	  . ":getArray_of_Array_for_search we executed '$sql;' and we got "
	  . scalar(@$return)
	  . " results\n"
	  if ( $self->{'debug'} );
	print ref($self)
	  . ":getArray_of_Array_for_search did not get any return values for SQL query '$sql;'\n"
	  unless ( ref( @$return[0] ) eq "HASH" );
	return $return;
}

sub execute_for_search {
	my ( $self, $hash, @bindValues ) = @_;
	$self->{"execute_complex_search"} = $self->{"complex_search"} = undef;

#print root::get_hashEntries_as_string ($hash, 3, "we try to create a search for this hash:");
	$self->{'complex_search'} = $self->create_SQL_statement($hash);

	#print ref($self)."::execute_for_search -> '$self->{'complex_search'};'\n";
	my ( $replacement, $columnType );
	foreach (@bindValues) {
		$replacement = $columnType = '';
		$self->{'complex_search'} =~ s/('?)\?'?/REPLACE-HERE/;
		$columnType = $1;

#print ref($self)."::execute_for_search - we identified the column type \"$columnType\"\n";

		if ( ref($_) eq "ARRAY" ) {

			if ( scalar(@$_) > 1 ) {
				my $temp;
				$temp =
				    "IN ($columnType"
				  . join( "$columnType, $columnType", @$_ )
				  . "$columnType)";
				$temp =~ s!\\!\\\\\\!g;
				$self->{'complex_search'} =~ s/= *REPLACE-HERE/$temp/;
			}
			else {
				$replacement = "$columnType@$_[0]$columnType";
				@$_[0] =~ s!\\!\\\\\\!g;
				$self->{'complex_search'} =~ s/REPLACE-HERE/$replacement/;

			}
		}
		else {
			$_ =~ s!\\!\\\\\\!g;
			$self->{'complex_search'} =~
			  s/REPLACE-HERE/$columnType$_$columnType/;
		}
	}

	#print ref($self)."::execute_for_search -> '$self->{'complex_search'};'\n";
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'complex_search' } );
	unless ( defined $self->{'Do_not_execute'} ) {
		unless ( $sth->execute() ) {
			Carp::confess(
				ref($self),
":getArray_of_Array_for_search -> we got a database error for query '",
				$self->_getSearchString('complex_search'),
				";'\n",
				root::get_hashEntries_as_string( $hash, 3,
					"the hash that lead to the creation of the search " )
				  . $self->{dbh}->errstr()
			);
		}
	}
	return $sth;
}

sub _getLinkageInfo {
	my ($self) = @_;
	## we need to create a hash of the structure:
	##{
	##	class_name  => ref($self),
	##	'variables' => { class.name => TableName.name },
	##	'links'     => { <join statement> => { this hash other class } }
	##}
	my $linkage_info = linkage_info->new();
	$linkage_info->ClassName( ref($self) );

	foreach my $variable ( @{ $self->{'table_definition'}->{'variables'} } ) {

		if ( defined $variable->{'data_handler'} ) {
			if (
				ref( $self->{'data_handler'}->{ $variable->{'data_handler'} } )
				eq "ARRAY" )
			{
				foreach my $dataHandler (
					@{
						$self->{'data_handler'}->{ $variable->{'data_handler'} }
					}
				  )
				{
					$linkage_info->myVariableName_linksTo_otherObj_id(
						$self,        $variable->{'name'},
						$dataHandler, $variable->{'link_to'}
					);
				}
			}
			else {
				$linkage_info->myVariableName_linksTo_otherObj_id(
					$self, $variable->{'name'},
					$self->{'data_handler'}->{ $variable->{'data_handler'} },
					$variable->{'link_to'}
				);
			}
		}
		else {
			$linkage_info->AddVariable( $self, $variable->{'name'} );
		}
	}
	return $linkage_info;
}

=head2 IDENTIFY_TASK_ON_DATASET

  Implement this function
  if you want to do some checks on the dataset . This is helpful,
  if the class can perform multiple AddDataset functions depending on the
	  values you get
	  . One example is the NimbleGeneArrays class
	  .

	  If errors occure during this process please add them to the \$self
	  ->{error} string !

=cut

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	$self->{'error'} .= ref($self) . "::DO_ADDITIONAL_DATASET_CHECKS \n"
	  unless (1);

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

=head2 Database

A method to set an recieve the database name from this class.

=cut

sub Database {
	my ( $self, $database_name ) = @_;
	$self->{'database_name'} = $database_name if ( defined $database_name );
	if ( defined $self->{'_propagateTableName_to'} ) {
		if ( ref( $self->{'_propagateTableName_to'} ) eq "ARRAY" ) {
			foreach ( @{ $self->{'_propagateTableName_to'} } ) {
				$_->Database($database_name);
			}
		}
	}
	return $self->{'database_name'};
}

=head2 Select_by_ID

This function utilizes the _select_all_for_DATAFIELD function to fetch the results for the PRIMARY KEY (id).

=cut

sub Select_by_ID {
	my ( $self, $data ) = @_;
	return $self->_select_all_for_DATAFIELD( $data, 'id' );
}

sub __match2_unique_constrains {
	my ( $self, $dataset ) = @_;
	return 0
	  unless (
		ref( $self->{'table_definition'}->{'do_unique_check'} ) eq "ARRAY" );

	my ( $sth, $rv, $unique_constrains, @values, @names, $var_name, $sql );
  MASTER:
	foreach $unique_constrains (
		@{ $self->{'table_definition'}->{'do_unique_check'} } )
	{
		@values = @names = ();
		$sql = '';
		next unless ( ref($unique_constrains) eq "ARRAY" );
		foreach $var_name (@$unique_constrains) {
			next MASTER unless ( defined $dataset->{$var_name} );
			push( @names,  $var_name );
			push( @values, $dataset->{$var_name} );
			$sql .= " $var_name = ? AND";
		}
		if ( defined $self->{ 'unique_search_' . join( "_", @names ) } ) {
			$sth = $self->{ 'unique_search_' . join( "_", @names ) };
		}
		else {
			$sql = "Select id FROM " . $self->TableName() . " WHERE " . $sql;
			$sql = substr( $sql, 0, length($sql) - 3 );

			#print ref($self)."::we are going to execute '$sql'\n";
			$sth = $self->{'dbh'}->prepare($sql)
			  or Carp::confess(
				ref($self)
				  . "::__check_unique_constrains -> we could not prepare the unique search '$sql'\n"
			  );
			$self->{ 'unique_search_' . join( "_", @names ) } = $sth;
		}
		if ( $rv = $sth->execute(@values) ) {

			#print "we have $rv matches for the query $sql ( @values ) \n";
			( $dataset->{'id'} ) = $sth->fetchrow_array();
			$self->{'warning'} .= "we have a unique match!\n";
			return 1 if ( defined $dataset->{'id'} && $dataset->{'id'} > 0 );
		}
	}
	return 0;
}

sub getActual_timestamp {
	my ($self) = @_;
	return DateTime::Format::MySQL->format_datetime(
		DateTime->now()->set_time_zone('Europe/Berlin') );
}

sub __escape_putativley_dangerous_things {
	my ( $self, $dataset ) = @_;
	foreach my $tag ( keys %$dataset ) {
		$dataset->{$tag} =~ s/\\\\/\\/g;
		$dataset->{$tag} =~ s/'/\\'/g;
		$dataset->{$tag} =~ s/\\\\'/\\'/g;
	}
	return 1;
}

sub _mysql_now_{
	my ( $self, ) = @_;
	return DateTime::Format::MySQL->format_datetime(
				DateTime->now()->set_time_zone('Europe/Berlin') );
}

sub check_dataset {
	my ( $self, $dataset ) = @_;

	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	my ( $className, $refered_dataset, $id_str );
	$self->{error} = $self->{warning} = '';
	$self->{error} .=
	  ref($self) . ":check_dataset -> we do not have a dataset to check!\n"
	  unless ( defined $dataset );
	unless ( ref($dataset) eq "HASH" ) {
		Carp::confess(
			ref($self)
			  . ":check_dataset -> the dataset $dataset is not an hash!\n" );
	}
	$self->__escape_putativley_dangerous_things($dataset);

	if ( defined $dataset->{'id'} ) {
		return 1 if ( $self->{'already_checked_ids'}->{ $dataset->{'id'} } );
		my $data = $self->_select_all_for_DATAFIELD( $dataset->{'id'}, "id" );

#warn root::get_hashEntries_as_string ($data, 3, "I got the results for the query for  \$self->_select_all_for_DATAFIELD( $dataset->{'id'}, 'id' ) ");
		foreach my $exp (@$data) {
			if ( $exp->{'id'} == $dataset->{'id'} ) {
				$self->{'already_checked_ids'}->{ $dataset->{'id'} } = 1;
				return 1;
			}
		}
		Carp::confess(
			ref($self)
			  . "::check_dataset -> I do not know why, but we have not identified our ID $dataset->{'id'} in the database!\n"
		) unless ( $dataset->{'id'} == 0 );
		$dataset->{'id'} = undef;
	}

	return 0 unless ( $self->DO_ADDITIONAL_DATASET_CHECKS($dataset) );

	return 1 if ( defined $dataset->{'id'} );
	if ( $self->isa('materialList') ) {
		return 1 if ( defined $dataset->{'list_id'} );
	}

 #	print ref($self)
 #	  . "::check_dataset we did not find the the unique entry in the database \n"
 #	  . root::get_hashEntries_as_string( $self->{'UNIQUE_KEY'}, 3,
 #		"The unique array " )
 #	  . "using the serach $self->{'comples_search'}\n"
 #	  . root::get_hashEntries_as_string( $dataset, 3,
 #		"and finally using the dataset $dataset" )
 #	  if ( $self->{'debug'} );

	if ( $self->__match2_unique_constrains($dataset) ) {
		warn ref($self) . "::The dataset was found in the table\n";
		unless ( $self->{'error'} =~ m/\w/ ) {
			## we have enough data to try to search for a unique entry!
			print ref($self)
			  . ":check_dataset -> we try to search for a unique entry!\n"
			  if ( $self->{'debug'} );
			$dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset);
			return 1 if ( defined $dataset->{'id'} );
		}
	}
	if ( $dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset) ) {
		return 1;
	}
	print Carp::cluck(
		root::get_hashEntries_as_string(
			$dataset, 3,
			ref($self) . "::check_dataset we did not find the id\n"
		)
	) if ( $self->{'debug'} );
	$self->{'error'} = '';

	$self->{error} .=
	  ref($self)
	  . ":check_dataset -> we do not have a table_definition in this class!\n"
	  unless ( ref( $self->{'table_definition'} ) eq "HASH" );

	#warn ref($self)."we check the datastet\n";
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next
		  if ( $value_def->{'name'} eq "id" )
		  ;    ## that thing should not be defined here!
		$className = $value_def->{'name'};
		if ( $className eq "table_baseString" ) {
			next;
		}
		elsif ( $className eq "md5_sum" ) {
			$self->_create_md5_hash($dataset);
		}
		elsif ( $value_def->{'type'} eq "TIMESTAMP"
			&& !defined $dataset->{$className} )
		{
			## I suppose you mean the actual time here....
			#warn "\n\nwe create a timestamp!\n";
			#if ( $self->{'connection'}->{'driver'} eq "mysql"){
			$dataset->{$className} =
			  DateTime::Format::MySQL->format_datetime(
				DateTime->now()->set_time_zone('Europe/Berlin') );
		}
		elsif (
			$value_def->{'type'} eq "DATE"
			&& !(
				defined $dataset->{$className}
				|| $dataset->{$className} =~ m/\d{4}-\d{2}-\d{2}/
			)
		  )
		{
			$dataset->{$className} = root::Today();

#Carp::confess( "DEBUG:: we got a DATE column $className with the value ($className) = $dataset->{$className}");
		}
		if ( defined $value_def->{'data_handler'} ) {
			next if ( $value_def->{'NOT_AddDataset'} );
			unless (
				defined(
					$self->{'data_handler'}->{ $value_def->{'data_handler'} }
				)
			  )
			{
				Carp::confess(
					ref($self)
					  . " we miss the data_handler object for variable $value_def->{'name'} and handler name $value_def->{'data_handler'}\n"
				);
			}
			next
			  if ( $self->{'data_handler'}->{ $value_def->{'data_handler'} }
				->isa('basic_list') );
			if ( $value_def->{'NULL'} ) {
				$dataset->{ $value_def->{'name'} } = 0
				  unless ( defined $dataset->{ $value_def->{'name'} } );
				next if ( $dataset->{ $value_def->{'name'} } == 0 );
			}
			$className =~ s/_id//;
			if ( defined $dataset->{ $value_def->{'name'} }
				&& $dataset->{ $value_def->{'name'} } > 0  )
			{
				if ( ref( $dataset->{$className} ) eq "ARRAY" && $self->{'data_handler'}->{ $value_def->{'data_handler'} }
				->isa('basic_list') ){
					## OK I need to add a new list entry - crap but has to be done!
#					$dataset->{$className."_id"} = $self->{'data_handler'}->{ $value_def->{'data_handler'}} -> AddDataset ( $dataset->{$className} );
#					warn "\n\nwe have added a list\n\n";
#					$dataset->{$className} = { 'id' => $dataset->{$className."_id"}  };
					next;
				}
				elsif ( $self->{'data_handler'}->{ $value_def->{'data_handler'} }
				->isa('basic_list')){
					Carp::confess ( "I have an issue with the basic_list data hash '$className' - it is not an array and hence I can not process it!\n");
				}
				## Oh - could it be possible that we already have all we need?
				$id_str = 'id';
				$id_str = $value_def->{'link_to'} if ( defined $value_def->{'link_to'});
				
				$refered_dataset =
				  $self->{'data_handler'}->{ $value_def->{'data_handler'} }
				  ->{'dbh'}->selectrow_hashref( 'Select * from '
					  . $self->{'data_handler'}
					  ->{ $value_def->{'data_handler'} }->TableName()
					  . " where $id_str = $dataset->{$value_def->{'name'}}" );
				unless ( ref($refered_dataset) eq "HASH" ) {
					$self->{'error'} .=
					  "Sorry, but the table "
					  . $self->{'data_handler'}
					  ->{ $value_def->{'data_handler'} }->TableName()
					  . " does not contain a dataset with the id '$dataset->{ $value_def->{'name'}}'\n";
					next;
				}
				if ( ref( $dataset->{$className} ) eq "HASH" ) {
					foreach ( keys %{ $dataset->{$className} } ) {
						$self->{'error'} .=
						  ref($self)
						  . " - mismatch for handled dataset: '$className'->{$_}: $dataset->{$className}->{$_} != DB value $refered_dataset->{$_}\n"
						  unless ( $dataset->{$className}->{$_} eq
							$refered_dataset->{$_} );
					}
				}
				next;
			}
			## OK if we come here you have not defined the ID, 
			## hence we might need to create the downstream table line!
			if ( ref( $dataset->{$className} ) eq "HASH" ){
				$dataset->{$className."_id"} = $self->{'data_handler'}->{ $value_def->{'data_handler'} }
				->AddDataset( $dataset->{$className});
				unless ( defined $dataset->{$className."_id"} && $dataset->{$className."_id"} > 0 ){
					$self->{'error'} .= root::get_hashEntries_as_string ( $dataset->{$className}, 3, ref($self).' - we tried to create a table entry in the table '.$self->{'data_handler'}
					  ->{ $value_def->{'data_handler'} }->TableName(). " , but we did not get an id for the data hash" );
					 $self->{'error'} .=  $self->{'data_handler'}
					  ->{ $value_def->{'data_handler'} }-> {'error'};
				}
			}


			else {
				
					$self->{error} .=
					    ref($self)
					  . ":check_dataset -> I would expect to find either the variable $className"
					  . "_id or the variable $className to be an hash and not '$dataset->{$className}'\n";
			}
		}
		else {
			$self->{error} .=
			  ref($self)
			  . ":check_dataset -> the data for key '$className' is missing!\n"
			  if ( !defined $dataset->{$className} && !$value_def->{'NULL'} );
			if (   ref( $self->{'restrictions'} ) eq "HASH"
				&& ref( $self->{'restrictions'}->{ $value_def->{'name'} } ) eq
				"HASH" )
			{
				$self->{error} .=
				  ref($self)
				  . ":check_dataset -> the data '$dataset->{$className}' for key '$className' is not supported!\n"
				  unless ( $self->{'restrictions'}->{ $value_def->{'name'} }
					->{ $dataset->{$className} } );
			}
		}
	}

	$className =
	  $self->GET_entries_for_UNIQUE( [ ref($self) . '.id' ], $dataset );

	if ( ref($className) eq "HASH" && defined $className->{'id'} ) {
		$dataset->{'id'} = $className->{'id'};
		return 1;
	}
	$self->changes_after_check_dataset($dataset);
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub changes_after_check_dataset {
	my ( $self, $dataset ) = @_;
	return 1;
}

=head2 INSERT_INTO_DOWNSTREAM_TABLES

This function is called each time AddDataset is executed, prior to the addition of the dataset to the table.
You could add a functionallity here, that creates an additional value for the insert statement.

Originally this function was implemented, because of the reference to another table, e. g. in the emperiment table.

If you want to insert data after the INSERT statement in this table, then take the post_INSERT_INTO_DOWNSTREAM_TABLES
function.

The function adds to \$self->{error}.

Return value == boolean. If NOT is returned, the AddDataset dies printing the \$self->{error} value.

=cut

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1;
}

=head2 post_INSERT_INTO_DOWNSTREAM_TABLES

This function is called each time AddDataset is executed, AFTER to the addition of the dataset to the table.
Here you should add program structure, that handles adding data into dependant tables. In contrast to INSERT_INTO_DOWNSTREAM_TABLES
this function has additional knowledge about the latest inserted id.

Originally this function was implemented, because the gbFeatureTable needs to add the gbFeatures into another table 
and these gbFeatures need the gbFiles ID that is generated during the insert into this table.

The function adds to \$self->{error}.

Return value == boolean. If NOT is returned, the AddDataset dies printing the \$self->{error} value.


=cut

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1;
}

sub update_structure {
	my ($self) = @_;
	return 1 if ( $self->isa('basic_list') );
	my $sth =
	  $self->{'dbh'}
	  ->prepare( "SELECT * FROM " . $self->TableName() . " where id < 10" );
	$sth->execute;
	my $hash   = $sth->fetchrow_hashref();
	my @fields = ( keys %$hash );
	if ( scalar(@fields) == 0 ) {
		return 1;
	}
	my $columns;
	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$columns->{ $_->{'name'} } = $_;
	}
	my ( $str, $error ) = ( '', '' );

	foreach my $colName (@fields) {

		#$str .= "we got the column '$colName' from the database\n";
		unless ( defined $columns->{$colName} ) {
			next if ( $colName eq "id" );
			next if ( $colName eq "others_id" );
			## OH OH - we need to drop that column!!!
  # $self->{'dbh'}-> do ( 'alter table '.$self->TableName().' drop '.$colName );
			$error .=
			  'alter table ' . $self->TableName() . ' drop ' . $colName . "\n";
			next;
		}

#$str .= "we should have deleteed the column '$colName' from our check hash!\n";
		delete $columns->{$colName};
	}
	foreach ( values %$columns ) {
		my $col_def = $self->_construct_variableDef( undef, $_ );
		$col_def =~ s/\t/ /g;
		$col_def =~ s/,//g;
		my $rv =
		  $self->{'dbh'}->do(
			"alter table " . $self->TableName() . " add column " . $col_def );
		if ( $self->{'dbh'}->errstr() =~ m/\w/ ) {
			Carp::confess(
"we could not create a new column $_->{'name'} using the sql str:'"
				  . "alter table "
				  . $self->TableName()
				  . " add column $col_def \nThe error: "
				  . $self->{'dbh'}->errstr() );
		}
		$str .=
"we had to create the column $_->{'name'} using this statement:\nalter table "
		  . $self->TableName()
		  . " add column $col_def\n";
	}
	$sth->finish;
	Carp::confess( "Please ask an DB admin to modify the database table "
		  . $self->TableName()
		  . "\n$error" )
	  if ( $error =~ m/\w/ );
	Carp::confess($str) if ( $str =~ m/\w/ );
	return 1;
}

=head2 UpdateDataset

This function can only be used to update the variables in this table.
It will not accept recursive datasets!

In addition you have to provide an hash of data with the keys resembling 
the columns that you want to change, together with a 'id' key, 
that will not be changed, but will be the query string.
The update sql will look like that:
'Update table 'name' set $key = $value ... where id = $dataset->{'id'};

=cut

sub UpdateDataset {
	my ( $self, $dataset ) = @_;

	$self->{'error'} .=
	  ref($self)
	  . "::UpdateDataset - I do not know which dataset to update - I have not got an id\n"
	  unless ( defined $dataset->{'id'} );

	$self->__escape_putativley_dangerous_things($dataset);

	my $sql = "UPDATE " . $self->TableName() . " SET ";
	foreach my $key ( keys %$dataset ) {
		next if ( $key eq "id" );
		$sql .= "$key = '$dataset->{$key}' ,";
	}
	chop($sql);
	$sql .= " WHERE id = $dataset->{id}";
	Carp::confess(
		    ref($self)
		  . "::UpdateDataset -> we could not update the table line $dataset->{id} unsing this sql query:\n $sql;\n"
		  . root::get_hashEntries_as_string( $dataset, 3,
			"Using this dataset " )
		  . "and the erroe was:\n"
		  . $self->{'dbh'}->errstr() )
	  unless ( $self->{'dbh'}->do($sql) );
	$self->{'complex_search'} = $sql;
	if ( ref( $self->{'Group_to_MD5_hash'} ) eq "ARRAY"
		&& !defined $dataset->{'md5_sum'} )
	{
		my @search_columns = ( ref($self) . ".id" );
		foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
			push( @search_columns, ref($self) . "." . $_->{'name'} );
		}
		my $new_dataset = $self->get_data_table_4_search(
			{
				'search_columns' => \@search_columns,
				'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ],
			},
			$dataset->{'id'}
		)->get_line_asHash(0);
		$dataset = {};
		my @temp;
		foreach ( keys %$new_dataset ) {
			@temp = ( $_, ref($self) . "." );
			$temp[0] =~ s/$temp[1]//;
			$dataset->{ $temp[0] } = $new_dataset->{$_};
		}
		$dataset->{'md5_sum'} = undef;
		$self->_create_md5_hash($dataset);
		$self->UpdateDataset(
			{ 'id' => $dataset->{'id'}, 'md5_sum' => $dataset->{'md5_sum'} } );
	}
	return $dataset->{'id'};
}

=head2 Add_2_list

This function can handle list connections. 

Arguments:
'my_id'		the id, where the list should be updated
'var_name'	the name of the list_variable
'other_ids'	an array of other ids

In order to work, the data handler of the variable 'var_name' has to implement the 'basic_list'.
We do:
1. get the list_id for this dataset - if it is '0', then we will get a new list id from the list_table_object
2. use the list_object to add the links
3. update our entry to contain the old/new list id
4. return 1

=cut

sub Add_2_list {
	my ( $self, $hash ) = @_;
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$hash, 3,
			"::Add_2_list -> we need an my_id hash-entry - not only this:"
		  )
	) unless ( defined $hash->{'my_id'} );
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$hash, 3,
			"::Add_2_list -> we need an var_name hash-entry - not only this:"
		  )
	) unless ( defined $hash->{'var_name'} );
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$hash,
			3,
"::Add_2_list -> we need an array of other_ids hash-entry - not only this:"
		  )
	) unless ( ref( $hash->{'other_ids'} ) eq "ARRAY" );

	my ( $dataline, $dbObj, $temp );
	## 1
	$dataline = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".$hash->{'var_name'}" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$hash->{'my_id'}
	)->get_line_asHash(0);
	Carp::confess(
		    ref($self)
		  . "::Add_2_list -> we do not have a table entry for"
		  . $self->TableName()
		  . ".id = $hash->{'my_id'}!\n" )
	  unless ( defined $dataline );
	## 2
	foreach my $var_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$dbObj = $self->{'data_handler'}->{ $var_def->{'data_handler'} }
		  if ( $var_def->{'name'} eq $hash->{'var_name'} );
	}
	Carp::confess(
		ref($self)
		  . "::Add_2_list -> sorry, but the dbObj $dbObj is no basic_list!\n" )
	  unless ( ref($dbObj) =~ m/\w/ && $dbObj->isa('basic_list') );

	if ( $dataline->{ ref($self) . ".$hash->{'var_name'}" } == 0 ) {

#Carp::confess( "we would now create a new $hash->{'var_name'} column value for the ".ref($self).".id =  $hash->{'my_id'}\n");
		$dataline                          = {};
		$dataline->{ $hash->{'var_name'} } = $dbObj->readLatestID() + 1;
		$dataline->{'id'}                  = $hash->{'my_id'};
		## 3
		$self->UpdateDataset($dataline);
	}
	else {
		$temp     = $dataline->{ ref($self) . ".$hash->{'var_name'}" };
		$dataline = {};
		$dataline->{ $hash->{'var_name'} } = $temp;
		$dataline->{'id'} = $hash->{'my_id'};
	}

#Carp::confess( "we would now create a new $hash->{'var_name'} column value for the ".ref($self).".id =  $hash->{'my_id'}\n");
	foreach my $other_id ( @{ $hash->{'other_ids'} } ) {
		next unless ( defined $other_id );

#Carp::confess ( "and now we try to add a link to ".ref($dbObj). " between the list_id ".$dataline->{ $hash->{'var_name'} }. " and the data id $other_id\n");
		$dbObj->add_to_list(
			$dataline->{ $hash->{'var_name'} },
			{ 'id' => $other_id },
			$hash->{'var_name'}
		);
	}
	## 4
	return 1;

}

=head2 AddDataset

The function expects an hash of values that should be inserted into the table. 
The keys of the hash have to be the column titles of the table.
The whole table structure is stored in the \$self->{'table_definition'} hash.
THis hash can be created from a normal MySQL CREATE TABLE statement using the command line tool 'create_hashes_from_mysql_create.pl'
that comes with this package.

If a column is a link to an other table, then the Perl classes expect that the column name ends on \textit{\_id}. 
The data for this column is ment to be stored in a hash\_key with the name of the column without the \textit{\_id}.
This value on runtime added to the other table using the \textbf{AddDataset} function of that class.

Values that are of type 'TIMESTAMP' will be created upon call of this function using the library call
"DateTime::Format::MySQL->format_datetime(DateTime->now()->set_time_zone('Europe/Berlin') );" ONLY IF THEY ARE UNDEFINED.

Variables named 'table_baseString' are never checked during a AddDataset call. Instead, the whole function will die if they are not present at inster time.
Please implement the function 'INSERT_INTO_DOWNSTREAM_TABLES' for each table that contains a 'table_baseString' entry!

=cut

sub AddDataset {
	my ( $self, $dataset ) = @_;

	unless ( ref($dataset) eq "HASH" ) {
		Carp::confess(
			ref($self)
			  . ":AddDataset -> didn't you want to get a result?? - we have no dataset to add!!\n"
		);
		return undef;
	}
	;    ## perhaps this value is not needed for the downstream table...
	Carp::confess(
		$self->{error}
		  . root::get_hashEntries_as_string(
			$dataset, 3, "the problematic dataset:"
		  )
	) unless ( $self->check_dataset($dataset) );
	## did thy only want to look for a thing?
	return $dataset->{'id'} if ( defined $dataset->{'id'} );

	$self->_create_insert_statement();
	Carp::confess $self->{error}
	  unless ( $self->INSERT_INTO_DOWNSTREAM_TABLES($dataset) );

	## do we already have that dataset
	my $id = $self->_return_unique_ID_for_dataset($dataset);
	if ( defined $id ) {
		return $dataset->{'id'} = $id;
	}

	if ( $self->{'debug'} ) {
		print ref($self),
		  ":AddConfiguration -> we are in debug mode! we will execute: '",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n";
	}
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
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
			  . "\nand the last search for a unique did not return the expected id!'$self->{'complex_search'}'\n"
			  . root::get_hashEntries_as_string(
				$self->_get_search_array($dataset), 3,
				"Using the search array: "
			  )
		);
	}
	$self->{'last_insert_stm'} =
	  $self->_getSearchString( 'insert',
		@{ $self->_get_search_array($dataset) } );
	unless ( @{ $self->{'UNIQUE_KEY'} }[0] eq "id" ) {
		$id = $dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset);
	}
	else {
		## FUCK - that is not OK - we read our last ID...
		$id = $dataset->{'id'} = $self->readLatestID();
	}
	Carp::confess(
"We have not gotten the id using the last search $self->{'complex_search'}\n"
	) unless ( defined $id );

	## we might be a really dump package storing things without a unique we could search for  - that would be horrible!
	$self->post_INSERT_INTO_DOWNSTREAM_TABLES( $id, $dataset );
	if ( $self->{'error'} =~ m/\w/ ) {
		Carp::croak(
			ref($self)
			  . "::AddDataset -> we have an error from post_INSERT_INTO_DOWNSTREAM_TABLES:\n$self->{'error'}"
		);
		$self->_delete_id($id) if ( $self->{'error'} =~ m/\w/ );
	}

	return $id if ( defined $id );
	my $searchArray = $self->_get_unique_search_array($dataset);

	Carp::confess(
		root::get_hashEntries_as_string(
			$dataset,
			4,
			ref($self)
			  . ":_return_unique_dataset -> we got no result for query '"
			  . $self->_getSearchString( 'select_unique_id', @$searchArray )
			  . ";'\nwe used this searchArray: @$searchArray\n"
			  . ref($self)
			  . ":AddDataset -> we could not get a id for the dataset using the search:\n$self->{'complex_search'}; \nand the dataset "
			  . root::get_hashEntries_as_string( $dataset, 3, "" )
			  . " our last insert statement was $self->{'last_insert_stm'}\n"
		)
	);
	return undef;
}

sub _delete_id {
	my ( $self, $id ) = @_;
	$self->{'delete_id'} =
	  "delete from " . $self->TableName() . " where id = ?";
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'delete_id' } );
	unless ( $sth->execute($id) ) {
		die ref($self),
		  ":_delete_id -> we got a database error for query '",
		  $self->_getSearchString( 'delete_id', $id ), ";'\n",
		  $self->{dbh}->errstr();
	}
	return 1;
}

sub readLatestID {
	my ($self) = @_;
	my ( $sql, $sth, $rv );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.id' ],
			'where'          => [],
			'order_by'       => [ [ 'my_value', '-', ref($self) . '.id' ] ],
			'limit'          => "limit 1"
		}
	)->get_line_asHash(0);
	return undef unless ( ref($data) eq "HASH" );
	return $data->{ $self->TableName() . '.id' };
}

sub delete_entry {
	my ( $self, $dataset ) = @_;
	unless ( ref($dataset) eq "HASH" ) {
		warn ref($self)
		  . "::delete_entry -> we need an hash to identify our entry\n";
		return undef;
	}
	my $id = _return_unique_ID_for_dataset($dataset);
	unless ( defined $id ) {
		warn ref($self)
		  . "::delete_entry -> we can only delete defined ids - not a set of table entries!\n";
		return undef;
	}
	return $self->{'dbh'}
	  ->do( "delete from " . $self->TableName() . " where id = $id" );
}

sub _return_unique_ID_for_dataset {
	my ( $self, $dataset ) = @_;

   #return undef if ( scalar(@{$self->{'UNIQUE_KEY'}}) == 0 );
   #	warn "we have the uniwue array ".join( ", ",@{$self->{'UNIQUE_KEY'}})."\n";
	Carp::confess(
"please identify where you have messed up the scipt as I did not get an object as self!\n"
	) unless ( ref($self) =~ m/\w/ );
	my $searchArray = $self->_get_unique_search_array($dataset);
	my @temp;
	foreach ( my $i = 0 ; $i < @$searchArray ; $i++ ) {
		if ( ref( @$searchArray[$i] ) eq "ARRAY" ) {
			push( @temp, @{ @$searchArray[$i] }[0] );
		}
		else {
			push( @temp, @$searchArray[$i] );
		}
	}

	my $where = [];
	foreach my $column ( @{ $self->{'UNIQUE_KEY'} } ) {
		unless ( $column =~ m/\./ ) {
			push( @$where,
				[ $self->TableName() . "." . $column, '=', 'my_value' ] );
		}
		else {
			push( @$where, [ $column, '=', 'my_value' ] );
		}
	}
	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ $self->TableName() . '.id' ],
			'where'          => $where
		},
		@temp
	);
	unless ( ref( @$rv[0] ) eq "ARRAY" ) {
		$self->{'warning'} = "we could not identify the id with this search:"
		  . $self->{'complex_search'} . "\n";
		return undef;
	}

#$self->{'warning'} = "we identified the id ".@{ @$rv[0] }[0]." using the query $self->{'complex_search'}\n";
	return @{ @$rv[0] }[0];
}

sub _get_unique_search_array {
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';

	my ( @data_values, $className, $use, $uniques );
	## now we might have some complex datasets!
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$className = $value_def->{'name'};

		## now we have to check, whether we have a $self->{'UNIQUE_KEY'}
		$use = 0;
		foreach $uniques ( @{ $self->{'UNIQUE_KEY'} } ) {
			$use = 1 if ( $uniques eq $className );
		}
		if ($use) {    ## we need to identify a value for the column!
			## md5_sums can be created!
			$self->_create_md5_hash($dataset)
			  if ( $className eq "md5_sum"
				&& !defined $dataset->{'md5_sum'} );
			## timestams can be created
			if ( $value_def->{'type'} eq "TIMESTAMP"
				&& !defined $dataset->{$className} )
			{
				$dataset->{$className} =
				  DateTime::Format::MySQL->format_datetime(
					DateTime->now()->set_time_zone('Europe/Berlin') );
			}
			## and dates should also be no problem!
			if ( $value_def->{'type'} eq "DATE" ) {
				unless ( defined $dataset->{$className} ) {
					$dataset->{$className} = root::Today();
					$dataset->{$className} = "$dataset->{$className}";
				}
				elsif ( ref( $dataset->{$className} ) eq "ARRAY"
					&& !defined @{ $dataset->{$className} }[0] )
				{
					@{ $dataset->{$className} }[0] = root::Today();
				}

			}
			## Now we are at the position, where we want to store the data!
			if ( defined $dataset->{$className}
				&& ref( $dataset->{$className} ) eq "" )
			{
				push( @data_values, $dataset->{$className} );
			}
			elsif ( defined $dataset->{$className}
				&& ref( $dataset->{$className} ) eq "ARRAY" )
			{
				push( @data_values, [ @{ $dataset->{$className} } ] );
			}
			elsif ( defined $value_def->{'data_handler'} ) {
				$className =~ s/_id//;
				next if ( $className eq "id" );
				$dataset->{ $className . "_id" } =
				  $self->{'data_handler'}->{ $value_def->{'data_handler'} }
				  ->AddDataset( $dataset->{$className} )
				  if ( defined $dataset->{$className} );
				if ( $dataset->{ $className . "_id" } > 0 ) {
					push( @data_values, $dataset->{ $className . "_id" } );
				}
				else {
					$self->{'warning'} .=
					    ref($self)
					  . ":_get_unique_search_array: sorry, but we could not get a usable value for $className"
					  . "_id\n";
				}

			}
			else {
				$self->{'warning'} .=
				    ref($self)
				  . ":_get_unique_search_array: sorry, but we could not get a usable value for $className ($dataset->{$className}; "
				  . ref( $dataset->{$className} ) . ")" . "\n";
			}
		}
	}

#	Carp::confess(
#		    ref($self)
#		  . "::_get_unique_search_array we have some HEAVY problems: \n$self->{'warning'}"
#		  . root::get_hashEntries_as_string(
#			$dataset, 3, "analyzing the datahash "
#		  )
#	) if ( $self->{'warning'} =~ m/\w/ );
	return \@data_values;
}

sub _create_unique_search {
	my ( $self, $return_values ) = @_;

	die ref($self)
	  . ":_create_unique_search -> we need a \$self->{'UNIQUE_KEY'} dataset to check for duplicates!\n"
	  unless ( ref( $self->{'UNIQUE_KEY'} ) eq "ARRAY" );
	my $where = [];
	foreach my $column ( @{ $self->{'UNIQUE_KEY'} } ) {
		push( @$where, [ $column, '=', 'my_value' ] );
	}
	my $sql = $self->create_SQL_statement(
		{
			'search_columns' => ['id'],
			'where'          => $where,
		}
	);

#	if ( ref($return_values) eq "ARRAY" ) {
#		$sql =
#		    "SELECT "
#		  . join( ", ", @$return_values )
#		  . " FROM "
#		  . $self->TableName()
#		  . " where ";
#	}
#	else {
#		$self->{error} .= ref($self)
#		  . ":_create_unique_search -> we do not know which columns to select\n";
#	}
#	my $first = 1;
#	foreach my $value ( @{ $self->{'UNIQUE_KEY'} } ) {
#		if ($first) {
#			$sql .= " $value = ?";
#			$first = 0;
#		}
#		else {
#			$sql .= " AND $value = ?";
#		}
#
#	}
#	Carp::confess ( "PLEASE REMOVE THAT LINE ONCE THE ERROR IS FIXED!\n$return_values\n")
#	unless (ref ($return_values) eq "ARRAY" );
	$self->{ 'select_unique_' . join( "_", @$return_values ) } = $sql;
	return $sql;
}

sub _confess_insert_errors {
	my ( $self, $insert_type, @bind_vars ) = @_;
	Carp::confess( ref($self),
		    ":AddDataset -> we were unable to execute "
		  . $self->_getSearchString( $insert_type, @bind_vars ) . "\n"
		  . $self->{dbh}->errstr() );
}

sub _create_insert_statement {
	my ( $self, @notAddedColumns ) = @_;
	my $key = 'insert' . join( "_", @notAddedColumns );

	#return $self->{$key} if ( defined $self->{$key} );

	my ( $values, $className, $notAdd );
	## now we might have some complex datasets!
	$self->{$key} = 'insert into ' . $self->TableName() . " (";
	$values = '';
	if ( ref( $self->{'table_definition'}->{'FOREIGN KEY'} ) eq "HASH" ) {
		## if we have a db2 foreigne key - as in this class,
		## we have to create the id not as an autoincremented key, but as a foreign key.
		## as this table is generated as beeng as lean as possible and in addition
		## will ALWAYS have a 1:1 link between the foregn key and the internal key,
		## we have to change the insert statement the way, that we add the id as inserted value!
		## but that of cause ONLY if we are communicating with a DB2 database
		if ( $self->{'connection'}->{'driver'} eq "DB2" ) {
			$self->{$key} .= 'id, ';
			$values .= " ?,";
		}

	}
	## we might not want to add all columns to the insert statement
	if ( defined $notAddedColumns[0] ) {
		$notAdd = join( " ", @notAddedColumns );
	}
	else { $notAdd = ' ' }

	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next if ( $notAdd =~ m/$value_def->{'name'}/ );
		next if ( $value_def->{'name'} eq "id" );
		$self->{$key} .= " " . $value_def->{'name'} . ",";
		$values .= " ?,";
	}
	chop( $self->{$key} );
	chop($values);
	$self->{$key} .= " ) values ( $values )";
	return $self->{$key};
}

sub _create_select_all_for_DATAFIELD {
	my ($self) = @_;

#print ref($self)."::_create_select_all_for_DATAFIELD we have a table name = ".$self->TableName() . " (self = $self)\n";
	$self->{'select_all_for_DATAFIELD'} =
	  "select * from " . $self->TableName() . " where DATAFIELD = ?";

#print ref($self)."::_create_select_all_for_DATAFIELD we created '$self->{'select_all_for_DATAFIELD'}'\n";
}

=head2 GET_entries_for_UNIQUE

This function expects two variables, an array of column titles to select and a dataset hash as it is used with the AddDataset function.
It returns an hash that is created using the DBI::fetchrow_hashref function.

=cut

sub GET_entries_for_UNIQUE {
	my ( $self, $entries, $unique_dataset ) = @_;

	if ( defined $unique_dataset->{'id'} ) {
		## the id is the primaly key - that should be a pice of cake!
		my $data = $self->Select_by_ID( $unique_dataset->{'id'} );
		print root::get_hashEntries_as_string (
			@$data[0], 2,
			ref($self) . ":GET_entries_for_UNIQUE -> we get a result for 'id'"
		) if ( $self->{'debug'} );
		return $unique_dataset->{'id'};
	}

	$self->create() unless ( $self->tableExists( $self->TableName ) );
	$unique_dataset->{'id'} =
	  $self->_return_unique_ID_for_dataset($unique_dataset);

	my $where = [];
	foreach my $columns ( @{ $self->{'UNIQUE_KEY'} } ) {
		unless ( $columns =~ m/\./ ) {
			push( @$where, [ ref($self) . "." . $columns, '=', 'my_value' ] );
		}
		else {
			push( @$where, [ $columns, '=', 'my_value' ] );
		}
	}
	my $uniques_array = $self->_get_unique_search_array($unique_dataset);
	my $data          = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [@$entries],
			'where'          => $where
		},
		@$uniques_array
	);

	my $return = @$data[0];
	unless ( ref($return) eq "ARRAY" ) {
		warn ref($self)
		  . ":GET_entries_for_UNIQUE we got no search result for \n"
		  . $self->_getSearchString( 'complex_search', @$uniques_array ), ";'\n"
		  if ( $self->{'debug'} );
	}
	my $ret = {};
	for ( my $i = 0 ; $i < @$entries ; $i++ ) {
		$ret->{ @$entries[$i] } = @$return[$i];
	}
	return $ret;
}

sub _select_all_for_DATAFIELD {
	my ( $self, $value, $datafield ) = @_;
	$self->_create_select_all_for_DATAFIELD();

	my ( @return, $value_name, $hash, @bindValues, @value_names, $error );
	@bindValues = ();
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next if ( $value_def->{name} eq 'id' );
		$error .= ", $value_def->{name}";
		push( @bindValues,  \$hash->{ $value_def->{name} } );
		push( @value_names, $value_def->{name} );
	}

	my $sth = $self->_get_SearchHandle(
		{
			'search_name' => 'select_all_for_DATAFIELD',
			'furtherSubstitutions' =>
			  { 'DATAFIELD' => $datafield, '\*' => 'id' . $error }
		}
	);

	die ref($self)
	  . ":_select_all_for_DATAFIELD _version2 -> we miss a table_definition or we do not have a 'variables' array!\n"
	  unless ( ref( $self->{'table_definition'} ) eq "HASH"
		&& ref( $self->{'table_definition'}->{'variables'} ) eq "ARRAY" );

	$sth->execute($value);
	if ( defined $self->{dbh}->errstr() ) {
		print "\n\nwe got an mysql error:\n$self->{dbh}->errstr()\n\n";
		my $temp =
		  $self->_getSearchString( 'select_all_for_DATAFIELD', $value );
		$temp =~ s/DATAFIELD/$datafield/;
		Carp::confess(
			ref($self),
":_select_all_for_DATAFIELD ($datafield) -> we got a database error for query '",
			$temp,
			";' ( DATAFIELD == $datafield)\n",
			$self->{dbh}->errstr()
		);
	}

	unless ( $sth->bind_columns( \$hash->{'id'}, @bindValues ) ) {
		Carp::confess(
			    ref($self)
			  . ":_select_all_for_DATAFIELD '$datafield'-> we got an DB error for \n"
			  . $self->INFO_STR()
			  . $self->_getSearchString( 'select_all_for_DATAFIELD', $value )
			  . "\n"
			  . "Using the bind values= id$error\n" );
	}
	while ( $sth->fetch() ) {
		my $_this_hash = { 'id' => $hash->{'id'}, };
		foreach $value_name (@value_names) {
			$_this_hash->{$value_name} = $hash->{$value_name};
		}
		push( @return, $_this_hash );
	}
	return \@return if ( defined $return[0] );
	if ( defined $self->{debug} ) {
		my $str = $self->_getSearchString( 'select_all_for_DATAFIELD', $value );
		$str =~ s/DATAFIELD/$datafield/;
		warn ref($self),
":_select_all_for_DATAFIELD ($datafield) -> we got no data for query ' $str; '\nbind values= id$error\n"
		  ,;
	}
	return \@return;
}

sub INFO_STR {
	my ($self) = @_;
	my $str = '';
	$str .= "class name:\t" . ref($self) . "\n";
	$str .= "tableName:\n" . $self->TableName() . "\n";
	$str .= "Value name\ttype\tdecscription\n";
	foreach my $values ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$str .=
		  "$values->{'name'}\t$values->{'type'}\t$values->{'description'}\n";
	}
	$str .= "INDEXES:\n";
	foreach my $indices ( @{ $self->{'table_definition'}->{'INDICES'} } ) {
		$str .= "\t" . join( ", ", @$indices ) . "\n";
	}
	$str .= "UNIQUE INDICES:\n";
	foreach my $indices ( @{ $self->{'table_definition'}->{'UNIQUES'} } ) {
		$str .= "\t" . join( ", ", @$indices ) . "\n";
	}
	$str .= "MySQL create string::\n"
	  . $self->create_String_mysql( $self->{'table_definition'} );
	return $str;
}

sub _get_search_array {
	my ( $self, $dataset ) = @_;

	return $dataset->{'search_array'}
	  if ( ref( $dataset->{'search_array'} ) eq "ARRAY" );

	my ( @data_values, $className, $do_not_save );
	## now we might have some complex datasets!
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$className = $value_def->{'name'};
		if ( $className eq "table_baseString" ) {
			$do_not_save = 1;
			next
			  unless ( defined $dataset->{'table_baseString'} );
		}
		$self->_create_md5_hash($dataset)
		  if ( $className eq "md5_sum"
			&& !defined $dataset->{'md5_sum'} );
		
		if ( defined $dataset->{$className} ) {
			push( @data_values, $dataset->{$className} );
		}
		elsif ( $value_def->{'NULL'} ) {
			push( @data_values, '' );
		}
		else {
			$self->{'error'} .=
			    ref($self)
			  . ":_get_search_array -> we have no value for column name '$className' ("
			  . $dataset->{$className} . ")\n" unless ( $className =~ m/id$/ );
		}
	}
	Carp::confess(
		    ref($self)
		  . "::_get_search_array -> we have an error here:\n$self->{'error'}"
		  . root::get_hashEntries_as_string( $dataset, 3,
			"using the dataset  " ) )
	  if ( $self->{'error'} =~ m/\w/ );
	$dataset->{'search_array'} = \@data_values
	  unless ($do_not_save);
	return \@data_values;
}

sub _create_md5_hash {
	my ( $self, $dataset ) = @_;

	return $dataset->{'md5_sum'}
	  if ( defined $dataset->{'md5_sum'}
		&& length( $dataset->{'md5_sum'} ) == 32 );
	my $md5_data = '';
	unless ( ref( $self->{'Group_to_MD5_hash'} ) eq "ARRAY" ) {
		$self->{error} .= ref($self)
		  . ":check_dataset -> we can not craete the md5_hash as we do not know which values should be grouped! (\$self->{'Group_to_MD5_hash'} is missing!)\n";
	}
	else {
		foreach my $temp ( @{ $self->{'Group_to_MD5_hash'} } ) {

			unless ( defined $dataset->{$temp} ) {
				$self->{error} .=
				    ref($self)
				  . ":_create_md5_hash -> we do not have the value '$temp' to create the md5_hash (keys = '"
				  . join( "' ,'", ( keys %$dataset ) ) . "')!\n";
			}
			else {
				$md5_data .= $dataset->{$temp};
			}
		}
		$dataset->{'md5_sum'} = md5_hex($md5_data);
	}
	return $md5_data;
}

1;
