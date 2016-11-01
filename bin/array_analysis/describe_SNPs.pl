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

=head1 describe_SNPs.pl

this script will help in understanding the function of single SNPs.

To get further help use 'describe_SNPs.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @rsIDs, $organism_name, $distance, $outfile );

die "Sorry, but this script is not functional!\n";
Getopt::Long::GetOptions(
	"-rsIDs=s{,}"      => \@rsIDs,
	"-organism_name=s" => \$organism_name,
	"-distance=s" => \$distance,
	"-outfile=s"       => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $rsIDs[0] ) {
	$error .= "the cmd line switch -rsIDs is undefined!\n";
}
unless ( defined $organism_name ) {
	$organism_name = 'H_sapiens';
	$warn .= "organism_name was set to $organism_name\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $distance ) {
	$distance = 50000;
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
 command line switches for describe_SNPs.pl

   -rsIDs          :a list of rsIDs of interest
   -organism_name  :the name of the organism the SNP is for (H_sapiens is the default)
   -distance       :the maximal distance where we want to get overlapping genes
   -outfile        :a up to now unused outfile

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'describe_SNPs.pl';
$task_description .= ' -rsIDs ' . join( ' ', @rsIDs ) if ( defined $rsIDs[0] );
$task_description .= " -organism_name $organism_name"
  if ( defined $organism_name );
$task_description .= " -outfile $outfile" if ( defined $outfile );

open ( LOG , ">$outfile.log") or die "I could not create the log file '$outfile.log'\n$!\n";
print LOG $task_description;
close ( LOG );

my ( $genomeDB, $interface );
$genomeDB  = genomeDB->new();
$interface = $genomeDB->GetDatabaseInterface_for_Organism($organism_name);
$interface = $interface->get_rooted_to('SNP_table');
my $results = $interface->get_data_table_4_search(
	{
		'search_columns' => [
			'rsID',                         ref($interface) . '.position',
			ref($interface) . '.gbFile_id', 'gbFeaturesTable.name',
			'gbFeaturesTable.gbString'
		],
		'where' => [
			[ ref($interface) . '.rsID', '=', 'my_value' ],
			[ 'gbFeaturesTable.tag',     '=', 'my_value' ],
			[
				'gbFeaturesTable.gbFile_id', '=', ref($interface) . '.gbFile_id'
			],
			[
				'gbFeaturesTable.start', '<',
				[ ref($interface) . '.position', '+', 'my_value' ]
			],
			[
				'gbFeaturesTable.end', '>',
				[ ref($interface) . '.position', '-', 'my_value' ]
			]
		]
	},
	\@rsIDs,
	['gene', 'mRNA','CDR'], $distance ,$distance 
);

die "Sorry, but we have no information about these SNPs!\n"
  unless ( ref($results) eq "data_table" );
## Do whatever you want!
print "we executed the search $interface->{'complex_search'}\n";
print $results ->print();
