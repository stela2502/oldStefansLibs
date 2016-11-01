package phenotype_base_class;
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
use base 'variable_table';


sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "phenotype_base_class" );
  	
  	Carp::confess( ref($self)."->new I am only an iterface - you can not create an instance of me");

  	return $self;

}

sub Get_neededColumns {
	my ( $self ) = @_;
	my $data = {};
	foreach my $variable ( @{$self->{'table_definition'}->{'variables'}}){
		if ( $variable->{'name'} eq "subject_id" ){
			$data->{ 'subject_identifier' } = 1;
		}
		else {
			$data->{ $variable->{'name'} } = 1;
		}
	}
	return $data;
}

sub InsertMode{
	my ( $self, $subjectTable ) = @_;
	Carp::confess ( ref($self). "::InsertMode -> the table definition is not usable, as the first table_variable is not names 'subject_id' - please change that!\n ")
		unless ( @{$self->{'table_definition'}->{'variables'}}[0]->{'name'} eq "subject_id");
	my $temp;
	unless ( ref( $subjectTable ) eq "subjectTable" ){
		@{$self->{'table_definition'}->{'variables'}}[0]->{'data_handler'} = undef;
		$temp = $self->{'data_handler'} -> {'subjectTable'};
		unless ( defined $temp->{'var_id'}){
			$temp->{'var_id'} = {
				'name'        => 'id',
				'type'        => 'INTEGER UNSIGNED',
				'NULL'        => '0',
				'data_handler' => 'multiple',
				'link_to' => 'subject_id',
				'description' => 'The id links to multiple other table objects e.g.'
			};
			push ( @{$temp->{'table_definition'}->{'variables'}}, $temp->{'var_id'});
			$temp->{'data_handler'}->{'multiple'} = [];
		}
		push (@{$temp -> {'data_handler'}->{'multiple'}} , $self );
		$self->{'data_handler'} -> {'subjectTable'} = undef;
		return $temp;
	}
	else{
		$subjectTable->{'name'} = 'subjects';
		@{$self->{'table_definition'}->{'variables'}}[0]->{'data_handler'} = 'subjectTable';
		$self->{'data_handler'} -> {'subjectTable'} = $subjectTable;
		for ( my $i = 0; $i < @{$subjectTable->{'data_handler'}->{'multiple'}}; $i++){
			if ( @{$subjectTable->{'data_handler'}->{'multiple'}}[$i] eq $self ){
				splice(@{$subjectTable->{'data_handler'}->{'multiple'}},$i,1);
			}
		}
		if ( scalar ( @{$subjectTable->{'data_handler'}->{'multiple'}} ) == 0){
			
			$temp = pop (@{$subjectTable->{'table_definition'}->{'variables'}} );
			unless ( $temp -> {'name'} eq "id" ){
				push (@{$subjectTable->{'table_definition'}->{'variables'}},$temp );
			}
			$subjectTable->{'var_id'} = undef;
		}
		return 1;
	}
	return 0;
}

sub setRestriction {
	my ( $self, $hash ) = @_;
	Carp::confess( ref($self)."::setRestriction I need to have the hash keys ".
	"('table_name', 'name', 'module_spec_restr', 'min_val', 'max_val')")
	unless ( ref($hash) eq "HASH" );
	$self->setTableBaseName( $hash->{'table_name'});
	$self->{'name'} = $hash->{'name'};
	$self->{'min_val'} = $hash->{'min_val'};
	$self->{'max_val'} = $hash->{'max_val'};
	$self->{'module_spec_restr'} = $hash->{'module_spec_restr'};
	#print root::get_hashEntries_as_string ($self, 3, "my internal values after setRestriction");
	$self->Parse_module_spec_restr ();
	return 1;
}

sub Parse_module_spec_restr {
	my ( $self) = @_;
	Carp::confess ( ref($self)."::Parse_module_spec_restr has to be overwritten in this class!\n");
}

1;
