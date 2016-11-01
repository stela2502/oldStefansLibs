package color;

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
use warnings;

sub new {

	my ( $class, $im ) = @_;

	warn "$class -> new() - we have not got a image to deploy the colors to..." unless ( defined $im);
	my ($self);

	$self = {
		uniqueColor         => 1 == 1,
		IL7_difference      => 1 == 1,
		white               => undef,
		grey                => undef,
		dark_purple         => undef,
		purple              => undef,
		light_purple        => undef,
		black               => undef,
		dark_green          => undef,
		green               => undef,
		light_green         => undef,
		dark_yellow         => undef,
		yellow              => undef,
		light_yelow         => undef,
		dark_blue           => undef,
		blue                => undef,
		light_blue          => undef,
		red                 => undef,
		rosa                => undef,
		brown               => undef,
		light_orange        => undef,
		orange              => undef,
		pastel_blue         => undef,
		pastel_yellow       => undef,
		ultra_pastel_blue   => undef,
		ultra_pastel_yellow => undef
	};

	bless $self, $class if ( $class eq "color" );

	$self->createColors($im) if ( defined $im );

	return $self;

}

sub getNextColor {
	my ($self) = @_;
	$self->{nextColor} = 0 if ( $self->{nextColor} == $self->{maxColorIndex} );
	return $self->{colorArray}[ ++$self->{nextColor} ];
}

sub getDensityMapColorArray {
	my ($self) = @_;
	return (
		$self->{black},       $self->{dark_blue},  $self->{blue},
		$self->{dark_purple}, $self->{dark_green}, $self->{green},
		$self->{tuerkies1},      $self->{red},        $self->{rosa},
		$self->{yellow}
	);
}

sub UseUniqueColors {
	my ( $self, $boolean ) = @_;
	if ( defined $boolean ) {
		$self->{uniqueColor} = $boolean;
	}
	return $self->{uniqueColor};
}

sub makeBackground {
	my ( $self, $im, $color ) = @_;

	print "what we ($self) got: image='$im', color='$color' \n ";

	$im->colorAllocate( 255, 255, 255 ) if ( $color eq 'white' || $color == 0 );

	$im->colorAllocate( 183, 183, 183 ) if ( $color eq 'grey' || $color == 1 );
	$im->colorAllocate( 100, 100, 100 )
	  if ( $color eq 'dark_grey' || $color == 2 );
	$im->colorAllocate( 155, 0, 155 )
	  if ( $color eq 'dark_purple' || $color == 3 );    ## helles Violett
	$im->colorAllocate( 169, 0, 247 ) if ( $color eq 'purple' || $color == 4 );
	$im->colorAllocate( 251, 148, 251 )
	  if ( $color eq 'light_purple' || $color == 5 );
	$im->colorAllocate( 0, 0, 0 ) if ( $color eq 'black' || $color == 6 );

	$im->colorAllocate( 0, 119, 10 )
	  if ( $color eq 'dark_green' || $color == 7 );
	$im->colorAllocate( 0, 155, 0 ) if ( $color eq 'green' || $color == 8 );
	$im->colorAllocate( 0, 255, 0 )
	  if ( $color eq 'light_green' || $color == 9 );
	$im->colorAllocate( 165, 202, 0 )
	  if ( $color eq 'yellowgreen' || $color == 10 );

	$im->colorAllocate( 240, 240, 40 )
	  if ( $color eq 'dark_yellow' || $color == 11 );
	$im->colorAllocate( 255, 255, 0 ) if ( $color eq 'yellow' || $color == 12 );
	$im->colorAllocate( 255, 255, 235 )
	  if ( $color eq 'light_yelow' || $color == 13 );

	$im->colorAllocate( 0, 0, 255 )
	  if ( $color eq 'dark_blue' || $color == 14 );
	$im->colorAllocate( 0,  155, 255 ) if ( $color eq 'blue'  || $color == 15 );
	$im->colorAllocate( 71, 0,   184 ) if ( $color eq 'blau2' || $color == 16 );
	$im->colorAllocate( 0,  220, 255 )
	  if ( $color eq 'tuerkies1' || $color == 17 );
	$im->colorAllocate( 149, 204, 243 )
	  if ( $color eq 'light_blue' || $color == 18 );

	$im->colorAllocate( 255, 0, 0 )   if ( $color eq 'red'  || $color == 19 );
	$im->colorAllocate( 255, 0, 221 ) if ( $color eq 'rosa' || $color == 20 );
	$im->colorAllocate( 194, 132, 80 ) if ( $color eq 'brown' || $color == 21 );
	$im->colorAllocate( 255, 180, 4 )
	  if ( $color eq 'light_orange' || $color == 22 );
	$im->colorAllocate( 254, 115, 8 ) if ( $color eq 'orange' || $color == 23 );

	## do not change!! colors for legend! ###########################################
	$im->colorAllocate( 249, 247, 255 )
	  if ( $color eq 'pastel_blue' || $color == 24 );    ##
	$im->colorAllocate( 255, 255, 230 )
	  if ( $color eq 'pastel_yellow' || $color == 25 );    ##
	$im->colorAllocate( 251, 251, 255 )
	  if ( $color eq 'ultra_pastel_blue' || $color == 26 );    ##
	$im->colorAllocate( 255, 255, 240 )
	  if ( $color eq 'ultra_pastel_yellow' || $color == 27 );    ##
	#################################################################################
	return $im;
}

