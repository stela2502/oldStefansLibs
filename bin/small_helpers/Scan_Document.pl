#! /usr/bin/perl -w

#  Copyright (C) 2011-11-18 Stefan Lang licence GPL (v3)
use Getopt::Long;
use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $device, $outfile);

Getopt::Long::GetOptions(
	 "-device=s"    => \$device,
	 "-outfile=s"    => \$outfile,
);

my $warn = '';
my $error = '';

unless ( defined $device) {
	$device = "genesys:libusb:002:002";
	$warn .= "I set the device to '$device'\nIf that does not work chack your scanning device name using\nscanimage -L\n"
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for scan_text.pl

   -device       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}

my ( @temp, $path, $file );
@temp = split( "/", $outfile );
$file = pop ( @temp );
$path = join ( "/", @temp );
$path = '.' unless  ( $path =~m/\w/);

@temp = undef;

system ( "scanimage -d '$device' --resolution 300  --mode Lineart  > $path/$file.pnm");
push ( @temp , "$path/$file.pnm");
system ( "unpaper $path/$file.pnm $path/r_$file.pnm ");
push ( @temp , "$path/r_$file.pnm");
system ( "convert $path/r_$file.pnm $path/$file.png");

foreach ( @temp ) {
	unlink ( $_ );
}


