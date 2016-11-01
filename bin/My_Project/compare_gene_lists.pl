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

=head1 compare_gene_lists.pl

a tool to compare two or more gene lists

To get further help use 'compare_gene_lists.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::Latex_Document;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::database::genomeDB::gene_description;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @gene_list_files, $outfile);

Getopt::Long::GetOptions(
	 "-gene_list_files=s{,}"    => \@gene_list_files,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $gene_list_files[0] && -f $gene_list_files[1] ) {
	$error .= "the cmd line switch -gene_list_files does need at least two file names!\n";
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
 command line switches for compare_gene_lists.pl

   -gene_list_files       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'compare_gene_lists.pl';
$task_description .= ' -gene_list_files '.join( ' ', @gene_list_files ) if ( defined $gene_list_files[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);

my ( $data, @temp, $sum, $gene, $group_tag );

$sum = {};
## read the data
foreach my $infile ( @gene_list_files ){
	open ( IN ,"<$infile" ) or die "could not open the infile $infile\n$!\n";
	@temp = split( "/", $infile );
	$group_tag = $temp[@temp-1];
	$data->{$group_tag} = {};
	while (<IN> ){
		chomp $_;
		@temp = split(/\s/, $_ );
		foreach $gene ( @temp ){
			$data->{$group_tag} ->{$gene} = 1;
			$sum ->{$gene} = {} unless (  ref($sum ->{$gene}) eq "HASH");
			$sum ->{$gene} -> {$group_tag} = 1;
		}
	}
	close ( IN );
}

my $group_tags;
foreach $gene ( keys %$sum ){
	$sum -> {$gene} =  join( " ", sort keys %{$sum -> {$gene}} );
	$group_tags -> { $sum -> {$gene} } = 1;
}

## analyze the data
my ( @states, $in_all_groups, $not_in_all_groups, $temp, $outfile_obj );



@states = ( keys %$data );
$temp = scalar(@states);

$outfile_obj = data_table->new();
$outfile_obj -> Add_2_Header ( "Gene Symbol" );
foreach ( sort { scalar (split(" ", $b)) <=> scalar (split(" ", $a))} keys %$group_tags ){
	$outfile_obj -> Add_2_Header ( $_ );
}
foreach $gene ( keys %$sum ){
	$outfile_obj -> Add_Dataset ({ "Gene Symbol" => $gene , $sum->{$gene} => $gene});
}
if ( scalar @gene_list_files == 2 ){
	$outfile_obj = $outfile_obj -> Sort_by ( [ [ @{$outfile_obj->{'header'}}[1],'lexical'], [ @{$outfile_obj->{'header'}}[2],'lexical'], [ @{$outfile_obj->{'header'}}[3],'lexical'] ] );
}
$outfile_obj->write_file( $outfile );

if ( scalar @gene_list_files == 2 ){
	## OK I would like to get a comparison over the three gene lists
	## Questions are: Which Pathways are overrepresented in the three groups?
	
}


