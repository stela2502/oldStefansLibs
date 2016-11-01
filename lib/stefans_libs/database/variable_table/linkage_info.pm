package linkage_info;

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
use
  stefans_libs::database::variable_table::linkage_info::table_script_generator;
use Carp qw(cluck);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a helper class to construct SQL queries

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class linkage_info.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'class_name' => undef,
		'links'      => {},
		'variables'  => {},
		'tableObj'   => undef
	};

	bless $self, $class if ( $class eq "linkage_info" );

	return $self;

}

sub __get_colNames_fromWhereArray {
	my ( $self, $where_array ) = @_;
	my @return;
	Carp::confess(
		    ref($self)
		  . ":create_SQL_statement -> we need an 'where' array of arrays containing three entries, not ($where_array) with "
		  . scalar(@$where_array)
		  . " entries (@$where_array)\n" )
	  unless ( ref($where_array) eq "ARRAY" && scalar(@$where_array) == 3 );
	if ( ref( @$where_array[0] ) eq "ARRAY" ) {
		push( @return,
			$self->__get_colNames_fromWhereArray( @$where_array[0] ) );
	}
	else {
		push( @return, @$where_array[0] );
	}
	if ( ref( @$where_array[2] ) eq "ARRAY" ) {
		push( @return,
			$self->__get_colNames_fromWhereArray( @$where_array[2] ) );
	}
	else {
		push( @return, @$where_array[2] );
	}
	return @return;
}

=head2 create_SQL_statement

A quite usefull function to create complex SQL queries from a rather simple sub.
We need:
=over 2

=item 1. an array of columns to select. 

These columns can have the structure 'tableName'.'column_name' or 'Table_Class'.'column_name' ore only 'column_name'.

=item 2. a complexe where statement

The where statement has to be an array of arrays with the structure 
[ 
	[col_of_interst, connector, other value] 
]
like 'gbFile_id' '=' 'my_value'
if 'other value' matches to a column, then the column name will be inserted.


=item 3. an optional complexSelect_statement

A complex select statement can be used, if you want to do a subselect. e.g. you want to select a substring of a table value.
Then you can use a normal string with variables in it like "substring( #1, #2, #3), #4, #5".
This string is modified with the final query strings of the selected columns.

Say you wanted to select seq, start and end from a table set, but you do not want to select the whole sequence stored in the seq variable.
In that case you can add the complexSelect_statement "substring( #1, #2, #3), #2, #3" to get a final query like
"SELECT substring( seq, start, end), start, end". Keep in mind, that you may be restricted to one database type with this!

=back

Please ceep in mind, that only the first column that matches in the whole table series will be used for the select statement.

=cut

sub ___init_internal_values {
	my ( $self, $sql_hash, $touched_columns, $where_statements,
		$join_statements, $join_tables, $needed_tables, $knownTables )
	  = @_;

	my ($new_variables);

	## 1. select all the columns we would like to use:
	$self->{'touched_columns'} = {};
	$self->{'join_statement'}  = {};
	$self->{'join_tables'}     = {};
	$self->{'needed_tables'}   = {};
	$self->{'knownTables'}     = {};
	$self->{'touched_columns'} = $touched_columns;
	$self->{'column_types'}    = {};

	my ( $colName, $where_array );

	## a) the columns for the SELECT statement
	foreach $colName ( @{ $sql_hash->{'search_columns'} } ) {
		$self->{'touched_columns'}->{$colName} = []
		  unless ( ref( $self->{'touched_columns'}->{$colName} ) eq "ARRAY" );
	}
	if ( ref( $sql_hash->{'order_by'} ) eq "ARRAY" ) {

		#Carp::confess( "we try to add some more columns!\n");
		foreach $colName ( @{ $sql_hash->{'order_by'} } ) {
			if ( ref($colName) eq "ARRAY" ) {
				unless (
					ref( $self->{'touched_columns'}->{ @$colName[0] } ) eq
					"ARRAY" )
				{
					$self->{'touched_columns'}->{ @$colName[0] } = []
					  unless ( @$colName[0] eq "my_value" );
				}
				unless (
					ref( $self->{'touched_columns'}->{ @$colName[2] } ) eq
					"ARRAY" )
				{
					$self->{'touched_columns'}->{ @$colName[2] } = []
					  unless ( @$colName[2] eq "my_value" );
				}

				#print "hellp worrld!\n";
			}
			else {
				$self->{'touched_columns'}->{$colName} = []
				  unless (
					ref( $self->{'touched_columns'}->{$colName} ) eq "ARRAY" );
			}
		}
	}

	$colName = undef;
	## b) the columns for the where_statement
	$sql_hash->{'where'} = [] unless ( defined $sql_hash->{'where'} );
	Carp::confess(
"we have a really big problem here -> the where array is NOT an array \n"
	) unless ( ref( $sql_hash->{'where'} ) eq "ARRAY" );
	foreach $where_array ( @{ $sql_hash->{'where'} } ) {
		foreach $colName ( $self->__get_colNames_fromWhereArray($where_array) )
		{
			$self->{'touched_columns'}->{$colName} = []
			  unless (
				ref( $self->{'touched_columns'}->{$colName} ) eq "ARRAY" );
		}
	}
	## c) the columns in the order_by array (if there are any)
	if ( ref( $sql_hash->{'order_by'} ) eq "ARRAY"
		&& scalar( @{ $sql_hash->{'order_by'} } ) > 0 )
	{
		foreach my $colName ( @{ $sql_hash->{'order_by'} } ) {
			$self->{'touched_columns'}->{$colName} = []
			  unless (
				ref( $self->{'touched_columns'}->{$colName} ) eq "ARRAY" );
		}
	}

	## 2. resolve the column names in our dataset
	$new_variables = $self->_identify_columns_byName();

	if ( $new_variables == 0 ) {
		return undef;
		Carp::cluck(
			    ref( $self->{'tableObj'} )
			  . ":create_SQL_statement -> we could not identify ANY columns of interest in our table structure!\n"
			  . root::get_hashEntries_as_string( $touched_columns, 5,
				"touched_columns" )
			  . root::get_hashEntries_as_string( $where_statements, 5,
				"where_statements" )
			  . root::get_hashEntries_as_string( $join_statements, 5,
				"join_statements" )
			  . root::get_hashEntries_as_string( $join_tables, 5,
				"join_tables" )
		);
		
	}

	## 3. get the WHERE statements
	$self->_create_whereStatement( $sql_hash->{'where'} );
	return 1;
}

