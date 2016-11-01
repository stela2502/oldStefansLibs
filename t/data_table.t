#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 53;
BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $data_table, $data_table2 );

$data_table = data_table->new();
foreach ( 'forename', 'surename', 'university' ){
	$data_table -> Add_2_Header ( $_ );
}
$data_table2 = data_table->new();
foreach ( 'forename', 'surename', 'gender' ){
	$data_table2 -> Add_2_Header ( $_ );
}
$data_table2 -> define_subset( 'search', ['forename', 'surename' ]);
$data_table -> define_subset( 'search', ['forename', 'surename' ]);
$data_table->AddDataset ( {'forename' =>'stefan', 'surename' => 'lang','university' => 'none' });
$data_table2->AddDataset ( {'forename' =>'stefan', 'surename' => 'lang','gender' => 'male' });
$data_table -> merge_with_data_table ( $data_table2 );
is_deeply ( $data_table->get_line_asHash(0), {'forename' =>'stefan', 'surename' => 'lang','university' => 'none','gender' => 'male' }, "I could merge on two columns");

$data_table = data_table->new();
is_deeply( ref($data_table), 'data_table',
	'simple test of function data_table -> new()' );

$data_table->parse_from_string(
"#first\tsecond\temail\tage\nstefan\tlang\tstefan\@nix.de\t32\neva\tlang\tnix2\@nix.de\t30\n"
);

is_deeply(
	$data_table->AsString(),
"#first\tsecond\temail\tage\nstefan\tlang\tstefan\@nix.de\t32\neva\tlang\tnix2\@nix.de\t30\n",
	"we can reas from a string and get the string back!"
);

is_deeply( $data_table->createIndex('second'),
	1, "we get no error while creating an index" );

is_deeply(
	[ $data_table->define_subset( 'name', [ 'second', 'first' ] ) ],
	[ 1, 0 ],
	"it seams as if we could add an subset"
);

is_deeply(
	$data_table->AsString('name'),
	"#second\tfirst\nlang\tstefan\nlang\teva\n",
	"we can get the data for a subset"
);

is_deeply(
	$data_table->getAsHash( 'name', 'email' ),
	{ 'lang stefan' => "stefan\@nix.de", 'lang eva' => "nix2\@nix.de" },
	"the function getAsHash"
);

is_deeply( $data_table->Add_2_Header('nationality'),
	4, "we can add a new column" );

is_deeply(
	$data_table->Add_Dataset(
		{ 'first' => 'geraldin', 'second' => 'lang', 'nationality' => 'de' }
	),
	3,
	"we can add a dataset"
);

is_deeply(
	[ split( /[\t\n]/, $data_table->AsString() ) ],
	[
		split(
			/[\t\n]/,
"#first\tsecond\temail\tage\tnationality\nstefan\tlang\tstefan\@nix.de\t32\t\neva\tlang\tnix2\@nix.de\t30\t\ngeraldin\tlang\t\t\tde\n"
		)
	],
	"and we can get the updated data structure back!"
);

is_deeply(
	[
		$data_table->get_rowNumbers_4_columnName_and_Entry(
			'name', [ 'lang', 'geraldin' ]
		)
	],
	[2],
	"we can get the row number for one entry"
);

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan", "lang", "stefan\@nix.de", "32" ],
		[ 'eva',    'lang', 'nix2@nix.de',    '30' ],
		[ 'geraldin', 'lang', undef, undef, 'de' ]
	],
	"we can use getLines_4_columnName_and_Entry"
);

$data_table->Add_dataset_for_entry_at_index( { 'nationality' => 'de' },
	'lang', 'second' );

is_deeply(
	[
		$data_table->getLines_4_columnName_and_Entry(
			'name', [ 'lang', 'stefan' ]
		)
	],
	[ [ 'stefan', 'lang', 'stefan@nix.de', '32', 'de' ] ],
	"we can add data to a row"
);

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32",  'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30',  'de' ],
		[ 'geraldin', 'lang', undef,            undef, 'de' ]
	],
"and the data is added to all rows, but not to the row the data was already present"
);

$data_table->Add_dataset_for_entry_at_index( { 'nationality' => 'se' },
	'lang', 'second' );

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32",  'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30',  'se' ],
		[ 'geraldin', 'lang', undef,            undef, 'se' ]
	],
	"if a new entry is added, the old data is replaced"
);

$data_table->Add_unique_key( 'name_loc', [ 'first', 'second', 'nationality' ] );

