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

=head1 histogram_for_gbFeature_values.pl

This script is able to craete histograms over certain features of a gbFeature over the whole genome of a organism.
To get further help use 'histogram_for_gbFeature_values.pl -help' at the comman line.

In order to be able to get the features, we need the organism string for the genome you want to select,
the gbFeature tag(s) you want to analyze or the name of a specialized sub function, that is included into this script:

\itemize
\over 2
\item distance_between_features evaluate the distance between the two closest gbFeatures that are of the gbFeature tag 'tag'
\item no_idea in time there will be further things to do with this script

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::statistics::new_histogram;

my (
	$help,           $debug,       $organism,       $gbFeatureTag,
	$dependant_vals, $pic_outFile, $gbFeature_name, @functionList,
	$steps,          $regExp,      $entryName,      $max_distance,
	$min_distance, $regionLength
);

Getopt::Long::GetOptions(
	"-organism=s"             => \$organism,
	"-gbFeature_tag=s"        => \$gbFeatureTag,
	"-gbFeature_name=s"       => \$gbFeature_name,
	"-regExp=s"               => \$regExp,
	"-entryName=s"            => \$entryName,
	"-min_distance=s"         => \$min_distance,
	"-max_distance=s"         => \$max_distance,
	"-regionLength=s"         => \$regionLength,
	"-hist_steps=s"           => \$steps,
	"-histogram_outfile=s"    => \$pic_outFile,
	"-internalFunctions=s{,}" => \@functionList,
	"-help"                   => \$help,
	"-debug"                  => \$debug
);

$dependant_vals->{'regExp'}       = $regExp;
$dependant_vals->{'entryName'}    = $entryName;
$dependant_vals->{'min_distance'} = $min_distance;
$dependant_vals->{'max_distance'} = $max_distance;
$dependant_vals->{'regionLength'} = $regionLength;

if ($help) {
	print helpString();
	exit;
}

my ( $database, $featureList, @hist_data, $gbFeature, $executeFunction );

unless ( defined $organism ) {
	warn helpString(
		"we can not select a database without the organism string!");
	exit;
}

unless ( defined $steps ) {
	$steps = 100;
}

unless ( defined $gbFeatureTag ) {
	warn helpString(
		"we can not select the gbFeatures without a gbFeature tag!");
	exit;
}

unless ( defined $pic_outFile ) {
	warn helpString(
		"we can not print the histogram without knowning where to put it!");
	exit;
}

unless ( scalar(@functionList) > 0 ){
	warn helpString(
		"pleas select one of the functions we provide - we have nothing to do!");
	exit;
}

my $depends_on = {
	'internal_value'  => [ 'entryName',    'regExp' ],
	'distance'        => [ 'min_distance', 'max_distance' ],
	'amount_inRegion' => ['regionLength']
};

foreach my $function (@functionList) {
	unless ( defined $depends_on->{$function} ) {
		warn helpString("The internal function '$function' is not defined!");
		exit;
	}
	$executeFunction->{$function} = 1;
	foreach my $deps ( @{ $depends_on->{$function} } ) {
		unless ( defined $dependant_vals->{$deps} ) {
			warn helpString(
"The internal function '$function' depends on the (empty) value '$deps'!"
			);
			exit;
		}
	}
}

## get the genome DB interface...
$database =
  genomeDB->new( undef, $debug )->GetDatabaseInterface_for_Organism($organism);
unless ( ref($database) eq "chromosomesTable" ) {
	warn helpString(
"we did not get a genome interface using the organism string '$organism'"
	);
	exit;
}

##and now start to read the gbFeatures!

