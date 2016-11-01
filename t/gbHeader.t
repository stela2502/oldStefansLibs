#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::gbFile::gbHeader' }
## test for new
my ( $value, @values, $gbHeader);
$gbHeader = gbHeader->new();

## test for AddHeaderArray

my $header_str = ( "LOCUS       NT_113819             554624 bp    DNA     linear   CON 29-FEB-2008
DEFINITION  Homo sapiens chromosome Y genomic contig, reference assembly.
ACCESSION   NT_113819
VERSION     NT_113819.1  GI:89061331
KEYWORDS    .
SOURCE      Homo sapiens
  ORGANISM  Homo sapiens
            Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi;
            Mammalia; Eutheria; Primates; Catarrhini; Hominidae; Homo.
REFERENCE   1  (bases 1 to 554624)
  AUTHORS   International Human Genome Sequencing Consortium.
  TITLE     Finishing the euchromatic sequence of the human genome
  JOURNAL   Nature 431 (7011), 931-945 (2004)
   PUBMED   15496913
COMMENT     GENOME ANNOTATION REFSEQ:  Features on this sequence have been
            produced for build 36 version 3 of the NCBI's genome annotation
            [see documentation].
            The DNA sequence is part of the fourth release of the finished
            human reference genome. It was assembled from individual clone
            sequences by the Human Genome Sequencing Consortium in consultation
            with NCBI staff.
            Name: HsY_111538.
            COMPLETENESS: not full length.
");
@values = (split ("\n", $header_str));

$gbHeader -> AddHeaderArray (\@values );

## test for HeaderEntry

$value = $gbHeader->HeaderEntry ( "SOURCE" );

is_deeply ( $value , "Homo sapiens", "gbHeader HeaderEntry works for 'SOURCE'" );

$value = $gbHeader->HeaderEntry ( "VERSION" );

is_deeply ( $value , "NT_113819.1  GI:89061331", "gbHeader HeaderEntry works for 'VERSION'" );


$value = $gbHeader->HeaderEntry ( "AUTHORS" );

is_deeply ( $value , "International Human Genome Sequencing Consortium.", "gbHeader HeaderEntry works for 'AUTHORS'" );


$value = $gbHeader->HeaderEntry ( "ORGANISM" );

is_deeply ( $value , "Homo sapiens Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Primates; Catarrhini; Hominidae; Homo.", "gbHeader HeaderEntry works for 'ORGANISM'" );

## test for getAsGB

$value = $gbHeader->getAsGB (),

is_deeply ( $value , $header_str, "the genbank export");

## test for FormatAsGB

## test for FillStringWithSpaces

