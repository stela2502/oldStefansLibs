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

=head1 identfyGenes_close_to_ROI.pl

a simple DB query interface, that can search for ROI_tags and craetes a list of genes in there vincity.

To get further help use 'identfyGenes_close_to_ROI.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::genomeDB;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::array_analysis::outputFormater::arraySorter;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @ROI_tags, $genome_organism_tag, @ROI_info_names, $outfile);

Getopt::Long::GetOptions(
	 "-ROI_tags=s{,}"    => \@ROI_tags,
	 "-ROI_info_names=s{,}" => \@ROI_info_names,
	 "-genome_organism_tag=s"    => \$genome_organism_tag,
	 "-outfile=s"        => \$outfile,
	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 "-database=s"       => \$database
);

if ( $help ){
	print helpString( ) ;
	exit;
}



sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for identfyGenes_close_to_ROI.pl

   -ROI_tags       :The name of the ROI you are interested in
   -ROI_info_names :the names of the information hidden in the ROI features
   -genome_organism_tag    :the name of the genome you have ROIs for
   -outfile        :the file to print the results to
   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

"; 
}
my ( $gene, @ROI_ids, $dataSet, $interface, $genomeDB, $ROI_string, $ROI_gbFeature, $ROI_TAG );

unless ( defined $genome_organism_tag){
	print helpString( "Sorry, but without the name of the genome, I can not select the right ROI table name!") ;
	exit;
}
unless ( defined $ROI_tags[0] ){
	print helpString( "we need the ROI_tag to select several ROI from the database!") ;
	exit;
}
else {
	$ROI_string = "'".join ( "', '",@ROI_tags)."'";
}


$genomeDB = genomeDB->new();
$interface = $genomeDB->getGenomeHandle_for_dataset ( {'organism_tag' => $genome_organism_tag });
$interface = $interface->get_rooted_to('gbFilesTable');
$interface->Connect_2_result_ROI_table();

my ( $sql_q, $sql_gbFile_id, $rel_position, $temp, $sth, $max_gbFile_id, $rv, $gbFile_id, @gbFile_features, $loactionHash, $sql_ROI);

$sql_q = $interface -> create_SQL_statement ( {
 	'search_columns' => ['gbFeaturesTable.gbString'],
 	'where' => [['gbFeaturesTable.tag','=','my_value'],
 	 ['gbFeaturesTable.gbFile_id', '=', 'my_value']],
},
);
$sql_q =~ s/\?/gene/;

$sql_gbFile_id = $interface -> create_SQL_statement ( {
 	'search_columns' => ['chromosomesTable.id'],
 	'order_by' => [ ['my_value', '-',  'chromosomesTable.id' ] ],
 	'limit' => 'limit 1'
}
);
$sql_gbFile_id =~ s/\?//;

$sql_ROI = $interface -> create_SQL_statement ( {
 	'search_columns' => ['ROI_table.tag', 'ROI_table.start', 'ROI_table.gbString'],
 	'where' => [['ROI_table.gbFile_id' ,'=','my_value'], ['ROI_table.tag' , '=' , 'my_value']],
 	'order_by' => [ 'ROI_table.start' ]
}
);

$sth = $interface->{'dbh'}->prepare( $sql_gbFile_id );
unless ( $sth->execute()){
	Carp::confess ( "We have not got a result for query '$sql_gbFile_id;'\n".$interface->{'dbh'}->errstr()."\n");
}
($max_gbFile_id) = $sth->fetchrow_array();

my ( $matches, $data_table );
$data_table = data_table->new();
$data_table->Add_2_Header('Gene Symbol');
$data_table->createIndex('Gene Symbol');

foreach $ROI_TAG ( @ROI_tags ){
	$data_table->Add_2_Header("$ROI_TAG"."_relative_position");
	$data_table->setDefaultValue("$ROI_TAG"."_relative_position", 'no match');
}
foreach $ROI_TAG ( @ROI_info_names ){
	$data_table->Add_2_Header("$ROI_TAG"."_relative_position");
	$data_table->Add_2_Header("$ROI_TAG"."_mean");
	$data_table->Add_2_Header("$ROI_TAG"."_n");
	$data_table->Add_2_Header("$ROI_TAG"."_std");
}


