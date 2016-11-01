package hapMap_phase;

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
use stefans_libs::array_analysis::dataRep::hapMap_phase::haplotypeList;
use stefans_libs::array_analysis::dataRep::affy_geneotypeCalls::rs_dataset;

sub new {

	my ( $class, $phaseFile, $morganFile ) = @_;

	my ($self);

	$self = {
		phaseData   => my $temp,
		position2rs => my $pos,
		morganData  => my $data,
		'cm/Mb cutoff' => 2,
	};

	bless $self, $class if ( $class eq "hapMap_phase" );

	$self->AddPhases($phaseFile) if ( -f $phaseFile );
	print "data read from $phaseFile next comes $morganFile\n";
	$self->AddRecProbFile($morganFile) if ( -f $morganFile );
	print "data read from $morganFile\n";
	return $self;

}

sub AddPhases {
	my ( $self, $file ) = @_;
	die "this object can only be used for one chromosome!"
	  if ( defined $self->{phaseHeader} );
	open( IN, "<$file" ) or die "could not open infile $file\n,$!\n";

	#print "$self AddPhases: opened file $file\n";

	my ( $location, $rsID );
	while (<IN>) {
		chomp $_;
		unless ( defined $self->{phaseHeader} ) {
			my @line = split( " ", $_ );
			shift(@line);
			shift(@line);
			$self->{phaseHeader} = \@line;
			next;
		}
		my @line = split( " ", $_ );
		$rsID = shift(@line);

		$location = shift(@line);
		$self->{position2rs}->{$rsID} = $location;

		#print "We got a rsID $rsID\n";
		$self->{phaseData}->{$rsID} = \@line;
	}
	close(IN);
	return 1;
}

sub AddRecProbFile {
	my ( $self, $file ) = @_;
	die "this object can only be used for one chromosome!"
	  if ( defined $self->{morganHeader} );

	open( IN, "<$file" ) or die "could not open infile $file\n,$!\n";

	print "$self AddRecProbFile: opened the file $file\n";

	## here we have to create a list of haplotypeLists
	## according to the actual  cM/Mb value ( @line[1])
	## cM/Mb > 0.5 -> new Haplotype!
	## at the same time, we should create a opssible list of rsValues that would lie inside this haplotype
	## a selection of this list has to be given to the haplotypeList if we want to use it in any way!

	## scenarios: we want the get the haplotypes for a SNP_cluster

	## the List is also helpfull, if we want to select all rsIDs for a list of haplotypes from a certain chromosomal region

	#die "$self, AddRecProbFile -> here some work needs to be done!\n";

	my ( $location, $start, @haplotypeLists, @locations, $lastLocation,
		$position2rs );

	$lastLocation = 0;
	$position2rs  = $self->{position2rs};
	while ( my ( $rsID, $position ) = each %$position2rs ) {
		push( @locations, [ $rsID, $position ] );
	}
	@locations = ( sort { @$a[1] <=> @$b[1] } @locations );

	while (<IN>) {
		chomp $_;
		unless ( defined $self->{morganHeader} ) {
			my @line = split( " ", $_ );
			shift(@line);
			$self->{morganHeader} = \@line;
			next;
		}
		my @line = split( " ", $_ );
		$start = $line[0] unless ( defined $start );
		#print "recombination efficiency = $line[1]?\n";
		
		if ( $line[1] > $self->{'cm/Mb cutoff'} ) {
			## we should create a new haplotypeList
			## IF the gap is not extending...
			my ( @rsIDs, @matrix );
			while ( $locations[$lastLocation][1] < $line[0]
				&& defined $locations[$lastLocation][1] )
			{
				print "we include ", $locations[$lastLocation][0],
"into the array of rsIDs at position $locations[$lastLocation], i = $lastLocation\n";
				push( @rsIDs, $locations[$lastLocation][0] );
				push( @matrix,
					$self->{phaseData}->{ $locations[$lastLocation][0] } );
				$lastLocation++;
			}
			
			if ( @matrix < 2 ){
				$start = undef;
				next;
			}
			
			print "we create a new haplotypeList!\n";
			#	$hash->{haplotypeMatrix}
			 unless ( $start == $line[0] ){
			push(
				@haplotypeLists,
				haplotypeList->new(
					{
						start           => $start,
						end             => $line[0],
						rsIDs           => \@rsIDs,
						haplotypeNames  => $self->{phaseHeader},
						haplotypeMatrix => \@matrix
					}
				)
			);
			 }
			$start = undef;
		}
	}
	$self->{haplotypeLists} = \@haplotypeLists;
	close(IN);
	return 1;
}

sub getHaplotypes_4_rsList {
	my ( $self, $rsList ) = @_;

	my ( @return, $haplotypeList );
	$haplotypeList = $self->{haplotypeLists};
	foreach my $haplotype (@$haplotypeList) {
		push( @return, $haplotype ) if ( $haplotype->containsRSids($rsList) );
	}
	return \@return;
}

sub getHaplotypes_at_location {
	my ( $self, $start, $end ) = @_;
	my ( @list, @haplotypes, $haplotypeList );

	$haplotypeList = $self->{haplotypeLists};
	foreach (@$haplotypeList) {
		push( @list, $_ ) if ( $_->match2region( $start, $end ) );
	}
	## what to do with this regions?
	# we have to craete some full featured haplotypeLists!
	# we already have the full rsList in the haplotypeLists!
	# therefore simply return the array!
	return \@list;
}

sub transposeMatrix {
	my ( $self, $matrix ) = @_;
	my ( @new, $temp );
	foreach my $lineArray (@$matrix) {
		for ( my $i = 0 ; $i < @$lineArray ; $i++ ) {
			unless ( defined $new[$i] ) {
				my @temp;
				$new[$i] = \@temp;
			}
			$temp = $new[$i];
			push( @$temp, @$lineArray[$i] );
		}
	}
	return \@new;
}
1;
