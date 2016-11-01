#! /usr/bin/perl -w

#  Copyright (C) 2011-02-28 Stefan Lang

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

=head1 perform_missing_subselection.pl

The script will do all registered cleaning steps for a set of infiles.

To get further help use 'perform_missing_subselection.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::MeDIP_results;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
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
 command line switches for perform_missing_subselection.pl

   -infiles       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/perform_missing_subselection.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);


## Do whatever you want!

my ( $analysis_settings, $data_file, $temp_data, $function_name );
$analysis_settings = {
	'_one_oligo_per_gene.xls' => 'get_best_oligo_per_gene',
	'_oligos_hypo_true.xls' => 'get_all_supportive_oligos'
};

foreach my $infile ( @infiles ){
	$data_file = undef;
	foreach my $file_ext ( keys %$analysis_settings ){
		unless (-f "$infile$file_ext" ){
			unless ( ref($data_file) eq "stefans_libs_file_readers_MeDIP_results" ){
				$data_file = stefans_libs_file_readers_MeDIP_results ->new();
				$data_file ->read_file ( $infile );
			}
			$function_name = $analysis_settings->{$file_ext};
			$temp_data = $data_file->$function_name();
			$temp_data -> write_file ( "$infile$file_ext" );
		}
	}
}

print "Done\n";