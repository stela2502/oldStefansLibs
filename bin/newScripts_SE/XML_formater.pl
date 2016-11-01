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

=head1 XML_formater.pl

a simple script that reformats XML files

To get further help use 'XML_formater.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::exec_helper::XML_handler;

my ( $infile, $outfile, $help, $debug);

Getopt::Long::GetOptions(
	 "-infile=s"         => \$infile,
	 "-outfile=s"        => \$outfile,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

if ( $help ){
	print helpString( ) ;
	exit;
}

unless ( -f $infile && defined $outfile){
	print helpString( "we need a readable infile and a outfile!" ) ;
	exit;
}

my $XML_handler = XML_handler->new();
$XML_handler -> print_XML_job_description_2_file ( $XML_handler -> read_XML_job_description_from_file ( $infile), $outfile );


sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for XML_formater.pl
 
   -help           :print this help
   -debug          :verbose output


"; 
}