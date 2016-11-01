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

=head1 affy_csv_to_tsv.pl

a simple conversion tool to convert affymetrix csv files to 'normal' tab separated files. 
Hopefully, the table merger can handle the files afterwards....

To get further help use 'affy_csv_to_tsv.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

my ( $help, $debug, $source, $drain);

Getopt::Long::GetOptions(
	"-sourceFile=s"      => \$source,
	"-outputFile=s"      => \$drain,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

unless ( -f $source ){
	print helpString( "I can't open the source file ('$source')") ;
	exit;
}

unless ( defined $drain ){
	print helpString( "you have to define the outfile!") ;
	exit;
}

if ( $help ){
	print helpString( ) ;
	exit;
}
my ( @line );

open ( IN ,"<$source") or die "could not open $source\n$!";
open ( OUT , ">$drain") or die "could not create outfile ('$drain')\n$!\n!";

while ( <IN>){
	print OUT $_ if ( $_ =~ m/^#/);
	@line = split ( "\",\"", $_ );
	$line[0] =~ s/"//;
	$line[@line-1] =~ s/"//;
	print OUT join ("\t", @line);
}

close (IN);
close (OUT);
print "data written to $drain\n";

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for affy_csv_to_tsv.pl
   
   -sourceFile     :the file that should be converted
   -outputFile     :the output file
   -help           :print this help
   -debug          :verbose output


"; 
}