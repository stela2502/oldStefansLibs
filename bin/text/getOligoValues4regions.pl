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
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use Getopt::Long;
use stefans_libs::database_old::hybInfoDB;

my (
	$data,      @tableHeader, $gffFiles,    $oligoList, @IVARs,
	$oligo2dna, $gffFile,     @IVAR_oligos, $hybInfo, $outFile
);
my ( $regions, $GFF_list, $HMM_list, $help, @gff, @hmm, $pathModifier, $temp, @temp );

Getopt::Long::GetOptions(
	'regions=s'  => \$regions,
	'GFF_list=s' => \$GFF_list,
	'outFile=s'	 => \$outFile,
	'help'       => \$help
) or die helpText();

die helpText() if ($help);

die helpText() unless ( defined $regions);

open( RegionsFile, "<$regions" )
  or die "regionXY_plot could not open region definition file!\n";

open( GFF_File, "<$GFF_list" )
  or die "regionXY_plot could not open gff location file\n";


@gff = <GFF_File>;

if ( $gff[0] =~ m/^PATH_MODIFIER=([\w\d_]+)/ ) {
	$pathModifier = $1;
	$gff[0] = "#$gff[0]";
}

print "Path modifier added: $pathModifier\n";
$hybInfo = hybInfoDB->new();

for ( my $i = 0 ; $i < @gff ; $i++ ) {
	next if ( $gff[$i] =~ m/^#/ );
	print "Use gff file $gff[$i]\n";
	$temp    = $gff[$i];
	@temp    = split( " ", $temp );
	$gff[$i] = $temp[0];
	$temp    = $1 if ( $gff[$i] =~ m/(\d+)_ratio.gff/ );
	$gffFiles->{ $hybInfo->getInfo4NimbleGeneID($temp) } = $gff[$i];
}

my ( $hash, @regions );

@tableHeader = qw(OligoID Start End gbFile Sequence OligoHitCount );
$oligo2dna   = oligo2dnaDB->new();

while (<RegionsFile>) {
	next if ( $_ =~ m/^#/ );
	next if ( $_ =~ m/^new=/ );
	chomp $_;
	(
		$hash->{gbFile},    $hash->{start},        $hash->{end},
		$hash->{X_axis},    $hash->{pictureTitle}, $hash->{filename},
		$hash->{binLength}, @temp
	) = split( ",", $_ );
	push( @regions, $hash );
	$oligoList =
	  $oligo2dna->GetOligoLocationArray( "2005-09-08_RZPD1538_MM6_ChIP",
		$hash->{gbFile} );
	## jetzt werden alle oligo Infos für die einzelnen Regionen eingetragen
	foreach my $oligo (@$oligoList) {
		if ( @$oligo[2] < $hash->{end} && @$oligo[1] > $hash->{start} ) {
			@$oligo[3] = $hash->{gbFile};
			push( @$oligo,      $hash->{filename} );
			push( @IVAR_oligos, $oligo );
		}
	}
}

push( @tableHeader, "region name" );

$gffFile = gffFile->new();
## Und jetzt die Oligo enrichemnt daten mit eintragen
foreach my $key ( sort keys %$gffFiles ) {
	$data = $gffFile->GetData( $gffFiles->{$key} );
	foreach my $oligo (@IVAR_oligos) {
		push( @$oligo, $data->{ @$oligo[0] } );
	}
	push( @tableHeader, $key );
}

open( OUT, ">$outFile" )
  or die
  "konnte datei $outFile nicht anlegen (has to be determined at runtime)\n";
print OUT join( "\t", @tableHeader ), "\n";
foreach my $oligo (@IVAR_oligos) {
	print OUT join( "\t", @$oligo ), "\n";
}
close(OUT);

print "all infos for the IVAR elements have been stored in $outFile\n";

sub helpText {
	return "getOligoValues4regions.pl command line info\n",
"getOligoValues4regions.pl can access all NimbleGene Files and report the oligo values for a given region\n",
	  "the syntax is similar to regionsXY_plot.pl\n",
	  "\t-regions <>    :A tab formated list of wanted regions\n",
"\t-GFF_list <>   :A text formated list of mean enrichment array data files in gff format\n",
"\t-outFile  <>   :A filename to store the tab delimited results\n",
"\t-help          :print this help message\n";
}
