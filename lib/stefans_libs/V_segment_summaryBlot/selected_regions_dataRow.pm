package selected_regions_dataRow;
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

use stefans_libs::V_segment_summaryBlot::oligoBin;
use stefans_libs::V_segment_summaryBlot::dataRow;
use stefans_libs::plot::axis;

@ISA = qw(dataRow);

use strict;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::V_segment_summaryBlot::dataRow

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

=head3 retrun values

A object of the class dataRow

=cut

sub new {

	my ( $class, $length, $binLength, $end, $gbFile, $matching_gbTags ) = @_;

#die "dataRow->new (atribute[0] = class name, atribute[1] = data range length, atribute[2] = bin length )\n",
#    " got ( $class, $length, $binLength ) !\n" if (@_ < 3);

	my ( $self, @bins, $gbFeatures, $temp );

	#root::print_hashEntries( $matching_gbTags, 2,
	#	"$self->new got matchingStrings '$matching_gbTags'\n" );

	$self = {
		binLength => $binLength,
		bins      => \@bins,
		lastBin   => undef,
		start     => undef,
		end       => undef,
		max       => 0,
		min       => 0,
		dataSets  => 0
	};

	bless( $self, $class ) if ( $class eq "selected_regions_dataRow" );

	my $add = $binLength / 2;

	if ( defined $end ) {
		$self->{start} = $length;
		$self->{end}   = $end;
	}
	else {
		$self->{start} = 0;
		$self->{end}   = $length;
	}

	if ( defined @$matching_gbTags[0] ) {
		$gbFeatures = $gbFile->SelectMatchingFeatures($matching_gbTags);
		$self->{bins} =
		  $self->createBinArray( $binLength, $matching_gbTags, $add,
			$gbFeatures, $gbFile );

	print "\nDEBUG $self: new with matching_gbTags:\n\t", join("\n\t",@$matching_gbTags),"\n";
	print "we got the gbFile ",$gbFile->Name(),"\n";

	}

	unless ( defined @$matching_gbTags[0] ) {
		for ( my $i = $self->{start} ; $i <= $self->{end} ; $i += $binLength ) {
			$bins[ $self->getBinLocation( $i + $add ) ] =
			  oligoBin->new( $i, $i + $binLength -1);

#print "DEBUG $self: New Bin for ",$i + $add,"bp -> ",$self->getBinLocation($i + $add),"\n";
		}
	}
	return $self;
}

sub createBinArray {
	my ( $self, $regionRadius, $matching_gbTags, $add, $gbFeatures, $gbFile ) =
	  @_;

	my ( $temp, $region, @bins );

	foreach my $gbFeature (@$gbFeatures) {
		$temp = 0;
		foreach my $string (@$matching_gbTags) {
			$temp = 1 if ( $gbFeature->Name =~ m/$string/i );
			$temp = 1 if ( $temp == 0 && $gbFeature->Tag eq $string );
		}
		next if ( $temp == 0 );
		my $hash = {
			gbFile     => $gbFile,
			tag        => $gbFeature->Tag(),
			name       => $gbFeature->Name(),
			complement => $gbFeature->IsComplement()
		};
		$region = $gbFeature->getRegionForDrawing();
		if ( $hash->{tag} eq "V_segment" ) {
			if ( @$region == 1 ) {
				$hash->{start}    = @$region[0]->{start};
				$hash->{end}      = @$region[0]->{start} + $regionRadius;
				$hash->{gbFeatue} = $gbFeature;
			}
			if ( @$region == 2 ) {
				$hash->{start}    = @$region[1]->{start};
				$hash->{end}      = @$region[1]->{start} + $regionRadius;
				$hash->{gbFeatue} = $gbFeature;
			}
			die "Unexprected Problem: the V segment ", $gbFeature->Name(),
			  " had more that 2 exons!"
			  if ( @$region > 2 );
		}
		else {
			$hash->{start}    = @$region[0]->{start};
			$hash->{end}      = @$region[0]->{start} + $regionRadius;
			$hash->{gbFeatue} = $gbFeature;
		}
		next
		  unless ( $self->{start} <= $hash->{start}
			&& $hash->{end} < $self->{end} );

#print "DEBUG $self: bin created at $hash->{start} bp (",$self->getBinLocation( $hash->{start} + $add ),")\n";
		$bins[ $self->getBinLocation( $hash->{start} + $add ) ] =
		  oligoBin->new( $hash->{start}, $hash->{end} );
	}
	return \@bins;
}

sub max {
	my ( $self, $max, $stdDev, $stdErr ) = @_;
	unless ( defined $self->{max} ) {
		$self->{max}            = $max;
		$self->{max_std}        = $max + $stdDev;
		$self->{max_stdErrMean} = $max + $stdErr;
	}
	if ( defined $max ) {
		$self->{max} = $max if ( $self->{max} < $max );
		$self->{max_std} = $max + $stdDev
		  if ( $self->{max_std} < $max + $stdDev );
		$self->{max_stdErrMean} = $max + $stdErr
		  if ( $self->{max_stdErrMean} < $max + $stdErr );
	}
	return $self->{max}, $self->{max_dev}, $self->{max_stdErrMean};
}

sub min {
	my ( $self, $min, $stdDev, $stdErr ) = @_;
	unless ( defined $self->{min} ) {
		$self->{min}            = $min;
		$self->{min_std}        = $min - $stdDev;
		$self->{min_stdErrMean} = $min - $stdErr;
	}
	if ( defined $min ) {
		$self->{min} = $min if ( $self->{min} > $min );
		$self->{min_std} = $min - $stdDev
		  if ( $self->{min_std} > $min - $stdDev );
		$self->{min_stdErrMean} = $min - $stdErr
		  if ( $self->{min_stdErrMean} > $min - $stdErr );
	}
	return $self->{min}, $self->{min_dev}, $self->{min_stdErrMean};
}

sub getAsPlottable {
	my ($self) = @_;
	my ( $bins, @return, $pos, $val, $std, $n, $a );
	$a    = 0;
	$bins = $self->{bins};
	for (
		my $i = $self->getBinLocation( $self->{start} ) ;
		$i <= $self->getBinLocation( $self->{end} ) ;
		$i++
	  )
	{
		next unless ( defined @$bins[$i] );

		my $hash;
		(
			$hash->{bp}, $hash->{mean}, $hash->{stdDev}, $hash->{median},
			$hash->{oligoCount}, $hash->{stdErrMean}, $hash->{n}, $hash->{start}, $hash->{end} 
		) = @$bins[$i]->GetValues();
		$self->max( $hash->{mean}, $hash->{stdDev}, $hash->{stdErrMean} );
		$self->min( $hash->{mean}, $hash->{stdDev}, $hash->{stdErrMean} );

		$return[ $a++ ] = $hash;
	}

#	print "\tlittle test $return[0]->{mean} $return[0]->{stdDev}\ndataRow get as plottable max = $self->{max} (std_max = $self->{max_std})",
#	" min = $self->{min} (std_min = $self->{min_std})\n";
	return \@return;
}

sub GetAsTableLine {
	my ($self) = @_;
	my $bins = $self->{bins};
	die
"dataRow GetAsTableLine is not possible due to mor than one Data point in the row!\n"
	  if ( @$bins > 2 );
	my ( $pos, $val, $std, $median ) =
	  @$bins[ $self->getBinLocation( $self->{start} + 1 ) ]->GetValues();

	#print "Got Values $median, $std\n";
	return $val, $std;
}

1;

