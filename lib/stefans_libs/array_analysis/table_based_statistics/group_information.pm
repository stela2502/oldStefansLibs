package stefans_libs_array_analysis_table_based_statistics_group_information;
#  Copyright (C) 2011-12-14 Stefan Lang

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



=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_array_analysis_table_based_statistics_group_information

=head1 DESCRIPTION

This lib can pares 'normal' tables and produce an group information dataset from that.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_array_analysis_table_based_statistics_group_information.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
		'groups' => {}
  	};

  	bless $self, $class  if ( $class eq "stefans_libs_array_analysis_table_based_statistics_group_information" );

  	return $self;

}

=for description

This object provides a structure to parse tab separated group definition files.
The information will be parsed into this object.

=cut


sub AddFile {
	my ( $self, $filename ) = @_;
	
	my $data_table= data_table->new();
	$data_table -> read_file ( $filename );
	my ($header_hash);
	for ( my $i = 0; $i < @{$data_table->{'header'}}; $i ++ ){
		$header_hash -> {$i} =  @{$data_table->{'header'}}[$i];
	}
	my ( $row, $array, $group_is_number);
	for ( my $i = 0; $i < $data_table->Lines(); $i ++ ){
		$array = @{$data_table->{'data'}}[$i];
		unless ( defined @$array[0]){
			Carp::confess ( "Critical Error - I do not have a grouping name for line $i in file\n".$data_table->AsString());
		}
		$self->{'groups'}->{@$array[0]} = {
			'groups' => {},
			'stat_type' => 'groups',
		};
		for ( $row = 1; $row < @$array; $row ++ ){
			if ( @$array[$row] =~m/[\w\d]/ ){
				$self->{'groups'}->{@$array[0]}->{'groups'}->{@$array[$row]} = [] unless ( defined $self->{'groups'}->{@$array[0]}->{'groups'}->{@$array[$row]});
				push ( @{ $self->{'groups'}->{@$array[0]}->{'groups'}->{@$array[$row]} }, $header_hash -> {$row} );
			} 
		}
		$group_is_number = 1;
		foreach ( keys %{$self->{'groups'}->{@$array[0]}->{'groups'}} ){
			$group_is_number = 0 unless ( $_ =~m/(\d?\.?\d+e?-?\d*)/);
		}
		$self->{'groups'}->{@$array[0]}->{'stat_type'} = 'linear' if ( $group_is_number );
		
	}
	
	return 1;
}

=head2 As_LaTex_section ( {
	'latex_section' => a stefans_libs::Latex_Document::Section object,
	'section_title' => default = 'Sample Groupings',
	'section_label' => 
})

=cut

sub As_LaTex_section{
	my ( $self, $hash ) = @_;
	#$hash->{'latex_section'}, $hash->{'section_title'}, $hash->{'section_label'}
	Carp::Confess ( "I need to get a 'stefans_libs::Latex_Document::Section' section at startup!") unless ( ref($hash->{'latex_section'}) eq "stefans_libs::Latex_Document::Section");
	## I found good help here: https://en.wikibooks.org/wiki/LaTeX/Tables
	$hash->{'section_title'} = 'Sample Groupings' unless ( defined $hash->{'section_title'} );
	my $main_section = $hash->{'latex_section'} -> Section ( $hash->{'section_title'}, $hash->{'section_label'} );
	$main_section -> AddText (  'the following subsectiond contain a detailed description table for '.
	'each sample grouping, that has been used in this document.');
	my ($text_obj, $samples);
	foreach my $group_name ( keys %{$self->{'groups'}}) {
		my $Stistics = '';
		my @ordered_tags;
		if ( $self->{'groups'}->{$group_name} ->{'stat_type'} eq "linear" ){
			$Stistics = "Spearman Signed rank linear correlation";
			@ordered_tags = (sort { $a <=> $b } keys %{$self->{'groups'}->{$group_name}->{'groups'}});
		}
		elsif ( scalar ( keys %{$self->{'groups'}->{$group_name}->{'groups'}}) == 2 ){
			$Stistics = "two-sample Wilcoxon or Mann-Whitney two group test";
			@ordered_tags = sort ( keys %{$self->{'groups'}->{$group_name}->{'groups'}});
		}
		else {
			$Stistics = "Kruskal-Wallis test";
			@ordered_tags = sort ( keys %{$self->{'groups'}->{$group_name}->{'groups'}});
		}
		#warn "we got a stat type $Stistics 4 goup name $group_name (".scalar ( keys %{$self->{'groups'}->{$group_name}->{'groups'}}).")\n";
		$text_obj = $main_section->Section( $group_name ) -> AddText ("The group '$group_name' has been analyzed using a $Stistics." );
		my $latex_table = "\\begin{tabular}{|c|c|}\n"."\\hline\n"."Group tag & sample id\\\\\n\\hline\n";
		
		foreach my $group_tag ( @ordered_tags ){
			$samples = $self->{'groups'}->{$group_name}->{'groups'}->{$group_tag};
			next unless ( ref($samples) eq "ARRAY" );
			if ( scalar (@$samples) > 1 ){
				$latex_table .= "\\multirow{".scalar(@$samples)."}{*}{$group_tag} ";			
			}
			else {
				$latex_table .= "$group_tag ";
			}
			foreach ( @$samples ){
				$latex_table .= " & $_ \\\\\n";
			}
			$latex_table .= "\\hline\n";
		}
		$latex_table .= "\\end{tabular}\n";

		#Carp::confess (  root::get_hashEntries_as_string ( $self->{'groups'}->{$group_name} , 3 , "I parsed this LaTeX table from that info:\n$latex_table" ));
		$text_obj -> add_LaTeX_text_object ( $latex_table );
	}
	unless ( scalar ( keys %{$self->{'groups'}} ) > 0 ) {
		$main_section -> AddText ( "Sorry we did not have any groupings in the data file we analyzed! ");
	}
	#Carp::confess ( root::get_hashEntries_as_string ($self  , 3 , "Hey - why don't we have some groups??" )) unless ( scalar ( keys %{$self->{'groups'}} ) > 0 );

	return $main_section;
}

sub GetGroups {
	my ( $self ) = @_;
	return $self->{'groups'};
}

1;
