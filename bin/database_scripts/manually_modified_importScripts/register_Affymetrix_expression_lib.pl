#! /usr/bin/perl -w

#  Copyright (C) 2008 Stefan Lang

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

=head1 register_Affymetrix_expression_lib.pl

This script can be used to register new Affymetrix expression array lib files. THe mein effort is to store the cdf or clf and plf files together with a probeset_id to Gene_Symbol table in the database so that we can use the affymetrix pover tools to estimate the expression levels.

To get further help use 'register_Affymetrix_expression_lib.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::expression_estimate::Affy_description;
use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,                $debug,            $database,
	$column_name_probeID, $column_name_Gene, $cdf_file,
	$clf_file,            $pgf_file,         $probe2gene_file,
	$lib_description,     $affy_identifier,  $lib_version
);

Getopt::Long::GetOptions(
	"-cdf_file=s"            => \$cdf_file,
	"-clf_file=s"            => \$clf_file,
	"-pgf_file=s"            => \$pgf_file,
	"-affy_identifier=s"     => \$affy_identifier,
	"-lib_version=s"         => \$lib_version,
	"-probe2gene_file=s"     => \$probe2gene_file,
	"-column_name_probeID=s" => \$column_name_probeID,
	"-column_name_Gene=s"    => \$column_name_Gene,

	"-lib_description=s" => \$lib_description,

	"-help"       => \$help,
	"-debug"      => \$debug,
	"-database=s" => \$database
);

unless ( defined $probe2gene_file ) {
	$probe2gene_file = 'probeset_id';
}
unless ( defined $column_name_Gene ) {
	$column_name_Gene = 'Gene Symbol';
}

my $warn  = '';
my $error = '';

unless ( defined $cdf_file ) {
	$cdf_file = '';
	$warn .= "the cmd line switch -cdf_file is undefined!\n";
}
unless ( defined $clf_file ) {
	$clf_file = '';
	$warn .= "the cmd line switch -clf_file is undefined!\n";
}
unless ( defined $pgf_file ) {
	$pgf_file = '';
	$warn .= "the cmd line switch -pgf_file is undefined!\n";
}
unless ( defined $cdf_file || ( defined $clf_file && defined $pgf_file ) ) {
	$error .= "we need either the affy cdf- or the affy clf- and pgf- files!";
}
unless ( defined $affy_identifier ) {
	$error .= "the cmd line switch -affy_identifier is undefined!\n";
}
unless ( defined $probe2gene_file ) {
	$error .= "the cmd line switch -probe2gene_file is undefined!\n";
}
unless ( defined $lib_description ) {
	$error .= "the cmd line switch -lib_description is undefined!\n";
}
unless ( defined $lib_version){
	$error .= "the cmd line switch -lib_version is undefined!\n";
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
 command line switches for register_Affymetrix_expression_lib.pl
 
   -affy_identifier :the affy name of the array (e.g. 'NuGO_Hs1a520180' or 'HuGene-1_0-st-v1')

   -cdf_file       :the affymetrix cdf lib file for the expression array
   -clf_file       :the affymetrix clf lib file for the expression array
   -pgf_file       :the affymetrix pgf lib file for the expression array
       ## NOTE: either the cdf or the clf and the pgf files are needed
   
   -probe2gene_file     :a file containing a 'probeset_id' and a 'Gene Symbol' column
   -column_name_probeID :the header of the probe_id column (default 'probeset_id')
   -column_name_Gene    :the header of the gene name column (defaul 'Gene Symbol')
   
   -lib_description :a description where you got the the lib files from

   -help           :print this help
   -debug          :verbose output   

";
}

## now we set up the logging functions....

my ( $task_description, $workingTable, $loggingTable, $workLoad,
	$loggingEntries, $temp );

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );

## and add a working entry

$task_description =
"register_Affymetrix_expression_lib.pl -cdf_file $cdf_file -clf_file $clf_file -pgf_file $pgf_file -probe2gene_file $probe2gene_file -lib_description $lib_description";

$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'register_Affymetrix_expression_lib.pl',
		'description' => $task_description
	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description($task_description);
unless ( defined @$loggingEntries[0] ) {

## first we need to check the probe2gene_file as that has to be in a readable format
## the affy cdf or clf and pgf files are a little harder to check - they might be in binary format.
## as we do not use the information stored in these files I do not want to support them at the moment :-(

	my $dataTable = data_table->new();
	$dataTable->read_file($probe2gene_file);
	$error = '';
	$temp  = $dataTable->Header_Position($column_name_probeID);
	unless ( $temp >= 0 ) {
		$error .=
"there is no comun named $column_name_probeID in the file $probe2gene_file\n";
	}
	$temp = $dataTable->Header_Position($column_name_Gene);
	unless ( $temp >= 0 ) {
		$error .=
"there is no comun named $column_name_Gene in the file $probe2gene_file\n";
	}
	if ( $error =~ m/\w/ ) {
		Carp::confess($error."\nhaving the column headers ".join ("; ", @{$dataTable->{'header'}}) );
	}## OK the file can be used
	
	my $probe2gene_hash =
	  $dataTable->getAsHash( $column_name_probeID, $column_name_Gene );
	my $Affy_description = Affy_description->new( root->getDBH(), $debug );
	my $hash = {'identifier'      => $affy_identifier,
			'manufacturer'    => 'affymetrix',
			'array_type'      => 'expression',
			'lib_description' => $lib_description,
			'description_data' => $probe2gene_hash,
			'lib_version' => $lib_version
	};
	$hash->{'cdf_file'} = $cdf_file if ( defined $cdf_file);
	$hash->{'clf_file'} = $cdf_file if ( defined $clf_file);
	$hash->{'pgf_file'} = $cdf_file if ( defined $pgf_file);
	$Affy_description->AddDataset(
		$hash
	);
	print "DONE!\n";


## work is finfished - we add a log entry and remove the workload entry!

	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

}

$workingTable->delete_workload_for_PID($$);

