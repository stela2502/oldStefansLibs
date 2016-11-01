package SNP_2_gene_expression_reader;

#  Copyright (C) 2010-08-23 Stefan Lang

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

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::file_readers::SNP_2_gene_expression_reader.pm

=head1 DESCRIPTION

A lib file that is able to read a SNP 2 gene expression fil and can plot interesting entries. In the future, it might also be able to put the information into the database. But that is things to come.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class SNP_2_gene_expression_reader.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug' => $debug,
		'data'  => {}
	};

	bless $self, $class if ( $class eq "SNP_2_gene_expression_reader" );

	return $self;

}

sub __parse_orig_entries {
	my ( $self, $hash ) = @_;
	my ( $error, $data, @header, @data, $temp, $snp_count );
	unless ( ref($hash) eq "HASH" ) {
		$error .= ref($self)
		  . ":__parse_orig_entries we need a has of variables at startup\n\tsee the other error messages for help!\n";
		$hash = {};
	}
	if (   !( ref( $hash->{'file'} ) eq "GLOB" )
		|| !( ref( $hash->{'array'} ) eq "ARRAY" ) )
	{
		$error .= ref($self)
		  . ":__parse_orig_entries - we did not get any data as neither file nor array is set!\n";
	}
	if ( !defined $hash->{'gene'} && !defined $self->{'correlating_gene'} ) {
		$error .= ref($self)
		  . ":__parse_orig_entries - sorry, but we need to know with which 'gene' we got a correlation with!\n";
	}
	$hash->{'p_value_cutoff'} = 1 if ( !defined $hash->{'p_value_cutoff'} );

	if ( ref( $hash->{'file'} ) eq "GLOB" ) {
		$data = $hash->{'file'};
		while (<$data>) {

			chomp $_;
			if ( $_ eq "" ) {

				#print "we have to initialize our variables!\n";
				@header = undef;
				@data   = ();
				next;
			}

			if ( defined $header[0] ) {
				@data = split( "\t", $_ );
				$data[0] =~ s/ //g;

				#print "we read the rsID $data[0]\n";
				next if ( defined $self->{'data'}->{ $data[0] } );
				$self->{'data'}->{ $data[0] } = { 'header' => [@header] };
				for ( my $i = 0 ; $i < @data ; $i++ ) {
					$header[$i] = "p-value" if ( $header[$i] eq "p value" );
					$self->{'data'}->{ $data[0] }->{ $header[$i] } = $data[$i];
				}
				Carp::confess(
					root::get_hashEntries_as_string(
						$self->{'data'}->{ $data[0] },
						3,
"we could not read the entry as the p-value is not defined ",
						100
					)
				  )
				  unless ( defined $self->{'data'}->{ $data[0] }->{'p-value'} );
				if ( $self->{'data'}->{ $data[0] }->{'p-value'} >
					$hash->{'p_value_cutoff'} )
				{
					delete $self->{'data'}->{ $data[0] };
				}
				next;
			}
			@header = split( "\t", $_ );
		}
	}
	elsif ( ref( $hash->{'array'} ) eq "ARRAY" ) {
		while ( @{$hash->{'array'}}){
			chomp $_;
			if ( $_ eq "" ) {

				#print "we have to initialize our variables!\n";
				@header = undef;
				@data   = ();
				next;
			}

			if ( defined $header[0] ) {
				@data = split( "\t", $_ );
				$data[0] =~ s/ //g;

				#print "we read the rsID $data[0]\n";
				next if ( defined $self->{'data'}->{ $data[0] } );
				$self->{'data'}->{ $data[0] } = { 'header' => [@header] };
				for ( my $i = 0 ; $i < @data ; $i++ ) {
					$header[$i] = "p-value" if ( $header[$i] eq "p value" );
					$self->{'data'}->{ $data[0] }->{ $header[$i] } = $data[$i];
				}
				Carp::confess(
					root::get_hashEntries_as_string(
						$self->{'data'}->{ $data[0] },
						3,
"we could not read the entry as the p-value is not defined ",
						100
					)
				  )
				  unless ( defined $self->{'data'}->{ $data[0] }->{'p-value'} );
				if ( $self->{'data'}->{ $data[0] }->{'p-value'} >
					$hash->{'p_value_cutoff'} )
				{
					delete $self->{'data'}->{ $data[0] };
				}
				next;
			}
			@header = split( "\t", $_ );
		}
	}
	return 1;
}

