#! /usr/bin/perl

use stefans_libs::gbFile;

my $gbFile = $ARGV[0];

open (IN , "<$gbFile") or die "could not open file $gbFile\n";

my @array = <IN>;

close ( IN );
#$gbFile  = gbFile->new($gbFile);
$gbFile = gbFile->new(\@array);

root::print_hashEntries($gbFile, 2, "entries in the gbFile $gbFile:");


