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
while (<IN>) {
	if ( $_ =~ m/<td width="565"/ && $_ =~ m/Dr. / ) {

		#print "I search here for the name: $_";
		next if ( defined $hash->{'forename'} );
		next if ( $_ =~ m/Prof. em./ );
		if ( $_ =~ m/>([\w\-øóæëäöγüÄÖÅÜØáåéð\.\s]+)<\/[ab]>/ )
		{
			$hash = {};

			#	print "This should contain the name: '$1'\n";
			foreach ( split( " ", $1 ) ) {
				if ( $_ =~ m/\.$/ ) {
					$hash->{'title'} .= $_;
				}
				elsif ( !defined $hash->{'forename'} ) {
					$hash->{'forename'} = $_;
				}
				else {

#			warn "Please check the outfile names! Probably we get a wrong surname here :'$hash->{'surname'} $_'\n"
#						if ( defined $hash->{'surname'});
					$hash->{'surname'} = $_;
				}
			}
			if ( $_ =~ m/href="([\w\d\-_\.\/:]+)"/ ) {
				$hash->{'web_page'} = $1;
			}
		}

#print root::get_hashEntries_as_string ( $hash , 3 , "And I hopefully got the name information" );
	}
	if ( $_ =~ m/<dt>([\w\-øóæëäöγüÄÖÅÜØáåéð\.\s\:\d]+)/ ) {

		#	print "This line should contain some more info: $_\n";
		$use = $1;
		if ( $use =~ m/Tel.: ([\d\-\s]+)/ ) {
			$hash->{'WORK_telephone'} = $1;
			unless ( $hash->{'WORK_telephone'} =~ m/0?[0\+]49/ ) {
				$hash->{'WORK_telephone'} =~ s/^0/049 /;
				chomp ($hash->{'WORK_telephone'} );
			}
		}
		elsif ( $use =~ m/E-Mail: / ) {
			if ( $_ =~ m/>([\w\.\-]+\@[\w\.\-]+)</ ) {
				$hash->{'WORK_email'} = $1;
				print "Identified a work mail: '$hash->{'WORK_email'}'\n";
			}
		}
	}
if ( defined $hash->{'WORK_email'} ) {
	print root::get_hashEntries_as_string ( $hash, 3,
		"I add this info to the table:" );
	$data_table->AddDataset($hash) if ( defined $hash->{'title'} );
	$hash = {};
}
}

print root::get_hashEntries_as_string (
	$hash, 3,
	"I would hopt to find an empty hash and more than 0 lines in the table ("
	  . $data_table->Lines . ")"
);
print $data_table->AsString();

