package gbFileMerger;
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
use stefans_libs::chromosome_ripper::seq_contig;
use stefans_libs::gbFile;
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::chromosome_ripper::gbFileMerger

=head1 DESCRIPTION

This class is used to create the sequence files corresponding to the NimbleGene array design.
It uses the NimbleGene array design order file and a downloaded version of the NCBI genome version on which the array sdesign is based.

=head2 Depends on

L<::chromosome_ripper::seq_contig>,

L<::gbFile>,

L<::root>

=head2 Provides

L<Create_GBfiles|"Create_GBfiles">

=head1 METHODS

=head2 new

=head3 arguments

none

=head 3 return value

A new object of the class gbFileMerger.

=cut

sub new {

    my ($class) = @_;

    my ( $self, $seq_contig, $root );

    $seq_contig = seq_contig->new();
    $root       = root->new;

    $self = { 
       seq_contig => $seq_contig,
       root       => $root,
       test => ""
    };

    bless( $self, $class ) if ( $class eq "gbFileMerger" );
    return $self;
}

=head2 Create_GBfiles

This is the main method of the class gbFileMerger.

=head3 arguments

[0]: the NimbleGene design order file. It has to consist of lines like this:
"Chr[0-9]+:[0-9]+.[0-9]+[KM]*-[0-9]+.[0-9]+[KM]* ('filename MySQL entry for this chromosomal region')"
The filename must not contain '.' or any characters used by a command line shell.

[1]: the outpath where the sequences should be written to

[2]: the species string for this chromosomal assembly (i.e. C57BL/6J for the  Mus musculus strain C57BL/6J)

[3]: the NCBI genome build version

[4]: the local path of the NCBI chromosome data

=head3 Method

Foreach genomic region on the array the method L<stefans_libs::chromosome_ripper::seq_contig/"getContigsInRegion"> is called to get the
NCBI accession numbers of the sequences deinfining this genomic region. A new L<stefans_libs::gbFile> is created for every genomic region.

If such a genomic region consists only of one NCBI sequence file, the sequence file is extracted from the (uncompressed) NCBI genbank formated 
chromosome data. This genbank formated sequence file if inserted in a L<stefans_libs::gbFile> object and the object method
L<stefans_libs::gbFile/"WriteAsGB"> is used to clip the region of interest.

If there is more than one NCBI sequence file corresponding to the genomic region, each sequece is trimmed as beforementioned and these
trimmed sequences are merged together using this algorithm:

1. get trimmed features using L<stefans_libs::gbFile/"Features">. 
2. foreach feature adjust the location of that feature using L<stefans_libs::gbFile::gbFeatures/"ChangeRegion_Add"> with the sequence 
length of the newly created genbank formated file or 0 if this is the first trimmed sequence in this genoic region.
3. add these features to the newly created genabnk formated file and
4. add the trimmed sequence to the newly created genbank file using L<stefans_libs::gbFile/"AddSequence">.

The newly created sequence file is writted as I<outpath>/I<filename_in_brackets>.gb

=header3 retrun values

Reference to a array containing the absolute filenames of the newly created genbank files.
=cut

