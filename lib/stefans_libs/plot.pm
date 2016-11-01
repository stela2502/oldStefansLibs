package plot;
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
use GD::SVG;
use stefans_libs::plot::axis;
use stefans_libs::root;
use stefans_libs::NimbleGene_config;
use stefans_libs::root;
use stefans_libs::plot::legendPlot;
use stefans_libs::plot::gbAxis;
use stefans_libs::plot::Font;
use stefans_libs::plot::color;
#use stefans_libs::multiLinePlot::multiline_gb_Axis;

sub new() {

    my ( $class, $pathModifier ) = @_;

    my ( @data, @info );
    my $self = {
        #use_V_segment_colors => 1 == 1,
		use_V_segment_colors => 1 == 0,
        max_override => 4.0,
        min_override => -1.5,
        #useStdDev => 2 == 2,
        useStdDev  => 2 == 1,
        #resolution => "max",
        resolution => "med",
        #resolution       => "min",
        width   => undef,    #1000,
        height  => undef,    #750,
        data    => undef,
        x_title => undef,
        y_title => undef,
        legend  => undef,    #legendPlot->new,
        font    => undef,
        info    => undef
    };

    if ( $self->{resolution} eq "max" ) {
        $self->{width}             = 1500;
        $self->{height}            = 1000;
        $self->{font}              = Font->new( $self->{resolution} );
        $self->{tokenX_correction} = 8;
        $self->{tokenY_correction} = -9;
    }
    elsif ( $self->{resolution} eq "min" ) {
        $self->{width}  = 500;
        $self->{height} = 333;
        $self->{font}   = Font->new( $self->{resolution} );
    }
    elsif ( $self->{resolution} eq "med" ) {
        $self->{width}  = 1000;
        $self->{height} = 666;
        $self->{font}   = Font->new( $self->{resolution} );
    }

    $self->{legend} = legendPlot->new( $self->{resolution} );

    my $today = root->Today();
    my $path  = NimbleGene_config::DataPath();
    $path = "$path/Graphical_Summary_Report/$today";
    mkdir($path);

    $self->{OUTpath} = "$path/$pathModifier";
    root->CreatePath( $self->{OUTpath} );

#    print "plot outPath = $self->{OUTpath}\n";

    bless $self, 'plot' if ( $class eq "plot" );

    return $self;
}

sub AddRows {

    my ( $self, $GFF_data_Y_axis, $title ) = @_;

    my ( $dataArray, $InfoArray );
    $self->{data} = $GFF_data_Y_axis
      if ( $GFF_data_Y_axis =~ m/GFF_data_Y_axis/
        && !defined( $self->{data} ) );
    die "AddRows needs a object of the class GFF_data_Y_axis!\n"
      unless ( $GFF_data_Y_axis =~ m/GFF_data_Y_axis/ );
    $self->{y_title} = $title if ( defined $title );
    return 1;
}

sub AddGbFeatureInfos {
    my ( $self, $gbFeature_X_axis, $title, $start, $end ) = @_;
    $self->{start} = $start;
    $self->{end}   = $end;
#    print "plot->AddGbFeatureInfos got ( $self, $gbFeature_X_axis, $title )\n";
    $self->{Info} = $gbFeature_X_axis
      if ( defined $gbFeature_X_axis && !defined( $self->{Info} ) );
    $self->{x_title} = $title if ( defined $title );
    return 1;
}

sub LegendVisible {
    my ( $self, $value ) = @_;
    if ( defiend $value ) {
        $self->{legendVisible} = 1 == 1;
    }
    return 1 == 0 unless ( $self->{legendVisible} );
    return $self->{legendVisible};
}

