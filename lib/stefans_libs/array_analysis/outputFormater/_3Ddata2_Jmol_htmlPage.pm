package _3Ddata2_Jmol_htmlPage;
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

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "_3Ddata2_Jmol_htmlPage" );

  	return $self;

}



sub htmlReport {
	my ( $self, $hash ) = @_;
	## we need hash = { outfile , html_title, log_text, log_title}
	open( LOG, ">$hash->{outfile}.html" )
	  or die "could not open logfile '$hash->{outfile}.html'\n";
	print LOG "<head>\n\t<title>$hash->{html_title}</title>\n";
	print LOG "</head>\n";

	print LOG "<body>\n";
	print LOG "\t<h1>$hash->{log_title}</h1>\n";
	print LOG "$hash->{log_text}\n";

	print LOG "</body>\n";

	close(LOG);
	return "$hash->{outfile}.html";
}

sub print3D_HTML_Report {
	my ( $self, $hash ) = @_;

	## we need hash = { outfile, html_title, jmolPath, pdb_file, type}
	
	open( OUT, ">$hash->{outfile}" )
	  or die
"could not create outfile '$hash->{outfile}' in pca_calculation printPCA_HTML_Report \n";
	print OUT "<head>\n\t<title>$hash->{html_title}</title>\n";
	print OUT "\t<h1>$hash->{html_title}</h1>\n";
	print OUT
	  "<script src=\"$hash->{jmolPath}/Jmol.js\" type=\"text/javascript\"></script> \n";
	print OUT "</head>\n";
	print OUT"  <body>
    <table>
	<tr> <td>
    <form> 
      <script type=\"text/javascript\">
        jmolInitialize(\"$hash->{jmolPath}\");

        jmolSetAppletColor(\"skyblue\"); // if you don't want black

	// 200x200 & file from another directory
	jmolApplet(400, \"load $hash->{pdb_file}\");
	jmolBr();
      </script>
    </form>
    </td> <td>
	<script>
	jmolBr();
        // a radio group
        jmolHtml(\"atoms \");
        jmolRadioGroup([
          [\"spacefill off\",  \"off\"],
          [\"spacefill 20%\",  \"20%\", \"checked\"],
          [\"spacefill 100%\", \"100%\"]
        ]);
        jmolBr();
        // a button
        jmolButton(\"reset\", \"Reset to original orientation\");
        jmolBr();
        // a checkbox
	jmolCheckbox(\"select *.cl ; spacefill 50% \", \"select *.cl  ; spacefill 20%\", \"select\");
	jmolBr();

        jmolCheckbox(\"spin on\", \"spin off\", \"spin\");
        jmolBr();
        // a link
        jmolLink(\"move 360 0 0 0 0 0 0 0 2\", \"Rotate once about the x axis\");
        jmolBr();
        // a menu
        jmolMenu([
        \"background white\",
        [\"background skyblue\", null, \"selected\"],
        \"background yellow\",
        \"background salmon\",
        \"background palegreen\",
        \"background black\"
        ]);
	</script>
     </td> <td> ",$self->{group}->histogramPic_as_HTML_Link( 400, 400) ," </td> </tr>
     </table>
     ", $self->{group}->getJmolHTMLTable4group($self->{AdditionalInfo_gin}), "
</body>
</html>\n";
	close(OUT);
	return "<a href=\"$hash->{outfile}\">$hash->{type} report</a>";
}

sub writeMatrix2pdbFile {
	my ( $self, $matrix, $outPath, $type, $scaleMax, $jmolPath ) = @_;

#0         1         2         3         4         5         6         7
#01234567890123456789012345678901234567890123456789012345678901234567890123456789
#ATOM     86  CG  ARG    11      -2.455   1.706  24.211  1.00 17.72      1AAK 146

	my ( $return, $pdbFile );

	my ( $i, @line, $i5, $i4 );
	my $formater = Number::Format->new();
	$i = 1;

#Name  	Start  	End  	Format  	Description
#recname 	0	5	A6 	a literal "ATOM  " (note two trailing spaces).
#serial 	6	10	I5 	atom serial number, e.g. "   86". See below for details.
#	11	11	1X 	space
#atom 	12	15	A4 	Atom role name, e.g. " CG1;". See below for details.
#altLoc 	16	16	A1 	atom variant, officially called the "alternate location indicator". This is usually " " for atoms with well-defined positions, as in this case, but sometimes "A", "B", etc. See below for details.
#resName 	17	19	A3 	amino acid abbreviation, e.g. "ARG". See below for details.
#	20	20	1X 	space
#chainID 	21	21	A1 	chain ID, usually " ", but often "A", "B", etc, for multichain entries. See below for details.
#Seqno 	22	26	A5 	residue sequence number (I4) and insertion code (A1), e.g. "  11 " or " 256C". See below for details.
#	27	29	3X 	three spaces
#x 	30	37	F8.3 	atom X coordinate
#y 	38	45	F8.3 	atom Y coordinate
#z 	46	53	F8.3 	atom Z coordinate
#occupancy 	54	59	F6.2 	atom occupancy, usually "  1.00". The sum of atom occupancies for all variants in field 4 generally add to 1.0.
#tempFactor 	60	65	F6.2 	B value or temperature factor, e.g. " 17.72". (I don't use this value, so have nothing to add; see the ATOM record specification discussion of B factors, etc. -- rgr, 8-Oct-96.)
#	66	71	A6 	ignored. [Some older PDB files have footnote numbers here, but this field is not described in the Format 2.1 specification. -- rgr, 22-Jan-99.]
#recID 	72	79	A8 	[prior to format version 2.0.] record identification field, e.g. "1AAK 146" (tres FORTRAN, n'est-ce pas?).
#segID 	72	75	A4 	segment identifier, left-justified. [format version 2.0 and later.]
#element 	76	77	A2 	element symbol, right-justified. [format version 2.0 and later.]
#charge 	78	79	A2 	charge on the atom. [format version 2.0 and later.]

	#warn "we have to rescale the data points!\n";

	## 1. recenter
	# center = (max + min) / 2
	# ( value - center ) = new value

	## 2. rescale
	# scalingFactor = wish max / (max - center)
	# scaled value = new value * scalingFactor
	my (
		$center1, $center2, $center3, $min1,   $min2,   $min3,
		$max1,    $max2,    $max3,    $scale1, $scale2, $scale3
	);
	$min1 = $min2 = $min3 = 1e+6;
	$max1 = $max2 = $max3 = -1e+6;

	foreach my $array (@$matrix) {
		$min1 = @$array[1] if ( @$array[1] < $min1 );
		$min2 = @$array[2] if ( @$array[2] < $min2 );
		$min3 = @$array[3] if ( @$array[3] < $min3 );

		$max1 = @$array[1] if ( @$array[1] > $max1 );
		$max2 = @$array[2] if ( @$array[2] > $max2 );
		$max3 = @$array[3] if ( @$array[3] > $max3 );
		warn "min1 = $min1; max1 = $max1 @$array\n";
		
	}
	$center1 = ( $max1 + $min1 ) / 2;
	$center2 = ( $max2 + $min2 ) / 2;
	$center3 = ( $max3 + $min3 ) / 2;
	$scale1  = $scaleMax / ( $max1 - $center1 );
	$scale2  = $scaleMax / ( $max2 - $center2 );
	$scale3  = $scaleMax / ( $max3 - $center3 );

	## use only one scale value (the smallest!)!

	#$scale1 = $scale2 if ( $scale2 < $scale1 );
	#$scale1 = $scale3 if ( $scale3 < $scale1 );
	## by definition, the first axis has to have the highest eigenvectors.
	## otherwise the pca calculated wrong!
	warn "pca_calculation writeMatrix2pdbFile rescaling!\n",
		"\tmin1 = ",$min1 - $center1,"; max1 = ",$max1 - $center1 ," => scale1 = $scale1  recenter to $center1\n",
		"\tmin2 = ",$min2 - $center1,"; max2 = ",$max1 - $center1 ," => scale2 = $scale2\n",
		"\tmin3 = ",$min3 - $center1,"; max3 = ",$max1 - $center1 ," => scale3 = $scale3\n";
	
	$scale2 = $scale3 = $scale1;
	$center2 = $center3 = $center1;

	foreach my $array (@$matrix) {
		die "too many data points to display them in RasMol! ( $i )\n "
		  if ( $i > 99999 );    # the actual Atom ID

		@$array[1] = $scale1 * @$array[1] - $center1;
		@$array[2] = $scale2 * @$array[2] - $center2;
		@$array[3] = $scale3 * @$array[3] - $center3;
	}
	## create group infos

	my $group = $self->group3D_MatrixEntries->new( $outPath, $type );

	#print "We try to craete the groups\n";
	$group->createGroups($matrix);

	#$group->print();
	#print "we try to create the grouping report!\n";
	#$group->printReport2HTMLfile();

	#print "done!\n";
	my $pdbPath = &createAbsolutePath( $outPath, $jmolPath );
	$pdbFile = "$type-3D_report.pdb";

	mkdir("$pdbPath/data/") unless ( -d "$pdbPath/data/" );
	open( OUT, ">$pdbPath/data/$pdbFile" )
	  or die
"could not create outfile '$pdbPath/data/$pdbFile' in writeMatrix2pdbFile\n";

	foreach my $array (@$matrix) {
		$i5 = "    $i" if ( $i < 10 );
		$i5 = "   $i"  if ( $i < 100 && $i > 9 );
		$i5 = "  $i"   if ( $i < 1000 && $i > 99 );
		$i5 = " $i"    if ( $i > 999 && $i < 9999 );
		$i5 = "$i"     if ( $i > 9999 );

		$i -= 9999 if ( $i > 9999 );
		$i4 = "   $i" if ( $i < 10 );
		$i4 = "  $i"  if ( $i < 100 && $i > 9 );
		$i4 = " $i"   if ( $i < 1000 && $i > 99 );
		$i4 = "$i"    if ( $i > 999 );

		$formater->{thousands_sep} = '';
		$formater->{decimal_point} = '.';

		@line = (
			"ATOM  ",                           # The ATOM Modifier
			$i5,                                # the atim unique ID
			" ",                                # space
			$group->getGroupID( @$array[0] ),   #"AR  ",      # Atom chemical ID
			" ",                                #location modifier
			"aag",                              # three digit aminoacid code
			" ",                                #space
			" ",                                # Chain ID
			"     ",                            # Seq Number - unused
			"   ",                              # three spaces
			$formater->format_picture( @$array[1], '###.###' ),    #the X
			$formater->format_picture( @$array[2], '###.###' ),    #the Y
			$formater->format_picture( @$array[3], '###.###' ),    #the Z
			" ",         #the occupancy
			"     ",     # the temperature - not used here!
			"      ",    # not used A6
			substr( @$array[0], 0, 8 ),    #old (?) identifier
			$i4,
			"  ",                          #element ??
			"  "                           #charge - none!
		);
		print OUT join( "", @line ), "\n";

		#print "DEBUG\t",join("", @line ),"\n";

		$i++;
	}
	close(OUT);

	$return =
	  printPCA_HTML_Report( "$jmolPath/data/$pdbFile", $group,
		"$outPath/$type-3D_report.html", $type );

	print "RasMol formated data (n=$i) was written to $pdbPath/data/$pdbFile\n";
	return $return;
}

sub parse_data_file {
	my ($file) = @_;

	open( IN, "<$file" )
	  or die "parse_data_file: could not open file '$file'\n";

	my ( $line, @return );
	## actually we concentrate on scores and loadings,
	## the perArray differneces and perGene differences in 3 dimensions
	$line = 0;
	while (<IN>) {
		chomp $_;
		$line++;
		next if ( $_ eq "^ *\n" );
		next if ( $line == 1 );

		my @line = split( /\t/, $_ );
		push( @return, \@line );
	}
	close(IN);

	#	foreach my $array ( @return ){
	#		print "@$array\n";
	#	}
	#	print "\n";

	return \@return;
}

sub createAbsolutePath{
	my ( $absolute, $relative ) = @_;

	$absolute = $1 if ( $absolute =~ m!(.+)/$! );
	$relative = $1 if ( $relative =~ m!(.+)/$! );

	my ( @absolute, @relative, $slice );

	@absolute = split( "/", $absolute );
	@relative = split( "/", $relative );

	#print "DEBUG createAbsolutePath\n";
	#print "\t$absolute -> @absolute\n";
	#print "\t$relative -> @relative\n";

	foreach $slice (@relative) {
		if ( $slice eq "\.\." ) {
			pop @absolute;

			#print "Ups: we got a /../ path => we remove the ", pop @absolute,
			#	"from \@absolute and create (@absolute)\n";
			next;
		}

		#print "\twe simply add $slice to @absolute\n";
		push( @absolute, $slice );
	}
	return join( "/", @absolute );
}


1;
