package rsID_2_SNP;

#  Copyright (C) 2010 Stefan Lang

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

use stefans_libs::database::variable_table;
use stefans_libs::database::WGAS::SNP_calls;
use stefans_libs::database::genomeDB;

use base variable_table;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class if ( $class eq "rsID_2_SNP" );
	$self->init_tableStructure();

	return $self;

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
			'name'        => 'rsID',
			'type'        => 'VARCHAR (15)',
			'NULL'        => '0',
			'description' => 'the rsID',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'majorAllele',
			'type'        => 'CHAR (1)',
			'NULL'        => '1',
			'description' => 'the major allele (one nucleotide)'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'minorAllele',
			'type'        => 'CHAR (1)',
			'NULL'        => '1',
			'description' => 'the minor allele (one nucleotide)'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['rsID'] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['rsID'];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	#     unless ( $self->tableExists( $self->TableName() ) ) {
	#     	$self->create();
	#     }
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

=head2 decode_SNP

This function will convert a SNP in affymetrix 1-2-3 format into a Nucleotide_A Nucleotide_B format,
if you provide the following information:
'id' or 'rsID'
and 'value'. Therefore this function fits well to decode the data stored in the SNP_calls tables. 

=cut

sub decode_SNP {
	my ( $self, $hash ) = @_;
	my $error = '';
	Carp::confess("Sorry, but without data you will not get a result\n")
	  unless ( ref($hash) eq "HASH" );
	$error .=
"Sorry, but I can not use the value that is not one of  1, 2 or 3 ($hash->{'value'})\n"
	  unless ( $hash->{'value'} =~ m/^\-?[012]$/ );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my $id;
	if ( defined $hash->{'id'} ) {
		$id = $hash->{'id'};
	}
	else {
		$id = $self->_return_unique_ID_for_dataset($hash);
	}
	Carp::confess(
		root::get_hashEntries_as_string(
			$hash, 3, "Sorry, but I do not know the data for the dataset"
		)
	) unless ( defined $id );
	my ( $major, $minor ) = $self->__get_major_minor_4_id($id);
	return ( $major, $major )
	  if ( $hash->{'value'} == 0 );
	return ( $major, $minor )
	  if ( $hash->{'value'} == 1 );
	return ( $minor, $minor )
	  if ( $hash->{'value'} == 2 );
	return ( 0, 0 ) if ( $hash->{'value'} == -1 );
	Carp::confess( "SHIT - we have an critical error here, as you alleles "
		  . "'$hash->{'Allele_1'}' and '$hash->{'Allele_2'}' did not match to mine '$major', '$minor'"
	);
}

=head2 encode_SNP

This function will convert some SNP info into the affymetrix 0-1-2 format,
if you support either the right 'id' or the 'rsID' for the SNP and the values 
'Allele_1' and 'Allele_2'. The function will also performe some tests if 
the information stored in the database does fit to the given information. 

=cut

sub encode_SNP {
	my ( $self, $hash ) = @_;
	Carp::confess("Sorry, but without data you will not get a result\n")
	  unless ( ref($hash) eq "HASH" );
	my $error = '';
	$error .=
"Sorry, but I can not use a Allele_1 that is not one of AGCT ($hash->{'Allele_1'})\n"
	  unless ( $hash->{'Allele_1'} =~ m/^[AGCT0]$/ );
	$error .=
"Sorry, but I can not use a Allele_2 that is not one of AGCT ($hash->{'Allele_2'})\n"
	  unless ( $hash->{'Allele_2'} =~ m/^[AGCT0]$/ );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my $id;
	if ( defined $hash->{'id'} ) {
		$id = $hash->{'id'};
	}
	else {
		$id = $self->_return_unique_ID_for_dataset($hash);
	}
	Carp::confess(
		root::get_hashEntries_as_string(
			$hash,
			3,
			"Sorry, but I do not know the data for the dataset\n"
			  . $self->{'complex_search'}
		)
	) unless ( defined $id );

	my ( $major, $minor ) = $self->__get_major_minor_4_id($id);
	return 0
	  if ( $hash->{'Allele_1'} eq $major && $hash->{'Allele_2'} eq $major );
	return 1
	  if ( $hash->{'Allele_1'} eq $major && $hash->{'Allele_2'} eq $minor );
	return 2
	  if ( $hash->{'Allele_1'} eq $minor && $hash->{'Allele_2'} eq $minor );
	return -1 if ( $hash->{'Allele_1'} == 0 && $hash->{'Allele_2'} == 0 );
	Carp::confess( "SHIT - we have an critical error here, as you alleles "
		  . "'$hash->{'Allele_1'}' and '$hash->{'Allele_2'}' did not match to mine '$major', '$minor'"
	);
}

