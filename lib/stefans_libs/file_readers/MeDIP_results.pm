package stefans_libs_file_readers_MeDIP_results;

#  Copyright (C) 2011-02-17 Stefan Lang

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
use
  stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile;
use stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo;
use stefans_libs::file_readers::affymetrix_expression_result;

use base 'data_table';

=head1 General description

A lib to store medip result data - to speed up the analysis process.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'Oligo_id'          => 0,
			'p value'           => 1,
			'meanA'             => 2,
			'meanB'             => 3,
			'fold_change [A/B]' => 4,
			'stdA'              => 5,
			'stdB'              => 6,
		},
		'default_value' => [],
		'header'        => [
			'Oligo_id',          'p value', 'meanA', 'meanB',
			'fold_change [A/B]', 'stdA',    'stdB',
		],
		'data'                => [],
		'index'               => {},
		'last_warning'        => '',
		'subsets'             => {},
		'fold_change_columns' => [],
		'expreesion_p_values' => [],
		'accepted_new'        => {
			'Oligo_id'                                         => 1,
			'p value'                                          => 1,
			'meanA'                                            => 1,
			'meanB'                                            => 1,
			'fold_change [A/B]'                                => 1,
			'difference [A -B ]'                               => 1,
			'stdA'                                             => 1,
			'stdB'                                             => 1,
			'seq'                                              => 1,
			'chr'                                              => 1,
			'start'                                            => 1,
			'end'                                              => 1,
			'Gene Symbol'                                      => 1,
			'location'                                         => 1,
			'CpG content [n]'                                  => 1,
			'all p values > 0.05'                              => 1,
			'methylation affects expression'                   => 1,
			'all expression changes are significant'           => 1,
			'expression difference invers to MeDIP difference' => 1
		},
		'accepted_new_partial' => [
			' expression p value$',
			' difference A-B$',
			' mean expression [AB]$',
			' std expression [AB]$',
			' fold change A/B'
		  ]

	};
	bless $self, $class
	  if ( $class eq "stefans_libs_file_readers_MeDIP_results" );

	return $self;
}

## two function you can use to modify the reading of the data.

sub get_best_oligo_per_gene {
	my ($self) = @_;
	Carp::confess("Sorry, but you have not added any Gene Symbols!")
	  unless ( defined $self->Header_Position("Gene Symbol") );
	my $result = $self->Sort_by(
		[ [ 'Gene Symbol', 'lexical' ], [ 'p value', 'antiNumeric' ] ] );
	my $gene_position = $self->Header_Position("Gene Symbol");
	my $array;
	my $already_processed_geens = {};
	$result = $result->select_where(
		'Gene Symbol',
		sub {
			unless ( $already_processed_geens->{ $_[0] } ) {
				$already_processed_geens->{ $_[0] } = 1;
				return 1;
			}
			return 0;
		}
	);
	$result->Description( $self->Description() );
	$result->Add_2_Description('Best oligo per gene!');
	return $result;
}

=head2 read_file

This function can be used to read from an previously created results file
and might be necessary to implement forther selection methods.

=cut

sub read_file {
	my ( $self, $filename, $lines ) = @_;
	return undef unless ( -f $filename );
	$self->{'read_filename'}   = $filename;
	$self->{'header_position'} = {};
	$self->{'header'}          = [];
	$self->{'data'}            = [];
	my ( @line, $value );
	open( IN, "<$filename" )
	  or die ref($self)
	  . "::read_file -> could not open file '$filename'\n$!\n";

	if ( defined $lines ) {
		my $i = 0;
		foreach (<IN>) {
			push( @line, $_ );
			$i++;
			last if ( $i >= $lines );
		}
		$self->parse_from_string( \@line );
	}
	else {
		$self->parse_from_string( [<IN>] );
	}
	return $self;
}

sub get_all_supportive_oligos {
	my ($self) = @_;
	$self->Check_MeDIP_Hypothesis();
	my $expression =
	  $self->Header_Position('all expression changes are significant');
	my $MeDIP = $self->Header_Position(
		'expression difference invers to MeDIP difference');
	+my ( $array, $hash );
	my $return = $self->_copy_without_data();
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$array = @{ $self->{'data'} }[$i];
		if ( @$array[$MeDIP] eq "Yes" && @$array[$expression] eq "Yes" ) {
			$return->AddDataset( $self->get_line_asHash($i) );
		}
	}
	$return->Description( $self->Description() );
	$return->Add_2_Description("Only supportive and significant oligos shown");
	return $return;
}

sub pre_process_array {
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	return 1;
}

