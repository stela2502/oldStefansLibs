package gbFeaturesTable;

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
use stefans_libs::gbFile::gbFeature;
use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::database::genomeDB::db_xref_table;
use stefans_libs::database::variable_table;

#use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::database::fulfilledTask::fulfilledTask_handler;

use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

class to access and create the gbFeatures tables in the NCBI genomes database

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class gbFeaturesTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh,
		'select_gbString_for_gbID_tag_start_end' =>
'select gbString from database where gbFile_id = ? && tag = ? && start >= ? && end <= ?',
		selectID_NTS =>
"select id from database where  tag = ? && name = ? && start = ? && end = ?",
		selectIDs_by_gbFile => "select id from database where gbFile_id = ?;",
		select_gbStrings =>
"select gbString from database where id IN ( theSearchIDs ) order by start",
		select_all_for_feature_tag_and_name =>
		  "select gbFile_id, gbString from database where tag = ? && name = ?",
		'select_gbString_for_gbID_tag_name_start_end' =>
"select gbString from database where  gbFile_id = ? && tag = ? && name = ? && start >= ? && end <= ?",
		'delete_from_gbFeatures' =>
		  "delete from database where tag = ? && name = ? && gbFile_id = ?;"
	};

	bless $self, $class if ( $class eq "gbFeaturesTable" );
	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';

	#return "not a database interface";
	#return "database_name";
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
			'name'         => 'gbFile_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'gbFileTable',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tag',
			'type'        => 'VARCHAR (20)',
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

	$self->{'Group_to_MD5_hash'} = ['gbString'];

	$self->{'UNIQUE_KEY'} = ['md5_sum']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	$self->{'data_handler'}->{'gbFileTable'} =
	  gbFilesTable->new( $self->{dbh}, $self->{debug} );
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'_propagateTableName_to'} =
	  [ $self->{'data_handler'}->{'gbFileTable'} ];
	return $dataset;
}

sub unlink_gbFilesTable{
	my ( $self ) = @_;
	## OK, that is a harsh step!
	$self->{'data_handler'}->{'chromosomesTable'} = chromosomesTable->new($self->{'dbh'}, $self->{'debug'} ) unless ( defined $self->{'data_handler'}->{'chromosomesTable'});
	$self->{'data_handler'}->{'chromosomesTable'}->TableBaseName( $self->TableBaseName());
	foreach my $vardef ( @{$self->{'table_definition'}->{'variables'}}){
		if ($vardef->{'name'} eq "gbFile_id"){
			$vardef->{'data_handler'} = 'chromosomesTable';
		}
	}
	return 1;
}

sub relink_gbFilesTable{
	my ( $self ) = @_;
	## OK, that is a harsh step!
	foreach my $vardef ( @{$self->{'table_definition'}->{'variables'}}){
		if ($vardef->{'name'} eq "gbFile_id"){
			$vardef->{'data_handler'} = 'gbFileTable';
		}
	}
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	unless ( ref( $dataset->{'gbFeature'} ) eq "gbFeature" ) {
		$self->{'error'} .=
		    ref($self)
		  . ":DO_ADDITIONAL_DATASET_CHECKS -> you can not add a db_entry to table "
		  . $self->TableName()
		  . " that is not of type gbFeature ($dataset->{'gbFeature'})\n";
	}
	else {
		$dataset->{'tag'}      = $dataset->{gbFeature}->Tag();
		$dataset->{'name'}     = $dataset->{gbFeature}->Name();
		$dataset->{'gbString'} = $dataset->{gbFeature}->getAsGB();
		$dataset->{'start'}    = $dataset->{gbFeature}->Start();
		$dataset->{'end'}      = $dataset->{gbFeature}->End();
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

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
#	$self->{'selectID_start_stop'} = $self->create_SQL_statement(
#		[ 'gbFile_id', 'chr_start', 'chr_stop' ],
#		[ [ 'chr_start', ">=", "my value" ], [ 'chr_stop', "<=", "my value" ] ]
#	);
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

sub get_gbFile_for_acc {
	my ( $self, $gbFile_acc ) = @_;
	my $gbFile =
	  $self->{'data_handler'}->{'gbFileTable'}
	  ->getGbfile_obj_for_acc($gbFile_acc);
	$gbFile->Feature(
		$self->get_gbFeatures_for_gbFileID(
			$self->{'data_handler'}->{'gbFileTable'}->ID_for_ACC($gbFile_acc)
		)
	);
	return $gbFile;
}

=head3 get_rooted_to

This function is implemented in all genomeDB interface classes and allows to switch interfaces.
That might be needed to reformat the perl objects to link to special downstream tables.

You might get a several db_objects if you use this function:

=over

=item 
'gbFeaturesTable'

=item 
'gbFilesTable'

=item 
'ROI_table'

=item 
'SNP_table'

=back

=cut

sub get_rooted_to {
	my ( $self, $root_str ) = @_;
	if ( $root_str eq "gbFeaturesTable" ) {
		return $self;
	}
	elsif ( $root_str eq "gbFilesTable" ) {
		return $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self);
	}
	elsif ( $root_str eq "ROI_table" ) {
		my $interface =
		  $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self);
		$interface->get_rooted_to("ROI_table");
	}
	elsif ( $root_str eq "SNP_table" ) {
		return $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self)
		  ->get_SNP_Table_interface();
	}
	else {
		Carp::confess(
			ref($self)
			  . ":get_rooted_to -> I cant root to \$root_str '$root_str'\n" );
	}
}

