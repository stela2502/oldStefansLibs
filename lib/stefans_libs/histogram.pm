package histogram;
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
use stefans_libs::NimbleGene_config;
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::histogram

=head1 DESCRIPTION

This class is a MySQL wrapper that is used to access the table Design where all the different design descriptions are stored.

=head2 Depends on

L<::NimbleGene_config>

L<::root>

=head2 Provides

L<AddDataArray|"AddDataArray">

L<createGFF|"createGFF">

L<writeHistogram|"writeHistogram">


=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class designDB

=cut


sub new {

    my ($class) = @_;

    my ( $self, $dataPath, $root, $today );
    $root     = root->new;
    $today    = $root->Today();
    $dataPath = NimbleGene_config::DataPath;
    $dataPath = "$dataPath/Histograms/$today";

    $self = {
        dataPath => $dataPath,
        spread   => 1
    };
    root->CreatePath("$dataPath");
    bless( $self, $class ) if ( $class eq "histogram" );
    return $self;
}

=head2 createGFF

This method is ment to calculate the log( data1 / data2 ).

=head3 atributes

[0]: reference to the first oligo hash

[1]: reference to the second oligo hash

=head3 method

Calculates the log( $data1->{$key} / $data2->{$key} ). Therefor the two data hashes atributes[0] and atributes[1]
have to use the same keys!

=head3 return value

a reference to a array that contains the calculated values. The keys are lost!

=cut

sub createGFF {
    my ( $self, $data1, $data2 ) = @_;

    my @gff;
    foreach my $OligoID ( keys %$data1 ) {
        push( @gff, 1.442695 * log( $data1->{$OligoID} / $data2->{$OligoID} ) );
    }
    return \@gff;
}

=head2 createGFF_greedy

This method is ment to calculate the log( data1 / data2 ) of two hashes of data 
similar to L<createGFF|"createGFF">, but here the OligoID is preserved!

=head3 atributes

[0]: reference to the first oligo hash

[1]: reference to the second oligo hash

=head3 method

Calculates the log( $data1->{$key} / $data2->{$key} ). Therefor the two data hashes atributes[0] and atributes[1]
have to use the same keys!

=head3 return value

a reference to a hash with the structure { OligoID => enrichmentFactor }.

=cut


sub createGFF_greedy {
    my ( $self, $data1, $data2 ) = @_;

    my $gff;
    foreach my $OligoID ( keys %$data1 ) {
        print "OligoID = $OligoID $data1->{$OligoID} / $data2->{$OligoID} \n" if ( $data2->{$OligoID} == 0);
        $gff->{$OligoID} = ( 1.442695 * log( $data1->{$OligoID} / $data2->{$OligoID} ) );
    }
    return $gff;
}


=head2 writeHistogram

=head3 atributes

[0]: output filename

[0]: histogram data as returned by L<AddDataArray|"AddDataArray">.

=head3 method

Save the histogram data to atributes[0] in the format 'center of data bin'<TAB>'value of data bin'.

=cut



sub writeHistogram {
    my ( $self, $filename, $histo ) = @_;

#    $filename = "$self->{dataPath}/$filename";
#    $spread   = $self->{spread} unless ( defined $spread );

    $histo = $self->{data} unless (defined $histo);
    die "Sie muessen erst einen Daten Array eintragen ( ->AddDataArray )\n",
        "um diesen dann als Histogramm ausgeben zu können!\n" unless (defined $histo);
    open( DAT, ">$filename" ) or die "Konnte $filename nicht anlegen!\n";

#    print "writeHistogram Spread of data = $spread\n";
	my ( $x1, $x2);
    foreach my $temp ( sort numeric keys %$histo ) {
    	( $x1, $x2 ) = $self->getBoundary4X_value($temp);
    	print DAT ($x1+$x2) / 2 ,"\t$histo->{$temp}\n";
    }
    close(DAT);
    print "Historgram written to $filename\n";
}

sub numeric {
    return $a <=> $b;
}

sub getAsDataMatrix{
	my ( $self ) = @_;
	my @return;
	warn "$self you have to enter data before you want to get it!\n" unless ( defined  $self->{data} );
	my $i = 0;
	foreach my $temp ( sort numeric keys %{$self->{'data'}} ){
		print "we create the matrix for position $temp and value $self->{'data'}->{$temp} (i =$i)\n";
		$i++;
		my @line = ( $self->getBoundary4X_value($temp), $self->{'data'}->{$temp} );
		print "we got the line: ".join(";", @line)."\n";
		push (@return, \@line);
	}
	## matrix is of type (x1, x2, y)!
	return \@return;
}

=head2 AddDataArray

=head3 atributes

[0]: referece of a array containing the numeric data values

[1]: the spread modificator of the data bins.

=head3 method

The data values are sorted in data bins. The default bin width is 1. 
Use atributes[1] to modify this bin width ( binWidth = defaultBinWidth * atributes[1] ).

=head3 return value

a reference of a hash with the structure { center of data bin -> sum of data values }
=cut

sub AddDataArray {
    my ( $self, $data, $spread ) = @_;

    my ( $value, $hash, $scaled );
	$spread |= $self->{spread};
    $spread = 1 unless ( defined $spread );
    #print "Create a histogram using a spread of $spread\n";
    $self->{spread} = $spread;
    #print "AddDataArray Spread of data = $spread\n";
    if ( lc($data) =~ m/hash/ ){
       my @data = (values %$data);
       $data = \@data;
    }
    foreach $value (@$data) {
        next unless ( defined $value );
        print "Add value $value at position ";
        $value = $self->getPosition($value);
        print "$value ";
        $hash->{$value} = 0 unless ( defined $hash->{$value} );
        $hash->{$value}++;
        print "to a total of $hash->{$value}\n";
        $self->maxAmount($hash->{$value});
    }
    
    $self->{data} = $hash;
    return $hash;
}

sub minAmount{
	my ( $self ) = @_;
	my ( $ref, @values );
	$ref = $self->{data};
	@values = (sort {$a <=> $b} (values %$ref ) );
	#print "the min amount is $values[0] using ( @values )\n";
	return $values[0];
}

sub ScaleSumToOne {
	my ($self) = @_;

	my ( $i, $data );
	$data = $self->{data};
	die "$self->ScaleSumToOne no data present!" unless ( defined $data );
	$self->{scale21} = 1;
	$i = 0;

	while ( my ($key, $value) = each %$data){
		$i += $value unless ( $key =~ m/ARRAY/);
	}
	foreach my $value ( values %$data ) {
		$value = $value / $i;
	}
	$i = 0;
	while ( my ($key, $value) = each %$data){
		$i += $value unless ( $key =~ m/ARRAY/);
	}
	$i = $self->ScaleSumToOne() unless ($i > 0.99999);
	return $i;
}

sub maxAmount{
	my ( $self, $value) = @_;
	$self->{max} = $value if ( $value > $self->{max});
	#print "the max amount is $self->{max}\n";
	return $self->{max};
}

sub getPosition{
	my ( $self, $value ) = @_;
	#$value /= $self->{spread};
	$value -= 1 if ( $value < 0);
	return $value = int($value);
}

sub getBoundary4X_value{
	my ( $self, $x_value ) = @_;
	return undef unless ( defined $x_value );
	$x_value = $self->getPosition($x_value);
	return $x_value , ($x_value + 1);
}

1;
