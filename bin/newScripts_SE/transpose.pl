#! /usr/bin/perl

use strict;

## Transpose the file we are getting. 
## It is expected to be a tab separated table!!

open ( IN , "<$ARGV[0]") or die "could not open $ARGV[0]\n";

open (OUT , ">$ARGV[1]") or die "could not create $ARGV[1]\n";

my (@rowArray,  $rowCount, $columnCount);

$rowCount = $columnCount = 0;

while ( <IN>) {
	chomp $_;
	my @line = split ( "\t", $_ );
	$columnCount = @line unless ( defined $columnCount);
	@rowArray[$rowCount++] = \@line;
}

close (IN);
my ( @new );

foreach my $lineArray ( @rowArray ){
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
