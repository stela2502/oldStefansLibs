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

=head1 get_XML_helper_dataset_definition.pl

a small script that returns the actual needs of the XML_helper data stucture.

To get further help use 'get_XML_helper_dataset_definition.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::exec_helper::XML_handler;
use stefans_libs::root;


my ( $help, $debug);

Getopt::Long::GetOptions(
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

if ( $help ){
	print helpString( ) ;
	exit;
}

my $XML_handler = XML_handler->new();

print "Definition of the XML data structure that describes a single job package.\n\n";
print "\tNeeded tags for the 'executable' section\n";
print "\ttag\tdescription\n";
foreach my $tag ( @{$XML_handler->{'job_tags'}}){
	print "\t$tag->{'name'}\t$tag->{'description'}\n";
}
print "\n";
print "\tNeeded tags for the 'argument_tags' section\n";
print "\ttag\tdescription\n";
foreach my $tag ( @{$XML_handler->{'argument_tags'}}){
	print "\t$tag->{'name'}\t$tag->{'description'}\n";
}

print "\nAnd now we try to get the XML structure for a sample hash....\n";

my $hash = {
	'executable' => {
		'SCRIPT_NAME' => 'calculateNucleosomePositionings.pl',
		'DESCRIPTION' => 'a maintainance script to calculate the nucleosome positioning for a whole genome and stores those values in the database',
		'ENCAPSULATED' => 0,
		'RUN_NICE' => 1,
		'JOB_ID' => 1,
		'THREAD_PROVE' => 1
	},
	'arguments' => [
		{ 'ARGUMENT_NAME' => 'organism', 'IS_NECESSARY' => 1, 'CONFLICTS_WITH' => [], 'VALUE' => 'H_sapiens'},
		{ 'ARGUMENT_NAME' => 'executable', 'IS_NECESSARY' => 1, 'CONFLICTS_WITH' => [], 'VALUE' => '/home/stefan_l/Downloads/prgramme/nucleosomePrediction/nucleosome_prediction.pl' },
		{ 'ARGUMENT_NAME' => 'max_seq_length', 'IS_NECESSARY' => 0, 'CONFLICTS_WITH' => [], 'VALUE' => 1000000 },
	]
};

my $string = $XML_handler->print_XML_job_description_2_file ( $hash, "test.xml" );

root::print_hashEntries( $hash, 3, "we try to include convert this hash into a XML structure" );
print "\nand got this XML string:\n$string";



sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for get_XML_helper_dataset_definition.pl
 
   -help           :print this help
   -debug          :verbose output


"; 
}