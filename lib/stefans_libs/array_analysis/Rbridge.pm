package Rbridge;

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

use Statistics::R;
use strict;

sub new {

	my ($class) = @_;

	my ($self);

	$self = { R => Statistics::R->new(), match2number => '(-?\d+\.?[e\d-]+)' };

	$self->{R}->startR();
	bless $self, $class if ( $class eq "Rbridge" );
	
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

	return $self;

}

sub send{
	my ( $self, $cmd) = @_;
	
	return $self->{R}->send($cmd);
}

sub read{
	my ( $self ) = @_;
	
	return $self->{R}->read();
}


sub calculate_wilcox_statistics {
	my ( $self, $referenceData, $actualData ) = @_;

	return ('p value', 'w', 'rho' ) unless ( defined $referenceData );
	
	my @string;
	@string = (
		"x<- c(",
		join( ',', @$referenceData ),
		")\ny<-c(",
		join( ',', @$actualData ),
		")\nres <- wilcox.test( x, y, exact = 0)\n",
		"print ( res )"
	);
	my $cmd = join( '', @string );
	$self->{R}->send($cmd);
	my $return = $self->{R}->read();
	## remove the line breaks
	my @return = split( "\n", $return );
	$return = join( " ", @return );
	## select the interesting information from the R results
	my $p = $1 if ( $return =~ m/p-value *[=<] *(\d\.[e\d-]+)/ );

	#$return =~ m/(p-value *[=<] *................)/;
	return undef unless ( defined $p );
	my $w = $1 if ( $return =~ m/W *= *([\d\.]+)/ );

	my $rho = $1 if ( $return =~ m/rho *(-?[\d\.]+) *$/);

	my ( $conf_int_low, $conf_int_high, $difference ) = ( $1, $2, $3 )
	  if ( $return =~
m/confidence interval: *(-?\d+\.?[e\d-]+) +(-?\d+\.?[e\d-]+).*in location *(-?\d+\.?[e\d-]+)/
	  );
	return { 'p value' => $p, 'w' => $w, 'rho' => $rho };
}

sub calculate_spearmanWeightFit_statistics {
	my ( $self, $referenceData, $actualData ) = @_;

	return ('p value', 'S', 'rho') unless (defined $referenceData) ;
	my @string;
	@string = (
		"x<- c(",
		join( ',', @$referenceData ),
		")\ny<-c(",
		join( ',', @$actualData ),
		")\nres <- cor.test( x,y,method='spearman')\n",
		"print ( res )"
	);
	my $cmd = join( '', @string );
	$self->{R}->send($cmd);
	my $return = $self->{R}->read();
	my @return = split( "\n", $return );
	$return = join( " ", @return );
	my $p   = $1 if ( $return =~ m/p-value [=<] (\d\.\d+)/ );
	my $s   = $1 if ( $return =~ m/S *= *([\d\.]+)/ );
	my $rho = $1 if ( $return =~ m/rho *(-?[\d\.]+) *$/ );
	#print "p: $p\tspearman: $s\trho: $rho\n";
	return {'p value' => $p, 'S' => $s, 'rho' => $rho };
}

sub kruskal_test{
	my ( $self, @groups) = @_;
	## each value in the array @groups has to be a array ref to the a list 
	## of values that should be used for the non parametric anova test calculated
	return ( 'chi-squared', 'degrees of freedom', 'p-value' ) unless ( defined $groups[0] );
	my ( @temp, $result, $return );
	
	my $cmd = 
		 $self->_createRlist_fromMultipleArrayRefs( "list", @groups)." \n".
		 "result <- kruskal.test( list )\n".
		"print (result)\n";
	
	print "R command:\n", $cmd;
		
	$self->{R}->send( $cmd );
	
	$result= $self->{R}->read();
	print "result from the krustal.wallis test: \n$result\n";
	@temp = split( "\n", $result );
	$result = join( " ", @temp );
	
	$return -> {'chi-squared'} = $1 if ( $result =~ m/chi-squared [=<] $self->{match2number}/);
	$return -> {'degrees of freedom'} = $1 if ( $result =~ m/df = (\d+)/);
	$return -> {'p-value'} = $1 if ($result =~ m/p-value [<=] $self->{match2number}/);
	return $return;
}

sub _createRvariable_fromArrayRef{
	my ( $self, $variableName, $arrayRef ) = @_;
	return "$variableName <- c ( ".join( ",", @$arrayRef ) ." )" if ( defined $variableName);
	return "c ( ".join( ",", @$arrayRef ) ." )";

}


sub _createRlist_fromMultipleArrayRefs{
	my ( $self, $listName, @arrayRefs ) = @_;
	my @temp;
	#print "we try to make nice results from @arrayRefs\n";
	
	foreach my $arrayRef ( @arrayRefs){
		push ( @temp, $self->_createRvariable_fromArrayRef(undef, $arrayRef) );
	}
	return "$listName <- list ( ".join(", ", @temp )." )" if ( defined $listName);
	return "list ( ".join(",",@temp)." )";
}

1;