$data_table->Add_dataset_for_entry_at_index(
	{ 'nationality' => [ 'se', 'de' ] },
	'lang', 'second' );

is_deeply(
	[
		sort { @$a[0] cmp @$b[0] }
		  ( $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) )
	],
	[
		sort { @$a[0] cmp @$b[0] } (
			[ "stefan",   "lang", "stefan\@nix.de", "32",  'se' ],
			[ 'eva',      'lang', 'nix2@nix.de',    '30',  'se' ],
			[ 'geraldin', 'lang', undef,            undef, 'se' ],
			[ "stefan",   "lang", "stefan\@nix.de", "32",  'de' ],
			[ 'eva',      'lang', 'nix2@nix.de',    '30',  'de' ],
			[ 'geraldin', 'lang', '',               '',    'de' ]
		)
	],
"if the new entry is an array, we create new lines for the not existing entries"
);

## and finally - the import export...
$data_table->Add_dataset_for_entry_at_index( { 'email' => 'nix', 'age' => 2 },
	[ 'lang', 'geraldin' ], 'name' );
$data_table->print2file('temp_table.txt');
$data_table2 = data_table->new();
$data_table2->read_file('temp_table.txt');
$data_table->{'read_filename'} = 'temp_table.txt';
is_deeply( $data_table, $data_table2, "import / export is ok" );
$data_table2 = $data_table->Sort_by( [ [ 'age', 'numeric' ] ] );

