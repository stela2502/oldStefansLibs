#! /usr/bin/perl -w

#  Copyright (C) 2011-12-05 Stefan Lang

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

=head1 analyze_duplicates.pl

This tool looks at the duplicate files and clculates some statistics on these files.

To get further help use 'analyze_duplicates.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @infiles, $outfile, @options );

Getopt::Long::GetOptions(
	"-infiles=s{,}" => \@infiles,
	"-outfile=s"    => \$outfile,
	"-options=s{,}" => \@options,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infiles[0] ) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}

my @path = split ( "/", $infiles[0] );
pop ( @path);
$outfile = join("/",@path)."/analyze_duplicates.log";

unless ( defined $outfile ) {
	#$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $options[0] ) {
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
 command line switches for analyze_duplicates.pl

   -infiles       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>
   -options       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/analyze_duplicates.pl';
$task_description .= ' -infiles ' . join( ' ', @infiles )
  if ( defined $infiles[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= ' -options ' . join( ' ', @options )
  if ( defined $options[0] );

open( LOG, ">$outfile.log" )
  or die "Ic ould not craete the log file '$outfile.log'\n";
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!
my ( $data_table, $results_table, $infile, $temp, $sample_id );

for ( my $i = 0 ; $i < @infiles ; $i++ ) {
	$data_table = data_table->new();
	$infile     = $infiles[$i];
	$sample_id = 'unknown';
	$sample_id = $1 if ( $infile =~ m/\/(.+)-detailed_duplicate_analysis.xls/);
	$data_table->read_file($infile);
## these files has to contain at least the columns group_id	Sequence number	Sequence ID	Functionality	V-GENE and allele	V-REGION score
	foreach (
		(
			'group_id',
			'Sequence number',
			'Sequence ID',
			'Functionality',
			'V-GENE and allele',
			'V-REGION score'
		)
	  )
	{
		unless ( defined $data_table->Header_Position($_) ) {
			Carp::confess(
"The infile '$infile' does not contain the column '$_' - format not supported!\n"
			);
		}
	}
	$data_table -> define_subset ('DATA', ['V-GENE and allele' , 'Functionality']);
	$temp = $data_table ->pivot_table ( {
		'grouping_column' => 'group_id',
		'Sum_data_column' => 'DATA',
		'Sum_target_columns' => [ 'V Gene', "$sample_id ".'amplificates 4 gene'],
		'Suming_function' => sub {
			my $V_gene = $1 if ( $_[0] =~m/(IGHV\d+\-\d+)/);
			if ( $_[1] =~m/unproductive/ ) {
				$V_gene .= " unproductive";
			}
			else {
				$V_gene .= " productive";
			}
			return $V_gene, (scalar(@_) /2);
		}
	});
	$temp ->write_file ( "$infile.processed");
	$temp->Rename_Column( 'group_id', "$sample_id ".'group_id');
	$temp = $temp ->pivot_table ( {
		'grouping_column' => 'V Gene',
		'Sum_data_column' => "$sample_id ".'amplificates 4 gene',
		'Sum_target_columns' => [ 'n', 'min','lower','median',  'upper','max'],
		'Suming_function' => sub {
			my $hash = root->whisker_data(\@_);
			return 		scalar(@_),
			$hash->{'min'}, 
			$hash->{'lower'},
			$hash->{'median'},
			$hash->{'upper'},
			$hash->{'max'},
		}
	});
	$temp->setDefaultValue("n", 0);
	foreach ( ('n', 'min','lower','median',  'upper','max') ){
		$temp->Rename_Column( $_, "$sample_id $_");
	}
	$temp ->write_file ( "$infile.results" );
}
