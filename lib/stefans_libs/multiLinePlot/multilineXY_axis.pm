package multilineXY_axis;
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

use stefans_libs::V_segment_summaryBlot::NEW_GFF_data_Y_axis;
use stefans_libs::multiLinePlot::XYvalues;

@ISA = qw(NEW_GFF_data_Y_axis);

use strict;

sub new {

    my ( $class, $line, $what ) = @_;

    my ( @antibodyOrder, $self, %data, @cellTypes );
    warn "Use of multilineXY_axis is deprecated!\n";

    @cellTypes = (

        #{ matchingString => "", plotString => "" },
        { matchingString => "prob\$",   plotString => "proB cells" },
        { matchingString => "prot",     plotString => "proT cells" },
        { matchingString => "dc",       plotString => "dendritic cells" },
        { matchingString => "prob il7", plotString => "proB cells (IL7)" },
        { matchingString => "preb il7", plotString => "preB cells (IL7)" }
    );

    @antibodyOrder = ( 
		{ matchingString => "h3ac"   , plotString => "H3Ac"},
		{ matchingString => "h3k4me2", plotString => "H3K4Me2"},
		{ matchingString => "h3k9me3", plotString => "H3K9Me3"} 
	);

    $self = {
        cellTypes     => \@cellTypes,
        antibodyOrder => \@antibodyOrder,
        plotLable     => 1 == 0,
        data          => \%data,
        UseMean       => 1 == 1,
        binLength     => 200,
        max           => undef,
        useStdDev     => 1 == 0,

        #     flushMedian => 1 == 1,
        flushMedian     => 1 == 0,
        min             => undef,
        max_std         => undef,
        min_std         => undef,
        max_oligo_count => 5
    };

  bless $self, $class  if ( $class eq "multilineXY_axis" );

  return $self;

}

sub AddTabellaricData{
	my ( $self, $hash ) = @_;
	
	foreach my $arrayID ( keys %$hash){
		unless ( defined $self->{data}->{$arrayID}){
			$self->defineArrayType ( $arrayID );
			print "Add Data for Array ID $arrayID\n";
		}
		$self->{data}->{$arrayID}->{data}->AddValues($hash->{$arrayID});
		$self->Max( $self->{data}->{$arrayID}->{data}-> Max ( $self->Max() ) ) unless ( $self->{useStdDev} );
		$self->Max( $self->{data}->{$arrayID}->{data}-> Max_StdErr ( $self->Max() ) ) if ( $self->{useStdDev} );
		$self->Min( $self->{data}->{$arrayID}->{data}-> Min ( $self->Min() ) ) unless ( $self->{useStdDev} );
		$self->Min( $self->{data}->{$arrayID}->{data}-> Min_StdErr ( $self->Min() ) ) if ( $self->{useStdDev} );
		print " $self AddTabellaricData min = ",$self->Min()," max = ",$self->Max(),"\n";
	}
	return 1;
}

sub getAsPlottable{
	my ( $self ) = @_;
	my $data = $self->{data};
	my @return;
	foreach my $dataSet ( values %$data){
		push(@return, $dataSet);
	}
	return \@return;
}

sub defineArrayType{
	my ( $self, $arrayID) = @_;
	my $dataPoint;
	#2005-09-08_RZPD1538_MM6_ChIPH3K4Me2Mus musculus:Rag KO proB
	$dataPoint -> {designString} = $1 if ( $arrayID =~ m/(\d\d\d\d-\d\d-\d\d_RZPD\d\d\d\d_MM\d_ChIP)/);
	$dataPoint -> {antibodySpecificity} = $1 if ( $arrayID =~ m/ChIP(.+)Mus/);
	$dataPoint -> {Organism} = "Mus musculus";
	$dataPoint -> {cellType} = $1 if ( $arrayID =~ m/us:(.+)$/);
	$dataPoint -> {data} = XYvalues->new();
	$dataPoint -> {ID} = $arrayID;
	$self->{data}->{$arrayID} = $dataPoint;
	#print "defineArrayType for arrayID $arrayID:\n";
	#foreach my $keys ( keys %$dataPoint ){
	#	print "\t$keys -> $dataPoint->{$keys}\n";
	#}
	return 1;
}

sub Plot_DataPoints {
    my ( $self, $Y_data, $X, $Y, $color ) = @_;
    my (
        $i,             $tokens,      $colors, $data,
        $last,          $act,         $lastBP,
		$antibodyOrder
    );
	print "$self : Plot_DataPoints max = ",$self->Max(),", min = ", $self->Min,"\n";
    $i             = 0;
    $antibodyOrder = $self->{antibodyOrder};
    $self->{im}->setThickness(1);
	$data = $Y_data->{data}->getData_withSEM();
	
	
#		print "color for $hybType->{cellType}, $hybType->{antibodySpecificity} = $color\n";
	foreach my $position (%$data) {
		next if ( $position < $X->min_value || $position > $X->max_value);		
		next if ( $data->{$position}->{mean} == 0 && $data->{$position}->{sem} == 0 );
		$act = {
			x   => $X->resolveValue( $position ),
			y   => $Y->resolveValue( $data->{$position}->{mean} ),
			min => $Y->resolveValue(
									$data->{$position}->{mean} - $data->{$position}->{sem}
									),
			max => $Y->resolveValue(
									$data->{$position}->{mean} + $data->{$position}->{sem}
									)
		};
	my $rautengroesse = 6;	
	$self->plot_a_Raute ($color, $act->{x}, $act->{y}, $rautengroesse, $color);
	}
	$self->{im}->setThickness(1);
}

sub Plot_StdErrMean {
    my ( $self, $Y_data, $X, $Y, $color ) = @_;
    my ( $data, $act, $position );
	
    $self->{im}->setThickness(1);
	
	$data = $Y_data->{data}->getData_withSEM();
	
	foreach my $oligoBinRep (@$data) {
		next if ( $position < $X->min_value || $position > $X->max_value);
		next if ( $data->{$position}->{mean} == 0 && $data->{$position}->{sem} == 0 );
		$act = {
			x   => $X->resolveValue( $position ),
			y   => $Y->resolveValue( $data->{$position}->{mean} ),
			min => $Y->resolveValue(
									$data->{$position}->{mean} - $data->{$position}->{sem}
									),
			max => $Y->resolveValue(
									$data->{$position}->{mean} + $data->{$position}->{sem}
									)
		};
		
		$self->{im}
		->line( $act->{x}, $act->{max}, $act->{x}, $act->{min}, $color );
		
		$self->{im}->line(
						  $act->{x} - 3, $act->{min}, $act->{x} + 3, $act->{min},
						  $color
						  );
		$self->{im}->line(
						  $act->{x} - 3, $act->{max}, $act->{x} + 3, $act->{max},
						  $color
						  );
	}
	return 1;
}

sub plot_a_Raute {
	my ($self, $x, $y, $RautenGroesse, $color) = @_;

	## wir malen eine Raute!!
	$RautenGroesse = 6 unless ( defined $RautenGroesse);
	
	my ( $y_start, $y_end );
	for ( my $xr = -$RautenGroesse ; $xr <= $RautenGroesse ; $xr++ ) {
		$y_end = $RautenGroesse - ( $xr**2 )**0.5;
		$y_start = -$y_end;
		for ( my $yr = $y_start ; $yr <= $y_end ; $yr++ ) {
			$self->{im}->setPixel( $x + $xr, $y + $yr, $color );
		}
	}

	#print "\n";
	return 1;
}

1;
