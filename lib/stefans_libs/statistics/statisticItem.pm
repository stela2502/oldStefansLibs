package statisticItem;

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

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'               => $debug,
		control               => undef,
		ip                    => undef,
		degreeFreedom         => undef,
		oligo_varianz         => undef,
		p_value               => undef,
		mean_ip               => undef,
		IP_Varianz            => undef,
		Control_Varianz       => undef,
		mean_control          => undef,
		summary_oligo_varianz => undef,
		shrinkageEstimator    => undef,
		tStatistic            => undef
	};

	bless( $self, "statisticItem" ) if ( $class eq "statisticItem" );

	return $self;
}

sub AddData {
	my ( $self, $value, $mode ) = @_;

	my ( $nimbleIDs, $ID );

	#print "and we got $value = (@$value) with the mode $mode\n";
	if ( $mode eq "control" ) {
		for ( my $i = 0 ; $i < @$value ; $i++ ) {
			@$value[$i] = log( @$value[$i] );
		}
		$self->{control} = $value;
	}
	elsif ( uc($mode) eq "IP" ) {
		for ( my $i = 0 ; $i < @$value ; $i++ ) {
			@$value[$i] = log( @$value[$i] );
		}
		$self->{ip} = $value;
	}

#print "we have added @$value with mode $mode (n=".scalar(@$value).") ".$value."\n";
#  print "statisticItem: InfoArray ref = $dataArray\n";
	return 1;
}

sub P_Value {
	my ( $self, $p_value ) = @_;
	$self->{p_value} = $p_value if ( defined $p_value );

	#   print $self->{p_value};
	return $self->{p_value};
}

sub DegreeFreedom {
	my ($self) = @_;

	return $self->{degreeFreedom} if ( defined $self->{degreeFreedom} );
	my ( $dataArray, $freedom, $ip, $control );

	$dataArray = $self->{control};

 #   print "statisticItem: DegreeFreedom control DataArray ref = $dataArray;\n";

	$self->{nimbleIDs_control} = undef;
	$self->{nimbleIDs_ip}      = undef;
	$control = @$dataArray - 1 if ( defined(@$dataArray) );

	$dataArray = $self->{ip};

	#   print "statisticItem: DegreeFreedom IP DataArray ref = $dataArray;\n";

	$ip                    = @$dataArray - 1 if ( defined(@$dataArray) );
	$freedom               = $ip + $control;
	$self->{degreeFreedom} = $freedom;

#   print "DegreeFreedom  = $self->{degreeFreedom}: IP = $ip , control = $control)!\n" if ( $self->{degreeFreedom} != 14 );
	return $self->{degreeFreedom};
}

sub MeanControl {
	my ($self) = @_;
	return $self->{mean_control} if ( defined $self->{mean_control} );
	$self->{mean_control} = $self->mittelwert( $self->{control} );
	return $self->{mean_control};
}

sub MeanIP {
	my ($self) = @_;
	return $self->{mean_ip} if ( defined $self->{mean_ip} );
	$self->{mean_ip} = $self->mittelwert( $self->{ip} );
	return $self->{mean_ip};
}

sub mittelwert($) {
	my ( $self, $Werte ) = @_;
	my @Werte = @$Werte;

	#    print @Werte,"\n";
	my $i       = 0;
	my $gesammt = 0;
	my $wert;
	foreach $wert (@Werte) {
		next unless ( defined $wert );
		$gesammt = $gesammt + $wert;
		$i++;
	}

	#    print "Summe: $gesammt\nn: $i\n";
	return ( $gesammt / $i ) unless ( $i == 0 );
	return "No Values";
}

sub OligoVarianz {
	my ($self) = @_;

	return $self->{oligo_varianz} if ( defined $self->{oligo_varianz} );

	my ( $varianz, $dataArray, $value );

	$dataArray = $self->{control};
	foreach $value (@$dataArray) {
		$self->{Control_Varianz} =
		  ( ( $value - $self->MeanControl() )**2 ) / $self->DegreeFreedom();
	}

	#  print "Varianz _ teilstop control = $varianz\n";
	$dataArray = $self->{ip};
	foreach $value (@$dataArray) {
		$self->{IP_Varianz} =
		  ( ( $value - $self->MeanIP() )**2 ) / $self->DegreeFreedom();
	}
	$self->{oligo_varianz} = $self->{IP_Varianz} + $self->{Control_Varianz};
	return $self->{oligo_varianz};
}

