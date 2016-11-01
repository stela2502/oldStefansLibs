#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;
use stefans_libs::database::materials::materialsTable;
BEGIN { use_ok 'stefans_libs::database::materials::materialList' }


my $dbh = root::getDBH('root', 'geneexpress' );

my ( $value, $values, $expected );

my $materialList = materialList -> new($dbh, 0);
$materialList ->create();
$materialList->{'data_handler'}->{'otherTable'}->create();

is_deeply ( ref($materialList) , 'materialList', 'simple test of function materialList -> new()' );

## OK first we need to add some materials...
my $materialsTable = materialsTable->new ($dbh, 0 );
is_deeply ( ref($materialsTable) , 'materialsTable', 'simple test of function materialsTable -> new()' );

## we should have by now two data entries in the storages table - so simply take the first one

$value = $materialsTable -> AddDataset ( {
'company' => "No ones land",
'OrderNumber' => "#1",
'LotNumber' => "#1",
'type' => "test",
'name' => "toilet",
'orderDate' => undef,
'storage' => {
	'temperature' => -20,
	'building' => 60,
	'floor' => 13,
	'room' => 60,
	'box_label' => 'my box',
	'description' => 'nothing special'
},
'description' => "the first test component"
});

is_deeply ($value, 1, "we could insert one dataset into materialsTable\n");

$value = $materialsTable -> AddDataset ( {
'company' => "No ones land",
'OrderNumber' => "#2",
'LotNumber' => "#1",
'type' => "test_2",
'name' => "spoon",
'storage_id' => 1,
'storage' => {
'id' => 1
},
'description' => "the second test component"
});

is_deeply ($value, 2, "we could insert a second dataset into materialsTable\n");

$value = $materialsTable -> AddDataset ( {
'company' => "No ones land",
'OrderNumber' => "#2",
'LotNumber' => "#1",
'type' => "test_2",
'name' => "spoon",
'storage_id' => 1,
'storage' => {
'id' => 1
},
'description' => "the second test component"
});

is_deeply ($value, 2, "we could insert a second dataset into materialsTable\n");

$value = $materialsTable -> AddDataset ( {
'company' => "No ones land",
'OrderNumber' => "#3",
'LotNumber' => "#1",
'type' => "test_3",
'name' => "spoon",
'storage_id' => 1,
'storage' => {
'id' => 1
},
'description' => "the third test component"
});

is_deeply ($value, 3, "we could insert a third dataset into materialsTable\n");

$value = $materialList -> AddDataset ( {
	'others_id' => [1,2]
});

is_deeply ( $value, 1, "we got the list_id $value and expected the list_id to be '1'");

$value = $materialList -> AddDataset ( {
	'others_id' => [2,1]
});

is_deeply ( $value, 1, "we got the list_id $value and expected the list_id to be '1'");

$value = $materialList -> AddDataset ( {
	'others_id' => [3,2]
});

unless (is_deeply ( $value, 2, "we got the list_id $value and expected the list_id to be '2'")){
	warn "the last serach was:\n$materialList->{'complex_search'}\n";
}

$value = $materialList -> AddDataset ( {
	'others_id' => [1,2,3]
});

is_deeply ( $value, 3, "we can not create problems by adding the same list twice!");

$value = $materialList -> getArray_of_Array_for_search ( {
	'search_columns' => [ 'materialsTable.name', 'materialList.list_id'],
	'where' => [['materialsTable.OrderNumber', '=', 'my_value']]
},
"#2"
);

$expected = [ [ 'spoon',1 ],['spoon',2], ['spoon',3]];
unless (is_deeply ( $value, $expected, "and we can search that construct!")){
	print "we executes the query $materialList->{'complex_search'}\n";
	print root::get_hashEntries_as_string ($expected, 4, " we expected");
	print root::get_hashEntries_as_string ( $value , 4, " but we got that");
};



## test for new


