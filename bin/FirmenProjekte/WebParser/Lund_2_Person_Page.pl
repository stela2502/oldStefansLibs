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

my ( $help, $debug, $database, $link, $outfile, @options, $email );

Getopt::Long::GetOptions(
	"-link=s"       => \$link,
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
foreach ( @options ){
	$options -> { $_ } = 1;
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
		'forename',   'surname',  'title', 'company', 'WORK_telephone','FAX_telephone',
		'WORK_email', 'web_page', 'description', 'address', 'MOBILE_telephone'
	  )
	{
		$data_table->Add_2_Header($_);
	}
	$data_table -> define_subset ( 'name' , ['forename', 'surname', 'WORK_email']);
	$data_table -> createIndex ( 'WORK_email' );
}
else {
	$data_table->read_file( $outfile . ".xls" );
	foreach (
		'forename',   'surname',  'title', 'company', 'WORK_telephone','FAX_telephone',
		'WORK_email', 'web_page', 'description', 'address', 'MOBILE_telephone'
	  )
	{
		$data_table->Add_2_Header($_);
	}
	$data_table -> define_subset ( 'name' , ['forename', 'surname', 'WORK_email']);
	$data_table -> createIndex ( 'WORK_email' );
}

my $Mech = WWW::Mechanize->new( 'stack_depth' => 2 );
$Mech->get($link);
open ( OUT , ">$temp_dir/main.htm") or die "I could not create the temp file!\n$!\n";
print OUT $Mech->content();
close ( OUT );

#system("wget -O $temp_dir/main.htm $link");
#unless ( -f "$temp_dir/main.htm" ) {
#	die "Oh I did not get the main file!\n";
#}
open( IN, "$temp_dir/main.htm" )
  or die "I could not open the web page '$link'\n";

my ($hash, $use, $text_obj, $large_line );
$hash -> {'WORK_email'} = $email;
$text_obj = stefans_libs::Latex_Document::Text->new();
$use = 0;
$large_line = '';
while (<IN>) {
	chop($_);
	chop($_);
	$use = 1 if ( $_ =~m/Lund University, person and address catalogue/ );
	next unless ( $use );
	next unless ( $_ =~m/\w/);
	print "new long line= '$_'\n";
	$large_line = $large_line. $_;
	$use = 0 if ( $_ =~m/Tel:/ );
}
close ( IN );
$large_line =~ s/\t/ /g;
$large_line =~ s/  +/ /g;

## first get the name
## <br>Lund University, person and address catalogue <br> Karlsson, Stefan <br> Lund University 
$large_line = $text_obj->convert_coding( $large_line, 'html', 'text' ) unless ( $options->{'no_conversion'} );

if ( $large_line =~m/Lund University, person and address catalogue <br> ([\w_&\$øóæëäöγüÄÖÅÜØáåéð\- ]+), ([\w_&\$øóæëäöüγÄÅÖÜØáåéð\- ]+) <br> ([\w_&\$øóæëäöüγÄÅÖÜØáåéð\- ]+) <input type/){
	$hash->{'forename'} = $2; $hash->{'surname'} = $1;
	$hash->{'company'} = $3;
}
else { 
	die "You should parse the right info from this line:\n'$large_line'\n\nBut I could not identify the name of the target person!\n";
}
if ( $large_line =~m/<br><br> <b> $hash->{'surname'}, $hash->{'forename'} <\/b> <br> ([\w_&\$øóæëäöγüÄÖÅÜØáåéð\-, ]+), <a href="javascript:sendTask/) {
	$hash->{'title'} = $1;
}
else {
	$hash->{'title'} = 'UNKNOWN';
	warn  "You should parse the right info from this line:\n'$large_line'\n\nBut I could not identify the title\n'<br><br> <b> $hash->{'surname'}, $hash->{'forename'} <\/b> <br> ([\\w_&\$øóæëäöγüÄÖÅÜØáåéð\-, ]+), <a href=\"javascript:sendTask'\n";
}
if (  $large_line =~m/<\/a>,([\w_&\$øóæëäöγüÄÖÅÜØáåéð\-,:; ]+)<br> <B>Tel: \+46 \(0\)(\d\d*-\d+)<\/B>, Fax: \+46 \(0\)(\d\d*-\d+)/ ){
	$hash->{'address'} = $1;
	$hash->{'WORK_telephone'} = "0046 ".$2;
	$hash->{'FAX_telephone'} = "0046 ".$3;
	$hash->{'WORK_telephone'} =~s/-/ /;
	$hash->{'FAX_telephone'} =~s/-/ /;
}
elsif ($large_line =~m/<\/a>,([\w_&\$øóæëäöγüÄÖÅÜØáåéð\-,:; ]+)<br> <B>Tel: \+46 \(0\)(\d\d*-\d+)<\/B>, Mobil arbete: \+46 \(0\)(\d\d*-\d+), Fax: \+46 \(0\)(\d\d*-\d+)/) {
	$hash->{'address'} = $1;
	$hash->{'WORK_telephone'} = "0046 ".$2;
	$hash->{'FAX_telephone'} = "0046 ".$4;
	$hash->{'MOBILE_telephone'} = "0046 ".$3;
	$hash->{'WORK_telephone'} =~s/-/ /;
	$hash->{'FAX_telephone'} =~s/-/ /;
	$hash->{'MOBILE_telephone'} =~s/-/ /;
}
elsif ( $large_line =~m/<\/a>,([\w_&\$øóæëäöγüÄÖÅÜØáåéð\-,:; ]+)<br> Tel: \+46 \(0\)(\d\d*-\d+)/){
	$hash->{'address'} = $1;
	$hash->{'WORK_telephone'} = "0046 ".$2;
	$hash->{'WORK_telephone'} =~s/-/ /;
}
elsif ( $large_line =~m/<\/a>,([\w_&\$øóæëäöγüÄÖÅÜØáåéð\-,:; ]+)<br> /){
	$hash->{'address'} = $1;
}
else {die  "You should parse the right info from this line:\n'$large_line'\n\nBut I could not identify the address and telephone numbers!\n<br> <B>Tel: +46 .0.([\\d\\-]+)<\/B>, Fax: +46 .0.([\\d\\-]+)\n"; }
	

warn "You should parse the right info from this line:\n'$large_line'\n". root->print_perl_var_def($hash);

$data_table -> AddDataset ( $hash );
$data_table -> write_file ( $outfile );
