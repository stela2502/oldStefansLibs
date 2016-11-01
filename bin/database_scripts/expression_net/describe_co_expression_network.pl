#! /usr/bin/perl -w

#  Copyright (C) 2010-12-01 Stefan Lang

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

=head1 describe_co_expression_network.pl

We mainly count the number of coexpressed genes per gene.

To get further help use 'describe_co_expression_network.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::expression_net_reader;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $expression_net_file, $outfile, @genes_of_interest);

Getopt::Long::GetOptions(
	 "-expression_net_file=s"    => \$expression_net_file,
	 "-outfile=s"    => \$outfile,
	 "-genes_of_interest=s{,}"    => \@genes_of_interest,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $expression_net_file) {
	$error .= "the cmd line switch -expression_net_file is undefined!\n";
}
unless ( defined $outfile) {
	#$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for describe_co_expression_network.pl

   -expression_net_file :the expression net you want to get infos on
   -outfile             :where to print the infos to
   -genes_of_interest   :a list or file containing the seeder genes
   
   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'describe_co_expression_network.pl';
$task_description .= " -expression_net_file $expression_net_file" if (defined $expression_net_file);
$task_description .= " -outfile $outfile" if (defined $outfile);

if ( -f $genes_of_interest[0] ) {
	open( IN, "<$genes_of_interest[0]" )
	  or die "could not read your gene list!\n";
	my @temp;
	while (<IN>) {
		chomp($_);
		push( @temp, split( /\s+/, $_ ) );
	}
	shift(@temp) unless ( defined $temp[0] );
	@genes_of_interest = @temp;
	close(IN);
}

my ($expression_net_reader , $gene_to_group );

$expression_net_reader = expression_net_reader->new();
$expression_net_reader->Read_from_File( $expression_net_file,
	\@genes_of_interest );
$expression_net_reader->__define_connection_groups();


foreach my $group_key (
	keys %{ $expression_net_reader->{'connection_group_description'} } )
{
	foreach my $gene (
		@{
			$expression_net_reader->{'connection_group_description'}
			  ->{$group_key}->{'connecting_genes'}
		}
	  )
	{
		$gene_to_group->{$gene} = scalar( @{$expression_net_reader->{'connection_group_description'}
			  ->{$group_key}->{'genes_connected'}});
	}
}

## Now I should know all the connecting genes in a group!
## Therefore I am now able to get all the gene, that correlate to only one seeder gene!

foreach my $seeder_gene ( keys %{ $expression_net_reader->{'connection'} } ) {
	unless ( defined $gene_to_group->{$seeder_gene} ) {
		$gene_to_group->{$seeder_gene} = 1;
	}
	foreach my $gene (
		keys %{ $expression_net_reader->{'connection'}->{$seeder_gene} } )
	{
		$gene_to_group->{$gene} = 1
		  unless ( defined $gene_to_group->{$gene} );
	}
}

my $hash;
foreach ( values %$gene_to_group ){
	$hash->{$_} = 0 unless ( defined $hash->{$_});
	$hash->{$_} ++;
}

foreach ( sort { $b <=> $a} keys %$hash ){
	print "$hash->{$_} did correlate to $_ genes\n";
}