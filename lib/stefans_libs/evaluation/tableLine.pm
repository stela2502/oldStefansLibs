package tableLine;
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
	
    my ( $class, $gbFeature, $filename ) = @_;
	
    my ( $self, %data );
	
    die "Please Add gbFeature here!!\n" unless ( $gbFeature =~ m/gbFeature/ );
    die "Please add the gb filename here!!\n" unless ( defined $filename );
	
## filename conversion!!
    $filename = "IgH" if ( lc($filename) =~m/igh/);
    $filename = "IgK" if ( lc($filename) =~m/igk/);
    $filename = "IgL" if ( lc($filename) =~m/igl/);
    $filename = "TCRG" if ( lc($filename) =~m/tcrg/);
    $filename = "TCRB" if ( lc($filename) =~m/tcrb/);
    $filename = "TCRA" if ( lc($gbFeature->Name()) =~ m/tra/ );
    $filename = "TCRD" if ( lc($gbFeature->Name()) =~ m/trd/ );
	
    $self = {
        'gbFilename'  => $filename,  ##genbank filename
        'gbFeature' => $gbFeature,
#        'test'      => 1,
        'data'      => \%data
    };
	
    bless( $self, $class ) if ( $class eq "tableLine" );
    return $self;
}

sub IsIg_gene{
    my ( $self) = @_;
    return $self->{'gbFeature'}->IsIg_gene();
}

sub Name{
    my ( $self) = @_;
    return $self->{'gbFeature'}->Name();
}

=head2 GetActivationState

=head3 return values

The refeernce to a summary array with the structure

( { Ig_type => bool, organism, celltype,  antibody, gbFilename, feature_tag, match_to, feature_start, feature_end, summary_data} )  

=cut


sub GetActivationState{
    my ( $self) = @_;
## Get Organism/CellType/Filename/Antibody/start/end/Gen-Name/Gen-Tag/Hit-Tag/ListOf_HitLength
    my (
        $data,         $organism,      $celltype,      $antibody,
        $hitTag,       $organism_hash, $celltype_hash, $antibody_hash,
        $hitTag_array, $iteration_ref, @return,
        @temp, $return_count
		);
    $return_count = 0;
    $data = $self->{data};
    foreach $organism ( keys %$data ) {
        $organism_hash = $data->{$organism};
        print "org = ",$organism,"\n" if  defined ( $self->{test});
        foreach $celltype ( keys %$organism_hash ) {
            $celltype_hash = $organism_hash->{$celltype};
            print "cellType = ",$celltype,"\n" if  defined ( $self->{test});
            foreach $antibody ( keys %$celltype_hash ) {
                $antibody_hash = $celltype_hash->{$antibody};
                print "Antibody = ",$antibody,"\n" if  defined ( $self->{test});
                foreach $hitTag ( keys %$antibody_hash ) {
                    $hitTag_array = $antibody_hash->{$hitTag};
                    print "HitTag = ",$hitTag,"\n" if  defined ( $self->{test});
                    my (@sum, $temp);
                    for ( my $i = 1 ; $i < @$hitTag_array ; $i++ ) {
                        $iteration_ref = @$hitTag_array[$i];
                        $sum[$i-1] = 0;
                        unless ( defined @$iteration_ref ){
							$sum[$i-1] = undef;
							next;
                        }
                        for ( my $a = 0 ; $a < @$iteration_ref ; $a++ ) {
                            $sum[$i-1] += @$iteration_ref[$a]->getLength() if ( @$iteration_ref[$a] =~ m/gbFeature/);
                        }
                    }
                    $temp = {
                        Ig_type => $self->IsIg_gene(),
                        organism => $organism,
                        celltype => $celltype,
                        antibody => $antibody,
                        gbFilename => $self->{'gbFilename'},
                        feature_name => $self->{'gbFeature'}->Name(),
                        feature_tag => $self->{'gbFeature'}->Tag(),
                        match_to => $hitTag,
                        feature_start => $self->{'gbFeature'}->ExprStart(),
                        feature_end => $self->{'gbFeature'}->ExprEnd(),
                        summary_data => \@sum
                    };
                    $return[$return_count++] = $temp;
                }
            }
        }
    }
    return \@return if ( $return_count >= 1 );
	return undef;
}

sub HeaderFirstTime{
	my ( $self) = @_;
	my (@return, $matchingDataArray);
	@return = ("Organism","Celltype","Antibody","filename","gbFeature name","gbFeature tag","HMM Hit Identifier","gbFeature start","gbFeature end");
	
	$matchingDataArray = $self->GetActivationState();
	unless ( lc(@$matchingDataArray[0]) =~ m/hash/){
		warn "hier laeuft was falsch!\n",
		$self->{'gbFeature'}->getAsGB(),"\n",
		"is the data hash defined (?): '$self->{data}'\n";
		$self->PrintData();
		return undef;
	}
	$matchingDataArray = @$matchingDataArray[0]->{summary_data};
	for ( my $i = 0; $i < @$matchingDataArray; $i++){
		push (@return, "Iteration $i");
	}
	
	return join("\t", @return) if ( @return > 9);
	return undef;
}

