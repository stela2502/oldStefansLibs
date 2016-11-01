package tableHandling;

use stefans_libs::array_analysis::outputFormater::HTML_helper;
use stefans_libs::array_analysis::outputFormater::arraySorter;
use strict;

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

tableHandling

=head1 PURPOSE

The class is used to read and manipulate a tab separated table file in text format.
Its methods work on a per line basis to reduce the memory usage and speed of the table handling.
It is written in object oriented style! Always crate a object using ->new('optional_line_separator') to use the class!

For details how to use the functions please look into the source code!

=cut

sub new {

	my ( $class, $lineSeparator, $debug ) = @_;

	my ($self);
	$lineSeparator = "\t" unless defined($lineSeparator);

	$self = {
		line_separator => $lineSeparator,
		arraySorter => arraySorter->new(),
		ID_searchHash  => {
			gbID         => 'gb:(\w{2}_\d+\.?\d?)',
			debug => $debug,
			ENSMBL_ID    => '(ENSG\d{11})',
			geneID       => '\(([\w\d_-])\)',
			unclassified => '(\w[\w\d]+\d)'
		},
		html_helper => HTML_helper->new()
	};

	bless $self, $class if ( $class eq "tableHandling" );

	return $self;

}

sub sortMatrixBy{
	my  $self = shift;
	return $self->{arraySorter}->sortArrayBy(@_);
}


sub returnBioLinks{
	my ( $self, $line ) = @_;
	my $hash = $self->getBioDB_ID_hash_4_line( $line );
	my $returnHash;
	# keys in $hash ( 'gene_name', 'gbID', 'ENSMBL_ID', 'unclassified' );
	$returnHash->{"genCard"} = $self->{html_helper}->getLink_2_externalBioInfoSite_4_bioID("genCard", $hash->{gene_name});
	$returnHash->{"NCBI_mapview"} = $self->{html_helper}->getLink_2_externalBioInfoSite_4_bioID("NCBI_mapview", $hash->{gene_name});
	$returnHash->{"ENSMBL"} = $self->{html_helper}->getLink_2_externalBioInfoSite_4_bioID("ENSMBL", $hash->{ENSMBL_ID});
	$returnHash->{"google"} = $self->{html_helper}->getLink_2_externalBioInfoSite_4_bioID("google", $hash->{unclassified});
	return $returnHash;
}

sub getBioDB_ID_hash_4_line {
	my ( $self, $line ) = @_;

	my ( @line, $ID_hash, @words, $searchHash );
	@line = $self->_split_line($line);

	## identify a possible gene name
	unless ( defined $ID_hash->{gene_name} ) {
		$ID_hash->{gene_name} = $self->_search_in_array_for_pattern( '\(([\w\d][\w\d][\w\d]+)\)', \@line );
	}
	## identify possible other IDs as defined by $self->{ID_searchHash};
	$searchHash = $self->{ID_searchHash};
	while ( my ( $key, $pattern ) = each %$searchHash ) {
		$ID_hash->{$key} = $self->_search_in_array_for_pattern( $pattern, \@line );
	}
	foreach my $bioDB ( keys %$searchHash){
		
	}
	return $ID_hash;
}


sub _search_in_array_for_pattern {
	my ( $self, $pattern, $array ) = @_;
	my (@words);
	foreach my $cell (@$array) {
		@words = split( / +/, $cell );
		for ( my $i = @words - 1 ; $i > -1 ; $i-- ) {
			return $1 if ( $words[$i] =~ m/$pattern/ );
		}
	}
	return "";
}

sub identify_columns_of_interest_bySearchHash {
	my ( $self, $line, $searchHash ) = @_;

	my ( @line, @LineNumbers );

#print "DEBUG tableHandling::identify_columns_of_interest_bySearchHash got:\n$line",join(" ",(keys %$searchHash )),"\n";

	@line = $self->_split_line($line);

	unless ( defined $self->{'Gene Symbol ID'} ) {
		for ( my $i = 0 ; $i < @line ; $i++ ) {
			$self->{'Gene Symbol ID'} = $1 if ( $line[$i] eq "Gene Symbol" );
		}
	}

	for ( my $i = 0 ; $i < @line ; $i++ ) {
		$line[$i] = $1 if ( $line[$i] =~ m/ *"? *(.+) *"? */ );

#print "DEBUG identify_columns_of_interest_bySearchHash for entry '$line[$i]' using search hash values {",join(", ",(keys %$searchHash)),"}\n";
		push( @LineNumbers, $i ) if ( $searchHash->{ $line[$i] } );
	}
	return \@LineNumbers;
}

