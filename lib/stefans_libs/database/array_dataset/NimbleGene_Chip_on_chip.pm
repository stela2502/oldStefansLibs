package NimbleGene_Chip_on_chip;

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
use warnings;

use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::pairFile;
use stefans_libs::database::array_dataset::oligo_array_values;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A datahandler object, that is able to handle nimblege ChIP on chip datasets. 
This object is not a table interface, but it can be used to insert and 
to get Nimbelege 'ChIP on chip' data out of the database.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class NimbleGene_Chip_on_chip.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die $class, ":new -> we need a DBI object at startup!(not $dbh)\n$!"
	  unless ( defined $dbh && $dbh =~ m/DBI::db/ );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "NimbleGene_Chip_on_chip" );

	return $self;

}

sub expected_dbh_type {
	return "not a primary table handler";
}

sub check_dataset {
	my ( $self, $dataset ) = @_;

	$self->{error} = '';
	my $pairFile = pairFile->new();

	unless ( defined $dataset->{'data_values'}->{'IP'} ) {
		#print
#"we check for the dataset->{'data'}->{'IP'} value ($dataset->{'data'}->{'IP'})\n";
		if ( defined $dataset->{'data'}->{'IP'} ) {
			$dataset->{'data_values'}->{'IP'} =
			  $pairFile->GetData( $dataset->{'data'}->{'IP'} );
			$self->{'error'} .= $pairFile->{'error'};
		}
		else {
			$self->{error} .= ref($self)
			  . ":check_dataset -> check the array_type 'NimbleGene chip on chip': we lack a 'IP' entry\n";
		}
	}
	unless ( defined $dataset->{'data_values'}->{'INPUT'} ) {
		if ( defined $dataset->{'data'}->{'INPUT'} ) {
			$dataset->{'data_values'}->{'INPUT'} =
			  $pairFile->GetData( $dataset->{'data'}->{'INPUT'} );
			$self->{'error'} .= $pairFile->{'error'};
		}
		else {
			$self->{error} .= ref($self)
			  . ":Check_Array_Dataset -> check the array_type 'chip on chip': we lack a 'INPUT' entry\n";
		}
	}
	unless ( defined $dataset->{'data_values'}->{'GFF'} ) {
		if ( defined $dataset->{'data'}->{'GFF'} ) {
			## ok - no calculation needed!
			unless ( -f $dataset->{'data'}->{'GFF'} ) {
				$self->{error} .= ref($self)
				  . ":Check_Array_Dataset -> check the array_type 'chip on chip': found a gff_file antry but the file is not accessable!\n";
			}
			else {
				my $gffFile = gffFile->new();
				$dataset->{data_values}->{'GFF'} =
				  $gffFile->GetData( $dataset->{'data'}->{'GFF'} );
				$self->{'error'} .= $pairFile->{'error'};
				$gffFile = undef;
			}
		}
		elsif (defined $dataset->{'data_values'}->{'INPUT'}
			&& defined $dataset->{'data_values'}->{'IP'} )
		{
			## shit - we have to calculate the enrichment factors...
			## but at least we are able to do so....

			my ( $oligoID, $gffData );

			foreach $oligoID ( keys %{ $dataset->{'data_values'}->{'IP'} } ) {
				$gffData->{$oligoID} =
				  log2( $dataset->{'data_values'}->{'IP'}->{$oligoID} /
					  $dataset->{'data_values'}->{'INPUT'}->{$oligoID} );
				#print ref($self)."::check_dataset -> we calculated GFF = $gffData->{$oligoID} for oligoID $oligoID\n";
			}
			my $median = $self->Tukey_BiWeight( [ values %$gffData ] );
			#print ref($self)."::check_dataset -> we have calculated the Tukey_BiWeight mean ($median)\n";
			foreach $oligoID ( keys %$gffData ) {
				#print ref($self)."::check_dataset -> we convert GFF = $gffData->{$oligoID} ";
				$gffData->{$oligoID} = $gffData->{$oligoID} - $median;
				#print "to GFF = $gffData->{$oligoID} for oligoID $oligoID\n";
			}
			$dataset->{'data_values'}->{'GFF'} = $gffData;
			

		}
		else {
			$self->{error} .= ref($self)
			  . ":check_dataset -> shit - we could not get the mean enrichment values!\n";
		}
	}
	$pairFile = undef;

	return 1 unless ( $self->{error} =~ m/\w/ );
	return 0;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	die $self->{error} unless ( $self->check_dataset($dataset) );

	## now we need to create 3 tables!!
	## 1. INPUT
	## 2. IP
	## 3. GFF
	my ( $oligo_array_values, @return );
	if ( ref( $dataset->{'data_values'}->{"INPUT"} ) eq "HASH" ) {
		$oligo_array_values =
		  oligo_array_values->new( $self->{'dbh'}, $self->{'debug'} );

		$dataset->{'data'} = $dataset->{'data_values'}->{'INPUT'};
		$oligo_array_values->{'_tableName'} =
		  $dataset->{'table_baseName_base'} . "_INPUT";
	$dataset->{'array_type'} = "INPUT";
		$oligo_array_values->AddDataset($dataset);
		push(
			@return,
			{
				'table_name' => $oligo_array_values->TableName(),
				'array_type'  => "INPUT"
			}
		);
	}
	if ( ref( $dataset->{'data_values'}->{"IP"} ) eq "HASH" ) {
		$oligo_array_values =
		  oligo_array_values->new( $self->{'dbh'}, $self->{'debug'} );
		$oligo_array_values->{'_tableName'} =
		  $dataset->{'table_baseName_base'} . "_IP";
		$dataset->{'data'}      = $dataset->{'data_values'}->{'IP'};
		$dataset->{'data_type'} = 'IP';
		$oligo_array_values->AddDataset($dataset);
		$dataset->{'array_type'} = "IP";
		push(
			@return,
			{
				'table_name' => $oligo_array_values->TableName(),
				'array_type'  => "IP"
			}
		);
	}
	#die "the data we would like to inster: $dataset->{'data_values'}->{GFF}\n";
	if ( ref( $dataset->{'data_values'}->{"GFF"} ) eq "HASH" ) {
		$oligo_array_values =
		  oligo_array_values->new( $self->{'dbh'}, $self->{'debug'} );
		$oligo_array_values->{'_tableName'} =
		  $dataset->{'table_baseName_base'} . "_GFF";
		$dataset->{'data'} = $dataset->{'data_values'}->{'GFF'};
		$dataset->{'array_type'} = "GFF"; 
		$oligo_array_values->AddDataset($dataset);
		push(
			@return,
			{
				'table_name' => $oligo_array_values->TableName(),
				'array_type'  => "GFF"
			}
		);
	}
	return \@return;
}

