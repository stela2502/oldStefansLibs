#! /usr/bin/perl -w

#  Copyright (C) 2010-10-04 Stefan Lang

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

=head1 clean_up_statistics_path.pl

A script, that cleans up the early statistical results where multiple enaluation could occure for the same genomic region.

To get further help use 'clean_up_statistics_path.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use File::Copy;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $inpath );

Getopt::Long::GetOptions(
	"-inpath=s" => \$inpath,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -d $inpath ) {
	$error .= "the cmd line switch -inpath is undefined!\n";
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
 command line switches for clean_up_statistics_path.pl

   -inpath       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ( $task_description, @files, $chr_regions, $chr_tag, $filetype, $move_to );

$task_description .= 'clean_up_statistics_path.pl';
$task_description .= " -inpath $inpath" if ( defined $inpath );

opendir( DIR, "$inpath" ) or die "I could not open the inpath $inpath\n$!\n";
@files = readdir(DIR);
closedir(DIR);
chdir($inpath);
## I need to set up the target path(s)
foreach (
	'statistics',        'PHASE_infiles', 'PHASE_logs',
	'PHASEd_haplotypes', 'duplicates', 'simply_remove'
  )
{
	mkdir "$_" unless ( -d "$_" );
}

$move_to = {
	'PHASE.log'           => 'PHASE_infiles',
	'PHASE'               => 'PHASE_infiles',
	'PHASE.descr'         => 'PHASE_infiles',
	'chromosomes_hbg'     => 'PHASE_logs',
	'chromosomes_probs'   => 'PHASE_logs',
	'chromosomes_freqs'   => 'PHASE_logs',
	'chromosomes_monitor' => 'PHASE_logs',
	'chromosomes_pairs'   => 'PHASE_logs',
	'chromosomes_recom'   => 'PHASE_logs',
	'chromosomes'         => 'PHASEd_haplotypes',
	'statistics.log'      => 'statistics',
	'statistics'          => 'statistics'
};

## now I look at the files!

if ($debug) {
	foreach my $file (@files) {
		unless ( $file =~ m/(\w+)_(CHR\w+)_(\d+)\.\.(\d+).(.*)/ ){
			print "we can not use this file $file\n";
			next;
		}
		$chr_tag  = "$2:$3..$4";
		$filetype = $5;
		if ( defined $chr_regions->{$chr_tag} ) {
			if ( $chr_regions->{$chr_tag}->{$filetype}){
				move( $file, "duplicates/$file" );
				next;
			}
		}
		if ( defined $move_to->{$filetype} ) {
			print join( ' ',
				( 'move', $file, $move_to->{$filetype} . "/" . $file ) )."\n";
		}
		elsif ( $filetype =~ m/statistics_/ ) {
			print join( ' ',
				( 'move', $file, $move_to->{'statisics'} . "/" . $file ) )."\n"
			  ;
		}
		$chr_regions->{$chr_tag} = {} unless ( defined  $chr_regions->{$chr_tag});
		$chr_regions->{$chr_tag}->{$filetype} = 1;
	}
}
else {
	foreach my $file (@files) {
		next unless ( $file =~ m/(\w+)_(CHR\w+)_(\d+)\.\.(\d+).(.*)/ );
		$chr_tag  = "$2:$3..$4";
		$filetype = $5;
		if ( defined $chr_regions->{$chr_tag} ) {
			if ( $chr_regions->{$chr_tag}->{$filetype}){
				move( $file, "duplicates/$file" );
				next;
			}
		}
		if ( defined $move_to->{$filetype} ) {
			move( $file, $move_to->{$filetype} . "/" . $file );
		}
		elsif ( $filetype =~ m/statistics_/ ) {
			move( $file, $move_to->{'statistics'} . "/" . $file );
		}
		elsif ( -d $file ){
			move ( $file, "simply_remove/$file");
		}
		else { warn "We can not move that file $file\n";}
		$chr_regions->{$chr_tag} = {} unless ( defined  $chr_regions->{$chr_tag});
		$chr_regions->{$chr_tag}->{$filetype} = 1;
	}
}
print "Done\n";
