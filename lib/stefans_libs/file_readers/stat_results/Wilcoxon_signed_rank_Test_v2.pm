package stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2;
#  Copyright (C) 2011-12-15 Stefan Lang

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
use stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result;
use base ( 'stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2

=head1 DESCRIPTION

This class handles the statistical output from the batchStatistics_v2 process.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2.

=cut

sub new{

	my ( $class, $debug ) = @_;

	my ( $self );

	$self = {
		'debug'                 => $debug,
		'arraySorter'           => arraySorter->new(),
		'last_group'            => 0,
		'number_of_read_groups' => 0,
		'sample_ids'            => [],
		'header_position'       => {},
		'default_value' => [],
		'header' => [],
		'data'   => [],
		'index'  => {},
		'last_warning' => '',
		'subsets'      => {}
	};

  	bless $self, $class  if ( $class eq "stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2" );

  	return $self;

}


sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		print "we add the column '$value'\n" if ( $self->{'debug'} );
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] = $value;
		${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ] =
		  '';
	}
	return $self->{'header_position'}->{$value};
}

sub After_Data_read {
	my ($self) = @_;
	$self->Rename_Column( 'p', 'p-value' );
	
	my $x_values = [ split( ";", $1 ) ]
	  if ( @{ $self->Description("in order group names:\t") }[0] =~
		m/in order group names:\t(.+)/ );
	Carp::confess(
		root::get_hashEntries_as_string(
			{
				'description_string' => @{ $self->Description(":\t") }[0],
				'x_values'           => $x_values
			},
			3,
			"I miss the x labels that are coded in the line 'in order group names:'"
		)
	) unless ( defined @$x_values[0]);
	
	## here comes the generic stuff dealing with $self->{'sample_ids'}
	my $desxr = @{ $self->Description('Samples_Columns:') }[0];
	$desxr = $1 if ( $desxr =~ m/Samples_Columns:(.+)/ );
	my ($group_id);
	$self->define_subset( 'Samples', [split( ";", $desxr )] );
	foreach ( split( ";", $desxr ) ) {
		$group_id = $1 -1 if ( $_ =~ m/G(\d+)R\d+/ );
		@{ $self->{'sample_ids'} }[$group_id] =
		  { 'tag' => @$x_values[ $group_id ], 'samples' => [] }
		  unless ( ref( @{ $self->{'sample_ids'} }[$group_id] ) eq "HASH" );
		push( @{ @{ $self->{'sample_ids'} }[$group_id]->{'samples'} }, $_ );
	}
	$self->define_subset ('Group 1',  @{ $self->{'sample_ids'} }[0]->{'samples'} );
	$self->define_subset ('Group 2',  @{ $self->{'sample_ids'} }[1]->{'samples'} );
	$self->{'number_of_read_groups'} = scalar( @{ $self->{'sample_ids'} } );
	$self->calculate_fold_change();
	
	my @add = ('Probe Set ID', 'Gene Symbol','fold change', 'p-value','Wilcoxon W');
	push ( @add, 'q_value (BH)') if ( defined $self->Header_Position ( 'q_value (BH)') );
	$self->define_subset ('essentials', \@add );
	
	Carp::confess(
		print root::get_hashEntries_as_string (
			{
				'Description' => $self->Description(),
				'sample_ids'  => $self->{'sample_ids'},
				'x_values' => $x_values,
				'x_count' => scalar (@$x_values ),
				'sample_ids_count' => scalar(@{$self->{'sample_ids'}}),
			}, 
			5,
			"I miss the sample Information that is coded in the Description line #Samples_Columns:\n"
		)
	) unless ( scalar(@{$self->{'sample_ids'}}) == scalar ( @$x_values ) );
	foreach ( keys %{ $self->{'index'} } ) {
		$self->__update_index($_);
	}
	return 1;
}

sub calculate_fold_change {
	my ( $self ) = @_;
	unless ( defined $self->Header_Position ( 'fold change') ) {
		my $fold_change_position = $self->Add_2_Header( 'fold change' );
		my @group_1 = $self->define_subset ( 'Group 1' );
		my @group_2 = $self->define_subset ( 'Group 2' );
		my ( $a, $b );
		for ( my $i = 0; $i < $self->Lines(); $i ++ ){
			$a = root->mean( [ @{@{$self->{'data'}}[$i]}[@group_1] ]);
			$b = root->mean( [@{@{$self->{'data'}}[$i]}[@group_2]] );
			@{@{$self->{'data'}}[$i]}[$fold_change_position] = 2 ** ( $a -$b ); 
			#@{@{$self->{'data'}}[$i]}[$fold_change_position] = root->mean( [ @{@{$self->{'data'}}[$i]}[@group_1] ]) / root->mean( [@{@{$self->{'data'}}[$i]}[@group_2]]);
		}
	}
	return 1;
}

1;
