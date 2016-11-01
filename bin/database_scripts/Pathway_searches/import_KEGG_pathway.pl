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

=head1 import_KEGG_pathway.pl

Import the KEGG pathway into the database.

To get further help use 'import_KEGG_pathway.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::pathways::kegg::kegg_genes;
use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, $data_path, $organism_tag );

Getopt::Long::GetOptions(
	"-data_path=s"    => \$data_path,
	"-organism_tag=s" => \$organism_tag,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $data_path ) {
	$error .= "the cmd line switch -data_path is undefined!\n";
}
unless ( defined $organism_tag ) {
	$error .= "the cmd line switch -organism_tag is undefined!\n";
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
 command line switches for import_KEGG_pathway.pl

   -data_path       :<please add some info!>
   -organism_tag       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

";
}

## now we set up the logging functions....

my (
	$task_description, $workingTable, $loggingTable,
	$workLoad,         $loggingEntries, $data, $PathWay_ID, $dataset, $kegg_genes, $i, $genes
);

$workingTable = workingTable->new( '', $debug );
$loggingTable = loggingTable->new( '', $debug );
$kegg_genes = kegg_genes->new(root::getDBH('root'),$debug);

## and add a working entry

$task_description =
  "import_KEGG_pathway.pl -data_path $data_path -organism_tag $organism_tag";
$i = 0;

unless ( 0 ) {
	opendir( DIR, "$data_path" ) or die "could not access the directory $data_path\n$!\n";
	my @files = readdir( DIR );
	foreach my $file ( @files){
		next unless ( $file=~ m/png$/ );
		$PathWay_ID = '';
		$PathWay_ID = $1 if ( $file=~ m/(.*)\.png/);
		unless ($PathWay_ID =~ m/\w/){
			warn "we could not parse the filename $file\n";
			next;
		}
		print "we found a pathway id $PathWay_ID\n";
		$data ->{$PathWay_ID} = { 'data' => $data_path."/".$PathWay_ID.".html", 'image' => $data_path."/".$PathWay_ID.".png"};
	}
	close ( DIR );
	
	## now we need to parse the data!
	## we need to get:
	## 1. the description of the pathway
	## 2. the genes that built up the pathway
	##    -names
	##    -coordinates in the picture
	PROCESS_PATHWAYS: foreach $PathWay_ID ( keys %$data ){
		print "we process the pathway  $PathWay_ID\n";
		$dataset = {'pathway' => {'picture' => {}, 'organism' => {}}};
		open ( IN , "<$data->{$PathWay_ID}->{'data'}") or die "could not open file $data->{$PathWay_ID}->{'data'}\n";
		$dataset->{'pathway'}->{'kegg_pw_id'} = $PathWay_ID;
		$dataset->{'pathway'}->{'picture'}->{'filename'} = $data->{$PathWay_ID}->{'image'};
		$dataset->{'pathway'}->{'picture'}->{'mode'} = 'binary';
		$dataset->{'pathway'}->{'picture'}->{'filetype'} = 'png';
		$dataset->{'pathway'}->{'organism'}->{'organism_tag'} = $organism_tag;
		$i++;
		while ( <IN> ){
			
			unless ( defined $dataset->{'pathway'}->{'pathway_name'}){
				next unless ( $_=~ m/DEFINITION  (.*) - Homo sapiens \(human\)/);
				print $_;
				$dataset->{'pathway'}->{'pathway_name'} = $1;
				$dataset->{'pathway'}->{'pathway_name'} =~ s/'/ /g;
				#print "we got the the pathway name $dataset->{'pathway'}->{'pathway_name'}\n";
				next;
			}
			unless ( defined $dataset->{'pathway'}->{'description'}){
				if ( $_ =~ m/(.+\.)<\/td><\/tr><\/table>/ ){
				$dataset->{'pathway'}->{'description'} = $1;
				$dataset->{'pathway'}->{'description'} =~ s/'/ /g;
				#print "we got the pathway description $dataset->{'pathway'}->{'description'}\n";
				}
			}
			#<area shape=rect        coords=334,151,380,168  href="/dbget-bin/www_bget?hsa:7389"     title="7389 (UROD)" />
			#print $_ if ( $_ =~ m/area/);
			if ( $_ =~ m/shape=rect.*coords=(\d+),(\d+),(\d+),(\d+).*href=.*title="(.+)"/){
				next if ( $_ =~ m/pathway/ );
				
				$dataset->{'pathway'}->{'description'} = 'no description' unless ( defined $dataset->{'pathway'}->{'description'});
				#print "and this line did match for a gene: $_";
				$dataset->{'mark_type'} = 'rect';
				$dataset->{'x_coord_1'} = $1;
				$dataset->{'y_coord_1'} = $2;
				$dataset->{'x_coord_2'} = $3;
				$dataset->{'y_coord_2'} = $4;
				foreach my $gene_rep ( split(", ",$5)){
					delete $dataset->{'id'};
					delete $dataset->{'search_array'};
					unless ($gene_rep =~ m/(\w+\d+) \((.*)\)/){
						warn "we can not process the gene names '$gene_rep'\n" ;
					}
					$dataset->{'Gene_Symbol'} = $2;
					$dataset->{'KEGG_gene_id'} = $1;
					## now we need to insert the dataset into the database
					$genes->{$dataset->{'Gene_Symbol'}} = 1;
					unless ( $debug ){
						$kegg_genes->AddDataset( $dataset );
					}
					else{
						print root::get_hashEntries_as_string ($dataset, 3, " DEBUG - we would insert this hash into 'kegg_genes'\n" );
					}
				}
			}			
		}
		if ( $debug){
			last PROCESS_PATHWAYS if ( $i > 5);	
		}
	}
	
	
#	$loggingTable->set_log(
#		{
#			'start_time'  => @$workLoad[0]->{'timeStamp'},
#			'programID'   => @$workLoad[0]->{'programID'},
#			'description' => @$workLoad[0]->{'description'}
#		}
#	) unless ( $debug );

}

print "we inserted $i pathways and a total of ".scalar(keys %$genes)." genes into the KEGG database\n";

$workingTable->delete_workload_for_PID($$);

