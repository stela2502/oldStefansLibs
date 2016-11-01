package chromosomesTable;

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

use stefans_libs::database::genomeDB::nucleosomePositioning;
use stefans_libs::database::fulfilledTask;
use stefans_libs::database::variable_table;
use stefans_libs::database::genomeDB::genomeSearchResult;
use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

class to access and create the chromosomes tables in the NCBI genomes database

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class chromosomesTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);
	Carp::confess ( "we need the dbh at $class new \n" ) unless ( ref($dbh) eq "DBI::db" );

	$self = {
		debug         => $debug,
		dbh           => $dbh,
		tableBaseName => undef,
		'selectID' =>
"select id from database where chromosome = ? and  chr_stop >= ? and chr_start <= ?",
		'selectID_start_stop' =>
"select id, chr_start, chr_stop from database where chromosome = ? and  chr_stop >= ? and chr_start <= ?",
		'sel_gbFileID_for_ID' => "select gbFiles_id from database where id = ?",
		'select_all' => 'select gbFiles_id, chromosome, chr_start from database'

	};

	bless $self, $class if ( $class eq "chromosomesTable" );

	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tax_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'A id from the NCBI TAX database - I do not know what to do with that....',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chromosome',
			'type'        => 'CHAR (2)',
			'NULL'        => '0',
			'description' => 'The chromosome ID - it must not me more that two digits',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chr_start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the start position on this chromosome',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chr_stop',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the end position on this chromosome',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'orientation',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'the orientaion of that gbFile on the chromosome',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'feature_name',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the NCBI name of the database',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'feature_type',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'one more NCBI internal value',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'group_label',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'one more NCBI internal value',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'weight',
			'type'        => 'TINYINT',
			'NULL'        => '1',
			'description' => 'one more NCBI internal value',
			'needed'      => '1'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'chr_start', 'chr_stop', 'chromosome' ] );
	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'chromosome', 'chr_start', 'chr_stop']
	  ; # add here the values you would take to select a single value from the database

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $self;

}

sub expected_dbh_type {
	return 'dbh';
	#return "database_name";
}

