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

=head1 identify_groups_in_PPI_results.pl

A tool to identify connected groups in the PPI data tables.

To get further help use 'identify_groups_in_PPI_results.pl -help' at the comman line.

=cut

use Getopt::Long;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $PPI_file, $outfile);

Getopt::Long::GetOptions(
	 "-PPI_file=s"    => \$PPI_file,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $PPI_file) {
	$error .= "the cmd line switch -PPI_file is undefined!\n";
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
 command line switches for identify_groups_in_PPI_results.pl

   -PPI_file       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

"; 
}

## now we set up the logging functions....

my ( $task_description, $data, @line );

## and add a working entry

$task_description = "identify_groups_in_PPI_results.pl -PPI_file $PPI_file -outfile $outfile";

open ( IN, "<$PPI_file") or die "could not open PPI_file $PPI_file\n";

foreach ( <IN> ) {
	chomp ( $_);
	@line = split("\t", $_);
	$data->{$line[0]} -> {$line[1]} = 1;
	$data->{$line[1]} -> {$line[0]} = 1;
}
close ( IN );
my ( $group, @groups, $match, $i );

foreach my  $gene1 ( keys %$data ){
	foreach my $gene2 ( keys %{$data->{$gene1}}){
	$match = 0;
	for( $i = 0; $i < @groups; $i ++ ) {
		$group = $groups[$i];
		if ( $group->{$gene1} ){
			$group->{$gene2} = 1;
			$match = 1;
		}
		elsif ($group->{$gene2} ){
			$group->{$gene1} = 1;
			$match = 1;
		}
		if ( $match ){
			print "we added to group $i the genes $gene1 and $gene2\n" if ( $debug);
			last ;
		}
		
	}
	unless ( $match ){
		push ( @groups, { $gene1 => 1, $gene2 => 1});
		print "we have craeted a new group of the genes $gene1 and $gene2\n";
	}
	}
}

## now we need a round up the missing links - step (bottom up!)
my @soredGroup = ( sort {scalar(keys %$a) <=> scalar(keys %$b) } @groups );
for( $i = 0; $i <@soredGroup; $i ++){
	MATCH_GENES:foreach my $gene1 ( keys %{$soredGroup[$i]} ){
		for (my $a = @soredGroup - 1; $a > $i ; $a -- ){
			if ( $soredGroup[$a]->{$gene1}){
				&merge_groups( \@soredGroup,$i, $a );
				last MATCH_GENES;
			}
		}
	}
	
}

open ( OUT ,">$outfile") or die "could not open outfile $outfile\n";
$i = 0;
foreach $group ( sort {scalar(keys %$b) <=> scalar(keys %$a) } @groups ){
	$i ++;
	print OUT "Group $i(".scalar(keys %$group).")\t".join(" ",sort keys %$group )."\n";
}
close ( OUT );

print "we have identified $i groups and stored the gene names building up the groups in file $outfile\n";

sub merge_groups{
	my ( $groups, $id_small, $id_big ) =@_;
	foreach my $gene ( keys %{@$groups[$id_small]}){
		@$groups[$id_big]->{$gene} = 1;
	}
	@$groups[$id_small] = {};
}