sub Add_Olig_Infos {
	my ( $self, $filename ) = @_;
	return 1 if ( $self->Header_Position('CpG content [n]') );
	my $ndfFile    = ndfFile->new();
	my $oligo_info = $ndfFile->GetAsFastaDB($filename);

#die root::get_hashEntries_as_string ($oligo_info, 3, "the oligo info $oligo_info");
	my ( $oligoID, $CpG_pos, $seq_pos, $SEQ, $sum, $last_C );
	$CpG_pos = $self->Add_2_Header('CpG content [n]');
	$seq_pos = $self->Add_2_Header('seq');

	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$oligoID = @{ @{ $self->{'data'} }[$i] }[0];
		unless ( defined $oligo_info->{'data'}->{$oligoID} ) {
			warn "we do not know the oligo '$oligoID'\n";
			next;
		}
		$SEQ = uc( $oligo_info->{'data'}->{$oligoID} );
		@{ @{ $self->{'data'} }[$i] }[$CpG_pos] = scalar( $SEQ =~ s/CG/CG/g );
		@{ @{ $self->{'data'} }[$i] }[$seq_pos] =
		  $oligo_info->{'data'}->{$oligoID};
	}
	return 1;
}

sub Check_MeDIP_Hypothesis {
	my ($self) = @_;
	## OK I need the gene expressions - but where to find them??
	unless ( scalar( @{ $self->{'fold_change_columns'} } ) > 0 ) {
		Carp::confess("Please add some expression data first!\n");
	}
	return 1
	  if (
		defined $self->Header_Position(
			'expression difference invers to MeDIP difference')
	  );
	my $MeDIP =
	  $self->Add_2_Header('expression difference invers to MeDIP difference');
	my $Expression =
	  $self->Add_2_Header('all expression changes are significant');
	my @expression_changes =
	  $self->define_subset( 'FoldChange', $self->{'fold_change_columns'} );
	my @expression_p_values = $self->define_subset( 'Expression_p values',
		$self->{'expreesion_p_values'} );
	my ( $OK, $p_OK, $array, $medip_fold_change );
	unless ( defined $self->Header_Position('difference [A -B ]') ) {
		## OOPS - we have an old version data file and need to change that to new version!
		$medip_fold_change = $self->Add_2_Header('difference [A -B ]');
		my ( $MeDIP_A, $MeDIP_B );
		$MeDIP_A = $self->Header_Position('meanA');
		$MeDIP_B = $self->Header_Position('meanB');
		for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
			$array = @{ $self->{'data'} }[$i];
			unless ( defined @$array[$MeDIP_A] || defined @$array[$MeDIP_B] ) {
				## OH that could be an alternative splice event
				## captured by the expression arrays, but not by the MeDIP
				## I should state that!
				@$array[$medip_fold_change] = 0;
				@$array[$MeDIP_A]           = 0;
				@$array[$MeDIP_B]           = 0;
				@$array[0] =
"artifact due to two or more splice isoforms analyzed on the expression arrays";
				next;
			}
			@$array[$medip_fold_change] = @$array[$MeDIP_A] - @$array[$MeDIP_B];
		}
	}
	else {
		$medip_fold_change = $self->Header_Position('difference [A -B ]');
	}

	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$OK = $p_OK = 1;
		$array = @{ $self->{'data'} }[$i];
		next unless ( defined @$array[$medip_fold_change] );
		foreach ( @$array[@expression_p_values] ) {
			unless ( defined $_ ) {
				$p_OK = 0;
			}
			if ( $_ < 0 ) {
				$p_OK = 0;
			}
		}
		if ($p_OK) {
			@$array[$Expression] = "Yes";
		}
		else {
			@$array[$Expression] = "No";
		}

		if ( @$array[$medip_fold_change] > 0 ) {
			foreach ( @$array[@expression_changes] ) {
				unless ( defined $_ ) {
					$OK = 0;
					last;
				}
				if ( $_ < 0 ) {
					$OK = 0;
					last;
				}
			}
		}
		elsif ( @$array[$medip_fold_change] < 0 ) {
			foreach ( @$array[@expression_changes] ) {
				unless ( defined $_ ) {
					$OK = 0;
					last;
				}
				if ( $_ > 0 ) {
					$OK = 0;
					last;
				}
			}
		}
		else {
			$OK = 0;
		}
		if ($OK) {
			@$array[$MeDIP] = "Yes";
		}
		else {
			@$array[$MeDIP] = "No";
		}
	}

}

