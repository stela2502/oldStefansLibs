#! /usr/bin/perl
#
use strict;
use warnings;

my ($hash, $line,@line);
foreach my $infile ( @ARGV){
	unless ( -f $infile) { 
	warn " need a list of connection net datasets files at start up\n";
	next;
	}
	open  ( IN, "<$infile" ) or die "could not open infile $infile!\n$!\n";
	$hash = {};
	$line = 1;
	while ( <IN> ){
		if ( $line == 1 ){
			$line ++;
			next;
		}
		@line = split("\t", $_);
		@line = split("_", $line[0]);
		#print "we have a line: '".join("','",@line)."' with ".scalar(@line)." entries\n";
		$hash->{$line[scalar(@line)-1]} = 0 unless ( defined $hash->{$line[scalar(@line)-1]});
		$hash->{$line[scalar(@line)-1]} ++;
	}
	print "$infile\n".join("\n",keys %$hash)."\n".scalar(keys %$hash )." genes\n";
}
