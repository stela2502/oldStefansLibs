package oligo2DNA_table;

use stefans_libs::database::genomeDB;
use strict;
use warnings;

## that should be small!

sub new {
	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'            => $debug,
		'header'           => undef,
		'oligoID_2_lineNr' => {},
		'data'             => []
	};

	bless( $self, $class ) if ( $class eq "oligo2DNA_table" );

	return $self;
}

sub ENFORCE_ORDER {
	my ($self) = @_;
	return $self if ( $self->{'ordered'} );
	my $return = oligo2DNA_table->new( $self->{'debug'} );
	$return->{'header'} = $self->{'header'};
	## 1. We need to order by chromosome!
	## 2. we need to order by chr_start
	## therefore we need a temporary array
	my @temp;
	## I need to know the position of the chromosome and the chr_start in our data structure
	my ( $chr, $chr_start, $last_chr, $i );
	$chr       = $self->{'header'}->{'chromosome_name'};
	$chr_start = $self->{'header'}->{'chr_start'};
	$i         = 0;
	foreach
	  my $data_line ( sort { @$a[$chr] cmp @$b[$chr] } @{ $self->{'data'} } )
	{
		$last_chr = @$data_line[$chr] unless ( defined $last_chr );

		unless ( $last_chr eq @$data_line[$chr] ) {
			foreach
			  my $sorted ( sort { @$a[$chr_start] <=> @$b[$chr_start] } @temp )
			{
				$return->AddDataLine($sorted);

				#print join( "; ", @$sorted ) . "\n";
			}
			$last_chr = @$data_line[$chr];
			@temp     = undef;
			$i        = 0;
		}
		$temp[ $i++ ] = $data_line;
	}
	foreach my $sorted ( sort { @$a[$chr_start] <=> @$b[$chr_start] } @temp ) {
		$return->AddDataLine($sorted);
		#print join( "; ", @$sorted ) . "\n";
	}

	$self = $return;
	$self->{'ordered'} = 1;
	return $self;
}

sub connect_2_genomeTable {
	my ( $self, $orgaism_tag, $version ) = @_;
	my $genomeDB = genomeDB->new( '', $self->{'debug'} );
	$self->{'genome_interface'} = $genomeDB->getGenomeHandle_for_dataset(
		{ 'version' => $version, 'organism_tag' => $orgaism_tag } );
	return 1 if ( ref( $self->{'genome_interface'} ) =~ m/\w/ );
	return 0;
}

sub get_closeby_gene_PROMOTER_MODE {
	my ( $self) = @_;
	return $self->get_closeby_gene ( 10000, 2000);
}

sub get_closeby_gene_ENHANCER_MODE {
	my ( $self ) = @_;
	return $self->get_closeby_gene ( 500000, 500000);
}

sub get_closeby_gene {
	my ($self, $upstream, $downstream ) = @_;

	$self->ENFORCE_ORDER();

	my (
		$chr_start_nr, $chromosome, $last_chr,  $chr,      $data,
		$i,            $oligoID,    $chr_start, $lastGood, $return
	);
	$chr          = $self->{'header'}->{'chromosome_name'};
	$chr_start_nr = $self->{'header'}->{'chr_start'};

	## we need to change the genomeDB interface - the gbFiles table has to go away!
	## H_sapiens_36_3_gbFeaturesTable.gbFile_id =  H_sapiens_36_3_chromosomesTable.id
	$data = $self->{'genome_interface'}->unlink_gbFilesTable();

	foreach my $data_line ( @{ $self->{'data'} } ) {
		last if ( $last_chr eq "2" );
		$last_chr = @$data_line[$chr] unless ( defined $last_chr );
		$chromosome = undef unless ( $last_chr eq @$data_line[$chr] );
		print "we execute for chr @$data_line[$chr]\n";
		unless ( ref($chromosome) eq "ARRAY" ) {
			$chromosome = [];
			$i          = 0;
			print "we need to set up the chromosome\n";
			$data = $self->{'genome_interface'}->getArray_of_Array_for_search(
				{
					'search_columns' => [
						'gbFeaturesTable.gbString',
						'chromosomesTable.chr_start'
					],
					'where' => [
						[ 'chromosomesTable.chromosome', '=', 'my_value' ],
						[ 'gbFeaturesTable.tag',         '=', 'my_value' ]
					],
					'order_by' => [ 'chromosomesTable.chr_start', 'gbFeaturesTable.start' ]
				},
				$last_chr,
				'gene'
			);
			print
"we useed this query to get the gbFeatures matching gene from the chromosome $last_chr\n";

			foreach my $result_array (@$data) {
				my $gbFeature = gbFeature->new( 'nix', '1..2' );
				$gbFeature->parseFromString( @$result_array[0] );
				#print "we got a start of ".$gbFeature->Start()."\n";
				$gbFeature->ChangeRegion_Add( @$result_array[1] );
				#print "and that changed to ".$gbFeature->Start()." after we added @$result_array[1]\n";
				@$chromosome[ $i++ ] = [
					$gbFeature->getPromoterRegion(  $upstream, $downstream ),
					$gbFeature->Name()
				];
				#print "we create the promoter array adding the values ". join ("; ", @{@$chromosome[ $i -1 ]} )." [". join ("; ", @{@$chromosome[ $i -2 ]}) ."]\n" if ( ($i -2) >= 0 );
			}
			$lastGood = 0;
		}
		## now we have a list @$chromosome that contains all promoters
		## and an entry point into that list givung the last known matching promoter ($lastGood)
		## Therefore we now have to iterate over the oligos and get the good promoters for each oligo
		$chr_start = @$data_line[$chr_start_nr];
		$oligoID   = @$data_line[ $self->{'header'}->{'oligoID'} ];
		for ( my $a = 0 ; $a < @$chromosome ; $a++ ) {
			#print "we try to match to the promoter ".join("; ", @{@$chromosome[$a]} )."\n";
			if (   $chr_start <= @{ @$chromosome[$a] }[1]
				&& $chr_start >= @{ @$chromosome[$a] }[0] )
			{
				$lastGood = $i;
				print "we found a match! ( $chr_start <= @{ @$chromosome[$a] }[1] && $chr_start >= @{ @$chromosome[$a] }[0])\n";
				$return->{$oligoID} = [] unless ( defined $return->{$oligoID} );
				push( @{ $return->{$oligoID} }, @{ @$chromosome[$a] }[2] );
			}
			elsif ( $chr_start < @{ @$chromosome[$a] }[0] ) {
				print "$chr_start was <   @{ @$chromosome[$a] }[0] -> last\n";
				last;
			}
			elsif ( $chr_start < @{ @$chromosome[$a] }[0] ) {
				print "$chr_start was >   @{ @$chromosome[$a] }[1] -> we need to look at the next promoter\n";
				next;
			}
		}
		$last_chr = @$data_line[$chr];
	}
	$data = $self->{'genome_interface'}->relink_gbFilesTable();
	print root::get_hashEntries_as_string (
		$return, 3,
		ref($self) . " get_closeby_gene_PROMOTER_MODE -- we return that datset "
	);
	return $return;
}


