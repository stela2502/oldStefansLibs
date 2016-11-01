#! /usr/bin/perl -w

#  Copyright (C) 2012-01-16 Stefan Lang

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

=head1 extract_file_from_tar_archives.pl

This script extracts one file from the tar archives and renames the file to the name of the tar archive.

To get further help use 'extract_file_from_tar_archives.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $FoI, $outpath);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,
	 "-FoI=s"    => \$FoI,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $FoI) {
	$error .= "the cmd line switch -FoI is undefined!\n";
	$warn .= "the cmd line switch -FoI is undefined!\nI will extract all files and put them into subfolders\n";
}
unless ( defined $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
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
 command line switches for extract_file_from_tar_archives.pl

   -infiles       :a list of batchStatistics_v2.pl result files
   -FoI           :the File of Interest you want to extract
   -outpath       :the outpath

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/extract_file_from_tar_archives.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= " -FoI $FoI" if (defined $FoI);
$task_description .= " -outpath $outpath" if (defined $outpath);


## Do whatever you want!
mkdir ( $outpath) unless (-d $outpath );
chdir( $outpath );
my ( $extension, $filename, @temp );
@temp = split ( /\./, $FoI );
$extension = pop ( @temp );
foreach my $infile ( @infiles ){
	unless (-f $infile ) {
		warn "I can not access the file '$infile'\n$!\nplease give me the absolute path to the file!\n";
		next;
	}
	system ( "tar -f $infile -x $FoI" );
	unless ( -f $FoI ){
		warn "I have not found the file $FoI in the archive $infile\n";
		next;
	}
	@temp = split( "/", $infile ) ;
	$filename = pop ( @temp );
	$filename =~s/.tar$//;
	rename ( $FoI, $filename.".".$extension ) or die "I could not change the name of the FoI '$FoI'\n$!\n";
}
print "Done\n";