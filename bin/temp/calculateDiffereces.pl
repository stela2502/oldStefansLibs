#! /usr/bin/perl

use strict;

warn "we evaluate the files @ARGV\n";
my ( @gffObjects,@line );

foreach  my $filename ( @ARGV ){
	my @gff;
	open ( IN , "<$filename" ) or die "could not open file $filename\n";
	while ( <IN> ) {
		@line = split ( "\t",$_);
		next unless ( defined $line[5]);
		push ( @gff, 2**$line[5] );

	}
	close ( IN );
	#print "dataRead $filename\t";
	push (@gffObjects, \@gff);
}

my $line = getHeaderString( "", @ARGV )."\n";
chop $line;
print "$line\n";

my $resultsArray = calculateFraction( [], @gffObjects );

foreach my $array ( @$resultsArray) {
	print join("\t",@$array),"\n";
} 

sub getHeaderString{
	my ( $string, $first, @rest ) = @_;
	foreach my $otherName ( @rest ) {
		$string .= "$first vs. $otherName\t";
	}
	return getHeaderString($string, @rest ) if ( @rest > 1);
	return $string;	
}
sub calculateFraction{
	my ( $resultsArray, $array1, @arrays2compare ) = @_;
	my ( $temp, $value );
	foreach my $compareArray ( @arrays2compare ) {
		for ( my $i = 0; $i < @$compareArray; $i++ ) {
			@$resultsArray[$i] = [] unless ( defined @$resultsArray[$i]);
			$temp = @$resultsArray[$i];
			$value = "na";
			$value = @$array1[$i] / @$compareArray[$i] unless ( @$compareArray[$i] == 0);
			push ( @$temp, $value );
		}
	}
	return calculateFraction($resultsArray,@arrays2compare)if ( @arrays2compare > 1 );
	return $resultsArray;
}
