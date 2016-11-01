#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 19;
BEGIN { use_ok 'stefans_libs::array_analysis::table_based_statistics' }

my ( $value, @values, $exp, $path );
my $stefans_libs_array_analysis_table_based_statistics = stefans_libs_array_analysis_table_based_statistics -> new();
is_deeply ( ref($stefans_libs_array_analysis_table_based_statistics) , 'stefans_libs_array_analysis_table_based_statistics', 'simple test of function stefans_libs_array_analysis_table_based_statistics -> new()' );
$stefans_libs_array_analysis_table_based_statistics -> {'Do_not_run_automatic'} = 0; ## I do not want to bother with the R RUN
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$path = "/home/stefan/tmp/simply_remove";
my $data_table = data_table->new();
foreach ( "Probe Set ID", qw(A B C D E F G H) ){
	$data_table -> Add_2_Header ( $_ ) ;
}
mkdir ( $path.'/Description');
$data_table -> AddDataset ( {
	"Probe Set ID" => 'x',
	'A' => 1, 
	'B' => 2,
	'C' => 3,
	'D' => 4,
	'E' => 5,
	'F' => 4,
	'G' => 3,
	'H' => 4,
} );
$data_table -> AddDataset ( {
	"Probe Set ID" => 'y',
	'A' => 1, 
	'B' => 2,
	'C' => 3,
	'D' => 4,
	'E' => 5,
	'F' => 6,
	'G' => 7,
	'H' => 8,
} );
$data_table -> AddDataset ( {
	"Probe Set ID" => 'z',
	'A' => 1, 
	'B' => 2,
	'C' => 3,
	'D' => 1,
	'E' => 7,
	'F' => 8,
	'G' => 9,
	'H' => 5,
} );
$data_table -> write_file ( $path.'/Description/source_table.xls');
$data_table = $data_table ->_copy_without_data ();
$data_table -> AddDataset ( {
	"Probe Set ID" => 'Wilcox',
	'A' => 'a', 
	'B' => 'a',
	'C' => 'a',
	'D' => 'a',
	'E' => 'b',
	'F' => 'b',
	'G' => 'b',
	'H' => 'b',
} );
$data_table -> AddDataset ( {
	"Probe Set ID" => 'Student-T',
	'A' => 'a', 
	'B' => 'a',
	'C' => 'a',
	'D' => 'a',
	'E' => 'b',
	'F' => 'b',
	'G' => 'b',
	'H' => 'b',
} );
$data_table -> AddDataset ( {
	"Probe Set ID" => 'spearman',
	'A' => 1.2, 
	'B' => 2,
	'C' => 3.5,
	'D' => 5,
	'E' => 5,
	'F' => 6,
	'G' => 6.9,
	'H' => 8.1,
} );
$data_table -> AddDataset ( {
	"Probe Set ID" => 'Kruskal Wallis',
	'A' => 'a', 
	'B' => 'a',
	'D' => 'c',
	'E' => 'c',
	'F' => 'b',
	'G' => 'b',
} );

$data_table->write_file ($path.'/groups.xls');
$stefans_libs_array_analysis_table_based_statistics -> Path($path);

is_deeply ( [$stefans_libs_array_analysis_table_based_statistics->GetStatProjects( {'data_table' =>  $path.'/Description/source_table.xls', 'grouping_table' => $path.'/groups.xls' })],
 [$path.'/Kruskal_Wallis.tar',$path.'/Student-T.tar', $path.'/spearman.tar',$path.'/Wilcox.tar' ], "got the right filenames - at least");

## Now I check the addition od a description column!

$data_table = data_table->new();
$data_table -> Add_2_Header( 'Probe Set ID');
$data_table -> Add_2_Header( 'Gene Symbol');
$data_table -> AddDataset ( {'Probe Set ID' => 'x',  'Gene Symbol' => 'XX' } );
$data_table -> AddDataset ( {'Probe Set ID' => 'y',  'Gene Symbol' => 'YY' } );
$data_table -> AddDataset ( {'Probe Set ID' => 'z',  'Gene Symbol' => 'ZZ' } );
mkdir ( 'Description');
$data_table ->write_file ( $path.'/Description/Description.xls' );

foreach ( qw(Kruskal_Wallis spearman Wilcox) ){
	$stefans_libs_array_analysis_table_based_statistics ->process_result_file ( $path. "/$_.tar",  $path.'/Description/Description.xls', "From the test script mode $_" );
}
## Now I need to check the results!
$data_table = data_table->new();
chdir ( '/home/stefan/tmp/simply_remove/' );
#foreach ( qw(Kruskal_Wallis spearman Wilcox) ){
	
system ( "tar -xf Kruskal_Wallis.tar");
$data_table->read_file ( 'purged_results.xls' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'p' ), { 'x' => 0.12299787068125, 'y' => 0.101701392304227, 'z' => 0.165055980273822 }, 'p values - Kruskal_Wallis' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'Gene Symbol' ), { 'x' => 'XX', 'y' => 'YY', 'z' => 'ZZ' }, 'Gene Symbols - Kruskal_Wallis' );

