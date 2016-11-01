#! /usr/bin/perl
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

use stefans_libs::plot::multi_axis;
use stefans_libs::plot::Font;
use stefans_libs::multiLinePlot;

use strict;

#my $axis = multi_axis->new("x",1,800,"test","max");
my $im = new GD::Image( 1000, 800 );
#$axis->AddSubRegion( 10, 30, 400 );
#$axis->AddSubRegion( 20, 3000, 3100 );
my $font = Font->new("max");
my $color = color->new();
$color->createColors($im);
$im->line(500,1,500,800,$color->{black});
#$axis->plot( $im, 500, $color->{black}, "test" );

$font->plotStringAtY_leftLineEnd($im, "plotStringAtY_leftLineEnd", 500, 400, $color->{black}, "large",0);
$im->line(500,400,1000,400,$color->{black});
$font->plotStringAtY_rightLineEnd($im, "plotStringAtY_rightLineEnd", 500, 300, $color->{black}, "large",0);
$im->line(0,300,500,300,$color->{black});

open( PICTURE, ">font_plot_test.png" ) or die
"Cannot open file font_plot_test.png for writing\n";

binmode PICTURE;

print PICTURE $im->png;
close PICTURE;
print "Bild als font_plot_test.png gespeichert\n";

