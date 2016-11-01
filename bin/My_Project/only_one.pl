#! /usr/bin/perl -w

#  Copyright (C) 2010-06-17 Stefan Lang

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

=head1 only_one.pl

A script, that deletes duplicate lines from a text file.

To get further help use 'only_one.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use Digest::MD5 qw(md5);
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $amount);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
         "-amount"      => \$amount,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
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
 command line switches for only_one.pl

   -infile       :the infile
   -amount       :if set, the amount of hits for a given line will be reported

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'only_one.pl';
$task_description .= " -infile $infile" if (defined $infile);


## Do whatever you want!

open ( IN ,"<$infile" ) or die "could not open infile $infile\n";

my (@data, $md5, $temp);

while ( <IN> ){
	$temp = md5($_);
	unless ( $md5->{$temp} ){
		push (@data, $_);
		$md5->{$temp} = 0;
	}
	$md5->{$temp} ++;
}
close ( IN );
open ( OUT , ">$infile.out" ) or die "could not create outfile $infile.out\n";
if ( $amount ) {
	print OUT "line\tcount\n";
	foreach ( @data ) {
	$temp = md5($_);
	chomp ( $_ );
	print OUT "$_\t$md5->{$temp}\n";
	}
}
else {
print OUT @data;
}
close (OUT);
print "cleaned file wirtten as $infile.out\n";
