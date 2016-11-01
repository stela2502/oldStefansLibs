#! /usr/bin/perl -w

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

=head1 check_database_classes.pl

A small helper that can check database classes (all databseclasses)

To get further help use 'check_database_classes.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use File::HomeDir;
use stefans_libs::database;
use stefans_libs::root;

my ( $help, $debug );

Getopt::Long::GetOptions(
	"-help"  => \$help,
	"-debug" => \$debug
);

if ($help) {
	print helpString();
	exit;
}

my (
	$database_classes, $db_object,     $db_class,
	$dbh,              $database_name, $database_type,
	$variable,         $i,             @needed_variable_tags,
	$variable_tag,     @additional_values, $OK
);
$database_name        = 'test_db_genome';
$dbh                  = root::getDBH( 'root', $database_name );
@needed_variable_tags = ( 'name', 'type', 'NULL', 'description', 'needed' );

print "\n\n\n";
$database_classes = get_all_database_classes();
foreach $db_class (sort @$database_classes) {
	$OK = 1;
	next if ( $db_class eq "variable_table" );
	eval {
		( $database_type, @additional_values ) = $db_class->expected_dbh_type();
	};
	if ($@) {
		print "db_class $db_class lacks the function 'expected_dbh_type'\n";
		next;
	}
	if ( $database_type eq "dbh" ) {
		$db_object = $db_class->new( $dbh, @additional_values );
	}
	elsif ( $database_type eq "database_name" ) {
		$db_object = $db_class->new( $database_name, @additional_values );
	}
	else{
		print "db_class $db_class claims to be '$database_type' - it can't be cheched by this script!\n";
		$OK= 0;
		next;
	}
	unless ( defined $db_object->{'table_definition'} ) {
		print
"db_class $db_class lacks the variable \$self->{'table_definition'} \n"
		  . "\t-> you can get a sample version of that using the tool 'create_hashes_from_mysql_create.pl'\n";
		  $OK= 0;
		next;
	}
	unless ( ref( $db_object->{'table_definition'}->{'variables'} ) eq "ARRAY" )
	{
		print
"\tdb_class $db_class lacks the variable \$self->{'table_definition'}->{'variables'}\n"
		  . "\t-> you can get a sample version of that using the tool 'create_hashes_from_mysql_create.pl'\n";
		$OK= 0;
	}
	else {
		## check the variables!!
		$i = 0;
		foreach $variable (
			@{ $db_object->{'table_definition'}->{'variables'} } )
		{
			foreach $variable_tag (@needed_variable_tags) {
				unless ( defined $variable->{$variable_tag} ){
				print
"\t\t $db_class -> we need a '$variable_tag' for the table_variable '$variable->{'name'}' at position $i\n"
				  ;
				$OK= 0;
				}
			}
			print "\n" if ( $OK == 0);
			if ( defined $variable->{'data_handler'} && ! defined $db_object->{'data_handler'}->{$variable->{'data_handler'}}){
				print "\t\t $db_class you have defined a dependant data value '$variable->{'name'}',\n".
				" but not the corresponding data_handler \$self->{'data_handler'}->{'$variable->{'data_handler'}'}\n\n";
				$OK = 0;
			}
			if ( defined $variable->{'data_handler'} && ! ($variable->{'name'} =~ m/_id$/ ) ){
				print "\t\t $db_class you have defined a dependant data value '$variable->{'name'}',\n".
				" but the name does not end on _id -> that will lead to errors using the check_dataset and future export as XML functions\n\n";
				$OK = 0;
			}
			
			$i++;
		}
	}

	#INDICES
	unless ( ref( $db_object->{'table_definition'}->{'INDICES'} ) eq "ARRAY"
		&& defined @{ $db_object->{'table_definition'}->{'INDICES'} }[0] )
	{
		print
"\tdb_class $db_class lacks the variable \$self->{'table_definition'}->{'INDICES'}\n"
		  . "\tthis dataset is need to add INDICES to the table during the CREATE TABLE statement\n"
		  . "\t-> you can get a sample version of that using the tool 'create_hashes_from_mysql_create.pl'\n\n";
		$OK= -1 unless ( $OK == 0);
	}

	#UNIQUES
	unless ( ref( $db_object->{'table_definition'}->{'UNIQUES'} ) eq "ARRAY"
		&& defined @{ $db_object->{'table_definition'}->{'UNIQUES'} }[0]
	  )
	{
		print
"\tdb_class $db_class lacks the variable \$self->{'table_definition'}->{'UNIQUES'}\n"
		  . "\tthis dataset is need to add INDICES to the table during the CREATE TABLE statement\n"
		  . "\t-> you can get a sample version of that using the tool 'create_hashes_from_mysql_create.pl'\n\n" if ( $OK < 1);
		$OK= -2 unless ( $OK == 0);
	}
	unless ( ref( $db_object->{'UNIQUE_KEY'} ) eq "ARRAY" ) {
		print "\tdb_class $db_class lacks the variable \$self->{'UNIQUE_KEY'}\n"
		  . "\tthis dataset is need to execute the function $db_class->_return_unique_ID_for_dataset(\$dataset)\n"
		  . "\t-> you can get a sample version of that using the tool 'create_hashes_from_mysql_create.pl'\n\n" if ( $OK < 1);
		$OK= 0;
	}
	$OK = 1 if ( $OK == -1);
	$OK = 0 if ( $OK == -2);
	
	if ( $OK ){
		print "HURAY this class passed my test : '$db_class'\n";
	}
}

print "\n\n\n";

sub get_all_database_classes {

	my $target_dir =
	  '/home/stefan_l/workspace/Stefans_Libraries/lib/stefans_libs/database';
	my $awk_cmd  = '{print $8,"\n", $9, "\n", $10, "\n", $11 }';
	my $temp_dir = File::HomeDir->my_home() . "/temp";

	my ( @database_classes, $string );

	my $system_call =
"find $target_dir | awk -F\"/\" ' $awk_cmd ' | grep -o \[a-Z_24\]*.pm > $temp_dir/database_classes.txt";
	unless ( -f "$temp_dir/database_classes.txt" ) {
		die "please execute on the command line - I can't!\n$system_call\n";
	}

	open( IN, "<$temp_dir/database_classes.txt" )
	  or die "I could not open the file '$temp_dir/database_classes.txt'\n",
	  $!;
	while (<IN>) {
		$string = $_;
		chomp($string);
		if ( $string =~ m/^([\w_]+)\.pm$/ ) {
			push( @database_classes, $1 );
		}
	}
	return \@database_classes;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for check_database_classes.pl
 
   -help           :print this help
   -debug          :verbose output


";
}
