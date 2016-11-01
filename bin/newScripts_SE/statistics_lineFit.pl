#! /usr/bin/perl

use strict;
use Statistics::LineFit;
use Statistics::R;

my ( $infile, $pattern, $p_accepted ) = @ARGV;

open( IN, "<$infile" )
  or die "could not open infile '$infile' (first command line argument)\n";

warn "the differnet datasets has to be stored in lines, not rowes.
The first line is ment to consist of column titles and is used to select the columns that should be evaluated!
The second line is the line with the corelating data set. 
All further lines contain the data that schould be compared to the second line.

Have much fun and keep in mind, that the columns are selecetd by an regular pattern match! 
";

$p_accepted = 0.05 unless ( defined $p_accepted);
my ( $lineFit, $iterator, @columnsOfInterest );

$iterator = -1;
$lineFit  = Statistics::LineFit->new();
my $R = Statistics::R->new();
$R->startR;
die "R could not be called" unless ( $R->is_started());


my ( @line, @referenceData, @actualData, $GeneTagNr, $GeneInfoNr );

while (<IN>) {

    if ( $iterator == -1 ) {
        @columnsOfInterest =
          &select_multiple_ColumnNumbers_by_PatternMatch( $pattern, $_ );
	$iterator ++;
	($GeneTagNr) = &select_multiple_ColumnNumbers_by_PatternMatch( "Gene Symbol", $_ );
        ($GeneInfoNr) = &select_multiple_ColumnNumbers_by_PatternMatch( "mRna - Description", $_ ); 
        next;
    }
    $_ =~ s/,/\./g;
    @actualData = ();
    chomp $_;
    @line = split( "\t", $_ );
    for ( my $i = 0 ; $i < @columnsOfInterest ; $i++ ) {
        @actualData[$i] = $line[ $columnsOfInterest[$i] ];
    }
    if ( $iterator == 0 ) {
        ## the reference data!
	print "gene ID\tgene description\ts\tp\tslope (rho)\t->data values\n";
        @referenceData = (@actualData);
        $iterator++;
        next;
    }
	#&calculate_and_print_normal_lineFit(\@referenceData, \@actualData, \@line );
	&calculate_and_print_spearmanWeightFit_statistics (\@referenceData, \@actualData, \@line, $p_accepted);

	#die "just a test!\n";
}

sub calculate_and_print_spearmanWeightFit_statistics{
	my ( $referenceData, $actualData, $line, $cutoff_p_value ) = @_;
	
	my @string;
	@string = ( "x<- c(",join(',',@$referenceData),")\ny<-c(",join(',',@$actualData),")\nres <- cor.test( x,y,method='spearman')\n",
	"print ( res )");
	my $cmd = join ('', @string);
	$R->send($cmd);
	my $return = $R->read();
	my @return = split ( "\n", $return);
	$return = join ( " ", @return);
	my $p = $1 if ($return =~ m/p-value [=<] (\d\.\d+)/);
	my $s = $1 if ($return =~ m/S *= *([\d\.]+)/);
	my $rho = $1 if ( $return =~ m/rho *(-?[\d\.]+) *$/);
	print  "@$line[$GeneTagNr]\t@$line[$GeneInfoNr]",
	      "\t$s\t$p\t$rho\tx->\t",join("\t",@$referenceData),"\ty->\t",join("\t",@$actualData),"\n" if ( $p < $cutoff_p_value );
	#print  "gene\t@$line[17]\t@$line[22]\n",
        #      $return,"\n" if ( $p >= 0.05 );
	
	#warn "No p value for:\ngene\t@$line[17]\t@$line[22]\n",
        #      $return,"\n" unless ( $p >= 0.05 || $p < 0.05);;
}

sub byColum1{
	return @$a[1] <=> @$b[1];
}

sub byColumn0{
        return @$a[0] <=> @$b[0];
}


sub calculate_and_print_normal_lineFit{
	my ( $referenceData, $actualData, $line ) = @_;

my (
    $intercept,        $rsquared,     $slope,     $rSquared,
    $meanSquaredError, $durbinWatson, $sigma,     $tStatIntercept,
    $tStatSlope,       @predictedYs,  @residuals, $varianceSlope
);

    $lineFit->setData( $referenceData, $actualData ) or die "Invalid data";
    ( $intercept, $slope ) = $lineFit->coefficients();
    defined $intercept or warn "Can't fit line if x values are all equal";
    $rSquared         = $lineFit->rSquared();
    $meanSquaredError = $lineFit->meanSqError();
    $durbinWatson     = $lineFit->durbinWatson();
    $sigma            = $lineFit->sigma();
    ( $tStatIntercept, $tStatSlope ) = $lineFit->tStatistics();

    #    @predictedYs = $lineFit->predictedYs();
    #    @residuals = $lineFit->residuals();
    #   (varianceIntercept, $varianceSlope) = $lineFit->varianceOfEstimates();

        print "Gene info\t$line[$GeneTagNr]\t$line[$GeneInfoNr]
intercept\t$intercept
slope\t$slope
rsquared\t$rSquared
meanSquareError\t$meanSquaredError
durbinWatson\t$durbinWatson
sigma\t$sigma
tStatIntercept\t$tStatIntercept
tStatSlope\t$tStatSlope
\n" if ($rSquared > 0.4 && $rSquared < 1 );# if ( $durbinWatson < 2.5 && $durbinWatson > 1.5 );
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

