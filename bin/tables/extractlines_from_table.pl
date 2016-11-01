#! /usr/bin/perl -w

#  Copyright (C) 2011-02-23 Stefan Lang

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

=head1 extractlines_from_table.pl

A simple tool to extract lines from a text formated table.

To get further help use 'extractlines_from_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, @patterns, $outfile, $line_sep, $column_name, $column_id);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,
	 "-line_sep=s"    => \$line_sep,
	 "-column_name=s"    => \$column_name,
	 "-patterns=s{,}"  => \@patterns,
	 "-column_id=s"    => \$column_id,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $patterns[0] ){
	$error .= "the cmd line switch -patterns is undefined!\n";
}
unless ( defined $line_sep) {
	$line_sep = "\t";
}
if (! defined $column_name && ! defined $column_id ) {
	$error .= "the cmd line switch -column_name AND the -column_id is undefined!\n";
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
 command line switches for extractlines_from_table.pl

   -infile       :<please add some info!>
   -outfile       :<please add some info!>
   -line_sep       :<please add some info!>
   -column_name       :<please add some info!>
   -column_id       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/extractlines_from_table.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -line_sep $line_sep" if (defined $line_sep);
$task_description .= " -column_name $column_name" if (defined $column_name);
$task_description .= " -column_id $column_id" if (defined $column_id);

open ( OUT, ">$outfile.log") or die "I could not create the outfile $outfile.log\n$!\n";
print OUT $task_description."\n";
close (OUT);

if ( -f $patterns[0]){
	open ( IN , "<$patterns[0]" ) or die "I could not open the pattern file $patterns[0]\n$!\n";
	my @temp;
	while ( <IN> ){
		chomp ($_ );
		push ( @temp, split(/\s/,$_) );
	}
	close ( IN );
	shift @temp unless ( defined $temp[0]);
	@patterns = @temp;
}
my $pattern_hash;
foreach ( @patterns ){
	$pattern_hash->{$_} = 1;
}
## Do whatever you want!
my ( @line );
open ( IN , "<$infile" ) or die "I could not open the infile $infile\n$!\n";
open ( OUT , ">$outfile") or die "We could not create the outfile $outfile\n$!\n";

if ( defined $column_name ){
	$column_id = undef;
	while ( <IN> ) {
		chomp ( $_ );
		@line = split ( /$line_sep/, $_);
		unless ( defined $column_id ){
			for ( my $i = 0; $i < @line; $i ++ ){
				if ( $line[$i] eq $column_name ){
					$column_id = $i;
					last;
				}
			}
			Carp::confess ("we could not identify your column in the line '$_'\n")unless ( defined $column_id);
			print OUT "$_\n";
		}
		print OUT "$_\n" if ( $pattern_hash->{$line[$column_id]} );
	}
}
elsif ( defined $column_id ){
	while ( <IN> ) {
		chomp ( $_ );
		@line = split ( /$line_sep/, $_);
		print OUT "$_\n" if ( $pattern_hash->{$line[$column_id]} );
	}
}

close ( IN );
close ( OUT );
print "the restricted table has been written to $outfile\n";
