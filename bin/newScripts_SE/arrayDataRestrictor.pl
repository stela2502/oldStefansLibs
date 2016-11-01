#! /usr/bin/perl

use strict;
use Getopt::Long;


my ( $tableFile, $namesFile, $outFile, $searchColumnTitles, $notEmpty_columnTitles, 
     $notMatch, $help );

Getopt::Long::GetOptions(
	"tableFile=s" => \$tableFile,
	"tagFile=s" => \$namesFile,
	"outFile=s" => \$outFile,
	"searchColumnTitles=s" => \$searchColumnTitles,
	"not_empty_column_titles=s" => \$notEmpty_columnTitles,
	"notMatch=s" => \$notMatch,
	"help" => \$help
) or die &helpString();

die &helpString() if ( $help );
die &helpString() unless ( defined $tableFile && defined $outFile && defined $namesFile);

sub helpString{
	return
"command line options:
  -tableFile                :the file containing all data in tab seaparated text format
  -tagFile                   :the file containing the exact enties for the table lines to be selected
  -outFile                   :the file to stor the selected table lines in
  -searchColumnTitles        :a semicolon (;) separated list of column titles (first line entries) 
                              we look for the different tags (complete match!)
  -not_empty_column_titles   :a semicolon separated list of columns that must not be empty 
                              and must not contain the a match to RegExp ^-+\$
  -notMatch                  :opposite of the tagFile entry, this entry (1) must not be part of the match column
  -help                      :display this help message
";
}

open ( SEARCH , "<$namesFile" ) or die "could not open the search list '$ARGV[0]'\n";

open ( DATA , "<$tableFile" ) or die "could not open the data file '$ARGV[1]'\n";

open ( OUT , ">$outFile" ) or die "could not create the output file '$ARGV[2]'\n";

my ($searchHash, $controlHash );

while ( <SEARCH> ){
	chomp $_;
	$searchHash -> {"$_"} = 1 == 1;
	#print "search entry = '$_'\n";
}
close (SEARCH);

my @temp = (keys %$searchHash);
$controlHash = @temp;

print "We are searching for $controlHash diferent genes\n";

my ($match, $searchString,$dictionary);

$controlHash = -1;
my (@columnNumbers, @line, @found, $use, @notEmptyRows);
while (<DATA>){
	$match = 1 == 0;
	if ( $controlHash == -1 ){ ##first line!
		chomp $_;
		@columnNumbers = &select_multiple_ColumnNumbers_by_PatternMatch(
			$searchColumnTitles, $_);
		@notEmptyRows = &select_multiple_ColumnNumbers_by_PatternMatch( $notEmpty_columnTitles, $_);
		
		print "We check the columns (",join ( ', ', @columnNumbers),") for the match\n",
		"and the columns (",join (",", @notEmptyRows),") if they are empty\n";
		$controlHash = 0;
		print OUT $_,"\n";
		next;
	}

	chomp $_;
	@line = split ( "\t", $_);
	$use = 1 == 0;
	
	for ( my $i = 0; $i < @columnNumbers; $i ++){
		$line[$columnNumbers[$i]] = $1 if ($line[$columnNumbers[$i]] =~ m/ *(.+) +/);
		#print "line $i does the entry $line[$columnNumbers[$i]] match to anything (",join (';',(keys %$searchHash) ),")?\n";
		if ( $searchHash -> {$line[$columnNumbers[$i]]} && !($line[$columnNumbers[$i]] =~ m/$notMatch/ ) ){
			$use = 1 == 1 ;
			push (@found, $line[$columnNumbers[$i]] );
		}
	}
	#print "Yes after the first! \n" if ( $use );
	#print "match the rows ",join(",",@notEmptyRows),"\n" if ( $use);
	
	for ( my $i = 0; $i < @notEmptyRows; $i ++){
		 if ( $line[$notEmptyRows[$i]] =~ m/^-*$/ ){
		 	$use = 0 == 1;
		 	#print "we match to $line[$notEmptyRows[$i]] !!\n";
		 }
		
	}
	#print "No after the pattern match!\n" unless ( $use );
	if ( $use ){
		print OUT $_,"\n";
	}
	else {
		print "not selected $line[0], $line[1]\n";
	}
}

print "Selected genes: ",join("\t", @found);

close (OUT);
close (SEARCH);
close (DATA);
print "selected list is printed to $ARGV[2] ($controlHash entries)\n";
	


sub select_multiple_ColumnNumbers_by_PatternMatch {
    my ( $title, $line ) = @_;
    chomp $line;
    my ( @lineArray, $linesOfInterest, @titles, @return );
    @lineArray = split( "\t", $line );
    @titles = split ( ";", $title);
    
    for ( my $i = 0 ; $i < @lineArray ; $i++ ) {
        for ( my $a = 0 ; $a < @titles; $a++ ){
        	 if ( $lineArray[$i] =~ m/$titles[$a]/ ){
        	 	$linesOfInterest->{$i} = 1;
        	 	last;
        	 }
        }
    }
    @return = ( keys %$linesOfInterest);
    die "we could not determin the column number for string '$title'\n"
      unless ( defined $return[0] );

    #    print "We are evaluating lines \n@linesOfInterest\n";
    return @return;
}

sub select_multiple_ColumnNumbers_by_exactMatch {
    my ( $title, $line ) = @_;
    chomp $line;
    my ( @lineArray, @linesOfInterest, @titles );
    @lineArray = split( "\t", $line );
    @titles = split ( ";", $title);
    
    for ( my $i = 0 ; $i < @lineArray ; $i++ ) {

        #        print "we are checking column title $lineArray[$i]\n";
        for ( my $a = 0 ; $a < @titles; $a++ ){
        	 if ( $lineArray[$i] eq $titles[$a] ){
        	 	push( @linesOfInterest, $i );
        	 	last;
        	 }
        }
    }
    die "we could not determin the column number for string '$title'\n"
      unless ( defined $linesOfInterest[0] );

    #    print "We are evaluating lines \n@linesOfInterest\n";
    return @linesOfInterest;
}
	
