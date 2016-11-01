package HTML_helper;

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
use stefans_libs::array_analysis::outputFormater::arraySorter;

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		bioDB_links => {
			genCard =>
			  "http://www.genecards.org/cgi-bin/carddisp.pl?gene=USE_MY_GENE",
			NCBI_mapview =>
"http://www.ncbi.nlm.nih.gov/projects/mapview/map_search.cgi?taxid=9606&query=USE_MY_GENE&qchr=&strain=reference",
			ENSMBL =>
"http://www.ensembl.org/Homo_sapiens/Gene/Summary?db=core;g=USE_MY_GENE",
			hapmap =>
"http://www.hapmap.org/cgi-perl/snp_details_phase3?name=USE_MY_GENE&source=hapmap27_B36&tmpl=snp_details_phase3",
			google => "http://www.google.se/search?hl=se&q=USE_MY_GENE"
		},
		std_link       => "<a MODIFIERS href=\"URL\">TEXT</a>",
		arraySeparator => 100
	};

	bless $self, $class if ( $class eq "HTML_helper" );

	return $self;

}

sub getHeader {
	my ( $self, $pageName ) = @_;
	return "<head>
	<title>$pageName</title>
	</head>\n";
}

sub get_Link_2_SVG_Picture {
	my ( $self, $pictureFile, $x, $y ) = @_;

	return
"<p> <object data=\"$pictureFile\" type=\"image/svg+xml\" width=\"$x\" height=\"$y\">
    <param name=\"src\" value=\"$pictureFile\">
    Sorry your browser is not able to display the svg picture!</object> </p>\n"
	  if ( defined $x && defiend $y);
	return "<p> <object data=\"$pictureFile\" type=\"image/svg+xml\">
    <param name=\"src\" value=\"$pictureFile\">
    Sorry your browser is not able to display the svg picture!</object> </p>\n";
}

sub getLink_2_externalBioInfoSite_4_bioID {
	my ( $self, $bioDB, $bioID ) = @_;
	unless ( defined $bioID || $bioID =~ m/^ *$/ ) {
		warn "you have to define a bioID for bioDB $bioDB\n";
		return "no $bioDB ID";
	}

	warn "no predefined link for bioDB $bioDB\n"
	  unless ( defined $self->{bioDB_links}->{$bioDB} );
	my $url = $self->{bioDB_links}->{$bioDB};

	if ( $url =~ s/USE_MY_GENE/$bioID/g ) {
		return $self->getLink( $url, $bioID, "target='card'" );
	}
	return "no $bioDB ID";
}

sub printA_htmlTableFile4matrix {
	my ( $self, $tableName, $table_matrix, $outPath, $topLevelFile, $sortArray ) = @_;

	#die "UPS: the file $outPath/$tableName.html is existing\n"
	#  if ( -f "$outPath/$tableName.html" );
	mkdir($outPath) unless ( -d $outPath );
	## if the amount of data point is larger than 100,
	## we have to split the thing up!
	#print "printA_htmlTableFile4matrix we got the sort Array @$sortArray\n";
	my $tableHeader = shift(@$table_matrix);
	@$table_matrix = arraySorter::sortArrayBy($sortArray, @$table_matrix);
	unshift ( @$table_matrix, $tableHeader);
	
	if ( @$table_matrix > $self->{arraySeparator} ) {
		my @temp;
		## als erstes eine †bersicht?? Nš - keine Ahnung wie das gehen kšnnte!
		## das sollte man rekusiv machen
		## 1. den Array verkeinern und das verkleinerte ausgeben
		my $last = int( @$table_matrix / $self->{arraySeparator} + 0.999 );
		for ( my $i = 1 ; $i <= $last ; $i++ ) {
			@temp = (
				@$table_matrix[0],
				@$table_matrix[
				  ( ( $i - 1 ) * $self->{arraySeparator} )
				  .. ( $i * $self->{arraySeparator} - 1 )
				]
			) if ( $i > 1 );
			@temp = (
				@$table_matrix[
				  ( ( $i - 1 ) * $self->{arraySeparator} )
				  .. ( $i * $self->{arraySeparator} - 1 )
				]
			  )
			  if ( $i == 1 );
			$self->_tableSlices( $tableName, \@temp, $outPath, $topLevelFile,
				$i, $last );
		}
		return "$outPath/$tableName-001.html";
	}

	open( OUT, ">$outPath/$tableName.html" )
	  or die "could not create file $outPath/$tableName.html\n$!\n";
	print OUT $self->getHeader($tableName);
	print OUT "<h1> $tableName </h1> <br>\n";
	print OUT $self->getLink( $topLevelFile, "select statistic result files" ),
	  "<br>\n";
	print OUT "<table border=\"3\" frame=\"box\">\n";
	for ( my $i = 0 ; $i < @$table_matrix ; $i++ ) {
		print OUT $self->getAnHTML_tableLine4array( @$table_matrix[$i] );
	}
	print OUT "</table>\n";
	print OUT "</body>\n";
	close OUT;
	return "$outPath/$tableName.html";
}

