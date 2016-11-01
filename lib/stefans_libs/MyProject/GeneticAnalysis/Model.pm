package stefans_libs_MyProject_GeneticAnalysis_Model;

#  Copyright (C) 2011-02-10 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_MyProject_GenetcAnalysis_Model

=head1 DESCRIPTION

A genetic model

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_MyProject_GenetcAnalysis_Model.

=cut

sub new {

	my ( $class, $hash, $stat_obj ) = @_;

	my ( $self, $this_hash );

	my $error = '';
	foreach ( 'SNPs', 'max_subjects', 'phenotype' ) {
		unless ( defined $hash->{$_} ) {
			$error .= "We miss the has key $_\n";
		}
		else {
			if ( ref($hash->{$_}) eq "ARRAY"){
				$this_hash->{$_} = [ @{$hash->{$_}}];
			}
			else {
				$this_hash->{$_} = $hash->{$_};
			}
		}
	}
	$error .= 'we need a stst object of the type chi_square'
	  unless ( ref($stat_obj) eq "chi_square" );
	Carp::confess(
		"Sorry, but we need some information on startup :\n" . $error )
	  if ( $error =~ m/\w/ );
	$self = {
		'info'       => $this_hash,
		'keys'       => {},
		'max'        => 0,
		'min'        => 0,
		'sums'       => {},
		'chi_square' => $stat_obj,
		'all' => { '1' => 0, '2' => 0 }
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_MyProject_GeneticAnalysis_Model" );

	return $self;

}

=head2 plot

write some text information about the model

=cut

sub plot {
	my ($self) = @_;
	my $str = '';
	return $str;
}

=head2 addKey_value (  $key, $value )

Will add a phenotypic value for the key $key.
I expect the value to be either 1 (not affected) or 2 (affected)

=cut

sub addKey_value {
	my ( $self, $key, $value ) = @_;
	my $error = '';
	$error .= "We miss the key\n"   unless ( defined $key );
	$error .= "We miss the value\n" unless ( defined $value );
	$error .= "The value must not be '$value' (only '1' or '2' is allowed).\n"
	  if ( !( $value == 1 || $value == 2 ) );
	Carp::confess( ref($self) . "->addKey_value($key, $value )\n" . $error )
	  if ( $error =~ m/\w/ );

	unless ( defined $self->{'keys'}->{$key} ) {
		$self->{'keys'}->{$key} = [];
		$self->{'sums'}->{$key} = { 1 => 0, 2 => 0 };
	}
	unless ( ref( $self->{'keys'}->{$key} ) eq "ARRAY" ) {
		Carp::confess(
			"You already finalized this model - you must not add new values!\n"
		);
	}
	push( @{ $self->{'keys'}->{$key} }, $value );
	$self->{'sums'}->{$key}->{$value}++;
	$self->{'all'}->{$value} ++;
	return 1;
}

=head2 Min

Predictive keys with less than 10 entries will not be considered!

This function will finalize the model and return the least predictive key for this model as
{
	'key' => 'the key', 
	'mean' => <mean predictifve value> , 
	'n' => <number of samples that had that key>, 
	'std' => <std of the predictive value> 
}
	
=cut

sub Min {
	my ($self) = @_;
	return $self->{'min'} if ( ref( $self->{'min'} ) eq "HASH" );
	$self->Finalize();
	$self->{'min'} = { 'key' => '', 'mean' => 2, 'n' => 0, 'std' => 0, 'p_value' => 1 };
	foreach my $key ( sort { $self->{'keys'}->{$b}->{'n'} <=> $self->{'keys'}->{$a}->{'n'}} keys %{ $self->{'keys'} } ) {
		next if ( $self->{'keys'}->{$key}->{'n'} < 10 );
		if ( $self->{'keys'}->{$key}->{'mean'} < $self->{'min'}->{'mean'} ) {
			$self->calculate_stat_4_model_hash( $key );
			next if ( $self->{'keys'}->{$key}->{'p_value'} > $self->{'min'}->{'p_value'});
			$self->{'min'}->{'key'} = $key;
			foreach ( 'mean', 'n', 'std','p_value' ) {
				$self->{'min'}->{$_} = $self->{'keys'}->{$key}->{$_};
			}
		}
	}
	foreach ( 'max_subjects', 'phenotype' ) {
		$self->{'min'}->{$_} = $self->{'info'}->{$_};
	}
	$self->{'min'}->{'SNPs'} = join( ",", @{ $self->{'info'}->{'SNPs'} } );
	return $self->{'min'};
}

=head2 Max

Predictive keys with less than 10 entries will not be considered!

This function will finalize the model and return the most predictive key for this model as
{
	'key' => 'the key', 
	'mean' => <mean predictifve value> , 
	'n' => <number of samples that had that key>, 
	'std' => <std of the predictive value> 
}
	
=cut

sub _print_model{
	my ( $self, $model ) = @_;
	my $p_value = $model->{'p_value'};
	$p_value = "n.d." unless ( defined $p_value );
	my $str = '';
	return "model contains only $model->{'n'} samples - discarded\n" if ( $model->{'n'} < 10 );
	$str .= "mean\tstd\tnumber of samples\tp value\n";
	$str .= "$model->{'mean'}\t$model->{'std'}\t$model->{'n'}\t$p_value\n";
	return $str;
}

sub _print_this{
	my ( $self ) = @_;
	my $str = "################################\nModel INFO:\n";
	$str .= "SNP_positions\t".join(",",@{$self->{'info'}->{'SNPs'}})."\n";
	foreach ( 'max_subjects', 'phenotype' ){
		$str .= "$_\t$self->{'info'}->{$_}\n";
	}
	$str .= "Total Unaffected\t$self->{'all'}->{'1'}\n";
	$str .= "Total Affected\t$self->{'all'}->{'2'}\n";
	$str .= "################################\n";
	my $temp = $self->Max();
	$str .=  "#Model High Risk\nSNPs\t$temp->{'key'}\n";
	$str .=  $self->_print_model ($temp);
	$temp = $self->Min();
	$str .=  "#Model Low Risk\nSNPs\t$temp->{'key'}\n";
	$str .=  $self->_print_model ($temp);
	$str .= "#############\n";
	return $str;
}

sub print {
	my ( $self ) = @_;
	my $str = $self-> _print_this ();
	my $i = 1;
	
	foreach my $key ( sort { $self->{'keys'}->{$b}->{'n'} <=> $self->{'keys'}->{$a}->{'n'}} keys %{$self->{'keys'}} ){
		$str .=  "#Model $i\nSNPs\t$key\n";
		$str .=  "unaffected\t$self->{'sums'}->{$key}->{'1'}\n".
			"affected\t$self->{'sums'}->{$key}->{'2'}\n";
		$str .= $self->_print_model ( $self->{'keys'}->{$key} );
		$i ++;
	}
	return $str;
}

sub Max {
	my ($self) = @_;
	return $self->{'max'} if ( ref( $self->{'max'} ) eq "HASH" );
	$self->Finalize();
	$self->{'max'} = { 'key' => '', 'mean' => 0, 'n' => 0, 'std' => 0 , 'p_value' => 1 };
	foreach my $key (sort { $self->{'keys'}->{$b}->{'n'} <=> $self->{'keys'}->{$a}->{'n'}} keys %{ $self->{'keys'} } ) {
		#print $self->_print_model($self->{'keys'}->{$key});
		next if ( $self->{'keys'}->{$key}->{'n'} < 10 );
		if ( $self->{'keys'}->{$key}->{'mean'} > $self->{'max'}->{'mean'} ) {
			$self->calculate_stat_4_model_hash( $key );
			next if ( $self->{'keys'}->{$key}->{'p_value'} > $self->{'max'}->{'p_value'});
			$self->{'max'}->{'key'} = $key;
			foreach ( 'mean', 'n', 'std', 'p_value' ) {
				$self->{'max'}->{$_} = $self->{'keys'}->{$key}->{$_};
			}
		}
	}
	foreach ( 'max_subjects', 'phenotype' ) {
		$self->{'max'}->{$_} = $self->{'info'}->{$_};
	}
	$self->{'max'}->{'SNPs'} = join( ",", @{ $self->{'info'}->{'SNPs'} } );
	return $self->{'max'};
}

=head2 Finalize

this funtion will sum up the model phenotypes,
converting the array of values into an hash containing mean std and n

=cut

sub Finalize {
	my ($self) = @_;
	return 1 if ( $self->{'finalized'} );
	my ( $mean, $n, $std, $stat_res );
	foreach my $key ( keys %{ $self->{'keys'} } ) {
		( $mean, $n, $std ) =
		  root->getStandardDeviation( $self->{'keys'}->{$key} );
		$self->{'keys'}->{$key} = { 'mean' => $mean, 'n' => $n, 'std' => $std };
	}
	$self->{'finalized'} = 1;
	return 1;
}

sub calculate_stat_4_model_hash{
	my ( $self, $key ) = @_;
	my $stat_res = $self->{'chi_square'}->chi_square_test(
			[ $self->{'sums'}->{$key}->{'1'}, $self->{'sums'}->{$key}->{'2'} ],
			[ $self->{'all'}->{'1'}, $self->{'all'} ->{'2'} ] );
	$self->{'keys'}->{$key}->{'p_value'} = $stat_res -> {'p_value'};
}
1;
