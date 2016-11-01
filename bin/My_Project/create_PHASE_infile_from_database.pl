#! /usr/bin/perl -w

#  Copyright (C) 2010-09-09 Stefan Lang

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

=head1 create_PHASE_infile_from_database.pl

A script, that can read SNP data from the database and create a PHASE infile from that to identify chromosmes.

To get further help use 'create_PHASE_infile_from_database.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::WGAS;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @rsIDs, @sampleIDs, $outfile, $WGAS_name, $organism_name);

Getopt::Long::GetOptions(
	 "-rsIDs=s{,}"    => \@rsIDs,
	 "-outfile=s"    => \$outfile,
	 "-WGAS_name=s"    => \$WGAS_name,
	 "-organism_name=s"    => \$organism_name,
	 "-sample_IDs=s{,}"   => \@sampleIDs,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $rsIDs[0]) {
	$error .= "the cmd line switch -rsIDs is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $WGAS_name) {
	warn "I have set the WGAS name to 'DGI' as you have not supplied one!\n";
	$WGAS_name = 'DGI';
}
unless ( defined $organism_name) {
	$organism_name = "H_sapiens";
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
 command line switches for create_PHASE_infile_from_database.pl

   -rsIDs         :a list of rsIDs
   -outfile       :the PHASE input file
   -WGAS_name     :the WGAS name (e.g. DGI)
   -sample_IDs    :a list of sample ids you want to get the data for
   -organism_name :the name of the organism - defaults to H_sapiens
   
   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= "perl ".root->perl_include()." $plugin_path/create_PHASE_infile_from_database.pl";
$task_description .= ' -rsIDs '.join( ' ', @rsIDs ) if ( defined $rsIDs[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -WGAS_name $WGAS_name" if (defined $WGAS_name);
$task_description .= " -organism_name $organism_name" if (defined $organism_name);

open ( LOG, ">$outfile.log") or die "could not create logfile $outfile.log";
print LOG $task_description."\n";
close ( LOG );

my $WGAS = WGAS->new( root->getDBH() );
my ($interface, $sample_IDs);
unless ( defined $sampleIDs[0]){
	print "we have no sample ids!\n";
	($interface, $sample_IDs) = $WGAS -> GetDatabaseInterface_for_dataset ( {'study_name' => $WGAS_name });

}
else {
	print "we restrict the output to the sample ids\n";
	($interface, $sample_IDs) = $WGAS -> GetDatabaseInterface_for_dataset ( {'study_name' => $WGAS_name, 'sample_id' => \@sampleIDs });
}

if ( ref($interface) eq "variable_table::queryInterface" ){
	## oh oh - so manny results....
	foreach ( @{$interface->{'tables'}}){
		$_-> Organism_name ( $organism_name );
	}
	my $temp_interface = rsID_2_SNP->new( $WGAS ->{'dbh'} );
	$temp_interface->{'_tableName'} = @{$interface->{'tables'}}[0]->{'_tableName'};
	$temp_interface -> Organism_name ( $organism_name );
	$temp_interface -> Sample_Lables( $sample_IDs );
	$temp_interface -> Print_SNP_List_4_PHASE ( \@rsIDs, $outfile, $interface );
}
else {
	$interface -> Organism_name ( $organism_name );
	$interface -> Print_SNP_List_4_PHASE ( \@rsIDs, $outfile );
}

print "we have used this SQL query:".$interface ->{'complex_search'}."\n";

print "Data written to $outfile\n";


