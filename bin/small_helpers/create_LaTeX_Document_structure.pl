#! /usr/bin/perl -w

#  Copyright (C) 2011-05-03 Stefan Lang

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

=head1 create_LaTeX_Document_structure.pl

create an empty LaTeX document.

To get further help use 'create_LaTeX_Document_structure.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::Latex_Document;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $outfile);

Getopt::Long::GetOptions(
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

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
 command line switches for create_LaTeX_Document_structure.pl

   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/create_LaTeX_Document_structure.pl';
$task_description .= " -outfile $outfile" if (defined $outfile);

my $LaTeX_doc = stefans_libs::Latex_Document -> new();

my $section = $LaTeX_doc -> Section ( 'Sample Section');
my $text = $section->AddText ( "Test Text" );
my ( @temp, $path, $filename );
@temp = split ( "/", $outfile);
$filename = pop ( @temp );
$path = join ( "/", @temp );
unless ( $path =~m/\//){
	$path = "./";
}
$LaTeX_doc -> Outpath ( $path );
$LaTeX_doc -> write_tex_file ( $filename  );
## Do whatever you want!