=head2 __get_SNP_dataset

This function should not be called by a script, as the dataset is quite complex.
But I will describe it for deveopers:

The function expects, that this object was created by the WGAS->GetDatabaseInterface_for_dataset
function. It does also need an array of rsIDs for which the data will be created.

The resulting data hash is structures like that:
{
'data' -> <sample_lable> -> <rsID> -> { 'AlleleA', 'AlleleB'}
'info' ->  <rsID> -> { 'Chr', 'position'} 
}
AlleleA and AlleleB will always be in the right order according to major and minor allele.

=cut

sub Organism_name {
	my ( $self, $tag ) = @_;
	$self->{'org_tag'} = $tag if ( defined $tag );
	$self->{'org_tag'} = 'H_sapiens' unless ( defined $self->{'org_tag'} );
	return $self->{'org_tag'};
}

sub GenomeInterface {
	my ($self) = @_;
	unless ( defined $self->{'gbInterface'} ) {
		$self->{'gbInterface'} = genomeDB->new();
		$self->{'gbInterface'} =
		  $self->{'gbInterface'}
		  ->GetDatabaseInterface_for_Organism( $self->Organism_name )
		  ->get_rooted_to('SNP_table');
	}
	return $self->{'gbInterface'};
}

sub __check_dataset {
	my ( $self, $dataset ) = @_;
	my $error = '';
	$error .= ref($self) . "::__check_dataset we need a has at startup\n"
	  unless ( ref($dataset) eq "HASH" );
	return $error . "no further checks possible\n" if ( $error =~ m/\w/ );
	$error .= ref($self) . "::__check_dataset we need an info hash\n"
	  unless ( ref( $dataset->{'info'} ) eq "HASH" );
	$error .= ref($self) . "::__check_dataset we need an data hash\n"
	  unless ( ref( $dataset->{'data'} ) eq "HASH" );
	return $error . "no further checks possible\n" if ( $error =~ m/\w/ );
	## now I only want to check if the Sample and SNP information is OK
	foreach my $sample ( keys %{ $dataset->{'data'} } ) {
		if (
			scalar( keys %{ $dataset->{'data'}->{$sample} } ) !=
			scalar( keys %{ $dataset->{'info'} } ) )
		{
			foreach my $rsID ( keys %{ $dataset->{'data'}->{$sample} } ) {
				$error .=
				  ref($self)
				  . "::__check_dataset we have no gb info for the rsID '$rsID'"
				  unless ( defined $dataset->{'info'}->{$rsID} );
			}
			foreach my $rsID ( keys %{ $dataset->{'info'} } ) {
				## OK that is not problematic - I will just delete the info
				next if ( defined $dataset->{'data'}->{$sample}->{$rsID} );
				$dataset->{'not in DB'} = {}
				  unless ( defined $dataset->{'not in DB'} );
				$dataset->{'not in DB'}->{$rsID} = 0
				  unless ( defined $dataset->{'not in DB'}->{$rsID} );
				$dataset->{'not in DB'}->{$rsID}++;
			}
		}
	}
	warn root::get_hashEntries_as_string ($dataset->{'not in DB'}, 3, "these things could all be 'not in DB':");
	return $error;
}

