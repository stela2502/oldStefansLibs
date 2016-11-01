#! /usr/bin/perl

use strict;
use warnings;

use stefans_libs::array_analysis::table_based_statistics;
use Getopt::Long;

my (
	$infile,         $outfile, @pattern,    $help, $data_type,
	$phenothpeTable, $debug,   @phenotypes, $cutOff
);

Getopt::Long::GetOptions(
	"-array_values=s"   => \$infile,
	"-outfile=s"        => \$outfile,
	"-p4cS=s{,}"        => \@pattern,
	"-help"             => \$help,
	"-phenotypeTable=s" => \$phenothpeTable,
	'-data_type=s'      => \$data_type,
	"-p_value=s"        => \$cutOff,
	"-phenotypes=s{,}"  => \@phenotypes,
	"-debug"            => \$debug
) or die &helpString();

die &helpString()
  unless ( defined $infile && defined $outfile && defined $phenothpeTable );

die &helpString() if ($help);

warn "we got these patterns 4 column search: '"
  . join( "', '", @pattern ) . "'\n";

sub helpString {
	return "
 command line switches for batchStatistics.pl:
 
   -array_values   :the table file containing the expresion values (tab separated)
   -phenotypeTable :the table containing the phenotypic data set (tab separated)
   -phenotypes     :a semicolon separated list of wanted phenotypes (included in the phenotypeTable!)
#   -p_value        :the max p value for the reported test statistics
   -outfile        :the name of the outfile (<tab> separated table)
#   -p4cS           :the pattern to select the data containing columns
   -data_type      :default 'non_parametric' optional 'parametric' (only implemented for two group comparisons)
 
   -help           :print this help
   -debug          :verbose output
 "
}

my ($task_description);
unless ( defined $data_type ) {
	$data_type = 'non_parametric';
}
$task_description .= 'batchStatistics_v2.pl';

#$task_description .= " -array_values $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= ' -p4cS "' . join( '" "', @pattern ) . '"'
  if ( defined $pattern[0] );
$task_description .= " -phenotypeTable $phenothpeTable"
  if ( defined $phenothpeTable );
$task_description .= " -data_type $data_type";

#$task_description .= " -p_value $cutOff" if (defined $cutOff);
$task_description .= ' -phenotypes \'' . join( "' '", @phenotypes ) . "'"
  if ( defined $phenotypes[0] );

## Logs will be included in the tar result file!

my @outfile = split( "/", $outfile );
$outfile = pop(@outfile);

my $outPath = join( "/", @outfile );
mkdir($outPath) unless ( -d $outPath );

my $statistics = stefans_libs_array_analysis_table_based_statistics->new();
$statistics->{'Do_not_run_automatic'} =
  0;                                ## I do not want to bother with the R RUN
$statistics->Path($outPath);

my @result_files = $statistics->GetStatProjects(
	{
		'data_table'     => $infile,
		'grouping_table' => $phenothpeTable,
		'execution_log'  => $task_description . " -array_values $infile",
		'data_type'      => $data_type,
		'phenotypes'     => \@phenotypes
	}
);

print root::get_hashEntries_as_string ( \@result_files, 3,
	"The result data should be in the files " );