is_deeply(
	$data_table2->{'data'},
	[
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can sort 'numeric'"
);

$data_table2 = $data_table->Sort_by( [ [ 'first', 'lexical' ] ] );

is_deeply(
	$data_table2->{'data'},
	[
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can sort 'lexical'"
);

$data_table2 = $data_table->Sort_by( [ [ 'age', 'antiNumeric' ] ] );

my @temp = ('stefan');
$value = $data_table2->getCopy_4_values( 'first', @temp );

is_deeply(
	$value->{'data'},
	[
		[ "stefan", "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan", "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can get a column subset"
);

#print $value-> AsLatexLongtable();

is_deeply(
	$data_table2->{'data'},
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ]
	],
	"we can sort 'antiNumeric'"
);

$data_table2 = $data_table->Get_first_for_column( 'first', 1, 'lexical' );

is_deeply(
	$data_table2->{'data'},
	[
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ]
	],
	"we can restrict the dataset to on per line entry"
);

is_deeply( $data_table2->get_value_for( 'name', [ 'lang', 'stefan' ], 'email' ),
	'stefan@nix.de', "We can get one value" );

is_deeply(
	$data_table2->AsLatexLongtable(), '
\begin{longtable}{|c|c|c|c|c|}
\hline
first & second & email & age & nationality\\\\
\hline
\hline
\endhead
\hline \multicolumn{5}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 eva & lang & nix2@nix.de & 30 & se \\\\
 geraldin & lang & nix & 2 & se \\\\
 stefan & lang & stefan@nix.de & 32 & se \\\\
\end{longtable}

', "we can print as latex longtable"
);

$data_table2->define_subset( 'info', [ 'first', 'gender' ] );

is_deeply(
	$data_table2->{'last_warning'},
"data_table::define_subset -> sorry - we do not know a column called 'gender'\n"
	  . "but we have created that column for you!",
	"we can create a subset using previously undefined columns!"
);
is_deeply(
	$data_table2->AsLatexLongtable('info'), '
\begin{longtable}{|l|c|}
\hline
first & gender\\\\
\hline
\hline
\endhead
\hline \multicolumn{2}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 eva &   \\\\
 geraldin &   \\\\
 stefan &   \\\\
\end{longtable}

', "We can get a table with previously undefined columns."
);

## Now lets test the (new) description
$data_table2->Add_2_Description("Just a test file");
my $data_table3 = data_table->new();
$data_table3->parse_from_string( $data_table2->AsString() );

is_deeply( $data_table3->AsString, $data_table2->AsString,
	"we can add a description and create the same object from the string" );

my $other_data_table = data_table->new();
$other_data_table->Add_2_Header('some_crap');
$other_data_table->Add_2_Header('second');
$other_data_table->createIndex('second');
$other_data_table->Add_Dataset(
	{ 'some_crap' => 'nothing - really', 'second' => 'lang' } );
is_deeply( $other_data_table->AsString (), "#some_crap\tsecond\nnothing - really\tlang\n", "we add a simple column to the \$other_table");

$data_table2->Add_Dataset(
	{ 'first' => 'hugo', 'second' => 'Boss', 'email' => 'Hugo.Boss@nix.com' } );

#print "the data_table3 has the index columns ".join(", ", (keys %{$data_table3->{'index'}}))."\n";

#print "\nWith the table\n".$other_data_table->AsString();
$data_table2->createIndex('second');
$data_table2 = $data_table2->merge_with_data_table($other_data_table);

#print "Is the table merged ?\n". $data_table2->AsString();

print $data_table2->AsString();
is_deeply( $data_table2->Header_Position('some_crap'),
	6, "we get a merged table" );

#warn root::get_hashEntries_as_string ($data_table3 -> get_line_asHash ( 3 ), 3, "please see if we got a line test ");
$value = {
	'some_crap'   => '',
	'nationality' => '',
	'gender'      => '',
	'age'         => '',
	'first'       => 'hugo',
	'second'      => 'Boss',
	'email'       => 'Hugo.Boss@nix.com'
};
is_deeply( $data_table2->get_line_asHash(3),
	$value, "we do not touch a not acceptable column" );

$data_table2->define_subset( 'name', [ 'first', 'second' ] );
is_deeply(
	[ $data_table2->get_value_for( 'second', 'Boss', 'name' ) ],
	[ 'Boss', 'hugo' ],
	"we can use 'get_value_for'"
);
is_deeply(
	[ $data_table2->get_value_for( 'first', 'stefan', 'name' ) ],
	[ 'lang', 'stefan' ],
	"and we can use the function a second time"
);

is_deeply(
	[ $data_table2->get_value_for( 'second', 'Boss', 'ALL' ) ],
	[ 'hugo', 'Boss', 'Hugo.Boss@nix.com', '', '', '', '' ],
	"we can search for all entries"
);

#print root::get_hashEntries_as_string ($data_table, 3, "the old data table ");
#print root::get_hashEntries_as_string ($data_table2, 3, "the new data table ");

$data_table = $data_table2->get_as_table_object('name');
is_deeply(
	$data_table->AsString(),
	"#Just a test file\n#second\tfirst\nlang\teva\nlang\tgeraldin\nlang\tstefan\nBoss\thugo\n",
	"we can get a table object for a subset"
);
$exp = $data_table->getAsHash( "first", 'second' );
is_deeply( $exp->{'geraldin'}, 'lang', "getAsHash" );
$data_table->set_HeaderName_4_position( "new name", 1 );
is_deeply(
	$data_table->AsString(),
	"#Just a test file\n#second\tnew name\nlang\teva\nlang\tgeraldin\nlang\tstefan\nBoss\thugo\n",
	"and we can rename a column and get the right STRING back"
);
$value = $data_table->getAsHash( "new name", 'second' );
is_deeply( $value, $exp,
"after a rename of the column I can still get the same dataset using getAsHash with the new column names"
);

$data_table->set_HeaderName_4_position( 8, 1 );
$value = $data_table->getAsHash( 8, 'second' );
is_deeply( $value, $exp, "we get no problem using intergers as column titles" );

#print "we try to select all columns where 'first' eq 'geraldin'\n".$data_table2->AsString()."\n";
$value =
  $data_table2->select_where( "first", sub { return shift eq 'geraldin' } );
is_deeply( ref($value), 'data_table', 'select_where return object' );
is_deeply(
	$value->AsString(),
"#first\tsecond\temail\tage\tnationality\tgender\tsome_crap\ngeraldin\tlang\tnix\t2\tse	\tnothing - really\n",
	'select_where return data'
);
$exp   = {};
$value = $data_table2->select_where(
	"second",
	sub {
		if ( !defined $exp->{ $_[0] } ) { $exp->{ $_[0] } = 1; return 1; }
		return 0;
	}
);
is_deeply(
	$value->AsString(),
	"#first\tsecond\temail\tage\tnationality\tgender\tsome_crap\n"
	  . "eva\tlang\tnix2\@nix.de\t30\tse\t\tnothing - really\n"
	  . "hugo\tBoss\tHugo.Boss\@nix.com\t\t\t\t\n",
	'select_where return data #2'
);

## check the calculate function on table2 that looks like
## print $data_table2->AsString();
# #first   second  email               age  nationality  gender  some_crap
# eva      lang    nix2@nix.de         30   se                   nothing - really
# geraldin lang    nix                 2    se                   nothing - really
# stefan   lang    stefan@nix.de       32   se                   nothing - really
# hugo     Boss    Hugo.Boss@nix.com

## so now add the gender!
$data_table2->calculate_on_columns(
	{
		'function' =>
		  sub { return 'male' if ( "stefan hugo" =~ $_[0] ); return 'female' },
		'data_column'   => 'first',
		'target_column' => 'gender'
	}
);
is_deeply(
	$data_table2->AsString(),
"#Just a test file\n#first\tsecond\temail\tage\tnationality\tgender\tsome_crap\n"
	  . "eva\tlang\tnix2\@nix.de\t30\tse\tfemale\tnothing - really\n"
	  . "geraldin\tlang\tnix\t2\tse\tfemale\tnothing - really\n"
	  . "stefan\tlang\tstefan\@nix.de\t32\tse\tmale\tnothing - really\n"
	  . "hugo\tBoss\tHugo.Boss\@nix.com\t\t\tmale\t\n",
	'calculate_on_columns no column creation'
);

$data_table2 = data_table->new();
$data_table2->string_separator('"');
$data_table2->line_separator(",");
$data_table2->parse_from_string(
'"Probe Set ID","Affy SNP ID","dbSNP RS ID","Chromosome","Physical Position","Strand","ChrX pseudo-autosomal region 1","Cytoband","Flank","Allele A","Allele B","Associated Gene","Genetic Map","Microsatellite","Fragment Enzyme Type Length Start Stop","Allele Frequencies","Heterozygous Allele Frequencies","Number of individuals/Number of chromosomes","In Hapmap","Strand Versus dbSNP","Copy Number Variation","Probe Count","ChrX pseudo-autosomal region 2","In Final List","Minor Allele","Minor Allele Frequency","% GC"
"SNP_A-1780619","10004759","rs17106009","1","50433725","-","0","p33","ggatattgtgtgagga[A/G]taagcccacctgtggt","A","G","ENST00000371827 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000371821 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000371819 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000323186 // intron // 0 // --- // --- // --- // ELAV-like protein 4 (Paraneoplastic encephalomyelitis antigen HuD) (Hu-antigen D). [Source:Uniprot/SWISSPROT;Acc:P26378] /// NM_021952 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000357083 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000361667 // intron // 0 // --- // --- // --- // ELAV-like protein 4 (Paraneoplastic encephalomyelitis antigen HuD) (Hu-antigen D). [Source:Uniprot/SWISSPROT;Acc:P26378] /// ENST00000371823 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000371824 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D)","72.030224900657 // D1S2824 // D1S197 // --- // --- /// 76.2778636775225 // D1S2706 // D1S2661 // --- // --- /// 68.1611616801535 // --- // --- // TSC59969 // TSC770243","D1S1559 // downstream // 52144 /// D1S2299E // upstream // 6915","StyI // --- // 817 // 50433297 // 50434113 /// NspI // --- // 574 // 50433477 // 50434050","0.010204 // 0.989796 // CEPH /// 0.0 // 1.0 // Han Chinese /// 0.0 // 1.0 // Japanese /// 0.022222 // 0.977778 // Yoruba","0.0202 // CEPH /// 0.0 // Han Chinese /// 0.0 // Japanese /// 0.043457 // Yoruba","49.0 // CEPH /// 45.0 // Han Chinese /// 45.0 // Japanese /// 45.0 // Yoruba","YES","reverse","---","12","0","YES","--- // CEPH /// --- // Han Chinese /// --- // Japanese /// --- // Yoruba","0.010204 // CEPH /// 0.0 // Han Chinese /// 0.0 // Japanese /// 0.022222 // Yoruba","0.415785"
"SNP_A-1780618","10004754","rs233978","4","104894961","+","0","q24","ggatattgtccctggg[A/G]atggccttatttatct","A","G","ENST00000305749 // downstream // 714054 // Hs.12248 // CXXC4 // 80319 // CXXC finger 4 /// NM_001059 // upstream // 34539 // Hs.942 // TACR3 // 6870 // Tachykinin receptor 3 /// NM_025212 // downstream // 714054 // Hs.12248 // CXXC4 // 80319 // CXXC finger 4 /// ENST00000304883 // upstream // 34539 // Hs.942 // TACR3 // 6870 // Tachykinin receptor 3","108.086324698038 // D4S1572 // D4S2913 // --- // --- /// 107.781224080953 // D4S1591 // D4S2907 // --- // --- /// 105.84222066207 // --- // --- // TSC571244 // TSC798293","D4S2650 // downstream // 90282 /// D4S1344 // upstream // 103722","StyI // --- // 221 // 104894854 // 104895074 /// NspI // --- // 700 // 104894812 // 104895511","0.38 // 0.62 // CEPH /// 0.366667 // 0.633333 // Han Chinese /// 0.322222 // 0.677778 // Japanese /// 0.2 // 0.8 // Yoruba","0.4712 // CEPH /// 0.5111 // Han Chinese /// 0.4667 // Japanese /// 0.32 // Yoruba","50.0 // CEPH /// 45.0 // Han Chinese /// 45.0 // Japanese /// 50.0 // Yoruba","YES","reverse","---","12","0","YES","--- // CEPH /// --- // Han Chinese /// --- // Japanese /// --- // Yoruba","0.38 // CEPH /// 0.366667 // Han Chinese /// 0.322222 // Japanese /// 0.2 // Yoruba","0.358613"'
);
is_deeply( $data_table2->Header_Position('Probe Set ID'),
	0, "the column header was identified in the right way!" );
is_deeply( $data_table2->Header_Position('Affy SNP ID'),
	1, "the second column header was identified in the right way!" );
is_deeply( $data_table2->Header_Position('% GC'),
	26, "the last column header was identified in the right way!" );

is_deeply(
	$data_table2->getAsArray('Probe Set ID'),
	[ 'SNP_A-1780619', 'SNP_A-1780618' ],
	"data import first column"
);
is_deeply(
	$data_table2->getAsArray('% GC'),
	[ 0.415785, 0.358613 ],
	"data import last column"
);

$data_table2 = data_table->new();
$data_table2->parse_from_string(
	"#name	payment	sex\nA	10	m\nB	6	m\nC	40	w\nD	30	w\n");
$value = $data_table2->pivot_table(
	{
		'grouping_column'    => 'sex',
		'Sum_data_column'    => 'payment',
		'Sum_target_columns' => ['mean_payment'],
		'Suming_function'    => sub {
			my $sum = 0;
			foreach (@_) { $sum += $_; }
			return $sum / scalar(@_);
		  }
	}
);
$exp = "#sex	mean_payment\nm	8\nw	35\n";
is_deeply( $value->AsString(), $exp, 'simple pivot_table' );
$data_table2->define_subset( 'data', [ 'payment', 'name' ] );
$value = $data_table2->pivot_table(
	{
		'grouping_column'    => 'sex',
		'Sum_data_column'    => 'data',
		'Sum_target_columns' => [ 'mean_payment', 'names', 'subjects' ],
		'Suming_function'    => sub {
			my $sum  = 0;
			my $name = '';
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				$sum += $_[$i];
				$name .= $_[ $i + 1 ] . " ";
			}
			chop($name);
			return ( $sum / scalar(@_) * 2, $name, scalar(@_) / 2 );
		  }
	}
);
$exp = "#sex	mean_payment	names	subjects\nm	8	A B	2\nw	35	C D	2\n";
is_deeply( $value->AsString(), $exp, 'complex pivot_table' );
$value->plot_as_bar_graph ( {
	'outfile' => "/home/stefan_l/test_figure",
				'title' => "only a test",
				'y_title' => "mean payment",
		        'data_name_column' => 'sex', 
		        'data_values_columns' => ['mean_payment', 'subjects'], 
		        'x_res' => 800,
				'y_res' => 500,
				'x_border' => 70,
				'y_border' => 50
});

