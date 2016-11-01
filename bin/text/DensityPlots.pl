#! /usr/bin/perl
 
 use strict;
 use warnings;
 use stefans_libs::plot::densityMap;
 use stefans_libs::tableHandling;
 use stefans_libs::normalize::quantilNormalization;
 use Getopt::Long;
 
 my ( @infiles, @inputColumns, $log2, $log2_apply, $help, $debug, $noHeader,
 	$firstDataLine, $createGraph, $createFractions, $outpath, $normalize );
 
 Getopt::Long::GetOptions(
 	"-infiles=s{,}"      => \@infiles,
 	"-inputColumns=s{,}" => \@inputColumns,
 	"-outpath=s"		 => \$outpath,
 	"-log2"              => \$log2,
 	"-log2_apply"        => \$log2_apply,
 	"-noHeader"          => \$noHeader,
 	"-firstDataLine=s"   => \$firstDataLine,
 	"-createGraph"		 => \$createGraph,
 	"-createFractions"	 => \$createFractions,
 	"-normalize"         => \$normalize,
 	"-debug"             => \$debug,
 	"-help"              => \$help
 ) or die &helpString();
 
 die &helpString()
   unless ( -f $infiles[0] && defined $inputColumns[0] && -d $outpath );
 
 die &helpString() if ($help);
 
 sub helpString {
 	return "
 command line switches for createPhaseInputFiles:
 
   -infiles         :a list of data files
   -inputColumns    :a list of columns to use (if numerical the culumn numbers are used)
   -outpath         :the outpath (absolute)
   -log2            :the data values are supposed to be log2 and if '-log' but not '-log2_apply' is used, the log will be reversed
   -log2_apply      :the data will be plotted log2 transformed - if '-log2' is not given the log2 will be applied!
   -noHeader        :logical indicator, if the first data line contains a header (default to TRUE)
   -firstDataLine   :the line of every data file where the value collection should start (default to 1)
   -createGraph     :a density graph for each comparison between two data sets will be craeted
   -createFractions :for each dataset a fraction between this datset and each other dataset will be calculated
   -normalize       :the datasets are normalized unsing a quantilNormalization
   -debug           :verbose output
   -help            :print this help
 "
 }
 
 warn "we evaluate the files @infiles\n";
 if ( @infiles == 1 && @inputColumns == 1 ) {
 	die
 "bad joke - you want to correlate the dataset in $infiles[0] column $inputColumns[0] with nothing??\n";
 }
 
