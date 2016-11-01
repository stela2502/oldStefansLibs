package oligo_array_values;

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
use base ('variable_table');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

::database::dataset::oligo_array_values

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Array_Data_Hyb where all hybridization valuies are stored.

=head2 new

=head3 atributes

a DBI database handle and a binary value that defines if we are in debug mode or not.

=head3 retrun values

A object of the class array_Hyb

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die $class, ":new -> we need a DBI object at startup!(not $dbh)\n$!"
	  unless ( defined $dbh && $dbh =~ m/DBI::db/ );

	my ($self);

	$self = {
		'debug' => $debug,
		'dbh'   => $dbh
	};

	bless( $self, $class ) if ( $class eq "oligo_array_values" );

	## table definition
	# add output of create_hashes_from_mysql_create.pl here
	# take care for the variable table names!!
	my $hash;
	$hash->{'INDICES'}   = [];
	$hash->{'UNIQUES'}   = [];
	$hash->{'variables'} = [];

	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'value',
			'type'        => 'FLOAT',
			'NULL'        => '0',
			'description' => 'a value, that can contain any number'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'std',
			'type' => 'FLOAT',
			'NULL' => '1',
			'description' =>
'an optional value, that reflects the standars deviation of the other value'
		}
	);
	$hash->{'ENGINE'}                            = 'InnoDB';
	$self->{'table_definition'}                  = $hash;
	$self->{'table_definition'}->{'FOREIGN KEY'} = {};
	return $self;
}

=head2 create

Creates a new table to store the hybridization values foreach oligo.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub create {
	my ( $self, $FOREIGN_TABLE_NAME ) = @_;

	my $createString;

	$FOREIGN_TABLE_NAME = $self->linked_table_name()
	  unless ( defined $FOREIGN_TABLE_NAME );
	Carp::confess(
		ref($self)
		  . ":create -> we definitely need an \$FOREIGN_TABLE_NAME '$FOREIGN_TABLE_NAME' to create the linked table structure!\n"
	) unless ( defined $FOREIGN_TABLE_NAME );

	my $table_baseName = $self->TableName();

	$self->_dropTable($table_baseName);

	$self->{'table_definition'}->{'table_name'} = "$table_baseName";

	$self->{'table_definition'}->{'FOREIGN KEY'} = {
		'foreignColumn' => 'id',
		'foreignTable'  => $FOREIGN_TABLE_NAME,
		'myColumn'      => 'id'
	};

	if ( $self->{'connection'}->{'driver'} eq "mysql" ) {
		$createString =
		  $self->create_String_mysql( $self->{'table_definition'} );
	}
	elsif ( $self->{'connection'}->{'driver'} eq "DB2" ) {
		$createString = $self->create_String_DB2( $self->{'table_definition'} );
	}
	else {
		Carp::confess(
			ref($self)
			  . " - variableTable -> we can not create a CREATE statement for this database driver '$self->{'connection'}->{'driver'}'\n"
		);
	}

	if ( $self->{debug} ) {
		print ref($self), ":create -> we would run $createString\n";
	}
	else {
		$self->{dbh}->do($createString)
		  or die
"we tried to craete the table structure: \n'$createString;'\n But we got that error: ",
		  $self->{dbh}->errstr;
		$self->{__tableNames} = undef;
	}
	return 1;
}

sub Sample_Lable{
	my ( $self, $sample_lable )= @_;
	$self->{'sample_lable'} = $sample_lable if ( defined $sample_lable);
	return $self->{'sample_lable'} if ( defined $self->{'sample_lable'});
	return '--';
}
=head2 check_dataset

The table name defines our identity! 
Therefore no further infos about the dataset have to be stored - 
and we do not have to check for them!
All we need is a hash with the structure:{

=over 2

=item oligoDB  the oligoDB that contains the FOREIGN KEY. 

This key can be obtained from this object using the function ->getNext in exactly the same order as in the oligoDB.

=item data  a ref to an hash of arrays with the structure { <oligoName> => [ <value>, <std deviation>] } or { <oligoName> => <value> } 

=item baseName  "the base name for this oligo dataset"

=back

}

The function returns 1 for a usable dataset and 0 for an unusable. 
The error message is stored in the value $self->{error}.

=cut

sub check_dataset {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';

	$self->{error} .=
	  ref($self)
	  . ":check_dataset -> we need object of the class oligoDB ('oligoDB')\n"
	  unless ( ref( $dataset->{'oligoDB'} ) eq 'oligoDB' );
	unless ( ref( $dataset->{'data'} ) eq "HASH" ) {
		$self->{error} .= ref($self)
		  . ":check_dataset -> we need the oligo information ('data') as hash with the structure { <oligoName> => [ <value>, <std deviation>] } or { <oligoName> => <value> } \n";
	}
	$self->{error} .=
	  ref($self)
	  . ":check_dataset -> we need to know the table baseName for this dataset ('baseName')!\n"
	  unless ( defined $dataset->{'baseName'} || defined $self->{_tableName} );

	return 0 if ( $self->{error} =~ m/\w/ );

	return 1;
}

