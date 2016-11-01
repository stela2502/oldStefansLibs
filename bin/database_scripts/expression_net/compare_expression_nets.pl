#! /usr/bin/perl -w

#  Copyright (C) 2010-09-10 Stefan Lang

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

=head1 compare_expression_nets.pl

This script should be used to compare two connection nets according to the internal net structure. E.g. which connections were chenged in size, which were lost, which were added and so on.

To get further help use 'compare_expression_nets.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::expression_net_reader;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $stat_file_1, $stat_file_2, $outfile);

Getopt::Long::GetOptions(
	 "-stat_file_1=s"    => \$stat_file_1,
	 "-stat_file_2=s"    => \$stat_file_2,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $stat_file_1) {
	$error .= "the cmd line switch -stat_file_1 is undefined!\n";
}
unless ( -f $stat_file_2) {
	$error .= "the cmd line switch -stat_file_2 is undefined!\n";
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
 command line switches for compare_expression_nets.pl

   -stat_file_1       :<please add some info!>
   -stat_file_2       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'compare_expression_nets.pl';
$task_description .= " -stat_file_1 $stat_file_1" if (defined $stat_file_1);
$task_description .= " -stat_file_2 $stat_file_2" if (defined $stat_file_2);
$task_description .= " -outfile $outfile" if (defined $outfile);

my ($data1, $data2, $gene_list );

$data1 = expression_net_reader->read_LogFile( $stat_file_1 );
$data2 = expression_net_reader->read_LogFile( $stat_file_2 );

$error .= "Sorry, but we can analyze only one expression net at a time (file 1 contains ".scalar(keys %$data1).")\n" if ( scalar(keys %$data1) != 1);
$error .= "Sorry, but we can analyze only one expression net at a time (file 2 contains ".scalar(keys %$data2).")\n" if ( scalar(keys %$data2) != 1);
( $gene_list ) = ( keys %$data1);
$error .= "The results will not describe what you did expect as the initial gene list are not the same!\n" unless ( defined $data2->{$gene_list});
die $error if ( $error =~ m/\w/);

my ( $info1, $info2, @tags, @sizes );
$info1 = {};
$info2 = {};
@tags = split(";", $data1->{$gene_list}->{'group_tags'});
@sizes = split(";", $data1->{$gene_list}->{'group_size'});
for ( my $i = 0; $i < @tags; $i++){
	$info1 ->{ $tags[$i]} = $sizes[$i];
}
@tags = split(";", $data2->{$gene_list}->{'group_tags'});
@sizes = split(";", $data2->{$gene_list}->{'group_size'});
for ( my $i = 0; $i < @tags; $i++){
	$info2 ->{ $tags[$i]} = $sizes[$i];
}

## we will look at the files as 1->2 so existing in 1 but not in 2 -> lost in 2 or otherwise gained in 2
my $group_tag;
open ( OUT , ">$outfile") or die "could not create the outfile $outfile\n$!\n";
print OUT "CMD:\n$task_description\n\n";
print OUT "We look at the data as if we would have moved from file1 to file2\n";
print OUT "Groups lost in file2\nGrouped genes\tconnections in file1\n";
foreach $group_tag (sort keys %$info1 ){
	next if ( defined $info2->{$group_tag});
	print OUT "$group_tag\t$info1->{$group_tag}\n";
}
print OUT "\nGroups gained in file2\nGrouped genes\tconnections in file2\n";
foreach $group_tag (sort keys %$info2 ){
	next if ( defined $info1->{$group_tag});
	print OUT "$group_tag\t$info2->{$group_tag}\n";
}
print OUT "\nGroups that changed grouping gene count\nGrouped genes\tgenes in file1\tgenes in file2\tdiffernece\n";

@tags = ();
my $i = 0;
foreach $group_tag (sort keys %$info1 ){
	next unless ( defined $info2->{$group_tag});
	if ( $info2->{$group_tag}-$info1->{$group_tag} != 0){
			print OUT "$group_tag\t$info1->{$group_tag}\t$info2->{$group_tag}\t".($info2->{$group_tag}-$info1->{$group_tag})."\n";
	}
	else {
		$tags[$i++] = $group_tag;
	}
}

print OUT "\nGroups that did not change in the analysis:\nGrouped genes\n".join("\n",@tags)."\n";

close OUT;
print "The comparison was printed to $outfile\n";




