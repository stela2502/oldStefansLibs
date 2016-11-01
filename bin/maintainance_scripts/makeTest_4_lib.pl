#! /usr/bin/perl

use strict;
use warnings;

my ( $path, $testPath ) = @ARGV;

die "we need a libPath ($path) and a test path ($testPath) \n" unless ( -d $path && -d $testPath);

&parseFolder($path);


sub parseFolder{
  my ( $path ) = @_;
  my ( @entries, @path );
  opendir ( PATH ,$path ) or die "$path is no path\n$!\n";
  print "we analyze $path\n";
  @entries = readdir ( PATH );
  foreach ( @entries ){
    next if ( $path =~ m/\.$/);
    if ( -d "$path/$_" ){
        push ( @path , "$path/$_" );
	next;
    }
    &createTestFile ( "$path/$_" );
  }
  closedir ( PATH );
  foreach ( @path ){
    &parseFolder($_);
  }
}



sub createTestFile{
  my ( $file ) = @_;
  return 0 unless ( $file =~ m/\.pm$/ );
  my ( $testFile, @file, $temp, $include );
  open ( INFILE , "<$file" ) or die "could not open file $file\n";
  print "opened file $file\n";
  @file = split ( "/", $file );
  $temp = pop (@file );
  $include = join ("::",@file );

  $testFile = $1 if ( $temp =~ m/(.*)\.pm/);
  $include .= "::".$testFile;
  if ( -f "$testPath/$testFile.t" ){
	print "test file is already present ($testPath/$testFile.t)\n";
	return 1;
  }
  open ( Test , ">$testPath/$testFile.t" ) or die "could not open testFile $testFile\n";

  ## we have to create a stup for each sub in the INFILE!
  print Test 
"#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { use_ok '$include' }\n";

  while ( <INFILE> ) {
     print "a line of the infile $_\n";
     if ( $_ =~ m/sub *(\w+) *{/ ){
        print "match!\n";
	print Test "## test for $1\n\n";
      }
  }
  close ( Test );
  print "created testfile $testPath/$testFile.t\n";
  close ( INFILE ); 	
}

