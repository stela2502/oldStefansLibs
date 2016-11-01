package executable_table;

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
use base variable_table;
use File::Copy;

use stefans_libs::database::system_tables::PluginRegister;

##use some_other_table_class;

=head1 package 'executable_table'

=head2 DESCRIPTION

This package handles the 'executables_table' script definition table.
It depends on the configuration table, as the path to the XML files is
saved using this table ('xml_formdef_path'). We expect the formdef to 
be stored in a path named as the module_id.

=cut

use strict;
use warnings;
use XML::Simple;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug           => $debug,
		dbh             => $dbh,
		'XML_interface' => XML::Simple->new(
			ForceArray => [ 'step', /columns/, 'variable_names' ],
			AttrIndent => 1
		),
	};

	bless $self, $class if ( $class eq "executable_table" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "executables_table";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'plugin_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the plugin register',
			'data_handler' => 'PluginRegister'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_name',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the name of the execuable',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_version',
			'type'        => 'VARCHAR (5)',
			'NULL'        => '0',
			'description' => 'the vresion of the executable',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'XML_filename',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the name of the formdef xml file',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_description',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'a short description of the executable',
		}
	);
	push( @{ $hash->{'UNIQUES'} },
		[ 'executable_name', 'executable_version' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = [ 'executable_name', 'executable_version' ];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	$self->{'data_handler'}->{'PluginRegister'} =
	  PluginRegister->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}


sub install_script{
	my ( $self, $PluginName, $PluginID, $script_file, $XML_file ) = @_;
	my $configuration = configuration->new('' ,0);
	my $script_path = $configuration ->GetConfigurationValue_for_tag('catalyst_perl_scripts');
	my $xml_path =  $configuration ->GetConfigurationValue_for_tag('xml_formdef_path');
	my $error = '';
	unless ( -d $script_path ){
		$error .= "sorry, but I can not access the 'catalyst_perl_scripts' path '$script_path'\n";
	}
	unless ( -d $xml_path ){
		$error .= "sorry, but I can not access the 'xml_formdef_path' path '$xml_path'\n";
	}
	unless ( $self->check_formdef($XML_file)){
		$error .= $self->{'error'};
	}
	if ( $error =~ m/\w/ ){
		warn ( "Sorry, but I could not install the scriptfile $script_file due to the errors:\n".$error);
		return 0;
	}
	my @temp = split ("/",$script_file);
	my $script = $temp[@temp-1];
	root->CreatePath($script_path."/$PluginName" );
	copy( $script_file, $script_path."/$PluginName/$script" ) or Carp::confess("we could not copy '$script_file' to  $script_path/$PluginName/$script \n$!\n");
	@temp = split ("/",$XML_file);
	my $formdef =  $temp[@temp-1];
	root->CreatePath($xml_path."/$PluginName" );
	copy( $XML_file, $xml_path."/$PluginName/$formdef" ) or Carp::confess( "we could not copy \n$!\n");
	open ( SCR , "<$script_path/$PluginName/$script") or Carp::confess ( "we could not copy the file!\n");
	@temp = undef;
	my $read = 0;
	my $version = '';
	foreach my $line ( <SCR> ){
		$read = 0 if ( $line =~ m/^To get further help use /);
		if ( $read ){
			chomp ( $line );
			push ( @temp, $line ) ;
		}
		
		$read = 1 if ( $line =~ m/^=head1 /);
		$version = $1 if ( $line =~ m/VERSION = 'v(.+)';/);
	}
	close ( SCR );
	$script =~ s/.pl$//;
	$formdef =~ s/.XML$//;
	$self->AddDataset( {'executable_description' => join(" ", @temp),'plugin_id' => $PluginID, 'executable_name' => $script, 'executable_version' => $version, 'XML_filename' => $formdef  } );
	return 1;
}

sub check_formdef {
	my ( $self, $filename ) = @_;
	my $error = '';
	unless ( -f $filename ) {
		$error .= "check formdef $filename - the file does not exist!\n";
	}
	else {
		my $XML_definition = $self->{'XML_interface'}->XMLin($filename);
		my $linkage_info   = linkage_info->new();
		my ( $big_step, $i, $i2 );
		$i = 0;
		warn root::get_hashEntries_as_string ($XML_definition, 10, "that should look better! ") ;
		foreach $big_step ( @{ $XML_definition->{'step'} } ) {
			$i++;
			$i2 = 0;
			
			foreach my $step ( @{ $big_step->{'columns'} } ) {
				$i2++;
				$linkage_info->{'error'} = '';
				if ( defined $step->{'type'} && $step->{'type'} eq "db" ) {
					if ( defined $step->{'where_array'} ) {
						$error .= $linkage_info->{'error'}
						  unless (
							$linkage_info->__check_where_array(
								$step->{'where_array'}
							)
						  );
					}
				}
				else {
					$error .= "we miss the 'thing' in step_$i/value_$i2\n"
					  unless ( defined $step->{'thing'} );
					$error .= "we miss the 'label' in step_$i/value_$i2\n"
					  unless ( defined $step->{'label'} );
				}
			}
		}
		$big_step = @{ $XML_definition->{'step'} }[@{ $XML_definition->{'step'} }-1];
		unless ( $big_step->{'command'} ) {
			$error .= root::get_hashEntries_as_string ($big_step, 3,"the final step does not include the script file name!");
		}

	}
	$self->{'error'} = $error;
	if ( $error =~ m/\w/ ) {
		warn $error . "\n";
		return 0;
	}
	
	return 1;
}

sub create_job {
	my ( $self, $c, $cmd, $executable ) = @_;
	return $c->model('jobTable')->AddDataset(
		{
			'description'         => $c->session->{'description'},
			'scientist'           => { 'username' => $c->user() },
			'labbook_instance_id' => $c->session->{'Enrty_id'},
			'labbook_id'          => $c->session->{'LabBook_id'},
			'job_type'            => 'perl_script',
			'cmd'                 => $cmd,
			'executable'          => $executable
		}
	);
}

sub expected_dbh_type {
	return 'dbh';
}

1;