unless ( defined $gbFeature_name ) {
	print
"we try to read the gbFeatures using chromosmesTable->getAll_gbFeatures_of_type ($gbFeatureTag)\n"
	  if ($debug);
	$featureList = $database->getAll_gbFeatures_of_type($gbFeatureTag);
	print "and we have now ", scalar(@$featureList), " entries\n" if ($debug);
}
else {
	print
"we try to read the gbFeatures using chromosmesTable->getAll_gbFeatures_of_type_and_name ($gbFeatureTag, $gbFeature_name)\n"
	  if ($debug);
	$featureList =
	  $database->getAll_gbFeatures_of_type_and_name( $gbFeatureTag,
		$gbFeature_name );
	print "and we have now ", scalar(@$featureList), " entries\n" if ($debug);
}

if ( $executeFunction->{"internal_value"} ) {
	&internal_value( $dependant_vals, $featureList, $steps, $pic_outFile );
}

if ( $executeFunction->{"distance"} ) {
	&distance( $dependant_vals, $featureList, $steps, $pic_outFile );
}

if ( $executeFunction->{"amount_inRegion"} ) {
	&amount_inRegion ( $dependant_vals, $featureList, $steps, $pic_outFile );
}

sub amount_inRegion {
	my ( $dependant_vals, $featureList, $steps, $pic_outFile ) = @_;
	my ( $gbFeature, @hist_data, $error, $hist, $amount, $regionStart );
	$error = '';
	my $warning = '';
	foreach $gbFeature ($featureList->asArray()) {    ## first gbFeature
		unless ( defined $regionStart ) {
			$regionStart = $gbFeature->Start();
			if ( $amount > 0 ) {
				push( @hist_data, $amount );
			}
			$amount = 0;
			next;
		}
		if ( $regionStart > $gbFeature->Start() ) {    ## new gbFile
			$regionStart = $gbFeature->Start();
			if ( $amount > 0 ) {
				push( @hist_data, $amount );
			}
			$amount = 0;
			next;
		}
		if ( $gbFeature->Start() - $regionStart >
			$dependant_vals->{'regionLength'} )
		{
			$regionStart = $gbFeature->Start();
			if ( $amount > 0 ) {
				push( @hist_data, $amount );
			}
			$amount = 0;
			next;
		}
		$amount++;
	}
	push( @hist_data, $amount ) if ( $amount > 0 );

	$hist = new_histogram->new();
	if ( defined $hist_data[0] ) {
		##looks like we got data!
		$hist->CreateHistogram( \@hist_data, undef, $steps );
		$hist->plot( { 'outfile' => $pic_outFile . ".amount_inRegion.$steps" } );
		$hist->ScaleSumToOne();
		$hist->plot(
			{ 'outfile' => $pic_outFile . ".amount_inRegion.$steps.probability_plot" }
		);
	}
	else {
		warn "we got no values (internal_value process)!\n";
		print "databse error:\n";
		print $database->{error};
		print "gbFeatures errors:\n", $error;
		print "the gbFeatures array: \n@$featureList\n";
		print "and at last the values: \n@hist_data\n";
	}
	print "we got the following warnings:\n", $warning if ( $warning =~ /\w/ );
	return 1;
}

sub distance {
	my ( $dependant_vals, $featureList, $steps, $pic_outFile ) = @_;
	my ( $gbFeature, @hist_data, $error, $lastPos, $hist, $value );
	$error = '';
	my $warning = '';
	foreach $gbFeature ($featureList->asArray()) {    ## first gbFeature
		unless ( defined $lastPos ) {
			$lastPos = $gbFeature->Start();
			next;
		}
		if ( $lastPos > $gbFeature->Start() ) {    ## new gbFile
			$lastPos = $gbFeature->Start();
			next;
		}
		$value = $gbFeature->Start() - $lastPos;
		push( @hist_data, $value )
		  if ( $value >= $dependant_vals->{'min_distance'}
			&& $value <= $dependant_vals->{'max_distance'} );
		$lastPos = $gbFeature->Start();
	}
	$hist = new_histogram->new();
	if ( defined $hist_data[0] ) {
		##looks like we got data!
		$hist->CreateHistogram( \@hist_data, undef, $steps );
		$hist->plot( { 'outfile' => $pic_outFile . ".distance.$steps" } );
		$hist->ScaleSumToOne();
		$hist->plot(
			{ 'outfile' => $pic_outFile . ".distance.$steps.probability_plot" }
		);
	}
	else {
		warn "we got no values (internal_value process)!\n";
		print "databse error:\n";
		print $database->{error};
		print "gbFeatures errors:\n", $error;
		print "the gbFeatures array: \n@$featureList\n";
		print "and at last the values: \n@hist_data\n";
	}
	print "we got the following warnings:\n", $warning if ( $warning =~ /\w/ );
	return 1;
}