sub __Print {
	my ($self) = @_;
	return
	    "I, "
	  . ref($self)
	  . ", handle the table structure for table: '"
	  . $self->{'tableObj'}->TableName() . "'\n"
	  . root::get_hashEntries_as_string( $self->{'touched_columns'},
		5, "touched_columns" )
	  . root::get_hashEntries_as_string( $self->{'where_statements'},
		5, "where_statements" )
	  . root::get_hashEntries_as_string( $self->{'join_statements'},
		5, "join_statements" )
	  . root::get_hashEntries_as_string( $self->{'join_tables'},
		5, "join_tables" )
	  . root::get_hashEntries_as_string( $self->{'needed_tables'},
		5, "needed_tables" )
	  . root::get_hashEntries_as_string( $self->{'links'}, 4, "my links" )
	  . "\n"
	  . root::get_hashEntries_as_string( $self->{'knownTables'},
		4, "and finally my knownTables" )
	  . "\n";
}

sub __get_ONE_ColumnName_4_SQL_Query {
	my ( $self, $column_name ) = @_;
	## here should be the data structure, that we can use:
	## $self->__get_touched_columns()->{$column_name}
	unless ( ref( $self->__get_touched_columns()->{$column_name} ) eq "ARRAY" )
	{
		warn ref($self)
		  . "::__get_ONE_ColumnName_4_SQL_Query -> the dtata structure was not created properly! ($column_name) "
		  . root::get_hashEntries_as_string( $self, 3, "" )
		  unless ( $column_name eq "my_value" );
		return '?';
	}
	return '?'
	  unless defined( @{ $self->__get_touched_columns()->{$column_name} }[0] );
#	if ( scalar( @{ $self->__get_touched_columns()->{$column_name} } ) > 1 ) {
#		warn ref($self)
#		  . "::__resolveColumnName_4_SQL_Query($column_name) -> "
#		  . "we have multiple column names for the wanted column - "
#		  . "hope you can live with the first...\n";
#	}
	return @{ @{ $self->__get_touched_columns()->{$column_name} }[0] }[0];
}

sub __get_ONE_columnType_4_SQL_Query {
	my ( $self, $column_name ) = @_;
	## here should be the data structure, that we can use:
	## $self->__get_touched_columns()->{$column_name}
	$column_name = @$column_name[0] if ( ref($column_name) eq "ARRAY" );
	Carp::confess(
		    ref($self)
		  . "::__get_ONE_ColumnName_4_SQL_Query -> the dtata structure was not created properly ($column_name)! "
		  . root::get_hashEntries_as_string( $self, 3, "" ) )
	  unless (
		ref( $self->__get_touched_columns()->{$column_name} ) eq "ARRAY" );
	Carp::confess(
		    ref($self)
		  . ":: __get_ONE_ColumnName_4_SQL_Query-> we have no information for the column $column_name\n"
		  . root::get_hashEntries_as_string( $self, 3, "" ) )
	  unless defined( @{ $self->__get_touched_columns()->{$column_name} }[0] );
#	if ( scalar( @{ $self->__get_touched_columns()->{$column_name} } ) > 1 ) {
#		warn ref($self)
#		  . "::__resolveColumnName_4_SQL_Query($column_name) -> "
#		  . "we have multiple column names for the wanted column - "
#		  . "hope you can live with the first...\n";
#	}
	return @{ @{ $self->__get_touched_columns()->{$column_name} }[0] }[1];
}

