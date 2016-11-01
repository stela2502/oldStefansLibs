#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::database::system_tables::LinkList' }

my $LinkList = LinkList->new( root::getDBH('root') );
$LinkList->create();
$LinkList->{'data_handler'}->{'object_list'}->create();
is_deeply( ref($LinkList), 'LinkList',
	'simple test of function LinkList -> new()' );

## test for new

is_deeply(
	$LinkList->AddDataset(
		{
			'owner' => 'system',
			'description' =>
'recentyl uploaded script files. The form definition of these scripts may need revision. Afterwards you may add the scripts to new container objects.',
			'name'          => 'New Scripts',
			'managed_entry' => {
				'name'          => "TEST",
				'link_position' => '/form/TEST',
				'object_type'   => 'formdef',
				'owner_id'      => 1
			  }

		}
	),
	1,
	"we can add a dataset"
);

is_deeply(
	[
		split(
			/[\t\n]/,
			$LinkList->get_data_table_4_search(
				{
					'search_columns' => [
						'LinkList.name',  'LinkList.description',
						'LinkList.owner', 'www_object_table.link_position'
					],
					'where' => [ [ "LinkList.name", "=", "my_value" ] ]
				},
				'New Scripts'
			  )->AsString
		)
	],
	[
		split(
			/[\t\n]/,
"#LinkList.name\tLinkList.description\tLinkList.owner\twww_object_table.link_position\n"
			  . "New Scripts\trecentyl uploaded script files. The form definition of these scripts may need revision. "
			  . "Afterwards you may add the scripts to new container objects.\tsystem\t/form/TEST\n"
		)
	],
	"we can search the LinkList"
);

is_deeply(
	$LinkList->AddDataset(
		{
			'owner' => 'system',
			'description' =>
'recentyl uploaded script files. The form definition of these scripts may need revision. Afterwards you may add the scripts to new container objects.',
			'name'          => 'New Scripts',
			'managed_entry' => {
				'name'          => "TEST2",
				'link_position' => '/form/TEST2',
				'object_type'   => 'formdef',
				'owner_id'      => 1
			  }

		}
	),
	1,
	"we can add second linked dataset"
);

is_deeply(
	scalar(
		@{
			$LinkList->get_data_table_4_search(
				{
					'search_columns' => [
						'LinkList.name',         'LinkList.owner',
						'www_object_table.name'
					],
					'where' => [
						[ "LinkList.name",         "=", "my_value" ]
					  ]
				},
				'New Scripts'
			  )->{'data'}
		  }
	),
	2,
	"we can search the LinkList and get more than one entry"
);

$LinkList->printReport();

print $LinkList->{'complex_search'};

