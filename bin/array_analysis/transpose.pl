#! /usr/bin/perl

use strict;

## Transpose the file we are getting. 
## It is expected to be a tab separated table!!

warn "we need two filenames - the infile and the outfile.\n",
"the infile contains a tab separated table document and that ",
" will be transposed and wiritten to the outfile (also tab separated)\n",
"therefore you have to give me the two filenames(!) - you gave me @ARGV\n"
if ( @ARGV <2);

open ( IN , "<$ARGV[0]") or die "could not open $ARGV[0]\n";

open (OUT , ">$ARGV[1]") or die "could not create $ARGV[1]\n";

my (@rowArray,  $rowCount, $columnCount);

$rowCount = $columnCount = 0;

while ( <IN>) {
	chomp $_;
	my @line = split ( "\t", $_ );
	$columnCount = scalar(@line) unless ( defined $columnCount && $columnCount > 0);
	$rowArray[$rowCount++] = \@line;
}

close (IN);

my ( @new );

print "we have $columnCount columns in the original file\n";

foreach my $lineArray ( @rowArray ){
	for (my $i = 0; $i < $columnCount; $i++){
		@$lineArray[$i] = "-" unless ( defined @$lineArray[$i]);
	}
	for ( my $i = 0; $i < @$lineArray; $i++){
		$new[$i] = "$new[$i]@$lineArray[$i]\t";
	}
}
foreach my $line ( @new) {
	chop $line;
	$line = "$line";
	print OUT "$line\n";
}

close (OUT);

print "transposed table written to $ARGV[1]\n";
