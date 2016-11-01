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

=head1 extract_gbFile_fromDB.pl

Select a gbFile from the databse and write it to a file.

To get further help use 'extract_gbFile_fromDB.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;

my ( $help, $debug, $outFormat, $gbFile_id, $gbFile_version, $outFile, $organism );

Getopt::Long::GetOptions(
	 "-outFile=s" => \$outFile,
	 "-gbFile_id=s" => \$gbFile_id,
	 "-gbFile_version=s" => \$gbFile_version,
	 "-organism=s" => \$organism,
	 "-output_format=s" => \$outFormat,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

if ( $help ){
	print helpString( ) ;
	exit;
}

unless ( defined $organism){
	print helpString( "We need to know from which organism the gbFile should be selected!" ) ;
	exit;
}

unless ( defined $gbFile_id || defined $gbFile_version ){
	print helpString( "We need either a gbFile_id or a gbFile_version to identify the gbFile in the database!" ) ;
	exit;
}

unless ( defined $outFormat){
	warn "output_format was not set - I assume you want to have a genbank format!\n";
	$outFormat = 'genbank';
}

unless ( defined $outFile){
	print helpString( "We need a outFile!" ) ;
	exit;
}

my $genomeDB = genomeDB->new();
my $database = $genomeDB->GetDatabaseInterface_for_Organism( $organism );

my $gbFile;

if ( defined $gbFile_id ){
	$gbFile = $database->get_gbFile_for_gbFile_id ( undef, $gbFile_id );
}
elsif( defined $gbFile_version){
	$gbFile = $database->get_gbFile_for_acc( undef, $gbFile_version );
}
else {
	die "There is a severe error occuring - we do not habe a $gbFile_version or a $gbFile_id!\n";
}

die "we got no gbFile for gbFile_id '$gbFile_id' and gbVersion '$gbFile_version'\n"
	unless ( ref($gbFile) eq "gbFile" );

if ( $outFormat eq "genbank" ){
	$gbFile -> WriteAsGB ( $outFile );
}
elsif ( $outFormat eq "fasta"){
	$gbFile -> WriteAsFasta ( $outFile );
}
else {
	die "sorry, but the format '$outFormat' is not supported!\n";
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for extract_gbFile_fromDB.pl
   -outFile        :the filename of the output file. the right extension will be added automatially
   -gbFile_id      :the gbFile_id of the wanted gbFile
   -gbFile_version :the version string of the wanted gbFile. If gbFile_id is given this info is ignored
   -organism       :the organism string you want a gbFile from
   -output_format  :the output format can be either 'genbank' or 'fasta' (default 'genbank')
   -help           :print this help
   -debug          :verbose output


"; 
}