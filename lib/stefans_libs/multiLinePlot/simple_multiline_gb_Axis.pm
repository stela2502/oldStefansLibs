package simple_multiline_gb_Axis;
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

use stefans_libs::multiLinePlot::multiline_gb_Axis;
use stefans_libs::multiLinePlot::XYvalues;

@ISA = qw(multiline_gb_Axis);

use strict;

sub new{

my ( $class, $gbFile, $start, $end, $x1, $y1, $x2, $y2, $resolution, $color)
	= @_;
	
	my ( $self, $axis_title );
	
	$self = {
		usePrimer_Tag => 1 == 0,
		#usePrimer_Tag => 1 == 1,
		useOnlyJ558 =>  1 == 1,
		#useOnlyJ558 =>  1 == 0,
		use_genes => 1 == 0,
		color => $color,
		gbFile => $gbFile,
		start			 => $start,
		end				 => $end,
		tics             => 6,
		max_pixel        => $x2,
		min_pixel        => $x1,
		y1               => $y1,
		y2               => $y2,
		space_between_the_transciption_arrows => 10,
		axis_title       => $axis_title
	};
	$self->{x_axis} = multi_axis->new("x",$x1, $x2, $axis_title, $resolution);
	$self->{x_axis}->Bp_Scale(1);
	
    if ( $resolution eq "max" ) {
#        $self->{tics}       = 10;
        $self->{tic_length} = 20;
        $self->{font}       = Font->new($resolution);
    }
    if ( $resolution eq "med" ) {
 #       $self->{tics}       = 8;
        $self->{tic_length} = 13;
        $self->{font}       = Font->new($resolution);
    }
    if ( $resolution eq "min" ) {
 #       $self->{tics}       = 6;
        $self->{tic_length} = 7;
        $self->{font}       = Font->new($resolution);
	}
	
	bless $self, $class  if ( $class eq "simple_multiline_gb_Axis" );
	$self->min_value($start);
	$self->max_value($end);
#	print "New multiline_gb_Axis min = ", $self->min_value()," max = ", $self->max_value(),"\n";
	return $self;
}

sub UseRegion {
    my ( $self, $region ) = @_;
    my ( @usedRegions, $use, $tag, $temp );
	
    @usedRegions = (
					#"enhancer",     
					"V_region",  "V_segment", "J_segment",
					"D_segment",    "C_segment", "C_region" #, "gene", "mRNA"
					);
    $use = 0;
    $tag = $region->Tag();
    foreach $temp (@usedRegions) {
        if ( $temp =~m/$tag/ ) {
            $use = 1;
            last;
        }
    }
	return $use;
}