system ( "tar -xf spearman.tar");
$data_table->read_file ( 'purged_results.xls' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'p' ), { 'x' => 0.102860308433984, 'y' => 5.29615351564429e-07, 'z' => 0.0509044753743497 }, 'p values - spearman' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'Gene Symbol' ), { 'x' => 'XX', 'y' => 'YY', 'z' => 'ZZ' }, 'Gene Symbols - spearman' );
is_deeply ( $data_table->Description('Correlating data in order:'), ["Correlating data in order:\t1.2;2;3.5;5;5;6;6.9;8.1"], 'Spearman x values' );
system ( "tar -xf Wilcox.tar");
$data_table->read_file ( 'purged_results.xls' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'p' ), { 'x' => 0.136658247738147, 'y' => 0.0303828219765775, 'z' =>  0.0294010481903397 }, 'p values - Wilcox' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'Gene Symbol' ), { 'x' => 'XX', 'y' => 'YY', 'z' => 'ZZ' }, 'Gene Symbols - Wilcox' );

## OK and now test the FDR method!
$stefans_libs_array_analysis_table_based_statistics -> {'debug'} = 1;
#print "Start of FDR calculation tests\n";
$stefans_libs_array_analysis_table_based_statistics ->  calculate_FDR ( 'Wilcox.tar', 'BH', 'The test script did calculate( "Wilcox.tar", "BH", "this message")' );
system ( "tar -xf Wilcox.tar");
#print "We start the q_value checks:\n";
is_deeply ( -f 'qvalues.R', 1, 'q_values R script is OK' );
$data_table->read_file ( 'purged_results.xls' );
is_deeply ( defined $data_table->Header_Position('q_value (BH)'), 1, "The column was added in the results file" );
$exp = [ '0.1366582', '0.04557423', '0.04557423' ];
is_deeply ($data_table->get_column_entries( 'q_value (BH)' ), $exp, "q_values");

$stefans_libs_array_analysis_table_based_statistics ->  calculate_FDR ( 'Kruskal_Wallis.tar', 'BH', 'The test script did calculate( "Kruskal_Wallis.tar", "BH", "this message")' );
system ( "tar -xf Kruskal_Wallis.tar");
#print "We start the q_value checks:\n";
is_deeply ( -f 'qvalues.R', 1, 'q_values R script is OK' );
$data_table->read_file ( 'purged_results.xls' );
is_deeply ( defined $data_table->Header_Position('q_value (BH)'), 1, "Kruskal_Wallis The column was added in the results file" );
$exp = [ '0.165056', '0.165056', '0.165056' ];
#print "\$exp = ".root->print_perl_var_def( $data_table->get_column_entries( 'q_value (BH)' ) ).";\n";
is_deeply ($data_table->get_column_entries( 'q_value (BH)' ), $exp, "q_values");

$stefans_libs_array_analysis_table_based_statistics ->  calculate_FDR ( 'spearman.tar', 'BH', 'The test script did calculate( "spearman.tar", "BH", "this message")' );
system ( "tar -xf spearman.tar");
#print "We start the q_value checks:\n";
is_deeply ( -f 'qvalues.R', 1, 'q_values R script is OK' );
$data_table->read_file ( 'purged_results.xls' );
is_deeply ( defined $data_table->Header_Position('q_value (BH)'), 1, "spearman The column was added in the results file" );
$exp = [ '0.1028603', '1.588846e-06', '0.07635671' ];
#print "\$exp = ".root->print_perl_var_def( $data_table->get_column_entries( 'q_value (BH)' ) ).";\n";
is_deeply ($data_table->get_column_entries( 'q_value (BH)' ), $exp, "q_values");

#print "\$exp = ".root->print_perl_var_def( $data_table->get_column_entries( 'q_value (BH)' ) ).";\n";
$stefans_libs_array_analysis_table_based_statistics -> {'debug'} = 0;


is_deeply ( [$stefans_libs_array_analysis_table_based_statistics->GetStatProjects( {'data_table' =>  $path.'/Description/source_table.xls', 'grouping_table' => $path.'/groups.xls', 'data_type' =>"parametric" })],
 [$path.'/Kruskal_Wallis.tar',$path.'/Student-T.tar', $path.'/spearman.tar', $path.'/Wilcox.tar'], "got the right filenames - at least");

foreach ( 'Student-T' ){
	$stefans_libs_array_analysis_table_based_statistics ->process_result_file ( $path. "/$_.tar",  $path.'/Description/Description.xls', "From the test script mode $_" );
}
system ( "tar -xf Student-T.tar");
$data_table->read_file ( 'purged_results.xls' );
print "\$exp = ".root->print_perl_var_def($data_table->getAsHash ( 'Probe Set ID', 'p' ) ).";\n";
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'p' ), {
  'y' => '0.00465921494399393',
  'x' => '0.105964978166874',
  'z' => '0.00297671019171987'
}, 'p values - Student-T' );
is_deeply ($data_table->getAsHash ( 'Probe Set ID', 'Gene Symbol' ), { 'x' => 'XX', 'y' => 'YY', 'z' => 'ZZ' }, 'Gene Symbols - Student-T' );


#$data_table = data_table->new();
#$data_table->read_file ( '.xls' );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