sub restrict_to_oligoList {
	my ( $self, $oligoList ) = @_;
	my $new_list = oligo2DNA_table->new( $self->{'debug'} );
	$new_list->{'header'} = $self->{'header'};
	foreach my $oligoID (@$oligoList) {
		unless ( ref( $self->{'oligoID_2_lineNr'}->{$oligoID} ) eq "ARRAY" ) {
			warn "we do not have a position list for the oligoID $oligoID";
			next;
		}
		foreach my $LineNr ( @{ $self->{'oligoID_2_lineNr'}->{$oligoID} } ) {
			$new_list->AddDataLine( @{ $self->{'data'} }[$LineNr] );
		}
	}
	return $new_list;
}

sub Read_from_File {
	my ( $self, $filename ) = @_;
	warn ref($self)
	  . "::Read_from_File we alrady know some values - aborting!\n"
	  if ( scalar( @{ $self->{'data'} } ) > 0 );
	unless ( -f $filename ) {
		Carp::confess(
			ref($self)
			  . "::Read_from_File->we could not open the file $filename\n" );
	}
	open( IN, "<$filename" )
	  or die ref($self) . " We could not open the file '$filename'\n$!\n";
	my $line = 0;
	while (<IN>) {
		chomp($_);
		unless ( defined $self->{'header'} ) {
			$self->{'header'} = {};
			my @line = split( "\t", $_ );
			for ( my $i = 0 ; $i < @line ; $i++ ) {
				$self->{'header'}->{ $line[$i] } = $i;
			}
			next;
		}
		$self->AddDataLine( [ split( "\t", $_ ) ] );
		$line++;
	}
	print "read $line oligo to genome matches\n";
}

sub AddDataLine {
	my ( $self, $line ) = @_;
	my $position = scalar( @{ $self->{'data'} } );
	@{ $self->{'data'} }[$position] = $line;
	$self->{'oligoID_2_lineNr'}
	  ->{ $self->__get_values_from_line( 'oligoID', $position ) } = []
	  unless (
		defined $self->{'oligoID_2_lineNr'}
		->{ $self->__get_values_from_line( 'oligoID', $position ) } );
	push(
		@{
			$self->{'oligoID_2_lineNr'}
			  ->{ $self->__get_values_from_line( 'oligoID', $position ) }
		  },
		$position
	);
	return 1;
}

sub __get_values_from_line {
	my ( $self, $value, $line ) = @_;

	unless ( ref($value) eq "ARRAY" ) {
		return @{ @{ $self->{'data'} }[$line] }[ $self->{'header'}->{$value} ];
	}

	my @return;
	foreach my $tag (@$value) {
		push( @return,
			@{ @{ $self->{'data'} }[$line] }[ $self->{'header'}->{$value} ] );
	}
	return @return;
}

1;
