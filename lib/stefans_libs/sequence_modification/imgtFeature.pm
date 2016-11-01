package imgtFeature;
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
use stefans_libs::gbFile::gbRegion;
use stefans_libs::gbFile::gbFeature;

sub new {
    my ( $class, $arrayRef ) = @_;

    my ( $self, @features ,%features);

    #  print "imgtFeature->new with feature array ref $arrayRef\n";
    ## features := $tag->"string"

    $self = {
        name    => undef,
        feature => \%features,
        allFeatures => \@features,
        region  => undef,
    };

    bless( $self, $class ) if ( $class eq "imgtFeature" );

    $self->parseArray($arrayRef) if ( defined $arrayRef );

    return $self;
}

sub Name {
    my ( $self, $imgtTOgbk_hash ) = @_;

    return $imgtTOgbk_hash->{ $self->{name} }
      if ( defined $imgtTOgbk_hash->{ $self->{name} } );
    return $self->{name};
}

sub As_gbFeature {
    my ( $self, $imgtTOgbk_hash ) = @_;

    my ( $gbFeature, $features, $gbk_Tag, $featureQualifier );

    #  print "IMGT2GBK As_gbFeature: ",$self->Name($imgtTOgbk_hash),"\n";

    $features = $self->{feature};

#  print "Create gbFeature: ",$self->Name($imgtTOgbk_hash),", ",$self->{region}->getAsGB(),"\n";
    $gbFeature =
      gbFeature->new( $self->Name($imgtTOgbk_hash),
        $self->{region}->getAsGB() );

    foreach $featureQualifier ( keys %$features ) {

#      print "Feature entry $featureQualifier=\"$features->{$featureQualifier}\"\n";
        $gbFeature->AddInfo( "note",
"original featureQualifier $featureQualifier=\"$features->{$featureQualifier}\""
        );
    }

    #  print "\nFeature entry as gbFeature:\n";
    #  print $gbFeature->getAsGB(), "\n\n";

    return $gbFeature;
}

sub Allele {
    my ($self) = @_;
    return $self->{features}->{allele} if ( defined $self->{features}->{allele});
    return $self->{features}->{gene} if ( defined $self->{features}->{gene});
    return undef;
}

sub Gene {
    my ($self, $gene) = @_;
	
	if ( defined $gene){
		if ( defined $self->{features}->{gene}){
			$self->{features}->{gene} = "$self->{features}->{gene}; $gene" 
				unless ( $self->{features}->{gene} =~ m/$gene/ );
		}
		else {
			$self->{features}->{gene} = $gene;
		}
	}
    return $self->{features}->{gene} if ( defined $self->{features}->{gene});
    return $self->{features}->{allele} if ( defined $self->{features}->{allele});
    return undef;
}


sub Features{
    my ( $self) = @_;
    my $temp;
    $temp = $self->{allFeatures};
    $temp = @$temp;
#    print "IMGT Feature $self->{name} has $temp entries\n";
    return $self->{allFeatures};
}

sub LiesInRegion {
    my ( $self, $blastHit, $featuresTagToAccept ) = @_;
    my ( $use,  $features, $region );

    $region   = $blastHit->Region("hit");
    $features = $self->{feature};
    $use      = 0;
    return 1 == 2 unless ( defined $self->{region} );
    unless ( defined $featuresTagToAccept ) {
        $use = 1;
    }
    else {
        foreach my $useTag (@$featuresTagToAccept) {
            foreach my $haveTag ( keys %$features ) {
                $use = 1 if ( $useTag eq $haveTag );
            }
        }
    }
    return (
        (
                 $region->Start() <= $self->{region}->Start()
              && $region->End() >= $self->{region}->End()
        )
          && $use == 1
    );
}

sub Start {
    my ($self) = @_;
    return -2 unless ( defined $self->{region} );
    return $self->{region}->Start();
}

sub End {
    my ($self) = @_;
    return -2 unless ( defined $self->{region} );
    return $self->{region}->End();
}

sub Print {
    my ($self) = @_;
    my ($features);
    $features = $self->Features();
    print "IMGT Feature $self->{name} ", $self->{region}->getAsGB(), "\n";
    foreach my $entry ( @$features ) {
        print "\t\t@$entry[0]\t= @$entry[1]\n";
    }
}

sub AddRange {
    my ( $self, $line ) = @_;

    if ( @$line[2] =~ m/range/ ) {
        $self->{region} = gbRegion->new("@$line[4]..@$line[5]");

#    print "\n\nrange found! gbRegion @$line[4]..@$line[5] := ",$self->{region}->Start(), "  ", $self->{region}->End(),"\n\n\n";
        $self->{name} = @$line[1];
        return 1;
    }
    return undef;
}

sub ParseArray {
    my ( $self, $arrayRef ) = @_;

    foreach my $line (@$arrayRef) {

        next unless ( defined @$line );

        #    print "imgtFeature : parseArray : @$line\n";
        if ( @$line[2] eq "range" ) {

            #      print "range found!\n";
            $self->{region} = gbRegion->new("@$line[4]..@$line[5]");

#      print "\n\nrange found! gbRegion @$line[4]..@$line[5] := ",$self->{region}->Start(), "  ", $self->{region}->End(),"\n\n\n";
            $self->{name} = @$line[1];
        }
        if ( @$line[4] == 0 ) {
            $self->AddFeatureLine($line);
        }
    }
}

sub AddFeatureLine {

    my ( $self, $lineArray ) = @_;

    my ($array, @array);

    $array = $self->{allFeatures};
    @array = (@$lineArray[2],@$lineArray[3]);
    #print "!!!!!!!!!!!AddFeatureLine Added @$lineArray[2],@$lineArray[3]\n";
    push (@$array, \@array);

    $self->{features}->{@$lineArray[2]} = @$lineArray[3];
}

1;
