package gffFile;

#  Copyright (C) 2008 Stefan Lang

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
use stefans_libs::root;
use Archive::Zip;

#use stefans_libs::NimbleGene_config;

use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use
  stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::enrichedRegions;

#use stefans_libs::database_old::fileDB;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile

=head1 DESCRIPTION

=head2 Depends on

none

=head2 Provides

L<GetData|"GetData">

=head1 METHODS

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ( $self, %data );

	$self = {
		data  => \%data,
		debug => $debug
	};

	bless( $self, $class ) if ( $class eq "gffFile" );
	return $self;
}

sub expected_dbh_type {

	#return 'dbh';
	return "not a databse interface";

	#return "database_name";
}

sub writeData {

	my ( $self, $hash, $filename ) = @_;

	open( OUT, ">$filename" )
	  or die "Konnte Filename $filename nicht anlegen!\n";
	if ( ref($hash) eq "HASH" ) {
		while ( my ( $oligoID, $GFFvalue ) = each %$hash ) {
			print OUT "-\t-\t-\t-\t-\t$GFFvalue\t-\t-\t$oligoID\n";
		}
	}
	elsif (( ref($hash) eq "ARRAY" )
		&& ( ref( @$hash[0] ) eq "HASH" )
		&& ( scalar( keys %{ @$hash[0] } ) == 6 ) )
	{
		## we want to export a NEW dataset using an old data structure
		my $line;
		unless ( defined $self->{'data_handler'} ) {
			warn ref($self)
			  . ":writeData -> you could have changed the reported data type (\$self->{'data_handler'})\n";
			$self->{'data_handler'} = 'NimbleScan';
		}
		unless ( $self->{'data_handler'} =~ m/\w/ ) {
			warn ref($self)
			  . ":writeData -> you could have changed the reported data type (\$self->{'data_handler'})\n";
			$self->{'data_handler'} = 'NimbleScan';
		}
		unless ( defined $self->{'data_label'} ) {
			warn ref($self)
			  . ":writeData -> you could have changed the data lable that is displayed by SignalMap by setting \$self->{'data_label'}\n";
			$self->{'data_label'} = "exported_to_$filename";
		}

		foreach $line (@$hash) {
			print OUT
"$line->{'chromosome'}\t$self->{'data_handler'}\t$self->{'data_label'}\t"
			  . "$line->{'start'}\t$line->{'end'}\t$line->{'value'}\t-\t-\t$line->{'description'}\n";
		}
	}
	close(OUT);

	print "GFF Data written to $filename\n";
}

