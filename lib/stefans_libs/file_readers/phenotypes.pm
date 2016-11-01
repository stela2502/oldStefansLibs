package stefans_libs_file_readers_phenotypes;

#  Copyright (C) 2010-12-02 Stefan Lang 

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

use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=head1 General description

This class handles all ohenotype file using the first column to name the phenotypes and all other columns as samples.

=cut
sub new {

    my ( $class, $debug ) = @_;
    my ($self);
    $self = {
        'debug'           => $debug,
        'arraySorter'     => arraySorter->new(),
        'header_position' => {},
        'sample_ids' => [],
        'default_value'   => [],
        'header'          => [],
        'data'            => [],
        'index'           => {},
        'last_warning'    => '',
        'subsets'         => {}
    };
    bless $self, $class if ( $class eq "stefans_libs_file_readers_phenotypes" );

    return $self;
}


sub Add_2_Header {
    my ( $self, $value ) = @_;
    return undef unless ( defined $value );
    unless ( defined $self->Header_Position('phenotype') ){
    	$self->{'header_position'}->{$value} = 0;
    	$self->{'header_position'}->{'phenotype'} = 0;
    	@{$self->{'header'}}[0] = $value;
    	return 0;
    }
    unless ( defined $self->{'header_position'}->{$value} ) {
        $self->{'header_position'}->{$value} = scalar ( @{$self->{'header'}});
        push (@{$self->{'header'}}, $value );
       push ( @{$self->{'sample_ids'}}, $value );
    }
    return $self->{'header_position'}->{$value};
}

sub After_Data_read{
	my ( $self ) = @_;
	$self->define_subset('samples', $self->{'sample_ids'} );
	foreach my $array ( @{$self->{'data'}}){
		@$array[0] = $1 if ( @$array[0] =~ m/^ (.*)/);
		@$array[0] = $1 if ( @$array[0] =~ m/(.*) +$/);
	}
	return 1;
}

=head2 As_CLS_file_str ( $phenotype, \@data_column_headers )

The function will look through its data and decide whether we have a continuose dataset 
(more than 3 different x values) or a grouped dataset.
It will create the respective CLS strings to be used with the GSEA program.
 
=cut

sub As_CLS_file_str {
	my ( $self, $phenotype, $data_column_headers ) = @_;
	## ok that will be a little bit a problem.
	## I need to define how manny groups I could define with one pheotype
	## discrete or linear??
	my ($hash, $line_id, $line_hash, @sample_list,$data_headers, $i, $key_id );
	unless ( ref($data_column_headers) eq "ARRAY"){
		warn "I would need an array of data column headers - but as I have not got one I expect that you want to get data on all - or?\n";
		foreach ( @{$self->{'sample_ids'}}){
			$data_headers->{$_} = 1;
		}
	}
	else {
		foreach ( @$data_column_headers){
			$data_headers->{$_} = 1;
		}
	}
	($line_id) = $self->get_rowNumbers_4_columnName_and_Entry( 'phenotype', $phenotype);
	#print "we have the rowNumbers $line_id \n";
	Carp::confess ("Sorry, but I do not know the phenotype '$phenotype'\nI have these phenotypes: ".join(', ', @{$self->getAsArray('phenotypes')})."\n")unless ( defined $line_id);
	$key_id = 0;
	for ( $i = 1; $i< @{@{$self->{'data'}}[$line_id]}; $i ++){
		#print "we want to add the data ".@{@{$self->{'data'}}[$line_id]}[$i]."\n";
		next unless (@{@{$self->{'data'}}[$line_id]}[$i] =~ m/\w/ );
		next unless ($data_headers ->{@{$self->{'header'}}[$i]});
		$hash->{@{@{$self->{'data'}}[$line_id]}[$i]} = $key_id ++ unless ( defined $hash->{@{@{$self->{'data'}}[$line_id]}[$i]});
	}
	$line_hash = $self->get_line_asHash( $line_id );
	foreach my $key ( @{$self->{'header'}} ){
		next unless ($data_headers ->{$key} );
		if ( defined $hash-> { $line_hash->{$key} } ){
			push (@sample_list, $key ) ;
		}
	}
	my $str = '';
	## in @sample_list I have all usable column headers
	if ( @sample_list > 3 && scalar ( keys %$hash) <=3 ){
		## OK we have a grouped dataset
		$str .= scalar(@sample_list)." ".scalar( keys %$hash ). " 1\n";
		$str .= "# ".join( " ", (sort { $hash->{$b} <=> $hash->{$a}} keys %$hash) )."\n";
#		while( my ( $key, $value )= each %$hash ){
#			$str .= "$key -> $value;";
#		} 
#		$str .= "\n";
		 
		foreach ( @sample_list ){
			$str .= $hash->{$line_hash->{$_}}." ";
		}
		chop( $str );
		$str .= "\n";
	}
	else {
		$str .= "#numeric\n#$phenotype\n";
		foreach ( @sample_list ){
			$str .= $line_hash->{$_}." ";
		}
		chop( $str );
		$str .= "\n";
	}
	return { 'str' => $str, 'samples' => \@sample_list };
}
1;