$data_table->write_file($outfile);
close(IN);
exit;
while (<IN>) {
	next unless ( $_ =~ /<p class="bodytext"><a href=/ );
	print "I ckeck the line $_\n";

#<p class="bodytext"><a href="brueser.html" class="internal-link" >Prof. Dr. rer. nat. Thomas Brüser</a>&nbsp;(geschäftsführende Leitung)
#<br />&nbsp;E-Mail:&nbsp;<a href="javascript:linkTo_UnCryptMailto('ocknvq,dtwgugtBkhod0wpk/jcppqxgt0fg');" target="_blank" >brueser@ifmb.uni-hannover.de</a>
#<br />&nbsp;Telefon: +49 511 762 5945^M</p>
	if (
		$_ =~ m/<a href="([\w\.]+)"\sclass="internal-link"\s>([\w\s\.]+)[<\&]/ )
	{
		print root::get_hashEntries_as_string ( $hash, 3,
			"Did I have a contact from the last line?" );
		$hash               = {};
		$hash->{'company'}  = $institute . 'Leibnitz Universität Hanover';
		$hash->{'web_page'} = $web_page . $1;
		foreach ( split( " ", $2 ) ) {
			if ( $_ =~ m/\.$/ ) {
				$hash->{'title'} .= "$_";
			}
			elsif ( !defined $hash->{'forename'} ) {
				$hash->{'forename'} = $_;
			}
			else {
				$hash->{'surname'} = $_;
			}
		}
	}
	if ( $_ = m/>([\w\.\-]+\@[\w\.\-]+)</ ) {
		$hash->{'WORK_email'} = $1;
	}
	if ( $_ =~ m/Telefon:\s*([\+\d\s\-\.]+)/ ) {
		$hash->{'WORK_telephone'} = $1;
	}
	$data_table->AddDataset($hash) if ( defined $hash->{'surname'} );
}
print root::get_hashEntries_as_string (
	$hash, 3,
	"I would hopt to find an empty hash and more than 0 lines in the table ("
	  . $data_table->Lines . ")"
);
print $data_table->AsString();
$data_table->write_file($outfile);
close(IN);
exit;
while (<IN>) {

	if ( defined $hash->{'web_page'} ) {
		print root::get_hashEntries_as_string ( $hash, 3,
			"I will add this hash to the data file!" );
		$data_table->AddDataset($hash);
		$hash = {};
	}
	chop($_);
	chop($_);
	next unless ( $_ =~ m/\w/ );

	#print "new long line= '$_'\n";
	$large_line = $_;

## first get the name
## <br>Lund University, person and address catalogue <br> Karlsson, Stefan <br> Lund University
	$large_line = $text_obj->convert_coding( $large_line, 'html', 'text' )
	  unless ( $options->{'no_conversion'} );

	#print "new long line= '$_'\n";
	if ( $large_line =~ m!<h2>([\w\s]+)</h2>! ) {
		$type = $1;
		print "I have a type $type!\n";
	}
	last if ( $type eq "Wissenschaftliches Personal" );
	next unless ( defined $type );

	if ( $large_line =~
m/<p>(P?r?o?f?.? ?Dr.)\s*([\w\-øóæëäöγüÄÖÅÜØáåéð]+) ([\wøóæëäöγüÄÖÅÜØáåéð\s]+)/
	  )
	{
		$hash->{'title'}    = $1;
		$hash->{'forename'} = $2;
		$hash->{'surname'}  = $3;
		$hash->{'company'}  = $institute . 'Leibnitz Universität Hanover';
		next;
	}
	if ( $large_line =~ m!E-Mail! ) {
		print "I got the e-mail line '$large_line'\n";
		my ( $use, @last_4, @store );
		@last_4 = ( ' ', ' ', ' ', ' ' );
		@store = ();
		foreach ( split( "", $large_line ) ) {
			shift(@last_4);
			push( @last_4, $_ );
			unless ( defined $use ) {
				$use = '>' if ( join( "", @last_4 ) eq "href" );

			}
			elsif ( $_ eq $use ) {
				$use = 'push';
				if ( join( "", @store ) =~ m/\w\@\w/ ) {
					$hash->{'WORK_email'} = join( "", @store );
					last;
				}
				next;
			}
			elsif ( $use eq "push" ) {
				if ( $_ eq "<" ) {
					push( @store, '@' )
					  unless ( join( "", @store ) =~ m/\w\@\w/ );
					$use = ">";
					next;
				}
				push( @store, $_ );
			}
		}
		die
"I could not create a e-mail for $hash->{'forename'} $hash->{'surname'}!\n"
		  . join( "", @store ) . "\n"
		  unless ( defined $hash->{'WORK_email'} );
		next;
	}
	if ( $large_line =~ m/newsLatestLinkImage/ ) {
		print "Web Pahe with the line '$large_line'\n";
		$hash->{'web_page'} = $web_page . "$1"
		  if ( $large_line =~ m/href="([\w\.\d]+)[\?"]/ );
		next;
	}

	if ( $large_line =~ m/Telefon:/ ) {

#	print "Telephone, but I can not match to the the number!\n$large_line\n " unless ( $large_line =~m/([\d\s\-\.\(\)]+)/ );
		$hash->{'WORK_telephone'} = $1;
	}
}
print root::get_hashEntries_as_string (
	$hash, 3,
	"I would hopt to find an empty hash and more than 0 lines in the table ("
	  . $data_table->Lines . ")"
);
print $data_table->AsString();
$data_table->write_file($outfile);
close(IN);
