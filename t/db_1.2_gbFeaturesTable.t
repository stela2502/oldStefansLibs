#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
use stefans_libs::root;
BEGIN { use_ok 'stefans_libs::database::genomeDB::gbFeaturesTable' }
use stefans_libs::database::genomeDB::gbFilesTable;

my $gbFeaturesTable =
  gbFeaturesTable->new( root::getDBH( 'root', "geneexpress" ) );
is_deeply( ref($gbFeaturesTable), 'gbFeaturesTable',
	'simple test of function gbFeaturesTable -> new()' );

## test for new

my ( $value, @values, $gbFeature, $gbFeature_str );

## test for new

## test for TableName

$value = $gbFeaturesTable->TableName("make.a.test");

is_deeply( $value, "make_a_test_gbFeaturesTable",
	"table base name is created correctly" );

$value = $gbFeaturesTable->create();

root::print_hashEntries( $gbFeaturesTable->_getLinkageInfo(),
	10, "the linkage info of " . ref($gbFeaturesTable) );

print "we got a SQL query(!):\n\t'",
  $gbFeaturesTable->create_SQL_statement(
  {
	'search_columns' => [ 'seq', 'chromosome', 'gbString' ],
	'where' => [
		['tag', '=', 'gene'],
		['name', '=','TCF7L2' ]
	]
  }),
  "\n";

is_deeply( $value, 1, "create a gbFeatures table" );

$gbFeature_str =
  '     CDS             complement(join(76920..77043,79206..79358,79578..79726,
                     83265..83473,84612..84770,85996..>86066))
                     /db_xref="GI:6912588"
                     /db_xref="GeneID:8225"
                     /db_xref="HGNC:30189"
                     /db_xref="MIM:300124"
                     /protein_id="NP_036359.1"
                     /exception="unclassified translation discrepancy"
                     /gene="GTPBP6"
                     /product="pseudoautosomal GTP-binding protein-like
                     protein"
                     /GO_function="GTP binding [GO ID 0005525] [Evidence TAS]
                     [PMID 9466997]"
                     /GO_component="intracellular [GO ID 0005622] [Evidence
                     IEA]"
                     /note="pseudoautosomal GTP-binding protein-like;
                     pseudoautosomal GTP binding protein-like"';

$gbFeature = gbFeature->new( "nix", "1..100" );
$gbFeature->parseFromString($gbFeature_str);

$gbFeaturesTable->AddDataset(
	{ 'gbFile' => { 'id' => 1 }, 'gbFeature' => $gbFeature } );

my $name = $gbFeature->Name();
if ( defined $name ) {
	$name =~ s/"//g;
}
$value =
  $gbFeaturesTable->get_gbFeatures( { 'tag' =>$gbFeature->Tag, 'name' =>  $name} );
@{$gbFeature -> {information}->{gene}}[0] = '"GTPBP6"';
is_deeply(
	$value,
	[ $gbFeature  ],
	"get_gbFeatures"
);

my $secondFeature_str =
  '     mRNA            complement(85996..>86066)
                     /db_xref="GI:6912587"
                     /db_xref="GeneID:8225"
                     /db_xref="HGNC:30189"
                     /db_xref="MIM:300124"
                     /exception="unclassified transcription discrepancy"
                     /gene="HUGO"
                     /product="GTP binding protein 6 (putative)"
                     /transcript_id="NM_012227.1"
                     /note="Derived by automated computational analysis using
                     gene prediction method: BestRefseq. Supporting evidence
                     includes similarity to: 1 mRNA"

';
my $secondGbFeature = gbFeature->new( "nix", "1..100" );
$secondGbFeature->parseFromString($secondFeature_str);

$gbFeaturesTable->AddDataset( { 'gbFile' => { 'id' => 1 }, 'gbFeature' => $secondGbFeature } );

$value = $gbFeaturesTable->get_gbFeatures( { 'gbFile_id' => 1} );
@{$secondGbFeature-> {information}->{gene}}[0] = '"HUGO"';
is_deeply( $value, [ $gbFeature, $secondGbFeature ],
	"get_gbFeatures_for_gbFileID" );
	
$value = $gbFeaturesTable->get_gbFile_for_gbFile_id( 1 );

is_deeply( $value->Version(), 'NT_113968.1', "got the right gbfile");

