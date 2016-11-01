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

=head1 plot_array_data_for_gene.pl

plots array data using the same mechanism as the regionXY_plot.pl scripts, but relies on the database to fetch the data.

To get further help use 'plot_array_data_for_gene.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::db_report::plottable_gbFile;
use stefans_libs::plot::simpleXYgraph;
use stefans_libs::plot::simpleBarGraph;

use stefans_libs::XY_Evaluation;
use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$showPrimer,         $regions,             $stdErr,
	$GFF_list,           @ROI_tags,            @hmm,
	$gff,                $matching_gbFeatures, $summary,
	@gbList,             $min,                 $max,
	$useStd,             $widePicture,         $colored_V_segments,
	$highlight_Vsegment, $narrowPicture,       $bars,
	$median,             @gff,                 $gff_string,
	$largeDots,          $separate_arrays,     $useStdErr,
	@array_dataset_ids,  $help,                $debug,
	@genes,              $database,            $outpath
);
Getopt::Long::GetOptions(
	'-regions=s'              => \$regions,
	'-gene_list=s{,}'         => \@genes,
	'-array_dataset_ids=s{,}' => \@array_dataset_ids,
	'-ROI_tags=s{,}'          => \@ROI_tags,
	'-wanted_gbFeatures=s'    => \$matching_gbFeatures,
	'-summary'                => \$summary,
	'-bars'                   => \$bars,
	'-median'                 => \$median,
	'-colored_V_segments'     => \$colored_V_segments,
	'-min=s'                  => \$min,
	'-max=s'                  => \$max,
	'-stdDev'                 => \$useStd,
	'-stdErr'                 => \$useStdErr,
	'-showPrimer'             => \$showPrimer,
	'-widePicture'            => \$widePicture,
	'-narrowPicture'          => \$narrowPicture,
	"-highlight_Vsegment=s"   => \$highlight_Vsegment,
	'-separate_arrays'        => \$separate_arrays,
	"-large_dots"             => \$largeDots,
	"-outpath=s"              => \$outpath,
	"-help"                   => \$help,
	"-debug"                  => \$debug,
	"-database=s"             => \$database

) or die helpText();

die helpText() unless ( defined $regions );

$bars = 1 == 0 unless ( defined $bars );

sub helpText {
	my $error = shift;
	"help for regionsXY_plot.pl
	
	$error
	
	-regions 			:A tab formated list of wanted regions
	-gene_list          :An optional list of genes to create pictures for (one picture per gene)
	-array_dataset_ids  :A list of dataset ids as mentioned in the array_datasets table
	-ROI_tags	    	:A list of ROI tags you want to include into the output picture
	-wanted_gbFeatures	:A semicolon separated list of wanted gbFeatures (500bp at the start of the entry)
	-large_dots			:A boolean value if to use a line between small data points or only big data points
	-summary	 		:This option affects the display type of the gbFile data - give it a try
	-bars				:plot bar-graphs instead of line-graphs
						 different modifications are plooted in separate subplots!
						 hmm data is NOT displayed
	-separate_arrays	:do not calculate the mean/median over similar ChIP experiments (only usable in connection with -bars)
	-median				:plot median values instead of mean values (error bars are not supported!
	-showPrimer			:a boolean option to show primers (defaults to no)
	-min <>				:overwrite the calculated min value
	-max <>				:overwrite the calculated max value
	-stdDev				:display the standard deviation
	-stdErr				:display the standard error of the mean
	-widePicture		:create a picture 1.5 times as wide as a standard picture
	-narrowPicture      :create a picture 0.7 times as wide as a standard picture
	-colored_V_segments :show the different Vh families in differen colors
	-highlight_Vsegment :shows only the named Vh segment (regular paternmatch) in red the others in black
	-help               :print this help
    -debug              :verbose output
    -database           :the database name (default='genomeDB')
    
	";
}

if ($help) {
	print helpString();
	exit;
}
unless ( defined $array_dataset_ids[0] ) {
	print helpString(
"We definitively need at least one array_dataset to plot! (array_dataset_ids)"
	);
	exit;
}
unless ( defined $regions || defined $genes[0] ) {
	print helpString(
"We need either a list of genes or a region list to plot define the plotting areas (-gene_list or -regions)"
	);
	exit;
}
die "Sorry either use the '-widePicture' flag OR the '-narrowPicture' flag\n",
  helpText()
  if ( $widePicture && $narrowPicture );

if ( defined $matching_gbFeatures ) {
	$matching_gbFeatures = 1 if ( $matching_gbFeatures =~ m/"(.+)"/ );
	@gbList = split( ';', $matching_gbFeatures )
	  if ( defined $matching_gbFeatures );
	$summary = 1 == 1;
	print "gbFeatures to be evaluated:\n";
	foreach my $wFeature (@gbList) {
		print "\t\t$wFeature\n";
	}
	print "under construction\n";
}
print "\n\n";


## now we set up the logging functions....

my (
	$task_description, $workingTable, $loggingTable,
	$workLoad,         $loggingEntries
);

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );

## and add a working entry

$task_description =
    "-regions $regions -gene_list "
  . join( " ", @genes )
  . " -array_dataset_ids "
  . join( " .", @array_dataset_ids )
  . " -ROI_tags "
  . join( " ", @ROI_tags )
  . " -wanted_gbFeatures $matching_gbFeatures -summary $summary -bars $bars "
  . "-median $median -colored_V_segments $colored_V_segments -min $min "
  . "-max $max -stdDev $useStd -stdErr $useStdErr -showPrimer $showPrimer "
  . "-widePicture $widePicture -narrowPicture $narrowPicture -highlight_Vsegment "
  . "$highlight_Vsegment -separate_arrays $separate_arrays -large_dots $largeDots "
  . "-database $database";

$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'plot_array_data_for_gene.pl',
		'description' => $task_description
	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description($task_description);
unless ( defined @$loggingEntries[0] ) {

## 1. get to know how many datasets we should plot

## 2. define the size of the picture

## 3. get the data and create the plottableObjects (plottable_gbFile; simpleXYgraph; simpleBarGraph)

## 5. plot the shit







	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

}

$workingTable->delete_workload_for_PID($$);
