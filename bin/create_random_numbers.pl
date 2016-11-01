#! /usr/bin/perl -w

#  Copyright (C) 2010-06-15 Stefan Lang

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

=head1 create_random_numbers.pl

A tool to create random numbers and saves the list one value per line.

To get further help use 'create_random_numbers.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::histogram_container;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $amount, $outfile);

Getopt::Long::GetOptions(
	 "-amount=s"    => \$amount,
	 "-outfile=s"    => \$outfile,
	 
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $amount) {
	$error .= "the cmd line switch -amount is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for create_random_numbers.pl

   -amount       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'create_random_numbers.pl';
$task_description .= " -amount $amount" if (defined $amount);
$task_description .= " -outfile $outfile" if (defined $outfile);


## Do whatever you want!
my ( @data, $value );
open ( OUT , ">$outfile" ) or die "could not craete outfile $outfile\n";
for (my $i = 0; $i < $amount; $i++){
	$value = rand();
	push ( @data, &log10($value) );
	print OUT $value."\n";
}
close (OUT);

my $hist = histogram_container->new();
$hist -> AddDataArray('random data',\@data);
$hist -> plot( $outfile.".histogram", 600, 400 );





sub log10 {
	my ($value) = @_;
	return log($value) / log(10);
}