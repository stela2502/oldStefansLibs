#/usr/bin/perl

use strict;
use warnings;
use Bio::Affymetrix::CEL;

use Getopt::Long;

my ( $outfile, $infile, $debug, $help );

Getopt::Long::GetOptions(
	"-outfile=s" => \$outfile,
	"-infile=s"  => \$infile,
	"-debug"     => \$debug,
	"-help"      => \$help
) or die &helpString("we have a problem here!");

die &helpString("no file? \n$infile\n$outfile")
  unless ( -f $infile && defined $outfile );

die &helpString("you called for help?") if ($help);

sub helpString {
	my $start = shift;
	if ($debug) {
		return "
	infile      = $infile
	outfile     = $outfile
	debug       = $debug
	", "
command line switches for convert_affy_cel_to_DBtext.pl:

  -infile    : the text or biniary formated cel file
  -outfile   : the outfile
  -help      : print this help
  -debug     : verbose output
";
	}
	return "
command line switches for convert_affy_cel_to_DBtext.pl:

  -infile    : the text or biniary formated cel file
  -outfile   : the outfile
  -help      : print this help
  -debug     : verbose output
";
}

# Parse the CDF file

my $cel = new Bio::Affymetrix::CEL();

$cel->parse_from_file($infile);

# Print out all of the intensities for each square
open( OUT, ">$outfile" ) or die "could not create outfile '$outfile'\n";

my $parameters = $cel->algorithm_params();
my @strings = ( "", "");
$strings[0] .=  "algorithm name\t";
$strings[1] .= $cel->algorithm_name()."\t";

$strings[0] .=  "algorithm name\t";
$strings[1] .= $cel->original_file_name()."\t";

while ( my ($name, $value) = each %$parameters ){
	$strings[0] .= $name."\t";
	$strings[1] .= $value."\t";
}

chop $strings[0];
chop $strings[1];

print OUT  $strings[0],"\n",$strings[1],"\n";

print OUT "X\tY\tmean\tstd\tnumber of pixels\tuser said 'masked'\tsoftware has said 'outlier'\n";

for ( my $x = 0 ; $x < scalar( @{ $cel->intensity_map() } ) ; $x++ ) {
	for ( my $y = 0 ; $y < scalar( @{ $cel->intensity_map()->[$x] } ) ; $y++ ) {
		print OUT join(
			"\t",
			(
				$x,
				$y,
				$cel->intensity_map->[$x][$y]->[0],
				$cel->intensity_map->[$x][$y]->[1],
				$cel->intensity_map->[$x][$y]->[2],
				$cel->intensity_map->[$x][$y]->[3]
			) ), "\n";
	}
}

close OUT;