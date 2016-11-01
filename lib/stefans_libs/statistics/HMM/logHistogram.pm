package logHistogram;
 
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
 
 use stefans_libs::statistics::new_histogram;
 use stefans_libs::root;
 @ISA = qw(new_histogram);
 
 use strict;
 use warnings;
 
 sub new {
 
 	my ( $class, $title ) = @_;
 
 	my ( $self, $root, $hash );
 
 	$self = {
 		title => $title,
 		root  => root->new()
 	};
 
 	bless $self, $class if ( $class eq "logHistogram" );
 
 	return $self;
 
 }
 
 sub log2 {
 	my ($value) = @_;
 	return log($value) / log(2);
 }
 
 sub initialize {
 	my $self = shift;
 
 	#that will become quite complex!
 	# 1. we use a log2!
 	# 2. we have to rescale our data to $self->Category_steps values!
 	#    to avoid negativ or 0 values, we have to think first!
 	#    the best will be to start with values >1 - or?
 	my $value2add = 1 - $self->Min();
 	my ( @cutoff_values, $rescalefactor );
 	$rescalefactor = 1;
 	for ( my $i = 1 ; $i <= $self->Category_steps() ; $i++ ) {
 		push( @cutoff_values, 2**$i );
 	}
 	## OK now we have to add the value $value2add to each value and second we have to rescale the values to
 	## get to a maximum of @cutoff_values[@cutoff_values-1]
 	## and the whole thing has to be made transparent - only for the region definition!
 	if ( $self->Min < 1 ) {
 		die "Sorry - no support for values below 1 :-( (",$self->Min(),")\n";
 	}
 	if ( $self->Max != $cutoff_values[ @cutoff_values - 1 ] ) {
 		warn
 "we rescale the values to fitt into the range $cutoff_values[0] tp $cutoff_values[@cutoff_values-1]\n";
 		$rescalefactor = $cutoff_values[ @cutoff_values - 1 ] / $self->Max();
 	}
 
 	my ( @array, $hash );
 	$self->{data} = $hash;
 	$self->{bins} = \@array;
 
 	for ( my $i = 0 ; $i < @cutoff_values ; $i++ ) {
 		push(
 			@array,
 			{
 				category => ($cutoff_values[$i+1] / $rescalefactor + $cutoff_values[$i] / $rescalefactor)/ 2,
 				max      => $cutoff_values[$i+1] / $rescalefactor,
 				min      => $cutoff_values[$i] / $rescalefactor
 			}
 		);
 		$self->{data}->{ ($cutoff_values[$i+1] / $rescalefactor + $cutoff_values[$i] / $rescalefactor)/ 2 } = 0;
 	}
 	return 1;
 }
 
 1;
