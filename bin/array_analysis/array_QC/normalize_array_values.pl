#! /usr/bin/perl -w

#  Copyright (C) 2011-03-16 Stefan Lang

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

=head1 normalize_array_values.pl

the scipt will normalize the expression arrays to mean 0 and std 1 for each expression estimate.

To get further help use 'normalize_array_values.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::affymetrix_expression_result;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile, $revert_log, @p4Cs);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,
	 "-revert_log"    => \$revert_log,
	 "-p4Cs=s{,}"    => \@p4Cs,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $p4Cs[0]) {
	$error .= "the cmd line switch -p4Cs is undefined!\n";
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
 command line switches for normalize_array_values.pl

   -infile       :<please add some info!>
   -outfile       :<please add some info!>
   -revert_log       :<please add some info!>
   -p4Cs       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/normalize_array_values.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -revert_log" if ($revert_log);
$task_description .= ' -p4Cs '.join( ' ', @p4Cs ) if ( defined $p4Cs[0]);

if ( -f $p4Cs[0]){
	open ( IN , "<$p4Cs[0]");
	my @data;
	foreach ( <IN> ) {
		chomp ( $_ );
		push ( @data, split/\s/,$_ );
	}
	shift ( @data ) unless ( defined $data[0] );
	@p4Cs = @data;
	close ( IN );
}
my $data = stefans_libs_file_readers_affymetrix_expression_result->new ();
$data -> p4cS ( @p4Cs );
$data -> read_file ( $infile );
$data -> revert_RMA_log_values () if ( $revert_log );
$data = $data -> normalize_std0_Expression ();
$data -> write_file ( $outfile );

