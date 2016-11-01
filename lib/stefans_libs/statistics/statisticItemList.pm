package statisticItemList;

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

#use statisticItem;
use strict;

use stefans_libs::root;
use stefans_libs::statistics::statisticItem;
use stefans_libs::database::array_dataset;
use stefans_libs::statistics::new_histogram;

## gerade gefunden: Umrechnung von lg nach log2 log2(x) = 1.442695 * ln(x) ## ln ist in perl log() !

#my @ISA = qw(ArrayDataEvaluation::GetChIP_Infos);

use strict;

sub new {
	my ($class) = @_;

	my ( $dbh, $sth, %temp, %temp2, $arrayTStat, $arrayHyb, $root );
	$root       = root->new;

	my $self = {
		root                   => $root,
		celltype               => undef,
		specificity            => undef,
		organism               => undef,
		data                   => \%temp2,
		meanVarianz            => undef,
		quadErrorVarianz       => undef,
		meanShrinkageEstimator => undef,
		oligoCount             => 0,
		chipInfos              => undef
	};

	bless( $self, "statisticItemList" );

	return $self;
}

sub CalculateStatistics {
	my ( $self ) = @_;

	my ( $sth, $rv );
	
	return $self->CalculateTStatistics();
}

sub antiNumeric {
	return $b <=> $a;
}

sub numeric {
	return $a <=> $b;
}

sub MeanVarianze {
	my ($self) = @_;
	my ( $variances, $statisticItem );

	return $self->{meanVarianz} if ( defined $self->{meanVarianz} );
	print "Calculating Mean Oligo Variance:\n";
	$variances     = $self->OligoVariances();
	$statisticItem = statisticItem::new("statisticItem");

	$self->{meanVarianz} = $statisticItem->mittelwert($variances);

	print "Mean Oligo Variance = $self->{meanVarianz}\n";

	return $self->{meanVarianz};
}

sub OligoVariances {
	my ($self) = @_;

	return $self->{oligoVariances} if ( defined $self->{oligoVariances} );

	my ( $data, $oligoID, @variances );
	$data = $self->{data};
	foreach $oligoID ( keys %$data ) {

  #     print "OligoVariances: $oligoID -> ",$data->{$oligoID}->DegreeFreedom();
		push( @variances, $data->{$oligoID}->OligoVarianz() );
	}
	$self->{oligoCount}     = @variances;
	$self->{oligoVariances} = \@variances;
	return $self->{oligoVariances};
}

sub QuadErrorVarianzes {
	my ($self) = @_;

	return $self->{quadErrorVarianz} if ( defined $self->{quadErrorVarianz} );

	#print "Calculating quadratic error of variances:\n";

	my ( $variances, $quadError, $variance );
	$variances = $self->OligoVariances();
	$quadError = 0;
	foreach $variance (@$variances) {
		$quadError += ( $variance - $self->MeanVarianze() )**2;
		#print "we get some variances ($variance) ... and the new quadError =  $quadError\n";
	}
	$self->{quadErrorVarianz} = $quadError;

	#print "quadratic error of variances = $self->{quadErrorVarianz}\n";

	return $self->{quadErrorVarianz};
}

sub CalculateTStatistics {
	my ($self) = @_;
	my (
		$data, $TStat,      $hash,  @P_Value, $i,
		@temp, $last_Value, $count, $temp,    $OligoID
	);

	print "Create TStatistrics\n";

	open( ERROR, ">TStatistic_Error.log" )
	  or die "Konnte File TStatistic_Error.log nicht öffnen!\n";
	foreach $OligoID ( keys %{$self->{'data'}} ) {
		if ( $self->{'data'}->{$OligoID}->DegreeFreedom() < 1 ) {
			print ERROR "$OligoID DegreeFreedom = ",
			  $self->{'data'}->{$OligoID}->DegreeFreedom(), "\n";
			next;
		}
		$hash =
		  $self->{'data'}->{$OligoID}
		  ->TStatistic( $self->MeanVarianze(), $self->QuadErrorVarianzes(),
			$self->{oligoCount} );
		$TStat->{$OligoID} = [$hash->{"T_Stat"}] ;
		push ( @temp, $hash->{"T_Stat"} );
		#print "we got the T_Stat $hash->{T_Stat} \n";
		#push( @P_Value, { value => $hash->{"T_Stat"}, ID => $OligoID } );
	}

	my $new_histogram = new_histogram->new("histogram over the summary statistics values");
	$new_histogram -> CreateHistogram ( \@temp, undef , int(scalar(@temp) / 100) );
	
	$new_histogram -> plot( { 'outfile' => "summary_statistics_$$.svg"} );
	print "histogram over the summary statistics wasa plotted to 'summary_statistics_$$.svg'\n";
	
	return $TStat;
}

sub byTStat {
	return $b->{value} <=> $a->{value};
}

sub PrintTStatistics {
	my ($self) = @_;

	my ( $infoID, $data, @dbData, $i, $OligoID, $hash );

	$data = $self->{data};
	if (
		$self->{arrayTStat}->DataExists(
			$self->{specificity}, $self->{celltype},
			$self->{organism},    $self->{designID}
		)
	  )
	{
		print "Die Array TStat Daten werden ueberschieben!\n";
	}

	print "TStatistic(", $self->MeanVarianze(), ",",
	  $self->QuadErrorVarianzes(), ",", $self->{oligoCount}, ")\n";
	$i = 0;
	foreach $OligoID ( keys %$data ) {
		next if ( $data->{$OligoID}->DegreeFreedom() < 1 );
		$hash =
		  $data->{$OligoID}
		  ->TStatistic( $self->MeanVarianze(), $self->QuadErrorVarianzes(),
			$self->{oligoCount} );

		unless ( defined $hash->{GFF} ) {
			print
"$OligoID 1.442695 * log(exp($hash->{MeanIP})  / exp($hash->{MeanControl})) !!\n";
			next;
		}

		push(
			@dbData,
			{
				't-value'         => $hash->{T_Stat},
				'oligoID'         => $OligoID,
				'GFF'             => $hash->{GFF},
				'IP_varianz'      => $hash->{IP_Varianz},
				'Control_varianz' => $hash->{Control_Varianz}
			}
		);

	}
	$self->{arrayTStat}->insertData(
		$self->{specificity}, $self->{celltype}, $self->{organism},
		$self->{designID},    \@dbData
	);
}

sub AddData {
	my ( $self, $data_array, $mode ) = @_;

	my ( $oligoID, $count );
	$count = 0;

	foreach my $dataLine (@$data_array) {
		
		$oligoID = shift(@$dataLine);
		unless ( defined $self->{data}->{$oligoID} ) {
			$self->{data}->{$oligoID} = statisticItem->new( $self->{'debug'} );
		}
		#print $self.":AddData we got a data line @$dataLine and add the data to $self->{data}->{$oligoID}\n";
		$self->{data}->{$oligoID}->AddData( $dataLine, $mode );
		$count++;
	}

	#print "we added $count oligo values\n" if ( $self->{'debug'} );
	return $self->{data};
}

1;