sub makeMaster {
	my ( $self, $gbFilesTable_obj ) = @_;
	foreach ( @{ $gbFilesTable_obj->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq "id" ) {
			$_ = undef;
		}
	}
	$gbFilesTable_obj->{'data_handler'}->{'gbFeatureTable_obj'} = undef;

	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq "gbFile_id" ) {
			$_->{'data_hanlder'} = 'gbFileTable';
		}
	}
	$self->{'data_handler'}->{'gbFileTable'} = $gbFilesTable_obj;
	$self->{'genomeID'} = $gbFilesTable_obj->{'genomeID'};
	return $self;
}

sub getNucleosomePositioning_Table {
	my ($self) = @_;
	use stefans_libs::database::genomeDB::nucleosomePositioning;
	unless (
		ref( $self->{'nucleosomePositioning'} ) eq 'nucleosomePositioning' )
	{
		$self->{'nucleosomePositioning'} =
		  nucleosomePositioning->new( $self->{dbh}, $self->{debug} );
		$self->{'nucleosomePositioning'}->{'data_handler'}->{'gbFilesTable'} =
		  $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self);
		$self->{'nucleosomePositioning'}->TableName( $self->TableBaseName() );
		$self->{'nucleosomePositioning'}->create()
		  unless (
			$self->tableExists( $self->{'nucleosomePositioning'}->TableName ) );
	}
	return $self->{'nucleosomePositioning'};
}

sub get_gbFile_for_gbFile_id {
	my ( $self, $gbFile_id ) = @_;
	my $gbFile =
	  $self->{'data_handler'}->{'gbFileTable'}
	  ->getGbfile_obj_for_id($gbFile_id);
	Carp::confess(
		ref($self)
		  . ":get_gbFile_for_gbFile_id -> we will die here as the gbFileID $gbFile_id is not defined in the databse!\n"
	) unless ( defined $gbFile );

	$gbFile->Features( $self->get_gbFeatures( { 'gbFile_id' => $gbFile_id } ) );
	return $gbFile;
}

sub ID {
	my ( $self, $tableName, $chromosome, $start, $end ) = @_;
	return $self->get_Columns( { 'search_columns' => ['gbFile_id'] },
		{ 'start' => $start, 'end' => $end, 'chromosome' => $chromosome } );
	my ($id) = @{
		$self->getArray_of_Array_for_search(
			{
				'search_columns' => ['gbFile_id'],
				'where'          => [
					[ 'chr_start',  '<', 'my value' ],
					[ 'chr_stop',   '>', 'my value' ],
					[ 'chromosome', '=', 'my value' ]
				]
			},
			( $end, $start, $chromosome )
		)
	  };
	return $id;
}

sub init_getNext_gbFile {
	my ($self) = @_;
	$self->{'__lastGBfile_position'} = undef;
}