sub ShrinkageEstimator {
	my ( $self, $meanVariances, $quadErrorVarianze, $oligoCount ) = @_;

#  print "ShrinkageEstimator got ( $self, $meanVariances, $varianceOfVariances, $oligoCount)\n",
#        "and uses ",$self->DegreeFreedom(),"\n";

	return $self->{shrinkageEstimator}
	  if ( defined $self->{shrinkageEstimator} );

	die
"Schwerer Fehler ShrinkageEstimator needs meanVariances ($meanVariances),",
" varianceOfVariances ($quadErrorVarianze) and oligoCount ( $oligoCount)!\n"
	  unless ( @_ = 4 );

	my ( $shrinkageEstimator1, $shrinkageEstimator2 );
	$shrinkageEstimator1 =
	  ( 2 / $self->DegreeFreedom() ) / ( 1 + 2 / $self->DegreeFreedom() );
	$shrinkageEstimator1 =
	  $shrinkageEstimator1 * ( ( $oligoCount - 1 ) / $oligoCount );
	$shrinkageEstimator2 = 1 / ( 1 + 2 / $self->DegreeFreedom() );
	$shrinkageEstimator2 =
	  $shrinkageEstimator2 * ( 2 / $self->DegreeFreedom() );
	$shrinkageEstimator2 = $shrinkageEstimator2 * ( $meanVariances**2 );
	$shrinkageEstimator2 =
	  $shrinkageEstimator2 * ( ( $oligoCount - 1 ) / $quadErrorVarianze );

	$shrinkageEstimator1 += $shrinkageEstimator2;

	$self->{shrinkageEstimator} = $shrinkageEstimator1;

	return $self->{shrinkageEstimator};
}

sub SummaryOligoVarianz {
	my ( $self, $meanVariances, $varianceOfVariances, $oligoCount ) = @_;

	return $self->{summary_oligo_varianz}
	  if ( defined $self->{summary_oligo_varianz} );

	$self->{summary_oligo_varianz} = (
		1 - $self->ShrinkageEstimator(
			$meanVariances, $varianceOfVariances, $oligoCount
		)
	  ) *
	  $self->OligoVarianz() +
	  $meanVariances *
	  $self->ShrinkageEstimator( $meanVariances, $varianceOfVariances,
		$oligoCount );
	return $self->{summary_oligo_varianz};
}

sub TStatistic {
	my ( $self, $meanVariances, $varianceOfVariances, $oligoCount ) = @_;

	my ( $ip, $control ) = ( $self->{ip}, $self->{control} );

	unless ( defined $self->{tStatistic} ) {
		$ip      = scalar(@$ip);
		$control = scalar(@$control);
		
		  
		$self->{tStatistic} = ( $self->MeanControl() - $self->MeanIP() ) / (
			sqrt(
				$self->SummaryOligoVarianz(
					$meanVariances, $varianceOfVariances, $oligoCount
				)
			  ) * sqrt( ( 1 / ($ip) ) + ( 1 + ($control) ) )
		);
		
#		print "we calculate: t_stat= ( "
#		  . $self->MeanControl() . " - "
#		  . $self->MeanIP()
#		  . " ) / ( "
#		  . "sqrt( "
#		  . $self->SummaryOligoVarianz( $meanVariances, $varianceOfVariances,
#			$oligoCount )
#		  . " ) * sqrt( ( 1 / ($ip) ) + ( 1 + ($control) ) ) = $self->{tStatistic}\n";
	}

	my $return = {
		"T_Stat"               => $self->{tStatistic},
		"ShrinkageEstimator"   => $self->ShrinkageEstimator(),
		"OligoVarianz"         => $self->OligoVarianz(),
		"MeanControl"          => $self->MeanControl(),
		"MeanIP"               => $self->MeanIP(),
		"SummaryOligoVarianz"  => $self->SummaryOligoVarianz(),
		"countIP"              => $ip,
		"countControl"         => $control,
		"oligoCount"           => $oligoCount,
		"meanVariances"        => $meanVariances,
		"quadError_ofVariance" => $varianceOfVariances,
		"IP_Varianz"           => $self->{IP_Varianz},
		"Control_Varianz"      => $self->{Control_Varianz},
		"p_value"              => $self->P_Value()
	};

#  print "1.442695 * log(exp(",$return->{MeanIP},") / exp (",$return->{MeanControl},"))\n";
	$return->{GFF} =
	  1.442695 * log( exp( $return->{MeanIP} ) / exp( $return->{MeanControl} ) );

	return $return;
}

1;