sub Plot {
    my ( $self, $Picturefilename, $title, $x_title, $y_title, $gbFilename,
        $start, $end )
      = @_;

    my ($temp, $X, $Y, $Y_data, $X_data, $max, $min );

    $y_title = "mean enrichment factor [log2(IP/INPUT)]"
      unless ( defined $y_title );

    $title = "$gbFilename $start - $end bp" unless ( defined $title );
    $self->new_im();

    $X = gbAxis->new(
        "X",
        $self->Width() * 0.12,
        $self->Width * 0.8,
        $x_title, $self->{Info}, $self, $self->{resolution}
    );
	$self->{Info}->{start} = $self->{Info}->{min} unless ( defined $self->{Info}->{start});
	$self->{Info}->{end} = $self->{Info}->{max} unless ( defined $self->{Info}->{end});
    $X->min_value( $self->{Info}->{start});
    $X->max_value( $self->{Info}->{end} );
	
	my ( $problem); 
	$problem = $self->{Info};
	print "We have a problem here! Cause unknown!! all values of Plot inertenal hash \$self->{Info}:\n";
	while (my ($have, $value) = each (%$problem)){
	   print "\tkey: $have to value $value\n";
	}
	unless ( defined $x_title) {
#    	$x_title = $X->bpScale();
		$x_title = "V segments centered at the begining of the second V exon"
    }
	$temp = $X->bpScale();
	$x_title = $1 if ( $x_title =~ m/(.*) *\[.*\]/ );
	$x_title = "$x_title [$temp]";
	$X->renewTitle($x_title);


	$self->{data}->plot($self->{im}, $self->Height() * 0.1,
        $self->Height() * 0.8, $X, $self->{colorObject}, $y_title, $self->{resolution},
		$self->{legend}, $self->{font}, $self->{min_override}, $self->{max_override});

    $X->plot(
        $self->{im},    $self->{data}->getMinimumPoint(),
        $self->{black}, undef,
        $self
    );

    $self->{legend}->Plot(
        $self->Width * 0.7,
        $self->Height() * 0.1,
        $self->{im}, $self->{colorObject}->{black}
    );

    my $filename = $Picturefilename;
    $filename = "./test.svg" unless ( defined $filename );
    $filename = "$filename.svg" unless ( $filename =~ m/\.svg/ );

    my @temp;
    @temp     = split( "/", $filename );
    $filename = $temp[ @temp - 1 ];
    $filename = "$self->{OUTpath}/$filename";



    open( OUT, ">$filename" );
    binmode OUT;
    print OUT $self->{im}->svg;
    close(OUT);
    print "Graf in $filename gespeichert!\n";
	return 1;


}


sub DefineMax {
    my ( $self, $values, $medians ) = @_;
    my ( $max, $stdDev, $median, $temp );

    #   $median = root->median($values);
    $max = root->Max(@$values);

    #   ($temp, $temp, $stdDev) = root->getStandardDeviation($medians);
    print "has max been modified? old max = $max ";

    #   $max = $mean + 4 * $stdDev if ( $max > $mean + 4 * $stdDev);
    $max = 20 if ( $max > 20 );
    print "new max = $max\n"
      ;    # ( max > $mean + 4 * $stdDev (",$mean + 4 * $stdDev,")\n";
    return $max;
}

sub DefineMin {
    my ( $self, $values, $medians ) = @_;
    my ( $min, $stdDev, $median, $temp, $mean );

    #   $median = root->median($values);
    $min = root->Min(@$values);
    print "has min been modified? old min = $min";

    #   ($mean, $temp, $stdDev) = root->getStandardDeviation($medians);
    #   $min = $mean - 4 * $stdDev if ( $min < $mean - 4 * $stdDev);
    $min = -3 if ( $min < -3 );
    print " new min = $min \n"
      ;    #( min < $mean - 4 * $stdDev (",$mean - 4 * $stdDev,")\n";
    return $min;
}

sub TEST_axes {
    my ($self) = @_;

    my ( $X, $Y, $i );
    print "A\n";
    $X = axis->new( "X", 100, 1300, "X-Achse", $self->{resolution} );
    print "A\n";
    $Y = axis->new( "Y", 100, 900, "Y-Achse", $self->{resolution} );

    print "A\n";
    $X->max_value(55);
    print "A\n";
    $X->min_value(-10);
    print "A\n";
    $Y->max_value(0.005);
    print "A\n";
    $Y->min_value(-0.1);
    print "A\n";
    $self->new_im();
    print "X:\n";
    $self->{im}->string( GD::Font->Small, 10,  10,  "10",  $self->{black} );
    $self->{im}->string( GD::Font->Small, 100, 100, "100", $self->{black} );

    $X->plot( $self->{im}, $Y->getMinimumPoint(), $self->{black}, "X-Achse2" );
    $X->plot( $self->{im}, $Y->getMinimumPoint(), $self->{black} );
    print "Y:\n";
    $Y->plot( $self->{im}, $X->getMinimumPoint(), $self->{black}, "Y-Achse2" );
    $Y->plot( $self->{im}, $X->getMinimumPoint(), $self->{black} );
    print "A\n";

    open( OUT, ">test.svg" );
    binmode OUT;
    print OUT $self->{im}->svg;
    close(OUT);
    print "Graf in test.svg gespeichert!\n";
}

