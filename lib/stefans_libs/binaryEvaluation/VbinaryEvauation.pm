package VbinaryEvauation;
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
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::gbFile;
use stefans_libs::database_old::fileDB;
use stefans_libs::binaryEvaluation::VbinElement;

sub new{

  my ( $class ) = @_;

  my ( $self, %hmmData, @data );

  $self = {
		hmmData => \%hmmData,
		data => \@data,
		gffFile => gffFile->new(),
		fileDB => fileDB->new(),
		cutOffProbability => 0.99
  };

  bless $self, $class  if ( $class eq "VbinaryEvauation" );

  return $self;

}

sub byPosition{
	return $a->Position() <=> $b->Position();
}

sub printTable{
	my ( $self, $outfile) = @_;
	open ( OUT ,">$outfile") or die root->FileWriteError($outfile) ;
	my $data = $self->{data};
	print OUT @$data[0]->asTableLineHead();
	foreach my $entry (@$data){
		print OUT $entry->asTableLine;
	}
	close (OUT);
	print "Data written to $outfile\n";
	return 1;
}

sub Add_HMM_File{
	my ( $self, $filename ) =@_;
	my ( $data );
	$data = $self->{gffFile}->getEnrichedRegions( $filename, $self->{cutOffProbability});
	$self->{hmmData}->{ "$data->{info}->{CellType} $data->{info}->{AB}" } = $data;
}

sub Add_gbFile{
	my ( $self, $dbString) =@_;
	my ( @temp, $gbFile, @table, $V_segments, $segmentData, $i,$V );
	
	$gbFile = $self->Get_gbFile($dbString);
	$i = 0;
	$segmentData = $self->{data};
	@temp = ("V_segment");
	$V_segments = $gbFile->SelectMatchingFeatures_by_Tag(\@temp);
	$i = @$V_segments;
	print "$i V_segments in file $dbString\n";
	$i = @$segmentData;
	foreach $V (@$V_segments){
		@$segmentData[$i++] = VbinElement->new( $V, $dbString);
	}
	return 1;
}

sub Evaluate{
	my ( $self) = @_;
	my ($hmmData, $segmentData );
	$hmmData = $self->{hmmData};
	$segmentData = $self->{data};
	foreach my $V (@$segmentData){
		foreach my $hmm_data ( values %$hmmData ) {
			$V->matchWithRegion($hmm_data);
		}
	}
	return 1;
}

sub Get_gbFile{
	my ( $self, $dbString) = @_;
	my ( $gbFileName, $gbFile );
	$gbFileName = $self->{fileDB}->SelectMatchingFileLocation(NimbleGene_config->DesignID(), $dbString);
	die "DB string $dbString not found in database!\n" unless ( defined $gbFileName);
	print "Get_gbFile $dbString -> $gbFileName\n";
	return gbFile->new($gbFileName);
}
	
1;
