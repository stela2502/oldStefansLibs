#! /usr/bin/perl -w

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

=head1 plotGBfile_with_marks.pl

plotGBfile_with_marks.pl - plot gbFiles with additional marks

=head1 SYNOPSIS

 command line switches for plotGBfile_with_marks.pl
 
=over 2

=item -infile :a file containing the SNPs of interest per default a 50kb region around the SNPs is displayed
=item -organism :the organism we should use to search for the gbFiles
=item -separator :the column separator for the infile
=item -picture_baseName :the base name for the pictures to produce
=item -help :print this help
=item -debug :verbose output
   
=back

=head1 Description

This script can use a tabluar input file with the named columns 'version', 'position' and 'description' to print
genbank entries with some further description added. 
The 'version' has to be known to the genomeDB database in oder to use get the gbFile.

The 'position' is used to identify the bp position where the 'description' should be added to the figure.
There may be multiple positions in a gbFile. Those with a distance of less than 50kb are plotted on the same plot.
Each named position is sourounded by a 25kb DNA fragment when plotted.

The picture is created in scalable vector format.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::plot::plottable_gbFile;
use stefans_libs::database::genomeDB;
use stefans_libs::tableHandling;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;

use GD::SVG;

my ( $help, $debug, $featuresFile, $organism, $genomeDB, $separator, $picture );

Getopt::Long::GetOptions(
	"-infile=s"         => \$featuresFile,
	"-organism=s"       => \$organism,
	"-separator=s"      => \$separator,
	"-picture_baseName" => \$picture,
	"-help"             => \$help,
	"-debug"            => \$debug
);

unless ( defined $organism ) {
	print helpString("we do not know which organism to analyze (-organism)!");
	exit;
}

unless ( -f $featuresFile ) {
	print helpString(
		"we need a file containing the wanted features (-infile)!");
	exit;
}

if ($help) {
	print helpString();
	exit;
}

my (
	$genome_handle, $gbFile,    $marks_hash,
	$tableHandling, $accession, $position,
	$tag,           @result,    $plottable_gbFile
);

$genomeDB      = genomeDB->new($debug);
$genome_handle = $genomeDB->GetDatabaseInterface_for_Organism($organism);

$tableHandling = tableHandling->new( $separator, $debug );

open( IN, "<$featuresFile" ) or die "could not open file '$featuresFile'\n";

while (<IN>) {
	chomp $_;
	unless ( defined $accession ) {
		$accession =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			$tableHandling->createSearchHash("version") );
		$position =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			$tableHandling->createSearchHash("position") );
		$tag =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			$tableHandling->createSearchHash("description") );
		die
'we could not find the column titles "version", "description" and "position" using the column separator "',
		  $separator, '"' . "\n in line $_"
		  unless ( defined $accession && defined $position );
		@$accession[1] = @$tag[0];
		@$accession[2] = @$position[0];
		next;
	}
	@result = $tableHandling->get_column_entries_4_columns( $_, $accession );

	$marks_hash->{ $result[0] } = []
	  unless ( defined $marks_hash->{ $result[0] } );
	push( @{ $marks_hash->{ $result[0] } }, [ $result[1], $result[2] ] );
}

close(IN);

my ( $im, $color, $font );
## now we need to make 'usable' pictures - not larger that 50kb?
@result           = ();
$plottable_gbFile = plottable_gbFile->new( undef, $debug );
$font             = Font->new();

foreach my $version ( keys %$marks_hash ) {
	if ( scalar( @{ $marks_hash->{$version} } ) > 1 ) {
		## how big is the difference??
		$position = undef;
		foreach
		  my $array ( sort { @$a[0] <=> @$b[0] } @{ $marks_hash->{$version} } )
		{
			unshift( @$array, $version );
			if ( !defined $position ) {
				$position = @$array[1];
			}
			unless ( $position + 25000 > @$array[1] ) {
				## now we create a picture!
				$im = new GD::SVG::Image( 1200, 400 );
				$color = $color->new($im);
				$plottable_gbFile->plot_2_image(
					{
						'im' => $im,
						'data' =>
						  $genome_handle->get_gbFile_for_acc( undef, $version ),
						'x_min' => 30,
						'x_max' => 1170,
						'y_min' => 30,
						'y_max' => 300,
						'color' => $color,
						'font'  => $font,
						'start' => @{ $result[0] }[1] - 25000,
						'end'   => @{ $result[ @result - 1 ] }[1] + 25000
					}
				);
				foreach my $array (@result) {
					$plottable_gbFile->addMark( $im, @$array[1], 350,
						@$array[2] );
				}
				&_writePicture(
					$im, $picture
					  . "_$version."
					  . ( @{ $result[0] }[1] - 50000 ) . '-'
					  . ( @{ $result[ @result - 1 ] }[1] + 50000 ) . ".svg"
				);
				@result = ();
			}
			push( @result, [ @$array[0], @$array[1], @$array[2] ] );
		}
	}
}

sub _writePicture {
	my ( $im, $pictureFileName ) = @_;

	# Das Bild speichern
	print "bild unter $pictureFileName speichern:\n";
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );

	#print "We print to path $path\n";
	mkdir($path) unless ( -d $path );
	$pictureFileName = "$pictureFileName.svg"
	  unless ( $pictureFileName =~ m/\.svg$/ );
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n";

	binmode PICTURE;

	print PICTURE $im->svg;
	close PICTURE;
	print "Bild als $pictureFileName gespeichert\n";
	$im = undef;
	return 1;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for plotGBfile_with_marks.pl
 
   -infile         :a file containing the SNPs of interest per default a 
                    50kb region around the SNPs is displayed
   -organism       :the organism we should use to search for the gbFiles
   -separator      :the column separator for the infile
   -picture_baseName
	               :the base name for the pictures to produce
   -help           :print this help
   -debug          :verbose output


";
}