sub new_im {

    my ( $self, $width, $height ) = @_;

    $self->{im} = new GD::SVG::Image( $self->Width($width), $self->Height($height) );

	$self->{colorObject} = color->new($self->{im});
    ## colors

    $self->{white} = $self->{im}->colorAllocate( 255, 255, 255 );
    $self->{grey}  = $self->{im}->colorAllocate( 183, 183, 183 );
    $self->{dark_purple} =
      $self->{im}->colorAllocate( 155, 0, 155 );    ## helles Violett
    $self->{purple}       = $self->{im}->colorAllocate( 169, 0,   247 );
    $self->{light_purple} = $self->{im}->colorAllocate( 251, 148, 251 );
    $self->{black}        = $self->{im}->colorAllocate( 0,   0,   0 );

    $self->{dark_green}  = $self->{im}->colorAllocate( 84, 160, 97 );
    $self->{green}       = $self->{im}->colorAllocate( 0,  155, 0 );
    $self->{light_green} = $self->{im}->colorAllocate( 0,  255, 0 );

    $self->{dark_yellow} = $self->{im}->colorAllocate( 240, 240, 40 );
    $self->{yellow}      = $self->{im}->colorAllocate( 255, 255, 0 );
    $self->{light_yelow} = $self->{im}->colorAllocate( 255, 255, 235 );

    $self->{dark_blue}  = $self->{im}->colorAllocate( 0,   0,   255 );
    $self->{blue}       = $self->{im}->colorAllocate( 0,   155, 255 );
    $self->{light_blue} = $self->{im}->colorAllocate( 149, 204, 243 );

    $self->{red}          = $self->{im}->colorAllocate( 255, 0,   0 );
    $self->{rosa}         = $self->{im}->colorAllocate( 255, 0,   221 );
    $self->{brown}        = $self->{im}->colorAllocate( 194, 132, 80 );
    $self->{light_orange} = $self->{im}->colorAllocate( 255, 180, 4 );
    $self->{orange}       = $self->{im}->colorAllocate( 254, 115, 8 );

    my ( @colors, $color, $tokens, $a, $b, $c );

    $tokens = {
        "Mus musculus:Rag KO proB"     => 'X',
        "Mus musculus:Rag KO proT"     => 'O',
        "Mus musculus:Rag KO proB IL7" => 'A',
        "Mus musculus:DC"              => 'D',
        "Mus musculus:Rag KO preB"     => 'p',
        "Mus musculus:Rag KO preB IL7" => 'e',
    };

    $a = {
        H3K4Me2  => $self->{dark_blue},
        H3K9Me3  => $self->{brown},
        H3Ac     => $self->{dark_green},
        Apoptose => $self->{orange}
    };
    $b = {
        H3K4Me2  => $self->{blue},
        H3K9Me3  => $self->{red},
        H3Ac     => $self->{green},
        Apoptose => $self->{orange}
    };
    $c = {
        H3K4Me2  => $self->{light_blue},
        H3K9Me3  => $self->{rosa},
        H3Ac     => $self->{light_green},
        Apoptose => $self->{orange}
    };

    @colors = ( $a, $b, $c );

    $color = {
        "Mus musculus:Rag KO proB"     => $a,
        "Mus musculus:Rag KO proT"     => $b,
        "Mus musculus:Rag KO proB IL7" => $c,
        "Mus musculus:DC"              => $a,
        "Mus musculus:Rag KO preB"     => $c,
        "Mus musculus:Rag KO preB IL7" => $a
    };
    $self->{color}  = $color;
    $self->{colors} = \@colors;
    $self->{tokens} = $tokens;

    ## do not change!! colors for legend! ###########################################
    $self->{pastel_blue}       = $self->{im}->colorAllocate( 249, 247, 255 ); ##
    $self->{pastel_yellow}     = $self->{im}->colorAllocate( 255, 255, 230 ); ##
    $self->{ultra_pastel_blue} = $self->{im}->colorAllocate( 251, 251, 255 ); ##
    $self->{ultra_pastel_yellow} =
      $self->{im}->colorAllocate( 255, 255, 240 );                            ##
    ################################################################################
    return $self->{im};
}