sub linked_table_name {
	my ( $self, $name ) = @_;
	return $self->{'FOREIGN_TABLE_NAME'} unless ( defined $name);
	if ( $name =~ m/\w/ ) {
		$self->{'FOREIGN_TABLE_NAME'} = $name;
	}
	return $self->{'FOREIGN_TABLE_NAME'};
}

=head2 AddDataset

We add the datasets preserving the original order! 
The order will be saved in the database using the class oligoID2oligoName.

=cut

sub AddDataset {
	my ( $self, $dataset ) = @_;

	Carp::confess( $self->{error} ) unless ( $self->check_dataset($dataset) );

	my ( $oligoID, $value, $dev, $mode, $do );
	## we need to check, whether we have a simple value or an value and an varianze
	while ( my ( $oligoID, $value ) = each %{ $dataset->{'data'} } ) {
		if ( ref($value) eq "ARRAY" ) {
			$mode = 'ARRAY';
		}
		else {
			$mode = 'value';
		}
		last;
	}

	#die "we would add the table ", $self->TableName() ," to the database\n";

	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create( $dataset->{'oligoDB'}->TableName() );
	}
	else {
		## OK - maybe there has not been any data insert taken place?
		my $sql = $self->create_SQL_statement(
			{
				'search_columns' => [ ref($self) . '.id' ],
				'limit'          => "limit 1"
			}
		);
		my $sth;
		unless ( $sth = $self->{'dbh'}->prepare($sql) ) {
			Carp::confess(
				    ref($self)
				  . "::AddDataset -> we check if we have previously added data to the table "
				  . $self->TableName()
				  . "\nBut out sql query has a serious error: '$sql;'\n" );
		}
		my $rv = $sth->execute();
		$rv = $sth->fetchall_arrayref();
		if ( defined @$rv[0] ) {
			print "the dataset "
			  . $self->TableName()
			  . " is already in the database! \n-> we will not import this dataset - done\n";
			return undef;
		}
		print "the table was already existant, but the table was empty!\n"
		  if ( $self->{'debug'} );
	}

	$self->_create_insert_statement();
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'insert' } ); ## use sth -> 1
	$self->_create_insert_statement('std');
	my $sth_onlyOne =
	  $self->_get_SearchHandle( { 'search_name' => 'insertstd' } )
	  ;                                                          ## use sth -> 2

	$dataset->{'oligoDB'}->{'actual_position'} = 0;
	my $useSth = 0;
	my @DATA   = ();

	######
	$do = 1;
	#######
	my $mean = 0;
	$dataset->{oligoDB}->reset_getNext_acc();
	my $i = 0;
	if ( $mode eq "ARRAY" ) {
		while ($do) {
			$oligoID = $dataset->{'oligoDB'}->getNext_acc();
			$i++;
			unless ($oligoID) {
				$do = 0;
				last;
			}
			unless ( defined $dataset->{'data'}->{$oligoID} ) {
				$oligoID = $i;
			}

# that is alwast the case! if ( @{ $dataset->{'data'}->{$oligoID} }[1] =~ m/\d/ )
			push(
				@DATA,
				[
					@{ $dataset->{'data'}->{$oligoID} }[0],
					@{ $dataset->{'data'}->{$oligoID} }[1]
				]
			);
		}
	}
	else {
		while ($do) {
			$oligoID = $dataset->{'oligoDB'}->getNext_acc();
			unless ($oligoID) {
				$do = 0;
				last;
			}
			unless ( defined $dataset->{'data'}->{$oligoID} ) {
				Carp::confess(
					    ref($self)
					  . "::AddDataset -> we have no value for oligoID $oligoID\n"
					  . root::get_hashEntries_as_string(
						$dataset, 5, "what dataset do we have??"
					  )
				);
			}

		  #print "we add to \@DATA $dataset->{'data'}->{$oligoID} ($oligoID)\n";
			push( @DATA, [ $dataset->{'data'}->{$oligoID} ] );
			$mean += $dataset->{'data'}->{$oligoID};
		}
	}
	print "\nwe got a mean of " . ( $mean / @DATA ) . "\n\n";
	if ( $self->{'connection'}->{'driver'} eq "DB2" ) {
		if ( $mode eq "ARRAY" ) {
			for ( my $i = 0 ; $i < @DATA ; $i++ ) {
				$sth->execute( $i + 1, @{ $DATA[$i] } )
				  or $self->_confess_insert_errors( 'insert', $i + 1,
					@{ $DATA[$i] } );
			}
		}
		else {
			for ( my $i = 0 ; $i < @DATA ; $i++ ) {
				$sth_onlyOne->execute( $i + 1, @{ $DATA[$i] } )
				  or $self->_confess_insert_errors( 'insertstd', $i + 1,
					@{ $DATA[$i] } );
			}
		}
	}
	else {
		if ( $mode eq "ARRAY" ) {
			for ( my $i = 0 ; $i < @DATA ; $i++ ) {
				$sth->execute( @{ $DATA[$i] } )
				  or $self->_confess_insert_errors( 'insert', @{ $DATA[$i] } );
			}
		}
		else {
			for ( my $i = 0 ; $i < @DATA ; $i++ ) {
				$sth_onlyOne->execute( @{ $DATA[$i] } )
				  or
				  $self->_confess_insert_errors( 'insertstd', @{ $DATA[$i] } );
			}
		}
	}

	return $self->TableName();
}

1;
