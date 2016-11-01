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

use stefans_libs::XY_Evaluation;


my $i = @ARGV;
print "$i command line arguments\n" if ( @ARGV < 2 );

die "atribute[0]: colon separated file with region information\n",
    "atribute[1]: GFF_File location file (one file per line)\n",
	"atribute[2]: optional min override value\n",
	"stribute[3]: otional max override value\n",
    "atributes are missing!\n"
  if ( @ARGV < 2 );

open( RegionsFile, "<$ARGV[0]" )
  or die "regionXY_plot could not open region definition file!\n";

open( GFF_File, "<$ARGV[1]") 
  or die "regionXY_plot could not open gff location file\n";


my ( $hash, @regions, $pictureData, @gff, $pathModifier,$xy, @temp, $temp, $useTitle );

@gff = <GFF_File>;
#$useTitle = 1 == 1;
$useTitle = 1 == 2;

if ( $gff[0] =~ m/^PATH_MODIFIER=([\w\d_]+)/){
   $pathModifier = $1;
   $pathModifier = "noTitle_$pathModifier" unless ( $useTitle);
   print "Path modifier added: $pathModifier\n";
   $gff[0] = "#$gff[0]";
}

$pathModifier = "$pathModifier.$ARGV[2]" if ( defined $ARGV[2] );
$pathModifier = "$pathModifier-$ARGV[3]" if ( defined $ARGV[3] );
root->CreatePath("/Mass/ArrayData/Evaluation/Oligo_Bins/$pathModifier/");

for (my $i = 0; $i < @gff; $i++){
  next if ( $gff[$i] =~ m/^#/);
  $temp = $gff[$i];
  @temp = split(" ", $temp);
  $gff[$i] = $temp[0];
}

$xy = XY_Evaluation->new($pathModifier);

$xy->{minOverride} = $ARGV[2] if ( defined $ARGV[2] );
$xy->{minOverride} = undef unless ( defined $ARGV[2] );
$xy->{maxOverride} = $ARGV[3] if ( defined $ARGV[3] );
$xy->{maxOverride} = undef unless ( defined $ARGV[3] );

while (<RegionsFile>) {
    next if ( $_ =~ m/^#/ );
    chomp $_;
    (
        $hash->{gbFile},$hash->{orientation},$hash->{startBP}, $hash->{gene}
	)
      = split( ",", $_ );
    $hash->{pictureTitle} = "  " unless ( $useTitle );
    $regions[0] = $hash;
    $hash->{start} = $hash->{startBP} - 5000;
	$hash->{end} = $hash->{startBP} + 5000;
    $hash->{X_axis} = "position in chromosomal orientation [bp]";
	$hash->{pictureTitle} = "$hash->{filename} gene start" if ( $useTitle );
	$hash->{filename} = "$hash->{gene}.png";
	$hash->{binLength} = 500;
	$hash->{tableBP} = $hash->{startBP} - 30 if ( $hash->{orientation} eq "rev");
	$hash->{tableBP} = $hash->{startBP} + 30 if ( $hash->{orientation} eq "ori");

	die "the second entry in the regionList line has to be either 'ori' or 'rev' to indicate the gene orientation!\n"
		unless ( defined $hash->{tableBP});

    print "\n\ngbFile = $hash->{gbFile}\n",
           "start = $hash->{start}\n",
           "end = $hash->{end}\n",
           "X_axis = $hash->{X_axis}\n",
           "pictureTitle = $hash->{pictureTitle}\n",
           "filename = $hash->{filename}\n",
		   "oligo bin length = '$hash->{binLength}'\n",
           "data bin [bp] that should be plotet = $hash->{tableBP}\n\n\n";
		   
    $pictureData = undef;
    $pictureData =
      $xy->defineRegions( \@regions, "2005-09-08_RZPD1538_MM6_ChIP",
        $hash->{gbFile} );
    foreach my $gff (@gff){
      next if ( $gff =~ m/^#/);
      $gff = $1 if ( $gff =~ m/^(.+) #.*/);
      $pictureData =
          $xy->Add2Y_axis( $xy->GetY_axisData( $pictureData, "$gff" ),
          $hash->{start}, $hash->{end}, $hash->{binLength} );
    }
	
    $pictureData = $xy->AddX_axis( $pictureData, $hash->{start}, $hash->{end} );
	root->CreatePath("/Mass/ArrayData/Evaluation/Oligo_Bins/$pathModifier/$hash->{gene}");
	$xy->printOligoData4Bin_inBP( $pictureData, $hash->{tableBP}, "/Mass/ArrayData/Evaluation/Oligo_Bins/$pathModifier/$hash->{gene}") if (defined $hash->{tableBP});
    $xy->Plot( $pictureData, "$pathModifier-$hash->{filename}", $hash->{pictureTitle},
        $hash->{X_axis}, undef, $hash->{gbFile}, $hash->{start}, $hash->{end} );

}

sub printPlottable {
    my $pictureData = shift;
    print "Inhalt von pictureData:\n";
    foreach my $key ( keys %$pictureData ) {
        print "\t$key -> $pictureData->{$key}\n";
    }

    my $regionList = $pictureData->{regionList};
    print "Inhalt von regionList:\n";
    foreach my $region (@$regionList) {
        print "$region\n";
        while ( my ( $key, $value ) = each %$region ) {
            print "\t\t$key->$value\n";
        }
    }
}
