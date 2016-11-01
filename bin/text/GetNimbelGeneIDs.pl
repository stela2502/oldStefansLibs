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

use stefans_libs::database_old::hybInfoDB;

my $hybDB = hybInfoDB->new();

my $allData = $hybDB->getAllByNimbleID();
#
#while ( my ($key, $value) = each(%$allData)) {
#	print "$key : $value\n";
#	if (defined %$value){
#		while ( my ($key1, $value1) = each (%$value)){
#			print "\t$key1 : $value1\n";
#			if (defined %$value1){
#				while ( my ($key2, $value2) = each (%$value1)){
#					print "\t\t$key2 : $value2\n";
#				}
#			}
#		}
#	}
#}
my $value;
foreach my $key (sort byNumber keys %$allData) {
	$value = $allData->{$key};
	print "NimbleGeneID: $key - ",
	"cellType: $value->{experiment}->{Celltype} - ",
	"antibody: $value->{experiment}->{Antibody}\n";
	#print "\t\texperiment dye: $value->{experiment}\n";
}

print "fertig!\n";

sub byNumber{
	return $a <=> $b;
}
