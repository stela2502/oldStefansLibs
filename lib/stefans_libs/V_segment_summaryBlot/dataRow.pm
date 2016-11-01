package dataRow;
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
use stefans_libs::V_segment_summaryBlot::oligoBin;
use stefans_libs::plot::axis;

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

   my ( $class, $length, $binLength,$end ) = @_;

   die "dataRow->new (atribute[0] = class name, atribute[1] = data range length, atribute[2] = bin length )\n",
       " got ( $class, $length, $binLength ) !\n" if (@_ < 3);

   my ( $self, @bins);

   if ( defined $end) {
      
   }

   $self = {
     binLength => $binLength,
     bins => \@bins,
     lastBin => undef,
     start => undef,
     end => undef,
     max => 0,
     min => 0,
     dataSets => 0
   };

   bless ($self , $class ) if ( $class eq "dataRow");

   my $add = $binLength / 2;

   if ( defined $end) {
      $self->{start} = $length;
      $self->{end} = $end;
   }
   else {
      $self->{start} = 0;
      $self->{end} = $length;
   }

   for (my $i = $self->{start} ; $i <= $self->{end}; $i += $binLength){
      $bins[$self->getBinLocation($i + $add)] = oligoBin->new($i, $i+$binLength -1 );
#      print "New Bin for ",$i + $add,"bp -> ",$self->getBinLocation($i + $add),"\n"; 
   } 

   return $self;
}

sub isRelevantOligo{
	my ( $self, $start) = @_;
	my $testBin = $self->getBinLocation( $start );
	my $bin = $self->{bins};
	#print "dataRow:  isRelevantOligo '$testBin' \n";
	return defined(@$bin[$testBin]);
}

sub startOfNewDataSet{
	my ( $self ) = @_;
	$self->{dataSets} ++;
}

sub printOligoData4Bin_inBP {
	my ( $self, $binBP, $filename) = @_;
	my ( $binNr);
	$binNr = $self->getBinLocation($binBP);
	return $self->printOligoData4Bin($binNr, "$filename");
}
	
sub printOligoData4Bin {
   my ( $self, $binNr, $filename) = @_;
#   open (OUT, ">$filename") or die "Konnte Filename $filename nicht anlegen!\n";
#   open (Oligos, ">$filename.oligoIDs.dat") or die "Konnte Filename $filename.oligoIDs.dat nicht anlegen!\n";

   my ( $oligoValues, $bins, $location);
   $bins = $self->{bins};
   return undef unless ( defined @$bins[$binNr]);
#   $oligoValues = @$bins[$binNr]->{oligoValues};
	($location, $oligoValues) = @$bins[$binNr]->GetOligoReport();
#   foreach my $value (@$oligoValues){
#     print OUT "$value\n";
#   }
#   close (OUT);
#   print "Bin Data for bin nr. $binNr written to file $filename\n";

#   $oligoValues = @$bins[$binNr]->{olgioIDs};
#   foreach my $key (keys %$oligoValues){
#     print Oligos "$key\n";
#   }
#   print "Bin Oligos for bin nr. $binNr written to file $filename.oligoIDs.dat\n";

   return $location, $oligoValues;
}

sub DataCount{
	my ( $self, $n) = @_;
	$self->{dataSets} ++ if ( defined $n);
	return $self->{dataSets};
}

sub getBinLocation{

   my ( $self, $position ) = @_;
   return int(($position- $self->{start}) / $self->{binLength});
#   return int(($position - $self->{start})/ $self->{binLength});
}

sub AddOligo {
   my ( $self, $oligoMean, $oligoValue,  $withMedianCalculation , $oligoID ) = @_;

   my ( $bins);
   $bins = $self->{bins};
   #print "DEBUG $self: Try to add oligo value at bp position $oligoMean\n";
   #$self->{max} = $oligoValue if ( $self->{max} < $oligoValue);
   #$self->{min} = $oligoValue if ( $self->{min} > $oligoValue);
   #print "DEBUG $self: AddOligo: Bin Nr. ",$self->getBinLocation($oligoMean)," was used!\n";
   $self->flush_median( $withMedianCalculation ) if ($self->getBinLocation($oligoMean) > $self->{lastBin} && defined $self->{lastBin});
   $self->{lastBin} = $self->getBinLocation($oligoMean);
   return @$bins[$self->getBinLocation($oligoMean)]->AddOligo($oligoValue, $oligoID) if (defined @$bins[$self->getBinLocation($oligoMean)]);
   warn "ERROR!! no data bin at position $oligoMean\n";
   print "\tpossible bin locations:\n";
   for ( my $i = 0; $i < @$bins; $i++ ){
      if ( defined @$bins[$i]){
          print "\tstart at $i";
		  #last;
	  }	  
   }
   $bins = @$bins;
   
   print "ERROR $self: and end at ", $bins - 1,"\n";
   die "ERROR $self: dies in dataRow AddOligo center [bp] = $oligoMean  gff = $oligoValue, OligoID = $oligoID with oligoBin nr. ",
       $self->getBinLocation($oligoMean),"\n",
}   

