package ph_age;

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

#use Date::Calc;
use stefans_libs::database::subjectTable::phenotype::phenotype_base_class;
use base 'phenotype_base_class';

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless ( ref($dbh) eq "DBI::db" );

	my $self = {
		'debug' => $debug,
		'dbh'   => $dbh,
	};

	bless $self, $class if ( $class eq "ph_age" );

	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return 'dbh';

	#return "not a databse interface";
	#return "database_name";
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = ['date'];
	$hash->{'UNIQUES'}    = ['subject_id'];
	$hash->{'variables'}  = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'subject_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the subjects table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'birth',
			'type'        => 'DATE',
			'NULL'        => '0',
			'description' => 'the birthdate',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'death',
			'type'        => 'DATE',
			'NULL'        => '1',
			'description' => 'the day the person died',
			'needed'      => ''
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['subject_id']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables


## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	#$self->{'data_handler'}->{''} =->new();
	return $dataset;
}

sub Parse_module_spec_restr {
	my ( $self ) = @_;
	$self->{'min_val'} = Date::Simple->new( $self->{'min_val'} );
	$self->{'max_val'} = Date::Simple->new( $self->{'max_val'} );
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	unless ( defined $dataset->{'birth'} )
	{
		$self->{error} .= ref($self)
		  . ":check_dataset -> we definitely need a 'birth' date for the individual\n";
	}
	elsif ( ! (defined Date::Simple->new( $dataset->{'birth'} )) ){
		$self->{error} .= ref($self)
		  . ":check_dataset -> we can not parse the date '$dataset->{'birth'}'\n";
	}
	else {
		$dataset->{'birth'} = Date::Simple->new( $dataset->{'birth'} );
		if ( Date::Simple->new() - $dataset->{'birth'} <= 0 ){
			$self->{'error'} .=
"::DO_ADDITIONAL_DATASET_CHECKS -> the birthdate is after today - most obviously an error -or?\n";
		  return 0;
		}
		elsif ( defined $self->{'min_val'}  && $dataset->{'birth'} - $self->{'min_val'} < 0){
				$self->{error} .= ref($self) 
			. ":check_dataset -> the birth date is below the minimum birth date ".$self->{'min_val'}->as_iso()."\n";
		}
	}
	if ( defined $dataset->{'death'} ) {
		$dataset->{'death'} = Date::Simple->new( $dataset->{'death'} );
		#die "I ".ref( $dataset->{'death'} )." died at ".$dataset->{'death'}->as_iso()."\n";
		unless ( ref($dataset->{'death'}) eq "Date::Simple" ) {
			$self->{error} .= ref($self)
			  . ":check_dataset -> the given 'death' date could not be parsed!\n";
		}
		elsif ( $dataset->{'death'} - $dataset->{'birth'} < 1 ){
			$self->{error} .= ref($self)
			  . ":check_dataset -> the given 'death' was ".($dataset->{'death'} - $dataset->{'birth'} )." days prior to the given birth date!\n";
		}
	}

	if ( ref($dataset->{'birth'}) eq "Date::Simple"){
		if ( $self->{'connection'}->{'driver'} eq "mysql" ) {
			$dataset->{'birth'} = $dataset->{'birth'}->as_iso();
		}
		elsif ( $self->{'connection'}->{'driver'} eq "DB2" ) {
			$dataset->{'birth'} = $dataset->{'birth'}->as_iso();
			#$dataset->{'birth'} = $dataset->{'birth'}->format("%m/%d/%Y");
		}
		else {
			Carp::confess(
				ref($self)
				  . "::DO_ADDITIONAL_DATASET_CHECKS -> I can't create the DATE value for the database type '$self->{'connection'}->{'driver'}'\n"
			);
		}
	}
	if ( ref($dataset->{'death'}) eq "Date::Simple"){
		if ( $self->{'connection'}->{'driver'} eq "mysql" ) {
				$dataset->{'death'} = $dataset->{'death'}->as_iso();
			}
			elsif ( $self->{'connection'}->{'driver'} eq "DB2" ) {
				$dataset->{'death'} = $dataset->{'death'}->format("%m/%d/%Y");
			}
			else {
				Carp::confess(
					ref($self)
					  . "::DO_ADDITIONAL_DATASET_CHECKS -> I can't create the DATE value for the database type '$self->{'connection'}->{'driver'}'\n"
				);
			}
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

1;