sub __convert_dataset_2_PHASE_string {
	my ( $self, $dataset ) = @_;
	my ( $error, $temp );
	$error = $self->__check_dataset($dataset);
	Carp::confess($error) if ( $error =~ m/\w/ );
	my ( $string, $line1, $line2, @rsIDs, $rsID, $sample, $SNP_description );
	warn root::get_hashEntries_as_string ($dataset->{'info'}, 3, "the info hash before the check: ");
	$line2 = scalar ( keys %{ $dataset->{'data'} }  );
	if ( defined $dataset->{'not in DB'} ) {
		#warn "we do the checks...\n";
		$self->{'not in DB'} = [];
		foreach $line1 ( keys %{ $dataset->{'not in DB'} } ) {
			if ( $dataset->{'not in DB'}->{$line1} == $line2 ) {
				$self->{'not_in_db'}->{$line1} = 1;
				#print "we have no data for SNP $line1\n";
				delete( $dataset->{'info'}->{$line1} );
				push( @{ $self->{'not in DB'} }, $line1 );
			}
		}
	}
	#warn root::get_hashEntries_as_string ($dataset->{'info'}, 3, "and the info hash after the check: ");
	$string =
	    scalar( keys %{ $dataset->{'data'} } ) . "\n"
	  . scalar( keys %{ $dataset->{'info'} } ) . "\nP";
	$line2 = scalar( keys %{ $dataset->{'data'} } );

	@rsIDs = (
		sort {
			$dataset->{'info'}->{$a}->{'position'} <=> $dataset->{'info'}->{$b}
			  ->{'position'}
		  } keys %{ $dataset->{'info'} }
	);
	$line1 = '';
	$SNP_description =
"#rsID\tposition\tmajor allele\tmajor [n]\tminor allele\tminor [n]\tMAF\tunknown [n]\n";
	my $rs_infos = {};
	foreach $rsID (@rsIDs) {
		$string .= " $dataset->{'info'}->{$rsID}->{'position'}";
		$line1  .= 'S';
		$temp = $self->{'data'}->{ $self->{'rs_2_id'}->{$rsID} };
		#print "we got the alleles: @$temp[0] and @$temp[1]\n";
		$rs_infos->{$rsID} = {
			"@$temp[0]" => 0,
			"@$temp[1]" => 0,
			'?'         => 0,
			'A_'         => "@$temp[0]",
			'B_'         => "@$temp[1]"
		};
		#print root::get_hashEntries_as_string ($rs_infos->{$rsID}, 3, "we created thios dataset");
	}
	$string .= "\n$line1\n";

	foreach $sample ( keys %{ $dataset->{'data'} } ) {
		$string .= "#$sample\n";
		$line1 = $line2 = '';
		foreach $rsID (@rsIDs) {
			unless ( defined $dataset->{'data'}->{$sample}->{$rsID} ) {
				$line1 .= '?';
				$line2 .= '?';
				$rs_infos->{$rsID}->{'none'} += 2;
			}
			if ( $dataset->{'data'}->{$sample}->{$rsID}->{'AlleleA'} eq "0" ) {
				$dataset->{'data'}->{$sample}->{$rsID}->{'AlleleA'} = '?';
			}
			if ( $dataset->{'data'}->{$sample}->{$rsID}->{'AlleleB'} eq "0" ) {
				$dataset->{'data'}->{$sample}->{$rsID}->{'AlleleB'} = '?';
			}
			$rs_infos->{$rsID}
			  ->{ $dataset->{'data'}->{$sample}->{$rsID}->{'AlleleA'} }++;
			$rs_infos->{$rsID}
			  ->{ $dataset->{'data'}->{$sample}->{$rsID}->{'AlleleB'} }++;
			$line1 .= $dataset->{'data'}->{$sample}->{$rsID}->{'AlleleA'} . " ";
			$line2 .= $dataset->{'data'}->{$sample}->{$rsID}->{'AlleleB'} . " ";
		}
		chop $line1;
		chop $line2;
		$string .= $line1 . "\n" . $line2 . "\n";
	}
	my @temp;
	foreach $rsID (@rsIDs) {
		if ( $rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} } +
			$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} } == 0 )
		{
			warn root::get_hashEntries_as_string(
				{
					'rs_Descriptions'     => $rs_infos,
					'problematic dataset' => $rs_infos->{$rsID}
				},
				5,
				"probably an error in the rs_Descriptions for rsID $rsID?"
			);
			@temp = ( '--', '--', '--', '--', '--' );
		}
		elsif ( $rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} } >
			$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} } )
		{
			@temp = (
				$rs_infos->{$rsID}->{'A_'},
				$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} },
				$rs_infos->{$rsID}->{'B_'},
				$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} },
				$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} } / (
					$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} } +
					  $rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} }
				)
			);
		}
		else {
			@temp = (
				$rs_infos->{$rsID}->{'B_'},
				$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} },
				$rs_infos->{$rsID}->{'A_'},
				$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} },
				$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} } / (
					$rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'A_'} } +
					  $rs_infos->{$rsID}->{ $rs_infos->{$rsID}->{'B_'} }
				)
			);
		}
		$SNP_description .=
		    "$rsID\t$dataset->{'info'}->{$rsID}->{'position'}\t"
		  . join( "\t", @temp )
		  . "\t$rs_infos->{$rsID}->{'?'}\n";
	}

	return $string, $SNP_description;
}