sub flush_median {
   my ( $self, $withMedianCalculation ) = @_;
   my ( $bins);
   $bins = $self->{bins};
   @$bins[$self->{lastBin}]->flush_median( $withMedianCalculation ) if ( defined @$bins[$self->{lastBin}]);

}

sub max{
	my ( $self, $max, $stdDev, $stdErr) = @_;
	unless ( defined $self->{max}){
		$self->{max} = $max;
		$self->{max_std} = $max + $stdDev;
		$self->{max_stdErrMean} = $max + $stdErr;
	}
	if ( defined $max){
		$self->{max} = $max if ( $self->{max} < $max);
		$self->{max_std} = $max + $stdDev if ( $self->{max_std} < $max + $stdDev);
		$self->{max_stdErrMean} = $max + $stdErr if ( $self->{max_stdErrMean} < $max + $stdErr);
	}
	return $self->{max}, $self->{max_dev}, $self->{max_stdErrMean};
}

sub min{
	my ( $self, $min, $stdDev, $stdErr) = @_;
	unless ( defined $self->{min}){
		$self->{min} = $min;
		$self->{min_std} = $min - $stdDev;
		$self->{min_stdErrMean} = $min - $stdErr;
	}
	if ( defined $min){
		$self->{min} = $min if ( $self->{min} > $min);
		$self->{min_std} = $min - $stdDev if ( $self->{min_std} > $min - $stdDev);
		$self->{min_stdErrMean} = $min - $stdErr if ( $self->{min_stdErrMean} > $min - $stdErr);
	}
	return $self->{min}, $self->{min_dev}, $self->{min_stdErrMean};
}

sub getAsPlottable{
	my ( $self ) = @_;
	my ( $bins, @return, $pos, $val, $std, $n, $a );
	$a = 0;
	$bins = $self->{bins};
	for( my $i = $self->getBinLocation($self->{start}); $i <= $self->getBinLocation($self->{end}) ; $i++){ 
		next unless ( defined @$bins[$i]);
		
		my $hash;
		($hash->{bp}, $hash->{mean}, $hash->{stdDev}, $hash->{median}, $hash->{oligoCount}, $hash->{stdErrMean}, $n ) 
			= @$bins[$i]->GetValues();
		$self->max($hash->{mean}, $hash->{stdDev},$hash->{stdErrMean});
		$self->min($hash->{mean}, $hash->{stdDev},$hash->{stdErrMean});	
		
		$return[$a++] = $hash;
	}
#	print "\tlittle test $return[0]->{mean} $return[0]->{stdDev}\ndataRow get as plottable max = $self->{max} (std_max = $self->{max_std})",
#	" min = $self->{min} (std_min = $self->{min_std})\n";
	return \@return;
}
 

sub GetAsTableLine{
	my ( $self) = @_;
	my $bins = $self->{bins};
	die "dataRow GetAsTableLine is not possible due to mor than one Data point in the row!\n" if ( @$bins > 2);
	my ($pos, $val, $std , $median) = @$bins[$self->getBinLocation($self->{start} + 1)]->GetValues();
	#print "Got Values $median, $std\n";
	return $val, $std;
}

sub GetAsLineArray_inBP{

	my ( $self, $position) = @_;
	my ( $Aposition, $mean, $StandartAbweichung, $median, $oligoValues, $stdErrMean, $bins);
	$bins = $self->{bins};
	( $Aposition, $mean, $StandartAbweichung, $median, $oligoValues, $stdErrMean) =  
		@$bins[$self->getBinLocation($position)]->GetValues();
	return $Aposition, $mean, $StandartAbweichung,$stdErrMean;
}

sub GetAsLineArray {
   ## return the data as 4 array references 1. binLocations
   my ( $self ) = @_;

   my ( $bins, @position,@values,@stdAbw, $pos, $val, $std, $median );
   $bins = $self->{bins};

   for( my $i = $self->getBinLocation($self->{start}); $i <= $self->getBinLocation($self->{end}) ; $i++){
       ($pos, $val, $std , $median) = @$bins[$i]->GetValues();
       $position[$i] =  $pos;
       $values[$i] = $val;
       $stdAbw[$i] = $std;
  }
  return \@position, \@values, \@stdAbw;
}

1;
