#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::correlatingData;
use stefans_libs::root;
#use stefans_libs::database::experiment;
#use stefans_libs::database::expression_net;
#use stefans_libs::database::expression_estimate;

use Getopt::Long;
use FileHandle;

my ( $infile, $outfile, $pattern, $help, $phenothpeTable, $debug, @phenotypes,@genes,
	$cutOff, $start_at_line );

Getopt::Long::GetOptions(
	"-array_values=s"   => \$infile,
	"-outfile=s"        => \$outfile,
	"-p4cS=s"           => \$pattern,
	"-start_at_line=s"  => \$start_at_line,
	"-help"             => \$help,
	"-p_value=s"        => \$cutOff,
	"-debug"            => \$debug, 
	"-correlate_with_genes=s{,}" => \@genes
) or die &helpString();

die &helpString()
  unless ( defined $infile && defined $outfile );

die &helpString() if ($help);

sub helpString {
	return "
 command line switches for createConnectionNet_4_expressionArrays.pl:
 
   -array_values   :the table file containing the expresion values (tab separated)
   -p_value        :the max p value for the reported test statistics
   -outfile        :the name of the outfile (<tab> separated table)
   -p4cS           :the pattern to select the data containing columns
   -start_at_line  :the first lie to start the calculation
   -correlate_with_genes
                   :a list of genes for which you want to calculate 
                    the correlation with all the other genes
   -help           :print this help
   -debug          :verbose output
 "
}

my ( $correlatingData, $lineCount );
## 1. read the phenotype data
$cutOff = 0.05 unless ( defined $cutOff );
$correlatingData = correlatingData->new($debug);


my @outfile = split( "/", $outfile );
pop(@outfile);

my $outPath = join( "/", @outfile );
mkdir($outPath) unless ( -d $outPath );

my (
	@possibleGroupingValues, @statObjects,
	$groupTag,               @dataColumnHeaders,
	$tableHandling,          $filename,
	@temp,                   $infoPositions,
	$temp,                   $statTests_per_TableLine, $data_array,
	$this_str, $dataPositions
);



$tableHandling = tableHandling->new();

open( IN, "<$infile" )
  or die "could not open array data file '$infile' in batchStatistic.pl\n";
print "opened the expression array dataset $infile\n";
$lineCount = 0;
my $statObj;
my @data_array = (<IN>);

close ( IN );
$dataPositions = $tableHandling->identify_columns_of_interest_patternMatch(
				$data_array[0], $pattern
			);
@dataColumnHeaders = $tableHandling->get_column_entries_4_columns(
			$data_array[0],$dataPositions
);
$infoPositions = $tableHandling->identify_columns_of_interest_bySearchHash(
			$data_array[0],
			$tableHandling->createSearchHash(
				"Gene Symbol"
			)
);
my $header = '';
my $log_header = '';
my $sign;
$correlatingData->{referenceLine} = $data_array[0];

	
if ( -f $outfile){
	open (OUT ,">>$outfile") or die "could not create outfile '$outfile'\$!\n";
	open (LOG ,">>$outfile.log") or die "could not create log file '$outfile.log' \n$!\n";
}
else {
	$header = "gene\tcorrelating gene\tP_value\tS\tR_square\n";
	$log_header = "correlating gene\tamount of genes correlating with p<$cutOff\n";
	open (OUT ,">$outfile") or die "could not create outfile '$outfile'\$!\n";
	open (LOG ,">$outfile.log") or die "could not create log file '$outfile.log' \n$!\n";
}


$start_at_line = 1 unless ( defined $start_at_line);
$start_at_line = 1 if ( $start_at_line < 1);

print OUT $header;#.join("\t", @dataColumnHeaders)."\n";
print LOG $log_header;

if ( defined $genes[0] ){
	## we only correlate some genes with all the other datasets
	$header = join( " ",@genes);
	
	$sign = 0;
	for (my $i = 0; $i < @data_array; $i ++){
		chomp ( $data_array[$i] );
		$this_str = join ("_", $tableHandling->get_column_entries_4_columns( $data_array[$i], $infoPositions));
		$this_str = $1 if ( $this_str =~m/ *([\w-]+) *$/ );
		#print "we match '$header' to '$this_str'\n";
		next unless ( &geen_is_needed($this_str,@genes) );
		print " $header matches to $this_str\n";
		## now we have one gene we are interested in!
		$correlatingData->{data}->{ $this_str } = $data_array[$i];
		$statObj = $correlatingData->getStatObj_4_dataLine_and_correlationValue( \@dataColumnHeaders, $this_str );
		$log_header = $data_array[0];
		$statObj -> processTableHeader ( $log_header, $infoPositions);
		for ( my $data_nr = 0; $data_nr < @data_array; $data_nr++){
			$temp = $statObj->getTest_result( $data_array[$data_nr], 1 );
		if ( $statObj->error() ) {
			warn $statObj->error();
			next;
		}
		#print $statObj->{lastP}."\n";
		if (   $statObj->{lastP} < $cutOff
			&& $statObj->{lastP} > 0 )
		{
			$sign++;
			@temp = split( "\t", $temp);
			print OUT join ("\t",( $this_str,$temp[0],$temp[1],$temp[2],$temp[3] ) )."\n";
			#print OUT join ("\t",( $temp[0],$this_str,$temp[1],$temp[2],$temp[3] ) )."\n";
			#print "temp = ".$temp."\n";
		}
		
		}
		print LOG "$this_str\t$sign\n";
		$statObj->DESTROY();
	}
	
}
else {
for (my $correlation_nr = $start_at_line; $correlation_nr < @data_array; $correlation_nr++){
	$sign = 0;
	chomp ( $data_array[$correlation_nr] );
	$this_str = join ("_", $tableHandling->get_column_entries_4_columns( $data_array[$correlation_nr], $infoPositions));
	$correlatingData->{data}->{ $this_str } = $data_array[$correlation_nr];
	$statObj = $correlatingData->getStatObj_4_dataLine_and_correlationValue( \@dataColumnHeaders, $this_str );
	$statObj -> processTableHeader ( $data_array[0], $infoPositions);
	#$statObj -> AddGroupingHash ();
	
	for ( my $data_nr = $correlation_nr +1 ; $data_nr < @data_array; $data_nr ++){
		## correlate the data!
		$temp = $statObj->getTest_result( $data_array[$data_nr], 1 );
		if ( $statObj->error() ) {
			warn $statObj->error();
			next;
		}

		if (   $statObj->{lastP} < $cutOff
			&& $statObj->{lastP} > 0 )
		{
			$sign++;
			@temp = split( "\t", $temp);
			print OUT join ("\t",( $this_str,$temp[0],$temp[1],$temp[2],$temp[3] ) )."\n";
			print OUT join ("\t",( $temp[0],$this_str,$temp[1],$temp[2],$temp[3] ) )."\n";
			#print "temp = ".$temp."\n";
		}
	}
	print LOG "$this_str\t$sign\n";
	$statObj->DESTROY();
}
}

sub geen_is_needed {
	my ( $gene, @genes ) =@_;
	foreach my $g ( @genes ){
		return 1 if ( $g eq $gene);
	}
	return 0;
}
close (OUT);
close (LOG);