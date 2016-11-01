#! /usr/bin/perl
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

use stefans_libs::gbFile;
use strict;

my ( $infile, $outfile, $length) = @ARGV;

die "USAGE: identifyPrimers.pl <gb INFILE> <list OUTFILE> <int amplifier Length>\n" unless ( @ARGV == 3 );
my ( @primerList, $primer, $gbFile, $temp, $lastLocation, $oligoHash, @ampificates );

print "identify possible Amplificates in file $infile that are longer than $length bp\n";

open ( OUT ,">$outfile") or die "could not create $outfile\n";

print OUT "3' TW\t3' ID\t5' TW\t5' ID\tamplifier length[bp]\tstart [bp]\tend [bp]\n";
$gbFile = gbFile->new($infile);
my @temp = ( "primer_bind" );
$primer = $gbFile->SelectMatchingFeatures_by_Tag(\@temp);

$temp = @$primer;
print "Got $temp primer entries\n";

foreach my $feature ( @$primer ){
	unless ( defined $oligoHash -> { $feature->Name() } ){
		my ( @list1, @list2);
		$oligoHash->{ $feature->Name() } = { sense => \@list1, antisense => \@list2 };
#		print "created hashEntry for primer $feature->Name() with sense and antisense arrays $oligoHash->{ $feature->Name() }->{sense}\n";
	}
	if ( defined $feature->IsComplement ){
		$temp = $oligoHash->{ $feature->Name() } ->{ antisense };
		push ( @$temp, $feature->ExprStart() );
	}
	else{
		$temp = $oligoHash->{ $feature->Name() } ->{ sense };
        push ( @$temp, $feature->ExprStart() );
	}
}

@primerList = ( sort keys %$oligoHash);
&_recSearchForAmplificates(@primerList);
close ( OUT );
print "Amplifiers written to $outfile\n";



sub _recSearchForAmplificates{
	my ( $aktPrimer, @primerList ) = @_;

	return 0 unless ( defined $primerList[0] );
	print "compare primer $aktPrimer\n";
	my ($fixed, $variable);
	$fixed = $oligoHash -> { $aktPrimer };
	foreach my $variableP (@primerList){
		print "\tvariable Primer $variableP\n";
		&_compareStarts( 
			$aktPrimer, 
			$oligoHash -> { $aktPrimer }->{sense}, 
			$variableP, 
			$oligoHash->{$variableP}->{antisense} 
		);
		#) unless ( $aktPrimer =~ m/_int"/);;
		&_compareStarts( 
			$variableP, 
			$oligoHash->{$variableP}->{sense}, 
			$aktPrimer, 
			$oligoHash -> { $aktPrimer }->{antisense} 
		);
		#) unless ( $variableP =~ m/_int"/);;
	}
	&_recSearchForAmplificates(@primerList);
}

sub _compareStarts{
	my ( $sens_name, $sens_array, $antisense_name, $antisense_array ) = @_;
 	my ( $i, $sensTW, $sensID, $antiTW, $antiID );
	$i = 0;
	foreach my $prime3 (@$sens_array){
		$sensTW = $sensID = undef;
		($sensTW, $sensID) = ($1, $2) if ( $sens_name =~ m/(TW\d+)-l*c*l*.(.+)"/ ); 
		foreach my $prime5 (@$antisense_array){
			$antiTW = $antiID = undef;
			($antiTW, $antiID) = ($1, $2) if ( $antisense_name =~ m/(TW\d+)-l*c*l*.(.+)"/ );
			#print "$sens_name, $antisense_name, ",$prime5 - $prime3,"\t$prime3\t$prime5\n";
			if ( $prime5 - $prime3 <= $length && $prime5 - $prime3 >= 0 ){
				if ( defined $sensTW ){
					print OUT "$sensTW\t$sensID\t";
					if ( defined $antiTW ) {
						print OUT "$antiTW\t$antiID\t";
					}
					else {
						print OUT "$antisense_name\t\t";
					}
				}
				else{
					print OUT "$sens_name\t\t";
					if ( defined $antiTW ) {
	                    print OUT "$antiTW\t$antiID\t";
					}
					else {
           				print OUT "$antisense_name\t\t";
					}
				}
				print OUT $prime5 - $prime3,"bp\t$prime3\t$prime5\n";
				$i++;
			}
		}
	}
	print "\t\t$i x length < $length\n";
	return 1;
}
			




	
