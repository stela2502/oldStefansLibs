package stefans_libs_file_readers_sequenome_resultFile_report;

#  Copyright (C) 2011-02-15 Stefan Lang

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

sub new {
	my ( $class, ) = @_;
	my ( $self, $accepted_types );
	$accepted_types = {
		'negative controls' => 0,
		'sample'            => 1,
		'assay'             => 2
	};
	$self = {
		'data' => {
			'negative controls' => {},
			'samples'           => {},
			'assay'             => {}
		},
		'accepted_types' => $accepted_types,
		'Description'    => {
			'A.Conservative'    => 'good calls',
			'B.Moderate'        => 'shaky calls',
			'C.Aggressive'      => 'shaky calls',
			'D.Low Probability' => 'shaky calls',
			'E.User Call'       => 'shaky calls',
			'F.User Call'       => 'failed calls',
			'I.Bad Spectrum'    => 'failed calls',
			'N.No-Alleles'      => 'failed calls'
		},
		'negative_controls' => {
			'0'    => 1,
			'tomt' => 1,
			'H2O'  => 1
		}
	};
	bless $self, $class
	  if ( $class eq "stefans_libs_file_readers_sequenome_resultFile_report" );
	return $self;
}

sub check_line_hash {
	my ( $self, $line ) = @_;
	my $error = '';
	foreach ( 'Well', 'Assay', 'Genotype', 'Description', 'Sample', 'Operator' )
	{
		$error .= "I miss the data column '$_'\n"
		  unless ( defined $line->{$_} );
	}
	my ( $active_type, $active_assay );
	Carp::confess( ref($self) . "::check_line_hash:\n" . $error )
	  if ( $error =~ m/\w/ );
	if ( $self->{'negative_controls'}->{ $line->{'Sample'} } ) {
		## OK we look at a negative control - here we need to invers the checks!
		unless (
			defined $self->{'data'}->{'negative controls'}
			->{ $line->{'Sample'} } )
		{
			$self->{'data'}->{'negative controls'}->{ $line->{'Sample'} } = {
				'good calls'    => 0,
				'failed calls'  => 0,
				'failed_assays' => {}
			};
		}
		$active_type =
		  $self->{'data'}->{'negative controls'}->{ $line->{'Sample'} };
		if ( $line->{'Genotype'} eq "NA" ) {
			$active_type->{'good calls'}++;
		}
		else {
			$active_type->{'failed_assays'}->{ $line->{'Assay'} } =
			  $line->{'Description'};
			$active_type->{'failed calls'} ++;
		}
	}
	else {
		## OK this entry is from a sample!
		unless ( defined $self->{'data'}->{'sample'}->{ $line->{'Sample'} } ) {
			$self->{'data'}->{'sample'}->{ $line->{'Sample'} } = {
				'good calls'    => 0,
				'shaky calls'   => 0,
				'failed calls'  => 0,
				'shaky_assays'  => {},
				'failed_assays' => {}
			};
		}
		unless ( defined $self->{'data'}->{'assay'}->{ $line->{'Assay'} } ) {
			$self->{'data'}->{'assay'}->{ $line->{'Assay'} } = {
				'good calls'     => 0,
				'shaky calls'    => 0,
				'failed calls'   => 0,
				'shaky_samples'  => {},
				'failed_samples' => {}
			};
		}
		$active_assay = $self->{'data'}->{'assay'}->{ $line->{'Assay'} };
		$active_type  = $self->{'data'}->{'sample'}->{ $line->{'Sample'} };
		Carp::confess(
"Sorry, but I do not know the description '$line->{'Description'}'\n"
		  )
		  unless ( defined $self->{'Description'}->{ $line->{'Description'} } );
		$active_type->{ $self->{'Description'}->{ $line->{'Description'} } }++;
		$active_assay->{ $self->{'Description'}->{ $line->{'Description'} } }++;
		if ( $self->{'Description'}->{ $line->{'Description'} } eq
			"shaky calls" )
		{
			$active_type->{'shaky_assays'}->{ $line->{'Assay'} } =
			  $line->{'Description'};
			$active_assay->{'shaky_samples'}->{ $line->{'Sample'} } =
			  $line->{'Description'};
		}
		elsif ( $self->{'Description'}->{ $line->{'Description'} } eq
			"failed calls" )
		{
			$active_type->{'failed_assays'}->{ $line->{'Assay'} } =
			  $line->{'Description'};
			$active_assay->{'failed_samples'}->{ $line->{'Sample'} } =
			  $line->{'Description'};
		}
	}
	return 1;
}

