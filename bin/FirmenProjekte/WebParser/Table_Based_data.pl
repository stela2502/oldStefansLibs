#! /usr/bin/perl -w

#  Copyright (C) 2012-01-10 Stefan Lang

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

=head1 Lund_Person_Page.pl

This script takes a person page from the Lund University and adds the information into a table.

To get further help use 'Lund_Person_Page.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::Latex_Document::Text;
use stefans_libs::flexible_data_structures::data_table;
use WWW::Mechanize;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

######## CONFIG ###########
my $web_page = "http://www.genetik.uni-hannover.de/";
$web_page = "http://www.ifmb.uni-hannover.de/";
$web_page = "http://portal.uni-freiburg.de/anatomie1/mitarbeiter";

###########################

my ( $help, $debug, $database, $link, $outfile, @options, $email, $institute );

Getopt::Long::GetOptions(
	"-link=s"       => \$link,
	"-institute=s"  => \$institute,
	"-outfile=s"    => \$outfile,
	"-options=s{,}" => \@options,
	"-email=s"      => \$email,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $link ) {
	$error .= "the cmd line switch -link is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $email ) {
	$error .= "the cmd line switch -email is undefined!\n";
}
unless ( defined $options[0] ) {
	$warn .= "the cmd line switch -options is undefined!\n";
}
if ( defined $institute ) {
	$institute .= "; ";
}
else {
	$warn .= "You should define the institute you got the contacts from!\n";
	$institute = '';
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
 command line switches for Lund_Person_Page.pl

   -link       :the link to the information page
   -institute  :the name of the institute to store in the company information
   -outfile    :a file where you want to store the information
   -options    :several options are possible
                'no_conversion' - I will not try to convert html to utf8 
   -email      :the email is coded in the pages - so please click on the mail and give it to me by hand

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/Lund_Person_Page.pl';
$task_description .= " -link $link"       if ( defined $link );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= ' -options ' . join( ' ', @options )
  if ( defined $options[0] );

my $temp_dir = "/home/stefan/tmp/";

my $options = {};
foreach (@options) {
	$options->{$_} = 1;
}

$outfile =~ s/\.xls$//;

unless ( -f "$outfile.log" ) {
	open( LOG, ">$outfile.log" )
	  or die "I could not create the log file '$outfile.log'\n$!\n";
}
else {
	open( LOG, ">>$outfile.log" )
	  or die "I could not open the log file '$outfile.log'\n$!\n";
}
print LOG $task_description . "\n";
close(LOG);
my ($data_table);
$data_table = data_table->new();

unless ( -f $outfile . ".xls" ) {
	foreach (
		'forename',   'surname',          'title',
		'company',    'WORK_telephone',   'FAX_telephone',
		'WORK_email', 'web_page',         'description',
		'address',    'MOBILE_telephone', 'web_page'
	  )
	{
		$data_table->Add_2_Header($_);
	}
	$data_table->define_subset( 'name',
		[ 'forename', 'surname', 'WORK_email' ] );
	$data_table->createIndex('WORK_email');
}
else {
	$data_table->read_file( $outfile . ".xls" );
	foreach (
		'forename',   'surname',          'title',
		'company',    'WORK_telephone',   'FAX_telephone',
		'WORK_email', 'web_page',         'description',
		'address',    'MOBILE_telephone', 'web_page'
	  )
	{
		$data_table->Add_2_Header($_);
	}
	$data_table->define_subset( 'name',
		[ 'forename', 'surname', 'WORK_email' ] );
	$data_table->createIndex('WORK_email');
}

my $help_table = data_table->new();


#my $Mech = WWW::Mechanize->new( 'stack_depth' => 2 );
#$Mech->get($link);
#open( OUT, ">$temp_dir/main.htm" )
#  or die "I could not create the temp file!\n$!\n";
#print OUT $Mech->content();
#close(OUT);

#system("wget -O $temp_dir/main.htm $link");
#unless ( -f "$temp_dir/main.htm" ) {
#	die "Oh I did not get the main file!\n";
#}
open( IN, "$link" )
  or die "I could not open the web page '$link'\n";

my ( $hash, $use, $text_obj, $large_line );
$hash->{'WORK_email'} = $email;
$text_obj             = stefans_libs::Latex_Document::Text->new();
$use                  = 0;
my ($type);
$hash = {};
my @header;
my $i = 0;
while ( <IN> ) {
	$use = 1 if ( $_ =~m/<table/);
	$use = 0 if ( $_ =~  m!</table!);
	next unless ( $use );
	#print "Table line: $_\n";
	if ( $_ =~m/<tr/ ){
		if (defined $header[0] ){
			if ( $use == 2) { ##OK - the data should be in the hash
				$help_table -> AddDataset ( $hash );
			}
			else {
				print "The summed up header = '".join(" ' '",@header)."'\n";
				foreach ( @header, 'web_page' ) {
					$help_table->Add_2_Header( $_ );
				}
			}
			$use = 2;
		}
		$hash = {};
		$i = 0;
	}
	next unless ( $_ =~m/<td/);
	unless ( $use == 2 ) { #I have got the full header!
		$header[$i++] = $1 if ( $_ =~m/>([\w\d\.\s\-øóæëäöγüÄÖÅÜØáåéð]+)</);
	}
	else {
		$hash->{$header[$i]} = $1 if ( $_ =~m/>([\w\d\.\s\-øóæëäöγüÄÖÅÜØáåéð,]+)</);
		$hash->{'web_page'} = $web_page.$1 if ( $_ =~m!href=".?([\w\d\/\._]+)!);
		$i ++;
	}
}
print "The help table:\n".$help_table->AsString();
my $temp;
for( my $i = 0; $i < $help_table->Lines; $i++){
		$temp = $help_table -> get_line_asHash ( $i);
		
		$hash = {'forename' => '', 'title' => '' };
		
		$hash->{'company'}  = $institute . 'Albert-Ludwigs-Universität Freiburg';
		$hash->{'web_page'} = $temp->{'web_page'};
		foreach ( split (/,?\s/, $temp->{'Name'} ) ){
			unless  ( $_ =~ m/\.$/){
				$hash->{'surname'} .= $_;
			}
			else { $hash->{'title'} .= $_; }
		}
		$hash->{'forename'} = $temp->{'Vorname'};
		$hash-> {'WORK_email'} = '';
		$hash->{'WORK_telephone'} = '0049 761-203 '.$temp->{'0761-203- '};
		$hash->{'WORK_telephone'} =~ s/,/, 0049 761-203 /g; 
	$data_table->AddDataset( $hash ) if ( defined $hash->{'surname'});
}
print root::get_hashEntries_as_string ( $hash , 3 , "I would hopt to find an empty hash and more than 0 lines in the table (".$data_table->Lines.")" );
print $data_table->AsString();
$data_table->write_file($outfile);
close(IN);