sub read_file {
	my ( $self, $infile, $p_value_cutoff ) = @_;
	Carp::confess(
		"Sorry, but I can not read from an not existing file '$infile'\n")
	  unless ( -f $infile );
	open( IN, "<$infile" );
	$p_value_cutoff = 1 unless ( defined $p_value_cutoff );
	my ( $dataset, @header, @data, $gene, $pathway, $geneName );

#rsID    Probe Set ID    Gene Symbol     mRna - Description      p value w       rho     group1->        ISL0015 ISL0019 ISL0022 ISL0005 ISL0025 ISL0027 ISL0029      ISL0030 ISL0031 ISL0034 ISL0037 ISL0038 ISL0040 ISL0044 ISL0047 ISL0048 ISL0049 ISL0050 group2->        ISL0001 ISL0010 ISL0011 ISL0012 ISL0013 ISL0014      ISL0016 ISL0002 ISL0020 ISL0021 ISL0003 ISL0004 ISL0006 ISL0007 ISL0008 ISL0009 ISL0023 ISL0024 ISL0026 ISL0028 ISL0032 ISL0033 ISL0035 ISL0036 ISL0039      ISL0041 ISL0042 ISL0043 ISL0045 ISL0046
#rs7967279      8129590 STX7    Homo sapiens syntaxin 7 (STX7). mRNA.   0.0006309       431             A/G     8.790747        8.384394        8.55669 8.664406     8.70976 8.780083        9.303828        8.77266 8.817075        8.818363        8.598653        8.229196        8.642244        8.821452        8.691568     8.738474        8.77425 8.911719        G/G     8.682122        8.653062        8.306258        8.291207        8.466276        8.456207        8.422802     8.161073        6.478458        8.326546        8.690364        8.595198        7.859156        7.707721        8.197258        8.363508        8.615611     8.51486 8.870448        8.547527        8.897597        8.683447        8.665744        8.593567        6.945088        8.426417        8.574166    9.036226 8.511272        8.207947
#
#rsID ...

	@data = split( "/", $infile );
	$pathway = $data[ @data - 1 ];
	$pathway =~ s/\.txt$//;
	@data = split( /[-_]/, $pathway );
	
	$geneName = shift(@data);
	if ( defined $self->{'correlating_gene'} ){
		Carp::confess(
		"Sorry, but you can not read from two differnet files with one object\n"
	) unless (  $self->{'correlating_gene'} eq $geneName );
	}
	$self->{'correlating_gene'} = $geneName;
	$self->{'pathway'}          = join( " ", @data );
	@data                       = undef;
	$self->__parse_orig_entries( {
		'gene' => $self->{'correlating_gene'},
		'file' => *IN
	});

	LINES: while (<IN>) {
		chomp $_;
		if ( $_ =~m/^correlating data set\t/ ){
			## DAMN a linear correlation result!
			close ( IN );
			$self->{'correlating_gene'}= undef;
			return $self->__read_linear_model_results( $infile, $p_value_cutoff );
		}
		if ( $_ eq "" ) {

			#print "we have to initialize our variables!\n";
			@header = undef;
			@data   = ();
			next;
		}

		if ( defined $header[0] ) {
			@data = split( "\t", $_ );
			$data[0] =~ s/ //g;

			#print "we read the rsID $data[0]\n";
			next if ( defined $self->{'data'}->{ $data[0] } );
			$self->{'data'}->{ $data[0] } = { 'header' => [@header] };
			for ( my $i = 0 ; $i < @data ; $i++ ) {
				unless ( defined $header[$i]){
					$header[$i] = 'no name';
					#warn "we had an undefined column header at position $i\n". join("\t", @header)."\ndata:'"
					#. join("\t", @data)."'\n\n";
					warn "the file is not complete!!\n";
					delete $self->{'data'}->{ $data[0] };
					for ( my $a = 0; $a < @data; $a++ ){
						## the header has to be saved!
						if ( $data[$a] =~ m/(rsID)/ ){
							$data[$a] = $1;
							@header = @data[$a..(@data-1) ];
							#print "the new header = ".join("; ", @header)."\n";
						}
					}
					
					@data   = ();
					next LINES;
				}
				$header[$i] = "p-value" if ( $header[$i] eq "p value" );
				$self->{'data'}->{ $data[0] }->{ $header[$i] } = $data[$i];
			}
			Carp::confess(
				root::get_hashEntries_as_string(
					$self->{'data'}->{ $data[0] },
					3,
"we could not read the entry as the p-value is not defined ",
					100
				)
			) unless ( defined $self->{'data'}->{ $data[0] }->{'p-value'} );
			if ( $self->{'data'}->{ $data[0] }->{'p-value'} > $p_value_cutoff )
			{
				delete $self->{'data'}->{ $data[0] };
			}
			next;
		}
		@header = split( "\t", $_ );
	}
	close(IN);
	return scalar( keys %{ $self->{'data'} } );
}


