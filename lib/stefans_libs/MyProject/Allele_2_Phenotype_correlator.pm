package Allele_2_Phenotype_correlator;

#  Copyright (C) 2010-09-01 Stefan Lang

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
use stefans_libs::array_analysis::correlatingData;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::plot::simpleBarGraph;
use base ('figure');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::MyProject::Allele_2_Phenotype_correlator.pm

=head1 DESCRIPTION

This class is able to open a DGI phenotype file, group the samples according to a PHASE_outfile datastructure and calculate the appropriate statistic.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Allele_2_Phenotype_correlator.

=cut

sub new {

	my ( $class, $R, $debug ) = @_;

	my ($self);
	$R = Statistics::R->new() unless ( ref($R) eq 'Statistics::R' );

	$self = {
		'debug'             => $debug,
		'KruskalWallisTest' => KruskalWallisTest->new( $R, $debug ),
		'chi_square'        => chi_square->new( $R, $debug ),
		'data'              => {},
		'plot_data'         => {}

	};
	$self->{'R'} = $self->{'test_obj'}->{'R'};
	bless $self, $class if ( $class eq "Allele_2_Phenotype_correlator" );

	return $self;

}

sub read_file {
	my ( $self, $infile ) = @_;
	Carp::confess("Sorry, but I have no file name to read from\n")
	  unless ( defined $infile );
	Carp::confess("Sorry, but there is no file named '$infile'\n")
	  unless ( -f $infile );
	open( IN, "<$infile" ) or die "I could not open the file '$infile'\n$!\n";
	my @line = split( "/", $infile );
	$self->{'phenotype'} = $line[ @line - 1 ];
	$self->{'phenotype'} =~ s/\.\w+$//;
	my $i = 0;
	while (<IN>) {
		$i ++;
		#sample_id sample_id value
		#100 100 -9
		chomp($_);
		@line = split( " ", $_ );
		$self->__value_for_sample( $line[0], $line[2] );
	}
	print "I have read $i lines from the file $infile\n" if ( $self->{'debug'});
	return 1;
}

=head2 create_plots

This function will return 1 if you give it an outpath to store the plos in.
In addition, plots will be created for each of the statistical tests.

=cut

sub create_plots {
	my ( $self, $outpath ) = @_;
	if ( defined $outpath ) {
		unless ( -d $outpath ) {
			mkdir($outpath);

		}
		$self->{'outpath'} = $outpath;
	}
	return 1 if ( defined $self->{'outpath'} );
	return 0;
}

sub Description {
	my ( $self, $description ) = @_;
	if ( defined $description ) {
		$self->{'description'} = $description;
	}
	$self->{'description'} = '' unless ( defined $self->{'description'} );
	return $self->{'description'};
}