sub Add_GeneExpression_File {
	my ( $self, $filename, $data_name ) = @_;
	$data_name = '' unless ( defined $data_name );
	Carp::confess("We can not open the file '$filename'\n")
	  unless ( -f $filename );
	my $expression_result =
	  stefans_libs_file_readers_affymetrix_expression_result->new();
	$expression_result->p4cS( @{ $self->Samples_GroupA() },
		@{ $self->Samples_GroupB() } );
	$expression_result->read_file($filename);
	my ( $genes, $hash );
	$self->createIndex('Gene Symbol');
	$expression_result->revert_RMA_log_values() if ( $filename =~ m/rma/ );

	foreach ( $self->getIndex_Keys('Gene Symbol') ) {
		$genes->{$_} = 1;
	}
	$expression_result->select_where( 'Gene Symbol',
		sub { return 1 if ( $genes->{ $_[0] } ); return 0; } );
	$expression_result->Sample_Groups( $self->Samples_GroupA() );
	$expression_result->Sample_Groups( $self->Samples_GroupB() );
	my $data_2_add = $expression_result->calculate_statistics();
	$self->Description(
		[ @{ $self->Description() }, @{ $data_2_add->Description() } ] );
	foreach ( @{ $data_2_add->{'header'} } ) {
		$self->{'accepted_new'}->{$_} = 1;
		$self->Add_2_Header($_);
	}
	## now I need to add the data!
	for ( my $i = 0 ; $i < @{ $data_2_add->{'data'} } ; $i++ ) {
		$hash = $data_2_add->get_line_asHash($i);
		if (
			defined $self->{'index'}->{'Gene Symbol'}
			->{ $hash->{'Gene Symbol'} } )
		{
			$self->AddDataset($hash);
		}
	}
	## And now we rename the columns (if we have a $data_name)
	if ( $data_name =~ m/\w/ ) {
		foreach ( @{ $data_2_add->{'header'} } ) {
			next if ( $_ eq "Gene Symbol" );
			$self->Rename_Column( $_, "$data_name $_" );
			if ( $_ =~ m/difference/ ) {
				push( @{ $self->{'fold_change_columns'} }, "$data_name $_" );
			}
			if ( $_ =~ m/p value/ ) {
				push( @{ $self->{'expreesion_p_values'} }, "$data_name $_" );
			}
		}
	}
	return 1;
}

sub Add_Genes_Using_this_GFF {
	my ( $self, $gff_file ) = @_;
	return 1 if ( defined $self->Header_Position('Gene Symbol') );
	my ( $gene_symbol_pos, $location_pos );

	$gene_symbol_pos = $self->Add_2_Header('Gene Symbol');
	$location_pos    = $self->Add_2_Header('location');

	$self->parse_oligo_id_2_position();
	my $Nimblegene_GeneInfo = Nimblegene_GeneInfo->new();
	$Nimblegene_GeneInfo->read_file($gff_file);
	my ( $array, $promoters, $dataArray, $location );
	$promoters =
	  $Nimblegene_GeneInfo->__define_promoter_structure( 2500, 7500 );
	foreach $array ( keys %$promoters ) {
		$promoters->{$array} =
		  [ sort { @$a[4] <=> @$b[4] } @{ $promoters->{$array} } ];
	}
	my ( $oligoRep, $return, $min, $min_A, $min_B, $used, $drop_chr );
	$drop_chr = {};
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$oligoRep = $self->get_line_asHash($i);
		$used     = 0;
		$min      = undef;
		unless ( ref( $promoters->{ $oligoRep->{'chr'} } ) eq "ARRAY" ) {
			$drop_chr->{ $oligoRep->{'chr'} } = 1;
			next;
			Carp::confess(
"OOPS - we do not know this chromosome: $oligoRep->{'chr'}\nwe know these: "
				  . join( ", ", keys %$promoters ) );
		}
		$return = {};
		foreach $dataArray ( @{ $promoters->{ $oligoRep->{'chr'} } } ) {
			$used++ if ( $used != 0 );
			$min = undef;
			if (   $oligoRep->{'end'} >= @$dataArray[0]
				&& $oligoRep->{'start'} <= @$dataArray[1] )
			{

				$location = '';
				$min_A = ( ( @$dataArray[4] - $oligoRep->{'start'} )**2 )**0.5;
				$min_B = ( ( @$dataArray[4] - $oligoRep->{'end'} )**2 )**0.5;
				$min   = $min_A;
				$min   = $min_B if ( $min_B < $min_A );

#Carp::confess ( root::get_hashEntries_as_string ($dataArray, 3, "\$dataArray "));
				if ( @$dataArray[3] eq "sense" ) {
					$location = join( "",
						$oligoRep->{'start'} - @$dataArray[4],
						"..", $oligoRep->{'end'} - @$dataArray[4] );
				}
				else {
					$location = join(
						"",
						(
							@$dataArray[4] - $oligoRep->{'end'},
							"..",
							@$dataArray[4] - $oligoRep->{'start'}
						)
					);
				}
				$return->{"$min"} =
				  { 'location' => $location, 'gene' => "@$dataArray[2]" };
				$used = 1;

				#print "we added a min $min (@$dataArray[2])\n";
			}
			last if ( !defined $min && $used > 1 );
		}
		foreach $min ( sort { $a <=> $b } keys %$return ) {
			## Add the new info!
	  #print
	  #"we add the gene $return->{$min}->{'gene'} using a differnece of $min\n";
			@{ @{ $self->{'data'} }[$i] }[$gene_symbol_pos] =
			  $return->{$min}->{'gene'};
			@{ @{ $self->{'data'} }[$i] }[$location_pos] =
			  $return->{$min}->{'location'};
			$used = $min;
			last;
		}
		next;
		Carp::confess(
			root::get_hashEntries_as_string( $oligoRep, 3,
"OH we could not identfy a promotor where we could match this oligo to"
			  )
			  . root::get_hashEntries_as_string(
				$promoters->{ $oligoRep->{'chr'} },
				3,
				"using this promoter dataset\n"
			  )
		);
	}
	if ( scalar( keys %$drop_chr ) > 0 ) {
		$return =
		  $self->select_where( 'chr',
			sub { return 0 if ( $drop_chr->{ $_[0] } ); return 1; } );
		$return->Description( $self->Description() );
		$self = $return;
	}
	return 1;
}

