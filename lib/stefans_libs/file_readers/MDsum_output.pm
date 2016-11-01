package MDsum_output;

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
use stefans_libs::fastaDB;
use stefans_libs::flexible_data_structures::data_table;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A lib to read MDsum output files.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class MDsum_output.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {

	 # a sequence will be a hash like that:
	 #{  'matrix' => data_table , 'sequences' => fastaDB,
	 #	'sens' => <str>, 'sens_deg' => <str>,  'anti_sens' => <str>,
	 #	'anti_sens_deg' => 'str', 'id'=> <int> 'Width' => <int>, 'Score' <float>,
	 #   'Sites' => <int> }
		'sequences' => []
	};

	bless $self, $class if ( $class eq "MDsum_output" );

	return $self;

}

sub readFile {
	my ( $self, $file ) = @_;
	Carp::confess("I can not open teh file '$file'\n") unless ( -f $file );
	open( IN, "<$file" );
	my @string = <IN>;
	close(IN);
	return $self->parseString( \@string );
}

sub parseString {
	my ( $self, $string ) = @_;
	unless ( ref($string) eq "ARRAY" ) {
		$string = [ split( "\n", $string ) ];
	}
	unless ( @$string[0] =~ m/\w/ ) {
		warn ref($self) . "::parseString - we did not get a string!\n";
		return 0;
	}
	my ( $line, $lastHash, $read_matrix, @matrix, $acc, $entry );
	$read_matrix = 0;
	$entry       = 0;
	foreach $line (@$string) {

		#print "we got a line $line\n";
		if ( $line =~
m/Motif (\d+): Wid (\d+); Score (\d\.\d+); Sites (\d+); Con ([ACGT]+); RCon ([AGCT]+)/
		  )
		{

			#print "we have a motife :$line\n";
			$entry = 1;
			my $lastHash = {
				'matrix'    => data_table->new(),
				'sequences' => fastaDB->new(),
				'sens'      => $5,
				'anti_sens' => $6,
				'id'        => $1,
				'Width'     => $2,
				'Score'     => $3,
				'Sites'     => $4
			};
			push( @{ $self->{'sequences'} }, $lastHash );
			next;
		}
		if ( $line =~ m/^[\* ]/ && $entry ) {
			## OK now we need to read the matrix!!
			#print "we start to read the matrix!\n";
			$entry       = 0;
			$read_matrix = 1;
			next;
		}
		elsif ( $line =~ m/^\*$/ ) {
			next;
		}
		if ( $line =~ m/>[\w\d]/ && $read_matrix ) {
			##OK - matrix ENDE
#print root::get_hashEntries_as_string (@matrix, 3, "\n\nwe create the matrix from this dataset");
			@{ $self->{'sequences'} }[ @{ $self->{'sequences'} } - 1 ]
			  ->{'matrix'}->parse_from_string( join( "", @matrix ) );
			@matrix      = undef;
			$read_matrix = 0;
		}
		if ( $line =~ m/>([\w\d\-\.#= ]+)/ ) {
			$acc = $1;

			#print "we got a acc = $acc;\n";
		}
		elsif ( $line =~ m/^([ACGT]+)$/ && defined $acc ) {

			#print "we got a seq $1 ($acc)\n";
			@{ $self->{'sequences'} }[ @{ $self->{'sequences'} } - 1 ]
			  ->{'sequences'}->addEntry( $acc, $1 );
			warn @{ $self->{'sequences'} }[ @{ $self->{'sequences'} } - 1 ]
			  ->{'sequences'}->{error}
			  if ( @{ $self->{'sequences'} }[ @{ $self->{'sequences'} } - 1 ]
				->{'sequences'}->{error} =~ m/\w/ );
			$acc = undef;
		}
		if ($read_matrix) {
			if ( $line =~ m/^  +A/ ) {
				$line = "position$line";
			}
			$line =~ s/ +/\t/g;
			push( @matrix, $line );
			next;
		}
	}
	return 1;
}

sub AsString {
	my ($self) = @_;
	my $str = '';
	foreach my $match ( @{ $self->{'sequences'} } ) {
		$str .= "Motif $match->{'id'}: Wid $match->{'Width'}; ";
		$str .= "Score $match->{'Score'}; Sites $match->{'Sites'}; ";
		$str .= "Con $match->{'sens'}; RCon $match->{'anti_sens'}\n";
		$str .= "********************************\n";
		$str .= $match->{'matrix'}->AsString();
		$str .= $match->{'sequences'}->getAsFastaDB();
		$str .= "********************************\n";
	}
	return $str;
}

1;
