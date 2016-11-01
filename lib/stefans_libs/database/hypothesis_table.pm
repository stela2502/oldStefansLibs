package hypothesis_table;

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
use stefans_libs::database::external_files;
use base "variable_table";


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to handle hypotheis data. This data consists of a picture, a legend and an name. The picture will be saved to a directory on this server. Only the path is stored....

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class hypothesis_table.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {

		#downstream_Tables => ['partizipatingSubjects'],
		debug => $debug,
		dbh   => root::getDBH( 'root' )
	};

	bless $self, $class if ( $class eq "hypothesis_table" );
	$self->init_tableStructure();

	#$self->create unless ( $self->tableExists('hypothesies'));
	return $self;

}

sub expected_dbh_type{
	return 'database_name';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "hypothesies";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'hypothesis_name',
			'type'        => 'VARCHAR (50)',
			'NULL'        => '0',
			'description' => 'a name for the hypothesis unique in the whole database',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'picture_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'a link to a graphic that describes the hypothsis',
			'data_handler' => 'external_files',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'a caption text for the graphic',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'hypothesis',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'a summary of that hypothesis (MAKE IT STRONG)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'access_right',
			'type'        => 'VARCHAR (50)',
			'NULL'        => '1',
			'description' => 'one of (scientis, group or all)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '0',
			'description' => 'the unique key md5_hash(hypothesis)',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['md5_sum', 'hypothesis_name'] );
	push( @{ $hash->{'UNIQUES'} }, ['hypothesis_name'] );
	
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['hypothesis_name']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'Group_to_MD5_hash'} = ['hypothesis']
	  ;    # define which values should be grouped to get the 'md5_sum' entry
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'data_handler'} ->{ 'external_files' } =  external_files->new( $self->{dbh}, $self->{debug});
##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $dataset;
}

sub get_id_for_hypothesis_description {
	my ( $self, $aim, $description ) = @_;
	my $md5_sum = md5_hash( $description . $aim );
	my $data = $self->_select_all_for_DATAFIELD( $md5_sum, "md5_sum" );
	foreach my $exp (@$data) {
		return $exp->{'id'};
	}
	return 0;
}

1;
