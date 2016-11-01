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

=head1 parse_PPI_data.pl

A tool that restricts PPI data to select only direct GOI GOI interaction.

To get further help use 'parse_PPI_data.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::root;
use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $PPI_file, $GOI_list, $firstOrder, $outfile);

Getopt::Long::GetOptions(
	 "-PPI_file=s"    => \$PPI_file,
	 "-GOI_list=s"    => \$GOI_list,
	 "-outfile=s"     => \$outfile,    
	 "-only_first_order" => \$firstOrder,
	 "-help"             => \$help,
	 "-debug"            => \$debug,
);

my $warn = '';
my $error = '';

unless ( defined $PPI_file) {
	$error .= "the cmd line switch -PPI_file is undefined!\n";
}
unless ( defined $GOI_list) {
	$error .= "the cmd line switch -GOI_list is undefined!\n";
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
 command line switches for parse_PPI_data.pl

   -PPI_file         :the PPI file (1st order please!)
   -GOI_list         :the genes that were used to create the PPI file
   -outfile          :the new PPI data file
   -only_first_order :do not include connection between GOIs and 2ON GOIs
   -help           :print this help
   -debug          :verbose output
   

"; 
}

## now we set up the logging functions....

my ( $task_description, $GOI, $result, @PPI, $data );
my $count = 0;

## and add a working entry

$task_description = "parse_PPI_data.pl -PPI_file $PPI_file -GOI_list $GOI_list";


open ( IN,"<$PPI_file" ) or die "could not open the PPI_file $PPI_file\n";
open ( GENES,"<$GOI_list" ) or die "could not open the PPI_file $GOI_list\n";
while ( <GENES> ){
	chomp $_;
	$GOI -> {$_} = 1;
}
close ( GENES);
open ( OUT, ">$outfile" ) or die "could notr create outfile $outfile\n";
while ( <IN> ){
	chomp ( $_);
	@PPI = split ( "\t", $_);
	$data->{$PPI[0]} = {} unless ( defined $data->{$PPI[0]} );
	$data->{$PPI[0]}->{$PPI[1]} = 1;
}
close ( IN );
my ( $first, $second, $third);

foreach $first ( keys ( %$data )){
	next unless ($GOI ->{$first} ); ## not interested in not GOIs
	foreach $second ( keys %{$data->{$first}}){
		if ( $GOI ->{$second}){
			print OUT "$first\t$second\t1ON\n";
			$count++
		}
		elsif( ref ($data->{$second}) eq "HASH"){
			next if ( $firstOrder );
			print "we search for a second order connection for gene $first\n";
			foreach $third (keys %{$data->{$second}} ){
				next if ( $third eq $first);
				if ( $GOI ->{$third}){
					print OUT "$first\t$third\t2ON\n";
					#print OUT "$first\t$second\thelper2\n$second\t$third\thelper1\n" ;
					$count++;
				}
				
			}
		}
	}
}
close ( OUT );

print "We identified $count gene-gene connections!\n";
