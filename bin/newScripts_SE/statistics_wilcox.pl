#! /usr/bin/perl

use strict;
use Statistics::R;
use Getopt::Long;

my ( $infile, $patternA, $patternB, $p_accepted, $infoList, @infoList );

Getopt::Long::GetOptions(
	"-infile=s"          => \$infile,
	"-pattern4groupX=s"  => \$patternA,
	"-pattern4groupY=s"  => \$patternB,
	"-p_value_cutoff=s"  => \$p_accepted,
	"-additionalInfos=s" => \$infoList
) or die &helpString();

die &helpString()
  unless ( defined $infile && ( defined $patternA || defined $patternB ) );

sub helpString {
	return
"A wilcox singed rank test for single lines of a tab separated text file is calculated 
using the R wilcox.test(x, y,conf.int = TRUE, exact = 0) algorithm.
 
command line options for statistical test:

   -infile          : the name of the table file
   -pattern4groupX  : a string to select the rows that contain the data for value group x
                      Oops - the string is used for a regular pattern match!
   -pattern4groupY  : a string to select the rows that contain the data for value group y
                      Oops - the string is used for a regular pattern match!
   -p_value_cutoff  : the maxiumum p_value that should be reported
                      default: p < 0.05
   -additionalInfos : Information that should be included in the report,
                      but is not necessary for the calculation
";
}

open( IN, "<$infile" )
  or die "could not open infile '$infile' (first command line argument)\n";

warn
"		Have much fun and keep in mind, that the columns are selecetd by an regular pattern match! 
";

warn "Infomation for column names $infoList\n";
@infoList = split( ';', $infoList ) if ( defined $infoList );
@infoList = ( "Gene Symbol", "mRna - Description" )
  unless ( defined @infoList[0] );
warn "got converted to the array @infoList\n";

$p_accepted = 0.05 unless ( defined $p_accepted );
my (
	$temp,               $lineFit,            $iterator,
	@columnsOfInterestA, @columnsOfInterestB, $info_Printed,
	@line,               @referenceData,      @actualData,
	@infoListNr,         $R
);

$R       = Statistics::R->new();
$R->startR;
die "R could not be called" unless ( $R->is_started() );

$iterator = -1;
my $g = 0;
while (<IN>) {

	if ( $iterator == -1 ) {
		$iterator++;
		foreach my $info (@infoList) {
			($temp) =
			  &select_multiple_ColumnNumbers_by_PatternMatch( $info, $_ );
			push( @infoListNr, $temp );
		}
		warn
"we got the info column name(s) @infoList and the column numbers @infoListNr\n";
		die next;
	}
	if ( $iterator == 0 ) {
		$iterator++;
		@columnsOfInterestA =
		  &select_multiple_ColumnNumbers_by_PatternMatch( $patternA, $_ );
		@columnsOfInterestB =
		  &select_multiple_ColumnNumbers_by_PatternMatch( $patternB, $_ );
	}
	$_ =~ s/,/\./g;
	@actualData = ();
	chomp $_;
	@line = split( "\t", $_ );
	for ( my $i = 0 ; $i < @columnsOfInterestA ; $i++ ) {
		@referenceData[$i] = $line[ $columnsOfInterestA[$i] ];
	}
	for ( my $i = 0 ; $i < @columnsOfInterestB ; $i++ ) {
		@actualData[$i] = $line[ $columnsOfInterestB[$i] ];
	}
	&calculate_and_print_wilcox_statistics( \@referenceData, \@actualData,
		\@line, $p_accepted );
	if ( $iterator++ > 200 ) {
		$iterator = 2;
		$R->restartR();
		warn "R restarted in evaluation $a\n";
		die "R could not be called" unless ( $R->is_started() );
	}
	$a++;
}

sub calculate_and_print_wilcox_statistics {
	my ( $referenceData, $actualData, $line, $cutoff_p_value ) = @_;

	my @string;
	@string = (
		"x<- c(",
		join( ',', @$referenceData ),
		")\ny<-c(",
		join( ',', @$actualData ),
		")\nres <- wilcox.test( x,y,conf.int = TRUE, exact = 0)\n",
		"print ( res )"
	);
	my $cmd = join( '', @string );
	$R->send($cmd);
	my $return = $R->read();
	## remove the line breaks
	my @return = split( "\n", $return );
	$return = join( " ", @return );
	## select the interesting information from the R results
	my $p = $1 if ( $return =~ m/p-value *[=<] *(\d\.[e-\d]+)/ );

	#$return =~ m/(p-value *[=<] *................)/;
	next unless ( defined $p );

	#print "@$line[$infoListNr[0]] Do we have a problem : $1 = $p?\n";
	my $w = $1 if ( $return =~ m/W *= *([\d\.]+)/ );
## Wilcoxon rank sum test with continuity correction  data:  x and y  W = 225, p-value = 3.383e-06 alternative hypothesis: true location shift is not equal to 0  95 percent confidence interval:  50.67999 55.74005  sample estimates: difference in location                 53.7565
	#my $rho = $1 if ( $return =~ m/rho *(-?[\d\.]+) *$/);

	#print "return= \n$return\n";

	my ( $conf_int_low, $conf_int_high, $difference ) = ( $1, $2, $3 )
	  if ( $return =~
m/confidence interval: *(-?\d+\.?[e-\d]+) +(-?\d+\.?[e-\d]+).*in location *(-?\d+\.?[e-\d]+)/
	  );
	unless ($info_Printed) {
		foreach my $info (@infoList) {
			print "$info\t";
		}
		print
"W\tp_value\tlow conf. int.\thigh conf. int.\tmean difference\t->values\n";
		$info_Printed = 0 == 0;
	}
	if ( $p < $cutoff_p_value ) {
		foreach my $number (@infoListNr) {
			print "@$line[$number]\t";
		}
		print
		  "$w\t$p\t$conf_int_low\t$conf_int_high\t$difference\t$patternA->\t",
		  join( "\t", @$referenceData ), "\t$patternB->\t",
		  join( "\t", @$actualData ),    "\n";
	}

	#print  "gene\t@$line[17]\t@$line[22]\n",
	#      $return,"\n" if ( $p >= 0.05 );

	#warn "No p value for:\ngene\t@$line[17]\t@$line[22]\n",
	#      $return,"\n" unless ( $p >= 0.05 || $p < 0.05);;
}

sub select_multiple_ColumnNumbers_by_PatternMatch {
	my ( $title, $line ) = @_;
	chomp $line;
	my ( @lineArray, @linesOfInterest );
	@lineArray = split( "\t", $line );
	for ( my $i = 0 ; $i < @lineArray ; $i++ ) {

		#        print "we are checking column title $lineArray[$i]\n";
		push( @linesOfInterest, $i ) if ( $lineArray[$i] =~ m/$title/ );
	}
	die "we could not determin the column number for string '$title'\n"
	  unless ( defined $linesOfInterest[0] );

	#    print "We are evaluating lines \n@linesOfInterest\n";
	return @linesOfInterest;
}