#=head2 get_listOfGbIds_start_end_for_chr_region
#
#=head2 function
#
#This method gets a list of gbFile IDs that lie in the wanted region.
#the returning dataset looks like that:
#
#[ [gbFile_id, position of the gbFile on the chromosome [bp]], ...], 
#the start position in bp on the first gbFile,
#the end position in bp on the last gbFile
#
#=cut
#
#sub get_listOfGbIds_start_end_for_chr_region {
#	my ( $self, $dataset ) = @_;
#
#	$self->{error} = $self->{warning} = '';
#
#	$self->{error} .=
#	  ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need a table base name ('baseName')\n"
#	  unless ( defined defined $self->TableName( $dataset->{'baseName'} ) );
#	$self->{error} .=
#	  ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need the chromosome number ('chr')\n"
#	  unless ( defined defined $dataset->{'chr'} );
#	$self->{error} .=
#	  ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need the start in bp on the chromosome ('start')\n"
#	  unless ( defined defined $dataset->{'start'} );
#	$self->{error} .=
#	  ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need the end in bp on the chromosome ('end')\n"
#	  unless ( defined defined $dataset->{'end'} );
#
#	my $sth = $self->_get_SearchHandle(
#		{
#			'baseName'    => $dataset->{'baseName'},
#			'search_name' => 'selectID_start_stop'
#		}
#	);
#	my ( $id, $start, $end, $start_return, $end_return, @gbFiles );
#	$sth->execute( $dataset->{'chr'}, $dataset->{'start'}, $dataset->{'end'} );
#	if ( $self->{debug} ) {
#		print ref($self),
#":get_listOfGbIds_start_end_for_chr_region -> we use this sql string:\n",
#		  $self->_getSearchString(
#			'selectID_start_stop', $dataset->{'chr'},
#			$dataset->{'start'},   $dataset->{'end'}
#		  ),
#		  ";\n";
#	}
#
#	$sth->bind_columns( \$id, \$start, \$end );
#	while ( $sth->fetch() ) {
#		$start_return = $start unless ( defined $start_return );
#		push( @gbFiles, [ $id, $start ] );
#		$start_return = $dataset->{'start'} - $start
#		  if ( $start < $dataset->{'start'} );
#		$end_return = $dataset->{'end'} - $dataset->{'start'};
#		$end_return = $dataset->{'end'} if ( $end > $dataset->{'end'} );
#	}
#	return \@gbFiles, $start_return, $end_return;
#
#}
#
#sub set_fulfilledTask {
#	my ( $self, $dataset ) = @_;
#	unless ( ref( $self->{fulfilled} ) eq "fulfilledTask" ) {
#		$self->{fulfilled} =
#		  fulfilledTask->new( $self->{dbh}, $self->TableName() );
#	}
#	return $self->{fulfilled}->AddDataset($dataset);
#}
#
#sub get_fulfilledTask_for_programName {
#	my ( $self, $programName ) = @_;
#	unless ( ref( $self->{fulfilled} ) eq "fulfilledTask" ) {
#		$self->{fulfilled} =
#		  fulfilledTask->new( $self->{dbh}, $self->TableName() );
#	}
#	return $self->{fulfilled}->get_fulfilled_for_program_id($programName);
#}
#
#sub get_fulfilledTask_for_description {
#	my ( $self, $programName ) = @_;
#	unless ( ref( $self->{fulfilled} ) eq "fulfilledTask" ) {
#		$self->{'fulfilled'} =
#		  fulfilledTask->new( $self->{dbh}, $self->TableName() );
#	}
#	return $self->{'fulfilled'}
#	  ->get_experimentData_for_description($programName);
#}
#
#sub hasBeenDone {
#	my ( $self, $dataset ) = @_;
#	unless ( ref( $self->{fulfilled} ) eq "fulfilledTask" ) {
#		$self->{'fulfilled'} =
#		  fulfilledTask->new( $self->{dbh}, $self->TableName() );
#	}
#	return $self->{'fulfilled'}->hasBeenDone($dataset);
#}
#
#sub get_gbFile_for_acc {
#	my ( $self, $baseName, $acc ) = @_;
#	$self->TableName($baseName);
#	return $self->{gbFiles}
#	  ->getGbfile_obj_for_acc( $self->{tableBaseName}, $acc );
#}
#
#sub get_gbFile_for_gbFile_id {
#	my ( $self, $baseName, $id ) = @_;
#	return $self->{gbFiles}->getGbfile_obj_for_id( $baseName, $id );
#}
#
#sub getNext_gbFile {
#	my ( $self, $baseName ) = @_;
#	## 1. get the position on our dataset.
#	return $self->{gbFiles}->getGbfile_obj_for_id( $self->{tableBaseName},
#		$self->_getNextGbId($baseName) );
#}
#
#sub getAll_gbFeatures_of_type {
#	my ( $self, $tag, $start, $end ) = @_;
#	my $resultSet = $self->_get_genomeSearchResult_object();
#	$self->{error} = '';
#	unless ( defined $tag ) {
#		$self->{error} .= ref($self)
#		  . ":getAll_gbFeatures_of_type -> we did not get the gbFeature tag to select all features. And I will not select 'ALL' features!\n";
#		return undef;
#	}
#	my ( $gbFileID, @gbFeatures );
#	$gbFileID = 0;
#	$self->_getNextGbId( undef, my $reset = 1 );
#	while ( $gbFileID = $self->_getNextGbId() ) {
#		$resultSet->AddDataset(
#			{
#				'gbFeatures' =>
#				  $self->{gbFiles}->get_featureList_for_gbID_start_end(
#					{
#						'gbFile_id' => $gbFileID,
#						'tag'       => $tag,
#						'start'     => $start,
#						'end'       => $end
#					}
#				  ),
#				'gbFile_id' => $gbFileID
#			}
#		);
#		last if ( $self->{debug} );
#		$self->{error} .= $self->{gbFiles}->{error};
#	}
#	return $resultSet;
#}
#
#sub _get_genomeSearchResult_object {
#	my ($self) = @_;
#	my $sth = $self->_get_SearchHandle( { 'search_name' => 'select_all' } );
#	unless ( $sth->execute() ) {
#		die ref($self),
#":_get_genomeSearchResult_object -> we got a database error for query '",
#		  $self->_getSearchString('get_all'), ";'\n", $self->{dbh}->errstr();
#	}
#	my ( $dataset, $gbFiles_id, $chromosome, $chr_start );
#	$sth->bind_columns( \$gbFiles_id, \$chromosome, \$chr_start );
#	while ( $sth->fetch() ) {
#		$dataset->{$gbFiles_id} =
#		  { 'chr' => $chromosome, 'start' => $chr_start };
#	}
#	return genomeSearchResult->new($dataset);
#}
#
#sub getAll_gbFeatures_of_type_and_name {
#	my ( $self, $tag, $name, $start, $end ) = @_;
#	my $resultSet = $self->_get_genomeSearchResult_object();
#	$self->{error} = '';
#	unless ( defined $tag ) {
#		$self->{error} .= ref($self)
#		  . ":getAll_gbFeatures_of_type -> we did not get the gbFeature tag to select all features. And I will not select 'ALL' features!\n";
#		return undef;
#	}
#	my ( $gbFileID, @gbFeatures, $gbFeature );
#	$gbFileID = 0;
#	$self->_getNextGbId( undef, my $reset = 1 );
#
##print ref($self),"we get gbFeatures from gbFile_id ",$self->_getNextGbId()," (just a test!)\n";
#	while ( $gbFileID = $self->_getNextGbId() ) {
#		$resultSet->AddDataset(
#			{
#				'gbFeatures' =>
#				  $self->{gbFiles}->get_featureList_for_gbID_start_end(
#					{
#						'gbFile_id' => $gbFileID,
#						'tag'       => $tag,
#						'name'      => $name,
#						'start'     => $start,
#						'end'       => $end
#					}
#				  ),
#				'gbFile_id' => $gbFileID
#			}
#		);
#		$self->{error} .= $self->{gbFiles}->{error};
#		last if ( $self->{debug} );
#	}
#	for ( my $i = @gbFeatures - 1 ; $i > -1 ; $i-- ) {
#		splice( @gbFeatures, $i, 1 ) unless ( $gbFeatures[$i]->Name eq $name );
#	}
#	return $resultSet;
#}
#
#sub get_features_in_chr_region_by_type {
#	my ( $self, $dataset ) = @_;
#	$self->{error} = $self->{warning} = '';
#	$self->{error} .= ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need a table base name ('
#						  baseName ')\n"
#	  unless ( defined defined $self->TableName( $dataset->{' baseName '} ) );
#	$self->{error} .= ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need the chromosome number ('
#						  chr ')\n"
#	  unless ( defined defined $dataset->{' chr '} );
#	$self->{error} .= ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need the start in bp on the chromosome ('
#						  start ')\n"
#	  unless ( defined defined $dataset->{' start '} );
#	$self->{error} .= ref($self)
#	  . ":get_features_in_chr_region_by_type -> we need the end in bp on the chromosome ('
#						  end ')\n"
#
#	  unless ( defined defined $dataset->{' end '} );
#	unless ( defined defined $dataset->{' tag '} ) {
#		$self->{warning} .= ref($self)
#		  . ":get_features_in_chr_region_by_type -> we set search for ' gene
#						  ' as you have not told us anything else (' tag ')\n";
#		$dataset->{' tag '} = ' gene ';
#	}
#
#	if ( $self->{debug} ) {
#		warn $self->{warning} if ( $self->{warning} =~ m/\w/ );
#		die $self->{error} if ( $self->{error} =~ m/\w/ );
#	}
#	my ( $i, $gbFile_ids, $start, $end, $gbFile_id, @results, $features );
#	( $gbFile_ids, $start, $end ) =
#	  $self->get_listOfGbIds_start_end_for_chr_region($dataset);
#
#	$i = 0;
#	foreach $gbFile_id (@$gbFile_ids) {
#		$dataset->{' gbFile_id '} = @$gbFile_id[0];
#		if ( $i == 0 ) {
#			$dataset->{start} = $start;
#		}
#		else {
#			$dataset->{start} = 0;
#		}
#		$i++;
#		if ( $i == @$gbFile_ids ) {
#			$dataset->{end} = $end;
#		}
#		else {
#			$dataset->{end} = 10**9;
#		}
#		$features =
#		  $self->{gbFiles}->get_featureList_for_gbID_start_end($dataset);
#		## and now we need to add to the region so that we come to the chromosomal location!
#		foreach (@$features) {
#			$_->ChangeRegion_Add( @$gbFile_id[1] );
#		}
#		push( @results, @$features );
#		die $self->{gbFiles}->{error} if ( $self->{gbFiles}->{error} =~ m/\w/ );
#	}
#	return \@results;
#}
#
#sub _getNextGbId {
#	my ( $self, $baseName, $reset ) = @_;
#
#	my $tableName = $self->TableName($baseName);
#
#	unless ( defined $self->{_lastPosition} ) {
#		$self->{_lastPosition} = 1;
#		return $self->{_lastPosition};
#	}
#	elsif ($reset) {
#		$self->{_lastPosition} = undef;
#		return undef;
#	}
#	unless ( $self->_exists( $self->{_lastPosition} ) ) {
#		$self->{_lastPosition} = undef;
#		return undef;
#	}
#	return $self->{_lastPosition}++;
#}
#
#sub _exists {
#	my ( $self, $id ) = @_;
#	my $sth =
#	  $self->_get_SearchHandle( { 'search_name' => 'sel_gbFileID_for_ID' } );
#	my $value = $sth->execute($id);
#	if ( $value == 1 ) {
#		return 1;
#	}
#	else {
#		return 0;
#	}
#	return undef;
#}
#
##sub create {
##	my ( $self, $baseName ) = @_;
##
##	my $table_baseName = $self->TableName($baseName);
##	print "we are craeting a new table named $table_baseName\n";
##	if ( $self->tableExists($table_baseName) ) {
##		warn "dataset exists( $self, $table_baseName )\n";
##		return 0;
##	}
##	my $craeteString = "
##CREATE table $table_baseName (
##	  id INTEGER UNSIGNED auto_increment,
##	  gbFiles_id INTEGER UNSIGNED NOT NULL default 0,
##	  tax_id INTEGER UNSIGNED NOT NULL default 0,
##	  chromosome char(2) NOT NULL default '',
##	  chr_start INTEGER UNSIGNED NOT NULL default ' 0 ',
##	  chr_stop INTEGER UNSIGNED NOT NULL default ' 0 ',
##	  orientation char(1) NOT NULL default '',
##	  feature_name varchar(20) NOT NULL default '',
##	  feature_type varchar(20) NOT NULL default '',
##	  group_label varchar(20) NOT NULL default '',
##	  weight TINYINT default NULL,
##	  KEY ID (id),
##	  unique KEY position (chr_start, chr_stop, chromosome)
##	) ENGINE=MyISAM DEFAULT CHARSET=latin1
##    ";
##
###tax_id	chromosome	chr_start	chr_stop	orientation	feature_name	feature_id	feature_type	group_label	weight
##	if ( $self->{debug} ) {
##		print ref($self), ":create -> we would run $craeteString\n";
##	}
##	else {
##		$self->{dbh}->do($craeteString) or die $self->{dbh}->errstr();
##	}
##	return $self->{gbFiles}->create($baseName);
##
##}
#
#sub _check_gbFeature_add {
#	my ( $self, $dataset ) = @_;
#	$self->{error} = '';
#	$self->{error} .=
#	  ref($self) . ":_check_gbFeature_add -> we need the gbFile_id\n"
#	  unless ( defined $dataset->{'gbFile_id'} );
#	$self->{error} .= ref($self)
#	  . ":_check_gbFeature_add -> we need the gbFeature\n"
#	  unless (
#		(
#			defined $dataset->{'gbFeature'}
#			&& $dataset->{'gbFeature'}->isa("gbFeature")
#		)
#	  );
#	return 0 if ( $self->{error} =~ m/\w/ );
#	return 1;
#}
#
#sub Get_Nulcl_prob_overall_for_region {
#	my ( $self, $dataset ) = @_;
#	unless ( defined $self->{'nucleosomePositioning'} ) {
#		$self->{'nucleosomePositioning'} =
#		  nucleosomePositioning->new( $self->{dbh} );
#		$self->{'nucleosomePositioning'}->TableName( $self->{tableBaseName} );
#	}
#	return $self->{'nucleosomePositioning'}
#	  ->Get_prob_overall_for_region($dataset);
#}
#
#sub Add_gbFeature {
#	my ( $self, $dataset ) = @_;
#	die $self->{error} unless ( $self->_check_gbFeature_add($dataset) );
#	$dataset->{'baseName'} = $self->{ '_tableName' }
#	  unless ( defined $dataset->{'baseName'} );
#	return $self->{'gbFiles'}->Add_gbFeature($dataset);
#}
#
#sub delete_gbFeatures_by_tag_name {
#	my ( $self, $dataset ) = @_;
#	return $self->{'gbFiles'}->delete_gbFeatures_by_tag_name($dataset);
#}
#
##sub AddDataset {
##	my ( $self, $baseName, $dataHash, $gbFile ) = @_;
##	my ( $tableName, @data, $sth );
##	$tableName = $self->TableName($baseName);
##
##	my @keys = @{ $self->{hashKeys} };
##
##	unless ( defined $gbFile ) {
##		warn
##"i can' t insert all datasets into the database without a genbank file !";
##		return 0;
##	}
##	foreach my $hashKey (@keys) {
##		next if ( $hashKey eq "gbFiles_id" );
##		unless ( defined $dataHash->{$hashKey} ) {
##			root::print_hashEntries( $dataHash, 1, " the problematic hash " );
##			die
##" we absolutely need the hash key $hashKey in $self 'AddDataset' \n ";
##		}
##	}
##
##	$dataHash->{gbFiles_id} =
##	  $self->{gbFiles}->AddDataset( $baseName, $gbFile );
##
##	foreach my $hashKey (@keys) {
##		push( @data, $dataHash->{$hashKey} );
##	}
##	$sth = $self->_get_SearchHandle(
##		{ baseName => $baseName, search_name => 'insert_all' } );
##	return $sth->execute(@data);
##}
##
##sub select_gbFileID_for_ID {
##	my ( $self, $tableName, $id ) = @_;
##	my $sth = $self->_get_SearchHandle(
##		{ baseName => $tableName, search_name => 'sel_gbFileID_for_ID' } );
##
##	unless ( $sth->execute($id) ) {
##		warn " problem in $self select_gbFileID_for_ID : \n ",
##		  $self->{dbh}->errstr();
##		return undef;
##	}
##	my @return = $sth->fetchrow_array();
##	return $return[0];
##}
#
#sub ID {
#	my ( $self, $tableName, $chromosome, $start, $end ) = @_;
#
#	my $sth = $self->_get_SearchHandle(
#		{ baseName => $tableName, search_name => 'selectID' } );
#
#	$end = $start unless ( defined $end );
#	unless ( $sth->execute( $chromosome, $start, $end ) ) {
#		warn " a problem occured in $self ID \n ", $self->{dbh}->errstr();
#		return undef;
#	}
#
#	my ( $id, @return );
#	$sth->bind_columns( \$id );
#	while ( $sth->fetch() ) {
#		push( @return, $id );
#	}
#	return @return;
#}

1;
