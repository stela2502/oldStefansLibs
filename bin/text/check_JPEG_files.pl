#! /usr/bin/perl -w

#  Copyright (C) 2011-05-11 Stefan Lang

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

=head1 check_JPEG_files.pl

This tool parses a directory tree and looks at each jpg or JPG file in the system. It will read from each file and check whether the file is corrupted. If the file is corrupted it will print out  the filename and an error message.

To get further help use 'check_JPEG_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use Image::MetaData::JPEG;
use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $document_root);

Getopt::Long::GetOptions(
	 "-document_root=s"    => \$document_root,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -d $document_root) {
	$error .= "the cmd line switch -document_root is undefined or not a path!\n";
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
 command line switches for check_JPEG_files.pl

   -document_root       :the base path to read all JPG or jpg files from

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/check_JPEG_files.pl';
$task_description .= " -document_root $document_root" if (defined $document_root);


## Do whatever you want!
my $errors = &open_path( $document_root );
my @problematic_files;

print "We found $errors in the jpg files\n".join("\n",@problematic_files);





sub open_path {
	my ( $path ) = @_;
	my ( @dir, $errors, $temp );
	$errors = 0;
	opendir ( DIR, $path ) or die "I could not open the path $path\n$!\n";
	@dir = readdir( DIR );
	closedir ( DIR );
	foreach my $file ( @dir ){
		next if $file =~m/^\./;
		if ( -d "$path/$file" ){
			$errors += &open_path("$path/$file");
			next;
		}
		unless (&check_image("$path/$file")){
			$errors ++;
			$temp = "$path/$file";
			$temp =~ s/ /\\ /g;
			push (@problematic_files,$temp );
		}
	}
	return $errors;
}


sub check_image{
	my ( $filename ) = @_;
	my ( $use );
	$use = 0;
	$use = 1 if ( lc($filename) =~m/jpg$/ );
	return 1 unless ( $use );
	my $image = new Image::MetaData::JPEG($filename);
	unless ($image) {
    	print "File: $filename\nError: " .Image::MetaData::JPEG::Error(). "\n" ;
    	return 0;
	}
	return 1;
}