sub getNext_gbFile {
	my ($self) = @_;
	unless ( defined $self->{'__lastGBfile_position'} ) {
		$self->{'__lastGBfile_position'} = 0;
		my @result = @{
			$self->getArray_of_Array_for_search(
				{ 'search_columns' => ['gbFilesTable.id'], 'where' => [] }
			)
		  };
		$self->{'gbFile_ids'} = [];
		foreach (@result) {
			push( @{ $self->{'gbFile_ids'} }, @$_[0] );
		}
		print ref($self)
		  . ":getNext_gbFile -> we executed '$self->{'complex_search'};'\n"
		  if ( $self->{'debug'} );
	}
	return undef
	  unless (
		defined $self->{'gbFile_ids'}[ $self->{'__lastGBfile_position'} ] );
	my $gbFile =
	  $self->get_gbFile_for_gbFile_id(
		$self->{'gbFile_ids'}[ $self->{'__lastGBfile_position'}++ ] );
	return $gbFile;
}

#sub getAll_gbFeatures_of_type {
#	my ( $self, $type ) = @_;
#	my $array =
#	  $self->getArray_of_Array_for_search( ['gbString'],
#		[ [ 'tag', '=', 'my value' ] ],
#		undef, $type );
#	my ( @return, $gbString );
#	foreach $gbString (@$array) {
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString( @$gbString[0] );
#		push( @return, $gbFeature );
#	}
#	return \@return;
#}

sub _get_genomeSearchResult_object {
	die "not implemented!\n";
}

#sub getAll_gbFeatures_of_type_and_name {
#	my ( $self, $type, $name ) = @_;
#	my $array =
#	  $self->getArray_of_Array_for_search( ['gbString'],
#		[ [ 'tag', '=', 'my value' ], [ 'name', '=', 'my value' ] ],
#		undef, $type, $name );
#	my ( @return, $gbString );
#	foreach $gbString (@$array) {
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString( @$gbString[0] );
#		push( @return, $gbFeature );
#	}
#	return \@return;
#}

sub get_features_in_chr_region_by_type {
	my ( $self, $dataset ) = @_;
	$self->{error} = $self->{warning} = '';
	$self->{error} .= ref($self)
	  . ":get_features_in_chr_region_by_type -> we need a table base name ('
						  baseName ')\n"
	  unless ( defined defined $self->TableName( $dataset->{'baseName'} ) );
	$self->{error} .=
	  ref($self)
	  . ":get_features_in_chr_region_by_type -> we need the chromosome number ('chr')\n"
	  unless ( defined defined $dataset->{'chr'} );
	$self->{error} .=
	  ref($self)
	  . ":get_features_in_chr_region_by_type -> we need the start in bp on the chromosome ('start')\n"
	  unless ( defined defined $dataset->{'start'} );
	$self->{error} .=
	  ref($self)
	  . ":get_features_in_chr_region_by_type -> we need the end in bp on the chromosome ('end')\n"
	  unless ( defined defined $dataset->{'end'} );
	unless ( defined defined $dataset->{'tag'} ) {
		$self->{warning} .= ref($self)
		  . ":get_features_in_chr_region_by_type -> we set search for 'gene' as you have not told us anything else ('tag')\n";
		$dataset->{'tag'} = 'gene';
	}
	my $array =
	  $self->getArray_of_Array_for_search( ['gbString'],
		[ [ 'tag', '=', 'my value' ], [ 'name', '=', 'my value' ] ], undef, );

}

sub Get_Nulcl_prob_overall_for_region {
	my ( $self, $dataset ) = @_;

	my $nulPos = $self->getNucleosomePositioning_Table();
	return $nulPos->Get_prob_overall_for_region($dataset);
}