for ( $gbFile_id = 1; $gbFile_id <= $max_gbFile_id; $gbFile_id ++){
	last if ( $debug && $gbFile_id == 5);
	print "we evaluate the gbFile with the id $gbFile_id\n";
	$temp = $sql_q;
	$temp =~ s/\?/$gbFile_id/;
	$sth = $interface->{'dbh'}->prepare ( $temp );
	
	unless ( $sth->execute()){
		Carp::confess ( "We have an database error for query '$temp;'\n".$interface->{'dbh'}->errstr()."\n");
	}
	$rv = $sth->fetchall_arrayref();
	## OK now we have all gbFeatureStrings for one gbFile
	## and we are going to generate a array of gbFeatures!
	@gbFile_features = ();
	$loactionHash = undef;
	foreach my $array ( @$rv ){
		my $gbFeature = gbFeature->new ( 'nix', '1..2' );
		$gbFeature->parseFromString ( @$array[0] );
		push (@gbFile_features, $gbFeature );
		$loactionHash -> { $gbFeature -> ExprStart () } = $gbFeature;
	}
	## OK got the gbFeatures_hash - and now get the ROI for this gbFeature
	$temp = $sql_ROI;
	$temp =~ s/\?/$gbFile_id/;
	$temp =~ s/= '?\?'?/IN ($ROI_string)/;
	$sth = $interface->{'dbh'}->prepare ( $temp );
	unless ( $sth->execute()){
		Carp::confess ( "We have an database error for query '$temp;'\n".$interface->{'dbh'}->errstr()."\n");
	}
	$rv = $sth->fetchall_arrayref();
	
	## OK now we have all gbFeatureStrings for one gbFile
	## and we are going to generate a array of gbFeatures!
	$matches = 0;
	foreach my $array ( @$rv ){
		$temp = &getTheClosestfromTheHash ($loactionHash, $array );
		if ( ref($temp) eq "gbFeature"){
			$dataSet = { 'Gene Symbol' => $temp->Name()};
			$ROI_gbFeature = gbFeature->new( 'nix', '1..2');
			$ROI_gbFeature->parseFromString ( @$array[2] );
			if ( defined $temp->IsComplement() ){
				$rel_position = ($ROI_gbFeature->Start() - $temp->ExprStart)."..".($ROI_gbFeature->End - $temp->ExprStart);
			}
			else {
				$rel_position = ( $temp->ExprStart - $ROI_gbFeature->Start())."..".($temp->ExprStart - $ROI_gbFeature->End);
			}
			
			foreach $ROI_TAG ( @ROI_info_names ){
				foreach ( '_mean', '_n', '_std'){
					$dataSet->{$ROI_TAG.$_} = @{$ROI_gbFeature->Info_for_Tag( $ROI_TAG.$_ )}[0];
				}
				$dataSet->{$ROI_TAG."_relative_position"} = $rel_position if ($dataSet->{$ROI_TAG.'_mean'});
			}
			unless ( scalar(keys %$dataSet) > 1 ){
				$dataSet->{@$array[0]."_relative_position"} = $rel_position;
			}
			else {
				$dataSet->{@$array[0]."_relative_position"} = "match";
			}
			$data_table->Add_Dataset($dataSet) ;
				$matches ++;
		}
	}
	unless ( $matches > 0) {
		print "and we got $matches matches using the search for ROIs:\n$temp;\n";
	}
	else {
		print "and we got $matches\n";
	}
}


#print "gene_name\t".join ( "\t",@ROI_tags),"\n";

my $d2 = $data_table->Sort_by('Gene Symbol','lexical');
$d2->print2file($outfile);

#open  ( OUT , ">$outfile") if ( defined $outfile );
#
#my $line = '';
#
#if ( defined *OUT ){
#	print OUT  "gene_name\t".join ( "\t",@ROI_tags),"\n";
#}
#else {
#	print  "gene_name\t".join ( "\t",@ROI_tags),"\n";
#}
#
#foreach $gene ( sort keys %$dataSet ) {
# $line =  $gene;
#	foreach my $ROI_tag(  @ROI_tags ){
#		if ( $dataSet->{$gene}->{$ROI_tag}){
#			$line .= "\tmatch";
#		}
#		else{
#			$line .=  "\t -- ";
#		}
#		
#	}	
#	if (  defined $outfile ){
#		print OUT $line."\n";
#	}
#	else{
#		print $line."\n";
#	}
#	
#}
#
#close ( OUT ) if (  defined $outfile );

sub getTheClosestfromTheHash{
	my ( $hash, $resultArray ) = @_;
	my ( $min, $actual, $last );
	$min = 10**10;
	foreach my $gbFeature_trsnc_start ( sort { $a <=> $b } keys ( %$hash )){
		$last = (($gbFeature_trsnc_start - @$resultArray[1])**2)**0.5;
		if ( $min > $last){
			$actual->{$last} = $gbFeature_trsnc_start;
			$min = $actual;
			#print "we got the distance to the transcription start of ".$hash->{$gbFeature_trsnc_start}->Name(). "\n"
		#." of ".(($gbFeature_trsnc_start - @$resultArray[1])**2)**0.5."\n";
		}
	}
	$min = @{[sort { $a <=> $b} keys %$actual] }[0];
	return $hash->{$actual->{$min}};
}
