#! /usr/bin/perl

use strict;
use stefans_libs::plot::xy_graph_withHistograms;

warn "we evaluate the files @ARGV\n";
my ( @gffObjects,@line );

foreach  my $filename ( @ARGV ){
	my @gff;
	open ( IN , "<$filename" ) or die "could not open file $filename\n";
	while ( <IN> ) {
		@line = split ( "\t",$_);
		next unless ( defined $line[5]);
		#push ( @gff, 2**$line[5] );
		push ( @gff, $line[5] );
	}
	close ( IN );
	print "dataRead $filename\n";
	print join("; ",@gff),"\n";
	push (@gffObjects, \@gff);
}

my @namesArray = ( @ARGV);
my @temp;
for (my $i = 0; $i < @namesArray; $i++ ) {
	@temp = split( "/", $namesArray[$i]);
	$namesArray[$i] = $temp[@temp-1];
}

createPictures( \@namesArray, @gffObjects );

sub getHeaderString{
	my ( $string, $first, @rest ) = @_;
	foreach my $otherName ( @rest ) {
		$string .= "$first vs. $otherName\t";
	}
	return getHeaderString($string, @rest ) if ( @rest > 1);
	return $string;	
}

sub createPictures{
	my ( $namesArray, $array1, @arrays2compare ) = @_;
	my ( $temp, $value, $compareArray );
	for ( my $i = 0; $i < @arrays2compare; $i++ ) {
		$compareArray = $arrays2compare[$i];
		my $xyWith_Histo = xy_graph_withHistograms->new();
		$xyWith_Histo->plotData( [$array1, $compareArray], "@$namesArray[0]_@$namesArray[1+$i].png", 
			800 , 800 , @$namesArray[0] , @$namesArray[1+$i] );
	}
	shift ( @$namesArray);
	return createPictures($namesArray, @arrays2compare) if ( @arrays2compare > 1 );
}
