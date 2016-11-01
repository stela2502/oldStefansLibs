#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::correlatingData;
use stefans_libs::root;
use Getopt::Long;
use FileHandle;

my ( $infile, $outfile, @pattern, $help, $phenothpeTable, $debug, @phenotypes,
	 $cutOff );

Getopt::Long::GetOptions(
	"-array_values=s"   => \$infile,
	"-outfile=s"        => \$outfile,
	"-p4cS=s{,}"        => \@pattern,
	"-help"             => \$help,
	"-phenotypeTable=s" => \$phenothpeTable,
	"-p_value=s"        => \$cutOff,
	"-phenotypes=s{,}"  => \@phenotypes,
	"-debug"            => \$debug
) or die &helpString();

die &helpString()
  unless ( defined $infile && defined $outfile && defined $phenothpeTable );

die &helpString() if ($help);

warn "we got these patterns 4 column search: '"
.join("', '", @pattern)."'\n";

sub helpString {
	return "
 command line switches for batchStatistics.pl:
 
   -array_values   :the table file containing the expresion values (tab separated)
   -phenotypeTable :the table containing the phenotypic data set (tab separated)
   -phenotypes     :a semicolon separated list of wanted phenotypes (included in the phenotypeTable!)
   -p_value        :the max p value for the reported test statistics
   -outfile        :the name of the outfile (<tab> separated table)
   -p4cS           :the pattern to select the data containing columns
   -help           :print this help
   -debug          :verbose output
 "
}

my ( $correlatingData, $lineCount );
## 1. read the phenotype data
$cutOff = 0.05 unless ( defined $cutOff );
$correlatingData = correlatingData->new($debug);
$correlatingData->AddFile($phenothpeTable);
print "We got these phenotypic datasets: \n\t",
  join( "\n\t", $correlatingData->getPossible_CorrelationDataSets() ), "\n"
  if ($debug);
  
my ( $task_description);

$task_description .= 'batchStatistics.pl';
$task_description .= " -array_values $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= ' -p4cS "'.join( '" "', @pattern ).'"' if ( defined $pattern[0]);
$task_description .= " -phenotypeTable $phenothpeTable" if (defined $phenothpeTable);
$task_description .= " -p_value $cutOff" if (defined $cutOff);
$task_description .= ' -phenotypes '.join( ' ', @phenotypes ) if ( defined $phenotypes[0]);



my @outfile = split( "/", $outfile );
$outfile = pop(@outfile);

my $outPath = join( "/", @outfile );
mkdir($outPath) unless ( -d $outPath );

my (
	@possibleGroupingValues, @statObjects,
	$groupTag,               @dataColumnHeaders,
	$tableHandling,          $filename,
	@temp,                   $infoPositions,
	$temp,                   $statTests_per_TableLine
);

if ( defined $phenotypes[0] ) {
	@possibleGroupingValues = @phenotypes;
}
else {
	@possibleGroupingValues =
	  $correlatingData->getPossible_CorrelationDataSets();
}

die "No evaluation as no grouping datasets are available!\n"
  unless ( defined $possibleGroupingValues[0] );

root::print_hashEntries( \@possibleGroupingValues, 3,
	"the grouping values in batchStatistics?" );
$tableHandling = tableHandling->new();

open( IN, "<$infile" )
  or die "could not open array data file '$infile' in batchStatistic.pl\n";
print "opened the expression array dataset $infile\n";
$lineCount = 0;

