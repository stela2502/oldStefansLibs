#! /usr/bin/perl

use strict; use warnings;

if ( scalar ( @ARGV ) == 0 ){
	die "Sorry, but I expect a list of paths to process!\n";
}

foreach my $path ( @ARGV ){
	unless ( -d $path ){
		warn "Oh - '$path' is not a path!\n";
		next;
	}
	if ( -f "$path/Makefile" ){
		print "make -C $path\n";
		system ( "make -C $path " );
	}
	else { warn "no Makefile in the path $path\n";}
}
 