sub getChi_square_table {
	my ( $self ) = @_;
	return  $self->{'chi_res_table'} if ( ref ( $self->{'chi_res_table'} ) eq "data_table");
	$self->{'chi_res_table'} = data_table->new();
	#print "we created a data table object $self->{'chi_res_table'}\n";
	foreach ( 'mode', 'group_name', 'NHD', 'affected', 'odds_ratio', 'odds_std',
	 'p_value', 'X_squared'  ){
		#print "we add a column name $_ to the obj $self->{'chi_res_table'}\n";
		$self->{'chi_res_table'} ->Add_2_Header ( $_ );
	}
	#print $self->{'chi_res_table'}->AsString();
	return $self->{'chi_res_table'};
}
sub calculate_4_grouping_hash {
	my ( $self, $PHASE_outfile ) = @_;
	Carp::confess(
		"I need an PHASE_outfile object in order to calculate the results!")
	  unless ( ref($PHASE_outfile) eq 'PHASE_outfile' );
	my $return = {};
	my $data   = {};
	my ( $significant, @values, $result, $print_stat_data );
	foreach (qw/dominant recessive combination/) {

warn root::get_hashEntries_as_string ($PHASE_outfile, 3, "the hash groups from PHASE_outfile for analysis type $_");
		$data->{$_} = [
			$self->__get_sample_id_groups(
				$PHASE_outfile->get_sample_id_groups($_)
			)
		];
		if ( $self->{'module'} eq "KruskalWallisTest" ) {
			
			$return->{$_} =
			  $self->{'KruskalWallisTest'}->_kruskal_test( @{ $data->{$_} } );
			@values = split( "\t", $return->{$_} );
			$significant = 1 if ( $values[0] <= 0.05 );
		}
		elsif ( $self->{'module'} eq "chi_square" ) {
			$return -> { $_} = "look at the chi_square tests file test file";
			#print "we will add to the data table!\n";
			$print_stat_data = 1;
			## OK first I need to count the samples in the groups
			my ( $all, $temp_Affected, $temp_NHD, $affected, $NHD, $groups,
				$group );
			$all->{'NHD'}      = 0;
			$all->{'affected'} = 0;
			$NHD               = 1;
			$affected          = 2;
			foreach $group ( keys %{ $self->{'last_values'} } ) {
				$temp_Affected = $temp_NHD = 0;
				foreach my $value ( @{ $self->{'last_values'}->{$group} } ) {
					next unless ( defined $value );
					if ( $value == $affected ) {
						$temp_Affected++;
					}
					else {
						$temp_NHD++;
					}
				}
				$groups->{$group} =
				  { 'NHD' => $temp_NHD, 'affected' => $temp_Affected };
				$all->{'NHD'}      += $temp_NHD;
				$all->{'affected'} += $temp_Affected;
			}
			## now I need to check the odds ratio for all the variables
			## and do the statistics only if the odds +- std are above 1.25 or below 0.8
			$self->getChi_square_table()->AddDataset(
					{'mode' =>  $_,
					'group_name'  => "all groups",
					'NHD' => $all->{'NHD'},
					'affected' => $all->{'affected'}
					});
			#print "we could add to the data table ". $self->getChi_square_table()->AsString();
			foreach $group ( keys %$groups ) {
				if ( $groups->{$group}->{'NHD'} == 0 || $groups->{$group}->{'affected'} == 0){
					$self->getChi_square_table()->AddDataset(
					{'mode' =>  $_,
					'group_name'  => $group,
					'NHD' => $groups->{$group}->{'NHD'},
					'affected' => $groups->{$group}->{'affected'}
					});
					next;
				}
				$groups->{$group}->{'Odds_ratio'} =
				  ($groups->{$group}->{'affected'} /$all->{'affected'} ) / ($groups->{$group}->{'NHD'}/  $all->{'NHD'} );
				
				$groups->{$group}->{'Odds_std'} =
				  ( 1 / $groups->{$group}->{'NHD'} +
					  1 / $groups->{$group}->{'affected'} +
					  1 / $all->{'affected'} +
					  1 / $all->{'NHD'} )**0.5;
				if (
					( (
						   $groups->{$group}->{'Odds_ratio'} > 1
						&& $groups->{$group}->{'Odds_ratio'} -
						$groups->{$group}->{'Odds_std'} > 1.1
					)
					|| (   $groups->{$group}->{'Odds_ratio'} < 1
						&& $groups->{$group}->{'Odds_ratio'} +
						$groups->{$group}->{'Odds_std'} < 0.9 )
				  )  && $groups->{$group}->{'NHD'} + $groups->{$group}->{'affected'} > 10 )
				{
					## now it would make sense to calculate the statistics!
					$result = $self->{'chi_square'} -> chi_square_test ( [$groups->{$group}->{'NHD'}, $groups->{$group}->{'affected'}], [$all->{'NHD'},$all->{'affected'}]);
					$self->getChi_square_table()->AddDataset(
					{'mode' =>  $_,
					'group_name'  => $group,
					'NHD' => $groups->{$group}->{'NHD'},
					'affected' => $groups->{$group}->{'affected'},
					'odds_ratio' => $groups->{$group}->{'Odds_ratio'},
					'odds_std' => $groups->{$group}->{'Odds_std'},
					'p_value' => $result->{'p_value'},
					'X_squared' => $result->{'X-squared'}
					});
					
				}
				else {
					$self->getChi_square_table()->AddDataset(
					{'mode' =>  $_,
					'group_name'  => $group,
					'NHD' => $groups->{$group}->{'NHD'},
					'affected' => $groups->{$group}->{'affected'},
					'odds_ratio' => $groups->{$group}->{'Odds_ratio'},
					'odds_std' => $groups->{$group}->{'Odds_std'}
					});
				}
			}
		}
		else {
			Carp::confess(
"Sorry, I do not know the statistical module $self->{'module'}\n"
			);
		}
		if ( $self->create_plots() ) {
			$self->{'plot_data'}->{$_} = $self->{'last_values'};
		}
	}
	
	if ( $self->{'debug'} ) {
		$self->plot($return);
	}
	elsif ( $self->create_plots() && $significant ) {
		$self->plot($return);
	}
	if ( $significant ){
		$significant = "$self->{'outpath'}/$self->{'phenotype'}" ;
	}
	else {
		$significant = "no plots"
	}
	if ( $print_stat_data == 1 ){
		return ($return, $significant, $self->getChi_square_table());
	}
	print "we do not have a useful stat data table ($print_stat_data)\n";
	return $return unless ($significant);
	return $return, "$self->{'outpath'}/$self->{'phenotype'}";
}

