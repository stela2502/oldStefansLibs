package familyHistory;

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
use stefans_libs::database::subjectTable::phenotype::phenotype_base_class;
use base 'phenotype_base_class';

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless (  ref($dbh) eq "DBI::db" );

	my $self = {
		'debug' => $debug,
		'dbh'   => $dbh,
	};

	bless $self, $class if ( $class eq "familyHistory" );


	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return 'dbh';

	#return "not a databse interface";
	#return "database_name";
}

sub Parse_module_spec_restr {
	my ( $self ) = @_;
	Carp::confess ( ref($self). "::Parse_module_spec_restr -> we need a module_spec_restr information, that should be inside of the phenotypes table!\n")
	unless ( defined $self->{'module_spec_restr'} );
	$self->{'possible_family_members'} = [ split(" ",$self->{'module_spec_restr'}) ];
	return 1;
}
sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	my $use = 0;
	foreach my $restriction ( @{$self->{'possible_family_members'}}){
		$use = 1 if ( $dataset->{'family_member'} =~ m/^$restriction$/ )
	}
	$self->{'error'} .= ref($self)."::DO_ADDITIONAL_DATASET_CHECKS - we do not support this family member name $dataset->{'family_member'}\n'".join ( "', '",@{$self->{'possible_family_members'}} )."'\n"
		unless ( $use);
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}


sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'subject_id',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the link to the subjects table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'family_member',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the type of the family member that is affected (mom, dad, sibling, ...)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'affection_type',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of the affection ( e.g. diabetes_type_2 )',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'affected',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'a binary value if the named family member is affected or not',
			'needed'      => ''
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['subject_id','family_member','affection_type']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
#	unless ( $self->tableExists( $self->TableName() ) ) {
#		$self->create();
#	}
### and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	#$self->{'data_handler'}->{''} =->new();
	return $dataset;
}

1;
