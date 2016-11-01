#! /usr/bin/perl
 
 use strict;
 use stefans_libs::tableHandling;
 use stefans_libs::array_analysis::Rbridge;
 use stefans_libs::array_analysis::affy_files::gin_file;
 use stefans_libs::array_analysis::group3D_MatrixEntries;
 use stefans_libs::root;
 use Number::Format;
 use Getopt::Long;
 
 my (
 	$infile,       $outfile, $pattern,        $firstDataLine,
 	$cutoffNumber, $help,    $phenothpeTable, $scaleMax,
 	$debug,        $jmolPath,$arrayType, $link_cutoff, $key_column
 );
 
 $scaleMax = 15;
 
 Getopt::Long::GetOptions(
 	"-infile=s"         => \$infile,
 	"-outfile=s"        => \$outfile,
 	"-p4cS=s"           => \$pattern,
 	"-NoAG=s"           => \$cutoffNumber,
 	"-help"             => \$help,
 	'-key_column=s'     => \$key_column,
 	"-firstDataLine=s"  => \$firstDataLine,
 	"-phenotypeTable=s" => \$phenothpeTable,
 	"-Jmol_path=s"      => \$jmolPath,
 	"-array_type=s"     => \$arrayType,
 	'-link_cutoff=s'    => \$link_cutoff,
 	"-debug"            => \$debug
 ) or die &helpString();
 
 die &helpString() unless ( defined $infile && defined $outfile );
 
 die &helpString() if ($help);
 
 sub helpString {
 	return "
 command line switches for pca_calculation:
 
   -infile         :the file containing the table (tab separated)
   -outfile        :the name of the outfile to visulaize the distribution in rasmol
   -firstDataLine  :the first line of data (first line has to be header)
   -p4cS           :the pattern to select the data containing columns
   -NoAG           :amount of genes that should be passed to pca (sorted by variance)
   -key_column     :one column should be the key - e.g. the 'ProbeSet ID' or something similar 
   -Jmol_path      :path to the jmol installation
   -array_type     :the location of the <affyID>.gin info file
   -help           :print this help
   -debug		  :do not evaluate the array data, just take the saved temp files
 "
 }
 
 my (
 	$identifier,        $R,             $iterator, $total,
 	$columnsOfInterest, $tableHandling, @header,   @fileData,
 	@line,              @statistics,    $mean,     $stdDef,
 	$varianz,           $root,          $temp,     $array,
 	@temp,              $outPath,       $AdditionalInfo_gin
 );
 
 $key_column = "Probe Set ID" unless ( defined $key_column );
 $R             = Rbridge->new();
 $tableHandling = tableHandling->new();
 $firstDataLine = 2 unless ( defined $firstDataLine );
 $cutoffNumber  = 100 unless ( defined $cutoffNumber );
 $root          = root->new();
 
 $iterator = $total = 0;
 
 my @outfile = split( "/", $outfile );
 splice( @outfile, @outfile - 1, 0, $cutoffNumber );
 $outfile = join( "/", @outfile );
 
 if ( defined $arrayType ){
 	$AdditionalInfo_gin = gin_file->new($arrayType);
 }
 
 pop @outfile;
 $outPath = join( "/", @outfile );
 mkdir($outPath) unless ( -d $outPath );
 
 unless ( defined $jmolPath ) {
 	$jmolPath = "../jmol";
 	warn
 "the relative path (in comparison to $outPath) to the jmol applet was set to $jmolPath\n";
 }
 die "path to the jmol is not correct! ($outPath/$jmolPath)\n"
   unless ( -f "$outPath/$jmolPath/Jmol.js" );
 
 open( LOG, ">$outfile.log" ) or die "could not open logfile '$outfile.log'\n";
 print LOG
   "$cutoffNumber genes were selected by overall variance analyzed my pca\n";
 
 unless ($debug) {
 	open( IN, "<$infile" )
 	  or die "could not open infile '$infile'\n";
 
 	while (<IN>) {
 		$iterator++;
 
 		if ( $iterator == 1 ) {    # first line!
 			$columnsOfInterest =
 			  $tableHandling->identify_columns_of_interest_patternMatch( $_,
 				$pattern );
 			@header =
 			  $tableHandling->get_column_entries_4_columns( $_,
 				$columnsOfInterest );
 			$identifier =
 			  $tableHandling->identify_columns_of_interest_patternMatch( $_,
 				$key_column );
 			push( @$identifier, @$columnsOfInterest );
 			next;
 		}
 		if ( $iterator >= $firstDataLine ) {
 			my @data =
 			  $tableHandling->get_column_entries_4_columns( $_,
 				$columnsOfInterest );
 			( $mean, $varianz, $stdDef ) =
 			  $root->getStandardDeviation( \@data );
 			@data =
 			  $tableHandling->get_column_entries_4_columns( $_, $identifier );
 			#print "we got a data entry for gene $data[0]\n";
 			my @temp = ( $varianz, \@data );
 			$statistics[ $total++ ] = \@temp;
 		}
 	}
 	$temp = NimbleGene_config::TempPath();
 	$temp = "/tmp/stefan/";
 	$temp = "$temp/temporarayFile.txt";
 
 	print "Array Data temp file = $temp\n";
 	open( TEMP, ">$temp" ) or die "could not craete temp file $temp\n";
 	print TEMP "name\t", join( "\t", @header ), "\n";
 
 	$iterator = 0;
 	foreach my $dataset ( sort { @$b[0] <=> @$a[0] } @statistics ) {
 		if ( $iterator == $cutoffNumber ) {
 			print LOG
 "we selected the $cutoffNumber genes that show the highest variance in mRNA level over the dataset.\n",
 			  "all variances lay higher than @$dataset[0]\n",
 			  "the values of the variance to be used with R:\n", "c( ",
 			  join( " ", @temp ), " )\n\n";
 			last;
 		}
 		if ( !defined @$dataset[0] ) {
 			$iterator--;
 			next;
 		}
 		push( @temp, @$dataset[0] );
 
 		#print "var: @$dataset[0]\n";
 		$array = @$dataset[1];
 		next if ( @$array[0] =~ m/^ *$/ );
 		$iterator++;
 
 		#next if ( $iterator == 1 );
 		print TEMP join( "\t", @$array ), "\n";
 	}
 	close(TEMP);
 }
 
 @header = ();
 my $temp_path = "/tmp/stefan";
 
 print
 "The first $iterator genes were included in the pca analysis, according to there overall variance\n";
 my $cmd = "
 library(pcaMethods)
 statistik<- read.table( '$temp', header = TRUE, sep = '\\t', dec = \".\", row.names = 1 )
 result <- pca(statistik, method = 'ppca', nPcs = 3, center = TRUE)
 write.table ( attr(result, 'loadings') , file = '$temp_path/loadings.txt', sep = '\\t')
 write.table ( attr(result, 'score') , file = '$temp_path/score.txt', sep = '\\t')
 ";
 print "R commands:\n$cmd";
 $R->send($cmd);
 
 
 my ( $gene_3d_Matrix, $array_3d_Matrix );
 $gene_3d_Matrix  = &parse_data_file("$temp_path/score.txt");
 $array_3d_Matrix = &parse_data_file("$temp_path/loadings.txt");
 
 #print "temp files have been read \n";
 
 @header = split( "/", $outfile );
 pop(@header);
 my ( $pdb_file, $groupLog_file, $histoFile );
 
 $outPath = join( "/", @header );
 
 # the 3D representation of the variations in the selected genes:
 my $info_gene = &writeMatrix2pdbFile( $gene_3d_Matrix, $outPath, "gene" );
 print LOG
 "the 3D representation of the variations in the selected genes is written to $pdb_file\n",
   "the histogram of the dataset is stored in $histoFile\n",
   "and the report of the grouping of the dataset is stored in $groupLog_file\n";
 
 # the 3D representation of the variation in the different samples:
 my $info_array = &writeMatrix2pdbFile( $array_3d_Matrix, $outPath, "array" );
 print LOG
 "the 3D representation of the variations in the selected genes is written to $pdb_file\n",
   "the histogram of the dataset is stored in $histoFile\n",
   "and the report of the grouping of the dataset is stored in $groupLog_file\n";
 
 $temp = &htmlReport( $info_array, $info_gene );
 print LOG "HTML report is strored in file $temp\n";
 print "log of the data is stored in $outfile.log\n";
 
 close(LOG);
 
 #print "here comes the R save files\n";
 #root::print_hashEntries($gene_3d_Matrix,2,"the gene matrix for 3d plotting");
 #root::print_hashEntries($array_3d_Matrix,2,"the array matrix for 3d plotting");
 
 sub htmlReport {
 	my ( $array_report, $gene_report ) = @_;
 
 	open( LOG, ">$outfile.html" )
 	  or die "could not open logfile '$outfile.html'\n";
 	print LOG "<head>\n\t<title>$cutoffNumber genes by variance</title>\n";
 	print LOG "</head>\n";
 
 	print LOG "<body>\n";
 	print LOG "\t<h1>Program execution summary</h1>\n";
 	print LOG
 "$cutoffNumber genes were selected by overall variance analyzed my pca<br>\n";
 
 	print LOG
 "here is the 3D representation of the pca result for the $array_report <br>and here for the $gene_report<br>\n";
 
 	print LOG "</body>\n";
 
 	close(LOG);
 	return "$outfile.html";
 }
 
 sub printPCA_HTML_Report {
 	my ( $pdb_file, $group, $outfile, $type ) = @_;
 
 	open( OUT, ">$outfile" )
 	  or die
 "could not create outfile '$outfile' in pca_calculation printPCA_HTML_Report \n";
 	print OUT "<head>\n\t<title>$cutoffNumber genes by variance</title>\n";
 	print OUT "\t<h1>PCA results for $type</h1>\n";
 	print OUT
 	  "<script src=\"$jmolPath/Jmol.js\" type=\"text/javascript\"></script> \n";
 	print OUT "</head>\n";
 	print OUT"  <body>
     <table>
 	<tr> <td>
     <form> 
       <script type=\"text/javascript\">
         jmolInitialize(\"$jmolPath\", \"JmolAppletSigned.jar\");
 
         jmolSetAppletColor(\"skyblue\"); // if you don't want black
 
 	// 200x200 & file from another directory
 	jmolApplet(400, \"load $pdb_file\");
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
      </td> <td> ",$group->histogramPic_as_HTML_Link( 400, 400) ," </td> </tr>
      </table>
      ", $group->getJmolHTMLTable4group($AdditionalInfo_gin), "
 </body>
 </html>\n";
 	close(OUT);
 	return "<a href=\"$outfile\">$type report</a>";
 }
 
 sub writeMatrix2pdbFile {
 	my ( $matrix, $outPath, $type ) = @_;
 
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
 
 	my $group = group3D_MatrixEntries->new( $outPath, $type );
 $group -> CutOff ($link_cutoff);
 	#print "We try to craete the groups\n";
 	$group->createGroups($matrix);
 
 	#$group->print();
 	#print "we try to create the grouping report!\n";
 	#$group->printReport2HTMLfile();
 
 	#print "done!\n";
 	my $pdbPath = &createAbsolutePath( $outPath, $jmolPath );
 	$pdbFile = "$type-3D_report-$cutoffNumber.pdb";
 
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
 		"$outPath/$type-3D_report-$cutoffNumber.html", $type );
 
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
