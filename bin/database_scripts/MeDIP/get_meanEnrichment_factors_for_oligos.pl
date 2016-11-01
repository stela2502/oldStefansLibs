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

=head1 get_meanEnrichment_factors_for_oligos.pl

a tool to fetch data from NimbleGene array datasets

To get further help use 'get_meanEnrichment_factors_for_oligos.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::array_dataset;
use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $scientist_id, $array_type, $experiment_id, @oligo_names, $outfile);

Getopt::Long::GetOptions(
	 "-scientist_id=s"    => \$scientist_id,
	 "-array_type=s"    => \$array_type,
	 "-experiment_id=s"    => \$experiment_id,
	 "-oligo_names=s{,}"    => \@oligo_names,
	 "-outfile=s"          => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $scientist_id) {
	$error .= "the cmd line switch -scientist_id is undefined!\n";
}
unless ( defined $array_type) {
	$error .= "the cmd line switch -array_type is undefined!\n";
}
unless ( defined $experiment_id) {
	$error .= "the cmd line switch -experiment_id is undefined!\n";
}
unless ( defined $oligo_names[0]) {
	$error .= "the cmd line switch -oligo_names is undefined!\n";
}
unless ( defined $outfile ){
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for get_meanEnrichment_factors_for_oligos.pl

   -scientist_id   :the id of the scientist - will be important for access control only
   -array_type     :the array_tape you want to get info for (INPUT, IP or GFF at the moment)
   -experiment_id  :the experiment you want to get info for
   -oligo_names    :the name of the oligos you want to get information for
   -outfile        :where to write the tab separated outfile to

   -help           :print this help
   -debug          :verbose output
   

"; 
}

## now we set up the logging functions....

my ( $task_description, $array_dataset );

$task_description .= 'get_meanEnrichment_factors_for_oligos.pl';
$task_description .= " -scientist_id $scientist_id" if (defined $scientist_id);
$task_description .= " -array_type " if (defined $array_type);
$task_description .= " -experiment_id $experiment_id" if (defined $experiment_id);
$task_description .= ' -oligo_names '.join( ' ', @oligo_names ) if ( defined $oligo_names[0]);

$array_dataset = array_dataset->new( undef, $debug);

unless ( $array_dataset->can('scientist_may_access')){
	warn "Sorry, but access control is not implemented in class ". ref($array_dataset)."\n";
}
else{
	Carp::confess( "Sorry, but the scientist $scientist_id must not access the expreiment $experiment_id\n")
	unless ( $array_dataset->scientist_may_access({'scientis_id' => $scientist_id , 'experiment_id' =>$experiment_id }));
}
my @array_dataset_ids;

foreach my $array (@{$array_dataset-> getArray_of_Array_for_search({
 	'search_columns' => [ref($array_dataset).".id"],
 	'where' => [
 	[ref($array_dataset).".experiment_id", "=", "my_value"],
 	[ref($array_dataset).".array_type", "=", "my_value"]]
 }, $experiment_id, $array_type)} ){
 	push ( @array_dataset_ids, @$array[0]);	
 }
 
my $interface = $array_dataset -> getMinimalSearchInterface( \@array_dataset_ids  );

 
# $interface->printReport ( "~/databse_internals.tex");
 my $data_file = $interface->get_data_table_4_search({
 	'search_columns' => [ ref($interface).".id", 'oligo_name', 'value'],
 	'where' => [['oligo_name','=','my_value']]
 }, \@oligo_names );
 $data_file->Add_2_Description("used sql query: $interface->{'complex_search'}");
 $data_file->Add_2_Description("the command: $task_description");
my $i = 0;
foreach my $sample_lable ( $interface->Sample_Lables () ){
 	if ( $i == 0){
 		$data_file->Rename_Column( 'value', $sample_lable);
 	}
 	else{
 		$data_file->Add_2_Header ( $sample_lable );
 	}
 	$i ++;
}
 $data_file->print2file($outfile);
