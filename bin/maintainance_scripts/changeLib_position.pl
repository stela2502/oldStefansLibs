#! /usr/bin/perl

use strict;
use warnings;

unless ( @ARGV == 3 ){
	print 
"
usage of changeLibPosition.pl
changeLibPosition.pl <old lib string> <new lib string> <lib base path>

The lib strings have to be in perl notation. Take care, as the actual position of the lib file is not changed!

";
	exit;
}

my ( $oldLibString, $newLibString, $lib_base_Path ) = @ARGV;


&parseFolder($lib_base_Path);


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
    &mv_libEntry ( "$path/$_" );
  }
  closedir ( PATH );
  foreach ( @path ){
    &parseFolder($_);
  }
}


sub mv_libEntry{
  my ( $file ) = @_;
  my $return  = 1;
  $return = 0 if ($file =~ m/\.pm$/);
  $return = 0 if ($file =~ m/\.t$/);
  $return = 0 if ($file =~ m/\.pl$/);
  return 0 if ( $return );
  my ( $changed, @file );
  open ( INFILE , "<$file" ) or die "could not open file $file\n";
  print "opened file $file\n";

  $changed = 0;
  while ( <INFILE> ) {
  	if ( $_ =~ m/$oldLibString/ ){
  	    $_ =~  s/$oldLibString/$newLibString/ ;
  	    $changed = 1;
  	}
  	push ( @file , $_);
  }
  close ( INFILE );
  
  if ( $changed ){
  	open ( OUT , ">$file" ) or die "good joke - I cant wirte to $file\n$!\n";
  	print OUT join  ("",@file);
  	close (OUT);
  	print "$file changed!\n";
  }
  return 1;
   	
}
