package expr_est;

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

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {
		debug => $debug,
		dbh   => root::getDBH( 'root', $database ),
	};

	bless $self, $class if ( $class eq "expr_est" );

	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return "database_name";
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
			'name'        => 'value',
			'type'        => 'FLOAT',
			'NULL'        => '0',
			'description' => 'the expression level'
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	return $dataset;
}

sub AddDataset{
	my ( $self, $dataset) = @_;
	## we will make no checks, because that could kill all. Instead, we do a similar thing as in oligo_array_values.
	## $dataset->{'affy_desc_id'} contains our 'oligoDB'
	$self->{'error'} = '';
	unless ( ref($dataset->{'affy_desc_id'}) eq "probesets_table"){
		$self->{'error'} .= ref($self).". we need the probeset_table object!\n" ;
	}
	else{
		$self->{'error'} .= ref($self).". the reference data table was not created properl (".$dataset->{'affy_desc_id'}->TableName().")\n"
		  unless ( $self->tableExists($dataset->{'affy_desc_id'}->TableName()));
		
	}
	unless ( ref($dataset->{'estimates'}) eq "HASH"){
		$self->{'error'} .= ref($self).". we miss the data hash ('estimates')!\n";
	}
	if ( $self->{'error'} =~ m/\w/ ){
		Carp::confess( root::get_hashEntries_as_string ($dataset, 3, ref($self). "..AddDataset -> we could not add the dataset")."as we got these errors:\n$self->{'error'}\n");
	}
	my ( $rv, $sth, @data, $aff_probes_2_DBid );
	$aff_probes_2_DBid = $dataset->{'affy_desc_id'}->Get_AffyID_2_dbID_hash();
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create( $dataset->{'oligoDB'}->TableName() );
	}
	$self->_create_insert_statement();
	$sth =
	  $self->_get_SearchHandle( { 'search_name' => 'insert' } ); ## use sth -> 1
	
	foreach my $info ( @$aff_probes_2_DBid){
		unless ( defined $dataset->{'estimates'}->{$info->{'probe_id'}}){
			Carp::confess( ref($self)."..AddDataset -> the estimate for probeset_id $info->{'probe_id'} is missing!\n");
		}
		$sth->execute( $dataset->{'estimates'}->{$info->{'probe_id'}} )
				  or $self->_confess_insert_errors( 'insert', $dataset->{'estimates'}->{$info->{'probe_id'}});
	}
	return $self->TableName();
}

1;