sub internal_value {
	my ( $dependant_vals, $featureList, $steps, $pic_outFile ) = @_;
	my ( $gbFeature, @hist_data, $hist, $error, $value );
	$error = '';
	my $warning = '';
	foreach $gbFeature ($featureList->asArray()) {
		print
"we try to select a value from gbFeature tag $dependant_vals->{'entryName'}",
		  " with the regExp:\n$dependant_vals->{'regExp'}\n"
		  if ($debug);
		$value =
		  $gbFeature->selectValue_from_tag_str( $dependant_vals->{'entryName'},
			$dependant_vals->{'regExp'} );
		if ( defined $value ) {
			push( @hist_data, $value );
		}
		else {
			$warning .=
"the regExp '$dependant_vals->{'regExp'}' did not match to gbFeature:\n"
			  . $gbFeature->getAsGB() . "\n";
		}
		$error .= $gbFeature->{error};
	}
	$hist = new_histogram->new();
	if ( defined $hist_data[0] ) {
		##looks like we got data!
		$hist->CreateHistogram( \@hist_data, undef, $steps );
		$hist->plot( { 'outfile' => $pic_outFile . ".internal_value.$steps" } );
		$hist->ScaleSumToOne();
		$hist->plot(
			{
				    'outfile' => $pic_outFile
				  . ".internal_value.$steps.probability_plot"
			}
		);
	}
	else {
		warn "we got no values (internal_value process)!\n";
		print "databse error:\n";
		print $database->{error};
		print "gbFeatures errors:\n", $error;
		print "the gbFeatures array: \n@$featureList\n";
		print "and at last the values: \n@hist_data\n";

	}
	print "we got the following warnings:\n", $warning if ( $warning =~ /\w/ );
	return 1;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for histogram_for_gbFeature_values.pl
 
   -organism          :the organism string to select the database
   -gbFeature_tag     :the gbFeature tag to sleect the interesting features
   -gbFeature_name    :the name tag of the gbFeatures (regExp)
   -regExp            :the RegExp to select the wanted info from the gbFeature (needed for 'internal_value')
   -entryName         :the anme of the gbFeature entry to select the info from (needed for 'internal_value')
   -min_distance      :the minimal distance two features must have to be included in the evaluation (needed for 'distance')
   -max_distance      :the maximum distance two features must have to be included in the evaluation (needed for 'distance')
   -regionLength      :the max region length (needed for 'amount_inRegion')
   -hist_steps        :the amount of steps for the histogram to display ( default = 100)
   -histogram_outfile :the name of the hist pic outfile
   -help              :print this help
   -debug             :verbose output
   -internalFunctions :select from a list of internal functions by name:
|----------------------------------------------------------------------------------
|   			name   |  description                                             |
|----------------------------------------------------------------------------------
|       internal_value | select a internal entry in the gbFeature and display that|
|                      | here we need the -entryName and the -regExp values       |
|             distance | calculate the distance between two start points of one of|
|                      | the anayzed gbFeatures (you have to specifie a range     |
|      amount_inRegion | calculate how many of the gbFeaures lie in one region    |
|                      | you have to specify a -regionLength for this to work     |
-----------------------------------------------------------------------------------
";
}
