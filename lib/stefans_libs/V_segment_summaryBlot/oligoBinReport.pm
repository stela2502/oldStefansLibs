package oligoBinReport;
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

sub new {

	my ($class) = @_;

	my ( $self, $temp );

	$self = { oligoReports => $temp };

	bless $self, $class if ( $class eq "oligoBinReport" );

	return $self;

}

sub AddToOligoReport {
	my ( $self, $binLocation, $oligoValues, $celltype, $antibody ) = @_;

	#print "New Hyb condition evaluated '$celltype $antibody'\n";

	#Datenstruktur erstellen.
	unless ( defined $self->{oligoReports}->{$binLocation} ) {
		my $temp;
		$self->{oligoReports}->{$binLocation} = $temp;
	}

	#daten eintragen
	foreach my $oligoID ( keys %$oligoValues ) {
		unless ( defined $self->{oligoReports}->{$binLocation}->{$oligoID} ) {
			my $temp;
			$self->{oligoReports}->{$binLocation}->{$oligoID} = $temp;
		}
		$self->{oligoReports}->{$binLocation}->{$oligoID}
		  ->{"$celltype $antibody"} = $oligoValues->{$oligoID}->{oligoValues};

		#my $array = $self->{oligoReports}->{$oligoID}->{"$celltype $antibody"};
		#print "\t";
		#foreach my $value ( @$array){
		#	print $value,"\t";
		#}
		#print "\n";
	}
	return 1;
}

sub writeOligoReport {
	my ( $self, $outFile ) = @_;

	my ( $oligoArray, $oligoReports, $string, $i, $OligoMasterReport,
		$headerWritten, $dataLine, $oligoID_hash );
	open( OUT, ">$outFile" ) or die root::FileOpenError('root',$outFile);
	$OligoMasterReport = $self->{oligoReports};
	foreach my $binLocation ( sort keys %$OligoMasterReport ) {
		$oligoReports = $self->{oligoReports}->{$binLocation};
		$string       = "oligoID\tmean oligoBin location";
		foreach my $oligoID ( keys %$oligoReports ) {
			$dataLine     = "$oligoID\t$binLocation";
			$oligoID_hash = $oligoReports->{$oligoID};
			foreach my $hybCondition ( sort keys %$oligoID_hash ) {

				#print "$hybCondition\n";
				$oligoArray = $oligoReports->{$oligoID}->{$hybCondition};
				unless ( $headerWritten == 1 ) {
					my $i = 1;
					foreach my $temp (@$oligoArray) {
						$string = "$string\t$hybCondition #$i";
						$i++;
					}
				}
				foreach my $temp (@$oligoArray) {
					$dataLine = "$dataLine\t$temp";
				}
			}

			#unless ( $string eq "oligoID" ){
			unless ( $headerWritten == 1 ) {
				print OUT "$string\n";
				$string        = undef;
				$headerWritten = 1;

				#	}
			}
			print OUT "$dataLine\n";
			$dataLine = undef;
		}
	}
	close(OUT);
	print "Data written to file $outFile\n";
	$self->{oligoReports} = undef;
}

1;
