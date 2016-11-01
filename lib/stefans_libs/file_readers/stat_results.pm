package stat_results;
#  Copyright (C) 2010-11-09 Stefan Lang

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
use stefans_libs::file_readers::stat_results::KruskalWallisTest_result;
use stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result;
use stefans_libs::file_readers::stat_results::Spearman_result;
use stefans_libs::file_readers::stat_results::KruskalWallisTest_result_v2;
use stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_v2;
use stefans_libs::file_readers::stat_results::Spearman_result_v2;
=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::lib::stefans_libs::file_readers::stat_results.pm

=head1 DESCRIPTION

Using this object you will be able to open whichever stst result table using the appropriate module.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stat_results.

=cut

sub new{

	my ( $class, $debug ) = @_;

	my ( $self );

	$self = {
		'___p_value_cutoff___' => 1
  	};

  	bless $self, $class  if ( $class eq "stat_results" );

  	return $self;

}

sub p_value_cutoff{
	my ( $self, $p_value ) = @_;
	if ( defined $p_value ){
		$self->{'___p_value_cutoff___'} = $p_value;
	}
	elsif ( ! $self->{'___p_value_cutoff___'} =~m/\d/ ){
		$self->{'___p_value_cutoff___'} = 1;
	}
	return $self->{'___p_value_cutoff___'};
}

## Using this function you can affect the read_file function.
## If you have given me a list of genes here, this object will read data for all the nemed genes, and not for any given p value!
sub Only_Genes {
	my ( $self, $genes_array ) = @_;
	if ( ref($genes_array) eq "ARRAY" ){
		$self->{'___genes2read___'} = {};
		foreach ( @$genes_array){
			$self->{'___genes2read___'} -> { $_} = 1;
		}
	}
	return $self->{'___genes2read___'};
}

sub read_file {
	my ( $self, $infile ) = @_;
	Carp::confess ( "Sorry, but I need to have an infile that is found on my harddisk!\nNot '$infile'\n") unless ( -f $infile);
	open ( IN , "<$infile") or die "cxould not open the infile $infile\n$!\n";
	my (@line, $obj);
	while ( <IN> ){
		unless ( $_ =~m/^#/ ){
			last if ( defined $line[0] );
		}
		@line = split("\t",$_);
	}
	close ( IN );
	if ( $line[4] eq 'degrees of freedom' && $line[3] eq 'chi-squared'){
		$obj = stefans_libs::file_readers::stat_results::KruskalWallisTest_result->new();

	}
	if ( $line[4] eq 'fold change' && $line[3] eq "w" ){
		$obj = stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result->new();
	}
	elsif ( $line[4] eq 'rho' && $line[3] eq "S" ){
		#Gene Symbol;p value;S;rho
		$obj = stefans_libs::file_readers::stat_results::Spearman_result->new();
	}
	elsif ( join("", @line) =~m/spearman rho/ ){
		## next generation spearman result!
		$obj = stefans_libs_file_readers_stat_results_Spearman_result_v2->new();
	}
	elsif ( join("", @line) =~m/Wilcoxon W/ ){
		## next generation wilcox result!
		$obj = stefans_libs_file_readers_stat_results_Wilcoxon_signed_rank_Test_v2->new();
	}
	elsif ( join("", @line) =~m/Kruskal Wallis chi squared/ ){
		## next generation Kruskal Wallis result!
		$obj = stefans_libs_file_readers_stat_results_KruskalWallisTest_result_v2->new();
	}
	elsif ( join("", @line) eq "" ){
		my $obj = undef ; #stefans_libs::file_readers::stat_results::KruskalWallisTest_result->new();
	}
	if ( defined $obj){
		$obj ->read_file( $infile );
		if ( defined $self->Only_Genes() ) {
			return $obj->select_where ( 'Gene Symbol', sub { return 0 unless ( defined $_[0] );return 1 if ( $self->Only_Genes()->{$_[0]}); return 0;});
		}
		return $obj->select_where ( 'p-value', sub { return 0 unless ( defined $_[0] );return 1 if ( $_[0] <= $self->p_value_cutoff()); return 0;});
	}
	
	# OK we have one last option - we have an empty file
	# we should just complain about that and return a KruskalWallisTest_result
	Carp::confess ( "Sorry, but I do not know which type of stat_result that header belongs to:\n".join(";",@line)."\nfor file $infile\n");

}
1;