sub createColors {
	my ( $self, $im ) = @_;
	$self->{im} = $im;
	my @array;
	$self->{colorArray} = \@array;
	$self->{nextColor}  = 0;

	$self->{white} = $self->{im}->colorAllocate( 255, 255, 255 );
	push( @array, $self->{white} );

	#    $self->{background} = $self->{im}->colorAllocate( 245, 245, 245 );
	$self->{grey}      = $self->{im}->colorAllocate( 183, 183, 183 );
	$self->{dark_grey} = $self->{im}->colorAllocate( 100, 100, 100 );

	$self->{dark_purple} =
	  $self->{im}->colorAllocate( 155, 0, 155 );    ## helles Violett

	$self->{purple} = $self->{im}->colorAllocate( 169, 0, 247 );
	push( @array, $self->{purple} );
	$self->{light_purple} = $self->{im}->colorAllocate( 251, 148, 251 );
	$self->{black}        = $self->{im}->colorAllocate( 0,   0,   0 );

	$self->{dark_green} = $self->{im}->colorAllocate( 0, 119, 10 );
	push( @array, $self->{dark_green} );
	$self->{green}       = $self->{im}->colorAllocate( 0,   155, 0 );
	$self->{light_green} = $self->{im}->colorAllocate( 0,   255, 0 );
	$self->{yellowgreen} = $self->{im}->colorAllocate( 165, 202, 0 );
	push( @array, $self->{yellowgreen} );

	$self->{dark_yellow} = $self->{im}->colorAllocate( 240, 240, 40 );
	push( @array, $self->{dark_yellow} );
	$self->{yellow}      = $self->{im}->colorAllocate( 255, 255, 0 );
	$self->{light_yelow} = $self->{im}->colorAllocate( 255, 255, 235 );

	$self->{dark_blue} = $self->{im}->colorAllocate( 0, 0, 255 );
	push( @array, $self->{dark_blue} );
	$self->{blue}      = $self->{im}->colorAllocate( 0,  155, 255 );
	$self->{blau2}     = $self->{im}->colorAllocate( 71, 0,   184 );
	$self->{tuerkies1} = $self->{im}->colorAllocate( 0,  220, 255 );
	push( @array, $self->{tuerkies1} );
	$self->{light_blue} = $self->{im}->colorAllocate( 149, 204, 243 );
	push( @array, $self->{light_blue} );

	$self->{red} = $self->{im}->colorAllocate( 255, 0, 0 );
	push( @array, $self->{red} );
	$self->{rosa} = $self->{im}->colorAllocate( 255, 0, 221 );
	push( @array, $self->{rosa} );
	$self->{brown} = $self->{im}->colorAllocate( 194, 132, 80 );
	push( @array, $self->{brown} );
	$self->{light_orange} = $self->{im}->colorAllocate( 255, 180, 4 );
	$self->{orange}       = $self->{im}->colorAllocate( 254, 115, 8 );
	push( @array, $self->{orange} );

	## do not change!! colors for legend! ###########################################
	$self->{pastel_blue}       = $self->{im}->colorAllocate( 249, 247, 255 ); ##
	$self->{pastel_yellow}     = $self->{im}->colorAllocate( 255, 255, 230 ); ##
	$self->{ultra_pastel_blue} = $self->{im}->colorAllocate( 251, 251, 255 ); ##
	$self->{ultra_pastel_yellow} =
	  $self->{im}->colorAllocate( 255, 255, 240 );                            ##
	#################################################################################
	push( @array, $self->{black} );
	push( @array, $self->{green} );
	push( @array, $self->{blue} );
	push( @array, $self->{light_orange} );
	push( @array, $self->{light_green} );
	push( @array, $self->{ultra_pastel_blue} );
	$self->{maxColorIndex} = @array - 1;
}

