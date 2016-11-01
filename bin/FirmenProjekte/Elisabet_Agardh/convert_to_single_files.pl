#! /usr/bin/perl -w

#  Copyright (C) 2011-12-12 Stefan Lang

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

=head1 convert_to_single_files.pl

A tool to split an expression data table into description and data tables.

To get further help use 'convert_to_single_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $outpath, $p4Cs, @description);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,
	 "-outpath=s"    => \$outpath,
	 "-p4Cs=s"    => \$p4Cs,
	 "-description=s{,}"    => \@description,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( ! -d $outpath ) {
	mkdir ( $outpath );
}
unless ( defined $p4Cs) {
	$error .= "the cmd line switch -p4Cs is undefined!\n";
}
unless ( defined $description[0]) {
	$warn .= "the cmd line switch -description is undefined!\n\t## I WILL NOT CREATE A DUCUMENTATION FILE ##\n";
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
 command line switches for convert_to_single_files.pl

   -infiles       :<please add some info!> you can specify more entries to that
   -outpath       :<please add some info!>
   -p4Cs       :<please add some info!>
   -description       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/convert_to_single_files.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= " -outpath $outpath" if (defined $outpath);
$task_description .= " -p4Cs $p4Cs" if (defined $p4Cs);
$task_description .= ' -description \''.join( "' '", @description )."'" if ( defined $description[0]);

open ( LOG, ">$outpath/convert_to_single_files.log" ) or die "I could not create the file '$outpath/convert_to_single_files.log'\n$!\n";
print LOG $task_description . "\n";
close ( LOG ) ;


## Do whatever you want!
my ( $data_table, @taregts, @t_descr );

foreach my $infile ( @infiles ) {
	$data_table = data_table->new();
	$data_table -> read_file ( $infile );
	unless ( defined $data_table->Header_Position ( 'Probe Set ID' )){
		warn "the file '$infile' is no Affymetrix outfile - I need a 'Probe Set ID' column!\n";
		next;
	}
	@t_descr = ();
	foreach ( @description ) {
		if ( defined $data_table->Header_Position ( 'Probe Set ID' ) ){
			push ( @t_descr, $_ );
		}
		else {
			warn "I did not identify the descitpion column $_!\n";
		}	
	}
	if ( defined $t_descr[0] ) {
		$data_table->define_subset ( 'Description', ['Probe Set ID', @t_descr ] );
		$data_table->write_file ( $outpath."Description", 'Description');
	}
	my $new_column;
	foreach ( @{$data_table->{'header'}} ){
		if ( $_ =~m/$p4Cs/ ){
			## now I wil transfor the damn column name to something usefull!
			unless ( $_ =~m/(ARPE\-\d+)/ ){
				warn "We keep the original column name!\n";
				$new_column = $_;
			}
			else {
				$new_column = $1; 
				$data_table->Rename_Column ( $_, $new_column );
			}
			$data_table->define_subset ( 'write '.$_, [ 'Probe Set ID', $new_column ] );
			$data_table->write_file ( $outpath."/$_", 'write '.$_ );
		}
	}
}
print "Done!\n";

