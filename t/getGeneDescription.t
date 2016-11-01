#! /usr/bin/perl
 use strict;
 use warnings;
 use Test::More tests => 1;
 BEGIN { use_ok 'stefans_libs::database::genomeDB::gene_description' };
 
 my ( $test_object, $value, $exp, @values, $temp_sav );
 $test_object = gene_description->new();
 is_deeply ( ref($test_object), 'gene_description', 'got the right object');
 
 $value = $test_object->_get_gene_description_from_genecards('RAG1');
 
 print root::get_hashEntries_as_string( $value, 3, 'the restur values for the gene RAG1');
 
is_deeply ($value->{'RefSeq_desc'} =~m/no information/, 0, 'we get RefSeq information' );
is_deeply ($value->{'Swiss_Prot_desc'} =~m/no information/, 0, 'we get RefSeq information' );

print "if the last two checks were not ok please check the web page '". $test_object->get_href_for_gene('RAG1')."'\n";
 