sub selectTwoFoldColor {
	my ( $self, $celltype, $antibody ) = @_;
	if ( lc($celltype) =~ m/il7/ ) {
		return $self->{red} if ( lc($antibody) =~ m/h3ac/ );
		return $self->{black}
		  if ( lc($antibody) =~ m/h3k4me2/ && lc($celltype) =~ m/prob/ );
		return $self->{purple}
		  if ( lc($antibody) =~ m/h3k4me2/ && lc($celltype) =~ m/preb/ );
	}
	return $self->selectColor( $celltype, $antibody );
}

sub selectColor {
	my ( $self, $celltype, $antibody ) = @_;

 #print "\n\nDEBUG color selectColor for celltype $celltype and ab $antibody\n";
 #	if ( $self->{IL7_difference} ){
 #		if ( lc($celltype) =~ m/il7/ ){
 #			$celltype = "prot";
 #			return $self->{red};
 #		}
 #		else {
 #			$celltype = "prob";
 #		}
 #		$self->{uniqueColor} =  1 == 0;
 #	}

	if ( $self->{uniqueColor} ) {
		if ( lc($antibody) =~ m/h3ac/ ) {
			return $self->{light_green};
		}
		if ( lc($antibody) =~ m/h3k4me2/ ) {
			return $self->{dark_blue};
		}
		if ( lc($antibody) =~ m/h3k9me3/ ) {
			return $self->{red};
		}
	}
	if ( lc($celltype) =~ m/prob/ ) {
		if ( lc($antibody) =~ m/h3ac/ ) {
			return $self->{green};
		}
		if ( lc($antibody) =~ m/h3k4me2/ ) {
			return $self->{black} if ( lc($celltype) =~ m/il7/ );
			return $self->{dark_blue};
		}
		if ( lc($antibody) =~ m/h3k9me3/ ) {
			return $self->{red};
		}
		warn "no color defined for celltype $celltype and antibody $antibody\n";
		return $self->{black};
	}
	if ( lc($celltype) =~ m/preb/ ) {
		if ( lc($antibody) =~ m/h3ac/ ) {
			return $self->{dark_green};
		}
		if ( lc($antibody) =~ m/h3k4me2/ ) {
			return $self->{dark_purple};

			# return $self->{black};
		}
		if ( lc($antibody) =~ m/h3k9me3/ ) {
			return $self->{dark_purple};
		}
		warn "no color defined for celltype $celltype and antibody $antibody\n";
		return $self->{black};
	}
	if ( lc($celltype) =~ m/prot/ ) {
		if ( lc($antibody) =~ m/h3ac/ ) {
			return $self->{light_green};
		}
		if ( lc($antibody) =~ m/h3k4me2/ ) {
			return $self->{blau2};
		}
		if ( lc($antibody) =~ m/h3k9me3/ ) {
			return $self->{rosa};
		}
		warn "no color defined for celltype $celltype and antibody $antibody\n";
		return $self->{black};
	}
	if ( lc($celltype) =~ m/dc/ ) {
		if ( lc($antibody) =~ m/h3ac/ ) {
			return $self->{yellowgreen};
		}
		if ( lc($antibody) =~ m/h3k4me2/ ) {
			return $self->{tuerkies1};
		}
		if ( lc($antibody) =~ m/h3k9me3/ ) {
			return $self->{light_orange};
		}
		warn "no color defined for celltype $celltype and antibody $antibody\n";
		return $self->{black};
	}
	warn "no color defined for celltype $celltype and antibody $antibody\n";
	return $self->{black};
}