sub delete_gbFeatures_by_tag_name {
	my ( $self, $dataset ) = @_;
	## we need the tag, the name and the gbFile_id
	$self->{error} = "";
	unless ( defined $dataset->{'tag'} ) {
		$self->{error} .= ref($self)
		  . ":delete_gbFeatures_by_tag_name -> we do not know what to delete!(tag)\n";
	}
	unless ( defined $dataset->{'name'} ) {
		$self->{error} .= ref($self)
		  . ":delete_gbFeatures_by_tag_name -> we do not know what to delete!(name)\n";
	}
	unless ( defined $dataset->{'gbFile_id'} ) {
		$self->{error} .= ref($self)
		  . ":delete_gbFeatures_by_tag_name -> we do not know what to delete!(gbFile_id)\n";
	}
	return 0 if ( $self->{error} =~ m/\w/ );
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'delete_from_gbFeatures' } );
	unless (
		$sth->execute(
			$dataset->{'tag'}, $dataset->{'name'}, $dataset->{'gbFile_id'}
		)
	  )
	{
		die ref($self),
":delete_gbFeatures_by_tag_name -> we got a database error for query '",
		  $self->_getSearchString(
			'delete_from_gbFeatures', $dataset->{'tag'},
			$dataset->{'name'},       $dataset->{'gbFile_id'}
		  ),
		  ";'\n", $self->{dbh}->errstr();
	}
	return 1;
}

#sub _gbFeature_exists_in_the_database {
#	my ( $self, $gbFeature ) = @_;
#	my $string;
#	my @strings = $self->get_gbStrings_for_IDs(
#		$self->ID_for_feature_name_tag_and_start(
#			$gbFeature->Name,    $gbFeature->Tag,
#			$gbFeature->Start(), $gbFeature->End()
#		)
#	);
#	foreach $string (@strings) {
#		return 1 if ( $string eq $gbFeature->getAsGB() );
#	}
#	return 0;
#}
#
#sub ID_for_feature_name_tag_and_start {
#	my ( $self, $name, $tag, $start, $end ) = @_;
#
#	my ( @return, $tableName, @line, $sth );
#
#	$tableName = $self->TableName();
#
#	$sth = $self->_get_SearchHandle( { search_name => "selectID_NTS" } );
#	$sth->execute( $tag, $name, $start, $end );
#
#	while ( @line = $sth->fetchrow_array() ) {
#		push( @return, $line[0] );
#	}
#	return @return;
#}
#
#=head3 all_for_feature_tag_and_name
#
#Function: takes a feature tag and name and will return the ref to an array of hashes with the structure
#{ gbFile_id => <gbFile_id>, gbFeature => <gbFeature obj> }
#
#=cut
#
#sub all_for_feature_tag_and_name {
#	my ( $self, $tag, $name ) = @_;
#	## create the search handle
#	$self->{error} = $self->{warning} = '';
#
#	my ( $sth, @returnArray, @array );
#	$sth = $self->_get_SearchHandle(
#		{ search_name => "select_all_for_feature_tag_and_name" } );
#	## execute the search
#	$sth->execute( "$tag", "$name" );
#	## create the gbFeatures
#	my $i = 0;
#	while ( @array = $sth->fetchrow_array ) {
#		$i++;
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString( $array[1] );
#		push( @returnArray,
#			{ gbFile_id => $array[0], gbFeature => $gbFeature } );
#	}
#	if ( $i == 0 ) {    ## no results!
#		$i = $self->{select_all_for_feature_tag_and_name};
#		$i =~ s/\?/"$tag"/;
#		$i =~ s/\?/"$name"/;
#		$self->{error} .= ref($self)
#		  . ":all_for_feature_tag_and_name -> No results in search $i;\n";
#		warn "No results in search $i;\n";
#	}
#	## return the result hash
#	return \@returnArray;
#}

#sub IDs_for_gbFileID {
#	my ( $self, $gbFileID ) = @_;
#	my ($sth);
#
#	return undef unless ( $gbFileID > 0);
#
#	$sth = $self->_get_SearchHandle( { search_name => "selectIDs_by_gbFile" } );
#
#	unless ( $sth->execute($gbFileID) ) {
#		warn "we did not socceed in the mysql query at $self IDs_for_gbFileID";
#		return undef;
#	}
#	my ( @id, @return );
#	while ( @id = $sth->fetchrow_array() ) {
#		push( @return, $id[0] );
#	}
#	unless ( defined $return[0] ) {
#		## no results!
#		my $sql = $self->{'selectIDs_by_gbFile'};
#		$sql =~ s/\?/$gbFileID/;
#		warn "No results for search $sql;\n";
#	}
#	return @return;
#}