sub restrict_to_p_value {
	my ( $self, $p_value ) = @_;
	$p_value = 0.05 unless ( defined $p_value );
	my $log = 0;
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		if ( @{ @{ $self->{'data'} }[$i] }[1] > 1 ) {
			$log = 1;
			last;
		}
	}
	my $return;
	if ($log) {
		$p_value = -&log10($p_value);
		$return =
		  $self->select_where( 'p value',
			sub { return 1 if ( $_[0] >= $p_value ); return 0 } );
	}
	else {
		$return =
		  $self->select_where( 'p value',
			sub { return 1 if ( $_[0] <= $p_value ); return 0 } );
	}
	$return->Description( $self->Description() );
	return $return;
}

sub log10 {
	my $n = shift;
	unless ( $n > 0 ) {
		warn "we can not take the log of that entry ($n)!\n";
		return undef;
	}
	return log($n) / log(10);
}

sub Samples_GroupA {
	my ($self) = @_;

#group 1:       34885_1 34893_1 34894_1 34895_1 34896_1 34898_1 34900_1 34906_1 34910_1 34912_1 34919_1 34901_1 34927_1 34928_1 34932_1
	my @return;
	foreach ( @{ $self->Description() } ) {
		if ( $_ =~ m/group 1:\t/ ) {
			chomp $_;
			@return = split( "\t", $_ );
			shift(@return);
		}
	}
	return \@return;
}

sub Samples_GroupB {
	my ($self) = @_;

#group 2:       34885_2 34893_2 34894_2 34895_2 34896_2 34898_2 34900_2 34906_2 34910_2 34912_2 34919_2 34901_2 34927_2 34928_2 34932_2
	my @return;
	foreach ( @{ $self->Description() } ) {

	#print ref($self)."::Samples_GroupB - we parse the description line '$_'\n";
		if ( $_ =~ m/group 2:\t/ ) {
			chomp $_;
			@return = split( "\t", $_ );
			shift(@return);
		}
	}
	return \@return;
}

sub parse_oligo_id_2_position {
	my ($self) = @_;
	return 1 if ( defined $self->Header_Position('chr') );
	my ( $array, $chr_pos, $start_pos, $end_pos, $use_seq );
	$use_seq = 0;
	$use_seq = $self->Header_Position('seq')
	  if ( defined $self->Header_Position('seq') );
	$chr_pos   = $self->Add_2_Header('chr');
	$start_pos = $self->Add_2_Header('start');
	$end_pos   = $self->Add_2_Header('end');
	foreach $array ( @{ $self->{'data'} } ) {

		if ( @$array[0] =~ m/CHR0?(\w+)FS(\d+)/ ) {
			@$array[$chr_pos]   = "chr$1";
			@$array[$start_pos] = $2 + 0;
			if ( $use_seq > 0 && length( @$array[$use_seq] ) > 0 ) {
				@$array[$end_pos] = $2 + length( @$array[$use_seq] );
			}
			else {
				@$array[$end_pos] = $2 + 50;
			}
		}
	}
	return 1;
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		unless ( $self->{'accepted_new'}->{$value} ) {
			Carp::confess("You must not add that column '$value'!\n")
			  unless ( $self->__check_accepted_new_partial($value) );
		}
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] = $value;
		${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ] =
		  '';
	}
	return $self->{'header_position'}->{$value};
}

sub __check_accepted_new_partial {
	my ( $self, $value ) = @_;
	## $self->{'fold_change_columns'}
	foreach ( @{ $self->{'accepted_new_partial'} } ) {
		if ( $value =~ m/difference A-B/ ) {
			push( @{ $self->{'fold_change_columns'} }, $value );
		}
		elsif ( $value =~ m/p value/ ) {
			push( @{ $self->{'expreesion_p_values'} }, $value );
		}
		return 1 if ( $value =~ m/$_/ );
	}
	return 0;
}

1;