sub Token {
	my ( $self, $celltype ) = @_;
	return "I" if ( lc($celltype) =~ m/il7/ && $self->{IL7_difference} );
	return "X" if ( lc($celltype) =~ m/prob/ );
	return "E" if ( lc($celltype) =~ m/preb/ );
	return "T" if ( lc($celltype) =~ m/prot/ );
	return "D" if ( lc($celltype) =~ m/dc/ );
}

sub Colored_V_segments {
	my ( $self, $bool ) = @_;
	if ( defined $bool ) {
		$self->{use_V_segment_colors} = $bool;
	}
	return $self->{use_V_segment_colors};
}

sub highlight_Vsegment {
	my ( $self, $tag ) = @_;
	if ( defined $tag ) {
		$self->{hi_V_seg} = $tag;
	}

	#print "$self->highlight_Vsegment returns: '",
	#  substr( $self->{hi_V_seg}, 0, 10 ), "...'\n";
	return $self->{hi_V_seg};
}

sub getIg_Values {

	my ( $self, $gbFeature ) = @_;
	return $self->color_and_Name($gbFeature);
}

sub color_and_Name {
	my ( $self, $region ) = @_;

	## $region is a gbFeature!

	my ( @temp, $name, $tag, $pg, $color );

	$name = $region->Name();
	$tag  = $region->Tag();

	if ( $name =~ m/"/ ) {    #"
		@temp = split( '"', $name );
		$name = $temp[1];
	}
	## Identification by Tag
	if ( $tag eq "enhancer" ) {
		return $name, $self->{purple};
	}
	if ( $tag eq "silencer" ) {
		return $name, $self->{rosa};
	}
	if ( $tag eq "D_segment" ) {

		#     print "D_segment name = $name;\n";
		return $1, $self->{dark_blue} if ( $name =~ m/(DQ-52)/ );
		return $1, $self->{dark_blue} if ( $name =~ m/D_FL16.1/ );
		return $name, $self->{dark_blue} if ( $name eq "D1" || $name eq "D2" );

		$name =~ s/TR[AGDB]/IGH/;
		$name =~ m/IG[HKL](D.*?)/;
		$name = $1;

  #     print "D_segment after match against /IGH(D.*).*?=\*/  name = $name;\n";
		return $name, $self->{dark_blue};
	}
	if ( $tag eq "J_segment" ) {
		$name =~ s/TR[AGDB]/IGH/;
		$name =~ m/IG[HKL](J\d)/;
		return $1, $self->{green};
	}
	if ( $tag eq "C_region" || $tag eq "C_segment" ) {

		#	print "color : C_region  name = $name\n";
		if ( $name =~ m/(IG[HKL][\w\d]+)/ ) {
			return $1, $self->{brown};
		}
		if ( $name =~ m/TR([ABDG])C/ ) {
			return $1, $self->{brown};
		}
		return "", $self->{brown};
	}

	## Jetzt kann es nur noch eine V_region sein!
	## Alle V_regionen die nach IMGT benannt sind haben den Schlüssel V\d[1-2] als Identificator der Familie!
	## Farben wurden in Analogie zu dem paper "Johnston,...,Corcoran Ig Heavy Chain V Region" gewählt
	if ( defined $self->highlight_Vsegment() ) {
		$tag = $self->highlight_Vsegment();
		@temp = split( ";", $tag );
		foreach my $matchingFeature (@temp) {
			if ( $region->getAsGB =~ m/$matchingFeature/ ) {

#print
#"$self->color_and_Name got a V_segment ($name) and it mached to $matchingFeature\n";
				return $self->V_segment_Name($name), $self->{red};
			}
		}
		return $name, $self->{black};
	}
	if ( $self->Colored_V_segments() ) {
		print "we return the color for V_segment $name\n";
		if ( $name =~ m/V10/ || $name =~ m/VH10/ ) {
			return "V10", $self->{rosa};
		}
		if ( $name =~ m/V11/ || $name =~ m/VH11/ ) {
			return "V11", $self->{brown};
		}
		if ( $name =~ m/V12/ || $name =~ m/VH12/ ) {
			return "V12", $self->{light_orange};
		}
		if ( $name =~ m/V13/ || $name =~ m/3609N/ ) {
			return "V13", $self->{dark_green};
		}
		if ( $name =~ m/V14/ || $name =~ m/SM7/ ) {
			print
"If name = SM7 this must be printed!\nreturns V14 , $self->{blue}\n";
			return "V14", $self->{blue};
		}
		if ( $name =~ m/V15/ || $name =~ m/VH15/ ) {
			return "V15", $self->{light_blue};
		}
		if ( $name =~ m/(V1\d)/ ) {
			return $1, $self->{red};
		}
		if ( $name =~ m/V1\.\d/ || $name =~ m/J558/ ) {
			return "V1", $self->{dark_blue};
		}
		if ( $name =~ m/(V2\d)/ ) {
			return $1, $self->{red};
		}
		if ( $name =~ m/V2/ || $name =~ m/Q52/ ) {
			return "V2", $self->{green};
		}
		if ( $name =~ m/(V3\d)/ ) {
			return $1, $self->{red};
		}
		if ( $name =~ m/V3/ || $name =~ m/36-60/ ) {
			return "V3", $self->{purple};
		}
		if ( $name =~ m/V4/ || $name =~ m/X24/ ) {
			return "V4", $self->{blue};
		}
		if ( $name =~ m/V5/ || $name =~ m/7183/ ) {
			return "V5", $self->{red};
		}
		if ( $name =~ m/V6/ || $name =~ m/J606/ ) {
			return "V6", $self->{black};
		}
		if ( $name =~ m/V7/ || $name =~ m/S107/ ) {
			return "V7", $self->{orange};
		}
		if ( $name =~ m/V8/ || $name =~ m/3609/ ) {
			if ( $name =~ m/3609.\d*pg/ ) {
				$pg = "pg";
			}
			else {
				$pg = "";
			}

#       return "V8.$1$pg", $self->{orange} if ( $name =~ m/3609.\d*p?g?.(\d{1,3})/ );
			return "V8", $self->{orange};
		}
		if ( $name =~ m/V9/ || $name =~ m/VGAM3\.8/ ) {
			return "V9", $self->{light_purple};
		}

		if ( $name =~ m/(V\d+)/ ) {
			return $1, $self->{red};
		}
		if ( $name =~ m/PG/ ) {
			return "PG", $self->{black};
		}
		return "undef", $self->{blue};
	}
	else {
		return $self->V_segment_Name($name), $self->{red};
	}

}

