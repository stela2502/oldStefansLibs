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

use stefans_libs::plot::axis;
use strict;

my $axis = axis->new("Y",1,1000,"test","max");
my ($min, $max) = ($ARGV[0],$ARGV[1]);
$min = -0.5 unless (defined $min);
$max = 0.75 unless (defined $max);

$axis->max_value( $max );
$axis->min_value( $min );

$axis->defineAxis();
