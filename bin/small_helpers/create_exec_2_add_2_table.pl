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

=head1 create_exec_2_add_2_table.pl

a tool that can create a binary to add to a database table using one of my database classes. Take care, as this scripts uses several built in command an variables. Change them if you change the location of the library.

To get further help use 'create_exec_2_add_2_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

my ( $help, $debug, $className, $executable_name);

Getopt::Long::GetOptions(
	 '-class_name=s'     => \$className,
	 '-executable_name=s' => \$executable_name,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

if ( $help ){
	print helpString( ) ;
	exit;
}



sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for create_exec_2_add_2_table.pl
 
   -class_name      :the name of the database class to use
   -executable_name :the name of the executable to build
   -help            :print this help
   -debug           :verbose output


"; 
}