sub log2 {
	my ($value) = @_;
	Carp::confess ( "we can not take the log of value $value") if ( $value < 0 );
	return log($value) / log(2);
}

sub median {
	my ( $self, $Werte ) = @_;

	if ( lc($Werte) =~ m/hash/ ) {
		my @temp = ( values %$Werte );
		return $self->median( \@temp );
	}

	my @sorted = sort { $a <=> $b } @$Werte;
	if ( @sorted / 2 == int( @sorted / 2 ) ) {    ## gerade anzahl an werten!
		return ( $sorted[ @sorted / 2 ] + $sorted[ @sorted / 2 - 1 ] ) / 2;
	}
	else {
		return $sorted[ int( @sorted / 2 ) ];
	}
}

=head2 Tukey_BiWeight

calculate the Tukey Biweighted mean of a array of values (no check!!)

=cut

sub Tukey_BiWeight {
	my ( $self, $values ) = @_;
	my ( $median, $y, $MAD, $zaeler, $nenner1, $nenner2, $temp, $u, $n );
	$median = $self->median($values);
	$MAD    = $self->MAD( $values, $median );
	$zaeler = $nenner1 = $nenner2 = $n = 0;
	foreach $y (@$values) {
		$u = $self->_calculate_u( $y, $median, $MAD );
		next if ( $u**2 >= 1 );
		$zaeler += ( ($y - $median )**2 ) * ( ( 1 - 5 * $u**2 )**4 );
		$temp = $self->_calculate_temp_value_for_tukey_mean($u);
		$nenner1 += $temp;
		#$nenner2 += -1 + $temp;
		$n++;
	}
	#print ref($self)."::Tukey_BiWeight calculates ( ( $n * $zaeler ) / ( $nenner1 * (-1 + $nenner1 ) ) )**0.5 = ".( ( ( $n * $zaeler ) / ( $nenner1 * (-1 + $nenner1 ) ) )**0.5)."\n";
	return ( ( $n * $zaeler ) / ( $nenner1 * (-1 + $nenner1 ) ) )**0.5;
}

=head2 MAD

the function calculated the median absolute deviation from an array of values.

=cut

sub MAD {
	my ( $self, $values, $median ) = @_;
	my ( $MAD, @MAD_values );
	$median = $self->median($values) unless ( defined $median );
	foreach my $val (@$values) {
		push( @MAD_values, ( ( $val - $median )**2 )**0.5 );
	}
	return $self->median( \@MAD_values );
}

=head2 _calculate_u 

calculate the u as described in http://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/biwscale.htm

u = (y_i - y_median) / ( 9 * MAD)

=cut

sub _calculate_u {
	my ( $self, $value, $median_value, $MAD ) = @_;
	return ( $value - $median_value ) / ( 9 * $MAD );
}

=head2 _calculate_temp_value_for_tukey_mean

calculate the formula (1-u**2) ( 1 - 5 u **2 )
needed to calculate the tukey biweighted mean as described in http://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/biwscale.htm

=cut

sub _calculate_temp_value_for_tukey_mean {
	my ( $self, $u ) = @_;
	my $u_sqare = $u**2;
	return ( 1 - $u_sqare ) / ( 1 - 5 * $u_sqare );
}

1;
