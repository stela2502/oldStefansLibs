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

use strict;

my ( $filename, $filename2);

open (INFILE, "<$ARGV[0]" ) or die "Konnte file $ARGV[0] nicht öffnen!\n";

while (<INFILE>){

#   print "$_";
   if ( $_ =~ m/--infile=([.\.\/\w]+).pm/ ){

      $filename =$1;
      $filename2 = $1 if ( $filename =~ m/^..\/(.+)/);
      print "pod2html --podpath=/home/stefan/IgH-Locus/Libs_new_structure/stefans_libs/ ",
            "--podroot=/Mass/IgH-Locus/doc/  ",
            "--htmldir=/Mass/IgH-Locus/doc/ ",
            "--infile=/home/stefan/IgH-Locus/Libs_new_structure/stefans_libs/$filename2.pm ",
            "--outfile=$filename2.html\n";
   }
   print $_ if ( $_ =~ m/mkdir/);
}
