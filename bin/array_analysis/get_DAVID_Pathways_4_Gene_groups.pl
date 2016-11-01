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

=head1 get_DAVID_Pathways_4_Gene_groups.pl

a script that initially retrieves the data from the DAVID web site. Possibly the script can get a Database interface in the future.

To get further help use 'get_DAVID_Pathways_4_Gene_groups.pl -help' at the comman line.

=cut

use Getopt::Long;
use WWW::Mechanize;
use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $gene_groups_file, $outpath);

Getopt::Long::GetOptions(
	 "-gene_groups_file=s"    => \$gene_groups_file,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug,
);

my $warn = '';
my $error = '';

unless ( -f $gene_groups_file) {
	$error .= "the cmd line switch -gene_groups_file is undefined!\n";
}
unless ( -d $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
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
 command line switches for get_DAVID_Pathways_4_Gene_groups.pl

   -gene_groups_file       :<please add some info!>
   -outpath       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

"; 
}

## now we set up the logging functions....

my ( $task_description, $Mech, $temp, $html, @line, $genes);

$Mech = WWW::Mechanize->new( 'stack_depth' => 2 );
$Mech->get("http://david.abcc.ncifcrf.gov/");
$html = 'http://david.abcc.ncifcrf.gov/api.jsp?type=OFFICIAL_GENE_SYMBOL&ids=PUT_THE_IDS_HERE&tool=chartReport&annot=GOTERM_BP_ALL,GOTERM_CC_ALL,GOTERM_MF_ALL,KEGG_PATHWAY,TRANSFAC_ID';
$task_description = "get_DAVID_Pathways_4_Gene_groups.pl -gene_groups_file $gene_groups_file -outpath $outpath";

open ( IN , "<$gene_groups_file" ) or die "could not open the -gene_groups_file $gene_groups_file\n";
while ( <IN> ){
	chomp($_);
	@line = split ("\t",$_);
	open (OUT,  ">$outpath/".join("_",split(/[\/ ]/,$line[0]))."out.html" ) or die "I could not create the file ".join("_",split(/\/_/,$line[0]))."out.html"."\n";
	$temp = $html;
	$genes = join(",", split(" ", $line[1]) );
	$temp =~ s/PUT_THE_IDS_HERE/$genes/;
	print "we will get '$temp'\n";
	$Mech->put($temp);
	$Mech->reload();
	print OUT $Mech->content();
	close ( OUT );
	last if ( $debug );
}