sub create_SQL_statement {
	my ( $self, $hash ) = @_;

	unless ( ref($hash) eq "HASH" ) {
		Carp::confess(
			    ref( $self->{'tableObj'} )
			  . ":create_SQL_statement -> format has changed"
			  . " - we need an hash as argument containing the keys 'search_columns','where' and 'complex_select'\n"
		);
	}
	$self->{'join_data'} = undef;
	unless ( $self->___init_internal_values($hash) ) {
		warn "this table has no usful info for this search!\n";
		if ( defined $self->{'str_create_SQL_statement_for_the_right_table'} ) {
			$self->{'touched_columns'} = undef;
			$self->{'join_statements'} = undef;
			$self->{'join_tables'}     = undef;
			$self->{'needed_tables'}   = undef;
			$self->{'knownTables'}     = undef;
			$self->{'column_types'}    = undef;
			return $self->{'str_create_SQL_statement_for_the_right_table'}
			  ->{'other_info'}->create_SQL_statement($hash);
		}
		else {
			Carp::confess(
				    $self->__Print() 
				  . "We could not generate a SQL query!\n"
				  . root::get_hashEntries_as_string(
					$hash, 3, "The arguments hash:"
				  )
			);
		}
	}

	my ( $complexSelect_statement, $sql, @select_columns, $temp );

	$sql = 'SELECT ';
	#######################################
	## add the required reported columns ##
	#######################################
	$complexSelect_statement = $hash->{'complex_select'}
	  if ( ref( $hash->{'complex_select'} ) eq "SCALAR" );

	my $update_search_columns = 0;
	foreach my $search_column ( @{ $hash->{'search_columns'} } ) {

#Carp::confess( ref($self)."::create_SQL_statement we did not get the array we expected (@{$self->{'touched_columns'}->{$search_column}})\n")
#unless ( ref( @{$self->{'touched_columns'}->{$search_column}} ) eq "ARRAY");
		$temp = 0;
		foreach
		  my $col_array ( @{ $self->{'touched_columns'}->{$search_column} } )
		{
			Carp::confess(
				ref($self)
				  . "::create_SQL_statement we did not get the array we expected ($col_array)\n"
			) unless ( ref($col_array) eq "ARRAY" );
			unless ( $search_column =~ m/\*/ ) {
				push( @select_columns, @$col_array[0] );
			}
			else {
				$update_search_columns = 1;
				push( @select_columns, @$col_array[0] );
			}
			if ( $temp > 0 ) {
				## oh -shit we need to add all column names AND we need to update the $hash->{'search_columns'}!!
				$update_search_columns = 1;
			}
			$temp++;
		}
	}
	if ($update_search_columns) {
		$hash->{'search_columns'} = \@select_columns;
	}
	############################################################################
	## modify the select statement if the user wants to have a complex select ##
	############################################################################
	unless ( defined $complexSelect_statement ) {
		$sql .= join( ", ", @select_columns ) . " \nFROM ";

		#print root::get_hashEntries_as_string ( $self, 2,"my internals");
		$self->{'tableObj'}->LastSelect_Columns( \@select_columns );
	}
	else {
		for ( my $i = 0 ; $i < @select_columns ; $i++ ) {
			$i++;

	 #print ref($self)."we got a complex statement $$complexSelect_statement\n";
			$$complexSelect_statement =~ s/#$i/$select_columns[$i-1]/g;
			$i--;

#print ref($self)."->modify the complexSelect_statement got the str '$$complexSelect_statement' ($select_columns[$i])\n";
			$self->{'tableObj'}->LastSelect_Columns( \@select_columns );
		}
		@select_columns = split( ", ", $$complexSelect_statement );
		$sql .= $$complexSelect_statement . " \nFROM ";
	}
	##########################################################
	## commit suecide if we can't connect to a needed table ##
	##########################################################
	Carp::confess(
		    ref( $self->{'tableObj'} )
		  . ":create_SQL_statement -> we could not resolve all values in our table set:\n"
		  . "look at the SQL query fragment : '$sql'\n"
		  . "and we wanted to get this columns: (@{ $hash->{'search_columns'} })\n"
		  . $self->__Print()
		  . "\n" )
	  if ( $sql =~ m/ 0/ );

	################################################
	## commit suecide if we miss a join statement ##
	################################################
	foreach my $neededTable ( keys %{ $self->{'needed_tables'} } ) {
		next if ( $neededTable eq $self->{'tableObj'}->TableName() );
		Carp::confess(
			ref( $self->{'tableObj'} )
			  . ":create_SQL_statement -> we do not have a connection to table $neededTable\n" #. $self->__get_objectList()
			  . $self->__Print()
		) unless ( $self->{'knownTables'}->{$neededTable} );
	}

	################################
	## create the JOIN statements ##
	################################
	$sql .= $self->{'tableObj'}->TableName() . " ";
	my $str = $self->__make_join_tables();
	if ( $str =~ m/ ON / ) {
		$sql .= $str;
	}

	#	## AND NOW WE NEED TO CHECK THE JOIN STMT ORDER!!
	#	$sql = $self->__check_joinStmt_order($sql);
	##########################
	## add the where clause ##
	##########################
	if ( ref( $self->{'where_statements'} ) eq "ARRAY"
		&& @{ $self->{'where_statements'} } > 0 )
	{
		$sql .= " \nWHERE " . join( " AND ", @{ $self->{'where_statements'} } );
	}

	################################
	## define the order by clause ##
	################################

	if ( ref( $hash->{'order_by'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'order_by'} } ) > 0 )
	{
		my $str = '';
		foreach ( @{ $hash->{'order_by'} } ) {
			if ( ref($_) eq "ARRAY" ) {
				$temp = $self->_create_sql_calculation($_);
				if ( defined $temp ) {
					$str .= " $temp, ";
				}
			}
			else {
				$temp = $self->__get_ONE_ColumnName_4_SQL_Query($_);

#				if ( $temp eq '?'){
#					Carp::confess( ref($self)."::crete_SQL_statement -> we can not create the 'order_by' part, as we can not resolve this variable name $_\n");
#				}
				$str .= " $temp ,";
			}
		}
		chop($str);
		chop($str);
		if ( $str =~ m/\w/ ) {
			$str =~ s/'?\?'?//g;
			$sql .= " \nORDER BY $str";
		}
		elsif ( scalar( @{ $hash->{'order_by'} } ) > 0 ) {
			Carp::confess(
				    ref( $self->{'tableObj'} )
				  . ":create_SQL_statement -> add order_by info -> we got no column entries for (@{$hash->{'order_by'}})\n"
				  . $self->__Print()
				  . "\n\n" );
		}

	}
	$self->{'order_by'} = [] unless ( ref( $self->{'order_by'} ) eq "ARRAY" );

	###########################
	## define the limit case ##
	###########################

	if ( defined $hash->{'limit'} ) {

		#print "we got a limit $hash->{'limit'}\n";
		if ( $self->{'tableObj'}->{'connection'}->{'driver'} eq "mysql" ) {
			$sql .= " $hash->{'limit'}";
		}
		elsif ( $self->{'tableObj'}->{'connection'}->{'driver'} eq "DB2" ) {
			$temp = $hash->{'limit'};
			$temp =~ s/limit/FETCH FIRST/;
			unless ( $temp =~ m/FETCH FIRST/ ) {
				$temp = "FETCH FIRST $temp";
			}
			$sql .= " " . $temp . " ROWS ONLY";
		}

	}
	$sql = $self->finally_check_sql_stmt($sql);

#Carp::confess( root::get_hashEntries_as_string ($self, 7, "We have generated this sql quers:\n$sql\nusing data structure!"));
	return $sql . "\n";
}

=head2 finally_check_sql_stmt

This function is a quite useless thing for simple SQL stmts, but for 
complex ones, it might help to reduce the amount of linked tables.
And that would in tur reduce the amount of errors!

