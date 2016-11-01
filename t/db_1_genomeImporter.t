#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use File::HomeDir;
BEGIN { use_ok 'stefans_libs::database::genomeDB::genomeImporter' }
my $home = File::HomeDir->my_home();
## test for new

#warn "we do not test the download capabilites of this lib - that would take too much time and bandwidth ;-)";

open( DB, ">$home/create_test.db" )
  or die "could not create file $home/create_test.db\n";
print DB "create database geneexpress;\n";
close(DB);
open( DB, ">$home/drop_test.db" )
  or die "could not drop file $home/create_test.db\n";
print DB "drop database geneexpress;\n";
close(DB);

#system("mysql -uroot -palmdiR < $home/drop_test.db");
#system("mysql -uroot -palmdiR < $home/create_test.db");

my ( $value, @values );

my $genomeImporter = genomeImporter->new("geneexpress");
is_deeply( ref($genomeImporter), 'genomeImporter',
	'simple test of function genomeImporter -> new()' );

$genomeImporter->{databaseDir} = "data"   if ( -d "data" );
$genomeImporter->{databaseDir} = "t/data" if ( -d "t/data" );

$genomeImporter->import_refSeq_genome_for_organism("hu_genome");

my $genomeDB        = genomeDB->new("geneexpress");

$genomeDB ->printReport();

my $chromsomesTable = $genomeDB->GetDatabaseInterface_for_Organism("hu_genome");

($value) = $chromsomesTable->ID( undef, 'Y', 1, 821 );

is_deeply( $value, [1], "we can access the genomesDB" );

 $value = $chromsomesTable->get_Columns( {
	'search_columns' => ['gbString']
	},
	{
		'start' => 1,
		'end' => 34821,
		'chromosome' => 'Y'
	}
);

is_deeply ( $value, ['     source          1..34821
                     /db_xref="taxon:9606"
                     /mol_type="genomic DNA"
                     /chromosome="Y"
                     /organism="Homo sapiens"
'] , "we can execute horribly complex searches using 'getArray_of_Array_for_search' ");


my $str = "substr( #1, #2, 5) ,#2, #3";

$value = $chromsomesTable->get_Columns({
	 'search_columns' =>[ 'gbFilesTable.seq', 'gbFeaturesTable.start', 'gbFeaturesTable.end' ],
	 'complex_select' => \$str
},
{	'tag' => 'gene', 'name' => "PLCXD1"}
  );

is_deeply ( $value , [['GTTTT', 48170 ,75199]], "we can get the first 5 bases at the start of the gene  'PLCXD1' from the mysql gbFiles table");

@values = ();
$chromsomesTable->init_getNext_gbFile();
print "we have started the gbFile iteration\n";
while ( 1 )  {
	$value = $chromsomesTable->getNext_gbFile();
	last unless ( defined $value);
	push ( @values, $value->Version());
	print "we got the next gbFile ".$value->Version()."\n";
}

is_deeply ( [ @values ], [ 'NT_113967.1', 'NT_113968.1', 'NT_113969.1' ] , "we can iterate through all gbFiles!!")