sub __read_linear_model_results{
	my ( $self, $infile, $p_value_cutoff ) = @_;
	Carp::confess(
		"Sorry, but I can not read from an not existing file '$infile'\n")
	  unless ( -f $infile );
	open( IN, "<$infile" );
	$p_value_cutoff = 1 unless ( defined $p_value_cutoff );
	my ( $dataset, @header, @data, $gene, $pathway, @correlations, $geneName );
	@data = split( "/", $infile );
	$pathway = $data[ @data - 1 ];
	$pathway =~ s/\.txt$//;
	@data = split( /[-_]/, $pathway );
	
	$geneName = shift(@data);
	if ( defined $self->{'correlating_gene'} ){
		Carp::confess(
		"Sorry, but you can not read from two differnet files with one object\n"
	) unless (  $self->{'correlating_gene'} eq $geneName );
	}
	
	$self->{'correlating_gene'} = $geneName;
	$self->{'pathway'}          = join( " ", @data );
	@data                       = undef;
	$self->__parse_orig_entries( {
		'gene' => $self->{'correlating_gene'},
		'file' => *IN
	});
	#rsID    Probe Set ID    Gene Symbol     p value S       rho     ISL0001 ISL0002 ISL0003 ISL0004 ISL0005 ISL0006 ISL0007 ISL0008 ISL0009 ISL0010 ISL0011 ISL0012      ISL0013 ISL0014 ISL0015 ISL0016 ISL0019 ISL0020 ISL0021 ISL0022 ISL0023 ISL0024 ISL0025 ISL0026 ISL0027 ISL0028 ISL0029 ISL0030 ISL0031 ISL0032 ISL0033      ISL0034 ISL0035 ISL0036 ISL0037 ISL0038 ISL0039 ISL0040 ISL0041 ISL0042 ISL0043 ISL0044 ISL0045 ISL0046 ISL0047 ISL0048 ISL0049 ISL0050 ISL0051 ISL0052      ISL0053 ISL0054 ISL0055 ISL0056 ISL0057 ISL0058 ISL0059
	#correlating data set                                    2       2       2       2       2       1       2       1       2       0       2       2       2   22       2       1       1       2       2       1       2       2       1       2       2       0       2       1       2       2       2       2       1   22       2       2       2       2       2       1       2       1       2       2       2       1       2       2       1       2       2       2       2   12
	#rs11114531      8121768 PKIB    0.000699        44308.6 -0.4359801      5.75    5.71    5.62    6.14    5.88    6.35    6.52    6.07    6.03    6.04    5.585.29     5.6     6.23    5.93    5.95    6.09    6.5     6.25    6.07    6.16    6.27    5.9     6.27    6.01    5.63    6.55    6.03    5.51    6.08    6.035.81     6.01    6.47    5.49    5.64    6.45    6.15    5.5     5.77    5.97    6.18    6.46    6.3     6.32    5.89    6.05    5.79    5.97    5.93    6.876.01     6.04    5.88    6.14    6.34    5.91
	LINES: while (<IN>) {
		chomp $_;
		if ( $_ eq "" ) {
			@header = undef;
			@correlations = undef;
			@data   = ();
			next;
		}
		if ( defined $header[0] && defined $correlations[0] ) {
			@data = split( "\t", $_ );
			$data[0] =~ s/ //g;
			#print "we read the rsID $data[0]\n";
			next if ( defined $self->{'data'}->{ $data[0] } );
			$self->{'data'}->{ $data[0] } = { 'header' => [@header] };
			#print "NOW we have read ".scalar( keys %{ $self->{'data'} } )." SNPs\n";
			for ( my $i = 0 ; $i < @data ; $i++ ) {
				unless ( defined $header[$i]){
					$header[$i] = 'no name';
					#warn "we had an undefined column header at position $i\n". join("\t", @header)."\ndata:'"
					#. join("\t", @data)."'\n\n";
					warn "the file is not complete!!\n";
					delete $self->{'data'}->{ $data[0] };
					for ( my $a = 0; $a < @data; $a++ ){
						## the header has to be saved!
						if ( $data[$a] =~ m/(rsID)/ ){
							$data[$a] = $1;
							@header = @data[$a..(@data-1) ];
							#print "the new header = ".join("; ", @header)."\n";
						}
					}
					@data   = ();
					next LINES;
				}
				$header[$i] = "p-value" if ( $header[$i] eq "p value" );
				$self->{'data'}->{ $data[0] }->{ $header[$i] } = $data[$i];
				
			}
			Carp::confess(
				root::get_hashEntries_as_string(
					$self->{'data'}->{ $data[0] },
					3,
"we could not read the entry as the p-value is not defined ",
					100
				)
			) unless ( defined $self->{'data'}->{ $data[0] }->{'p-value'} );
			if ( $self->{'data'}->{ $data[0] }->{'p-value'} > $p_value_cutoff )
			{
				#print "we delete the SNP $data[0] as the p_value was too low ($self->{'data'}->{ $data[0] }->{'p-value'})\n";
				delete $self->{'data'}->{ $data[0] };
			}
			else {
				print "we keep the SNP $data[0]\n";
			}
			next;
		}
		unless ( defined $header[0] ){
			@header = split( "\t", $_ );
			next;
		}
		unless ( defined $correlations[0]){
			@correlations = split( "\t", $_ );
			next;
		}
		
	}
	close(IN);
	#print root::get_hashEntries_as_string ($self , 5, "we read a linear correlations file");
	print "And we have read ".scalar( keys %{ $self->{'data'} } )." SNPs\n";
	return scalar( keys %{ $self->{'data'} } );
}


sub get_rsIDs {
	my ($self) = @_;
	return ( keys %{ $self->{'data'} } );
}

sub p_value_for_rsID {
	my ( $self, $rs_id ) = @_;
	return undef unless ( defined $rs_id );
	return undef unless ( defined $self->{'data'}->{$rs_id} );
	return $self->{'data'}->{$rs_id}->{'p value'};
}

1;
