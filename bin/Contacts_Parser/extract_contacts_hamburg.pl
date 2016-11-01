#! /usr/bin/perl -w

#  Copyright (C) 2011-11-23 Stefan Lang

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

=head1 extract_contacts_hamburg.pl

nix

To get further help use 'extract_contacts_hamburg.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::Latex_Document::Text;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile );

Getopt::Long::GetOptions(
	"-infile=s" => \$infile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
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
 command line switches for extract_contacts_hamburg.pl

   -infile       :<please add some info!>

   -help   :print this help
   -debug  :verbose output
   

";
}

## Do whatever you want!

open( IN, "<$infile" )
  or die
"Sorry I could not open the infile '$ARGV[0]' - or didn't you give me one?\n$!\n";

my $convert_text = stefans_libs::Latex_Document::Text->new();

my $table = data_table->new();
foreach (qw(title firstname surname WORK_email WORK_telephone web_page)) {
	$table->Add_2_Header($_);
}

#<table width="100%" cellspacing="1" cellpadding="1" border="0">
#    <tbody>
#    <tr>
#<td width="210">&nbsp;Altenburg, Christiane</td>
#    <td width="80">&nbsp;57140</td>
#<td width="80">&nbsp;54592</td>
#    <td><!--StartFragment --><a href="mailto:altenburg@uke.uni-hamburg.de" title="e-Mail: Altenburg"><img src="/institute/molekulare-zellbiologie/images_content/institut-biochemie-molekularbiologie-zellbiologie/ibmmz_II_e_mail.gif" alt="" /></a></td>
#    </tr>
#    <tr>
#<td>&nbsp;<em>Dr. med., F&auml;. Allgemeinmedizin</em></td>
#    <td>&nbsp;</td>
#<td>&nbsp;</td>
#    <td>&nbsp;</td>
#    </tr>
#</tbody>
#</table>

my ($hash, $is_table, $manual_inspection, $vorwahl);
$manual_inspection = 0;

while (<IN>) {
	if ( $_ =~m/<TD width=200>&nbsp;Vorwahl \((\d+)\)&nbsp;([\d ]+) -<\/TD>/){
		$vorwahl = $1;
		$vorwahl =~s/^0/0049 /;
	}
	if ( $_ =~
		m/<table width="100%" cellspacing="1" cellpadding="1" border="0">/ )
	{
		$is_table = 1;
		$hash  = {
			'title'          => undef,
			'firstname'      => undef,
			'surname'        => undef,
			'WORK_email'     => undef,
			'WORK_telephone' => undef,
			'web_page'       => undef,
		};
		next;
	}
	if ( $_ =~ /<\/table>/ ) {
		if (   defined $hash->{'WORK_email'}
			&& defined $hash->{'title'}
			&& defined $hash->{'surname'} )
		{
			$hash->{'WORK_telephone'} = "$vorwahl $hash->{'WORK_telephone'}" if ( defined $vorwahl);
			$table->AddDataset($hash);
		}
		else {
			warn root::get_hashEntries_as_string ( $hash , 3 , "Not complete??" );
		}
		$is_table = 0;
		next;
	}
	if ($is_table) {
		$_ = $convert_text ->convert_coding( $_ , 'html','text' );
		if ( $_ =~ m/<td width="210">.nbsp;([áØéëåæóðøäöü\w\- ]+), ([áØéëåæóðøäöü\w\- ]+)<\/td>/ ) {
			$hash->{'firstname'} = $2;
			$hash->{'surname'}   = $1;
			print "The name line was\n\t$_";
		}
		elsif ( $_ =~ m/<td width="210">.nbsp;([áØéëåæóðøäöü\w\-\(\), ]+)<\/td>/ ) {
			$hash->{'firstname'} = 'WARNING problemem mit dem Namen!! Warning';
			$hash->{'surname'}   = $1;
			$manual_inspection = 1;
		}
		elsif ( $_ =~ m/<td width="80">&nbsp;(\d+)<\/td>/
			&& !defined $hash->{'WORK_telephone'} )
		{
			$hash->{'WORK_telephone'} = $1;
		}
		elsif ( $_ =~ m/" ?mailto:([\w\.\-]+)@([\w\-\.]+) ?"/ ) {
			$hash->{'WORK_email'} = "$1\@$2";
		}
		elsif ( $_ =~ m/<td>&nbsp; ?<em>(.+)<\/em><\/td>/ ) {
			$hash->{'title'} = $1;
		}
		elsif ( $_ =~ m/<td> ?<em>&nbsp;(.+)<\/em><\/td>/ ) {
			$hash->{'title'} = $1;
		}
		elsif ( $_ =~ m/<td>&nbsp; ?<em>(.+)<br \/>/ ) {
			$hash->{'title'} = $1;
		}
		elsif ( $_ =~ m/<td> ?<em>&nbsp;(.+)<br \/>/ ) {
			$hash->{'title'} = $1;
		}
	}
}

if ( scalar( @{ $table->{'data'} } ) > 0 ) {
	$table = $table->Sort_by( [ [ 'title', 'lexical' ] ] );
	$table->write_file("$infile.xls");
	warn "Manual inspection nedded!!\n" if ( $manual_inspection );
}
else {
	warn "Sorry I could not identify any contacts in the file $infile\n";
}
close(IN);
