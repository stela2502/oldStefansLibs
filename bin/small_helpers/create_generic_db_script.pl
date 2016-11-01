#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
  if 0;    # not running under some shell

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

=head1 create_database_importScript.pl

A small scipt, that can read all values a table requires and creates an import script for these values. Including the XML definition files and all.

To get further help use 'create_database_importScript.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::root;
use strict;
use warnings;
use
  stefans_libs::database::variable_table::linkage_info::table_script_generator;

my ( $help, $debug, $executable_definition );

Getopt::Long::GetOptions(
	"-executable_definition=s" => \$executable_definition,
	"-help"                    => \$help,
	"-debug"                   => \$debug
);

if ($help) {
	print helpString();
	exit;
}

my (
	@variable,      $DB,                     $EXECUTABLE,
	$values,        $description,            $variables,
	$function_call, $table_script_generator, $includeStrings,
	$classPath,     $dbClass, $temp
);

$variables = $includeStrings = $values = 0;
$table_script_generator = table_script_generator->new();

open( DATA, "<$executable_definition" )
  or die
  "could not open the executable definition file '$executable_definition'\n";
while (<DATA>) {
	next if ( $_ =~ m/^#/ );
	chomp($_);
	if ( $_ =~ m/^executable_name=(\w+)/ ) {
		$EXECUTABLE = $1;
	}
	if ( $_ =~ m/^description=([ \w]+)/ ) {
		$description = $1;
	}
	elsif ( $_ =~ m/^data_handler_class=(\w+)/ ) {
		$dbClass = $1;
	}
	elsif ( $_ =~ m/^function_to_call=(\w+)/ ) {
		$function_call = $1;
	}
	elsif ( $_ =~ m/^includeStrings/ ) {
		$includeStrings = 1;
		next;
	}
	elsif ($variables) {
		if ( $_ =~ m/^finish includeStrings/ ) {
			$includeStrings = 0;
			next;
		}
	}
	elsif ( $_ =~ m/^variables/ ) {
		$variables = 1;
		next;
	}
	elsif ($variables) {
		if ( $_ =~ m/^finish variables/ ) {
			$variables = 0;
			next;
		}
	}
	elsif ( $_ =~ m/^values/ ) {
		$values = 1;
		next;
	}
	elsif ($values) {
		if ( $_ =~ m/^finish values/ ) {
			$values = 0;
			next;
		}
	}
	if ($includeStrings) {
		$classPath .= $_ . "\n";
	}
	if ($variables) {
		@variable = split( ";", $_ );
		die "sorry, but one variable definition line has to look like that\n"
		  . "<variable_name>;<variable_type>;<file_upload>;<NOT_needed>;<description>\n"
		  . "with  \n<variable_name> = a string WITHOUT spaces\n"
		  . "<variable_type> = one of ( VARCHAR(<integer>), TEXT, FILE )\n"
		  . "<file_upload> = 1||0\n"
		  . "<NOT_needed> = either 1 = NOT needed or 0 = needed\n"
		  . "<description> = a sring that describes the variable (no \" or ')\n"
		  if ( !( scalar(@variable) == 4 ) );
		my $hash = {
			$variable[0] => {
				'name'               => $variable[0],
				'type'               => $variable[1],
				'file_upload' => $variable[2],
				'NULL'               => $variable[3],
				'description'        => $variable[4],
			}
		};
		if ( $hash->{'type'} eq "DB" ) {
			## fuck! we have to be aware, that there is a DB query needed
			$hash->{'data_handler'} = $variable[0];
			$DB->{ $variable[0] } = 1;
		}
		$table_script_generator->VariableInformation($hash);
		next;
	}
}

unless ( defined $dbClass ) {
	die
"Sorry, but the executable_definition file did not contain a data_handler_class=(\\w+) definition of the data handler class\n";
}
unless ( defined $EXECUTABLE ) {
	die
"Sorry, but the executable_definition file did not contain a executable_name=(\\w+) definition\n";
}
unless ( defined $function_call ) {
	die
"Sorry, but the executable_definition file did not contain a function_to_call=(\\w+) definition\n";
}
unless ( defined $description ) {
	warn
"if you add a description=(\\w+) tag, we could add a usefull description of that executable to the help string\n";
	$description = '';
}

my ( $dbObj, $dbh, $database_name, $searchInterface );
$database_name = "geneexpress";

## and now we have to get all the possible variables in that dataset :-(

$table_script_generator->printXML_GUI_FormDef( "formdef_$EXECUTABLE.xml",
	$table_script_generator->CreateXML_formdef_Array() );

my $init_variables_str =
  $table_script_generator->Get_Add_to_Variable_Definition_String();
my $read_data_from_files = $table_script_generator->Get_READ_OPTIONS_string();

my $add_2_getOptions = $table_script_generator->Get_Add_to_GET_OPTIONS_string();

my $moreHelpStrings = $table_script_generator->createHelpString();

my $new_str = "my \$$dbClass = $dbClass->new ( )\n";

##ADD_TO_GET_OPTIONs
my $add_to_get_options =
  $table_script_generator->Get_Add_to_GET_OPTIONS_string();

my ($dataset) = $table_script_generator->getAddDatabaseDataset();

## OK and now we need to create the XML files!

## OK NOW we can create the executable script!

my $string = "#! /usr/bin/perl -w

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

=head1 $EXECUTABLE

INFO_STR

To get further help use '$EXECUTABLE -help' at the comman line.

=cut

use Getopt::Long;
$classPath
use Digest::MD5 qw(md5_hex);
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my ( \$help, \$debug, \$database_name, \$resorce_path, "
  . $table_script_generator->Get_Add_to_Variable_Definition_String() . " );

Getopt::Long::GetOptions(
	 \"-jobid=s\"  => \\\$resorce_path,
	 \"-database_name=s\"  => \\\$database_name,
$add_2_getOptions
	 \"-help\"             => \\\$help,
	 \"-debug\"            => \\\$debug
) or die (helpString());

if ( \$help ){
	print helpString( ) ;
	exit;
}

$read_data_from_files
" . "
$dataset

my ( \$error, \$dataStr) = check_dataset ( \$dataset );

if ( \$error =~ m/\\w/){
	print helpString( \$error ) ;
	exit;
}

$new_str

## now we set up the logging functions....

my ( \$workingTable, \$loggingTable, \$workLoad , \$loggingEntries );

\$workingTable = workingTable->new(\$database_name, \$debug);
\$loggingTable = loggingTable->new(\$database_name, \$debug);

## and add a working entry

my \$rv = \$workingTable->set_workload(
{
			'PID'       => \$\$,
			'programID' => '$EXECUTABLE',
			'description' =>
			  \"the dataset: \$dataStr\"
		}
);
" . "
unless ( defined \$rv) {
	print \"OOPS - we have a stuck process that wants to do the task - please mention that to your database administrator!\\n\";
	exit;
}

\$workLoad = \$workingTable->select_workloads_for_PID ( \$\$ );
\$loggingEntries = \$loggingTable->select_logs_for_description ( \"the dataset: \$dataStr\" );
unless ( defined \@\$loggingEntries[0]){

\$$dbClass->$function_call( \$dataset );

## work is finfished - we add a log entry and remove the workload entry!

\$loggingTable->set_log ( {
	'start_time' => \@\$workLoad[0]->{'timeStamp'},
	'evaluation_string' => \@\$workLoad[0]->{'programID'},
	'description' => \@\$workLoad[0]->{'description'}
}
);

}
else{
	print 'OOPS - the dataset was already present in the database!\n';
} 
\$workingTable->delete_workload_for_PID(\$\$);


sub check_dataset{
	my ( \$dataset, \$variable_name ) = \@_;
	my \$error = '';
	my \$dataStr = '';
	my (\$temp, \$temp_data);
	foreach my \$value_tag ( keys \%\$dataset ){
		\$dataStr .= \"-\$value_tag => \$dataset->{\$value_tag}, \" if ( defined \$dataset->{\$value_tag});
		#next if ( ref( \$dataset->{\$value_tag} ) eq \"HASH\" );
		unless (defined \$dataset->{\$value_tag} ){
			\$temp = \$value_tag;
			\$temp =~ s/_id//;
			if (  ref( \$dataset->{\$temp} ) eq \"HASH\" ){
				(\$temp, \$temp_data) = check_dataset ( \$dataset->{\$temp} );
				\$dataStr .= \$temp_data;
				\$error .= \"we miss the data for value \$value_tag and the downstream table:\\n\".\$temp if ( \$temp =~ m/\\w/) ;
			}
			else {
				\$error .= \"we miss the data for value \$value_tag\\n\";
			}
		}
	}
	
	return (\$error, \$dataStr);
}

sub helpString {
	my \$errorMessage = shift;
	\$errorMessage = ' ' unless ( defined \$errorMessage); 
 	
 	return \"
 	$description


 command line switches for EXECUTABLE

" . $table_script_generator->createHelpString() . "
   -help           :print this help
   -debug          :verbose output

\"; 
}
";

open( OUT, ">$EXECUTABLE" )
  or die "sorry, but I could not create the srcipt '$EXECUTABLE'\n";
print OUT $string;
close(OUT);

print "Script written to '$EXECUTABLE'\n";

open( OUT, ">sampleTableHeader-$EXECUTABLE.csv" )
  or die
"sorry, but I could not create the srcipt 'sampleTableHeader-$EXECUTABLE.csv'\n";
print OUT $table_script_generator->createHelpString();
print OUT $table_script_generator->create_sampleTableHeader();
close(OUT);
print "sample table header written to  'sampleTableHeader-$EXECUTABLE.csv'\n";

## and finally I want to check whether I can produce the XML form definitions

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for create_database_importScript.pl
 
   -help           :print this help
   -debug          :verbose output

";
}

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad );

