#! /usr/bin/perl
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


=head2 Function

This script will be the first data cruncher developed for the database interface.
Yet developed outside of a plugin.

=cut

use stefans_libs::XY_Evaluation;
use stefans_libs::database::genomeDB;
use stefans_libs::database::array_dataset;
use Getopt::Long;
use strict;

my (
	$showPrimer, @regions_ids,             $stdErr,
	@sample_ids,          
	$gff,        $matching_gbFeatures, $summary,$genomeID, 
	@gbList,     $min,                 $max,
	$useStd,     $widePicture,         $colored_V_segments,@HMM_tags,
	$highlight_Vsegment, $narrowPicture, $bars, $median,  $gff_string,
	$largeDots, $separate_arrays, $useStdErr
);
Getopt::Long::GetOptions(
	'-genome_id=s'           => \$genomeID, 
	'-regions_ids=s{,}'      => \@regions_ids,
	'-sample_ids=s{,}'       => \@sample_ids,
	'-HMM_tags=s{,}'            => \@HMM_tags,
	'-wanted_gbFeatures=s'   => \$matching_gbFeatures,
	'-summary'               => \$summary,
	'-bars'                  => \$bars,
	'-median'                => \$median,
	'-colored_V_segments'    => \$colored_V_segments,
	'-min=s'                 => \$min,
	'-max=s'                 => \$max,
	'-stdDev'                => \$useStd,
	'-stdErr'                => \$useStdErr,
	'-showPrimer'           => \$showPrimer,
	'-widePicture'          => \$widePicture,
	'-narrowPicture'        => \$narrowPicture,
	"-highlight_Vsegment=s" => \$highlight_Vsegment,
	'-separate_arrays'      => \$separate_arrays,
	"-large_dots"           => \$largeDots
) or die helpText();

die helpText() unless ( defined $regions_ids[0] );

$bars = 1==0 unless ( defined $bars);