sub PrintData{
	my ($self) = @_;
	my $Organisms = $self->{data};
	foreach my $Organism ( keys %$Organisms){
		print "Org: $Organism\n";
		my $CellTypes = $Organisms->{$Organism};
		foreach my $cellType (keys %$CellTypes){
			print "\tCT = $cellType\n";
			my $ABs = $CellTypes->{$cellType};
			foreach my $AB ( keys %$ABs){
				print "\t\tAB = $AB\n";
				my $hitRegions = $ABs->{$AB};
				foreach my $hitRegion (keys %$hitRegions){
					print "\t\t\thitRegion = $hitRegion\n";
					my $iterationData = $hitRegions->{$hitRegion};
					print "Iteration Data = ",join("  ", @$iterationData),"\n";
				}
			}
		}
	}
	print "Fertig\n";				
}

=head2 SummaryHeaderFirstTime

=cut

sub SummaryHeaderFirstTime{
	my ( $self) = @_;
	my @return = (
				  "organism", "celltype", "antibody", #"tiling array DesignID", 
				  "filename", "feature_name", "feature_tag", "start position in genomic DNA", "first iteration start < 0", "first iteration end < 0", "first iteration total < 0", "\n");
	return join("\t", @return);
}

=head2 IsEnriched

=head3 return value

returns the gbFeature if it is true or undef.

=cut

sub IsEnriched {
	my ( $self ) = @_;
	my ($GetActivationState);
	$GetActivationState = $self->GetActivationState();
	for (my $i = 0; $i < @$GetActivationState; $i++){
		return $self->{gbFeature} if ( $self->ArrayOverZero(@$GetActivationState[$i]->{summary_data}) != -1 );
	}
	return undef;
}

sub PrintFirstTime{
	my ( $self ) = @_;
	my ($GetActivationState, $return, @return);
	
	$GetActivationState = $self->GetActivationState();
	return undef unless ( defined @$GetActivationState);
	for (my $i = 0; $i < @$GetActivationState; $i++){
		$return->{@$GetActivationState[$i]->{match_to}} = @$GetActivationState[$i];
	}
	@return =(
			  $return->{start}->{organism}, $return->{start}->{celltype}, $return->{start}->{antibody}, $return->{start}->{gbFilename}, $return->{start}->{feature_name}, $return->{start}->{feature_tag},$self->{gbFeature}->Start(),$self->ArrayOverZero($return->{start}->{summary_data}), $self->ArrayOverZero($return->{end}->{summary_data}),$self->ArrayOverZero($return->{total}->{summary_data}), "\n");
	
	return undef unless ( defined $self->ArrayOverZero($return->{total}->{summary_data}));
	
	return join ("\t", @return);
}

sub ArrayOverZero{
	my ( $self, $array) = @_;
	
#  return undef unless ( defined @$array);
	return -1 unless ( defined @$array);
	for (my $i = 0 ; $i < @$array; $i++){
		return ($i + 1) if ( @$array[$i] > 0);
	}
	return -1;
} 


sub PrintBySummary {
    my ($self) = @_;
## Organism/CellType/Filename/Antibody/start/end/Gen-Name/Gen-Tag/Hit-Tag/ListOf_HitLength
    my (
        $data,         $organism,      $celltype,      $antibody,
        $hitTag,       $organism_hash, $celltype_hash, $antibody_hash,
        $hitTag_array, $iteration_ref, @sum,           @return,
        @temp
		);
	
    $data = $self->{data};
    foreach $organism ( keys %$data ) {
        $organism_hash = $data->{$organism};
        print "org = ",$organism,"\n" if  defined ( $self->{test});
        foreach $celltype ( keys %$organism_hash ) {
            $celltype_hash = $organism_hash->{$celltype};
            print "cellType = ",$celltype,"\n" if  defined ( $self->{test});
            foreach $antibody ( keys %$celltype_hash ) {
                $antibody_hash = $celltype_hash->{$antibody};
                print "Antibody = ",$antibody,"\n" if  defined ( $self->{test});
                foreach $hitTag ( keys %$antibody_hash ) {
                    $hitTag_array = $antibody_hash->{$hitTag};
                    print "HitTag = ",$hitTag,"\n" if  defined ( $self->{test});
                    for ( my $i = 1 ; $i < @$hitTag_array ; $i++ ) {
                        $iteration_ref = @$hitTag_array[$i];
                        $sum[$i-1] = 0;
                        next unless ( defined @$iteration_ref );
                        for ( my $a = 0 ; $a < @$iteration_ref ; $a++ ) {
                            $sum[$i-1] += @$iteration_ref[$a]->getLength() if ( @$iteration_ref[$a] =~ m/gbFeature/);
                        }
                    }
                    @temp = (
							 $organism,
							 $celltype,
							 $antibody,
							 $self->{'gbFilename'},
							 $self->{'gbFeature'}->Name(),
							 $self->{'gbFeature'}->Tag(),
							 $hitTag,
							 $self->{'gbFeature'}->ExprStart(),
							 $self->{'gbFeature'}->ExprEnd(),
							 join( "\t", @sum )
							 );
#                    print join( "\t", @temp ), "\n";
                    push( @return, join( "\t", @temp ) );
                }
            }
        }
    }
	return undef unless ( defined $return[0]);
    $data = join( "\n", @return );
    $data = "$data\n";
    return $data;
}

