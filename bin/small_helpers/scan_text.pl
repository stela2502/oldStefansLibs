#! /usr/bin/perl -w

#  Copyright (C) 2011-11-18 Stefan Lang

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

=head1 scan_text.pl

A small script to scan a text and convert it into a png file.

To get further help use 'scan_text.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

#use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $device, @outfile, @options );

Getopt::Long::GetOptions(
    "-device=s"     => \$device,
    "-outfile=s{,}" => \@outfile,
    "-options=s{,}" => \@options,
    "-help"         => \$help,
    "-debug"        => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $device ) {

    $device = "genesys:libusb:002:002";
    #system('scanimage -L');
    #$error .= "please select one of this devices!\n";
}
unless ( defined $outfile[0] ) {
    $error .= "the cmd line switch -outfile is undefined!\n";
}

if ($help) {
    print helpString();
    exit;
}

if ( $error =~ m/\w/ ) {
    print helpString($error);
    exit;
}

sub helpString {
    my $errorMessage = shift;
    $errorMessage = ' ' unless ( defined $errorMessage );
    return "
 $errorMessage
 command line switches for scan_text.pl

   -device       :the device used for scanning - see output on top
   -outfile      :the outfile
   -options      :some usable options as
                  'jpg' create jpg instead of png oputput
		          'resolution 500' change from 300 dpi to 500 dpi scanning
		          'no_deskew' do not rotate using unpaper
                  'no_mask_scan' do not re-center the picture
                  'djvu' create a djvu document instead of a figure

   -help           :print this help
   -debug          :verbose output
   

";
}

#my ( $task_description);
#
#$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/scan_text.pl';
#$task_description .= " -device $device" if (defined $device);
#$task_description .= " -outfile $outfile" if (defined $outfile);

## Do whatever you want!

my ( @temp, $path, $file, $file_pnm, $file_png, @files, $scanned_file );
@temp = undef;
my $hash = {};
my $temp = '';
foreach (@options) {
    $hash->{$_} = 1;
}
if ( defined $hash->{'resolution'} ) {
    my $use = 0;
    foreach (@options) {
        if ($use) {
            $hash->{'resolution'} = $_;
            last;
        }
        $use = 1 if ( $_ eq "resolution" );
    }
}
else {
    $hash->{'resolution'} = 300;
}

$file_pnm = $file_png = '';
$temp = 'png';
$temp = 'jpg' if ( $hash->{'jpg'} );
my $i = 0;
foreach (@outfile) {
	$i ++;
    @temp = split( "/", $_ );
    $file = pop(@temp);
    unless ( defined $path ) {
        $path = join( "/", @temp );
        $path = '.' unless ( $path =~ m/\w/ );
	$scanned_file = "$path/$file.pnm";
	$scanned_file =~s/%//;
	$file_pnm .= " $path/r_$file\\\%.pnm";
    }
    push ( @files ,"$file");
    $file_png .= " $path/$file"."0x$i.$temp";
}
$temp = '';
$temp = '--no-deskew' if ( $hash->{'no_deskew'} );
$temp .= " --no-mask-scan" if ( $hash->{'no_mask_scan'} );

foreach ( keys %$hash ) {
    $temp .= " --$1" if ( $_ =~ m/^\s*DS(.+)/ );
}

print
"scanimage -d '$device' --resolution $hash->{'resolution'}  --mode Lineart  > $path/$file.pnm\n\n";
system(
"scanimage -d '$device' --resolution $hash->{'resolution'}  --mode Lineart  > $path/$file.pnm "
);

unless ( -f "$path/$file.pnm" ){
	system('scanimage -L');
	die "Sorry I could not create the scan - probably you need to select the right device?\n";
}

push( @temp, "$path/$file.pnm" );
my $files_string;

print "unpaper $temp --overwrite $path/$file.pnm $file_pnm \n";
system("unpaper $temp --overwrite $path/$file.pnm $file_pnm ");
push( @temp, split( " ", $file_pnm ) );
$temp = 'png';
$temp = 'jpg' if ( $hash->{'jpg'} );
$temp = 'pdm' if ( $hash->{'djvu'} );
opendir ( DIR, "$path" ) ;
my @_files = readdir ( DIR );
closedir ( DIR );
my $outfiles = '';
foreach ( @_files ){
	if ( $_ =~m/^r_(.+)\.pnm/ ){
		system("convert $path/$_ $path/$1.$temp");
		unlink ( "$path/$_" );
		$outfiles .= " $path/$1.$temp";
	}
	elsif ( $_ =~m/^r_(.+)nm/ ){
		system ( "mv $path/$_ $path/r_$1.pnm");
		system("convert $path/r_$1.pnm $path/$1.$temp");
		unlink (  "$path/$_" );
		unlink ( "$path/r_$1.pnm");
		$outfiles .= " $path/$1.$temp";
	}
}

if ( $hash->{'djvu'} ) {
	## OH - did you want to create a djvu file - eh?
	my $outf_2 = '';
	foreach ( split (" ", $outfiles )) {
		$temp = $_;
		$temp =~s/pdm$/djvu/;
		system ("cjb2 -dpi $hash->{'resolution'} $_ $temp " );
		unlink ( $_ );
		$outf_2 .= " $temp";
	}
	$outfiles = $outf_2;
}
		

foreach ( @temp ) {
	unlink ( $_ ) unless ( $debug);
}
print "scanned document to $outfiles\n";
if ( $hash->{'djvu'} ) {
	print "You now should execute\ndjvm -c <YOUR OUTFIILE> $outfiles\nor save that info untill you have all files.\n";
}
