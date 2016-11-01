package deepSeq_region;

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

use stefans_libs::gbFile::gbRegion;

@ISA = qw(gbRegion);
use strict;

sub new {

	my ( $class, $region ) = @_;

	my ( @items, @regions );
	my $self = { items => \@items, regions => \@regions };

	bless $self, $class if ( $class eq "deepSeq_region" );

	$self->Region($region);

	return $self;

}

sub Add2Region {
	my ( $self, $deepSeq_blastLine ) = @_;

	my $regions = $self->{regions};

	if (
		$self->matchWithRegion(
			$deepSeq_blastLine->startOnQuery(),
			$deepSeq_blastLine->endOnQuery(),
			0
		)
	  )
	{
		## enlarge a own region.
		foreach my $region (@$regions) {
			if (   $region->{start} < $deepSeq_blastLine->endOnQuery()
				&& $region->{end} > $deepSeq_blastLine->startOnQuery() )
			{
				$region->{start} = $deepSeq_blastLine->startOnQuery()
				  if ( $region->{start} > $deepSeq_blastLine->startOnQuery() );
				$region->{end} = $deepSeq_blastLine->endOnQuery()
				  if ( $region->{end} < $deepSeq_blastLine->endOnQuery() );
				last;
				print
"deepSeq_region enlarged region $region->{start}..$region->{end}\n";
			}
		}
	}
	else {
		## new region!
		my $new = {
			start => $deepSeq_blastLine->startOnQuery(),
			end   => $deepSeq_blastLine->endOnQuery(),
			tag   => "normal"
		};
		unless ( defined @$regions ){
			$self->Region( "$new->{start}..$new->{end}" );
			print "the actual region: ",$self->Print(0, $new->{end} + 200 ),"\n";
			return 1;
		}

		push( @$regions, $new );
		$self->Region( $self->Print(0, $new->{end} + 200) );
		print "deepSeq_region added a new region $new->{start}..$new->{end}\n";
	}
	print "the actual region: ",$self->Print(0,5*10e+9),"\n";
	return 1;
}

1;
