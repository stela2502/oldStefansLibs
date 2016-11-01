#! /usr/bin/perl

use strict;
use Getopt::Long;
use stefans_libs::tableHandling;

#use stefans_libs::array_analysis::Rbridge;

my (
	$tableFile,          $namesFile,             $outFile,
	$searchColumnTitles, $notEmpty_columnTitles, $notMatch,
	$help,               $headingLine,           $select_without_check,
	$sepString,          @tags,                  $patternMatch
);

Getopt::Long::GetOptions(
	"tableFile=s"               => \$tableFile,
	"-patternMatch"             => \$patternMatch,
	"tagFile=s"                 => \$namesFile,
	"tagStrings=s{,}"           => \@tags,
	"outFile=s"                 => \$outFile,
	"searchColumnTitles=s"      => \$searchColumnTitles,
	"not_empty_column_titles=s" => \$notEmpty_columnTitles,
	"notMatch=s"                => \$notMatch,
	"headingLine=s"             => \$headingLine,
	"select_without_check=s"    => \$select_without_check,
	"separatingString=s"        => \$sepString,
	"help"                      => \$help
) or die &helpString();

die &helpString() if ($help);
die &helpString(
"we miss one of the options:\ntableFile=$tableFile\ntagFile=$namesFile (OR)\n tagStrings=$tags[0]...\noutFile=$outFile"
  )
  unless ( ( defined $namesFile || defined $tags[0] )
	&& defined $outFile
	&& defined $tableFile );

sub helpString {
	my $warning_str = shift;
	return "$warning_str\ncommand line options:
 	
   -tableFile                 :the file containing all data in tab seaparated text format
   -tagFile                   :the file containing the exact enties for the table lines to be selected
   -tagStrings                :a list of tags you want to get from the table file
   -separatingString          :the separating sting in the table file (default = \\t)
   -outFile                   :the file to store the selected table lines in
   -searchColumnTitles        :a semicolon (;) separated list of column titles (first line entries) 
                               we look for the different tags (complete match!)
   -not_empty_column_titles   :a semicolon separated list of columns that must not be empty 
                               and must not contain the a match to RegExp ^-+\$
   -notMatch                  :opposite of the tagFile entry, this entries must not be part of the match column
   -headingLine               :the line, the column headings are stored in (default = 0)
   -select_without_check      :up to the mentioned line all lines will be included into the output without check
   -patternMatch              :do a pattern match instead of a test for equality
   -help                      :display this help message
 ";
}

my ( $searchColumns, @searchStrings, $notEmptyColumns, $tableHandling );

if ( -f $namesFile ) {
	open( SEARCH, "<$namesFile" )
	  or die "could not open the search list '$namesFile'\n";
	while (<SEARCH>) {
		chomp $_;
		push( @searchStrings, $_ );
	}

	close(SEARCH);
}

if ( defined $tags[0] ) {
	push( @searchStrings, @tags );
}

open( DATA, "<$tableFile" )
  or die "could not open the data file '$tableFile'\n";

open( OUT, ">$outFile" ) or die "could not create the output file '$outFile'\n";

open( LOG, ">$outFile.log" )
  or die "could not create the log file '$outFile.log'\n";

$tableHandling = tableHandling->new($sepString);

print LOG "We are searching for ", $#searchStrings + 1,
  " diferent genes (@searchStrings)\n";
print LOG "using infile\t$tableFile\n",
  "search patterns file\t$namesFile\n",
  "searchColumnTitles\t$searchColumnTitles\n",
  "not_empty_column_titles\t$notEmpty_columnTitles\n",
  "not part of the searchColumn entries\t$notMatch\n",
  "titles are in line\t$headingLine\n",
  "no check until line\t$select_without_check\n";

my ( $match, $searchHash, $lineCount, @notMatch, @temp, @searchArray );
@notMatch = $tableHandling->_split_searchString($notMatch)
  if ( defined $notMatch );
$searchHash = $tableHandling->createSearchHash(@searchStrings);

@searchArray = ( keys %$searchHash );

$lineCount = 0;
$headingLine = 1 unless ( defined $headingLine );
my ( @columnNumbers, @line, @found, $use, @notEmptyRows );
$match = 0;

while (<DATA>) {
	$lineCount++;
	if ( $lineCount == $headingLine ) {
		$searchColumns =
		  $tableHandling->identify_columns_of_interest_bySearchHash(
			$_,
			$tableHandling->createSearchHash(
				$tableHandling->_split_searchString($searchColumnTitles)
			)
		  );
		print "TEST we are ready with the first thging...\n";
		$notEmptyColumns =
		  $tableHandling->identify_columns_of_interest_bySearchHash(
			$_,
			$tableHandling->createSearchHash(
				$tableHandling->_split_searchString($notEmpty_columnTitles)
			)
		  ) if ( defined $notEmpty_columnTitles );
		die
"we did not find the column name(s) '$searchColumnTitles' in the following line\n$_"
		  unless ( defined @$searchColumns );

		print LOG "search columns numbers\t", join( "; ", @$searchColumns ),
		  "\n"
		  if ( defined @$searchColumns );
		print LOG "not empty columns numbers\t",
		  join( "; ", @$notEmptyColumns ), "\n"
		  if ( defined @$notEmptyColumns );
	}
	if ( $lineCount <= $select_without_check ) {
		print OUT $_;
		next;
	}
	#print "we match against @searchArray\n";
	if ($patternMatch) {
		if (
			$tableHandling->match_columns_of_interest_2_patternArray(
				$_, $searchColumns, @searchArray
			)
		  )
		{

			#print "We got a match!!\n";
			next
			  if (
				$tableHandling->match_columns_of_interest_2_patternArray(
					$_, $searchColumns, \@notMatch
				)
			  );

			#print "and It didn't match to $notMatch\n";
			next
			  if (
				$tableHandling->match_columns_of_interest_2_pattern(
					$_, $notEmptyColumns, '^-*$'
				)
			  );

			#print 'and it didnt match to the pattern ---',"\n";
			$match++;
			print OUT $_;
		}
		else {
			@temp =
			  $tableHandling->get_column_entries_4_columns( $_,
				$searchColumns );

			#print "Not matched: '", join("|",@temp),"'\n";
		}
	}
	else {

		if (
			$tableHandling->match_columns_of_interest_2_searchHash(
				$_, $searchColumns, $searchHash
			)
		  )
		{

			#print "We got a match!!\n";
			next
			  if (
				$tableHandling->match_columns_of_interest_2_patternArray(
					$_, $searchColumns, \@notMatch
				)
			  );

			#print "and It didn't match to $notMatch\n";
			next
			  if (
				$tableHandling->match_columns_of_interest_2_pattern(
					$_, $notEmptyColumns, '^-*$'
				)
			  );

			#print 'and it didnt match to the pattern ---',"\n";
			$match++;
			print OUT $_;
		}
		else {
			@temp =
			  $tableHandling->get_column_entries_4_columns( $_,
				$searchColumns );

			#print "Not matched: '", join("|",@temp),"'\n";
		}
	}
}

print "genes selected:\t$match\n";

print LOG "matched genes:\t$match\nall genes\t",
  $lineCount - $select_without_check, "\n";
close(OUT);
close(SEARCH);
close(DATA);
close(LOG);

print "selected list is printed to $outFile ($match entries)\n";
