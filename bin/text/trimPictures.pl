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

use Getopt::Long;
use strict;

my (@files, $outpath, $help, $filename, @FILE, $silent, $outfile, $files );

if ( @ARGV == 2 && ! ($ARGV[0] eq "-infile") ){
	$files = $ARGV[0];
	$outfile = $ARGV[1];
}
else{
	Getopt::Long::GetOptions(
   	 	'-infile=s{,}' => \@files,
    	'-outpath=s' => \$outpath,
   		'-outfile=s' => \$outfile,
   		"-silent"    => \$silent,
   		'-help'		=> \$help
	) or die helpText("no return of the important things");
    
	die helpText("help text") if ( $help);
}

die helpText("no infile[$files[0]]") unless ( -f $files[0]);

$outpath = "./" unless (defined $outpath);

#system ( "convert -trim +repage -bordercolor white -border 8x8 $source $drain ");
foreach $files ( @files){
	unless ( defined $outfile){
		@FILE = split("/", $files);
		$filename = @FILE[@FILE-1];
		unless ( defined $outpath){
			$outpath = join( "/", @FILE[0..@FILE-2]);
			unless ( $outpath =~ m!/!){
				$outpath = "./";
			}
		}
		$filename = "$outpath/$filename";
		$filename = "$1.png" if ( $filename =~ m/(.+).svg/);
	}
	else{
		$filename = $outfile;
	}
	
	system ( "convert -trim +repage -bordercolor white  $files $filename ");
	print "File ($files) saved as $filename\n" unless ( $silent );
}

sub helpText{
	my $temp = shift;
	return "trimPictures.pl ($temp)\n",
	"\t-infile		: a pace separated string of input pictures\n",
	"\t-outpath     : the path to write the pictures to (if omitted './' is used)\n",
	"\t-outfile     : the absolute position of an outfile";
}