sub _tableSlices {
	my ( $self, $tableName, $table_matrix, $outPath, $topLevel,
		$actualSlideNumber, $lastSlideNumber )
	  = @_;
	## slides start with 001 to 999
	my $number = sprintf( "%03d", $actualSlideNumber );
	open( OUT, ">$outPath/$tableName-$number.html" )
	  or die "could not craete file $outPath/$tableName-$number.html\n$!\n ";
	print OUT $self->getHeader($tableName);
	print OUT "<h1> $tableName </h1>\n";
	print OUT "<p> The data is sorted by the amount of different tests passed <br>\n",
		"the genes at the positions ",( $actualSlideNumber - 1 ) * $self->{arraySeparator}, " to ",
	  ($actualSlideNumber) * $self->{arraySeparator}, " are shown <br><br>\n";

	## navigation
	print OUT $self->getLink( "./$tableName-001.html", "first" ) if ( $actualSlideNumber > 1 );
	
    $self->printNavigation_bar ($lastSlideNumber, $tableName, $number, $actualSlideNumber, *OUT);

	## the table
	print OUT $self->getLink( $topLevel, "select statistics outfile" ),
	  "<br><br>\n";
	print OUT "<table>\n";
	print OUT "<table border=\"3\" frame=\"box\">\n";
	for ( my $i = 0 ; $i < @$table_matrix ; $i++ ) {
		print OUT $self->getAnHTML_tableLine4array( @$table_matrix[$i] );
	}
	print OUT "</table>\n";

	## navigation
	$self->printNavigation_bar ($lastSlideNumber, $tableName, $number, $actualSlideNumber, *OUT);

	print OUT "</body>\n";
	close OUT;

}

sub getLink {
	my ( $self, $url, $name, $modifiers ) = @_;
	return " -- " unless ( defined $url && defined $name );
	my $link = $self->{std_link};
	$link =~ s/URL/$url/g;
	$link =~ s/TEXT/$name/g;
	$link =~ s/MODIFIERS/$modifiers/g;
	return $link;
}

sub getAnHTML_tableLine4array {
	my ( $self, @array ) = @_;
	if ( ref( $array[0] ) eq "ARRAY" ) {
		my $temp = $array[0];
		@array = @$temp;
	}
	return "" if ( "@array" =~ m/^[ <>]*$/ );

	#the tags have to be changed to links if $AdditionalInfo_gin is defined!

	my $string = "<tr> <td>";
	$string .= join( " </td> <td> ", @array );
	$string .= " </td> </tr>\n";

	#print "new HTML table line: $string";
	return $string;
}

sub printNavigation_bar {
	my ($self, $lastSlideNumber, $tableName, $number, $actualSlideNumber, $fh ) = @_;

	print { $fh } "..." if ( $actualSlideNumber - 3 > 2 );
	for ( my $i = -3 ; $i < 4 ; $i++ ) {
		next
		  if ( $actualSlideNumber + $i < 1
			|| $actualSlideNumber + $i > $lastSlideNumber - 1 );
		next if ( $i < 0 && $actualSlideNumber + $i == 1 );
		$number = sprintf( "%03d", $actualSlideNumber + $i );
		unless ( $i == 0 ) {
			print { $fh } "-",
			  $self->getLink( "./$tableName-$number.html",
				$actualSlideNumber + $i );
		}
		elsif ( $actualSlideNumber + $i > 1 ) {
			print { $fh } "-",
			  $self->getLink( "./$tableName-$number.html", "actual" );
		}
		else {
			print { $fh } $self->getLink( "./$tableName-$number.html", "actual" );
		}

	}
	if ( $actualSlideNumber + 3 < $lastSlideNumber - 1 ) {
		print { $fh } "...";
	}
	else {
		print { $fh } "-";
	}
	$number = sprintf( "%03d", $lastSlideNumber );
	print { $fh } $self->getLink( "./$tableName-$number.html", "last" );
	print { $fh } "<br>\n";
}

1;

