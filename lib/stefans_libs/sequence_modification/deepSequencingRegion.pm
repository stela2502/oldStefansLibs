package deepSequencingRegion;
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

use stefans_libs::gbFile::gbFeature;
use stefans_libs::plot::simpleBarGraph;
use stefans_libs::sequence_modification::deepSeq_region;

@ISA = qw(gbFeature);
use strict;

sub new{

	my ( $class, $DeepSeqID, $firstRead, $secondRead ) = @_;

	my ( $self, @reads, $regionString );
	warn "without deep Seq ID, the resulting information will be almoast worthless!\n"
		unless ( defined $DeepSeqID);
	
	@reads = ($firstRead, $secondRead );
	
	$self = {
		deepSeqID => $DeepSeqID,
		numberOfReads => 2,
		region => deepSeq_region->new(),
		deepReads => \@reads,
		barGraph => simpleBarGraph->new()
  	};
  	
  	$self->{region}->Add2Region($firstRead);
  	$self->{region}->Add2Region($secondRead);

  	bless $self, $class  if ( $class eq "deepSequencingRegion" );

  	return $self;

}

sub AddDeepRead{
	my ( $self, $read) = @_;
	
	$self->{deepReads}[$self->{numberOfReads}++] = $read if ( defined $read);
	#$self->{barGraph}->addRead($read->startOnQuery(),$read->endOnQuery() );
	
	return 1;
}

=head2 getForDrawing

=head3 return values

Returns a refernect to a array with the structure ( { start => { lower = mean = upper = <int> }, end => { lower = upper = mean = <int>} } )

=cut

sub getAsPlottable {
	my ( $self ) = @_;
}

=head2 getAsGB

=head3 atributes

[0]: start in basepairs

[1]: end in basepairs

=head3 return value

Returns the text string representing this gbFeature in genbank format

=cut

sub getAsGB {
	my ( $self ) =@_;
	my $temp = $self->asGBfeature();
	return $temp->getAsGB();	
}

sub asGBfeature{
	my ( $self ) = @_;
	my $meanReadCount= $self->meanReadCount();
	my $deepReads = $self->{deepReads};
	my @array;
	foreach my $read ( @$deepReads){
		push (@array, $read->{subjectID});
	}
	my $allReads = join (", ", (@array));
	
	my $gbFeature = gbFeature->new( "unsure", $self->{region}->Print(0, 5*10e+9 ) );
	$gbFeature->AddInfo("gene", "newly identifed in deep_seq_run $self->{deepSeqID}");
	$gbFeature->AddInfo("note", "match to $self->{numberOfReads} contigs");
	$gbFeature->AddInfo("note", "mean read count = $meanReadCount");
	$gbFeature->AddInfo("note", "reads: $allReads");
	return $gbFeature;
}

sub meanReadCount{
	my ( $self) = @_;
	my $array = $self->{deepReads};
	my $value = 0;
	foreach my $read (@$array){
		$value += $read->Coverage();
	}
	return $value / @$array;
}

1;
