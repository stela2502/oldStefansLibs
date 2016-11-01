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

=head1 remove_heterozygot_SNPs.pl

A tool to remove heterocygote SNP calls from a SNP table.

To get further help use 'remove_heterozygot_SNPs.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
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
 command line switches for remove_heterozygot_SNPs.pl

   -infile       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'remove_heterozygot_SNPs.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);

print $task_description."\n\n";
## Do whatever you want!

open ( IN , "<$infile") or die "could not open '$infile'\n";
open ( OUT ,">$outfile") or die "could not craete outfile '$outfile'\n";

my ( @line );
while ( <IN> ){
	chomp ( $_ );
	@line = split ( "\t" ,$_ );
	if ( $_ =~ m/^rs\d+/){
	for ( my $i = 1; $i < @line; $i ++){
		if ( $line[$i] =~ m/ *(\w) *\/ *(\w) */ ){
			$line[$i] = '' unless ( $1 eq $2 );
		}
		elsif ( $line[$i] =~ m/na.?/ ){
			$line[$i] = '';
		}
		else {
			die "sorry, but I can not parse the SNP call '$line[$i]'\n";
		}
	}
	}
	print OUT  join("\t",@line)."\n";
}
close ( IN );
 close ( OUT );
print "selected SNPs are in $outfile\n";
