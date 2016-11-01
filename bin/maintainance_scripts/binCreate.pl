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

=head1 binCreate.pl

This script is used to craete new scripts with a first pod description and a helpString function.

To get further help use 'binCreate.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::root;
use strict;
use warnings;

my $VERSION = "v1.1";

my ( $help, $debug, $name, $pod, $force, @commandLineSwitches);

Getopt::Long::GetOptions(
	 "-pod=s"              => \$pod,
     "-name=s"           	 => \$name,
     "-force"            => \$force,
     "-commandLineSwitches=s{,}" => \@commandLineSwitches, 
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

if ( $help ){
	print helpString( ) ;
	exit;
}
unless ( defined $name ){
	print helpString( "ERROR: no name defined" );
	exit;
}
unless ( defined $pod) {
	print helpString( "ERROR: no description for the executable") ;
	exit;
}


my ($exec_name, $path, @file);

print "We got the name $name and the pod $pod\n" if ( $debug );

@file = split( "/", $name );
$exec_name = pop( @file );
$path = join ( "/", @file );
unless ( -d $path ){
	die "the path '$path' does not exist. Please create it!";
}
$exec_name = "$exec_name.pl" unless ($exec_name =~ m/\.pl$/);

if ( -f "$path/$exec_name"  && ! $force) {
	warn "\nthe file '$path/$exec_name' already exists!\nUse the -force switch to delete it\n\n";
	exit;
}

my ($add_2_variable_def, $add_2_variable_read, $add_2_help_string, $task_string );

$add_2_variable_def = $add_2_variable_read = $add_2_help_string = '';
$task_string = "\$task_description .= 'perl '.root->perl_include().' '.\$plugin_path .'/$exec_name';\n";
my $error_check = '';

foreach my $variableStr ( @commandLineSwitches ){
	if ( $variableStr =~ s/#array// ){
		$add_2_variable_def .= ", \@$variableStr";
		$add_2_variable_read .= "	 \"-$variableStr=s{,}\"    => \\\@$variableStr,\n";
		$add_2_help_string .= "   -$variableStr       :<please add some info!> you can specify more entries to that\n";
		$task_string .= "\$task_description .= ' -$variableStr '.join( ' ', \@$variableStr ) if ( defined \$$variableStr"."[0]);\n";
		$error_check .= "unless ( defined \$$variableStr"."[0]".") {\n".
		"	\$error .= \"the cmd line switch -$variableStr is undefined!\\n\";\n"
	."}\n";
	}
	else {
		$add_2_variable_def .= ", \$$variableStr";
	$add_2_variable_read .= "	 \"-$variableStr=s\"    => \\\$$variableStr,\n";
	$add_2_help_string .= "   -$variableStr       :<please add some info!>\n";
	$task_string .=  "\$task_description .= \" -$variableStr \$$variableStr\" if (defined \$$variableStr);\n";
	$error_check .= "unless ( defined \$$variableStr) {\n".
		"	\$error .= \"the cmd line switch -$variableStr is undefined!\\n\";\n"
	."}\n";
	}
	
}

my $string = "#! /usr/bin/perl -w

#  Copyright (C) ".root::Today()." Stefan Lang

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

=head1 EXECUTABLE

INFO_STR

To get further help use 'EXECUTABLE -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my \$plugin_path = \"\$FindBin::Bin\";

my \$VERSION = 'v1.0';


my ( \$help, \$debug, \$database$add_2_variable_def);

Getopt::Long::GetOptions(
$add_2_variable_read
	 \"-help\"             => \\\$help,
	 \"-debug\"            => \\\$debug
);

my \$warn = '';
my \$error = '';

$error_check

if ( \$help ){
	print helpString( ) ;
	exit;
}

if ( \$error =~ m/\\w/ ){
	print helpString(\$error ) ;
	exit;
}

sub helpString {
	my \$errorMessage = shift;
	\$errorMessage = ' ' unless ( defined \$errorMessage); 
 	return \"
 \$errorMessage
 command line switches for EXECUTABLE

$add_2_help_string
   -help           :print this help
   -debug          :verbose output
   

\"; 
}


my ( \$task_description);

$task_string

## Do whatever you want!

";

$string =~ s/EXECUTABLE/$exec_name/g;
$string =~ s/INFO_STR/$pod/g;

open ( OUT, ">$path/$exec_name") or die "could not create file '$path/$exec_name'\n";
print OUT $string;
close OUT;

print "\nnew executable written to '$path/$exec_name'\n\n";

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for binCreate.pl
   -pod            :a small text, that describes the function of the script (required)
   -name           :the name of the script as a full filename to the position of the script
   -force          :delete an existing script (no warning!)
   -commandLineSwitches
                   :a list of option switches that you want to have included into that script
   -database       :the databse to use for logging
   -help           :print this help
   -debug          :verbose output
 "; 
}