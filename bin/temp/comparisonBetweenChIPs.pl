#! /usr/bin/perl
 
 use strict;
 use stefans_libs::plot::densityMap;
 use stefans_libs::tableHandling;
 
 warn "we evaluate the files @ARGV\n";
 my ( $i, @gffObjects,@line, @header );
 
 my $outpath = shift (@ARGV);
 
 die "We need a outpath as first argument! (not $outpath)\n"
 	unless ( -d $outpath);
 
 foreach  my $filename ( @ARGV ){
 	my (@gff, @array1, @array2, @array3);
 	open ( IN , "<$filename" ) or die "could not open file $filename\n";
 	warn "I expect a file with three tab separated columns\n"; 
 	$i = 0;
 	while ( <IN> ) {
 		$i++;
 		chomp $_;
 		@line = split ( "\t",$_);
 		if ( $i == 1 ){
 			@header = ( @line) ;
 			print "we use the header ",join ("; ",@header),"\n";
 			next;
 		}
 		next if ( $_ =~ m/^#/);
 		#push ( @gff, 2**$line[5] );
 		push ( @array1, log2($line[0]));
                 push ( @array2, log2($line[1]));
                 push ( @array3, log2($line[2]));
 	}
 	close ( IN );
 	print "do we have the pictureTitles in line 0?\n@header\n";
 	&createPictures(\@header, \@array1, \@array2, \@array3 );
 	print "dataRead $filename\n";
 	print join("; ",@gff),"\n";
 	push (@gffObjects, \@gff);
 }
 
 sub log2 {
 	my ($value) = @_;
 	return log($value) / log(2);
 }
 
 sub transposeMatrix{
 	my (  $matrix) =@_;
 	my ( @newMatrix, $oldLine);
 	for ( my $new_column_count = 0; $new_column_count < @$matrix; $new_column_count++){
 		$oldLine = @$matrix[$new_column_count];
 		for (my $new_row_count = 0; $new_row_count < @$oldLine; $new_row_count ++){
 			unless ( defined $newMatrix[$new_row_count]){
 				my @temp = ();
 				$newMatrix[$new_row_count] = \@temp;
 			}
 			$newMatrix[$new_row_count]->[$new_column_count] = @$oldLine[$new_row_count];
 		}
 	}
 	return \@newMatrix;
 }
 
 sub getHeaderString{
 	my ( $string, $first, @rest ) = @_;
 	foreach my $otherName ( @rest ) {
 		$string .= "$first vs. $otherName\t";
 	}
 	return getHeaderString($string, @rest ) if ( @rest > 1);
 	return $string;	
 }
 
 sub createPictures{
 	my ( $namesArray, $array1, @arrays2compare ) = @_;
 	my ( $temp, $value, $compareArray );
 	for ( my $i = 0; $i < @arrays2compare; $i++ ) {
 		$compareArray = $arrays2compare[$i];
 		my $xyWith_Histo = densityMap->new();
 		$xyWith_Histo -> AddData( [$array1, $compareArray] );
 
 		$xyWith_Histo->plot( "$outpath/secondLevelComparison-@$namesArray[0]_@$namesArray[1+$i].svg" ,800 , 800 , @$namesArray[0] , @$namesArray[1+$i] );
 	}
 	shift ( @$namesArray);
 	return createPictures($namesArray, @arrays2compare) if ( @arrays2compare > 1 );
 }
