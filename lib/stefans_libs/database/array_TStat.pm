package array_TStat;
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

use strict;
use stefans_libs::NimbleGene_config;
use stefans_libs::database::hybInfoDB;
use stefans_libs::nimbleGeneFiles::gffFile;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

database::array_TStat

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Array_Data_TStat where all probe level statistics are stored.

=head2 Depends on

L<database::hybInfoDB>

L<::NimbleGene_config>

=head2 Provides

L<CreateDB|"CreateDB">

L<DataExists|"DataExists">

L<insertData|"insertData">

L<getInfo|"getInfo">

L<GetValue_forInfoID|"GetValue_forInfoID">

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 return values

A object of the class array_TStat

=cut

sub new {

	my ($class) = @_;

	my (
		$self,                  $dbh,          $sth_insert_info,
		$sth_insert,       $root,         $NimbleGene_config,
		$hybInfoDB,             $sth_get_Info, $sth_get_Data,
		$sth_insert_normalized, $sth_test,     $sth_select_HybInfo,
		%data
	);

	$NimbleGene_config = NimbleGene_config->new;
	$root              = root->new();
	$hybInfoDB         = hybInfoDB->new;
	$dbh = $root->getDBH( $NimbleGene_config->{database} ) or die $_;

	$sth_insert =
	  $dbh->prepare(
		"Insert into Array_File_TStat ( InfoID, TstatFile ) values ( ?, ?) ")
	  or die $dbh->errstr();
	$sth_get_Data =
	  $dbh->prepare("Select TstatFile from Array_File_TStat where InfoID = ?")
	  or die $dbh->errstr();

	$sth_test = $dbh->prepare( "
        select TstatFile from Array_File_TStat where InfoID = ?")
        or die $dbh->errstr();

	$self = {
		data      => \%data,
		dbh       => $dbh,
		hybInfoDB => $hybInfoDB,
		root      => $root,

		#     select_Info => $sth_get_Info,
		select_Data => $sth_get_Data,

		#     insert_Info => $sth_insert_info,
		insert_Data => $sth_insert,

		#     select_HybInfo => $sth_select_HybInfo,
		data_existent_test => $sth_test
	};

	bless( $self, $class ) if ( $class eq "array_TStat" );

	return $self;
}

=head2 DataExists

=head3 atributes

See L<database::hybInfoDB/"SelectID_ByHybInfo">

=head3 return values

true if more than 1000 values are stored in the database ore false if less than 1000 values are stored

=cut

sub DataExists {
	my ( $self, $specificity, $celltype, $organism, $designID ) = @_;

	my ( $rv, @a, $infoID, $filename );
	$infoID = $self->getInfo( $specificity, $celltype, $organism, $designID );

	$rv = $self->{data_existent_test}->execute($infoID)
	  or die $self->{data_existent_test}->errstr();
	$filename = $self->{data_existent_test}->fetch();
	@a = stat(@$filename[0]);
	unless ( defined $a[0]){
		$self->{dbh}->do("delete from Array_File_TStat where InfoID = $infoID ");
	}
	return defined $a[0];
}

=head2 CreateDB

Creates a new table to store the probe level test statistic values foreach oligo.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
	my ($self) = @_;

	$self->{dbh}->do( "
DROP TABLE IF EXISTS Array_File_TStat
" ) or die $self->{dbh}->errstr();

	$self->{dbh}->do( "
CREATE TABLE Array_File_TStat (
  `ID` int(11) NOT NULL auto_increment,
  `InfoID` int(11) NOT NULL default '0',
  `TstatFile` varchar(100) NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  KEY `InfoID` (`InfoID`),
  UNIQUE (`InfoID`, `TstatFile`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1
"
	) or die $self->{dbh}->errstr();
}

=head2 getInfo

See L<::database::hybInfoDB/"GetInfoIDs_forHybType">

=cut

sub getInfo {
	my ( $self, $antibody, $celltype, $organism, $designID ) = @_;

	my ( $rv, $infoHash );
	$infoHash =
	  $self->{hybInfoDB}
	  ->GetInfoID_forHybType( $antibody, $celltype, $organism, $designID );
	return $infoHash;
}

=head2 insertData

=head3 atributes

[0]: the nimbleGeneID

[1]: either the antibody specificity or the DNA marker (cy3 or cy5)

[2]: the celltype or the celltype id

[3]: the organism string

[4]: the DNA fluorescence marker (cy3 or cy5)

[5]: reference to the data hash with the format { oligoID => the oligo ID, 't-value' => the probe level test statistics value , 
GFF => the enrichment factor based on the mean oligo hybridization values}

=cut

sub insertData {
	## Hier brauchen wir:
	## nimblgeneID, antibody, celltype, organism, Marker, data
	## data muss aus einem Array von hashes bestehen
	## { oligoID, t-value, GFF }

	my ( $self, $antibody, $celltype, $organism, $designID, $data ) = @_;

	my ( $dataPath, $filename, @temp, $infoID, $i );

	$filename = join( "-", ( $antibody, $celltype, $organism, $designID ) );
	@temp = split( " ", $filename );
	$filename = join( "_", @temp );

	$dataPath = NimbleGene_config::DataPath();
	$dataPath = "$dataPath/TStat";
	mkdir($dataPath);
	$filename = "$dataPath/$filename.txt";

	if ( $self->DataExists( $antibody, $celltype, $organism, $designID ) ) {
		print
"Daten wurden schon eingegeben!\nDaten werden nicht(!) �berschieben!\n";
		return;
	}

	$infoID = $self->getInfo( $antibody, $celltype, $organism, $designID );

	$i = 0;
	open( DATA, ">$filename" ) or die "could not create '$filename'\n";

	print DATA "#oligoID\tt-value\tGFF\tIP_varianz\tINPUT_varianz\n";

	foreach my $data_hash (@$data) {
		#print "priont a line to $filename\n";
		print DATA
			"$data_hash->{oligoID}\t$data_hash->{'t-value'}\t$data_hash->{GFF}\t",
			"$data_hash->{IP_varianz}\t$data_hash->{Control_varianz}\n";
		$i++;
	}
	close (DATA);
	print "Insert into Array_File_TStat ( InfoID, TstatFile ) values ( $infoID, '$filename' )\n";
	my $rv = $self->{insert_Data}->execute($infoID, "$filename" );
	print "$rv entries added to the database\n";
	return $i;
}

=head2 GetValue_forInfoID

=head3 atributes

[0]: the hybridization info id as returned by L<database::hybInfoDB/"SelectID_ByHybInfo">

[1]: either 'tstat' or 'gff_summary' 

=head3 return values

A reference to a hash with the structure { OlgioID => $value}. The variable content for $value depends on atribute[1].
If atribute[1] eq 'tstat' $value represents the probe level test statistics value for the given olgio, 
if atribute[1] equals 'gff_summary' $value represents the enrichment factor based on the mean oligo hybridization values.

=cut

sub GetValue_forInfoID {
	## Hier Brauchen wir;
	## nimblgeneID, Marker, what
	## mögliche werte für what = (tstat, gff )

	my ( $self, $infoID, $what ) = @_;
	die "$self->GetValue_forInfoID is deletetd! work it up!!\nnew method has to be called 'getFilename4InfoID'\n";
	my ( $filename, $oligoID, $TStat, $gff, $var_IP, $var_INPUT, $i, $return );

	return $self->{data}->{"$infoID$what"}, undef
	  if ( defined $self->{data}->{"$infoID$what"} );
	$i = 0;
	$self->{select_Data}->execute($infoID)
	  or die $self->{select_Data}->errstr();
	$filename = $self->{select_Data}->fetch();
	open ( DATA, "<$filename") or die "could not open data file '$filename'\n ";
	
	if ( lc($what) eq "tstat" ) {
		while (<DATA>){
			chomp $_;
			( $oligoID, $TStat, $gff, $var_IP, $var_INPUT ) = split("\t", $_);
			$return -> {$oligoID} = $TStat;
			$i++;
		}
	}
	if ( lc($what) eq "gff_summary" ) {
		while (<DATA>){
			chomp $_;
			( $oligoID, $TStat, $gff, $var_IP, $var_INPUT ) = split("\t", $_);
			$return -> {$oligoID} = $gff;
			$i++;
		}
	}
	$self->{data}->{"$infoID$what"} = $return;
	return $return, $i;
}

sub GetData4InfoID{
	my ( $self, $infoID) = @_;
	my ($filename, $return, @line);
	
	$filename = $self->getFilename4InfoID($infoID);
	open (DATA, "<$filename") or die "could not open '$filename' at $self->GetData4InfoID()!\n";
	#print "We get the data from '$filename' in $self->GetData4InfoID\n";
	while (<DATA>){
		next if ($_ =~ m/^#/);
		chomp $_;
		@line = split("\t",$_);
		die "unrecognized format in $self->GetData4InfoID ($line[0])\n" unless ( $line[0] =~ m/(CHR\d+)([PR])\d+/ );
		$return->{"$line[0]"} = $line[1];
	}
	close (DATA);
	#root::print_hashEntries($return, 2, "$self->GetData4InfoID return hash:\n");
	return $return;
}

sub getFilename4InfoID{
	my ( $self, $InfoID, $mode ) = @_;
	
	my ($rv, $filename, $sth);

	$rv = "select TstatFile from Array_File_TStat where InfoID = $InfoID";

	$sth = $self->{dbh}->prepare($rv);
	$sth->execute();
	$filename  = $sth->fetch();
	return @$filename[0];		 
}


1;
