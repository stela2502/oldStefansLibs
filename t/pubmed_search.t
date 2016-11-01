#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
	use_ok 'stefans_libs::database::PubMed_queries';
}

my $data = &getData();
my ( $value, $exp);
my $pubmed_search = PubMed_queries->new( root::getDBH());
is_deeply( ref($pubmed_search), 'PubMed_queries',
	'simple test of function pubmed_search -> new()' );

## first test will be brute force - hehehe
#&cascade_create($pubmed_search);

#is_deeply ( 1, $pubmed_search->AddDataset($data), "we get the right ID");;

#is_deeply( $pubmed_search->get_T2D_hit_count_4_GeneSymbol ('ERBB4'), 21,"A web search");

#is_deeply( $pubmed_search->get_T2D_hit_count_4_GeneSymbol ('KCNE1'), 376, "another search");

$pubmed_search->printReport();

$value = $pubmed_search -> _getLinkageInfo ();
#print "linkage_info for class ".$value->ClassName()." contains the infor for these other classes:\n";
#foreach (  @{$value->{'links'}} ){
#	if ( ref($_->{'other_info'}) eq "linkage_info" ){
#		&print_class_infos( $_->{'other_info'} );
#	}
#}

$value = $pubmed_search -> get_data_table_4_search( {
	'search_columns' => ['GeneSymbol', 'PubMed.title', 'Authors.first_name', 'Authors.last_name', 'Journals.name'],
	'where' => [ ['GeneSymbol', '=', 'my_value'] ]
}, 'ERBB4');

print $value ->AsString();

#$value = $pubmed_search->get_publications_for_T2D_gene('ERBB4' );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

sub print_class_infos {
	my ( $class ) = @_;
	if ( ref($class) eq "linkage_info" ){
		print "linkage_info for class ".$_->{'other_info'}->ClassName()."\n";
		&print_class_infos( $_->{'other_info'} );
	}
}

sub cascade_create{
	my ($db_obj) = @_;
	$db_obj ->create();
	foreach my $linked_table ( values %{$db_obj->{'data_handler'}} ){
		&cascade_create($linked_table);
	}
}

sub getData {
	return {
  'GeneSymbol' => 'MSR1',
  'query_string' => 'MSR1[All Fields] AND ("fat"[All Fields] OR ("insulin"[MeSH Terms] OR "insulin"[All Fields]) OR T2D[All Fields] OR ("mitochondria"[MeSH Terms] OR "mitochondria"[All Fields]))',
  'PubMed_list' => [ {
  'authors' => [  {
  'last_name' => 'Perucatti',
  'first_name' => 'A',
}, {
  'last_name' => 'Di Meo',
  'first_name' => 'GP',
}, {
  'last_name' => 'Goldammer',
  'first_name' => 'T',
}, {
  'last_name' => 'Incarnato',
  'first_name' => 'D',
}, {
  'last_name' => 'Brunner',
  'first_name' => 'R',
}, {
  'last_name' => 'Iannuzzi',
  'first_name' => 'L',
},  ],
  'pub_year' => '2007',
  'title' => 'Comparative FISH-mapping of twelve loci in river buffalo and sheep chromosomes: comparison with HSA8p and HSA4q.</a></p><p',
  'PMID' => '18253036',
  'journal' => {
  'name' => 'Cytogenetic and genome research',
},
}, {
  'authors' => [  {
  'last_name' => 'Dong',
  'first_name' => 'JT',
},  ],
  'pub_year' => '2006',
  'title' => 'Prevalent mutations in prostate cancer.</a></p><p',
  'PMID' => '16267836',
  'journal' => {
  'name' => 'Journal of cellular biochemistry',
},
}, {
  'authors' => [  {
  'last_name' => 'Kamada',
  'first_name' => 'N',
}, {
  'last_name' => 'Kodama',
  'first_name' => 'T',
}, {
  'last_name' => 'Suzuki',
  'first_name' => 'H',
},  ],
  'pub_year' => '2001',
  'title' => 'Macrophage scavenger receptor (SR-A I/II) deficiency reduced diet-induced atherosclerosis in C57BL/6J mice.</a></p><p',
  'PMID' => '11686309',
  'journal' => {
  'name' => 'Journal of atherosclerosis and thrombosis',
},
}, {
  'authors' => [ {
  'last_name' => 'De Winther',
  'first_name' => 'MP',
}, {
  'last_name' => 'Gijbels',
  'first_name' => 'MJ',
}, {
  'last_name' => 'Van Dijk',
  'first_name' => 'KW',
}, {
  'last_name' => 'Havekes',
  'first_name' => 'LM',
}, {
  'last_name' => 'Hofker',
  'first_name' => 'MH',
},  ],
  'pub_year' => '2000',
  'title' => 'Transgenic mouse models to study the role of the macrophage scavenger receptor',
  'PMID' => '10937358',
  'journal' => {
  'name' => 'International journal of tissue reactions',
},
}, {
  'authors' => [  {
  'last_name' => 'Tzagoloff',
  'first_name' => 'A',
}, {
  'last_name' => 'Shtanko',
  'first_name' => 'A',
},  ],
  'pub_year' => '1995',
  'title' => 'Mitochondrial and cytoplasmic isoleucyl-, glutamyl- and arginyl-tRNA synthetases of yeast are encoded by separate genes.</a></p><p',
  'PMID' => '7607232',
  'journal' => {
  'name' => 'European journal of biochemistry / FEBS',
},
}, {
  'authors' => [ {
  'last_name' => 'Acton',
  'first_name' => 'SL',
}, {
  'last_name' => 'Scherer',
  'first_name' => 'PE',
}, {
  'last_name' => 'Lodish',
  'first_name' => 'HF',
}, {
  'last_name' => 'Krieger',
  'first_name' => 'M',
},  ],
  'pub_year' => '1994',
  'title' => 'Expression cloning of SR-BI, a CD36-related',
  'PMID' => '7520436',
  'journal' => {
  'name' => 'The Journal of biological chemistry',
},
},  ],
  'results' => '6',
};
}