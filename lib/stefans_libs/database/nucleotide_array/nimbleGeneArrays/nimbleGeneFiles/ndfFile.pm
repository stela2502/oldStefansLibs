package ndfFile;

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

#use stefans_libs::database::nucleotide_array::oligoDB;
use stefans_libs::fastaDB;
use Archive::Zip;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile

=head1 DESCRIPTION

=head2 Depends on

L<::root>

=head2 Provides

L<AddData|"AddData">

L<GetAsFastaDB|"GetAsFastaDB">

L<WriteAsFastaDB|"WriteAsFastaDB">

=head1 METHODS

=head2 new

=head3 return value

Returns a object of the class ndfFile

=cut

sub new {

	my ( $class, $line, $what ) = @_;

	my ($self);

	$self = {
		important_positions => [],
		data                => fastaDB->new()
	};

	bless( $self, $class ) if ( $class eq "ndfFile" );
	return $self;
}

=head2 AddData

=head3 arguments

[0]: absolute location of a NimbleGene formated .ndf array design file

=head3 return value

a reference to a array of hashes where the values of the file are accessable by the column lable.
For a detailed description please refer to the NimbleGene DesignFile information.

=cut

sub AddData {
	my ( $self, $file ) = @_;

	my ( @line, $header, $notKnown, $unknown, $error );
	$unknown = 0;
	unless ( -f $file ) {
		warn ref($self),
		  ":AddData -> can not read the file '$file' no new data added!\n";
		return $self->{data};
	}
	if ( $file =~ m/^(.+)\.zip/ ){
		$unknown = $1;
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
	open( IN, "<$file" )
	  or die ref($self), "AddData: can not read the file '$file'\n$!\n";

	while (<IN>) {
		next if ( $_ =~ m/^#/ );
		chomp ( $_ );
		@line = split( "\t", $_ );

#		unless ( defined $header ) {
#			$header = 1;
#			next;
#		}

		unless ( defined @{ $self->{important_positions} }[0] ) {
			$error = '';
			## we have the first data line!!
			## first we search for the nucleotide ID
			for ( my $i = 0 ; $i < @line ; $i++ ) {
				next unless ( defined $line[$i] );
				if ( $line[$i] =~ m/(CHR\d+\w+\d+) *$/ ) {
					@{ $self->{important_positions} }[0] =
					  $i;    ## the position of the  PROBE_ID
				}
				elsif ( $line[$i] =~ m/^[ACGTN]+$/ ) {
					@{ $self->{important_positions} }[1] = $i;   ## the sequence
				}
			}
#			die "we got the first probe id and sequence ( "
#			  . $line[ @{ $self->{important_positions} }[0] ] . " ,"
#			  . $line[ @{ $self->{important_positions} }[1] ]
#			  . "\n";
			
			$error .=  ref($self).
			  ":AddData -> we did not find the oligo ID in line \n\t'".
			  join( "'; '", @line ). "'\n"
			  unless ( defined @{ $self->{important_positions} }[0] );
			$error .= ref($self).
			  ":AddData -> we did not find the oligo sequence in line \n\t'".
			  join( "'; '", @line ). "'\n"
			  unless ( defined @{ $self->{important_positions} }[1] );
			if ( $error =~ m/\w/){
				unless ( defined $header ){
					$header = $_;
					next;
				}
				else {
					Carp::confess($error);
				}
			}
		}
		if ( $line[ @{ $self->{important_positions} }[0] ] =~
			  m/(CHR[\d\w]+\w+\d+)$/ )
		  {
			  $line[ @{ $self->{important_positions} }[0] ] = $1;
			  $line[ @{ $self->{important_positions} }[1] ] = $1
				if ( $line[ @{ $self->{important_positions} }[1] ] =~
				  m/([ACGT]+)/ );
			  $self->{data}->addEntry(
				  $line[ @{ $self->{important_positions} }[0] ],
				  $line[ @{ $self->{important_positions} }[1] ]
			  );
		}
		else {
			  warn ref($self), ":AddData -> I could not parse ",
				join( "\t", @line ),
"\n$line[@{$self->{important_positions}}[0]] is not a nimblegene Sequence ID\n";
			  $notKnown->{ $line[ @{ $self->{important_positions} }[0] ] } = 1;
			  $unknown = 1;
		}
	}
	if ($unknown) {
		  print "please add a rule to handle these unknown oligo_names:\n";
		  foreach my $unknown_key ( keys %$notKnown ) {
			  print $unknown_key. "\n";
		  }
	}
	unlink("temp.data") if ( -f "temp.data");
	return $self->{data};
}

=head2 GetAsFastaDB

=head3 arguments

[0]: absolute location of a NimbleGene formated .ndf array design file

=head3 return value

returns a reference to a hash with the structure { OlgioID => Oligo_sequence }

=cut

sub GetAsFastaDB {
	  my ( $self, $inFile ) = @_;
	  return $self->AddData($inFile);
}

=head2 WriteAsFastaDB

=head3 arguments

[0]: absolute location of a NimbleGene formated .ndf array design file

[1]: absolute location of the fasta formated oligo database (new file)

=head3 return value

returns a reference to a hash with the structure { OlgioID => Oligo_sequence }

=cut

sub WriteAsFastaDB {
	  my ( $self, $inFile, $outFile ) = @_;
	  $self->GetAsFastaDB($inFile)->WriteAsFastaDB($outFile);
	  return 1;
}

sub printHead {
	  my ( $self, $file ) = @_;

	  my ( $data, $hash, $key );

	  $data = $self->AddData($file);
	  for ( my $i = 0 ; $i < 10 ; $i++ ) {
		  $hash = @$data[$i];
		  foreach $key ( sort keys %$hash ) {
			  print "$key -> $hash->{$key}\n";
		  }
	  }
	  return 1;
}

1;
