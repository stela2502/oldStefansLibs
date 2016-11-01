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
use stefans_libs::NimbleGene_config;
use stefans_libs::database::oligo2dnaDB;
use stefans_libs::nimbleGeneFiles::enrichedRegions;

#use stefans_libs::database::fileDB;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::nimbleGeneFiles::gffFile

=head1 DESCRIPTION

=head2 Depends on

none

=head2 Provides

L<GetData|"GetData">

=head1 METHODS

=cut

sub new {

	my ($class) = @_;

	my ( $self, %data );

	$self = { 
		data => \%data,
		#debug => 1==1
	};

	bless( $self, $class ) if ( $class eq "gffFile" );
	return $self;
}

sub writeData {

	my ( $self, $hash, $filename ) = @_;

	open( OUT, ">$filename" )
	  or die "Konnte Filename $filename nicht anlegen!\n";

	while ( my ( $oligoID, $GFFvalue ) = each %$hash ) {
		print OUT "-\t-\t-\t-\t-\t$GFFvalue\t-\t-\t$oligoID\n";
	}
	close(OUT);

	print "GFF Data written to $filename\n";
}

sub GetData_HMM {
	my ( $self, $file, $what, $antibody, $celltype, $organism, $designID ) = @_;
	my (
		@line, $insert, $return
	);

	open (DATA , "<$file") or die "could not open '$file' at gffFile->GetData_HMM\n";
	while ( <DATA>){
		next if ( $_ =~ m/^#/);
		@line = split("\t", $_);
		unless ( defined $return->{$line[0]}){
			my @temp;
			$return->{$line[0]} = \@temp;
			$insert = \@temp;
		}
		push (@$insert, {start => $line[3], end => $line[4], value => $line[5]});
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

	my ( @line, $data, $oligoID, $value, $chromosomalRegion, $temp, $line );
	return $self->{data}->{"$file$what"}
	  if ( defined $self->{data}->{"$file$what"} );

	open( IN, "<$file" ) or die "Konnte File $file nicht oeffnen!\n";

	$line = 0;

	#print "\n\tDEBUG: $self identifer = $file$what\n\n";
	unless ( defined $what ) {
		print "GFF data set is converted into a hash { OligoID => value }\n";
		while (<IN>) {
			next if ( $_ =~ m/^#/ );
			chomp $_;
			@line    = split( "\t", $_ );
			$oligoID = $line[8];
			$value   = $line[5];
			$line++;
			unless ( $oligoID =~ m/(CHR\d+[PR]\d+)/ ) {
				print "$file line $line stimmt was nicht! $oligoID -> $value\n";
				next;
			}
			$oligoID = $1;
			$data->{$oligoID} = $value;
		}
	}
	elsif ( $what eq "position" ) {
		print "GFF data set is converted into a hash\n";
		my (@data);
		$temp = 0;
		if ( (<IN>)[0] =~ m/^Sequence/ ) {
			##oh-oh hier kommt ein nucleosome positioning File!!
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
		else {

			while (<IN>) {
				#print $_;
				next if ( $_ =~ m/^#/ );
				chomp $_;
				
				@line = split( "\t", $_ );
				$oligoID = $line[8];
				unless ( $oligoID =~ m/(CHR\d+[PR]\d+)/ ) {
					print
"hier stimmt was nicht (Zeile $temp)! $oligoID -> $value\n";
					next;
				}
				$oligoID = $1;

				my $hash = {
					oligoID  => $oligoID,
					filename => $line[0],
					start    => $line[3],
					end      => $line[4],
					value    => $line[5]
				};
				push( @data, $hash );
				$temp++;
			}
			print "$temp oligos in file $file\n";
			$data = \@data;
		}
	}
	$self->{data}->{"$file$what"} = $data;
	return $self->{data}->{"$file$what"};
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
	if ($self->{debug} ){
		warn "\nwe do not use the saved region Informations!\nset the \$self->{debug} value to false\n";
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

	print
"DEBUG $self->getEnrichedRegions start reads the original data.\n";
	#$GFFdata = $self->GetData ( $gffFilename, "position");
	$GFFdata = $self->GetData_HMM(
		$gffFilename
	);

	print "GetData_HMM returned with $GFFdata\n";
	#root::print_hashEntries($GFFdata, 3);

	foreach my $filename (keys %$GFFdata){
		$data = $GFFdata->{$filename};
		my @data;
		$return->{ $filename } = \@data;
		$enrichmentData = \@data;
		foreach $dataHash (@$data){
			if ( $dataHash->{value} >= $cut && defined ( $start) ) {
				if ( $dataHash->{start} < $end + $D0){
					$end = $dataHash->{end};
				}
				else{
					if ( $end - $start > $D0){
						push (@$enrichmentData, gbFeature->new( "enriched", "$start..$end" ) );
					}
					$start = $end = undef;
				}
			}
			if ( $dataHash->{value} >= $cut && ! defined ( $start) ){
				$start    = $dataHash->{start};
				$end      = $dataHash->{end};
			}
			
		}
	}
	$self->writeEnrichedRegions( $gffFilename, $return ) unless ( $self->{debug});
	return enrichedRegions->new($return);
	return $return;
	
}

1;