=head2 Print_SNP_List_4_PHASE

This function will print the informations about the RSids as PHASE input file

=cut

sub Print_SNP_List_4_PHASE {
	my ( $self, $rsIDs, $outfile, $search_interface ) = @_;
	Carp::confess("I need an array of rsIDs at startup!\n")
	  unless ( ref($rsIDs) eq "ARRAY" );
	my ( $str, $snp_description ) =
	  $self->__convert_dataset_2_PHASE_string(
		$self->__get_SNP_dataset( $rsIDs, $search_interface ) );
	if ( defined $outfile ) {
		open( OUT, ">$outfile" )
		  or die "I could not create the outfile $outfile\n$!\n";
		print OUT $str;
		close OUT;
		open( OUT, ">$outfile.descr" );
		print OUT $snp_description;
		print OUT "queried SNPs that were not genotyped\t"
		  . join( " ", @{ $self->{'not in DB'} } ) . "\n"
		  if ( ref $self->{'not in DB'} eq "ARRAY" );
		close OUT;
	}
	else {
		print $str. "\n" . $snp_description;
	}
	return $str;
}

sub __get_SNP_dataset {
	my ( $self, $rsIDs, $data ) = @_;
	Carp::confess(
		root::get_hashEntries_as_string( $self, 2,
			"this is inside of me $self ", 100 )
		  . "Sorry, but we \n$self->__get_SNP_dataset( $rsIDs, $data )\ndo not have any SNP_calls tables linked - you can not get data from this object!\n"
	  )
	  if ( !( ref( $self->{'data_handler'}->{'SNP_calls'} ) eq "ARRAY" )
		&& !ref($data) =~ m/\w/ );
	return undef unless ( ref($rsIDs) eq "ARRAY" );
	my ( $return, $complex, @temp, @column_titles, $temp, $rsID );

	$return = { 'info' => {}, 'data' => {} };
	## first we want to fill the info hash!
	$complex = "#1, #2+ #3, #4";
	foreach my $array (
		@{
			$self->GenomeInterface()->getArray_of_Array_for_search(
				{
					'search_columns' => [
						'SNP_table.rsID',
						'SNP_table.position',
						'chromosomesTable.chr_start',
						'chromosomesTable.chromosome'
					],
					'where' => [ [ 'SNP_table.rsID', '=', 'my_value' ] ],
					'complex_select' => \$complex,
				},
				$rsIDs
			)
		}
	  )
	{
		last unless ( ref($array) eq "ARRAY" );
		$return->{'info'}->{ @$array[0] } =
		  { 'position' => @$array[1], 'Chr' => @$array[2] };
	}
	$self->{'warn'} = '';
	foreach $rsID (@$rsIDs) {
		unless ( ref( $return->{'info'}->{$rsID} ) eq "HASH" ) {
			$self->{'warn'} .= "No chromosomal position for SNP $rsID\n";
		}
	}
	## Now we have all the info that was necessary for the SNP poitions
	## Next: get the SNP calls for all the indviduals!
	$data = '' unless ( defined $data );
	print "and now we are interested in the SNP values ($data)\n"
	  if ( $self->{'debug'} );
	if ( ref($data) eq "variable_table::queryInterface" ) {
		print "Oh we will get them from the $data object!\n"
		  if ( $self->{'debug'} );
		$data = $data->get_data_table_4_search(
			{
				'search_columns' => [ ref($self) . ".rsID", 'SNP_calls.value' ],
				'where' => [ [ ref($self) . ".rsID", '=', 'my_value' ] ]
			},
			$rsIDs
		);
	}
	unless ( ref($data) eq "data_table" ) {
		print
"OK - we 'own' the data - therefore we will take the data directly from the DB\n"
		  if ( $self->{'debug'} );
		$data = $self->get_data_table_4_search(
			{
				'search_columns' => [ ref($self) . ".rsID", 'SNP_calls.value' ],
				'where' => [ [ ref($self) . ".rsID", '=', 'my_value' ] ]
			},
			$rsIDs
		);
	}

	#print ref($self)."ew print the result\n".$data->AsString()."\n";
	@column_titles = ( 'rsID', $self->Sample_Lables() );
	for ( my $i = 0 ; $i < scalar(@column_titles) ; $i++ ) {

	 #print "we change the column title for column $i to  $column_titles[$i]\n";
		$data->set_HeaderName_4_position( $column_titles[$i], $i );
	}

	#print ref($self)."we print the result\n".$data->AsString()."\n";
	$self->__init_whole_internal_dataset();
	## as we will convert quite some SNPs here we might verry well initialize the whole dataset!
	## now we have to convert the results into a funny little dataset!
	my $sample_title;

#$data->line_separator( ";");
#print "we are going to convert this data table to a internal data structure:\n".$data->AsString()."\n";
	for ( my $i = 1 ; $i < @{ $data->{'header'} } ; $i++ ) {
		$sample_title = @{ $data->{'header'} }[$i];
		Carp::confess(
			root::get_hashEntries_as_string(
				$data->{'header'},                          3,
				" Oops - the coluimn $i is unnamed - why?", 100
			)
		) unless ( defined $sample_title );
		$temp = $data->getAsHash( 'rsID', $sample_title );

#print root::get_hashEntries_as_string ($temp , 3, "we selected $data->getAsHash( 'rsID', '$sample_title' ) and we got ");
		$return->{'data'}->{$sample_title} = {};
		foreach $rsID ( keys %$temp ) {
			if ( !defined $temp->{$rsID} || $temp->{$rsID} eq "" ) {
				Carp::confess(
					"we have missing data - is that a bug? $rsID $sample_title?"
				);
			}
			@temp = $self->decode_SNP(
				{ 'rsID' => $rsID, 'value' => $temp->{$rsID} } );
			$return->{'data'}->{$sample_title}->{$rsID} =
			  { 'AlleleA' => $temp[0], 'AlleleB' => $temp[1] };
		}
	}

#print root::get_hashEntries_as_string ($return, 3, "that should now contain the results ");
	return $return;
}

