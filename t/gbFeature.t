#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 5;
BEGIN { use_ok 'stefans_libs::gbFile::gbFeature' }
## test for new
my ( $value, @values);
my $gbFeature = gbFeature ->new( "nix", "0..100");
my $gbFeature_string = 
'     source          1..86563
                     /db_xref="taxon:9606"
                     /mol_type="genomic DNA"
                     /chromosome="Y"
                     /organism="Homo sapiens"
                     /note="median probability for a nucleosome over this
                     region = 0.413"';
                     
$gbFeature->parseFromString($gbFeature_string);
$value = $gbFeature->getAsGB();
$gbFeature_string = 
'     source          1..86563
                     /mol_type="genomic DNA"
                     /db_xref="taxon:9606"
                     /chromosome="Y"
                     /organism="Homo sapiens"
                     /note="median probability for a nucleosome over this
                     region = 0.413"
';

is_deeply ( $value , $gbFeature_string, "parse from String");
my $exp = 'mol_type , "genomic DNA"; db_xref , "taxon:9606"; chromosome , "Y"; organism , "Homo sapiens"; note , "median probability for a nucleosome over this region = 0.413"; ';
is_deeply($gbFeature->Info_AsString(), $exp, "Info_AsString");

$value = $gbFeature->selectValue_from_tag_str('db_xref', 'taxon:(\d+)' );
is_deeply( $value, 9606, "selectValue_from_tag_str");

$value = $gbFeature->selectValue_from_tag_str('note', 'median probability for a nucleosome over this region = ([\d\.]+)' );
is_deeply( $value, 0.413, "selectValue_from_tag_str using a multiline match");

