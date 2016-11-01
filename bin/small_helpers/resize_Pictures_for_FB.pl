#! /usr/bin/perl -w

#  Copyright (C) 2012-02-26 Stefan Lang

#  This program is free software; you can redistribute it 
#  and/or modify it under the terms of the GNU General Public License 
#  as published by the Free Software Foundation; 
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful, 
#  but WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License 
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 resize_Pictures_for_FB.pl

This tool takes a list of figure files and resizes the pictures in order to fit into a online tool.

To get further help use 'resize_Pictures_for_FB.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $outpath, $max_pix);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,
	 "-outpath=s"    => \$outpath,
	 "-max_pixcels=s" => \$max_pix,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( -d $outpath) {
	$outpath = "./";
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
 command line switches for resize_Pictures_for_FB.pl

 This tool will convert all images from whichever format 
 into a png file with a default of 2000000 pixcels. 

   -infiles       :a list of image files
   -outpath       :optional use default './'
   -max_pix       :change the default pixel count

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/resize_Pictures_for_FB.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= " -outpath $outpath" if (defined $outpath);

$outpath .= "/" unless ( $outpath =~ m!/$! );
## Do whatever you want!
$max_pix = 2000000 unless ( defined $max_pix); 
my ( @temp, $filename );
foreach ( @infiles ) {
	@temp = split ( "/", $_ );
	@temp = split (/\./, $temp[@temp - 1]);
	pop ( @temp );
	$filename = join(".",@temp ). ".png";
	if ( $debug ) {
		print  "convert $_ -resize $max_pix@ $outpath$filename\n";
	}
	else {	
		system ( "convert $_ -resize $max_pix@ $outpath$filename" );
		print "Created file $outpath$filename\n";
	}
}