sub getColor4gbFeatureTag {
    my ( $self, $gbFeatureTag ) = @_;
	warn "Depricated use completely new color class!!\n";
	return $self->{purple}    if (  $gbFeatureTag =~ m/enhancer/ );
	return $self->{rosa}	  if ( $gbFeatureTag =~ m/silencer/ );
	return $self->{black}     if ( $gbFeatureTag =~ m/mRNA/ );
    return $self->{black}     if ( $gbFeatureTag =~ m/CDS/ );
    return $self->{red}       if ( $gbFeatureTag =~ m/primer_bind/ );
    return $self->{purple}    if ( $gbFeatureTag =~ m/misc_binding/ );
    return $self->{dark_blue} if ( $gbFeatureTag =~ m/D_segment/ );
    return $self->{green}     if ( $gbFeatureTag =~ m/J_segment/ );
    return $self->{brown}     if ( $gbFeatureTag =~ m/C_segment/ );
	if ( $self->{use_V_segment_colors}){
    return $self->{dark_blue}
      if ( $gbFeatureTag =~ m/V1/ || $gbFeatureTag =~ m/J558/ );
    return $self->{green}
      if ( $gbFeatureTag =~ m/V2/ || $gbFeatureTag =~ m/Q52/ );
    return $self->{purple}
      if ( $gbFeatureTag =~ m/V3/ || $gbFeatureTag =~ m/36-60/ );
    return $self->{blue}
      if ( $gbFeatureTag =~ m/V4/ || $gbFeatureTag =~ m/X24/ );
    return $self->{red}
      if ( $gbFeatureTag =~ m/V5/ || $gbFeatureTag =~ m/7183/ );
    return $self->{black}
      if ( $gbFeatureTag =~ m/V6/ || $gbFeatureTag =~ m/J606/ );
    return $self->{orange}
      if ( $gbFeatureTag =~ m/V7/ || $gbFeatureTag =~ m/S107/ );
    return $self->{dark_green}
      if ( $gbFeatureTag =~ m/V13/ || $gbFeatureTag =~ m/3609N/ );
    return $self->{orange}
      if ( $gbFeatureTag =~ m/V8/ || $gbFeatureTag =~ m/3609/ );
    return $self->{light_purple}
      if ( $gbFeatureTag =~ m/V9/ || $gbFeatureTag =~ m/VGAM3\.8/ );
    return $self->{rosa}
      if ( $gbFeatureTag =~ m/V10/ || $gbFeatureTag =~ m/VH10/ );
    return $self->{brown}
      if ( $gbFeatureTag =~ m/V11/ || $gbFeatureTag =~ m/VH11/ );
    return $self->{light_orange}
      if ( $gbFeatureTag =~ m/V12/ || $gbFeatureTag =~ m/VH12/ );
    return $self->{blue}
      if ( $gbFeatureTag =~ m/V14/ || $gbFeatureTag =~ m/SM7/ );
    return $self->{light_blue}
      if ( $gbFeatureTag =~ m/V15/ || $gbFeatureTag =~ m/VH15/ );
	}
	return $self->{rosa} if ( $self->isV_segment($gbFeatureTag) && lc($gbFeatureTag) =~ m/pg/);
	return $self->{red} if ( $self->isV_segment($gbFeatureTag) );  
    return $self->{red} if ( $gbFeatureTag =~ m/V_segment/ );
    return $self->{black}     if ( $gbFeatureTag =~ m/C_region/ );

    #    return $self->{} if ( $gbFeatureTag =~ m// || $gbFeatureTag =~ m//);
    return undef;
}

sub isV_segment{
  my ( $self, $featureName) = @_;
  my @V = ( "J558","Q52","36-60","X24","7183","J606",
            "S107","3609N","3609","VGAM3.8","VH10",
			"VH11","VH12","SM7","VH15");
  foreach my $tag (@V){
     return 1==1 if ( $featureName =~m/$tag/);
  }
  return 1 == 1 if ( $featureName =~m/V\d+/ );
  return 1 == 1 if ( $featureName =~m/PG\.\d+/);
  return 1 == 0;
}
   
sub Width {
    my ( $self, $width ) = @_;
    $self->{width} = $width if ( defined $width );

    #   print "Width = $self->{width}\n";
    return $self->{width};
}

sub Height {
    my ( $self, $width ) = @_;
    $self->{height} = $width if ( defined $width );

    #   print "Height = $self->{height}\n";
    return $self->{height};
}

1;
