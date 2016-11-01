#! /usr/bin/perl -w

#  Copyright (C) 2010-09-24 Stefan Lang

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

=head1 batch_caluclate_statistics.pl

priorize summed info and calculate all statistics

To get further help use 'batch_caluclate_statistics.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, $outpath, $WGAS_name );

Getopt::Long::GetOptions(
	"-infile=s"    => \$infile,
	"-outpath=s"   => \$outpath,
	"-WGAS_name=s" => \$WGAS_name,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	mkdir($outpath);
}
unless ( defined $WGAS_name ) {
	$error .= "the cmd line switch -WGAS_name is undefined!\n";
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
 command line switches for batch_caluclate_statistics.pl

   -infile       :<please add some info!>
   -outpath       :<please add some info!>
   -WGAS_name       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= "perl "
  . root->perl_include()
  . " $plugin_path/"
  . 'batch_caluclate_statistics.pl';
$task_description .= " -infile $infile"       if ( defined $infile );
$task_description .= " -outpath $outpath"     if ( defined $outpath );
$task_description .= " -WGAS_name $WGAS_name" if ( defined $WGAS_name );

my ( $data, $outfile );
open( LOG, ">$outpath/batch_caluclate_statistics.log" )
  or die
"sorry, but I could not open the log file $outpath/batch_caluclate_statistics.log\n";
print LOG $task_description . "\n";

my $priorized_list = data_table->new();
$priorized_list->read_file($infile);
$priorized_list = $priorized_list->Sort_by(
	[
		[ 'hight stat cut off [n]', 'antiNumeric' ],
		[ 'low stat cutoff [n]',    'antiNumeric' ]
	]
);
$priorized_list->define_subset( 'chr_region',
	[ 'chromosome', 'start', 'end' ] );
my ( $cmd, $rsIDs, $already_worked_on );
$already_worked_on = {};

for ( my $id = 0 ; $id < @{ $priorized_list->{'data'} } ; $id++ ) {
	## get the data from the database
	$data = $priorized_list->get_line_asHash($id);
	next if ($already_worked_on -> { "CHR_$data->{'chromosome'}"."_$data->{'start'}"} );
	$already_worked_on -> { "CHR_$data->{'chromosome'}"."_$data->{'start'}"} = 1;
	next
	  if (-f "$outpath/*CHR_$data->{'chromosome'}" . "_"
		. $data->{'start'}
		. "*.statistics" );
	next if ( $data->{'chromosome'} =~ m/[XY]/ );
	$outfile =
	    $outpath . "/"
	  . $data->{'islet expression gene'} . "_CHR"
	  . $data->{'chromosome'} . "_"
	  . $data->{'start'} . ".."
	  . $data->{'end'};
	$rsIDs = join( " ",
		&estimate_best_rsIDs_for_chromosomal_region( $priorized_list, $data ) );
	$cmd = "perl "
	  . root::perl_include()
	  . " $plugin_path/create_PHASE_infile_from_database.pl -rsIDs $rsIDs "
	  . "-outfile $outfile.PHASE "
	  . "-WGAS_name $WGAS_name ";
	print $cmd. "\n";
	print LOG $cmd . "\n";
	system($cmd ) unless ( -f "$outfile.PHASE" );
	## run PLINK
	$cmd = "PHASE $outfile.PHASE $outfile.chromosomes";
	print $cmd. "\n";
	print LOG $cmd . "\n";
	system($cmd ) unless ( -f "$outfile.chromosomes" );
	## calculate statitsics
	$cmd = "perl "
	  . root::perl_include()
	  . " $plugin_path/calculate_statistics_4_chromosomal_region.pl "
	  . " -PHASE_files $outfile.chromosomes "
	  . " -outfile  $outfile.statistics";
	print $cmd. "\n";
	print LOG $cmd . "\n";
	system($cmd ) unless ( -f "$outfile.statistics" );

}

sub estimate_best_rsIDs_for_chromosomal_region {
	my ( $data_table, $hash ) = @_;
	my ( $rsIDs, @return, $temp, $rsID );
	foreach my $line_id (
		$data_table->get_rowNumbers_4_columnName_and_Entry(
			'chr_region',
			join(
				" ", ($hash->{'chromosome'}, $hash->{'start'}, $hash->{'end'})
			)
		)
	  )
	{
		$temp = $data_table->get_line_asHash($line_id);
		foreach $rsID ( split( " ", $temp->{'rsIDs'} ) ) {
			$rsIDs->{$rsID} = 0 unless ( defined $rsIDs->{$rsID} );
			$rsIDs->{$rsID}++;
		}
	}
	@return = ( sort { $rsIDs->{$b} <=> $rsIDs->{$a} } keys %$rsIDs );
	return @return[ 0 .. 9 ];
}
