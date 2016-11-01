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
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::nimbleGeneFiles::ndfFile

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

   my ( $self, $root);

   $root = root->new();

   $self = {
     root => $root
   };

   bless ($self , $class ) if ( $class eq "ndfFile");
   return $self;
}

=head2 AddData

=head3 arguments

[0]: absolute location of a NimbleGene formated .ndf array design file

=head3 return value

a reference to a array of hashes where the values of the file are accessable by the column lable.
For a detailed description please refer to the NimbleGene DesignFile information.

=cut

sub  AddData{
  my ( $self, $file) = @_;

  my (@line, @config_line, $i, @data);
  open (IN, "<$file") or die $self->{root}->FileError($file);

  while (<IN>){
    chomp $_;
    @line = split ("\t", $_);
    unless ( defined $config_line[0]){
#      print "Config Line : $_\n";
      @config_line = @line;
      next;
    }
    my $hash;
    for ($i = 0; $i<@line; $i ++){
      $hash->{$config_line[$i]} = $line[$i];
    }
    push (@data, $hash);
  }
  return \@data;
}

=head2 GetAsFastaDB

=head3 arguments

[0]: absolute location of a NimbleGene formated .ndf array design file

=head3 return value

returns a reference to a hash with the structure { OlgioID => Oligo_sequence }

=cut

sub GetAsFastaDB {
  my ( $self, $inFile) = @_;

  my ( $data, $hash, $return);
  $data = $self->AddData($inFile);
  foreach $hash (@$data){
     $return -> {$hash->{PROBE_ID}} = $hash->{PROBE_SEQUENCE} if ($hash->{PROBE_CLASS} =~ m/experimental/ || $hash->{PROBE_CLASS} eq "" );
  }
  return $return;
}

=head2 WriteAsFastaDB

=head3 arguments

[0]: absolute location of a NimbleGene formated .ndf array design file

[1]: absolute location of the fasta formated oligo database (new file)

=head3 return value

returns a reference to a hash with the structure { OlgioID => Oligo_sequence }

=cut

sub WriteAsFastaDB{
  my ( $self, $inFile, $outFile ) = @_;

  my ( $data, $OligoID);
  open (OUT, ">$outFile") or die $self->{root}->FileError("outfile $outFile");
  $data = $self->GetAsFastaDB($inFile);

  foreach $OligoID (keys %$data){
     print OUT ">$OligoID\n$data->{$OligoID}\n";
  }
  close (OUT);
  return $data;
}

sub printHead {
  my ( $self, $file) = @_;

  my ( $data, $hash, $key);

  $data = $self->AddData($file);
  for ( my $i = 0; $i < 10; $i++){
    $hash = @$data[$i];
    foreach $key ( sort keys %$hash){
        print "$key -> $hash->{$key}\n";
    }
  }
  return 1;
}

1;