#sub get_gbStrings_for_gbFileID {
#	my ( $self, $gbFileID ) = @_;
#	my $result_array_ref = $self->getArray_of_Array_for_search(
#		{
#			'search_columns' => ['gbString'],
#			'where'          => [ [ 'gbFiles_id', '=', 'my value' ] ]
#		},
#		$gbFileID
#	);
#	my @return;
#	foreach (@$result_array_ref) {
#		push( @return, @$_[0] );
#	}
#	return @return;
#}
#
#sub get_gbStrings_for_IDs {
#	my ( $self, @IDs ) = @_;
#	my $result_array_ref = $self->getArray_of_Array_for_search(
#		{
#			'search_columns' => ['gbString'],
#			'where'          => [ [ 'gbFeaturesTable.id', '', \@IDs ] ]
#		}
#	);
#	my @return;
#	foreach (@$result_array_ref) {
#		push( @return, @$_[0] );
#	}
#	return @return;
#}
#
#=head2 get_gbFeatures_for_gbFileID
#
#Needs the table base name to look for the values and the gbFile_id to work.
#
#It will return a referect to an array of gbFeatures that are located on the given gbFile.
#Keep in mind, that you have to keep track, in which database the gbFile is located.
#Otherwise you might get features, that match to the (human) gbFile_id 1 instead of the (mouse) gbFile_id 1.
#
#The array should work fine with the L<gbFile|stefans_libs::gbFile>->Features function.
#
#=cut
#
#sub get_gbFeatures_for_gbFileID {
#	my ( $self, $gbFileID ) = @_;
#	my ( $gbStrings, @gbFeatures );
#	$gbStrings = $self->get_gbStrings_for_gbFileID($gbFileID);
#	foreach my $gbString (@$gbStrings) {
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString($gbString);
#		push( @gbFeatures, $gbFeature );
#	}
#	return \@gbFeatures;
#}
#
#sub _get_gbFeatures_for_gbFileID_tag_name {
#	my ( $self, $dataset ) = @_;
#	my ( $gbStrings, @gbFeatures );
#	$self->{error} = $self->{warning} = '';
#
#	$gbStrings = $self->_get_gbStrings_for_gbFileID_tag_name($dataset);
#	foreach my $gbString (@$gbStrings) {
#
#		# warn "we got gbFile string $gbString";
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString($gbString);
#		push( @gbFeatures, $gbFeature );
#	}
#	return \@gbFeatures;
#}

sub connect_to_db_xref {
	my ($self) = @_;
	push(
		@{ $self->{'table_definition'}->{'variables'} },
		{
			'name'         => 'id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'link to the db_xrf table',
			'data_handler' => 'db_xref_table'
		}
	);
	$self->{'data_handler'}->{'db_xref_table'} =
	  db_xref_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'db_xref_table'}
	  ->TableName( $self->TableBaseName() );
	return 1;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	
	unless (defined $self->{'data_handler'}->{'db_xref_table'} ){
		$self->{'data_handler'}->{'db_xref_table'} =  db_xref_table->new( $self->{'dbh'}, $self->{'debug'} );
		$self->{'data_handler'}->{'db_xref_table'}
	  ->TableName( $self->TableBaseName() );
	}
	
	$self->{'error'} .= '';
	my @data = $dataset->{gbFeature}->Info_for_Tag('db_xref');
	my @info;
	if ( defined $data[0] ) {
		$dataset->{'db_xref'} = [];
		foreach my $info (@data) {
			@$info[0] = $1 if ( @$info[0] =~ m/"(.*)"/ );
			@info = split( ":", @$info[0] );
			unless ( scalar(@info) == 2 ){
				warn ref($self)."::post_INSERT_INTO_DOWNSTREAM_TABLES -> db_xref data '@$info[0]' could not be parsed!";
				next ;
			}
			print "we try to insert into db_xref_table gbFile_id = $id; db_name = $info[0]; db_id = $info[1]\n";
			$self->{'data_handler'}->{'db_xref_table'}->AddDataset(
				{
					'gbFeature_id' => $id,
					'db_name'   => $info[0],
					'db_id'     => $info[1]
				}
			);
		}
	}
	return 1;
}

=head2 get_gbFeatures

