package MAplot;
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
use stefans_libs::root;
use stefans_libs::database::array_dataset::oligo_array_values;

sub new {

	my ($class) = @_;

	my ( $self, %A, $array_Hyb, $root );

	$array_Hyb = array_Hyb->new();
	$root      = root->new;

	$self = {
		array_Hyb => $array_Hyb,
		root      => $root,
		data      => \%A,
		value     => 0
	};

	bless( $self, $class ) if ( $class eq "MAplot" );

	return $self;
}

sub AddData {

	my ( $self, $AB, $celltype, $organism, $designID ) = @_;

	my (
		$HybInfoIDs, $infoID, $data, $table, $i, $Id
	);
	print "$AB, $celltype, $organism, $designID\n";
	$HybInfoIDs =
	  $self->{array_Hyb}
	  ->GetInfoIDs_forHybType( $AB, $celltype, $organism, $designID );
	print "AddData HybInfoIDs = $HybInfoIDs\n";
	foreach $infoID (@$HybInfoIDs) {
		print "GetData for $infoID\n";
		( $data, $i ) =
		  $self->{array_Hyb}->GetHybValue_forInfoID( $infoID, "hyb_ID" );
		$self->{value} = $i if ( $i > $self->{value} );
		unless ( defined $self->{data}->{$infoID} ) {
			my @temp;
			$self->{data}->{$infoID} = \@temp;
		}
		$table = $self->{data}->{$infoID};
		$i     = 0;
		foreach $Id ( keys %$data ) {
			@$table[ $i++ ] =
			  { 'pos' => $i, 'normalized' => log( $data->{$Id} ),
				'ID' => $Id };
		}
		$data = undef;
	}
	print "$self->{value} Datenpunkte\n";
}

sub QuantileNormalisation {
	my ($self) = @_;
	my ( $data, $AraryCount, $ArrayValue, $temp, @ZeilenweiseHybWerte );
	my ( $val, $complex, @keys );

	$data = $self->{data};

	$AraryCount = 0;

	for $ArrayValue ( keys %$data ) {
		$AraryCount++;
		$temp = $data->{$ArrayValue};
		print "SortByValue\n";
		@$temp = sort byValue @$temp;
	}
	@keys = keys %$data;
	for ( my $i = 0 ; $i < $self->{value} ; $i++ ) {
		@ZeilenweiseHybWerte = ();
		## zeilenweises iterieren über die Daten!
		foreach $ArrayValue (@keys) {
			$temp    = $data->{$ArrayValue};
			$complex = @$temp[$i];
			push( @ZeilenweiseHybWerte, $complex->{'normalized'} );
		}
		( $val, $temp ) = $self->{root}->mittelwert( \@ZeilenweiseHybWerte );

		foreach $ArrayValue (@keys) {
			$temp                    = $data->{$ArrayValue};
			$complex                 = @$temp[$i];
			$complex->{'normalized'} = exp($val);
			@$temp[$i]               = $complex;

		}
	}
	print "Normlisierung fertig!\n";
	return $temp;    #  $self->Print("QuantileNormalized");
}

sub Print {
	my ( $self, $what ) = @_;
	my (
		@M,          @A,         @data, $i,
		$valueA,     $valueB,    $logA, $logB,
		$data,       $ArrayData, $RA,   $RB,
		$arrayCount, @logA,      @logB, $median,
		$Varianz,    $StandartAbweichung
	);
	$data = $self->{data};

	#   die ; ##Hier muss ich weiter machen oder es lassen!
	$what = "" unless ( defined $what );
	$arrayCount = 0;
	foreach $ArrayData ( keys %$data ) {
		$valueA             = $data->{$ArrayData};
		@$valueA            = sort byPosition @$valueA;
		$data->{$ArrayData} = $valueA;
		$arrayCount++;
	}

	open( MA_Plot_Data, ">./MA_Plot_Data$what.dat" )
	  or die "Konnte file ./MA_Plot_Data$what.dat nicht öffnen!\n";

	## MA plots sind Vergleiche zwischen zwei Arrays
	## => bei mehreren Arrays muss ein Vergleich alle gegen alle durchgeführt werden

	## zum Anfang aber erst mal die ersten beiden gegeneinander!
	$i = 0;
	foreach $ArrayData ( keys %$data ) {
		$data[ $i++ ] = $data->{$ArrayData};
		last if ( $i == 2 );
	}

	for ( $i = 0 ; $i < $self->{value} ; $i++ ) {

		( $logA, $logB ) = ( $data[0][$i], $data[1][$i] );
		$logA = $logA->{value};
		$logB = $logB->{value};

		#      print "Print: logA / logB = $logA / $logB = ";
		#      print $logA / $logB,"\n";
		push( @logA, $logA / $logB );

		$M[$i] = $logB - $logA;
		$A[$i] = ( $logB + $logA ) / 2;

		print MA_Plot_Data "$M[$i]\t$A[$i]\n";
	}

	close(MA_Plot_Data);
	print "DataSet A / B :\n";
	( $median, $Varianz, $StandartAbweichung ) =
	  $self->{root}->getStandardDeviation( \@logA );
	print "mean = $median\n sta. dev. = $StandartAbweichung\n";

	print "Daten in ./MA_Plot_Data$what.dat abgelegt\n";
}

sub NormalisationToDB {
	my ($self) = @_;
	my ( $data, $sth_update, $infoID, $ArrayData, $entry );

	$data = $self->{data};

	foreach $infoID ( keys %$data ) {
		print
"self->{array_Hyb}->insertData($infoID,undef,\"normalized\", $data->{$infoID});\n";

		$self->{array_Hyb}
		  ->insertData( $infoID, undef, "normalized", $data->{$infoID} )
		  ;    ##UpdateData_addNormalized($infoID, $data->{$infoID});
	}
}

sub byPosition {
	return $a->{'pos'} <=> $b->{'pos'};
}

sub byValue {

	#  print "numeric $a <=> $b\n";
	return $a->{'normalized'} <=> $b->{'normalized'};
}

1;