# if ( $debug){
# 	foreach my $variable ( [@infiles], [@inputColumns], $log2, $log2_apply, $help, $debug, $noHeader,
# 	$firstDataLine, $createGraph, $createFractions, $outpath, $normalize ){
# 		if ( ref($variable) eq "ARRAY" ){
# 		print " @$variable \n";
# 		}
# 		else { print "$variable\n" ;}
# 	}
# }
 
 ## here the real thing is starting!
 my ( $i, $columnsOfInterest, $tableHandling, @columnHeaders, @matrix,
 	$lineArray, $evaluationArrays, @namesArray );
 
 $tableHandling = tableHandling->new();
 $firstDataLine = 1 unless ( defined $firstDataLine );
 
 print  "\$firstDataLine = $firstDataLine\n" if ( $debug);
 
 foreach my $filename (@infiles) {
 	my @gff;
 	open( IN, "<$filename" ) or die "could not open file $filename\n";
 	$i = 0;
 	while (<IN>) {
 		$i++;
 		chomp $_;
 		next if ( $i < $firstDataLine );
 		if ( $i == $firstDataLine ) {
 			unless ($noHeader) {
 				print "Table header for table: $filename\n$_\n";
 				if ( join( "", @inputColumns ) =~ m/^\d+$/ ) {
 					print "we are analyzing only columnIDs!\n";
 					$columnsOfInterest = \@inputColumns;
 					@columnHeaders = (@inputColumns);
 				}
 				else {
 					$columnsOfInterest =
 					  $tableHandling->identify_columns_of_interest_bySearchHash(
 						$_, $tableHandling->createSearchHash(@inputColumns) );
 				}
 				@columnHeaders =
 				  $tableHandling->get_column_entries_4_columns( $_,
 					$columnsOfInterest );
 			}
 			else {
 				die
 "you have to give a list of column ids if you do not have a table header \n"
 				  unless ( join( "", @inputColumns ) =~ m/^\d+$/ );
 				$columnsOfInterest = \@inputColumns;
 				@columnHeaders = (@inputColumns);
 			}
 			concatenate($filename,\@columnHeaders);
 			push ( @namesArray, (@columnHeaders) );
 			next;
 		}
 		unless ( defined $matrix[ $i - $firstDataLine - 1 ] ) {
 			$matrix[ $i - $firstDataLine - 1 ] = [];
 		}
 		$lineArray = $matrix[ $i - $firstDataLine - 1 ];
 		push(
 			@$lineArray,
 			(
 				$tableHandling->get_column_entries_4_columns(
 					$_, $columnsOfInterest
 				)
 			)
 		);
 	}
 	close(IN);
 	print "dataRead $filename\n";
 }
 
 $evaluationArrays = transposeMatrix( \@matrix, $log2, $log2_apply );
 
 if ( $normalize){
 	print "we normalize the dataset!\n";
 	my $obj = quantilNormalization->new($log2, $debug);
 	#root::print_hashEntries ( $evaluationArrays, 2, "the \$evaluationArrays\n" );
 	$obj->quantilNormalize( @$evaluationArrays );
 	$obj = undef;
 }
 
 createPictures( $outpath, $normalize, \@namesArray, @$evaluationArrays ) if ($createGraph);
 
 if ( $createFractions ){
 	@matrix = ();
 	 calculateFraction( \@matrix, \@namesArray, @$evaluationArrays );
 	open (OUT, ">$outpath/fractions.csv") or die "could not create $outpath/fractions.csv\n$!\n";
 	foreach ( @matrix ){
 		print OUT join("\t",@$_);
 	}
 	close OUT;
 	print "frations were written to '$outpath/fractions.csv'\n";
 }
 
 sub calculateFraction{
 	my ( $resultsArray, $namesArray, $array1, @arrays2compare ) = @_;
 	my ( $temp, $value, $compareArray, $columnTitle );
 	$columnTitle = shift(@$namesArray );
 	
 	for (my $i = 0; $i < @arrays2compare; $i++ ) {
 		$compareArray = $arrays2compare[$i];
 		@$resultsArray[0] = [] unless ( defined @$resultsArray[0] );
 		$temp = @$resultsArray[0];
 		push ( @$temp, "$columnTitle vs. @$namesArray[$i]");
 		for ( my $i = 0; $i < @$compareArray; $i++ ) {
 			@$resultsArray[$i+1] = [] unless ( defined @$resultsArray[$i]);
 			$temp = @$resultsArray[$i];
 			$value = "na";
 			$value = @$array1[$i] / @$compareArray[$i] unless ( @$compareArray[$i] == 0);
 			push ( @$temp, $value );
 		}
 	}
 	return calculateFraction($resultsArray,@arrays2compare)if ( @arrays2compare > 1 );
 	return $resultsArray;
 }
 
 sub transposeMatrix {
 	my ( $matrix, $log2, $log2_apply ) = @_;
 	my ( @newMatrix, $oldLine );
 	## if log2 and log2_apply everything is ok
 	## as is if neither is set
 	## but if log2 is set, but not log2_apply, we have to revert the log2 from every data point!
 	## likwise if log2 is not set, but log2_apply we have to calculate the log2 for every dataset!
 
 	if ($log2) {
 		if ($log2_apply) {
 			## phu - all is ok!
 			for (
 				my $new_column_count = 0 ;
 				$new_column_count < @$matrix ;
 				$new_column_count++
 			  )
 			{
 				$oldLine = @$matrix[$new_column_count];
 				for (
 					my $new_row_count = 0 ;
 					$new_row_count < @$oldLine ;
 					$new_row_count++
 				  )
 				{
 					unless ( defined $newMatrix[$new_row_count] ) {
 						my @temp = ();
 						$newMatrix[$new_row_count] = \@temp;
 					}
 					$newMatrix[$new_row_count]->[$new_column_count] =
 					  @$oldLine[$new_row_count];
 				}
 			}
 		}
 		else {
 			## we have to revert the log2!
 			for (
 				my $new_column_count = 0 ;
 				$new_column_count < @$matrix ;
 				$new_column_count++
 			  )
 			{
 				$oldLine = @$matrix[$new_column_count];
 				for (
 					my $new_row_count = 0 ;
 					$new_row_count < @$oldLine ;
 					$new_row_count++
 				  )
 				{
 					unless ( defined $newMatrix[$new_row_count] ) {
 						my @temp = ();
 						$newMatrix[$new_row_count] = \@temp;
 					}
 					$newMatrix[$new_row_count]->[$new_column_count] =
 					  2**@$oldLine[$new_row_count];
 				}
 			}
 		}
 	}
 	elsif($log2_apply){
 			for (
 				my $new_column_count = 0 ;
 				$new_column_count < @$matrix ;
 				$new_column_count++
 			  )
 			{
 				$oldLine = @$matrix[$new_column_count];
 				for (
 					my $new_row_count = 0 ;
 					$new_row_count < @$oldLine ;
 					$new_row_count++
 				  )
 				{
 					unless ( defined $newMatrix[$new_row_count] ) {
 						my @temp = ();
 						$newMatrix[$new_row_count] = \@temp;
 					}
 					die "we cant apply the log2 to value @$oldLine[$new_row_count] (line $new_column_count and row $new_row_count)\n"
 						if (@$oldLine[$new_row_count] <= 0 );
 					$newMatrix[$new_row_count]->[$new_column_count] =
 					  log2(@$oldLine[$new_row_count]);
 				}
 			}
 	}
 	else{
 		## nothing is set!
 		for (
 				my $new_column_count = 0 ;
 				$new_column_count < @$matrix ;
 				$new_column_count++
 			  )
 			{
 				$oldLine = @$matrix[$new_column_count];
 				for (
 					my $new_row_count = 0 ;
 					$new_row_count < @$oldLine ;
 					$new_row_count++
 				  )
 				{
 					unless ( defined $newMatrix[$new_row_count] ) {
 						my @temp = ();
 						$newMatrix[$new_row_count] = \@temp;
 					}
 					$newMatrix[$new_row_count]->[$new_column_count] =
 					  @$oldLine[$new_row_count];
 				}
 			}
 	}
 	foreach ( @$matrix ) {
 		@$_ = undef;
 	}
 	@$matrix = undef;
 	return \@newMatrix;
 }
 
 sub getHeaderString {
 	my ( $string, $first, @rest ) = @_;
 	foreach my $otherName (@rest) {
 		$string .= "$first vs. $otherName\t";
 	}
 	return getHeaderString( $string, @rest ) if ( @rest > 1 );
 	return $string;
 }
 
 sub concatenate{
 	my ( $string, $array) = @_;
 	if ( $string =~ m!/! ){
 		my @temp = split ( "/",$string);
 		$string = $temp[@temp-1];
 	}
 	foreach ( @$array ){
 		$_ = $string."#".$_;
 	}
 	return 1;
 }
 
 sub createPictures {
 	my ( $outpath, $normalize, $namesArray, $array1, @arrays2compare ) = @_;
 	my ( $temp, $value, $compareArray, $name, $outfile, $norm_str );
 	for ( my $i = 0 ; $i < @arrays2compare ; $i++ ) {
 		die "we do not have the array values DensityPlot.pl createPictures ($i) \n" 
 			unless (ref($arrays2compare[$i]) eq "ARRAY" );
 		
 		$compareArray = $arrays2compare[$i];
 		my $xyWith_Histo = densityMap->new();
 		$xyWith_Histo->AddData( [ $array1, $compareArray ] );
 
 		$outfile =  "$outpath/directArrayComparison-@$namesArray[0]_@$namesArray[1+$i].svg" unless ( $normalize);
 		$outfile =  "$outpath/directArrayComparison-@$namesArray[0]_@$namesArray[1+$i]_normalized.svg" if ( $normalize );
  
  		$norm_str = "";
  		$norm_str = "normalized" if ( $normalize );
 		$xyWith_Histo->plot(
 			$outfile,
 			800, 800, @$namesArray[0], @$namesArray[ 1 + $i ], ["@$namesArray[0] vs."," @$namesArray[1+$i]",$norm_str]
 		);
 	}
 	$name = shift(@$namesArray);
 	createPictures( $outpath,$normalize, $namesArray, @arrays2compare )
 	  if ( @arrays2compare > 1 );
 	unshift ( @arrays2compare, $array1);
 	unshift ( @$namesArray, $name);
 	return;
 }
 sub log2 {
 	my ($value) = @_;
 	return log($value) / log(2);
 }