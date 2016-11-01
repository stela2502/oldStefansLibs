#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok 'stefans_libs::database::variable_table';
}

BEGIN {
	use_ok 'stefans_libs::database::lists::list_using_table';
}

BEGIN {
	use_ok 'stefans_libs::database::lists::basic_list';
}

my ( $table1, $table2, $table_3, $list_link, $value, $temp, $exp, $dbh );

$dbh = root::getDBH();

$table_3                       = variable_table->new();
$table_3->{'_tableName'}       = 'test_organism';
$table_3->{'table_definition'} = {
	'table_name' => 'test_organism',
	'variables'  => [
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	]
};
$table_3->{'UNIQUE_KEY'} = ['name'];
$table_3->{'INDICES'}    = ['name'];
$table_3->{'dbh'}        = $dbh;
$table_3->create();

$table1                       = list_using_table->new(1);
$table1->{'_tableName'}       = 'test_master';
$table1->{'table_definition'} = {
	'table_name' => 'test_master',
	'variables'  => [
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		},
		{
			'name'        => 'time',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
		},
		{
			'name'         => 'list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'link_to'      => 'list_id',
			'data_handler' => 'list',
		},
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR(32)',
			'NULL'        => '0',
			'description' => ''
		}
	]
};
$table1->{'Group_to_MD5_hash'} = ['name'];
$table1->{'UNIQUE_KEY'}        = ['md5_sum'];
$table1->{'INDICES'}           = ['name'];
$table1->{'dbh'}               = $dbh;
$table1->create();

$table2                       = variable_table->new();
$table2->{'_tableName'}       = 'test_slave';
$table2->{'table_definition'} = {
	'table_name' => 'test_slave',
	'variables'  => [
		{
			'name'        => 'other_name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		},
		{
			'name'         => 'organism_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'organism',
		}
	]
};

$table2->{'UNIQUE_KEY'} = ['other_name'];
$table2->{'INDICES'}    = ['name'];
$table2->{'dbh'}        = $dbh;
$table2->create();

$list_link                    = basic_list->new(1);
$list_link->{'dbh'}           = $table2->{'dbh'};
$list_link->{'my_table_name'} = 'test_list';
$list_link->{'dbh'}           = $dbh;
$list_link->init_tableStructure();

$table1->{'linked_list'} = $table1->{'data_handler'}->{'list'} = $list_link;
$table2->{'data_handler'}->{'organism'}      = $table_3;
$list_link->{'data_handler'}->{'otherTable'} = $table2;
$list_link->{'__actualID'}                   = $list_link->readLatestID();

is_deeply(
	$table1->AddDataset(
		{
			'name' => 'test',
			'list' => [
				{
					'other_name' => 'hugo',
					'organism'   => { 'name' => 'from outer space' }
				},
				{
					'other_name' => 'egon',
					'organism'   => { 'name' => 'from outer space' }
				}
			]
		}
	),
	1,
	"probably we could add"
);

$value = $table1->get_data_table_4_search(
	{
		'search_columns' =>
		  [ 'test_master.name', 'test_slave.other_name', 'test_organism.name' ]
	}
);
is_deeply(
	$value->AsString(),
	'#test_master.name	test_slave.other_name	test_organism.name
test	hugo	from outer space
test	egon	from outer space
', 'got all data'
);

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
