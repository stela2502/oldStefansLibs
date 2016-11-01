#! /usr/bin/perl -w

#  Copyright (C) 2010-11-02 Stefan Lang

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

=head1 calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl

This script will populate the table hypergeometric_max_hits using the gene list you did provide to set up the hypergeometric test

To get further help use 'calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::pathways::kegg::kegg_genes;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $gene_set_name, @genes, $organism_tag);

Getopt::Long::GetOptions(
	 "-gene_set_name=s"    => \$gene_set_name,
	 "-genes=s{,}"    => \@genes,
	 "-organism_tag=s"    => \$organism_tag,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $gene_set_name) {
	$error .= "the cmd line switch -gene_set_name is undefined!\n";
}
unless ( defined $genes[0]) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
elsif ( -f $genes[0] ){
	my @temp;
	open ( IN, "<$genes[0]" );
	while ( <IN> ){
		chomp($_);
		push ( @temp, split(/\s/, $_));
	}
	shift ( @temp ) unless ( defined $temp[0]);
	@genes = @temp;
	close ( IN );
}
unless ( defined $organism_tag) {
	$error .= "the cmd line switch -organism_tag is undefined!\n";
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
 command line switches for calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl

   -gene_set_name       :<please add some info!>
   -genes       :<please add some info!> you can specify more entries to that
   -organism_tag       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl';
$task_description .= " -gene_set_name $gene_set_name" if (defined $gene_set_name);
$task_description .= ' -genes '.join( ' ', @genes ) if ( defined $genes[0]);
$task_description .= " -organism_tag $organism_tag" if (defined $organism_tag);


## Do whatever you want!
my ( $kegg_genes, $table, $kegg_pathway_counts, $target_table);

$kegg_genes = kegg_genes->new( root->getDBH(), $debug );

$table = $kegg_genes->get_data_table_4_search(
	{
		'search_columns' => [
			'Gene_Symbol', 'kegg_pathway.id'
		],
		'where' => [ [ 'Gene_Symbol', '=', 'my_value' ] ],
		'order_by' => ['pathway_name']
	},
	\@genes
);
$table -> define_subset ( 'data', [ 'Gene_Symbol', 'kegg_pathway.id' ]);
$kegg_pathway_counts = $table->pivot_table ( {
		'grouping_column'    => 'kegg_pathway.id',
		'Sum_data_column'    => 'data',
		'Sum_target_columns' => [ 'max_count' ],
		'Suming_function'    => sub {
			my $used_pathway_gene_connection = {};
			my $count = 0;
			for ( my $i = 0; $i <@_; $i +=2){
				next if ( $used_pathway_gene_connection->{ $_[$i].$_[$i+1]} );
				$used_pathway_gene_connection->{ $_[$i].$_[$i+1]} = 1;
				$count ++;
			}
			return $count;
		}
});
$kegg_pathway_counts->Rename_Column( 'kegg_pathway.id', 'kegg_id');
$kegg_pathway_counts->Add_2_Header( 'reference_dataset' );
$kegg_pathway_counts->setDefaultValue( 'reference_dataset', $gene_set_name);
$target_table = hypergeometric_max_hits->new( root->getDBH(), $debug );
my $hash;
#die "As we have not tested that feature - first a test!\n".$kegg_pathway_counts->AsString();
for ( my $i = 0; $i < @{$kegg_pathway_counts->{'data'}}; $i ++ ){
	$hash = $kegg_pathway_counts->get_line_asHash($i);
	$hash -> {'bad_entries'} = scalar (@genes) - $hash ->{'max_count'};
	#die root::get_hashEntries_as_string ($kegg_pathway_counts->get_line_asHash($i), 3, "we would add the hash ");
	$target_table->AddDataset ( $hash );
}
print "we have added this:".$kegg_pathway_counts->AsString();

