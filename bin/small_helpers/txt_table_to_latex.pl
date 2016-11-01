#! /udsr/bin/perl

use strict;
my @line;
open ( IN , "<$ARGV[0]")  or die  "could not read from the file '$ARGV[0]'\n";
while ( <IN>) {
	chomp ( $_ );
	$_ =~ s/,/\./g;
	@line =  split( "\t", $_);
	for ( my $i = 0; $i <@line; $i ++){
		if ( $line[$i] =~ m/^ *\d[\d\.Ee\-\+]* *$/){
			$line[$i] =~ s/[Ee]-0*([1-9]+)/*10^\{\-$1\}/;
			$line[$i] = " \$ $line[$i] \$ ";
		}
	}
	print join( ' & ', @line)."\\\\\n";
}
close ( IN );
