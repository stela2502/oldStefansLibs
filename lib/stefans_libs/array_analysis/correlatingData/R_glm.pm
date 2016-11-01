package R_glm;

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

use stefans_libs::root;
use stefans_libs::array_analysis::correlatingData::stat_test;
use base ('stat_test');


sub new {
	my ($class, $R) = @_;

	my ($self);
	
	unless ( defined $R){
		$R = Statistics::R->new();
	}

	$self = {
		tableHandling => tableHandling->new(),
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0,
		match2number  => '(\d?\.?\d+)',
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

	bless $self, $class if ( $class eq "R_glm" );

	return $self;
}

sub AddGroupingHash {
	Carp::confess ( "you must not use the method AddGroupingHash - just do the calculation!");
}

sub calculateTest {
	my ( $self, $xperienced_data_array, $control_dataset_hash ) = @_;
	my $model;
	unless ( ref($xperienced_data_array) eq "ARRAY" ){
		#warn "we have no refernece data!\n";
		return "you will het an hash" ;
	}
	
	
	$self->forceRunningR();
	my $glm = 'res <- glm( x ~';
	my $cmd =
		"x<- c(".
		join( ',', @$xperienced_data_array ).
		")\n";
	foreach  ( keys %$control_dataset_hash ){
		$glm .= " $_ +";
		$cmd .= "$_ <- c (".join(', ', @{$control_dataset_hash->{$_}})." )\n";
		$model -> {"mean_$_"} = root->mean( $control_dataset_hash->{$_} );
	}
	chop ( $glm );
	$cmd .= $glm." )\nprint (res)";

	print $cmd;
	##print "R command:\n$cmd\n";
	$self->{'last_cmd'} = $cmd;
	$self->{R}->send($cmd);
	
	unless ( $self->{R}->is_started() ){
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	
	#Call:  glm(formula = x ~ y) 
	#
	#Coefficients:
	#(Intercept)            y  
	#    2.94534     -0.01406  
	#
	#Degrees of Freedom: 47 Total (i.e. Null);  46 Residual
	#Null Deviance:      1.156 
	#Residual Deviance: 1.154        AIC: -36.72 
	
	my $return = $self->{R}->read();
	$self->{lastR} = $return;
	my @return = split( "\n", $return );
	my $use = 0;
	my ( @header, @line );
	foreach ( @return ){
		if ( $_ =~ m/\(Intercept\)/ ){
			$use = 1 ;
			chomp ( $_ );
			@header = split( / +/, $_);
			next;
		}
		if ( $use ) {
			@line = split( / +/, $_);
			for ( my $i = 1; $i < @line; $i++){
				$model->{$header[$i]} = $line[$i];
			}
			last;
		}
	}
	print root::get_hashEntries_as_string($model , 3, "we got the model ");# if ( $self->{'debug'});
	return $model;
}

sub processTableHeader {

}

sub getReport {
	my $self = shift;
	die "getReport is not implemented in $self!\n";
}

1;