$value = $data_table2->make_column_LaTeX_p_type ( 'payment', '5cm');
is_deeply ( $value, '5cm', 'set a LaTeX p value');
$value = $data_table2->AsLatexLongtable ();
is_deeply ( $value , '
\begin{longtable}{|c|p{5cm}|c|}
\hline
name & payment & sex\\\\
\hline
\hline
\endhead
\hline \multicolumn{3}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 A & 10 & m \\\\
 B & 6 & m \\\\
 C & 40 & w \\\\
 D & 30 & w \\\\
\end{longtable}

', 'And the p mode is printed right');

$value = $data_table2->LaTeX_modification_for_column ( { 'column_name' => 'payment', 'before' => 'before', 'after' => 'after' } );
is_deeply ( $value, { 'before' => 'before', 'after' => 'after'}, "LaTeX_modification_for_column");

$value = $data_table2->AsLatexLongtable ();

is_deeply ( $value , '
\begin{longtable}{|c|p{5cm}|c|}
\hline
name & payment & sex\\\\
\hline
\hline
\endhead
\hline \multicolumn{3}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 A & before10after & m \\\\
 B & before6after & m \\\\
 C & before40after & w \\\\
 D & before30after & w \\\\
\end{longtable}

', 'AsLatexLongtable after LaTeX_modification_for_column');