This functions internally calls the function get_gbStrings to get the gbStings out of the database.
Afterwards it converts the gbStrings into the gbFeatures and returns the referece to that gbFeature array.
Therefore for this function the same resctrictions and possibilities as for the function get_gbStrings appllie.

=cut

sub get_gbFeatures {
	my ( $self, $dataset ) = @_;
	my ( $gbStrings, @gbFeatures );
	$gbStrings =
	  $self->get_Columns( { 'search_columns' => ['gbString'] }, $dataset );
	foreach (@$gbStrings) {
		my $gbFeature = gbFeature->new( "nix", "1..100" );
		$gbFeature->parseFromString($_);
		push( @gbFeatures, $gbFeature );
	}
	return \@gbFeatures;
}

=head2 get_Columns

This is a very powerfull function!
You have to specify which columns you want to get in return. If you specify only one columns you will get an list of these column entries.
If you specify more that one column, you will get an array or arrays containing the columns in the order you wanted them.

=head3 The first hash

The first hash should contain an array of column names you want to select. You can of cause select from the whole spectrum of columns we have in the table set.
But take care to name the table from whaere you want to select the column if the anme of the column is not unique!

In this hash we need:
over 1

=item 'search_columns' The name of the columns you want to select

=item 'complex_select' The complex_select string to get some more advanced SQL queries.

=back

The values for both keys are described for the variables_table::getArray_of_Array_for_search function, that is called internally.

=head3 The second hash

You can specify 'start', 'end', 'gbFile_id', 'gbFile_acc', 'chromosome', 'name' and 'tag'.

The searches depend on the values you have specified:

=over 1
=item - 'start', 'end', 'gbFile_id' or 'gbFile_acc', 'name' and 'tag'

You get all gbFeatures with the tag and name that overlapp the region between start and end on the named gbFile

=item -  'start', 'end', 'chromosome', 'name' and 'tag'

You get all gbFeatures with the tag and name that overlapp the region between start and end on the named chromosome

=item - 'gbFile_id' or 'gbFile_acc' , 'name' and 'tag'

You get all gbFeatures with the tag and name on the named gbFile

=item - 'chromosome' , 'name' and 'tag'

You get all gbFeatures with the tag and name on the named chromosome

=back

If either 'name' or 'tag' or both are not defined, you get all column entries, not only those that would match the 'name', 'tag' or both.

=cut

sub get_Columns {
	my ( $self, $hash, $dataset ) = @_;

	$hash->{'complex_select'} = "NIX"
	  unless ( defined $hash->{'complex_select'} );
	my ( $data, @columns );
	Carp::confess(
		ref($self)
		  . ":get_Columns -> we need a hash with the keys 'search_columns' and (optional) 'complex_select'\n"
	) unless defined( ref( $hash->{'search_columns'} ) eq "ARRAY" );
	@columns = @{ $hash->{'search_columns'} };

	return $self->__get_Columns_by_name( $hash, $dataset )
	  unless ( defined $dataset->{'tag'} );
	return $self->__get_Columns_by_tag( $hash, $dataset )
	  unless ( defined $dataset->{'name'} );

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFeaturesTable.tag',  '=', 'my value' ],
					[ 'gbFilesTable.id',      '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFeaturesTable.tag',  '=', 'my value' ],
					[ 'gbFilesTable.acc',     '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{

		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',       '=',  'my value' ],
					[ 'gbFeaturesTable.tag',        '=',  'my value' ],
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',        '=', 'my value' ],
					[ 'gbFeaturesTable.tag',         '=', 'my value' ],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'name'} && defined $dataset->{'tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFeaturesTable.tag',  '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'}
		);
	}
	else {
		Carp::confess(
			    ref($self)
			  . "_get_gbStrings_for_gbFileID_tag_name: we could not get gbStrongs without information what to get\n"
			  . root::get_hashEntries_as_string(
				$dataset, 3, "the unsufficient dataset:"
			  )
		);
	}

	unless ( defined @$data[0] ) {
		warn
"we did not get any results for the query '$self->{'complex_search'};'\n";
	}
	else {
		print "we executed '$self->{'complex_search'};' and got ",
		  scalar(@$data), " results\n";
	}
	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

