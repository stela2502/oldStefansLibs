#! /usr/bin/perl -w

#  Copyright (C) 2010-11-30 Stefan Lang

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

=head1 add_expression_net_as_Pathway.pl

This script will help you to add a unique expression net pathway.

To get further help use 'add_expression_net_as_Pathway.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::file_readers::svg_pathway_description;
use stefans_libs::file_readers::expression_net_reader;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,                    $debug,              $database,
	$pathway_name,            $pathway_desc,       $pathways_ID,
	$svg_pathway_description, $png_pathway_figure, $co_expression_data,
	@genes_of_interest
);

Getopt::Long::GetOptions(
	"-pathway_name=s"            => \$pathway_name,
	"-pathway_desc=s"            => \$pathway_desc,
	"-pathways_ID=s"             => \$pathways_ID,
	"-svg_pathway_description=s" => \$svg_pathway_description,
	"-png_pathway_figure=s"      => \$png_pathway_figure,
	"-co_expression_data=s"      => \$co_expression_data,
	"-genes_of_interest=s{,}"    => \@genes_of_interest,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $pathway_name ) {
	$error .= "the cmd line switch -pathway_name is undefined!\n";
}
unless ( defined $pathway_desc ) {
	$error .= "the cmd line switch -pathway_desc is undefined!\n";
}
unless ( defined $pathways_ID ) {
	$error .= "the cmd line switch -pathways_ID is undefined!\n";
}
unless ( defined $svg_pathway_description ) {
	$error .= "the cmd line switch -svg_pathway_description is undefined!\n";
}
unless ( -f $png_pathway_figure ) {
	$error .= "the cmd line switch -png_pathway_figure is undefined!\n";
}
unless ( -f $co_expression_data ) {
	$error .= "the cmd line switch -co_expression_data is undefined!\n";
}
unless ( defined $genes_of_interest[0] ) {
	$error .= "the cmd line switch -genes_of_interest is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for add_expression_net_as_Pathway.pl

   -pathway_name :Your name for the new Pathway
   -pathway_desc :A long description of the pathway
                   what does it stand for
                   why do you think it is a pathway
                   Have you veryfied anything
                   Do you have a publication?
   -pathways_ID  :Your ID for that pathway
   
   -svg_pathway_description :a manually preparted svg file containing rectangles, 
                              that are named like the pathwas
                              read the script if you get problems
                              we do some translation of the tags! 
                              
   -png_pathway_figure :the position of the PNG representaion of that pathway
   -co_expression_data :the co-expression data the pathway piture is based on
                         WE DO NO SELECTIONS - we take all these results
   -genes_of_interest  :a list or file containing the seeder genes

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'add_expression_net_as_Pathway.pl';
$task_description .= " -pathway_name $pathway_name"
  if ( defined $pathway_name );
$task_description .= " -pathway_desc $pathway_desc"
  if ( defined $pathway_desc );
$task_description .= " -pathways_ID $pathways_ID" if ( defined $pathways_ID );
$task_description .= " -svg_pathway_description $svg_pathway_description"
  if ( defined $svg_pathway_description );
$task_description .= " -png_pathway_figure $png_pathway_figure"
  if ( defined $png_pathway_figure );
$task_description .= " -co_expression_data $co_expression_data"
  if ( defined $co_expression_data );
$task_description .= ' -genes_of_interest ' . join( ' ', @genes_of_interest )
  if ( defined $genes_of_interest[0] );

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
my (
	$gene_2_group_tag,     $svg_pathway_data,      $match_group_in_svg,
	$match_group_in_coExp, $expression_net_reader, $gene_to_group,
	$this_group,           $gene_group_in_svg,     $last_group_id, $organims_tag
);

$match_group_in_svg   = 'gr_';
$match_group_in_coExp = 'Gr.(\\d+) \\(\\d+\\)';
$gene_group_in_svg    = "gene_";
$organims_tag = "H_sapiens";

print
"we will use the \$match_group_in_svg '$match_group_in_svg'\nand the \$match_group_in_coExp '$match_group_in_coExp'}\n";

## now I will read all the group information
$expression_net_reader = expression_net_reader->new();
$expression_net_reader->Read_from_File( $co_expression_data,
	\@genes_of_interest );
$expression_net_reader->__define_connection_groups();

## OK and here comes the real logics of this script!
## I will iterate through the whole dataset checking which gene is in which group

foreach my $group_key (
	keys %{ $expression_net_reader->{'connection_group_description'} } )
{
	if ( $group_key =~ m/$match_group_in_coExp/ ) {
		$this_group = $match_group_in_svg . $1;
		foreach my $gene (
			@{
				$expression_net_reader->{'connection_group_description'}
				  ->{$group_key}->{'connecting_genes'}
			}
		  )
		{
			$gene_to_group->{$gene} = $this_group;
		}
		$last_group_id = $this_group;
	}
}
## Now I should know all the connecting genes in a group!
## Therefore I am now able to get all the gene, that correlate to only one seeder gene!

foreach my $seeder_gene ( keys %{ $expression_net_reader->{'connection'} } ) {
	$this_group = $gene_group_in_svg . $seeder_gene;
	unless ( defined $gene_to_group->{$seeder_gene} ) {
		$gene_to_group->{$seeder_gene} = $this_group;
	}
	foreach my $gene (
		keys %{ $expression_net_reader->{'connection'}->{$seeder_gene} } )
	{
		$gene_to_group->{$gene} = $this_group
		  unless ( defined $gene_to_group->{$gene} );
	}
}

## now I should have covered all the genes available!

$svg_pathway_data = stefans_libs_file_readers_svg_pathway_description->new();
$svg_pathway_data->read_file($svg_pathway_description);

## Just a small check - the $last_group_id should be the found in the $svg_pathway_data
Carp::confess(
"Sorry, but I did not find the pathway group_id '$last_group_id' in the svg description file!\n"
  )
  unless (
	defined $svg_pathway_data->get_rowNumbers_4_columnName_and_Entry(
		'key', $last_group_id
	)
) ;

## And now I should be ready to do the database import - or?

my $kegg_genes = kegg_genes->new( root->getDBH());
my ($dataset, $svg_info, $pathway_id);
$pathway_id = {
	'pathway_name' => $pathway_name,
	'organism' => {'organism_tag' => $organims_tag },
	'description' => $pathway_desc,
	'picture' => { 'filename' => $png_pathway_figure, 'filetype' => 'picture', 'mode' => 'binary' },
	'kegg_pw_id' => $pathways_ID
};
foreach my $gene ( keys %$gene_to_group ){
	$dataset = undef;
	$svg_info = $svg_pathway_data -> get_line_asHash( $svg_pathway_data->get_rowNumbers_4_columnName_and_Entry( 'key', $gene_to_group->{$gene}));
	Carp::confess ( "the group $gene_to_group->{$gene} is not defined in the svg_file\n") unless ( ref($svg_info) eq "HASH");
	$dataset ->{'x_coord_1'} = $svg_info->{'x1'};
	$dataset ->{'x_coord_2'} = $svg_info->{'x2'};
	$dataset ->{'y_coord_1'} = $svg_info->{'y1'};
	$dataset ->{'y_coord_2'} = $svg_info->{'y2'};
	$dataset->{'KEGG_gene_id'} = 1;
	$dataset->{'mark_type'} = 'rect';
	$dataset->{'Gene_Symbol'} = $gene;
	$dataset->{'pathway'} = $pathway_id;
	print root::get_hashEntries_as_string ($svg_info, 3, "the SVG info for gene $gene");
	print "we added a KEGG_GENE id ". $kegg_genes ->AddDataset( $dataset )." ($gene)\n";
}

print "Done";



