#! /usr/bin/perl -w

#  Copyright (C) 2011-06-28 Stefan Lang

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

=head1 create_Anschreiben.pl

A script to create personal letter stubs using the ebner.lco LaTeX macro.

To get further help use 'create_Anschreiben.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $opening, $outfile, $title, @ct_address);

Getopt::Long::GetOptions(
	 "-outfile=s"    => \$outfile,
	 "-title=s"    => \$title,
	 "-ct_address=s{,}"    => \@ct_address,
         "-opening=s" => \$opening,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $title) {
	$error .= "the cmd line switch -title is undefined!\n";
}
unless ( defined $ct_address[0]) {
	$error .= "the cmd line switch -ct_address is undefined!\n";
}
unless ( defined $opening ) {
	$error .= "the opening string is empty!\n";
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
 command line switches for create_Anschreiben.pl

   -outfile       :the new tex out file
   -title         :the subject or title for your letter
   -ct_address    :the contact adress like 
	'University of Copenhagen' 'BRIC' 'Ole Maal\\o{}es Vej 5' '2200 Copenhagen N'
   -opening       :the opening of your letter like 'Dear Klaus'

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/create_Anschreiben.pl';
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -title $title" if (defined $title);
$task_description .= ' -ct_address '.join( ' ', @ct_address ) if ( defined $ct_address[0]);


## Do whatever you want!
$outfile .= ".tex" unless($outfile =~ m/\.tex$/ );
open ( OUT , ">$outfile" ) or die "Sorry, but I could not create the outfile'$outfile'\n$!\n";
print OUT 
'% $Id$

% Author: Dr. Michael Ebner, Michael@DrEbner.net
% Date: May 2005

\documentclass[ebner,paper=a4,fontsize=11pt,ngerman,BCOR=10mm]{scrlttr2}% 

\KOMAoptions{foldmarks=false,backaddress=false,parskip=full}

\usepackage[ngerman]{babel}
\usepackage[T1]{fontenc}      % T1-encoded fonts: auch Woerter mit Umlauten trennen
\usepackage[latin9]{inputenc}

%\usepackage{marvosym}       % Fuer Telefon-, Handy- und Briefsymbol

% prefer syntax as sans serif

\usepackage{url}



% neuen satzspiegel berechnen, wg neuer Schrift
%\typearea{calc}              % (preferred for a5paper)
%\typearea{default}           % (preferred for a4paper)


% todo: implement use of my variable frommobilephone 
\firstfoot{} % no bank information

\begin{document}%\sffamily
\pagestyle{empty}
%% Adresse muss im Sourcecode in einer einzigen Zeile stehen!!! (keine Zeilenumbrueche)
\begin{letter}{',join("\\\\",@ct_address),'}

\setkomavar{date}{\today} 
\setkomavar{subject}{',$title,'}

%\opening{Sehr geehrte Damen und Herren,}

\opening{',$opening,',}

My Text...

\closing{Yours Sincerely}
\enlargethispage{6\baselineskip}

\medskip
%\noindent Anlagen

% Wort Anlagen reicht bei Bewerbungen
%\encl{
% anlagen
%}

\end{letter}
\end{document}

\endinput
%% end of file
';
close ( OUT );
print "I hope you can use the outfile $outfile\n";

print "
--
You need the ebner document class in order to use this tex source file!\ņ";