sub __get_Columns_by_name {
	my ( $self, $hash, $dataset ) = @_;

	my ( $data, @columns );
	@columns = @{ $hash->{'search_columns'} };

	return $self->__get_Columns( $hash, $dataset )
	  unless ( defined $dataset->{'name'} );

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFilesTable.id',      '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFilesTable.acc',     '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',       '=',  'my value' ],
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',        '=', 'my value' ],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'name'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where' => [ [ 'gbFeaturesTable.name', '=', 'my value' ], ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
		);
	}
	else {
		Carp::confess(
			    ref($self)
			  . "_get_gbStrings_for_gbFileID_tag_name: we could not get gbStrongs without information what to get\n"
			  . root::get_hashEntries_as_string(
				$dataset, 3, "the unsufficient dataset:"
			  )
		);
	}

	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

sub __get_Columns_by_tag {
	my ( $self, $hash, $dataset ) = @_;

	my ( $data, @columns );
	@columns = @{ $hash->{'search_columns'} };

	return $self->__get_Columns( $hash, $dataset )
	  unless ( defined $dataset->{'tag'} );

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag', '=', 'my value' ],
					[ 'gbFilesTable.id',     '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag', '=', 'my value' ],
					[ 'gbFilesTable.acc',    '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',        '=',  'my value' ],
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',         '=', 'my value' ],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where' => [ [ 'gbFeaturesTable.tag', '=', 'my value' ] ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'}
		);
	}
	else {
		Carp::confess(
			    ref($self)
			  . "_get_gbStrings_for_gbFileID_tag_name: we could not get gbStrongs without information what to get\n"
			  . root::get_hashEntries_as_string(
				$dataset, 3, "the unsufficient dataset:"
			  )
		);
	}

	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

sub __get_Columns {
	my ( $self, $hash, $dataset ) = @_;

	my ( $data, @columns );
	@columns = @{ $hash->{'search_columns'} };

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [ [ 'gbFilesTable.id', '=', 'my value' ], ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where' => [ [ 'gbFilesTable.acc', '=', 'my value' ], ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where' =>
				  [ [ 'chromosomesTable.chromosome', '=', 'my value' ] ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'chromosome'}
		);
	}
	else {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [],
				'complex_select' => $hash->{'complex_select'}
			}
		);
	}

	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

#sub _get_gbFeatures_for_gbFileID_tag {
#	my ( $self, $dataset ) = @_;
#	my ( $gbStrings, @gbFeatures );
#	$self->{error} = $self->{warning} = '';
#	$gbStrings = $self->_get_gbStrings_for_gbFileID_tag($dataset);
#	foreach my $gbString (@$gbStrings) {
#
#		# warn "we got gbFile string $gbString";
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString($gbString);
#		push( @gbFeatures, $gbFeature );
#	}
#	return \@gbFeatures;
#}
#
#sub _get_gbStrings_for_gbFileID_tag {
#	my ( $self, $dataset ) = @_;
#
#	my $sth = $self->_get_SearchHandle(
#		{
#			'baseName'    => $dataset->{'baseName'},
#			'search_name' => 'select_gbString_for_gbID_tag_start_end'
#		}
#	);
#	print "we try ",
#	  $self->_getSearchString(
#		'select_gbString_for_gbID_tag_start_end',
#		$dataset->{'gbFile_id'},
#		$dataset->{'tag'}, $dataset->{'start'}, $dataset->{'end'}
#	  ),
#	  "\n";
#	unless (
#		$sth->execute(
#			$dataset->{'gbFile_id'}, $dataset->{'tag'},
#			$dataset->{'start'},     $dataset->{'end'}
#		)
#	  )
#	{
#		warn ref($self),
#		  ":_get_gbStrings_for_gbFileID_tag -> we got no search results for '",
#		  $self->_getSearchString(
#			'select_gbString_for_gbID_tag_start_end',
#			$dataset->{'gbFile_id'},
#			$dataset->{'tag'}, $dataset->{'start'}, $dataset->{'end'}
#		  ),
#		  "\n", $self->{dbh}->errstr();
#	}
#	my ( $gbString, @gbStrings );
#	$sth->bind_columns( \$gbString );
#	while ( $sth->fetch() ) {
#		push( @gbStrings, $gbString );
#	}
#	return \@gbStrings;
#}

1;
