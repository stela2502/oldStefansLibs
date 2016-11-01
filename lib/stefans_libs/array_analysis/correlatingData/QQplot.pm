package stefans_libs_array_analysis_correlatingData_QQplot;
#  Copyright (C) 2012-03-19 Stefan Lang

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
use base ( 'stat_test');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_array_analysis_correlatingData_QQplot

=head1 DESCRIPTION

A tool to create QQ-plots using the R statistics package.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_array_analysis_correlatingData_QQplot.

=cut

sub new{
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


  	bless $self, $class  if ( $class eq "stefans_libs_array_analysis_correlatingData_QQplot" );

  	return $self;

}

## the only use of this object is to get an array of data and produce a qq plot for the data.
## and I only need to hope that is goes well!

=head2 qq_plot ( {
	'random_dist' => <R command filling in the variable x>,
	'values' => [],
	'outpath' => $path,
	'filename' => $filename,
	'title' => <the figure title>,
} );

=cut

sub qq_plot {
	my ( $self, $hash ) = @_;
	my $error = '';
	unlink ( $hash->{'outpath'}.'/'.$hash->{'filename'} ) if ( -f $hash->{'outpath'}.'/'.$hash->{'filename'});
	$hash->{'filename'} .= '.png' unless ( $hash->{'filename'} =~m/\.png$/);
	## Add some error handling later on!
	my $cmd = 
	'y <- c ( '.join (",", @{$hash->{'values'}}). ')
	library(ggplot2)
	qq = function(pvector, title=NULL, spartan=F) {
o = -log10(sort(pvector,decreasing=F))
#e = -log10( 1:length(o)/length(o) )
e = -log10( sort('.$hash->{'random_dist'}.',decreasing=F))
png(filename = "'.$hash->{'outpath'}.'/'.$hash->{'filename'}.'",
       width = 960, height = 960, units = "px", pointsize = 24,
       bg = "white")
plot=qplot(e,o, xlim=c(0,max(e)), ylim=c(0,max(o))) + stat_abline(intercept=0,slope=1, col="red")
plot=plot+opts(title=title)
plot=plot+scale_x_continuous(name=expression(Expected~~-log[10](italic(p))))
plot=plot+scale_y_continuous(name=expression(Observed~~-log[10](italic(p))))
plot
}

#png(filename = "'.$hash->{'outpath'}.'/'.$hash->{'filename'}.'",
#width = 960, height = 960, units = "px", pointsize = 24,
#bg = "white")
#	'.$hash->{'random_dist'}.'
#	qq <- qqplot( x,y, main="'.$hash->{'title'}.'",  ylab="Sample Quantiles", xlab="Theoretical Quantiles" )
#	fit <- lm(y ~ x, data = qq)
#	abline(fit, col="blue")
	qq ( y )
	';
	open ( ERR, ">$hash->{'outpath'}/QQscript.R" ) or die "I could not create the problematic R script!\n";
	print ERR $cmd."\n";
	close ( ERR );
	#Carp::confess ( "Check this R script: $hash->{'outpath'}/QQscript.R !\n") ;
	system ( "R CMD BATCH $hash->{'outpath'}/QQscript.R");
	Carp::confess ( "Sorry, the R command did not produce the expected outfile!\n$cmd\n(file not found '$hash->{'outpath'}/$hash->{'filename'}'\n") unless ( -f $hash->{'outpath'}.'/'.$hash->{'filename'});
	$self->{'last_cmd'} = $cmd;
	return $hash->{'outpath'}.'/'.$hash->{'filename'}
}

1;