sub GetData_HMM {
	my ( $self, $file, $what, $antibody, $celltype, $organism, $designID ) = @_;
	my ( @line, $insert, $return );

	open( DATA, "<$file" )
	  or die "could not open '$file' at gffFile->GetData_HMM\n";
	while (<DATA>) {
		next if ( $_ =~ m/^#/ );
		@line = split( "\t", $_ );
		unless ( defined $return->{ $line[0] } ) {
			my @temp;
			$return->{ $line[0] } = \@temp;
			$insert = \@temp;
		}
		push( @$insert,
			{ start => $line[3], end => $line[4], value => $line[5] } );
	}
	return $return;
}

sub GetNuclData {
	my ( $self, $file, $listOfRegions ) = @_;
	my ( $number, $actualList, @data, @line );
	open( IN, "<$file" ) or die "Konnte NuclData-File $file nicht oeffnen!\n";
	$actualList = 0;
	while (<IN>) {
		chomp $_;
		@line = split( "\t", $_ );
		next if ( $line[0] =~ m/Sequence/ );
		for ( $actualList = 0 ; $actualList < @$listOfRegions ; $actualList++ )
		{
			if (   $line[1] < @$listOfRegions[$actualList]->{end}
				&& $line[1] > @$listOfRegions[$actualList]->{start} )
			{
				$number++;
				$data[ $line[1] ] = {
					P_start    => $line[2],
					P_occupied => $line[3]
				};
			}
		}
	}
	print "$number of bp values returning\n";
	return \@data;
}

=head2 GetData

=head3 arguments

[0]: the absolute position of the NimbleGene pair file

[1]: either the undefined value or 'position'

=head3 return values

There are two possibilities depending on the argument[1]: (1) argument[1] is not defined:
a reference to a hash with the structure of {oligoID => value}; (2) argument[1] equals 'position':
a reference to a array of hashes with the structure [ { oligoID => oligoID , filename => name of the chromosomal region , 
start => start in bp on this chromosomal region, end => end in bp on this chromosomal region, value => value} ]
as they occure in the gff file.
=cut

sub GetData {
	my ( $self, $file, $what ) = @_;

	my ( @line, $data, $oligoID, $value, $chromosomalRegion, $temp, $line, $unknown);
	return $self->{data}->{"$file$what"}
	  if ( defined $self->{data}->{"$file$what"} );
	if ( $file =~ m/^(.+)\.zip/ ){
		$unknown = $1;
		$unknown = $1;
		@line = split( "/",$unknown);
		$unknown = $line[@line-1];
		warn "we hope, that we find an Dataset using the member '$unknown'\n";
		my $zipFile = Archive::Zip->new();
		unless ($zipFile ->read( $file ) == 0){
			Carp::confess( ref($self)."::AddData -> we can not read from the ZIP file $file\n");
		}
		open ( OUT, ">temp.data") or die "we could not craete a temp file to hold the unzipped data!\n";
		print OUT $zipFile->contents( $unknown );
		close (OUT);
		$zipFile = undef;
		$unknown = undef;
		$file = "temp.data";
	}

	open( IN, "<$file" ) or die "Konnte File $file nicht oeffnen!\n";

	$line = 0;

	print "\n\tDEBUG: $self identifer = $file$what\nusing file '$file'\n"; #if ( $self->{debug});
	unless ( defined $what ) {
		print "GFF data set is converted into a hash { OligoID => value }\n";
		while (<IN>) {
			next if ( $_ =~ m/^#/ );
			chomp $_;
			@line    = split( "\t", $_ );
			$oligoID = $line[8];
			$value   = $line[5];
			$line++;
			if ( $oligoID =~ m/(CHR[\d\w]+\d+)/ ){
				$oligoID = $1;
			}
			else
			{
				print "$file line $line stimmt was nicht! $oligoID -> $value\n";
				next;
			}
			$data->{$oligoID} = $value;
		}
	}
	
	elsif ( $what eq "preserve_structure_new" ) {
		my (@data);
		$temp = 0;
		print "GFF data set is converted into an array (NimbleGene GFF file)\n";
		while (<IN>) {
			#print $_;
			next if ( $_ =~ m/^#/ );
			chomp $_;
			@line = split( "\t", $_ );
			next if ( scalar(@line) < 8);
			$data[$temp++] = [@line];
		}
		$data = \@data;
	}
	
	elsif ( $what eq "preserve_structure" ) {
		
		my (@data);
		$temp = 0;
			print "GFF data set is converted into an array (NimbleGene GFF file)\n";
			while (<IN>) {
				#print $_;
				next if ( $_ =~ m/^#/ );
				chomp $_;

				@line = split( "\t", $_ );
				$oligoID = $line[8];
				unless ( $oligoID =~ m/(CHR[\d\w]+\d+)/ ) {
					warn ref($self).
"::GetData ->hier stimmt was nicht (Zeile $temp)! $oligoID -> $value\n";
					next;
				}
				$oligoID = $1;
				#print "we got the oligo id $oligoID\n";
				my $hash = {
					chromosome  => $line[0],
					oligoID     => $oligoID,
					start       => $line[3],
					end         => $line[4],
					value       => $line[5],
					description => $line[8]
				};
				push( @data, $hash );
				$temp++;
			}
			print "$temp oligos in file $file\n";
			$data = \@data;
	}
	elsif ( $what eq "position"  ){
		my (@data);
		if ( (<IN>)[0] =~ m/^Sequence/ ) {
			##oh-oh hier kommt ein nucleosome positioning File!!
			print "GFF data set is converted into an array (nucleosome positioning File)\n";
			while (<IN>) {
				chomp $_;
				print "$_\n";
				@line = split( "\t", $_ );
				next if ( $line[0] eq "Sequence" );

				my $hash = {
					oligoID    => undef,
					filename   => "mergedIg_H_locus",
					start      => $line[1],
					end        => $line[1],
					P_start    => $line[2],
					P_occupied => $line[3]
				};

				push( @data, $hash );

			}
			$self->{data}->{"$file$what"} = \@data;
			return $data;
		}
		
	}
	unlink("temp.data") if ( -f "temp.data");
	$self->{data}->{"$file$what"} = $data;
	$self->{'last_dataset'} = "$file$what";
	return $self->{data}->{"$file$what"};
}

sub getLastDataset{
	my ( $self) = @_;
	return $self->{'data'}->{$self->{'last_dataset'}};
}

sub ClearData {
	my ($self) = @_;
	$self->{data} = undef;
	my %temp;
	$self->{data} = \%temp;
	return 1;
}

sub readEnrichedRegions {
	my ( $self, $gffFilename, $cutoff ) = @_;
	my ( $path, $d0, $fileInfo, $data, $gbFile, $start, $end, $insertPoint );

	$path     = NimbleGene_config::DataPath();
	$cutoff   = $self->CutoffValue unless ( defined $cutoff );
	$d0       = $self->D0;
	$path     = "$path/Save/$cutoff/$d0/";
	$fileInfo = root->ParseHMM_filename($gffFilename);

	if ( open( Data, "<$path/$fileInfo->{filename}" ) ) {
		print
"gffFile: readEnrichedRegions reads from :\n$path/$fileInfo->{filename}\n";
		while (<Data>) {
			next if ( $_ =~ m/^#/ );
			( $gbFile, $start, $end ) = split( "\t", $_ );
			next unless ( defined $end );
			unless ( defined $data->{$gbFile} ) {
				my @array;
				$insertPoint = $data->{$gbFile} = \@array;
			}
			push( @$insertPoint, gbFeature->new( "enriched", "$start..$end" ) );
		}
		close(Data);
		$data->{info} = $fileInfo;
		return enrichedRegions->new($data);
	}
	return undef;
}

sub writeEnrichedRegions {
	my ( $self, $gffFilename, $data ) = @_;
	my ( $path, $cutoff, $d0, $fileInfo, $gbFile, $start, $end );
	$path   = NimbleGene_config::DataPath();
	$cutoff = $self->CutoffValue;
	$d0     = $self->D0;
	$path   = "$path/Save/$cutoff/$d0/";
	root->CreatePath($path);
	$fileInfo = root->ParseHMM_filename($gffFilename);
	open( OUT, ">$path/$fileInfo->{filename}" )
	  or die
"gffFile writeEnrichedRegions: Konnte $path/$fileInfo->{filename} nicht anlegen!\n";

	while ( my ( $gbFile, $value ) = each %$data ) {
		next if ( $gbFile eq "info" );
		foreach my $gbFeature (@$value) {
			next unless ( $gbFeature =~ m/gbFeature/ );
			( $start, $end ) = ( $gbFeature->Start(), $gbFeature->End );
			print OUT "$gbFile\t$start\t$end\n";
		}
	}
	close(OUT);
	return 1;
}

sub D0 {
	my ( $self, $d0 ) = @_;
	$self->{d0} = NimbleGene_config::D0 unless ( defined $self->{d0} );
	$self->{d0} = $d0 if ( defined $d0 );
	return $self->{d0};
}

sub CutoffValue {
	my ( $self, $cutoffValue ) = @_;

	if ( defined $cutoffValue ) {
		$self->{cutoffValue} = $cutoffValue;
	}
	$self->{cutoffValue} = NimbleGene_config::CutoffValue()
	  if ( !( defined $self->{cutoffValue} ) || $cutoffValue < -4 );

	return $self->{cutoffValue};
}

sub getEnrichedRegions {
	my ( $self, $gffFilename, $cutoff ) = @_;
	my (
		@differences, $last,     $add,      $fileInfo,
		$GFFdata,     $dataHash, $filename, $start,
		$end,         $return,   $data,     $myFilename,
		$i,           $path,     $d0,       $resultIterator,
		$enrichmentData
	);

#  ($myFilename, $data) = $self->{gbFile}->getPureSequenceName()
#     or die "You have to set the gbFilename using ->AddGbFile() befor adding HMM file data!\n";

	$data = $self->readEnrichedRegions( $gffFilename, $cutoff );
	if ( $self->{debug} ) {
		warn
"\nwe do not use the saved region Informations!\nset the \$self->{debug} value to false\n";
		$data = undef;
	}

	if ( defined $data ) {
		$data->{info} = root->ParseHMM_filename($gffFilename);
		return $data;
	}
	print "\nNo saved Data was found! Calculating new data set\n\n";

	my ( $D0, $cut );
	$D0  = $self->D0;
	$cut = $self->CutoffValue($cutoff);

	print
"DEBUG $self->getEnrichedRegions searches for regions larger than $D0 bp and min p_enriched = $cut\n";
	$return->{info} = root->ParseHMM_filename($gffFilename);

	print "DEBUG $self->getEnrichedRegions start reads the original data.\n";

	#$GFFdata = $self->GetData ( $gffFilename, "position");
	$GFFdata = $self->GetData_HMM($gffFilename);

	print "GetData_HMM returned with $GFFdata\n";

	#root::print_hashEntries($GFFdata, 3);

	foreach my $filename ( keys %$GFFdata ) {
		$data = $GFFdata->{$filename};
		my @data;
		$return->{$filename} = \@data;
		$enrichmentData = \@data;
		foreach $dataHash (@$data) {
			if ( $dataHash->{value} >= $cut && defined($start) ) {
				if ( $dataHash->{start} < $end + $D0 ) {
					$end = $dataHash->{end};
				}
				else {
					if ( $end - $start > $D0 ) {
						push( @$enrichmentData,
							gbFeature->new( "enriched", "$start..$end" ) );
					}
					$start = $end = undef;
				}
			}
			if ( $dataHash->{value} >= $cut && !defined($start) ) {
				$start = $dataHash->{start};
				$end   = $dataHash->{end};
			}

		}
	}
	$self->writeEnrichedRegions( $gffFilename, $return )
	  unless ( $self->{debug} );
	return enrichedRegions->new($return);
	return $return;

}

1;
