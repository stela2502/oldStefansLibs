package stefans_libs_array_analysis_correlatingData_FDR_calculation;
#  Copyright (C) 2011-12-21 Stefan Lang

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


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_array_analysis_correlatingData_FDR_calculation

=head1 DESCRIPTION

This lib is a R interface and uses the p.adjust method on an array of p values. The lib returns an array in the same order containing the results of the calulation. You can use any method of the p.adjust methods, but the 'BH' will be used by default.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_array_analysis_correlatingData_FDR_calculation.

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

	bless $self, $class if ( $class eq "stefans_libs_array_analysis_correlatingData_FDR_calculation" );

	return $self;

} 

sub TempFile {
	my ( $self, $tempfile ) = @_;
	$self->{'temp_file'} = $tempfile if ( defined $tempfile );
	return $self->{'temp_file'};
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

sub Method {
	my ( $self, $method ) = @_;
	$self->{'method'} = $method;
	$self->{'method'} = "BN" unless ( defined $self->{'method'} );
	return $self->{'method'};
}

sub calculateTest {
	my ( $self, $data_array ) = @_;
	my ( $result, $cmd );
	$data_array = $self->AddDataArray($data_array)
	  ;    ## does some checks - might need improvement!
	## now we need to write the data to a temp file!

	open( OUT, ">$self->{'temp_file'}" )
	  or die
"I could not creat the temp_file '$self->{'temp_file'}' - you might need to change that value in the lib!\n";
	print OUT join( " ", @$data_array );
	close(OUT);
	unlink ( "$self->{'temp_file'}.qvalue.txt" ) if ( -f "$self->{'temp_file'}.qvalue.txt");
	$cmd =
	    "library(qvalue)\n"
	  . "data <-  scan('$self->{'temp_file'}')\n"
	  . "qobj <- p.adjust(data, method = '".$self->Method()."')\n"
	  . "cat(qobj, file='$self->{'temp_file'}.qvalue.txt', sep=' ')\n";

	$self->{R}->send($cmd);

	unless ( $self->{R}->is_started() ) {
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	open ( IN, "<$self->{'temp_file'}.qvalue.txt" ) or die "Somehow the R process did not create the results file!\n$!\n";
	my @result;
	foreach ( <IN>){
		chomp ($_);
		push ( @result,split( " ", $_ ));
	}
	close ( IN );
	return \@result;
}

1;
