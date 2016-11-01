#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;
use FindBin;
my $plugin_path = "$FindBin::Bin";

BEGIN { use_ok 'stefans_libs::file_readers::affymetrix_expression_result' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs_file_readers_affymetrix_expression_result -> new();
is_deeply ( ref($test_object) , 'stefans_libs_file_readers_affymetrix_expression_result', 'simple test of function stefans_libs_file_readers_affymetrix_expression_result -> new()' );

my ( $file, $path );
$path = $plugin_path . "/data";
$path = "t/$path" unless ( -d $path );
$file = "$path/rma_expression.txt";

$test_object = stefans_libs_file_readers_affymetrix_expression_result -> new();
$test_object->p4cS('\d+_[12]');
$test_object ->read_file ( $file );
is_deeply ( scalar( @{$test_object->{'data'}}), 77, "read all data" );
$test_object->Sample_Groups ( ['34884_1', '34884_2', '34885_1', '34885_2', '34888_1']);
@values = $test_object->Sample_Groups ( ['34888_2', '34892_1', '34892_2', '34893_1', '34893_2', '34894_1', '34894_2']);
is_deeply ( \@values, [ ['34884_1', '34884_2', '34885_1', '34885_2', '34888_1'],['34888_2', '34892_1', '34892_2', '34893_1', '34893_2', '34894_1', '34894_2'] ],"the value groups were defined");


$exp = {
  '34908_2' => 2** '5.31967',
  '34908_1' =>2**  '5.23162',
  '34901_2' => 2** '5.31749',
  '34901_1' => 2** '5.23730',
  '34933_2' => 2** '5.32269',
  '34903_1' =>2**  '5.21054',
  '34902_2' => 2** '5.16944',
  '34915_2' => 2** '5.22112',
  '34904_1' =>2**  '5.21685',
  '34892_2' => 2** '5.31818',
  '34924_1' => 2** '5.38048',
  '34926_1' =>2**  '5.03256',
  '34922_1' =>2**  '5.21699',
  '34919_1' => 2** '5.36429',
  '34913_2' =>2**  '5.06160',
  '34905_2' =>2**  '5.45476',
  '34899_2' =>2** '5.47774',
  '34930_2' =>2** '5.08394',
  '34933_1' =>2** '5.26481',
  '34884_2' =>2** '4.98917',
  '34898_1' => 2**'5.11851',
  '34910_1' => 2**'5.14912',
  '34912_1' => 2**'5.32810',
  '34893_1' =>2** '5.32953',
  '34931_2' =>2** '5.16500',
  '34923_1' =>2** '5.29962',
  '34885_1' =>2** '5.22751',
  '34906_2' =>2** '5.13840',
  '34897_2' =>2** '5.09099',
  '34902_1' =>2** '5.18679',
  '34915_1' =>2** '5.51508',
  '34912_2' =>2** '5.11470',
  '34909_2' =>2** '5.53488',
  '34893_2' =>2** '6.06085',
  '34884_1' =>2** '5.13603',
  '34923_2' =>2** '5.20272',
  '34907_1' => 2**'5.12362',
  '34934_1' =>2** '5.22385',
  '34929_2' => 2**'5.21156',
  '34931_1' =>2** '4.92937',
  '34930_1' =>2** '5.27160',
  'Probe Set ID' => 'NM_000815_at',
  '34925_2' => 2**'5.07711',
  '34905_1' => 2**'5.27429',
  'Gene Symbol' => 'GABRD',
  '34895_1' =>2** '5.21991',
  '34921_2' => 2**'4.82790',
  '34898_2' => 2**'5.15931',
  '34900_1' =>2** '5.12176',
  '34896_1' => 2**'5.45074',
  '34927_1' =>2** '5.33885',
  '34897_1' => 2**'5.21119',
  '34924_2' => 2**'5.05518',
  '34894_1' => 2**'5.46326',
  '34929_1' =>2** '5.14004',
  '34932_1' =>2** '5.50893',
  '34894_2' => 2**'5.09613',
  '34921_1' => 2**'5.22069',
  '34927_2' => 2**'5.28548',
  '34932_2' => 2**'5.41709',
  '34926_2' => 2**'4.71713',
  '34925_1' => 2**'4.93521',
  '34900_2' => 2**'5.32010',
  '34888_2' => 2**'5.11324',
  '34892_1' => 2**'5.21962',
  '34913_1' => 2**'5.06471',
  '34896_2' => 2**'5.15333',
  '34909_1' =>2** '5.22084',
  '34899_1' =>2** '5.12214',
  '34904_2' => 2**'5.11957',
  '34922_2' => 2**'5.14589',
  '34907_2' => 2**'5.30247',
  '34919_2' => 2**'5.01670',
  '34934_2' => 2**'5.38322',
  '34903_2' => 2**'4.97398',
  '34906_1' =>2** '4.97858',
  '34895_2' =>2** '5.22416',
  '34910_2' =>2** '5.15802',
  '34885_2' => 2**'5.14188',
  '34888_1' =>2** '5.21919'
};

#print "$exp = ".root->print_perl_var_def($test_object->get_line_asHash(0)).";\n";
$test_object -> revert_RMA_log_values ();
is_deeply($test_object -> get_line_asHash(0),$exp,"we could revert RMA log nature" );
$test_object -> revert_RMA_log_values ();
is_deeply($test_object -> get_line_asHash(0),$exp,"and we can not do that twice" );
$value = $test_object->calculate_statistics ();
#print "$exp = ".root->print_perl_var_def($value->get_line_asHash(0)).";\n";
$exp = {
  'std expression A' => '2.2913601118834',
  'difference A-B' => -7.04764649198891,
#  'fold change A/B' => '0.833928000650905',
  'mean expression B' => '42.4372953876124',
  'std expression B' => '11.2654915765705',
  'expression p value' => '0.1437',
  'mean expression A' => '35.3896488956235',
  'Gene Symbol' => 'GABRD'
};
is_deeply ($value->get_line_asHash(0), $exp, "we get the right results" );

is_deeply ( scalar( @{$value->{'data'}}), 77, "we got resulty for all data" );

is_deeply (1== (join("\n",@{$value->Description()}) =~ m/wilcox analysis 0/), 1, "the description states a wilcox test");

$value = $test_object->calculate_statistics ();

is_deeply (1== (join("\n",@{$value->Description()}) =~ m/wilcox analysis 0/), 1, "we did not re-calculate the wilcox test just got the results one more time");

$value = $test_object->calculate_statistics ('',my $paired = 1);
$exp = {
  'std expression A' => '2.2913601118834',
  'difference A-B' => -7.04764649198891,
#  'fold change A/B' => '0.833928000650905',
  'mean expression B' => '42.4372953876124',
  'std expression B' => '11.2654915765705',
  'expression p value' => '0.1056',
  'mean expression A' => '35.3896488956235',
  'Gene Symbol' => 'GABRD'
};
is_deeply ($value->get_line_asHash(0), $exp, "we get the right results (paired test)" );

## A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