sub helpText {
	"help for regionsXY_plot.pl
	-genome_id          :The id of the genome the regionIDs are of
	-regions_ids		:A list of region ids as you can find them in the ROI table
	-sample_ids  		:A list of sample IDs that you want to include in the picture
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
	";
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


## OK - now we need to establish the database connection!
my $array_datast_db = array_dataset->new();
my $genomeDB = genomeDB->new();
my $genomeInstance = $genomeDB->GetDatabaseInterface_for_genomeID( $genomeID );
$genomeInstance -> get_rooted_to ( 'ROI_table');

my $array_interface = $array_datast_db->GetSearchInterface( $array_datast_db-> get_data_table_4_search({
 	'search_columns' => [ref($array_datast_db).".id"],
 	'where' => [[ref($array_datast_db).".sample_id", '=','my_value']]
 }, @sample_ids )->get_column_entries(ref($array_datast_db).".id"));


if ( defined $HMM_tags[0] && !$bars ) {
	## OK that has does not need to be done at this stage!
}

print "\n\n";

my (
	@arrayOfSubregions, $hash, @regions, $pictureData,
	$pathModifier,      $xy,   @temp,    $temp,
	$useTitle,          $nimbleGeneID
);


$useTitle = 1 == 2;

$pathModifier = "$pathModifier-summary" if ($summary);
$pathModifier = "$pathModifier.$min"    if ( defined $min );
$pathModifier = "$pathModifier-$max"    if ( defined $max );

print "Path modifier added: $pathModifier\n";


$xy = XY_Evaluation->new($pathModifier);
$xy->showPrimer($showPrimer);
$xy->WidePicture($widePicture);
$xy->NarrowPicture($narrowPicture);
$xy->Summary($summary);

if ($median) {
	$useStd = $useStdErr = 1 == 0;
}

foreach my $hmm (@HMM_tags) {
	## OK - we need to add the HMM enriched regions to the dataset - if they exist!
	
	next if ( $hmm =~ m/^#/ );
	chomp $hmm;
	print "Add HMM data for file $hmm\n";
	$xy->AddHMM_Data($hmm);
}

$xy->{minOverride} = $min;
$xy->{maxOverride} = $max;

while (<RegionsFile>) {
	$pathModifier = "$1/$pathModifier" if ($_ =~ m/PathModifier=(.*)/ );
	next if ( $_ =~ m/^#/ );
	next if ( $_ =~ m/^new=/ );
	chomp $_;
	(
		$hash->{gbFile},    $hash->{start},        $hash->{end},
		$hash->{X_axis},    $hash->{pictureTitle}, $hash->{filename},
		$hash->{binLength}, @arrayOfSubregions
	) = split( ",", $_ );
	$hash->{pictureTitle} = "  " unless ($useTitle);
	$regions[0] = $hash;

	print "\n\ngbFile = $hash->{gbFile}\n", "start = $hash->{start}\n",
	  "end = $hash->{end}\n", "X_axis = $hash->{X_axis}\n",
	  "pictureTitle = $hash->{pictureTitle}\n",
	  "filename = $hash->{filename}\n",
	  "oligo bin length = '$hash->{binLength}'\n\n\n";

	$pictureData = undef;
	$pictureData =
	  $xy->defineRegions( \@regions, "2005-09-08_RZPD1538_MM6_ChIP",
		$hash->{gbFile} );

	$xy->{minOverride} = $min;
	$xy->{maxOverride} = $max;
	$xy->Summary($summary);
	$xy->LargeDots( $pictureData, $largeDots );
	$xy->UseStdDev( $pictureData, $useStd );
	$xy->UseStdErrMean( $pictureData, $useStdErr );
	$xy->UseBars( $pictureData, $bars );
	$xy->UseMedian( $pictureData, $median );
	$xy->SeparateArrays( $pictureData, $separate_arrays );

	while ( ( $nimbleGeneID, $gff_string ) = each %$gff ) {
		next if ( $gff =~ m/^#/ );
		$gff = $1 if ( $gff =~ m/^(.+) #.*/ );
		#print
		#  "regionXY_plot.pl adds ChIP Data for nimblegeneID '$nimbleGeneID'\n";
		$pictureData = $xy->Add2Y_axis(
			$xy->GetY_axisData( $pictureData, "$gff_string" ),
			$hash->{start}, $hash->{end}, $hash->{binLength},
			\@gbList,       $nimbleGeneID
		);
	}

	print "We create a new gb axis:\n";
	$pictureData = $xy->AddX_axis( $pictureData, $hash->{start}, $hash->{end} );
	$xy->Colored_V_segments( $pictureData, $colored_V_segments );
	#print "regionXY_plot.pl: we try to highlight the V_segment '$highlight_Vsegment'\n";
	$xy->highlight_Vsegment( $pictureData, $highlight_Vsegment );
	$temp = @arrayOfSubregions;
	#print " regionXY....pl got $temp subregion infor (3 per one subregion)\n";

	for ( my $i = 0 ; $i < @arrayOfSubregions ; $i += 3 ) {
		$xy->defineSubAxis(
			$pictureData, $arrayOfSubregions[$i],
			$arrayOfSubregions[ $i + 1 ],
			$arrayOfSubregions[ $i + 2 ]
		);
	}

	#print "We created a x_axis of the type $pictureData->{X_axis}\n";
	$hash = {
		pictureData         => $pictureData,
		filename            => "$pathModifier-$hash->{filename}",
		gbFile              => $pictureData->{X_axis}->{gbFile},
		start               => $pictureData->{X_axis}->{start},
		end                 => $pictureData->{X_axis}->{end},
		X_title             => $pictureData->{title},
		GFF_Axis            => $pictureData->{Y_axis},
		minOverride         => $xy->{minOverride},
		maxOverride         => $xy->{maxOverride},
		rulerTitle          => undef,
		GBfile_MySQL_string => undef,
		NuclPosArray        => undef,
		x_axis              => $pictureData->{X_axis}
	};
	$xy->Plot_hash($hash);

   #$xy->Plot( $pictureData, , $hash->{pictureTitle},
   #    $hash->{X_axis}, undef, $hash->{gbFile}, $hash->{start}, $hash->{end} );

}

sub printPlottable {
	my $pictureData = shift;
	print "Inhalt von pictureData:\n";
	foreach my $key ( keys %$pictureData ) {
		print "\t$key -> $pictureData->{$key}\n";
	}

	my $regionList = $pictureData->{regionList};
	print "Inhalt von regionList:\n";
	foreach my $region (@$regionList) {
		print "$region\n";
		while ( my ( $key, $value ) = each %$region ) {
			print "\t\t$key->$value\n";
		}
	}
}