sub V_segment_Name {
	my ( $self, $name, $tag ) = @_;

	my ( @temp, $pg );
	if ( $name =~ m/"/ ) {    #"
		@temp = split( '"', $name );
		$name = $temp[1];
	}
	return $name if ( $tag eq "enhancer" );
	return $name if ( $tag eq "silencer" );
	if ( $tag =~ m/^C_/ ) {
		return "" if ( $name =~ m/MMI/ );
		return "" if ( $name =~ m/IMGT_feature_tag/ );
		return $1 if ( $name =~ m/"([\w\d]+)"/ );
		return $name;
	}
	if ( $tag =~ m/^J_/ ) {
		return $1 if ( $name =~ m/(J\d+)/ );
		return "";
	}
	if ( $tag =~ m/^D_/ ) {
		return $1        if ( $name =~ m/(D_Q52)/ );
		return "DQ52"    if ( $name =~ m/52/ );
		return "DFL16.1" if ( $name =~ m/D-FL16.1/ );
		return "D$1"     if ( $name =~ m/TRDD(\d)/ );
		return $name if ( $name eq "D1" || $name eq "D2" );
		return "";
		return $1 if ( $name =~ m/IGHD-(.*)/ );
		return $name;
		return "";
	}
	return "Vb13.2" if ( $name =~ m/ap. V/ );
	return $1       if ( $name =~ m/(V[abc])/ );
	return $1       if ( $name =~ m/(V\d\d[_-]?\d?)/ );
	return "V10$1"  if ( $name =~ m/V10(-?\d?)/ || $name =~ m/VH10/ );
	return "V11$1"  if ( $name =~ m/V11(-?\d?)/ || $name =~ m/VH11/ );
	return "V12$1"  if ( $name =~ m/V12(-?\d?)/ || $name =~ m/VH12/ );
	return "V13$1"  if ( $name =~ m/V13(-?\d?)/ || $name =~ m/3609N/ );
	return "V14$1"  if ( $name =~ m/V14(-?\d?)/ || $name =~ m/SM7/ );
	return "V15$1"  if ( $name =~ m/V15(-?\d?)/ || $name =~ m/VH15/ );
	return "V16$1"  if ( $name =~ m/V16(-?\d?)/ );
	return "V17$1"  if ( $name =~ m/V17(-?\d?)/ );
	return "V18$1"  if ( $name =~ m/V18(-?\d?)/ );
	return "V19$1"  if ( $name =~ m/V19(-?\d?)/ );
	return "V1$1"   if ( $name =~ m/V1(-?\d?)/ || $name =~ m/J558/ );
	return "V20$1"  if ( $name =~ m/V20(-?\d?)/ );
	return "V21$1"  if ( $name =~ m/V21(-?\d?)/ );
	return "V22$1"  if ( $name =~ m/V22(-?\d?)/ );
	return "V24$1"  if ( $name =~ m/V24(-?\d?)/ );
	return "V25$1"  if ( $name =~ m/V25(-?\d?)/ );
	return "V26$1"  if ( $name =~ m/V26(-?\d?)/ );
	return "V27$1"  if ( $name =~ m/V27(-?\d?)/ );
	return "V28$1"  if ( $name =~ m/V28(-?\d?)/ );
	return "V29$1"  if ( $name =~ m/V29(-?\d?)/ );
	return "V2$1"   if ( $name =~ m/V2(-?\d?)/ || $name =~ m/Q52/ );
	return "V30$1"  if ( $name =~ m/V30(-?\d?)/ );
	return "V31$1"  if ( $name =~ m/V31(-?\d?)/ );
	return "V32$1"  if ( $name =~ m/V32(-?\d?)/ );
	return "V34$1"  if ( $name =~ m/V34(-?\d?)/ );
	return "V35$1"  if ( $name =~ m/V35(-?\d?)/ );
	return "V36$1"  if ( $name =~ m/V36(-?\d?)/ );
	return "V37$1"  if ( $name =~ m/V37(-?\d?)/ );
	return "V38$1"  if ( $name =~ m/V38(-?\d?)/ );
	return "V39$1"  if ( $name =~ m/V39(-?\d?)/ );
	return "V3$1"   if ( $name =~ m/V3(-?\d?)/ || $name =~ m/36-60/ );
	return "V4$1"   if ( $name =~ m/V4(-?\d?)/ || $name =~ m/X24/ );
	return "V5$1"   if ( $name =~ m/V5(-?\d?)/ || $name =~ m/7183/ );
	return "V6$1"   if ( $name =~ m/V6(-?\d?)/ || $name =~ m/J606/ );
	return "V7$1"   if ( $name =~ m/V7(-?\d?)/ || $name =~ m/S107/ );
	return "V8$1"   if ( $name =~ m/V8(-?\d?)/ || $name =~ m/3609/ );
	return "V9$1"   if ( $name =~ m/V9(-?\d?)/ || $name =~ m/VGAM3\.8/ );
	return ""       if ( $name =~ m/(D)/ );
	return $1       if ( $name =~ m/J(\d+)/ );
	return $1 if ( $name =~ m/(IG\w)/ || $name =~ m/C([ABDG])/ );
	return "V?";
}

1;