while (<IN>) {
	$lineCount++;
	chomp $_;
	$_ =~ s/,/\./g;  ## change from european decimal separator',' to english '.'

	if ( $lineCount == 1 ) {
		## we have to create groups for each test type
		print
"\nwe try to select the data containing columns using the pattern ".join (" ", @pattern) ."\n"
		  if ($debug);
		unless ( defined $pattern[1] ) {
			@dataColumnHeaders = $tableHandling->get_column_entries_4_columns( $_,
			  $tableHandling->identify_columns_of_interest_patternMatch(
				$_, $pattern[0] ) );
		}
		else {
			@dataColumnHeaders = $tableHandling->get_column_entries_4_columns( $_,
			  $tableHandling->identify_columns_of_interest_bySearchHash(
				$_, $tableHandling->createSearchHash(@pattern) ));
		}
		
		

		$infoPositions =
		  $tableHandling->identify_columns_of_interest_bySearchHash(
			$_,
			$tableHandling->createSearchHash(
				"Gene Symbol", "mRna - Description",
				"Probe Set ID"
			)
		  );

		die
"we got no data to evaluate! ( @dataColumnHeaders )\nheader line\n$_\n"
		  unless ( defined $dataColumnHeaders[0] );

		for ( my $i = 0 ; $i < @possibleGroupingValues ; $i++ ) {
			my $statObj =
			  $correlatingData->getStatObj_4_dataLine_and_correlationValue(
				\@dataColumnHeaders, $possibleGroupingValues[$i] );

			unless ( defined $statObj ) {
				print "we got no StatObj for phenotypeDataset $groupTag\n"
				  if ($debug);
				next;
			}

			my ($fh);
			( $fh, $filename ) =
			  createFileHandle( $outPath, $outfile,
				$possibleGroupingValues[$i] );

#die "we have created the filehandle $outPath/$outfile ($possibleGroupingValues[$i]) \n";
			my $log;
			( $log, $temp ) =
			  createFileHandle( $outPath, "$outfile.log",
				$possibleGroupingValues[$i] );
			push(
				@statObjects,
				{
					group      => $possibleGroupingValues[$i],
					statObj    => $statObj,
					filename   => $filename,
					fileHandle => $fh,
					logFile    => $log,
					tableHeader =>
					  $statObj->processTableHeader( $_, $infoPositions )
				}
			);

			print {$fh} $statObj->processTableHeader( $_, $infoPositions );

			print
"the phenotypic data set $possibleGroupingValues[$i] is evaluated using a ",
			  ref($statObj), " statistical object\n"
			  if ($debug);
			root::print_hashEntries( $statObjects[$#statObjects], 4,
"a statistical object returned for the grouping variable $possibleGroupingValues[$i]"
			);
		}
		$statTests_per_TableLine = $#statObjects;
		next
		  ; # we do not want to calculate anything using the column header line!
	}

	last;
}
my $sign;
foreach my $hashRef (@statObjects) {
	seek( IN, 0, 0 );
	print "We evaluate grouping variable $hashRef->{group}\n";
	$lineCount = $sign = 0;
	while (<IN>) {
		$lineCount++;
		chomp $_;
		print "We analyze a line $_\n" if ($debug);
		next if ( $_ =~ m/^#/);
		#print "I process genes line\n\t$_\n";
		if ( $lineCount == 1 ) {
			print $hashRef->{tableHeader}, "\n" if ($debug);
			next;
		}
		$temp = $hashRef->{statObj}->getTest_result( $_, 1 );
		if ( $hashRef->{statObj}->error() =~ m/\w/ ) {
			warn "we did not get any result for line $_\n". $hashRef->{statObj}->error()."\n".$temp."\n";
		}
		elsif ($hashRef->{statObj}->{lastP} < $cutOff
			&& $hashRef->{statObj}->{lastP} > 0 )
		{
			$sign++;
			print { $hashRef->{fileHandle} } $temp;

			#print "'$temp'";

		}

		print "$temp $hashRef->{statObj}->{lastP} < $cutOff\n"
		  if ($debug);
	}
	$lineCount--;
	print { $hashRef->{logFile} } $task_description."\n";
	print { $hashRef->{logFile} } "stat test\t", ref( $hashRef->{statObj} ),
	  "\n", "amount of testes\t$lineCount\n", "significant\t$sign\n";
	print "done with group $hashRef->{group}\n";
	close( $hashRef->{logFile} );
	print "Log written to $hashRef->{filename}.log\n";
	close( $hashRef->{fileHandle} );
	print "results were written to $hashRef->{filename}\n";
}

close(IN);

sub createFileHandle {
	my ( $outPath, $outfile, $info ) = @_;

	my (@temp);

# my ($fh, $filename ) = createFileHandle ( $outPath, $outfile, $possibleGroupingValues[$i]);
	unless ( -d $outPath ) {
		warn "we have to create the directory $outPath\n";
		mkdir($outPath) or die "$!\n";
	}
	@temp = split( /[ ()\/]+/, $info );
	my $filename = join( '_', @temp );
	$filename = "$outPath/$filename-$outfile";
	my $fh = new FileHandle ">$filename";
	die "Cannot open $filename: $!" unless ( defined $fh );
	return $fh, $filename;
}