sub identify_columns_of_interest_patternMatch {
	my ( $self, $line, $pattern ) = @_;

	my ( @line, @LineNumbers );

#print "DEBUG tableHandling::identify_columns_of_interest_patternMatch got:\n$line$pattern\n";

	@line = $self->_split_line($line);
	for ( my $i = 0 ; $i < @line ; $i++ ) {
		push( @LineNumbers, $i ) if ( $line[$i] =~ m/$pattern/ );
	}
	return \@LineNumbers;
}

sub identify_columns_of_interest_NOTpatternMatch {
	my ( $self, $line, $pattern ) = @_;

	my ( @line, @LineNumbers );

#print "DEBUG tableHandling::identify_columns_of_interest_patternMatch got:\n$line$pattern\n";

	@line = $self->_split_line($line);
	for ( my $i = 0 ; $i < @line ; $i++ ) {
		push( @LineNumbers, $i ) unless ( $line[$i] =~ m/$pattern/ );
	}
	return \@LineNumbers;
}

sub get_column_entries_4_columns {
	my ( $self, $line, $lineNumbers_ref ) = @_;
	Carp::confess ( "sorry, but we need an arra ref , not '$lineNumbers_ref'" ) unless ( ref($lineNumbers_ref) eq "ARRAY");
	
	return undef unless ( defined @$lineNumbers_ref[0] );
	my ( @line, @strings );
	@line = $self->_split_line($line);
	foreach my $LoI_nr (@$lineNumbers_ref) {

#print "TableHandling get_column_entries_4_columns add value $line[$LoI_nr] (line nr. $LoI_nr)\n";
		push( @strings, $line[$LoI_nr] );
	}
	return @strings;
}

sub match_columns_of_interest_2_searchHash {
	my ( $self, $line, $lineNumbers_ref, $searchHash ) = @_;

	foreach my $lineEntry (
		$self->get_column_entries_4_columns( $line, $lineNumbers_ref ) )
	{
		$lineEntry = $1 if ( $lineEntry =~ m/ *(.+) +/ );

 #print "we try to match '$lineEntry' to ",join( ", ",(keys %$searchHash)),"\n";
		return 1 == 1 if ( $searchHash->{$lineEntry} );
	}
	return 1 == 0;
}

sub match_columns_of_interest_2_pattern {
	my ( $self, $line, $lineNumbers_ref, $pattern ) = @_;
	return 1 == 0 if ( $pattern eq "" );
	my @lineEntry =
	  $self->get_column_entries_4_columns( $line, $lineNumbers_ref );
	return 1 == 0 unless ( defined $lineEntry[0] );
	return 1 == 1 if ( "@lineEntry" =~ m/$pattern/ );
	return 1 == 0;
}

sub match_columns_of_interest_2_patternArray {
	my ( $self, $line, $lineNumbers_ref, $patternArrayRef ) = @_;

	return $self->match_columns_of_interest_2_pattern( $line, $lineNumbers_ref,
		$patternArrayRef )
	  unless ( ref($patternArrayRef) eq "ARRAY" );
	my @lineEntry =
	  $self->get_column_entries_4_columns( $line, $lineNumbers_ref );
	foreach my $pattern (@$patternArrayRef) {
		next if ( $pattern eq "" );

		#print "@lineEntry has to match with pattern $pattern\n";
		return 1 == 1 if ( "@lineEntry" =~ m/$pattern/ );
	}
	return 1 == 0;
}

sub createSearchHash {
	my ( $self, @strings ) = @_;
	
	print "We create a search hash from array ( ",join(";",@strings )," )\n" if ( $self->{'debug'});
	if ( ref( $strings[0] ) eq "ARRAY" ) {
		my $temp = $strings[0];
		@strings = @$temp;
	}
	my $hash;

	#print "DEBUG tableHandling::createSearchHash got\n@strings\n";
	foreach my $string (@strings) {
		$string = $1 if ( $string =~ m/ *"? *(.+) *"? */ );
		$hash->{$string} = 1 == 1;
	}
	return $hash;
}

sub _split_line {
	my ( $self, $line ) = @_;
	chomp $line;
	#my @temp = split( $self->{line_separator}, $line );
	#print "we split the line to \n\t",join("\n\t",@temp);
	return split( $self->{line_separator}, $line );
}

sub _split_searchString {
	my ( $self, $string ) = @_;

	#print "DEBUG tableHandling::_split_searchString got\n$string\n";
	$string = $1 if ( $string =~ m/ *" *(.+) *" */ );
	return split( ";", $string );
}

1;
