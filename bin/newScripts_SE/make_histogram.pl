#! /usr/bin/perl

use strict;
use warnings;
use stefans_libs::statistics::new_histogram;
use Getopt::Long;
use stefans_libs::tableHandling;
use GD::SVG;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use stefans_libs::plot::axis;

my ( $tableFile, $outFile, $searchColumnTitles, $help, $headingLine, $sepString,
	$columns, $pattern );

Getopt::Long::GetOptions(
	"tableFile=s"          => \$tableFile,
	"outFile=s"            => \$outFile,
	"columns=s"            => \$columns,
	"p4cS=s"               => \$pattern,
	"searchColumnTitles=s" => \$searchColumnTitles,
	"headingLine=s"        => \$headingLine,
	"separatingString=s"   => \$sepString,
	"help"                 => \$help
) or die &helpString();

die &helpString() if ($help);
die &helpString()
  unless ( defined $tableFile && defined $outFile );

sub helpString {
	my $warning_str = shift;
	return "$warning_str\ncommand line options:
 	
   -tableFile                 :the file containing all data in tab seaparated text format
   -separatingString          :the separating sting in the table file (default = \\t)
   -columns                   :the amount of columns used to create the histogram
   -outFile                   :the file to store the selected table lines in
   -searchColumnTitles        :a semicolon (;) separated list of column titles (first line entries) 
                               we look for the different tags (complete match!)
   -p4cS                      :the pattern to select the data containing columns
   -headingLine               :the line, the column headings are stored in (default = 0)
   -help                      :display this help message
 ";
}

open( IN, "<$tableFile" ) or die "can not open file '$tableFile'\n";

my ( $lineNrs, @data, @lineArray, $line_nr );

my $tableHandling = tableHandling->new();
$headingLine = 1 unless ( defined $headingLine );

$line_nr = 0;

while (<IN>) {
	$line_nr++;
	if ( $line_nr == $headingLine ) {
		if ( defined $searchColumnTitles ) {
			$lineNrs = $tableHandling->identify_columns_of_interest_bySearchHash(
				$_,
				$tableHandling->createSearchHash(
					split( ";", $searchColumnTitles )
				)
			);
			unless ( defined @$lineNrs[0] ) {
				die
"we could not identify the column titles using the data line:\n$_";
			}
		}
		elsif ( defined $pattern ) {
			$lineNrs =
			  $tableHandling->identify_columns_of_interest_patternMatch( $_,
				$pattern );
			unless ( defined @$lineNrs[0] ) {
				die
"we could not identify the column titles using the search pattern $pattern and the table line:\n$_";
			}
		}
		else {
			die &helpString(
"we do need either several table header strings or a pattern that matches to all intersting columns to select the data!"
			);
		}
		next;
	}

	push( @data, ( $tableHandling-> get_column_entries_4_columns ($_, $lineNrs) ) );

}

close(IN);
my $histogram = new_histogram->new();
$histogram -> CreateHistogram ( \@data, undef, $columns);
$histogram -> plotSingle ( 1 );
my $im = GD::SVG::Image->new( 800,600);
my $color = color->new( $im );
$histogram -> plot_2_image ( $im, 100,   40, 760,
		560,    $color->{black},     $color->{gray}, "data values",  "amount of data points", undef, 'Y');
&writePicture ( $im, $outFile);


sub writePicture {
 	my ( $im, $pictureFileName ) = @_;
 
 	# Das Bild speichern
 	print "bild unter $pictureFileName speichern:\n";
 	my ( @temp, $path );
 	@temp = split( "/", $pictureFileName );
 	pop @temp;
 	$path = join( "/", @temp );
 
 	#print "We print to path $path\n";
 	mkdir($path) unless ( -d $path );
 	$pictureFileName = "$pictureFileName.svg"
 	  unless ( $pictureFileName =~ m/\.svg$/ );
 	open( PICTURE, ">$pictureFileName" )
 	  or die "Cannot open file $pictureFileName for writing\n";
 
 	binmode PICTURE;
 
 	print PICTURE $im->svg;
 	close PICTURE;
 	print "Bild als $pictureFileName gespeichert\n";
 	$im = undef;
 	return 1;
 }
