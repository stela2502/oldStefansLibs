#! /usr/bin/perl

use strict;

my @a;
my $outfile;
foreach ( @ARGV){
	unless ( -f $_ ) {
		print "not a file :'$_'\n";
		next;
	}
	
	@a = split ( /\./, $_);
	pop ( @a );
	$outfile = join('.' ,@a);

	system ( "convert '$_' '$outfile.png'" );
}

