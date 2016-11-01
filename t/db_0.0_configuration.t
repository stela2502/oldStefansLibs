#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::database::system_tables::configuration' }

my $configuration = configuration->new('geneexpress');
$configuration->create();
is_deeply( ref($configuration), 'configuration',
	'simple test of function configuration -> new()' );

## test for new
my ( $value, @values);

my $data = {
	'systems_table' => 'TEST_TABLE',
	'database'      => 'genomeDB'
};
my $i = 0;
while ( my ( $tag, $this_value ) = each %$data ) {
	$value = $configuration->AddDataset( { 'tag' => $tag, 'value' => $this_value } );
	$i ++;
	is_deeply( $value, $i ,"we have added a value!");
	is_deeply( $configuration->GetConfigurationValue_for_tag($tag),
		$this_value, "add the tag $tag with the value $this_value" );
}