sub __get_sample_id_groups {
	my ( $self, $hash ) = @_;
	Carp::confess(
		"I can not create the value arrays, if I do not get an hash of values!")
	  unless ( ref($hash) eq "HASH" );

#Carp::confess ( root::get_hashEntries_as_string ($hash, 3, "the data to draw the samples from "));
	$self->{'last_values'} = {};
	$self->{'cutoff'}      = 0;

	my ( $group_tag, $sample_id, $values );
	foreach my $group_tag ( keys %{$hash} ) {
		$self->{'last_values'}->{$group_tag} = [];
		foreach $sample_id ( @{ $hash->{$group_tag} } ) {
			if ( defined $self->__value_for_sample($sample_id) ) {
				$self->{'cutoff'}++;
				$values->{ $self->__value_for_sample($sample_id) } = 1;
				push(
					@{ $self->{'last_values'}->{$group_tag} },
					$self->__value_for_sample($sample_id)
				);
			}
		}
	}

#	foreach ( keys %{$self->{'last_values'}}){
#		delete ( $self->{'last_values'}->{$_}) if ( scalar @{$self->{'last_values'}->{$_}} < $self->{'cutoff'} * 0.01 );
#	}
	if ( scalar( keys %$values ) == 2 ) {
		$self->{'module'} = 'chi_square';
		return ( values %{ $self->{'last_values'} } );
	}
	$self->{'module'} = 'KruskalWallisTest';
	return ( values %{ $self->{'last_values'} } );
}

sub __value_for_sample {
	my ( $self, $sample, $value ) = @_;
	if ( defined $value ) {
		$self->{'data'}->{$sample} = $value;
	}
	return $self->{'data'}->{$sample};
}

#######################
## The plotting part ##
#######################

sub _plot_axies {
	return 1;
}

sub plot {
	my ( $self, $hash ) = @_;
	Carp::confess("we do not know where to put the data unless ")
	  unless ( $self->create_plots() );
	mkdir( $self->{'outpath'} ) unless ( -d $self->{'outpath'} );
	open( OUT, ">$self->{'outpath'}/$self->{'phenotype'}.txt" )
	  or die
"could not create the text outfile '$self->{'outpath'}/$self->{'phenotype'}.txt'\n$!\n";

	my ( $name, $mode, $title, $tag );
	foreach $mode ( keys %$hash ) {
		$title .= "$mode: $hash->{$mode}\n";
	}
	print OUT "$title\nmode\tname\tmean\tn\tstd\n";
	foreach my $mode ( sort keys %{ $self->{'plot_data'} } ) {
		$tag = $mode;
		$tag = 'additive' if ( $tag eq "dominant" );
		foreach $name ( keys %{ $self->{'plot_data'}->{$mode} } ) {
			print OUT "$tag\t$name\t"
			  . join(
				"\t",
				root->getStandardDeviation(
					$self->{'plot_data'}->{$mode}->{$name}
				)
			  ) . "\n";
		}
	}
	close(OUT);

	print
	  "look at the phenotypes in $self->{'outpath'}/$self->{'phenotype'}.txt\n";
}

1;