But it is not implemented :-(

=cut

sub finally_check_sql_stmt {
	my ( $self, $sql ) = @_;
	return $sql;
	## I want to get rid of unused join statements!
	my @temp = split( "LEFT JOIN", $sql );
	return $sql if ( scalar(@temp) == 1 );
	my @addition = split( "where", $temp[ @temp - 1 ] );
	if ( scalar(@addition) == 2 ) {
		@temp[ @temp - 1 ] = $addition[0];
		@temp[ @temp - 1 ] = $addition[1];
	}

	my $temp = $temp[0] . $temp[ @temp - 1 ];    ## all BUT the join statements
	my ( $joined_table, $join_statement );
	for ( my $i = @temp ; $i > 0 ; $i-- ) {
		$join_statement = $temp[$i];
		$join_statement =~ m/^ *(\w+) /;
		if ( defined $1 ) {
			$joined_table = $1;
			unless ( $temp =~ m/$joined_table/ ) {
				splice( @temp, $i, 1 );
			}
		}
	}
	$temp = '';
	$temp = pop @temp if ( scalar(@addition) == 2 );
	return join( "LEFT JOIN", @temp ) . " where $temp" if ( $temp =~ m/\w/ );
	return join( "LEFT JOIN", @temp );
}

#sub __check_joinStmt_order {
#	my ( $self, $sql ) = @_;
#
#	$sql = join( " ", split( "\n", $sql ) );
#
#	#print "we want to reorder $sql\n";
#
#	my (
#		$save,     $variable, $base, @joinStmts, $accessible,
#		$provides, $t1,       $t2,   $join,      $runs
#	);
#	if ( $sql =~ m/(.* FROM) (.*)/ ) {
#		$save     = $1;
#		$variable = $2;
#		unless ( $variable =~ m/^ *([\w\d]+) *(LEFT JOIN .+)$/ ) {
#			return $sql;
#		}
#		$base     = $1;
#		$variable = $2;
#	}
#	$accessible->{$base} = 1;
#	@joinStmts = split( "LEFT JOIN", $variable );
#	shift(@joinStmts);
#
#	#print "we have the joins ".join (" ,", @joinStmts)."\n";
#	$runs = 0;
#	while ( defined $joinStmts[0] ) {
#		$runs++;
#		for ( my $i = 0 ; $i < @joinStmts ; $i++ ) {
#			$join = $joinStmts[$i];
#			if ( $join =~
#				m/ *([\w\d]+) ON ([\w\d]+)\.[\w\d]+ *= *([\w\d]+)\.[\w\d]+/ )
#			{
#				( $provides, $t1, $t2 ) = ( $1, $2, $3 );
#				if ( $accessible->{$t1}
#					&& ( $accessible->{$t2} || $provides eq $t2 ) )
#				{
#					$accessible->{$provides} = 1;
#					$base .= " LEFT JOIN $join";
#					splice( @joinStmts, $i, 1 );
#				}
#				elsif ( $accessible->{$t2} && $provides eq $t1 ) {
#					$accessible->{$provides} = 1;
#					$base .= " LEFT JOIN $join";
#					splice( @joinStmts, $i, 1 );
#				}
#			}
#		}
#		if ( $runs == 30 ){
#			warn "we could not create a useful order for the sql statement $sql\n".
#				"Cross your fiungers - we will go on using the original statement...!"
#		  ;
#		  return $sql;
#		}
#
#	}
#	return $save . " " . $base;
#}

sub __create_join_statement {
	my ( $self, $table1, $table2 ) = @_;
	my $sql = '';
	Carp::confess(
		"Sorry, but we can not use an array ref as table name $table1 (1)")
	  if ( $table1 =~ m/ARRAY\(/ );
	Carp::confess(
		"Sorry, but we can not use an array ref as table name $table2 (2)". root::get_hashEntries_as_string ($self, 5, "this object: "))
	  if ( $table2 =~ m/ARRAY\(/ );

	unless ( defined $self->{'join_data'} ) {
		my ( $data, @joins, $value, $key );
		foreach $value ( values %{ $self->{'join_statement'} } ) {
			push( @joins, split( "&& ", $value ) );
		}
		my $i = 0;
		while ( ( $key, $data ) = each %{ $self->{'join_tables'} } ) {
			foreach $value ( split( ", ", $data ) ) {
				$self->{'join_data'}->{$key}->{$value} = $joins[ $i++ ];
			}
		}
	}
	Carp::confess(
		"Sorry, but I do not know the connection between $table1 and $table2")
	  unless ( defined $self->{'join_data'}->{$table1}->{$table2} );
	$sql .=
	  " LEFT JOIN $table2 ON  $self->{'join_data'}->{$table1}->{$table2} ";
	Carp::confess(
"Sorry, we did mess it up! $table1 - $table2 should not result in \n$sql\n"
	) if ( $sql =~ m/ARRAY\(/ );
	return $sql;
}

sub __make_join_tables {
	my ( $self, $start_table, $str ) = @_;
	unless ( defined $str ) {
		my $temp = '';
		$str = \$temp;
	}
	my ( $return, @temp, $table_name );
	$return      = '';
	$start_table = $self->{'tableObj'}->TableName()
	  unless ( defined $start_table );
	Carp::confess(
		root::get_hashEntries_as_string(
			$self,
			3,
			"Oh - I could not identify my base table name ("
			  . $self->{'tableObj'}->TableName() . ")"
		)
	) unless ( defined $start_table );

	return $return unless ( defined $self->{'join_tables'}->{$start_table} );
	return $return unless ( $self->{'join_tables'}->{$start_table} =~ m/\w/ );

	@temp = split( ", ", $self->{'join_tables'}->{$start_table} );
	for ( my $i = 0 ; $i < @temp ; $i++ ) {
		$table_name = $temp[$i];
		unless ( $$str =~ m/$table_name/ ) {
			$$str .= " $table_name";
		}
		else {
			$temp[$i] = '';
		}
	}

	for ( my $i = @temp ; $i >= 0 ; $i-- ) {
		unless ( defined $temp[$i] ) {
			splice( @temp, $i, 1 );
		}
		elsif ( $temp[$i] eq '' ) {
			splice( @temp, $i, 1 );
		}
	}
	unless ( defined $temp[0] ) {
		delete( $self->{'join_tables'}->{$start_table} );
		delete( $self->{'join_statement'}->{$start_table} );
	}
	else {

		#warn "we want to get some joints here $start_table to @temp\n";
		foreach my $table_name (@temp) {

			$return .=
			  $self->__create_join_statement( $start_table, $table_name )
			  ;
			$return .= $self->__make_join_tables( $table_name, $str );
		}

		#warn "and we got $return in total\n";
		$self->{'join_tables'}->{$start_table} = join( ", ", @temp );
	}
	#print "__make_join_tables (".$self->ClassName().") returns '$return'\n";
	return $return;
}

sub __get_objectList {
	my ( $self, $objectList, $level ) = @_;
	$objectList ||= '';
	$level      ||= 0;
	for ( my $i = 0 ; $i < $level ; $i++ ) {
		$objectList .= "\t";
	}
	$objectList .= ref( $self->{'tableObj'} ) . "\n";
	foreach my $otherTab ( values %{ $self->{'links'} } ) {
		my $otherTab2 = @$otherTab[0];
		$objectList =
		  $otherTab2->{'other_info'}
		  ->__get_objectList( $objectList, $level + 1 );
	}
	return $objectList;
}

sub __check_where_array {
	my ( $self, $array ) = @_;

	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . ":_create_whereStatement -> we can not use this where statement ($array)!\n"
	  unless ( ref($array) eq "ARRAY"
		&& ( defined @$array[0] && @$array[2] ) );
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_create_whereStatement -> you may only skipp the 'connectWith' entry if \$array->{'B'} is an array of values!\n"
	  if ( !defined @$array[1]
		&& !ref( @$array[2] ) eq "ARRAY" );
	if ( defined @$array[1] ) {
		my $ok = 0;
		foreach my $OK_connector ( ( '>', '=', '<', '>=', '<=',, '!=' ) ) {
			$ok = 1 if ( $OK_connector eq @$array[1] );
		}
		$self->{'error'} .=
		  ref( $self->{'tableObj'} )
		  . ":_create_whereStatement -> Sorry, but I can not understand the connector '@$array[1]'\n"
		  unless ($ok);
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub _create_whereStatement {
	my ( $self, $where, $whereStatmentHash ) = @_;

	return undef unless ( ref($where) eq "ARRAY" && scalar(@$where) > 0 );
	my ( @where, $a_col_name, $b_col_name, @used_columns, $hash );

	@where = ();

	my $columNames = $self->{'touched_columns'};

	for ( my $i = 0 ; $i < @$where ; $i++ ) {
		$hash = @$where[$i];
		## possibly, this where statement has been processed previously.
		if ( defined @{ $self->{'where_statements'} }[$i]
			&& !@{ $self->{'where_statements'} }[$i] =~ m/\?/ )
		{
			warn
"we will not modify this statement: @{ $self->{'where_statements'} }[$i]\n";
			next;
		}
		elsif ( defined @{ $self->{'where_statements'} }[$i] ) {
			warn "we are going to modify this statement:\n";
		}

		Carp::confess(
			    ref( $self->{'tableObj'} )
			  . ":_create_whereStatement -> we got problems processing this where template"
			  . root::get_hashEntries_as_string( $hash, 10, "the array" ) )
		  unless ( $self->__check_where_array($hash) );

		if ( ref( @$hash[0] ) eq "ARRAY" ) {
			## ok - you want to do a small calculation - your choice
			$a_col_name = $self->_create_sql_calculation( @$hash[0] );
		}
		else {
			$a_col_name = $self->__get_ONE_ColumnName_4_SQL_Query( @$hash[0] );
		}
		unless ($a_col_name) {
			warn ref( $self->{'tableObj'} )
			  . ":_create_whereStatement -> we got no matching columns for the search column name '@$hash[0]' (0) ($a_col_name)\n"
			  . "\twe will not process this where statement";
			next;
		}

		if ( ref( @$hash[2] ) eq "ARRAY" && !defined @$hash[1] ) {
			if ( @{ @$hash[2] }[0] =~ m/^[\d\.E\+\-]+$/ ) {
				$b_col_name = "" . join( ", ", @{ @$hash[2] } ) . " )";
			}
			else {
				$b_col_name = "'" . join( "', '", @{ @$hash[2] } ) . "' )";
			}
			@$hash[1] = "IN ( ";
		}
		elsif ( ref( @$hash[2] ) eq "ARRAY" ) {
			## we want a SMALL calculation done during the select statement!
			$b_col_name = $self->_create_sql_calculation( @$hash[2] );
		}
		else {
			$b_col_name = $self->__get_ONE_ColumnName_4_SQL_Query( @$hash[2] );

#print "we got the variable type ".$self->__get_ONE_columnType_4_SQL_Query( @$hash[0] )." for the column @$hash[0]\n";
			if ( $b_col_name eq '?' ) {
				$b_col_name = "'?'"
				  if ( $self->__get_ONE_columnType_4_SQL_Query( @$hash[0] ) eq
					"char" );
			}
			$b_col_name = '?' unless ($b_col_name);
		}
		@{ $self->{'where_statements'} }[$i] =
		  "$a_col_name @$hash[1] $b_col_name";

#print "we have added a where statement at position $i: @{ $self->{'where_statements'} }[$i]\n";
	}
	return 1;
}

sub __check_sql_calculation {
	my ( $self, $calculationArray ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_create_whereStatement -> you tried to do a small calcualtion, but we need exactly an array with three values for that!\n"
	  unless ( scalar(@$calculationArray) == 3 );
	my $use = 0;
	foreach (qw( + - / * )) {
		$use = 1 if ( @$calculationArray[1] eq $_ );
	}
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_create_whereStatement -> you tried to do a small calcualtion, but the connector @$calculationArray[1] is not supported\n"
	  unless ($use);
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;

}

sub _create_sql_calculation {
	my ( $self, $calculationArray ) = @_;

	Carp::confess(
		    ref( $self->{'tableObj'} )
		  . ":_create_sql_calculation -> Sorry, but we got an error processing this \$calculationArray '$calculationArray':\n"
		  . $self->{'error'} )
	  unless ( $self->__check_sql_calculation($calculationArray) );
	my $columNames = $self->__get_touched_columns();

	my ( $left_side, $right_side );

	if ( ref( @$calculationArray[0] ) eq "ARRAY" ) {
		$left_side = ' ( '
		  . $self->_create_sql_calculation( @$calculationArray[0] ) . ' ) ';
	}
	else {
		$left_side =
		  $self->__get_ONE_ColumnName_4_SQL_Query( @$calculationArray[0] );
	}
	if ( ref( @$calculationArray[2] ) eq "ARRAY" ) {
		$right_side = ' ( '
		  . $self->_create_sql_calculation( @$calculationArray[2] ) . ' ) ';
	}
	else {
		$right_side =
		  $self->__get_ONE_ColumnName_4_SQL_Query( @$calculationArray[2] );
	}
	if ( $left_side eq '?' ) {
		if ( ref( @$calculationArray[2] ) eq "ARRAY" ) {
			## OK that is a calculation - threfore the value has to be a digit!
			$left_side = "?";
		}
		else {
			$left_side = "'?'"
			  if (
				$self->__get_ONE_columnType_4_SQL_Query(
					@$calculationArray[2]
				) eq "char"
			  );
		}
	}
	elsif ( $right_side eq '?' ) {
		if ( ref( @$calculationArray[0] ) eq "ARRAY" ) {
			## OK that is a calculation - threfore the value has to be a digit!
			$right_side = "?";
		}
		else {
			$right_side = "'?'"
			  if (
				$self->__get_ONE_columnType_4_SQL_Query(
					@$calculationArray[0]
				) eq "char"
			  );
		}
	}
	$left_side  = '?' unless ($left_side);
	$right_side = '?' unless ($right_side);

#print "we got a calculation: @$left_side[0]  @$calculationArray[1] @$right_side[0] \n";
	return "$left_side  @$calculationArray[1] $right_side ";
}

sub __match_column_name_to_WANTED {
	my ( $self, $values, $searchString ) = @_;

	my $str = '';
	return 1 if ( $values->{'pure_name'} =~ m/$searchString/ );
	return 1
	  if ( $values->{'name'} =~ m/$searchString$/ );
	$str = $self->{'tableObj'}->{'name'} . "." . $values->{'pure_name'};
	return 1 if ( $str eq $searchString );
	$str = $self->ClassName() . "." . $values->{'pure_name'};
	return 1 if ( $str =~ m/$searchString$/ );
	return 0;
}

sub _identify_columns_byName {
	my ( $self, $touched_columns, $join_statement, $join_tables, $needed_tables,
		$knownTables, $columns_2_select, $columnTypes )
	  = @_;

	## now we need to identify the wanted columns
	## in this process, we can build up the join statements and the join tables
	########################
	## init the variables ##
	########################
	$self->{'touched_columns'}           ||= $touched_columns;
	$self->{'join_statement'}            ||= $join_statement;
	$self->{'join_tables'}               ||= $join_tables;
	$self->{'needed_tables'}             ||= $needed_tables;
	$self->{'knownTables'}               ||= $knownTables;
	$self->{'substitute_search_columns'} ||= $columns_2_select;
	$self->{'column_types'}              ||= $columnTypes;

	###################
	## create errors ##
	###################
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_identify_columns_byName -> touched_columns is undefined!\n"
	  unless ( ref( $self->{'touched_columns'} ) eq "HASH" );
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_identify_columns_byName -> join_statement is undefined!\n"
	  unless ( ref( $self->{'join_statement'} ) eq "HASH" );
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_identify_columns_byName -> join_tables is undefined!\n"
	  unless ( ref( $self->{'join_tables'} ) eq "HASH" );
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_identify_columns_byName -> needed_tables is undefined!\n"
	  unless ( ref( $self->{'needed_tables'} ) eq "HASH" );
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_identify_columns_byName -> knownTables is undefined!\n"
	  unless ( ref( $self->{'knownTables'} ) eq "HASH" );
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );

	my (
		$variable_of_interest, $new_variables,
		$others_new_variable,  $searchString
	);

	##############################################
	## needed for the enhanced pattern matching ##
	##############################################
	$self->{'variables'}->{'id'} = {
		'pure_name' => 'id',
		'name'      => $self->{'tableObj'}->TableName() . ".id",
		'type'      => 'digit'
	};

	$new_variables = 0
	  ; ## we need to know if we have identified some variables for each call of this function

	####################################################
	## identification of wanted columns in this table ##
	####################################################
	foreach my $values ( values %{ $self->{'variables'} } ) {

		foreach $variable_of_interest ( keys %{ $self->{'touched_columns'} } ) {
			$self->{'tableObj'}->{'name'} = "1234567890"
			  unless ( defined $self->{'tableObj'}->{'name'} );
			#########################################################
			## a rather untested pattern match against all columns ##
			#########################################################
			if ( $variable_of_interest =~ m/\*/ ) {
				my $temp = $variable_of_interest;
				$variable_of_interest =~ s/\*/.+/;
#				warn ref($self)
#				  . ":: _identify_columns_byName -> you wanted to get VERY many results - or? ($variable_of_interest)\n";
				$searchString = $variable_of_interest;
				if (
					$self->__match_column_name_to_WANTED(
						$values, $searchString
					)
				  )
				{
					push(
						@{ $self->{'touched_columns'}->{$temp} },
						[ $values->{'name'}, $values->{'type'} ]
					);

					$new_variables++;    ## yes - we identified a variable!
				}
#				else {
#					warn "\tbut we did not match to var $values->{'name'}\n";
#				}
			}

			####################################################
			## the normal pattern match against named columns ##
			####################################################
			else {
				if (
					$self->__match_column_name_to_WANTED(
						$values, $variable_of_interest
					)
				  )
				{

#print root::get_hashEntries_as_string($values, 3, "this value matched against the search \$variable_of_interest $variable_of_interest ");
					push(
						@{
							$self->{'touched_columns'}->{$variable_of_interest}
						  },
						[ $values->{'name'}, $values->{'type'} ]
					);
					unless ( $values->{'name'} eq $variable_of_interest ) {
						unless (
							defined $self->{'touched_columns'}
							->{ $values->{'name'} } )
						{
							$self->{'touched_columns'}->{ $values->{'name'} } =
							  [];
						}
						push(
							@{
								$self->{'touched_columns'}
								  ->{ $values->{'name'} }
							  },
							[ $values->{'name'}, $values->{'type'} ]
						);
					}
					$new_variables++;
				}
			}
		}
	}

#print root::get_hashEntries_as_string($self->{'touched_columns'}, 3, ref($self)."::_identify_columns_byName -> the touched columns during there creation! ");
	my ( $this_table_is_neccessary, @links );
	$this_table_is_neccessary = 0;
	$this_table_is_neccessary = 1 if ( $new_variables > 0 );
	###########################################################
	## identification of needed columns in the linked tables ##
	###########################################################
	foreach my $link ( values %{ $self->{'links'} } ) {

		foreach my $otherTable (@$link) {
			$others_new_variable = 0;
			$others_new_variable =
			  $otherTable->{'other_info'}->_identify_columns_byName(
				$self->{'touched_columns'}, $self->{'join_statement'},
				$self->{'join_tables'},     $self->{'needed_tables'},
				$self->{'knownTables'}
			  );
			if ( $others_new_variable > 0 ) {
				push( @links, $otherTable );
			}
			$new_variables += $others_new_variable;
		}
	}
	#######################################################################
	## committ suecide if we can not provide any columns for this search ##
	#######################################################################
	if (
		(
			( !$this_table_is_neccessary && scalar(@links) < 2 )
			&& !( ref($touched_columns) eq "HASH" )
		)
	  )
	{
		if ( scalar(@links) == 1 ) {
			$self->{'str_create_SQL_statement_for_the_right_table'} = $links[0];
			return 0;
		}
		else {
			return 0;
		}
	}
	###########################################################################
	## now we need to take care of the links from this table to other tables ##
	###########################################################################
	foreach my $link (@links) {
		$self->__add_linkage_info($link);
	}

	$self->{'needed_tables'}->{ $self->{'tableObj'}->TableName() } = 1
	  if ( $new_variables > 0 );

	return $new_variables;
}

sub __add_linkage_info {
	my ( $self, $link ) = @_;

	## 1. to the needed tables
	$self->{'needed_tables'}->{ $link->{'other_obj'}->TableName() } = 1;
	## 1.1 knownTables
	$self->{'knownTables'}->{ $link->{'other_obj'}->TableName() } = 1;
	## 2. to the join_statement
	if (
		defined $self->{'join_statement'}
		->{ $self->{'tableObj'}->TableName() } )
	{
		$self->{'join_statement'}->{ $self->{'tableObj'}->TableName() } .=
		  " && $link->{'join_statement'}";
	}
	else {
		$self->{'join_statement'}->{ $self->{'tableObj'}->TableName() } =
		  $link->{'join_statement'};
	}
	## 3. to the join_tables
	if ( defined $self->{'join_tables'}->{ $self->{'tableObj'}->TableName() } )
	{
		$self->{'join_tables'}->{ $self->{'tableObj'}->TableName() } .=
		  ", " . $link->{'other_obj'}->TableName();
	}
	else {
		$self->{'join_tables'}->{ $self->{'tableObj'}->TableName() } =
		  $link->{'other_obj'}->TableName();
	}
	return 1;
}

sub __get_touched_columns {
	my ($self) = @_;
	die "Sorry, but we "
	  . ref($self)
	  . " have no touched columns ($self->{'touched_columns'})!\n"
	  if ( ( keys %{ $self->{'touched_columns'} } ) == 0 );
	return $self->{'touched_columns'};
}

sub getPrimaryKey_name {
	my ($self) = @_;
	die ref($self)
	  . ":we do not have another table object ($self->{'tableObj'})\n"
	  unless ( $self->{'tableObj'}->isa('variable_table') );

	return $self->{'tableObj'}->TableName() . ".id";
}

sub myVariableName_linksTo_otherObj_id {
	my ( $self, $myObj, $varName, $otherObj, $other_id ) = @_;
	#print ref($self)."::myVariableName_linksTo_otherObj_id ( $self, $myObj, $varName, $otherObj, $other_id );\n";
	my ( $this_var_name, $other_var_name );
	$self->{'tableObj'} = $myObj unless ( defined $self->{'tableObj'} );
	unless ( defined $other_id ) {
		$other_id = 'id';
	}
	unless ( defined $otherObj ) {
		Carp::confess("we have not got a \$otherObj ($otherObj)\n");
	}
	unless ( defined $myObj || defined $self->{'tableObj'} ) {
		Carp::confess("we have not got a \$myObj ($myObj)\n");
	}
	$other_id = 'id' unless ( defined $other_id );
	$self->{'links'}->{$varName} = []
	  unless ( ref( $self->{'links'}->{$varName} ) eq "ARRAY" );

	$this_var_name  = $myObj->TableName() . ".$varName";
	$this_var_name  = $varName if ( $varName =~ m/\./ );
	$other_var_name = $otherObj->TableName() . ".$other_id";
	$other_var_name = $other_id if ( $other_id =~ m/\./ );

	push(
		@{ $self->{'links'}->{$varName} },
		{
			'join_statement' => "$this_var_name = $other_var_name",

			#			'join_statement' => $myObj->TableName()
			#			  . ".$varName = "
			#			  . $otherObj->TableName()
			#			  . ".$other_id",
			'other_obj'  => $otherObj,
			'other_info' => $otherObj->_getLinkageInfo()
		}
	);
	$self->AddVariable( $myObj, $varName );
	return 1;
}

=head2 GetVariable_names

This function can be called to get the information of the used Columns, if they are absolutely 
needed and if the there are some column names, that could be replaced by an ID.

=cut

sub GetVariable_names {
	my ( $self, $hash ) = @_;

	my $table_script_generator;
	$hash                           ||= {};
	$hash->{'variable_information'} ||= {};
	$hash->{'surrogates'}           ||= {};

	my $master = 0;
	$master = 1 if ( !( ref( $hash->{'surrogates'}->{'MASTER'} ) eq "ARRAY" ) );
	my ( $uniques, $links, @column_names );

	if ($master) {

		#print "we are the master table ".ref($self->{'tableObj'})."\n";
		$hash->{'surrogates'}->{'MASTER'} = [];
	}
	else {
		## we need an serach hash to identify our uniques
		foreach ( @{ $self->{tableObj}->{'UNIQUE_KEY'} } ) {
			$uniques->{$_} = 1;
		}
	}

	foreach my $variables (
		@{ $self->{'tableObj'}->{'table_definition'}->{'variables'} } )
	{

		#next if ( $variables->{'name'} =~ m/md5/ );
		next
		  if ( $variables->{'name'} =~ m/md5/
			|| $variables->{'name'} eq "table_baseString" );
		next if ( $variables->{'internal'} );

		if ( $master || ref( $self->{'tableObj'} ) eq "external_files" ) {

		 #print "we extract the values from ". ref( $self->{'tableObj'} ). "\n";
			push(
				@{ $hash->{'surrogates'}->{'MASTER'} },
				ref( $self->{'tableObj'} ) . "." . $variables->{'name'}
			);
			push( @column_names,
				ref( $self->{'tableObj'} ) . "." . $variables->{'name'} );
			$hash->{'variable_information'}
			  ->{ ref( $self->{'tableObj'} ) . "." . $variables->{'name'} } =
			  $variables;

			if ( defined $variables->{'data_handler'} ) {
				$hash->{'variable_information'}
				  ->{ ref( $self->{'tableObj'} ) . "." . $variables->{'name'} }
				  ->{'tableObj'} =
				  @{ $self->{'links'}->{ $variables->{'name'} } }[0]
				  ->{'other_info'}->{'tableObj'};
				## get the other column names
				$hash->{'surrogates'}->{ ref( $self->{'tableObj'} ) . "."
					  . $variables->{'name'} } =
				  @{ $self->{'links'}->{ $variables->{'name'} } }[0]
				  ->{'other_info'}->GetVariable_names($hash);

				## Add the other column names to the columns array!
				push(
					@column_names,
					@{
						$hash->{'surrogates'}->{
							ref( $self->{'tableObj'} ) . "."
							  . $variables->{'name'}
						  }
					  }
				);
			}
		}
		else {

			#print "we look for the variable name $variables->{'name'}\n";
			if ( $uniques->{ $variables->{'name'} } ) {
				push( @column_names,
					ref( $self->{'tableObj'} ) . "." . $variables->{'name'} );
				$hash->{'variable_information'}
				  ->{ ref( $self->{'tableObj'} ) . "."
					  . $variables->{'name'} } = $variables;
			}

		}

	}
	if ($master) {
		$table_script_generator = table_script_generator->new();
		$table_script_generator->VariableNames( \@column_names );
		$table_script_generator->VariableInformation(
			$hash->{'variable_information'} );
		$table_script_generator->Table_Structure( $hash->{'surrogates'} );
		return $table_script_generator;
	}
	return \@column_names;
}

=head2 AddVariable

If you look for the place where the type of the variables is defined, 
you may want to start with this function!

=cut

sub AddVariable {
	my ( $self, $myObj, $varName ) = @_;
	$self->{'tableObj'} = $myObj unless ( defined $self->{'tableObj'} );
	unless ( defined $myObj->{'_tableName'} ) {
		## we are in test mode - and I would expect to be in 'documentaion print mode
		## therefore we can simply 'suspect a table name'
		$myObj->{'_tableName'} = ref($myObj) if ( $0 =~ m/\.t$/ );
	}
	$self->{'variables'}->{$varName} = {
		'pure_name'  => $varName,
		'name'       => $myObj->TableName() . "." . $varName,
		'table_name' => $myObj->TableName(),
		'type'       => $myObj->GetType_4_varName($varName)
	};
	return 1;
}

sub ClassName {
	my ( $self, $className ) = @_;
	if ( defined $className ) {
		$self->{'class_name'} = $className;
	}
	return $self->{'class_name'};
}

sub Print {
	my ( $self, $further_dataHandlers, $filename_extension ) = @_;
	use File::HomeDir;
	my $home = File::HomeDir->my_home();
	$home .= "/project_description";
	mkdir($home) unless ( -d $home );
	$home .= "/database";
	mkdir($home) unless ( -d $home );
	## Oops how to do that??
	$filename_extension .= "_" if ( defined $filename_extension );
	$filename_extension ||= '';
	my $outfile =
	    "$home/"
	  . $filename_extension
	  . $self->ClassName()
	  . "_tableStructure.tex";
	open( OUT, ">$outfile" )
	  or die "could not create the file $outfile\n";

	my $str = $self->_get_as_latex_section(0);

	if ( ref($further_dataHandlers) eq "HASH" ) {
		$str .= "\\newpage\n";
		while ( my ( $name, $obj ) = each %$further_dataHandlers ) {
			$str .=
			  "\\section{table_baseString handler for 'selection~key' $name}\n";
			## here we could have a problem.
			$str .= $obj->getDescription();
			$str .= $obj->_getLinkageInfo()->_get_as_latex_section(1);
		}
	}

	my $base = $self->_tex_file;
	$base =~ s/##HERE COMES THE FUN##/$str/;
	$base =~ s/_/\\_/g;
	$base =~ s/\\\\_/\\_/g;
	print OUT $base;
	close OUT;
	print "Latex source file written to $outfile\n";
}

sub _get_latex_level {
	my ( $self, $level ) = @_;
	my $str = '';
	for ( my $i = 0 ; $i < $level ; $i++ ) {
		$str .= "sub";
	}
	return $str;
}

sub _get_as_latex_section {
	my ( $self, $level ) = @_;
	my $str = "\\"
	  . $self->_get_latex_level($level)
	  . 'section{'
	  . $self->ClassName() . "}\n";
	$str .=
	  "\\label{" . root->Latex_Label( $self->_latex_label_name() ) . "}\n\n";

	$str .= $self->{'tableObj'}->getDescription() . "\n\n";

	$str .= "The class handles a table with a variable name. 
	Therefore I can not tell you which tables will be handled by the class, but all tables handled by that class will end on "
	  . $self->ClassName() . ".\n"
	  unless (
		defined $self->{'tableObj'}->{'table_definition'}->{'table_name'} );
	$str .=
	  "The class handles a table with the name "
	  . $self->{'tableObj'}->{'table_definition'}->{'table_name'} . ".\n"
	  if ( defined $self->{'tableObj'}->{'table_definition'}->{'table_name'} );
	$str .= "\n";

	#$str .= "\\".$self->_get_latex_level($level).'subsection{' . "Indices}\n";

	$str .=
	  "\\" . $self->_get_latex_level($level) . 'subsection{' . "Variables}\n";
	$str .= "\\begin{tabular}[tb]{|c|c|c|c|c|}\n";
	$str .= "\\hline\n";
	$str .= " NAME & DATA TYPE & NULL & DESCRIPTION & LINK TO TABLE \\\\\n";
	$str .= "\\hline\\hline\n";
	foreach my $var ( values %{ $self->{variables} } ) {
		$str .= " $var->{pure_name}  ";
		foreach my $variable (
			@{ $self->{'tableObj'}->{'table_definition'}->{'variables'} } )
		{
			if ( $var->{pure_name} eq $variable->{name} ) {
				$str .= " & $variable->{type} & $variable->{NULL} ";
				if ( defined $variable->{description} ) {
					$str .=
" & \n\\begin{minipage}[c]{4cm} \n$variable->{description} \\end{minipage} ";
				}
				else {
					$str .= " & ";
					warn ref( $self->{'tableObj'} )
					  . ":we miss a description for variable '$var->{pure_name}'\n";
				}

				if ( defined $self->{'links'}->{ $var->{'pure_name'} } ) {
					$str .=
					  "& \n\\begin{minipage}[c]{4cm} "
					  . @{ $self->{'links'}->{ $var->{'pure_name'} } }[0]
					  ->{'other_info'}->ClassName()
					  . " \\ref{"
					  . root->Latex_Label(
						@{ $self->{'links'}->{ $var->{'pure_name'} } }[0]
						  ->{'other_info'}->_latex_label_name() )
					  . "}\n \\end{minipage}\n";
				}
				else {
					$str .= "& ";
				}
				$str .= "\\\\\n";

				$str .= "\\hline\n";
			}
		}
	}
	$str .= "\\hline\n";
	$str .= "\\end{tabular}\n\n\n";
	$str .= "\\"
	  . $self->_get_latex_level($level)
	  . "subsection{The MySQL CREATE TABLE STATEMENT}\n\\begin{verbatim}"
	  . $self->{'tableObj'}->create_String_mysql()
	  . "\n\\end{verbatim}\n";

	foreach my $links ( values %{ $self->{'links'} } ) {
		$str .= "\\newpage\n";
		$str .= @$links[0]->{'other_info'}->_get_as_latex_section($level);
		if ( defined @$links[1] ) {
			$str .=
"This table is linked multiple times - but only the first linked table is displayed (if the tables are all of the same type!)\n";
		}
		my $tableObj = @$links[0]->{'other_info'}->ClassName();
		my $temp;
		for ( my $i = 1 ; $i < @$links ; $i++ ) {
			$temp = @$links[$i]->{'other_info'}->ClassName();
			unless ( $tableObj =~ m/$temp/ ) {
				$tableObj .= $temp;
				$str .=
				  @$links[$i]->{'other_info'}->_get_as_latex_section($level);
				$str .=
"Surprisingly, this variable was linked to more that one other table type.
				Therefore I had to include this table here...\n";
			}
		}
	}
	return $str;
}

sub _latex_label_name {
	my ($self) = @_;
	return join( "", split( "_", $self->ClassName() ) );
}

sub _tex_file {
	my ($self) = @_;
	use stefans_libs::root;

	return '\documentclass{scrartcl}
	 \usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
	 \usepackage{hyperref}
  \begin{document}
  \tableofcontents
  
  \title{ Table structure downstream of ' . $self->ClassName() . '}
  \author{Stefan Lang}\\
  \date{' . root->Today() . '}
  \maketitle
  
  \begin{abstract}
  	Each table has an "id" column, that is not described in the Variables section. 
	This row is the PRIMARY INDEX and can be searched using the function \textbf{Select\_by\_ID}.
	The return value for this function is an perl hash with all column names as keys.
	
	All tables implement a function called \textbf{AddDataset}, that expects an hash of values that should be inserted into the table. 
	The keys of the hash have to be the column titles of the table. 
	If a column is a link to an other table, then the Perl classes expect that the column name ends on \textit{\_id}. 
	The data for this column is ment to be stored in a hash\_key with the name of the column without the \textit{\_id}.
	This value on runtime added to the other table using the \textbf{AddDataset} function.
	
	All tables implement the function \textbf{\_select\_all\_for\_DATAFIELD}.
	This function expects a variable and the name of the column to search with that variable.
	It returns the same as the perl DBI function fetchall\_hashref.
	
	A new function that is implemented is the function \textbf{getArray\_of\_Array\_for\_search}.
	This function can automatically create SQL queries. Please refer to the POD of stefans\_libs::database::variable\_table to read more about this function.
  
  \end{abstract}
  
  \newpage
  
  ##HERE COMES THE FUN##
  
  \end{document}
';
}

1;
