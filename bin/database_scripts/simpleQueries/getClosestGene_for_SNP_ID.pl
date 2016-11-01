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

=head1 getClosestGene_for_SNP_ID.pl

Select the closest 'gene' gbFile name for either a given rsID or a list of rsIDs.

To get further help use 'getClosestGene_for_SNP_ID.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::genomeDB;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @rsIDs, $organism_tag, $gbFeature_tag, $outfile);

Getopt::Long::GetOptions(
	 "-rsIDs=s{,}"    => \@rsIDs,
	 "-organism_tag=s"    => \$organism_tag,
	 "-gbFeature_tag=s"    => \$gbFeature_tag,
	 "-outfile=s"        => \$outfile,
	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 "-database=s"       => \$database
);

if ( $help ){
	print helpString( ) ;
	exit;
}
unless ( defined $organism_tag){
	print helpString( "Sorry, but we need the 'organism_tag' to identify the right genome to search for!") ;
	exit;
}

unless ( defined $rsIDs[0] ){
	print helpString( "Sorry, but we need a list of rsIDs that look like 'rs1234567' (rsIDs)") ;
	exit;
}
elsif (-f $rsIDs[0]) {
	open ( IN, "<$rsIDs[0]") or die "could not open file $rsIDs[0]\n" ;
	my $i = 0;
	foreach ( <IN> ){
		chomp $_;
		print "we read a line '$_'\n";
		$_ =~ s/ //g;
		if ( $_ =~ m/^rs\d+$/ ){
			print "And we have a match!\n";
			$rsIDs[$i++] = $_;
		}
		
	}
}
unless  ( $rsIDs[0] =~ m/^rs\d+$/){
	print helpString( "Sorry, but we need a list of rsIDs that look like 'rs1234567' (rsIDs)") ;
	exit;
}
my $error = '';
foreach my $rsID ( @rsIDs ){
	$error .= " $rsID;" unless ( $rsIDs[0] =~ m/^rs\d+$/);
}
if ( $error =~ m/\w/ ){
	print helpString( "We found rsIDs that do not have the right format:\n($error)\n") ;
	exit;
}


sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 
 function:
 Select the closest 'gene' name for either a given rsID or a list of rsIDs.
 
 command line switches for getClosestGene_for_SNP_ID.pl

   -rsIDs          :a list of rsIDs in the format (rs132...)
   -organism_tag   :the organism_tag to identify the right genome table
   -gbFeature_tag  :an optional feature tag if you do not want to search for 'gene'
   -outfile        :an optional file to store the results in
   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

"; 
}

## now we set up the logging functions....

my ( $task_description, $workingTable, $loggingTable, $workLoad, $loggingEntries );


## and add a working entry
$gbFeature_tag = 'gene' unless ( defined $gbFeature_tag);



## get the SNP_table interface
my ( $genomeDB, $db_interface );
$genomeDB = genomeDB->new( $database, $debug);
$db_interface = $genomeDB->getGenomeHandle_for_dataset( { 'organism_tag' => $organism_tag });
$db_interface = $db_interface->get_rooted_to('SNP_table');

## select the Genes close to the SNPs
my ( $sql, $temp, $sth, @rv, $rv, @data, $complex, $gbFeature );

$complex = "#1, #2, #3, #4 + #7, #5 + #7, #6 + #7, #8, #7, #4 ";

$sql = $db_interface->create_SQL_statement(
	{
		'search_columns' => [ 'SNP_table.rsID','gbFeaturesTable.name', 'chromosomesTable.chromosome', 'SNP_table.position', 'gbFeaturesTable.start', 'gbFeaturesTable.end',
			 'chromosomesTable.chr_start', 'gbFeaturesTable.gbString'],
		'complex_select' => \$complex,
		'where' => [
			['gbFeaturesTable.tag', '=', 'my_value'],
			['SNP_table.rsID', "=", 'my_value'] 
		],
		'order_by' => [ [ ['SNP_table.position', '-','gbFeaturesTable.start' ] ,'*', ['SNP_table.position', '-','gbFeaturesTable.start' ]] ],
		'limit' => 'limit 10'
	}
);

$db_interface->{'dbh'}->do( "SET SQL_MODE = 'NO_UNSIGNED_SUBTRACTION'");

$sql =~ s/\?/$gbFeature_tag/;


push ( @data, "rsID\tfeature name\tchromosome\tSNP chromosomal position\tgbFeature start\tgbFeature end\tgbFeature orientation\t10 closest genes [semicolon separated]");
$gbFeature = gbFeature->new( 'nix', '1..2' );
my $gbFile = gbFile->new();
my (@gbFeatures, $position, @ten_closest);
foreach my $rsID ( @rsIDs ){
	$temp = $sql;
	$temp =~ s/\?/$rsID/;
	$sth = $db_interface->{'dbh'}->prepare ( $temp);
	$rv = $sth->execute();
	unless ( $rv > 0){
		warn "we have not got any results for query \n$temp;\n";
		next;
	}
	#print "we got $rv results from query $temp\n";
	$rv = $sth->fetchall_arrayref();
	@gbFeatures = ();
	@ten_closest = ();
	foreach my $return_array ( @$rv ){
		my $f = gbFeature->new( 'nix', '1..2' );
		#print "and we parse the gbString @$return_array[6]\n";
		$f -> parseFromString( @$return_array[6]);
		$gbFeatures[@gbFeatures] = $f ;
		push (@ten_closest, $f ->Name() );
	}
	$gbFile->{features} = \@gbFeatures;
	
	#print "gbFile has the gbFeatures '". join("', '", @{$gbFile->Features()})."'\n";

	$gbFeature = $gbFile->getClosestFeature( @{@$rv[0]}[8] );
	#print "the closes gbFeature name for $rsID is ".$gbFeature->Name()."\n";
	for ( $position = 0; $position < @gbFeatures; $position ++){
		last if ( $gbFeature eq $gbFeatures[$position] );
	}
	@rv = @{@$rv[$position]};
	$rv = "+";
	$rv = "-" if ( defined $gbFeature->IsComplement());
	push ( @data, "$rv[0]\t$rv[1]\t$rv[2]\t$rv[3]\t$rv[4]\t$rv[5]\t$rv\t".join(";",@ten_closest));
	#last if ( scalar (@data) > 35);
}

if ( defined $outfile){
	open ( OUT ,">$outfile" ) or die "sorry, but I could not create the outfile file '$outfile'\n".$!;
	print OUT join ( "\n", @data);
	close ( OUT);
	print "results were written to '$outfile'\n";
}
else {
	print join ( "\n", @data)."\n";;
}


