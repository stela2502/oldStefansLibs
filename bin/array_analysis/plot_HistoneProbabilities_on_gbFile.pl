#! /usr/bin/perl

use strict;
use stefans_libs::gbFile;
use stefans_libs::plot::simpleXYgraph;
use stefans_libs::multiLinePlot::multiline_gb_Axis;

use Getopt::Long;

my ( $gbFileLoc, $start, $end, $nuclPos_arrayLoc, $help );

Getopt::Long::GetOptions(
	"-nuclPosFile=s" => \$nuclPos_arrayLoc,
	"-start=s"       => \$start,
	"-end=s"         => \$end,
	"-help"          => \$help,
	"-gbFile=s"      => \$gbFileLoc
) or die &helpString();

die &helpString() if ($help);

die "you have to use the options -nuclPosFile and -gbFile\n", &helpString()
  unless ( -f $nuclPos_arrayLoc && -f $gbFileLoc );

sub helpString {
	return
"the script will try to identify enhancer and promoter elements soly on the basis of nucleosome
positioning data created by the model published in Kaplan et al. 2008 PMID:19092803
 
command line options for statistical test:

   -nuclPosFile : the name of the NuclPos file
   -gbFile      : the corresponding gbFile
   -start       : the start of the displayed region
   -end         : the end of the displayed region

";
}

my ( $gbFile, $plot, $model );

$plot = simpleXYgraph->new();

$plot->createPicture( 1000, 600 );

$gbFile = gbFile->new( $gbFileLoc );

$plot->X_axis(
	multiline_gb_Axis->new(
		$gbFile, $start, $end, 100, 500, 900, 550, "min", $plot->Color()
	)
);

open( IN, "<$nuclPos_arrayLoc" )
  or die "could not open the occupation array file '$nuclPos_arrayLoc'\n";

while (<IN>) {
	next if ( $_ =~ m/^#/ );
	$model = &createDataModel4plot($_, $start, $end);
	my $string = $gbFile->Name();
    $plot->plotData(
	$model->{plotHash},
	1000,
	600,
	"genomic locations [bp]",
	"probability to be occupied by a nucleosome",
	"Nucleosome positions at $string",
	"$string-picture-$start-$end.svg"
);
}


sub createDataModel4plot {
	my ($line, $start, $end) = @_;
	my ( $model, $temp, @y_array, @x_array, $hash, @array );
	chomp $line;
	( $model->{CHR}, $model->{start}, $model->{end}, $temp ) =
	  split( "\t", $line );
	return undef unless ( $temp =~ m/;/ );
	@array = split( ";", $temp );
	for ( my $i = $start ; $i <= $end ; $i++ ) {
		push (@x_array, $i);
		push (@y_array, $array[$i]);
		#print "DEBUG ##12 create x/y $x_array[$i]/$x_array[$i]\n";
	}
	$model->{probability_array} = \@array;
	$model->{plotHash} = { "nulc positioning data" => { x => \@x_array, y => \@y_array } };
	$model->{Length} = @y_array;
	return $model;
}
