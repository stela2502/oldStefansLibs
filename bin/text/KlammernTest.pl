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

my $file = $ARGV[0];
my ( @line, $count, @string, $string);

open ( IN , "<$file") or die "I did not get the infile!!\n";
$count = 0;
while (<IN>) {
	chomp $_;
	@line = split( "" ,$_);
	foreach my $char ( @line){
		next if ( $char eq " " );
		$string = "$string$char";
		if ( $char eq "{"){
			$count ++;
			$string[$count] = $string;
			$string = "";
		}
		$count -- if ( $char eq "}");
	}
}

print "final value shoud be 0\nfinal value = $count\n";
print "Unmatched { = $string[$count] \n" if ( $count > 0);
