#! /usr/bin/perl
 
 use strict;
 use Getopt::Long;
 use stefans_libs::tableHandling;
 use stefans_libs::array_analysis::outputFormater::HTML_helper;
 
 ## we need to get the Gene info for all elements analyzed.
 ## at the best, we should use these things as Hash keys to arrays.
 ## For each Gene, the correlating values have to be reported.
 ## report all genes, that show up in at least two analysies.
 ## woiuld be quite optimal!
 ## should not be much work either.
 ## tomorow - have to go to the swedish course.
 
 my ( @infiles, $outfile, $pattern, $help, $debug );
 
 Getopt::Long::GetOptions(
 	"-statOutputs=s{,}" => \@infiles,
 	"-outfile=s"        => \$outfile,
 	"-colNames=s"       => \$pattern,
 	"-help"             => \$help,
 	"-debug"            => \$debug
 ) or die &helpString();
 
 die &helpString()
   unless ( defined $infiles[0] && defined $outfile );
 
 die &helpString() if ($help);
 
 print "we got the files @infiles\n";
 
 sub helpString {
 	return "
 command line switches for pca_calculation:
 
   -statOutputs    :the files containing the statistical ouput table (tab separated)
                    accepts wildcards like *.csv
   -outfile        :the name of the outfile (<tab> separated table)
   -colNames       :the column names that contain the gene markers ( semicolon separated list )
   -help           :print this help
   -debug		  :do not evaluate the array data, just take the saved temp files
 "
 }
 
 my (
 	$resultsHash, $line,      $infoTagsColnNrs, $table,
 	@info,        $dataArray, $htmlHelper,      $infoHash,
 	$temp,        @temp,      $p_value_Col_nr,  @logInfo,
 	$i, $short_summary_HTML
 );
 $table      = tableHandling->new();
 $htmlHelper = HTML_helper->new();
 
 $pattern = "Probe Set ID;Gene Symbol;mRna - Description"
   unless ( defined $pattern );
 ## the key to the result hash will be a summary of keys that do not match $pattern in the first line!
 
 foreach my $infile (@infiles) {
 	print "start foreach infile\n";
 	if ( $infile =~ m/log$/){
 		print "We got a log file!! ( $infile ) \n";
 		next;
 	}
 	open( IN, "<$infile" )
 	  or die "could not open $infile in compareStatisticalResults:\n $!\n";
 
 	@info = split( "/", $infile );
 	$infile = pop(@info);
 
 	$line = 0;
 	while (<IN>) {
 		$line++;
 		chomp $_;
 		if ( $line == 1 ) {
 			$infoTagsColnNrs =
 			  $table->identify_columns_of_interest_bySearchHash(
 				$_,
 				$table->createSearchHash(
 					$table->_split_searchString($pattern)
 				)
 			  );
 			print
 "\$infoTagsColnNrs arra ref contains the column numbers ( @$infoTagsColnNrs )\n";
 			@info =
 			  $table->get_column_entries_4_columns( $_, $infoTagsColnNrs );
 
 			$p_value_Col_nr =
 			  $table->identify_columns_of_interest_bySearchHash( $_,
 				{ "p value" => 1 == 1 } );
 			if ( -f "$infile.log" ) {
 				print "we got a log file!\n";
 				open( LOG, "<$infile.log" )
 				  or die "could not open logfile $infile.log\n:$!\n";
 				my $hash;
 				$i = 0;
 				while (<LOG>) {
 					chomp $_;
 					$i++;
 					( $temp, $hash->{testType} ) = split( "\t", $_ )
 					  if ( $i == 1 );
 					( $temp, $hash->{amout_of_tests} ) = split( "\t", $_ )
 					  if ( $i == 2 );
 					( $temp, $hash->{amount_of_significant} ) =
 					  split( "\t", $_ )
 					  if ( $i == 3 );
 					push( @logInfo, $hash );
 				}
 
 			}
 
 #die "we search for the P_value columnname $temp and found it in column @$p_value_Col_nr\n";
 			die "we got no information columns -> we cant group the results!\n"
 			  unless ( defined @$infoTagsColnNrs[0] );
 			next;
 		}
 		@info = $table->get_column_entries_4_columns( $_, $infoTagsColnNrs );
 		@temp = $table->get_column_entries_4_columns( $_, $p_value_Col_nr );
 		next if ( "@info" =~ m/^[- ]*$/ );
 		next unless ( $temp[0] > 0 && $temp[0] < 1 );
 
 		$resultsHash->{"@info"}->{$infile} = $temp[0];
 
 		unless ( defined $resultsHash->{"@info"} ) {
 			my $temp = { n => 0 };
 			$resultsHash->{"@info"} = $temp;
 		}
 		$resultsHash->{"@info"}->{n}++;
 
 #print "The p_value for @info in file $infile is $resultsHash->{@info}->{$infile}\n";
 #die if ( $resultsHash->{"@info"}->{$infile} > 0 && $resultsHash->{"@info"}->{$infile} < 0.05);
 	}
 	close(IN);
 }
 
 ## now we have to create usefull groupings!
 
 my @matrixes;
 my @resultArray;
 my $linkHash;
 my $infile;
 
 while ( my ( $key, $result ) = each %$resultsHash ) {
 	$linkHash = $table->returnBioLinks($key);
 	my @temp = ( $key, $result->{n} );
 	foreach (qw( genCard NCBI_mapview ENSMBL google )) {
 		$linkHash->{$_} = " -- " unless ( defined $linkHash->{$_} );
 		push( @temp, $linkHash->{$_} );
 	}
 	foreach (@infiles) {
 
 		#print "we got a P_value of $result->{$_} -> ";
 		$result->{$_} = "NA" unless ( defined $result->{$_} );
 
 		#print " $result->{$_}\n";
 		push( @temp, $result->{$_} );
 	}
 	push( @resultArray, \@temp );
 }
 
 @resultArray = (
 	sort {
 
 		# my ( $a_p, $b_p );
 		# foreach ( @$a[ 5 .. @$a - 1 ] ) { $a_p = $_ unless ( $_ eq "NA" ) }
 		# foreach ( @$b[ 5 .. @$b - 1 ] ) { $b_p = $_ unless ( $_ eq "NA" ) }
 		( @$b[1] <=> @$a[1] ) 
 		#<=> ( $a_p <=> $b_p )
 
 		  # <=> ( @$a[2] cmp @$b[2] ) )
 	  } @resultArray
 );
 
 my @tableHeader = (
 	"gene info",
 	"amount of significant tests",
 	"link to GeneCards",
 	"link to NCBI Mapview",
 	"link to ENSMBL",
 	"link to google", @infiles
 );
 
 open( OUT, ">$outfile.csv" )
   or die "could not create outfile '$outfile.csv'\n$!\n;";
  print OUT join("\t", @tableHeader),"\n";
 foreach my $line ( @resultArray ){
 	print OUT join("\t", @$line),"\n";
 }
 close OUT;
 print "over all comparison data written to $outfile.csv\n";
 
 for ( my $i = 0 ; $i < @infiles ; $i++ ) {
 	my @matrix;
 	push( @matrixes, \@matrix );
 	push( @matrix,   \@tableHeader );
 	push( @matrix,   $resultArray[0] );
 	for ( my $a = 1 ; $a < @resultArray ; $a++ ) {
 		push( @matrix, $resultArray[$a] )
 		  unless ( $resultArray[$a][ 6 + $i ] eq "NA" );
 	}
 }
 
 
 $short_summary_HTML = 
 "<h1>Overview</h1>
 <p>The results from several expression arrays were compared to several phenotypic data sets 
 using either a Spearman Linear correlation, a Wilcoxon Rank Sum Test or a Kruskal Wallis test (anova).<br>
 Each gene where the statistical test reports a p \< 0.05 is included in this summary. 
 To estimate the reliability of the statistical tests, the results from all tests are compared gene by gene.
 For each gene the amount of tests passed and the p value from the passed tests is reported.
 In this first pase of the evaluation program, only links to external information is given for each gene.<br>
 To get to comparison, click on the links in the following overview table:<br><br>
 ";
 
 open( OUT, ">$outfile.html" )
   or die "could not create outfile '$outfile'\n$!\n;";
 my $relPos_topLevel;
 @temp = split( "/", "$outfile.html" );
 $relPos_topLevel = "../$temp[@temp-1]";
 print OUT $htmlHelper->getHeader("compareStatistics");
 print OUT $short_summary_HTML;
 
 print OUT "<table border=\"3\" frame=\"box\">\n";
 print OUT $htmlHelper->getAnHTML_tableLine4array(
 	"stat test overview",
 	"test type",
 	"amount of tests",
 	"passed tests \[%\]",
 	"passed tests [n]"
 );
 
 my (@sortModel);
 
 for ( my $i = 0 ; $i < @infiles ; $i++ ) {
 	$infile = $infiles[$i];
 	@temp = split("-",$infile);
 	print "$infile\n";
 	$infile = $temp[0];
 	@sortModel = (
 		{ position => 1, type => 'antiNumeric'},
 		{ position => 6 + $i , type => 'numeric' }
 	);
 	if ( defined $logInfo[$i] ) {
 		print "we sort for $infile p_value at position  6 + $i\n";
 		print OUT $htmlHelper->getAnHTML_tableLine4array(
 			$htmlHelper->getLink(
 				$htmlHelper->printA_htmlTableFile4matrix(
 					"$infile.cmp", $matrixes[$i],
 					$outfile, $relPos_topLevel, \@sortModel
 				),
 				"$infile"
 			),
 			$logInfo[$i]->{testType},
 			$logInfo[$i]->{amout_of_tests},
 			sprintf( "%.3f", ($logInfo[$i]->{amount_of_significant} /
 			  $logInfo[$i]->{amout_of_tests}) *100 ),
 			$logInfo[$i]->{amount_of_significant}
 		);
 	}
 	else {
 		print OUT $htmlHelper->getAnHTML_tableLine4array(
 			$htmlHelper->getLink(
 				$htmlHelper->printA_htmlTableFile4matrix(
 					"$infile.cmp", $matrixes[$i],
 					$outfile,      $relPos_topLevel, \@sortModel
 				),
 				"$infile"
 			),
 			" - ", " - ", " - ", " - "
 		);
 	}
 
 }
 
 print OUT "</table>\n";
 
 print OUT "</body>\n";
 
 close OUT;
 