sub Create_GBfiles {
    my ( $self, $listFileOfGBregions, $outpath, $group_label, $build,
        $path2Chromosomes )
      = @_;
    die
"Create_GBfiles needs the list file of the wanted chromosomal regions, the outpath,\n",
      "the NCBIsequence group label, the NCBI genome build number and the path to the NCBI chromosome data!\n $listFileOfGBregions, $outpath, $group_label, $build, $path2Chromosomes\n"
      unless ( @_ == 6 );

    my (
        $chromosome,        $start,            $end,
        $name,              $region_entries,   $new_gbFile,
        $newEntrie,         $gbSequence_array, $gbID_array,
        $chromosome_string, $tempGBfile,       $new,
        $features,          @accs , $temp,     @fileList
    );

    my $tempDir = "/Mass/temp";
    system("mkdir -p /Mass/temp");

    open( gbRegionFile, "<$listFileOfGBregions" )
      or die "could not open listFileOfGBregions ($listFileOfGBregions)\n";
    while (<gbRegionFile>) {
        next if ( $_ =~ m/^#/ );
        if ( $_ =~ m/Chr(\d*):([\d,\.MKbp]*)-([\d,\.MKbp]*) \(([-\w\d]*)\)/ ) {
            ( $chromosome, $start, $end, $name ) = ( $1, $2, $3, $4 );

            print "Create_GBfiles for Chromosoal Region: Chr$chromosome, $start bp to $end bp, write as $name.gb\n" if ( defined $self->{test}); 

            $region_entries =
              $self->{seq_contig}
              ->getContigsInRegion( $chromosome, $start, $end, $group_label,
                $build );

            if ( defined $self->{test}){
            my $temp = @$region_entries;
            print "Got $temp different regions for file $name.gb\n";
            }
            $new_gbFile         = gbFile->new();
            $new_gbFile->{path} = $outpath;
            $new_gbFile->{name} = $name;
            @accs = undef;

            foreach $newEntrie (@$region_entries) {

                foreach my $temp (sort keys %$newEntrie){
                   print "$temp -> $newEntrie->{$temp}\n";
                }

                ## 1. type <Gap|NCBI Accession>
                if ( $newEntrie->{type} eq "GAP" ) {
                    print "Gap with length = $newEntrie->{'length'}\n" if ( defined $self->{test});
                    $new_gbFile->AddSequence(
                        $self->getN_Sequence( $newEntrie->{'length'} ) );
                    next;
                }
                else {
                    next unless ( $newEntrie->{type} =~ m/NT_\d*/ );
                    push ( @accs, "$newEntrie->{type} ($newEntrie->{start_old} to $newEntrie->{end_old})");
                    if ( $chromosome / 10 < 1 ) {
                        $chromosome_string = "0$chromosome";
                    }
                    else { $chromosome_string = $chromosome; }

                    ## den richtigen NCBI Eintrag aus dem Chromosom extrahieren
#                    print "GetMatchingFeaturesOfFlatFile\n$path2Chromosomes/CHR_$chromosome_string/mm_ref_chr$chromosome.gbk\n$newEntrie->{type}\n";

                    ( $gbSequence_array, $gbID_array ) =
                      $self->{root}->GetMatchingFeaturesOfFlatFile(
"$path2Chromosomes/CHR_$chromosome_string/mm_ref_chr$chromosome.gbk",
                        $newEntrie->{type}
                      );
#                    foreach my $temp (@$gbSequence_array){
#                      print "$temp\n";
#                    }


                    ## das Temporäre GB file schreiben
                    open( TEMP, ">$tempDir/temp.gb" )
                      or die "could not create $tempDir/temp.gb\n";
                    foreach my $line (@$gbSequence_array) {
                        print TEMP $line;
                    }
                    close(TEMP);

                    ## das temporäre GB file lesen
                    $tempGBfile = gbFile->new("$tempDir/temp.gb");
                    $new        = 0;

                    ## falls nur ein Teil der GB files benötigt wird ->beschneiden!
                    if ( $newEntrie->{start_old} > 0 ) {
                        $tempGBfile->WriteAsGB( "$tempDir/temp.gb",
                            $newEntrie->{start_old},
                            $newEntrie->{end_old} );
                        $new = 1;
                    }
                    if (   $newEntrie->{end_old} < $tempGBfile->Length()
                        && $new == 0 )
                    {
                        $tempGBfile->WriteAsGB( "$tempDir/temp.gb",
                            $newEntrie->{start_old},
                            $newEntrie->{end_old} );
                        $new = 1;
                    }
                    if ( $new == 1 ) {
                        $tempGBfile = gbFile->new("$tempDir/temp.gb");
                    }

                    ## die Features des 'alten' gb files in das neue übertragen!
                    my $features = $tempGBfile->Features();
                    $tempGBfile->WriteAsGB("./test.gb");
                    $temp = @$features;
                    print "$temp features in ./test.gb\n";
                    foreach my $feature ( @$features) {
                       $feature->ChangeRegion_Add($new_gbFile->Length);
                       $new_gbFile->Features($feature);
                    }
                    $new_gbFile->AddSequence($tempGBfile->{seq});
                    unless ( defined $new_gbFile->Header()){
                        $new_gbFile->Header("LOCUS", "$name");
                        $new_gbFile->Header("ACCESSION", "$name.1");
                        $new_gbFile->Header("DEFINITION", $tempGBfile->Header("DEFINITION"));
                        $new_gbFile->Header("SOURCE", $tempGBfile->Header("SOURCE"));
                        $new_gbFile->Header("  ORGANISM", $tempGBfile->Header("  ORGANISM"));
                    }
                }

            }
            my $acc = join("; ", @accs);
            my $string = 
  "created from the NCBI genome build $build from the sequences $acc with the NimbleGene Array evaluation program written by Stefan Lang";
            $new_gbFile->Header("COMMENT", $string);
            $new_gbFile->WriteAsGB("$outpath/$name.gb", "fixedPath");
            push(@fileList, "$outpath/$name.gb");
        }
        else {
            die
"line $_ did not match to Chr",'/Chr(\d*):([\d,\.MKbp]*)-([\d,\.MKbp]*) \(([-\w\d]*)\)/',"\n";
        }
    }
    return \@fileList;
}

sub getN_Sequence {
    my ( $self, $length ) = @_;
    my (@seq);
    for ( my $i = 0 ; $i < $length ; $i++ ) {
        $seq[$i] = "N";
    }
    return join( "", @seq );
}

1;