sub __init_whole_internal_dataset {
	my ($self) = @_;
	return 1 if ( defined $self->{'data'} );
	$self->{'data'}    = {};
	$self->{'rs_2_id'} = {};
	foreach (
		@{
			$self->getArray_of_Array_for_search(
				{
					'search_columns' => [
						ref($self) . ".id",
						ref($self) . ".majorAllele",
						ref($self) . ".minorAllele",
						ref($self) . ".rsID"
					],
					'where' => []
				}
			)
		}
	  )
	{
		$self->{'data'}->{ @$_[0] } = [ @$_[1], @$_[2] ];
		$self->{'rs_2_id'}->{ @$_[3] } = @$_[0];
	}
	return 1;
}

sub __get_major_minor_4_id {
	my ( $self, $id ) = @_;
	Carp::confess("No id - no data!\n") unless ( defined $id );
	return @{ $self->{'data'}->{$id} }
	  if ( ref( $self->{'data'}->{$id} ) eq "ARRAY" );
	$self->{'data'}->{$id} = @{
		$self->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ ref($self) . ".majorAllele", ref($self) . ".minorAllele" ],
				'where' => [ [ ref($self) . ".id", "=", "my_value" ] ]
			},
			$id
		)
	  }[0];
	return @{ $self->{'data'}->{$id} };
}

sub Add_SNP_call_data {
	my ( $self, $SNP_call_data, $SNPcalls_Table_name ) = @_;
	$self->{'error'} = '';

   #Carp::confess( "Add_SNP_call_data ($SNP_call_data, $SNPcalls_Table_name )");
	$self->{'error'} .=
	  ref($self) . "::Add_SNP_call_data - we did not get any data! \n"
	  unless ( ref($SNP_call_data) eq "ARRAY" );
	$self->{'error'} .=
	  ref($self)
	  . "::Add_SNP_call_data - we need to know the SNPcalls_Table_name!\n"
	  unless ( defined $SNPcalls_Table_name );
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );

	my $Call_table =
	  $self->Add_SNP_calls_Table( { 'tableName' => $SNPcalls_Table_name } );
	foreach my $value ( @{$SNP_call_data} ) {
		$Call_table->BatchAddDataset( { 'value' => $value } );
	}
	return 1;
}