sub FeatureAsGB{
    my ( $self) = @_;
    return $self->{'gbFeature'}->getAsGB();
}

sub AddData {
	
    my ( $self, $data, $HMMfeature ) = @_;
	
## data: { Iteration, AB, CellType, Organism, hitRegion ( start, end, total )}
## write to data structure $self->{data}->{organism}->{celltype}->{AB}->{Iteration}
	
    my ($add_Here, $used);
	$self->InitData( $data, "start" );
	
    $used = 0;
    print "gbFeature Start = ",$self->{'gbFeature'}->Start(),"gbFeature End = ",$self->{'gbFeature'}->End(),
		"HMMfeature->Start() = ",$HMMfeature->Start(),"HMMfeature->End() = ",$HMMfeature->End(),"\n" if ( defined $self->{test});
#    $add_Here = $self->InitData( $data, "start" );
#    $add_Here = $self->InitData( $data, "end" );
#    $add_Here = $self->InitData( $data, "total" );
    if (   $self->{'gbFeature'}->ExprStart() > $HMMfeature->Start()
		   && $self->{'gbFeature'}->ExprStart() < $HMMfeature->End() )
    {
## Match to gbFeature Start!
        $add_Here = $self->InitData( $data, "start" );
        push( @$add_Here, $HMMfeature );
        $used = 1;
    }
    if (   $self->{'gbFeature'}->ExprEnd() > $HMMfeature->Start()
		   && $self->{'gbFeature'}->ExprEnd() < $HMMfeature->End() )
    {
## Match to gbFeature End!
        $add_Here = $self->InitData( $data, "end" );
        push( @$add_Here, $HMMfeature );
        $used = 1;
    }
    if (   $self->{'gbFeature'}->Start() < $HMMfeature->End()
		   && $self->{'gbFeature'}->End() > $HMMfeature->Start() )
    {
## Match to gbFeature Total!
        $add_Here = $self->InitData( $data, "total" );
        push( @$add_Here, $HMMfeature );
        $used = 1;
    }
    return $used;
}

sub InitData {
    my ( $self, $data, $hitRegion ) = @_;
## data: { HMM_Hit, Iteration, AB, CellType, Organism}
## write to data structure $self->{data}->{organism}->{celltype}->{AB}->{Iteration}
    if ( defined $self->{test}){
		print "InitData: \n";
		while (my ( $key, $value) = each %$data){
			print "$key -> $value\n";
		}
    }
    my ($return);
    die "the HMM iteration has to be of type <INTEGER>!\n"
		unless ( $data->{Iteration} / 2 == int( $data->{Iteration} ) / 2 );
	
    unless ( defined $self->{data}->{ $data->{Organism} } ) {
        my %temp;
        $self->{data}->{ $data->{Organism} } = \%temp;
    }
    unless (
			defined $self->{data}->{ $data->{Organism} }->{ $data->{CellType} } )
    {
        my %temp;
        $self->{data}->{ $data->{Organism} }->{ $data->{CellType} } = \%temp;
    }
    unless (
			defined $self->{data}->{ $data->{Organism} }->{ $data->{CellType} }
			->{ $data->{AB} } )
    {
        my %temp;
        $self->{data}->{ $data->{Organism} }->{ $data->{CellType} }
		->{ $data->{AB} } = \%temp;
    }
    unless (
			defined $self->{data}->{ $data->{Organism} }->{ $data->{CellType} }
			->{ $data->{AB} }->{$hitRegion} )
    {
        my @temp;
        $self->{data}->{ $data->{Organism} }->{ $data->{CellType} }
		->{ $data->{AB} }->{$hitRegion} = \@temp;
    }
    $return =
		$self->{data}->{ $data->{Organism} }->{ $data->{CellType} }
	->{ $data->{AB} }->{$hitRegion};
    unless ( defined @$return[ $data->{Iteration} ] ) {
        my @temp = (0);
        @$return[ $data->{Iteration} ] = \@temp;
    }
    return @$return[ $data->{Iteration} ];
	
}

1;