sub UpdateAssayInfos {
	my ( $self, $db_interface ) = @_;
	unless ( ref($db_interface) eq "stefans_libs_database_sequenome_data"){
		Carp::confess ( "Sorry, but I need a dbInterface of the class 'stefans_libs_database_sequenome_data'\n")
	}
}

sub print {
	my ( $self, $filename ) = @_;
	my $str = '';
	my ($value);
	## first the negative control, as this tells the story!
	if ( scalar( keys %{ $self->{'data'}->{'negative controls'} } ) > 0 ) {
		$str .= "#######################\n" . "## Negative Controls ##\n";
		foreach my $key ( keys %{ $self->{'data'}->{'negative controls'} } ) {
			$value = $self->{'data'}->{'negative controls'}->{$key};
			$str .=
			    "#######################\nnegative control tag=$key\n"
			  . "good calls=$value->{'good calls'}\n"
			  . "failed calls=$value->{'failed calls'}\n";

			if ( $value->{'failed calls'} > 0 )
			{
				$str .= "failed assays= ";
				foreach my $description (
					keys %{
						$value
						  ->{'failed_assays'}
					}
				  )
				{
					$str .=
					  "$description/"
					  . $value->{'failed_assays'}->{$description} . "; ";
				}
				chop ( $str );
				chop ( $str );
				$str .= "\n#######################\n";
			}
		}
	}
	$str .= "\n#######################\n" . "##      Samples      ##\n". "#######################\n";
	foreach my $sample ( keys %{ $self->{'data'}->{'sample'} } ) {
		$value = $self->{'data'}->{'sample'}->{$sample};
		$str .=
		    "sample=$sample\n"
		  . "good calls=$value->{'good calls'}\n"
		  . "shaky calls=$value->{'shaky calls'}\n"
		  . "failed calls=$value->{'failed calls'}\n";
		if ( $value->{'shaky calls'} > 0 ) {
			$str .= "shaky_assays= ";
			foreach my $assay ( keys %{ $value->{'shaky_assays'} } ) {
				$str .= "$assay/$value->{'shaky_assays'}->{$assay};";
			}
			chop ( $str );
			chop ( $str );
			$str .= "\n";
		}
		if ( $value->{'failed calls'} > 0 ) {
			$str .= "failed_assays= ";
			foreach my $assay ( keys %{ $value->{'failed_assays'} } ) {
				$str .= "$assay/$value->{'failed_assays'}->{$assay}; ";
			}
			chop ( $str );
			chop ( $str );
			$str .= "\n";
		}
		$str .= "#######################\n";
	}
	$str .= "\n#######################\n" . "##       Assays      ##\n". "#######################\n";
	foreach my $assay ( keys %{ $self->{'data'}->{'assay'} } ) {
		$value = $self->{'data'}->{'assay'}->{$assay};
		$str .=
		    "assay=$assay\n"
		  . "good calls=$value->{'good calls'}\n"
		  . "shaky calls=$value->{'shaky calls'}\n"
		  . "failed calls=$value->{'failed calls'}\n";
		if ( $value->{'shaky calls'} > 0 ) {
			$str .= "shaky_samples= ";
			foreach my $sample ( keys %{ $value->{'shaky_samples'} } ) {
				$str .= "$sample/$value->{'shaky_samples'}->{$sample}; ";
			}
			chop ( $str );
			chop ( $str );
			$str .= "\n";
		}
		if ( $value->{'failed calls'} > 0 ) {
			$str .= "failed_samples= ";
			foreach my $sample ( keys %{ $value->{'failed_samples'} } ) {
				$str .= "$sample/$value->{'failed_samples'}->{$sample}; ";
			}
			chop ( $str );
			chop ( $str );
			$str .= "\n";
		}
		$str .= "#######################\n";
	}
	if ( defined $filename ) {
		eval {
			open( OUT, ">$filename" );
			print OUT $str;
			close(OUT);
		};
	}
	return $str;
}

1;