sub Sample_Lables {
	my ( $self, $sample_labels ) = @_;
	return ()
	  if ( !ref( $self->{'data_handler'}->{'SNP_calls'} ) eq "ARRAY"
		&& !ref($sample_labels) eq "ARRAY" );
	my @sample_lables;
	if ( ref($sample_labels) eq "ARRAY" ) {
		## Oh - we have a buggy interface and need to store that value - shit
		## the seast problematic way would be to create the set of data objects!
		unless ( ref( $self->{'data_handler'}->{'SNP_calls'} ) eq "ARRAY" ) {
			$self->{'data_handler'}->{'SNP_calls'} = [];
		}
		Carp::confess("No - you must not rename a once set SamleList!\n")
		  if ( scalar( @{ $self->{'data_handler'}->{'SNP_calls'} } ) > 0 );
		my $i = 0;
		foreach my $SL (@$sample_labels) {
			my $temp = SNP_calls->new( $self->{'dbh'} );
			$temp->Sample_Lable($SL);
			@{ $self->{'data_handler'}->{'SNP_calls'} }[ $i++ ] = $temp;
		}
	}
	foreach my $SNP_calls ( @{ $self->{'data_handler'}->{'SNP_calls'} } ) {
		push( @sample_lables, $SNP_calls->Sample_Lable() );
		## This only works if the sample lable was known while creating the data structure.
		## 3rd value with $self->Add_oligo_array_values_Table had to be set!!
	}
	return @sample_lables;
}

sub Add_SNP_calls_Table {
	my ( $self, $hash ) = @_;
	my ( $tableName, $tableBaseName, $sample_id, $sample_lable );
	Carp::confess("format has changed - I need a has as argument")
	  unless ( ref($hash) eq "HASH" );
	$tableName     = $hash->{'tableName'};
	$tableBaseName = $hash->{'tableBaseName'};
	$sample_id     = $hash->{'sample_id'};
	$sample_lable  = $hash->{'sample_lable'};

#print ref($self). " - We added a data table $tableName, $tableBaseName, $sample_id, $sample_lable\n";
	unless ( defined $tableName ) {

		# I will now create a table base name
		unless ( defined $tableBaseName && defined $sample_id ) {
			Carp::confess(
				"Internal error - I could not create a SNP_calls table name!");
		}
		$tableName = "$tableBaseName" . "_" . "$sample_id";
	}
	unless ( ref( $self->{'data_handler'}->{'SNP_calls'} ) eq "ARRAY" ) {
		push(
			@{ $self->{'table_definition'}->{'variables'} },
			{
				'name'         => 'id',
				'data_handler' => 'SNP_calls',
				'type'         => 'INTEGER',
				'description'  => "this is an artefact of process $$",
				'NULL'         => 0
			}
		);
		$self->{'data_handler'}->{'SNP_calls'} = [];
	}

	my $SNP_calls;
	foreach $SNP_calls ( @{ $self->{'data_handler'}->{'SNP_calls'} } ) {
		if ( defined $tableName ) {
			if ( $SNP_calls->TableName() eq $tableName ) {
				return $SNP_calls;
			}
		}
		if ( defined $tableBaseName ) {
			if ( $SNP_calls->{'_tableName'} eq $tableBaseName ) {
				return $SNP_calls;
			}
		}
	}

	$SNP_calls = SNP_calls->new( $self->{'dbh'}, $self->{'debug'} );
	$SNP_calls->linked_table_name( $self->TableName() );

	if ( defined $tableName ) {
		$SNP_calls->{'_tableName'} = $tableName;
		$SNP_calls->TableName();
	}
	elsif ( defined $tableBaseName ) {
		$SNP_calls->TableName($tableBaseName);
	}

	$SNP_calls->{'FOREIGN_TABLE_NAME'} = $self->TableName();
	@{ $self->{'data_handler'}->{'SNP_calls'} }
	  [ scalar( @{ $self->{'data_handler'}->{'SNP_calls'} } ) ] = $SNP_calls;
	$SNP_calls->Sample_Lable($sample_lable);

#Carp::confess( "I know we had some errors - this is just for the tracking of the error!\n".root::get_hashEntries_as_string ($SNP_calls, 3, "And to see what is in the \$SNP_calls: "));
	return $SNP_calls;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
