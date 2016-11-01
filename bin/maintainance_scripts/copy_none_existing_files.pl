#! /usr/bin/perl -w

#  Copyright (C) 2012-01-27 Stefan Lang

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

=head1 copy_none_existing_files.pl

A simple tool to copy onle those files, that do not already exist - might be a reinvention of the wheel, but is easily done.

To get further help use 'copy_none_existing_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use File::Copy;
use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $inpath, $outpath);

Getopt::Long::GetOptions(
	 "-inpath=s"    => \$inpath,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $inpath) {
	$error .= "the cmd line switch -inpath is undefined!\n";
}
else {
	$inpath =~ s/ /\ /g;
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
 command line switches for copy_none_existing_files.pl

   -inpath       :<please add some info!>
   -outpath       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/copy_none_existing_files.pl';
$task_description .= " -inpath $inpath" if (defined $inpath);
$task_description .= " -outpath $outpath" if (defined $outpath);


## Do whatever you want!

print "Copied files:\n";
my $i = 0;
foreach ( &copy_files( $inpath, $outpath) ){
	print "$outpath/$_\n";
	$i ++;
}
print "In total I have copied $i files.\n";

sub copy_files {
	my ( $source_path, $target_path, $subpath ) = @_;
	$subpath = '' unless ( defined $subpath );
	my @return;
	opendir( DIR, $source_path . $subpath )
	  or Carp::confess("could not open path '$source_path/$subpath'\n");
	my @contents = readdir(DIR);
	closedir(DIR);
	foreach my $file (@contents) {
		next if ( $file =~ m/^\./ );
		if ( -d $source_path . $subpath . "/$file" ) {
			push( @return,
				&copy_files( $source_path, $target_path, $subpath . "/$file" )
			);
		}
		else {
			unless ( -d $target_path . $subpath ) {
				system( "mkdir -p " . $target_path . $subpath );
			}
			copy(
				$source_path . $subpath . "/$file",
				$target_path . $subpath . "/$file"
			);
			push( @return, $subpath . "/$file" );
		}
	}
	return @return;
}
