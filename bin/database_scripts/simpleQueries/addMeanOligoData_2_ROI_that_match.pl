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

=head1 identifyROI_that_match.pl

a simple DB query interface, that can search the region defined by a ROI for a sequence match.

To get further help use 'identifyROI_that_match.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::genomeDB;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::array_calculation_results;
use stefans_libs::database::array_dataset::oligo_array_values;
use stefans_libs::fastaFile;
use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,    $debug,      $database,
	$ROI_tag, $ROI_id,     $genome_organism_tag,
	$outfile, $add2region, @array_values_id,
	@array_calc_id
);

Getopt::Long::GetOptions(
	"-array_calculation_id=s{,}" => \@array_calc_id,
	"-array_values_id=s{,}"      => \@array_values_id,
	"-ROI_tag=s"              => \$ROI_tag,
	"-ROI_id=s"               => \$ROI_id,
	"-genome_organism_tag=s"  => \$genome_organism_tag,
	"-add2region=s"           => \$add2region,
	"-help"                   => \$help,
	"-debug"                  => \$debug,
	"-database=s"             => \$database
);

if ($help) {
	print helpString();
	exit;
}
unless ( defined $genome_organism_tag ) {
	print helpString(
"Sorry, but without the name of the genome, I can not select the right ROI table name!\n"
	);
	exit;
}
unless ( defined $ROI_tag || defined $ROI_id ) {
	print helpString(
"we need either the ROI_tag or the ROI_id to lelect a ROI from the database!\n"
	);
	exit;
}
unless ( defined $array_calc_id[0] || defined $array_values_id[0] ) {
	print helpString(
"we need either a id for an array_calc table or an array_values table!\n"
	);
	exit;
}
unless ( defined $add2region ) {
	print helpString(
		"we need to know how the array_data can be described (add2region)\n");
	exit;
}
my ( $already_evaluated, $genomeDB, $interface, @ROI_ids, $seq, $ROI_obj,
	$add2region_str );

$genomeDB  = genomeDB->new();
$interface = $genomeDB->getGenomeHandle_for_dataset(
	{ 'organism_tag' => $genome_organism_tag } );
$interface = $interface->get_rooted_to('ROI_table');
my $sql =
  "update " . $interface->TableName() . " set gbString = '?' where id = ?";
if ( defined $ROI_tag ) {
	@ROI_ids = @{ $interface->select_RIO_ids_for_ROI_tag($ROI_tag) };
}
else {
	@ROI_ids = ($ROI_id);
}
unless ( defined $ROI_ids[0] ) {
	warn "Sorry, but we got no regions of interest for this function call!\n";
	exit;
}

## we have to update our database!!
if ( defined $add2region ) {
	$add2region_str = " $add2region";
}
else {
	$add2region_str = '';
}

my ( $gbFile_id, $temp, $actual, $dataObj, $data_description );

$sql = "update " . $interface->TableName() . " set gbString = '?' where id = ?";

if ( defined $array_calc_id[0] ) {
	$dataObj = array_calculation_results->new( '', $debug );
	($temp, $data_description) = $dataObj->GetSearchInterface( \@array_calc_id );
	Carp::confess( "we got no search_interface, but '$temp'") unless ( ref($temp) =~ m/\w/ );
	$dataObj = $temp;
}
elsif ( defined $array_values_id[0] ) {
	$dataObj = array_dataset->new( '', $debug );
	($temp, $data_description) = $dataObj->GetSearchInterface( \@array_values_id );
	Carp::confess( "we got no search_interface, but '$temp'") unless ( ref($temp) =~ m/\w/ );
	$dataObj = $temp;	
}
else {
	print "we got no array_calc_id and no array_values_id - sorry without data we can not perform our task!\n";
	exit;
}
print root::get_hashEntries_as_string ($dataObj, 3, "the data object!");
my ( @data, $data, $array, $mean, $n, $std, $n );

foreach my $id (@ROI_ids) {
	( $ROI_obj, $gbFile_id ) = $interface->get_ROI_obj_4_id($id);
	$temp = $ROI_obj->getAsGB();
	if ( $temp =~ m/$add2region/ ) {
		$ROI_obj->DropInfo("$add2region" . "_mean");
		$ROI_obj->DropInfo("$add2region" . "_std");
		$ROI_obj->DropInfo("$add2region" . "_n");
#		print "we have already evaluated this array dataset \n$temp\n";
#		next;
	}
	## now we need to get the data
	$data = $dataObj->getArray_of_Array_for_search(
		{
			'search_columns' => ['oligo_array_values.value'],
			'where'          => [
				[ 'oligo2dnaDB.gbFile_id', '=', 'my_value' ],
				[ ['oligo2dnaDB.start','+','oligo2dnaDB.length'],       '>', 'my_value' ],
				[ 'oligo2dnaDB.start',     '<', 'my_value' ]
			],
		},
		$gbFile_id,
		$ROI_obj->Start(),
		$ROI_obj->End()
	);
	#print "we selected the oligo values using the sql query '$dataObj->{'complex_search'};'\n";
	#die;
	@data = undef;
	foreach $array (@$data) {
		push( @data, @$array[0] );
	}
	( $mean, $n, $std ) = root->getStandardDeviation( \@data );
	$ROI_obj->AddInfo( "$add2region" . "_mean", $mean );
	$ROI_obj->AddInfo( "$add2region" . "_std",  $std );
	$ROI_obj->AddInfo( "$add2region" . "_n",  $n );
	$actual = $sql;
	$seq    = $ROI_obj->getAsGB();
	$actual =~ s/\?/$seq/;
	$actual =~ s/\?/$id/;
	$interface->{'dbh'}->do($actual);
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for identifyROI_that_match.pl

   -array_calculation_id :an array_calculation_table id where the values should be comparedsummarized
   -array_values_id      :an array_values id where the values should be summarized
   
   -ROI_tag        :the tag for the regions of interest we should analyze
   -ROI_id         :the id of the ROI we should analyze (will not be used if 'ROI_tag' is set)
   -genome_organism_tag       
                   :we need the organism tag to get access to the ROI table
   -add2region     :a string, that describes the array_dataset that you want to have summarized
                    keep that extremely short (like 'mean_H_TCF')
   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

";
}
