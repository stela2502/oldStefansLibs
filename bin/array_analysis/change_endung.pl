#! /usr/bin/perl

use strict;
use warnings;

my $endung = shift (@ARGV);

unless ( defined $endung ){
	die "you should use this prog like that:\nchange_endung <new_endung> <list of files to change>\n";
}

foreach my $file ( @ARGV){
	system ( "mv $file  $file.$endung" );
	print "mv $file  $file.$endung\n";
}