sub plot{
	my ( $self, $im, $font) = @_;
	my ( $GBregions, $plotSite, $name, $color, $meanX, $start, $end, @temp, $locations);
	
	unless ( defined $self->{gbFile} ) {
		print "simple_multiline_gb_Axis: this is a final blow! no gbFile in MultiLinePlot!\n";
		return -1;
	}
	$self->{x_axis}->plot($im, $font);
	$GBregions = $self->{gbFile}->Features();
	$self->{font} = $font if ( defined $font);
	$self->{act_y1} = $self->{_y1} = $self->{y1} + ($self->{y2} - $self->{y1}) / 40;
	$self->{act_y2} = $self->{_y2} = $self->{y1} + ($self->{y2} - $self->{y1}) * 19 / 40;
	$self->{down_y1} = $self->{y1} + ($self->{y2} - $self->{y1}) * 21 / 40;
	$self->{down_y2} = $self->{y1} + ($self->{y2} - $self->{y1}) * 39 / 40;
	$self->{_mean} = $self->{act_y1} + ($self->{act_y2} -$self->{act_y1}) / 2;
	
	#$im->rectangle($self->{min_pixel}, $self->{y1}, $self->{max_pixel},$self->{y2},$self->{color}->{black});
#	$im->line($self->{min_pixel}, $self->{y2}, $self->{max_pixel},$self->{y2},$self->{color}->{grey});
	
	foreach my $region (@$GBregions) {
		next if ( $region->Start() > $self->max_value() || $region->End() < $self->min_value());
		next if ( $self->UseRegion($region) == 0 );

		$self->{mean} = $self->{_mean};
		$self->{actLoc} = "sense";
		
		if ( $region->Tag() eq "gene" ) {
		
			next unless ( $self->{use_genes} );
			$name = $region->Name();
			if ( $name =~ m/".*/ ) { #"
			   @temp = split ( '"', $name);
			   $name = $temp[1];
			}
#			$im->setBrush($self->createBrush($self->{color}->{black}, $self->{actLoc}));
#			$im->setStyle($self->{color}->{black},$self->{color}->{black},$self->{color}->{black},#
#			$self->{color}->{black},$self->{color}->{black}, gdStyledBrushed);			
#
#			$meanX = $self->drawLine($im, $region->Start(), $region->End(),gdStyledBrushed );
			$meanX = $self->drawLine($im, $region->Start(), $region->End(),$self->{color}->{black});
			# next if ( $region->ExprStart() < $self->min_value() || $region->ExprStart() > $self->max_value());
            $start = $region->Start();
			$end = $region->End();
			$start = $self->min_value() if ( $start < $self->min_value());
			$end = $self->max_value if ( $end > $self->max_value());

#			warn "multiline_gb_axis does not plot the feature names in this configuration!\n";
#			next;

			$self->{font}->plotString_FitIntoX_range_leftEnd($im,$name, $self->resolveValue($start),
												  $self->resolveValue($end),
												  $self->{down_y2} - 3, $self->{color}->{black}, "gbfeature");
		}
		if ( $self->IsIG_region($region->Tag() )){
			if ( $self->{useOnlyJ558} ){
				next unless ( $region->Name() =~ m/J558/ ); 
			}
			
			( $name, $color ) = $self->{color}->getIg_Values($region);
			unless ( defined $locations->{ $region->Tag()}){
				print "\n\nWe create a new location entry\n\n";
				$locations->{ $region->Tag()} = { start => $region->Start(), end => $region->End(), color => $color };
			}
			else{
				$locations->{ $region->Tag()}->{end} = $region->End();
			}
			$meanX = $self->drawLine($im, $region->Start(), $region->End(), $color) ;#gdStyledBrushed );
			$self->drawBox($im,$region,$color);
		}
		if ( $region->Tag() =~ m/mRNA/ || $region->Tag() eq "exon" ) {
			#print "Got a mRNA\n";
			next;
			$self->drawSmallBox($im,$region);
		}
		if ( $region->Tag() eq "CDS" ) {
#		    print "got a CDS!\n";
			$self->drawBox($im,$region);
		}
		if ( $region->Tag() eq "primer_bind" ) {
		
			next unless ($self->{usePrimer_Tag});
			$meanX = $self->drawLine($im, $region->Start(), $region->End(),$self->{color}->{dark_blue});
			# next if ( $region->ExprStart() < $self->min_value() || $region->ExprStart() > $self->max_value());
            $start = $region->Start();
			$end = $region->End();
			$start = $self->min_value() if ( $start < $self->min_value());
			$end = $self->max_value if ( $end > $self->max_value());

#			warn "multiline_gb_axis does not plot the feature names in this configuration!\n";
#			next;
			( $name, $color ) = $self->{color}->getIg_Values($region);
			$name = $region->Name();
			$name = $1 if ( $name =~ m/lcl\|(.+)/);
			$self->{font}->plotString_FitIntoX_range_leftEnd($im,$name, $self->resolveValue($start),
												  $self->resolveValue($end),
												  $self->{act_y1}, $self->{color}->{dark_blue}, "gbfeature")
												  if ($region->ExprStart() == $region->End()) ;			
			$self->{font}->plotString_FitIntoX_range_rightEnd($im,$name,  $self->resolveValue($start),
												  $self->resolveValue($end),
												  $self->{not_y1}, $self->{color}->{dark_blue}, "gbfeature")
												  if ($region->ExprStart() == $region->Start()) ;
		}
	}
	my $string;
	foreach my $IgFeatureType ( keys %$locations ){
		print "We plot the feature Type $IgFeatureType beween bp $locations->{$IgFeatureType}->{start}",
			" and $locations->{$IgFeatureType}->{end}\n";
		$im->line( $self->resolveValue($locations->{$IgFeatureType}->{start}), $self->{_y2}, 
			 $self->resolveValue($locations->{$IgFeatureType}->{end}), $self->{_y2}, $locations->{$IgFeatureType}->{color} ) 
			 unless ($IgFeatureType eq "enhancer");
		$string = "$1 cluster" if ( $IgFeatureType =~ m/^([VDJC])_/ );
		$self->{font}->plotStringCenteredAtX($im, $string, 
			($self->resolveValue($locations->{$IgFeatureType}->{start})+ 
			$self->resolveValue($locations->{$IgFeatureType}->{end})) /2,
			$self->{down_y2} - 3  , $locations->{$IgFeatureType}->{color}, "gbfeature") unless ($IgFeatureType eq "enhancer");
	}
	## plot the gaps:
	$self->{x_axis}->plot_holes($im, $self->{y1}, $self->{y2}, $self->{color});
	## plot the lines arround the axis:
	$im->line($self->{min_pixel}, $self->{y1},$self->{min_pixel},$self->{y2},$self->{color}->{black});
	$im->line($self->{max_pixel}, $self->{y1},$self->{max_pixel},$self->{y2},$self->{color}->{black});
	$self->{x_axis}->plot_simple_base_line($im,$self->{y1},$self->{color}->{black});
	$self->{x_axis}->plot($im,$self->{y2},$self->{color}->{black});
}



1;
