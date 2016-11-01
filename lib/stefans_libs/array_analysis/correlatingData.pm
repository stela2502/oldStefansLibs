package correlatingData;

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

use stefans_libs::tableHandling;
use warnings;
use Statistics::R;
use stefans_libs::array_analysis::correlatingData::KruskalWallisTest;
use stefans_libs::array_analysis::correlatingData::SpearmanTest;
use stefans_libs::array_analysis::correlatingData::Wilcox_Test;
use stefans_libs::array_analysis::correlatingData::chi_square;

sub new {

	my ( $class, $debug ) = @_;

	my ( $self, $data );

	$self = {
		data          => $data,
		debug         => $debug,
		R             => Statistics::R->new(),
		referenceLine => undef,
		tableHandling => tableHandling->new()
	};

	bless $self, $class if ( $class eq "correlatingData" );

	return $self;

}

sub AddFile {
	my ( $self, $filename) = @_;

	my ( $line, @return, @search );
	open( IN, "<$filename" )
	  or Carp::confess( "could not open '$filename' in correlatigData -> AddFile\n");
	$line   = 0;
	@search = (0);
	while (<IN>) {
		$line++;
		chomp $_;
		if ( $line == 1 ) {
			$self->{referenceLine} = $_;
			next;
		}
		$_ =~
		  s/,/\./g;  ## change from european decimal separator',' to english '.'
		$_ =~ s/n.?a.?//g; ## remove the not determined SNPs - otherwise we get only crap results!
		@return =
		  $self->{tableHandling}->get_column_entries_4_columns( $_, \@search );
		$self->{data}->{ $return[0] } = $_;
		print "we ($self) created an entry $return[0] -> $_\n" if ( $self->{debug});
	}
	close(IN);
	return 1;
}

sub getPossible_CorrelationDataSets {
	my ($self) = @_;
	my $data = $self->{data};
	return ( sort keys %$data ) if ( defined %$data );
	return undef;
}

=head2 getStatObj_4_dataLine_and_correlationValue

=head3 atributes
	
	[0]  a ref to an array containing the interesting column heades
	[1]  the name of the correlating data set (a list can be obtained by ->getListOfCorrelationData() )
	
=head3 algo

	The interesting entries are selected using the [0] argument. If no data is present in the correlating data set, the value will not be included into the return hash!

=head3 return value

	an statistical object the classes SpearmanTest, Wilcox_Test or KruskalWallisTest,
	depending on what type of grouping for the reference values was achieved
	n groups with numeric tags -> SpearmanTest (no bindings!!)
	2 groups with whatever tag -> Wilcox_Test
	< n groups with whatever tag -> KruskalWallisTest
	to 'activate' the objects, the table header line has to be given to each object ( $obj->processTableHeader($tableLine, $infoPosArrayRef ) )
	
=cut

sub getStatObj_4_dataLine_and_correlationValue {
	my ( $self, $sampleList, $correlationValue ) = @_;

	print
"\ncall to getStatObj_4_dataLine_and_correlationValue using the values $sampleList, $correlationValue\n"
	  if ( $self->{debug} );
	## here things start to get funny!
	## 1. we have to get the possible datapoints in our list that are also included in the $sampleList
	if ( $self->{debug} ) {
		print
"we try to get the correlating data set for correlationValue $correlationValue\n";
		print  "for the data lables:\n",join("; ",@$sampleList),"\n" ;
		root::print_hashEntries( $self, 4, "using the data structure");
	}
	my ( $searchHash, $valuesInArray, @correlatingData, @dataLabels );
	
	$searchHash = $self->{tableHandling}->createSearchHash(@$sampleList);
	$valuesInArray =
	  $self->{tableHandling}
	  ->identify_columns_of_interest_bySearchHash( $self->{referenceLine},
		$searchHash );

	## 2. we have to get all values that could correlate
	@dataLabels =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $self->{referenceLine}, $valuesInArray );

	@correlatingData =
	  $self->{tableHandling}
	  ->get_column_entries_4_columns( $self->{data}->{$correlationValue},
		$valuesInArray );

	
	## 3. we have to get an Idea of what should be grouped together and how that grouping should be done
	## three possibilities:
	## a: linear correlation
	## b: wilcox signed rank
	## c: annova using R::kruskal_test

	my ( $hash, $temp, $linear );
	$linear = 1 == 1;
	if ( $self->{debug}){
		print "we search for the correlating datasets in $self\n";
		root::print_hashEntries(\@correlatingData,3 , "the corelating data set:");
	}
	
	foreach ( my $i = 0 ; $i < @correlatingData ; $i++ ) {
		next unless (defined $correlatingData[$i]);
		next if ( $correlatingData[$i] =~ m/^ *$/ );
		unless ( defined $hash->{ $correlatingData[$i] } ) {
			$hash->{ $correlatingData[$i] } = [];
		}
		$linear = 1 == 0
		  unless ( $correlatingData[$i] =~ m/\d+\.?\d*[-+e]?\d*/ );
		$temp = $hash->{ $correlatingData[$i] };
		push (@$temp, $dataLabels[$i]);

	}
	my @temp = ( keys %$hash );
	
	if ( @temp == 0 ) {
		warn "$self: no corealting data for \$correlationValue $correlationValue and  (@$sampleList)\n";
		for ( my $i = 0; $i < @correlatingData; $i ++ ){
			$correlatingData[$i] = '' unless ( defined $correlatingData[$i]);
		}
		warn "we got the value set\n", join("\t",@dataLabels),"\n",join("\t",@correlatingData),"\n";
		warn "possibly we got no usable column list (@$valuesInArray)\n";
		root::print_hashEntries( $searchHash, 2, "list created using the search hash:") if ( $self->{'debug'});
		warn "and searching the line $self->{referenceLine}\n";
		return undef;
		#die;
	}
	return undef if ( @temp < 2 );

	if ($linear) {
		## perhaps we want to use a linear correlation?
		my $use = 1;
		foreach my $value (@temp) {
			$use = 0 unless ( $value =~ m/\d+\.?\d*[-+e]?\d*/ );
		}
		my $return = SpearmanTest->new( $self->{R} );
		$return->AddGroupingHash($hash);
		return $return;
	}
	if ( @temp == 2 ) {
		my $return = Wilcox_Test->new( $self->{R} );
		$return->AddGroupingHash($hash);
		return $return;
	}
	if ( @temp > 2 && @temp < @correlatingData ) {
		my $return = KruskalWallisTest->new( $self->{R} );
		$return->AddGroupingHash($hash);
		return $return;
	}
	return undef;
}

1;
