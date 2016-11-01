package qValues;

#  Copyright (C) 2010-06-15 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::array_analysis::correlatingData::stat_test;
use stefans_libs::flexible_data_structures::data_table;
use base 'stat_test';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::::home::stefan_l::Link_2_My_Libs::lib::stefans_libs::array_analysis::correlatingData::qValues.pm

=head1 DESCRIPTION

A wrapper around the R qvalues library - does support almost NOTHING.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class qValues.

=cut

sub new {

	my ( $class, $R, $debug, $temp_file ) = @_;

	my ($self);
	unless ( defined $R ) {
		$R = Statistics::R->new();
	}
	$temp_file ||= '/home/stefan_l/temp/q_values.txt';
	$self = {
		tableHandling => tableHandling->new(),
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0,
		'temp_file'   => $temp_file,
		match2number  => '(\d?\.?\d+)'
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

	bless $self, $class if ( $class eq "qValues" );

	return $self;

}

sub AddDataArray {
	my ( $self, $data_array ) = @_;
	if ( defined $data_array ) {
		Carp::confess(
			ref($self)
			  . "::AddDataArray($data_array) -> we have gotten no data_array!\n"
		) unless ( ref($data_array) eq "ARRAY" );
		Carp::confess(
			ref($self)
			  . "::AddDataArray([@$data_array[0] ,...]) ->there is no data in the array that you provided!\n"
		) unless ( defined @$data_array[0] );
		$self->{'data'} = $data_array;
	}
	Carp::confess(
"Sorry, but I can not give you the data, as you did not provide any (use AddDataArray!)\n"
	) unless ( ref( $self->{'data'} ) eq "ARRAY" );
	return $self->{'data'};
}

sub calculateTest {
	my ( $self, $data_array ) = @_;
	my ( $result, $cmd );
	$data_array = $self->AddDataArray($data_array)
	  ;    ## does some checks - might need improvement!
	## now we need to write the data to a temp file!

	open( OUT, ">$self->{'temp_file'}" )
	  or die
"I could not creat the temp_file '$self->{'temp_file'}' - you might need to chage that value in the lib!\n";
	print OUT join( "\n", @$data_array );
	close(OUT);

	$cmd =
	    "library(qvalue)\n"
	  . "data <-  scan('$self->{'temp_file'}')\n"
	  . "qobj <- qvalue(data)\n"
	  . "qwrite(qobj, '$self->{'temp_file'}.qvalue.txt')\n"
	  . "res <- qsummary(qobj)\n";

	$self->{R}->send($cmd);

	unless ( $self->{R}->is_started() ) {
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	$result = $self->{R}->read();

	# the data that could be in $result:
	#Call:
	#qvalue(p = hedenfalk)
	#
	#pi0:    0.6635185
	#
	#Cumulative number of significant calls:
	#
	#        <1e-04 <0.001 <0.01 <0.025 <0.05 <0.1   <1
	#p-value     15     76   265    424   605  868 3170
	#q-value      0      0     1     73   162  319 3170
	#print "we got the result '$result'\n";
	my ( $q_value, @q_values, @result, $summary_table, $read, $i,@line );
	@result = split( "\n", $result );
	## first get the overall q_value
	$q_value = $1 if ( $result[4] =~ m/pi0:[\t ]*(\d?\.?\d+[eE]?-?\d*) */ );
	#print "and we extracted the q value $q_value from line '$result[4]'\n";
	$summary_table = data_table->new();
	$summary_table->Add_db_result( [ split( / +/, 'data_type' . $result[8] ) ],
		[ [ split( / +/, $result[9] ) ], [ split( / +/, $result[10] ) ] ]
	);
	## We have 'secured' all summary statistics - now we get the real data
	open ( IN, "<$self->{'temp_file'}.qvalue.txt") or die "could not open the q_value file $self->{'temp_file'}.qvalue.txt\n";
	$read = $i = 0;
	while ( <IN> ){
		if ( $_ =~ m/^p-value/){
			$read = 1;
			next;
		}
		next unless ( $read );
		chomp ( $_);
		@line = split( " ", $_);
		$q_values[$i++] = $line[1] if ( $line[1] =~ m/\d?\.?\d+[eE]?-?\d*/);
	}
	my $return = { 'q_values' => \@q_values, 'overall_q_value' => $q_value, 'summary_table' => $summary_table};
	unless ( scalar(@$data_array) == scalar(@q_values)){
		$return->{'error'} = ref($self)."::calculateTest - we do not have the same amount of p- and q-values!\n";
		warn $return->{'error'};
	}
	unlink($self->{'temp_file'});
	unlink("$self->{'temp_file'}.qvalue.txt" );
	return $return;
	

}

1;
