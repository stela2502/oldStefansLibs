#! /usr/bin/perl -w

#  Copyright (C) 2012-01-09 Stefan Lang

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

=head1 parse_medical_lund.pl

The script gets the main page for a Lund University Profesors page and writes a ducument, that can be used to contact the people by mail or telephone.

To get further help use 'parse_medical_lund.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::Latex_Document::Text;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $initial_link, $temp_dir, $outfile, @modes );

Getopt::Long::GetOptions(
	"-initial_link=s" => \$initial_link,
	"-temp_dir=s"     => \$temp_dir,
	"-outfile=s"      => \$outfile,
	"-modes=s{,}"     => \@modes,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $initial_link ) {
	$error .= "the cmd line switch -initial_link is undefined!\n";
}
unless ( defined $temp_dir ) {
	$error .= "the cmd line switch -temp_dir is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $modes[0] ) {
	$warn .= "the cmd line switch -modes is undefined!\n";
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
 command line switches for parse_medical_lund.pl

   -initial_link   :a www address for the main table
   -temp_dir       :an temp dir which I can use and delete afterwards
   -outfile        :the results table file
   -modes          :not defined

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/parse_medical_lund.pl';
$task_description .= " -initial_link $initial_link"
  if ( defined $initial_link );
$task_description .= " -temp_dir $temp_dir" if ( defined $temp_dir );
$task_description .= " -outfile $outfile"   if ( defined $outfile );
$task_description .= ' -modes ' . join( ' ', @modes ) if ( defined $modes[0] );

open( LOG, ">$outfile.log" )
  or die "I could not open the olog file '$outfile.log'\n$!\n";
print LOG $task_description . "\n";
## Do whatever you want!

mkdir($temp_dir) unless ( -d $temp_dir );
system("wget -O $temp_dir/main.htm $initial_link");
unless ( -f "$temp_dir/main.htm" ) {
	die "Oh I did not get the main file!\n";
}
## I am looking for the lines:
## <ul class="Ul-A Ul-ul"><li>Abrahamsson, Per-Anders
## <ul><li><a href="en_projektdetaljer.php?Proj=352" class="blalank">New methods for diagnosis, prognosis and treatment of prostate cancer</a></li></ul>

open( IN, "$temp_dir/main.htm" )
  or die "I could not open the web page '$initial_link'\n";
my ( $data_table, $USE, $hash, $text_obj );

$text_obj = stefans_libs::Latex_Document::Text->new();

$data_table = data_table->new();
foreach (
	'forename',   'surname',  'title', 'WORK_telephone',
	'WORK_email', 'web_page', 'description'
  )
{
	$data_table->Add_2_Header($_);
}
$USE = 0;

while (<IN>) {
	chomp($_);
	$_ = $text_obj->convert_coding( $_, 'html', 'text' );

	#print $_;
	if ( $_ =~
m/\<ul class="Ul-\w Ul-ul"\>\<li\>([\w_&\$øóæëäöγüÄÖÅÜØáåéð\- ]+), ([\w_&\$øóæëäöüγÄÅÖÜØáåéð\- ]+)/
	  )
	{
		if ( defined $hash->{'forename'} ) {
			$data_table->AddDataset($hash);
			#last;
		}
		$USE                = 1;
		$hash               = {};
		$hash->{'forename'} = $2;
		$hash->{'surname'}  = $1;
	}
	elsif ($USE) {

		unless ( $_ =~
m/\<ul\>\<li\>\<a href="(en_projektdetaljer.php\?Proj=\d+)" class="blalank"\>([\w_&\$øóæëäγöü'´ÄÖÜØáåéð,\.;:()\-–\?\/ ]+)\<\/a><\/li><\/ul>/
#m/\<ul\>\<li\>\<a href="(en_projektdetaljer.php\?Proj=\d+)" class="blalank"\>([.]+)\<\/a><\/li><\/ul>/
		  )
		{
			die "I could not process the line $_!\n";
		}
		$USE                   = 0;
		$hash->{'web_page'}    = $initial_link."$1";
		$hash->{'web_page'} =~ s/index.php//;
		$hash->{'description'} = $2;
		$hash                  = &parse_web_page($hash);
	}
}
close(IN);
unlink("$temp_dir/main.htm");

$data_table->AddDataset($hash) if ( defined $hash );
$data_table->write_file($outfile);

sub parse_web_page {
	my ($hash) = @_;
	system("wget -O $temp_dir/part.htm $hash->{'web_page'}");
	unless ( -f "$temp_dir/part.htm" ) {
		warn "Oh I did not get the sub file!\n$hash->{'web_page'}\n";
		return 0;
	}
	my $use = 0;
	open( PART, "<$temp_dir/part.htm" )
	  or die "I could not open the file '$temp_dir/part.htm'\n$!\n";
	while (<PART>) {
		chomp($_);
		$_ = $text_obj->convert_coding( $_, 'html', 'text' );
		if ( $_ =~
m/mailto:([\w@\-_\.]+)">$hash->{'surname'}, $hash->{'forename'}\<\/a\>, (.+)<\/p>/
		  )
		{
			$hash->{'title'}      = $2;
			$hash->{'WORK_email'} = $1;
			$use                  = 1;
			next;
		}
		if ($use == 1) {
			if ( $_ =~ m/Link to project homepage/ ) {
				$use = 2;
				next;
			}
			if ( $_ =~ m/recent original publications/ ) {
				$use = 2;
				next;
			}
			next if ( $_ =~m/Co-workers:/);
			next if ( $_ =~m/Clinical speciality:/);
			my $str = $_;
			my $new_str = '';
			my $not     = 0;
			foreach ( split( "", $str ) ) {

				if ( $_ eq "<" ) {
					$new_str .= " ";
					$not = 1;
				}
				$new_str .= $_ unless ($not);
				$not = 0 if ( $_ eq ">" );
			}
			$new_str =~ s/ +/ /g;
			$new_str =~s/^ +//;
			#$new_str =~s/\s+$//;
			$new_str =~ s/\\\$//g;
			if ( $new_str =~ m/Phone: *\+([\d \-]+)*/ ){
				$hash->{'WORK_telephone'} = $1;
				next;
			}
			print "I add '$new_str' to the description\n";
			$hash->{'description'} .= $new_str;
		}
	}
	warn "Oh I have not been able to get any information from this file!\n"."most probably I did not find the line 'mailto:([\\w\@\_\-]+)\">$hash->{'surname'}, $hash->{'forename'}\<\/a\>, (.+)<\/p>'".
	root->print_perl_var_def (  $hash )
	if ( $use == 0);
	unlink("$temp_dir/part.htm");
	return $hash;

}

