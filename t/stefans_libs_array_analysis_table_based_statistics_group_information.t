#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::array_analysis::table_based_statistics::group_information' }
use stefans_libs::flexible_data_structures::data_table;

my ( $value, @values, $exp );
my $stefans_libs_array_analysis_table_based_statistics_group_information = stefans_libs_array_analysis_table_based_statistics_group_information -> new();
is_deeply ( ref($stefans_libs_array_analysis_table_based_statistics_group_information) , 'stefans_libs_array_analysis_table_based_statistics_group_information', 'simple test of function stefans_libs_array_analysis_table_based_statistics_group_information -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

my $path = "/home/stefan/tmp/simply_remove";
my $data_table = data_table->new();
foreach ( "Probe Set ID", qw(A B C D E F G H) ){
	$data_table -> Add_2_Header ( $_ ) ;
}

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
	"Probe Set ID" => 'spearman',
	'A' => 1.2, 
	'B' => 2,
	'C' => 3.5,
	'D' => 4,
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
$stefans_libs_array_analysis_table_based_statistics_group_information-> AddFile($path.'/groups.xls');
is_deeply( $stefans_libs_array_analysis_table_based_statistics_group_information-> GetGroups, &return_GetGroups_dataset, 'GetGroups');

use stefans_libs::Latex_Document;
my $document = stefans_libs::Latex_Document->new( );
$document ->UsePackage('{multirow}');
my $section = $document ->Section( 'Appendix', 'app');
$section -> AddText ( "Have I messed around with äöü&_?\n");
$value = $stefans_libs_array_analysis_table_based_statistics_group_information->As_LaTex_section ( {
	'latex_section' => $section, 
	'section_title' => 'Sample Groupings',
	'section_label' => 'test:descr'
});
$value = $value->AsString();
$value =~s/sec::\d\d\d?\d?/sec::1111/g;
is_deeply ( [split("\n",$value)], [&get_section_text()] ,"the right section text" );

if ( -f $ARGV[0] ){
	## WOW use this mdulte to analyze a file is also cool!
	$stefans_libs_array_analysis_table_based_statistics_group_information = stefans_libs_array_analysis_table_based_statistics_group_information -> new();
	$stefans_libs_array_analysis_table_based_statistics_group_information -> AddFile ( $ARGV[0] );
	print "\$groupings = ".root->print_perl_var_def($stefans_libs_array_analysis_table_based_statistics_group_information->GetGroups()).";\n";
	$document = stefans_libs::Latex_Document->new( );
$document ->UsePackage('{multirow}');
$section = $document ->Section( 'Appendix', 'app');
$section -> AddText ( "Have I messed around with äöü&_?\n");
$value = $stefans_libs_array_analysis_table_based_statistics_group_information->As_LaTex_section ( {
	'latex_section' => $section, 
	'section_title' => 'Sample Groupings',
	'section_label' => 'test:descr'
});
print "\$section = ".root->print_perl_var_def($value->AsString()).";\n";

}
#$document -> Outpath ( '/home/stefan/tmp/' );
#$document -> write_tex_file ('short_test.tex');

#print "\$exp = ".root->print_perl_var_def($value->AsString() ).";\n";





#print "\$exp = ".root->print_perl_var_def($value ).";\n";







sub return_GetGroups_dataset{
	return  {
  'Kruskal Wallis' => {
  'groups' => {
  'c' => [ 'D', 'E' ],
  'a' => [ 'A', 'B' ],
  'b' => [ 'F', 'G' ]
},
  'stat_type' => 'groups'
},
  'spearman' => {
  'groups' => {
  '6' => [ 'F' ],
  '4' => [ 'D' ],
  '6.9' => [ 'G' ],
  '3.5' => [ 'C' ],
  '1.2' => [ 'A' ],
  '8.1' => [ 'H' ],
  '2' => [ 'B' ],
  '5' => [ 'E' ]
},
  'stat_type' => 'linear'
},
  'Wilcox' => {
  'groups' => {
  'a' => [ 'A', 'B', 'C', 'D' ],
  'b' => [ 'E', 'F', 'G', 'H' ]
},
  'stat_type' => 'groups'
}
};
}

sub get_section_text {
	return split( "\n", '\section{Sample Groupings}
\label{test:descr}
the following subsectiond contain a detailed description table for each sample grouping, that has been used in this document.

\subsection{Kruskal Wallis}
\label{sec::1111}
The group \'Kruskal Wallis\' has been analyzed using a Kruskal-Wallis test.

\begin{tabular}{|c|c|}
\hline
Group tag & sample id\\\\
\hline
\multirow{2}{*}{a}  & A \\\\
 & B \\\\
\hline
\multirow{2}{*}{b}  & F \\\\
 & G \\\\
\hline
\multirow{2}{*}{c}  & D \\\\
 & E \\\\
\hline
\end{tabular}


\subsection{spearman}
\label{sec::1111}
The group \'spearman\' has been analyzed using a Spearman Signed rank linear correlation.

\begin{tabular}{|c|c|}
\hline
Group tag & sample id\\\\
\hline
1.2  & A \\\\
\hline
2  & B \\\\
\hline
3.5  & C \\\\
\hline
4  & D \\\\
\hline
5  & E \\\\
\hline
6  & F \\\\
\hline
6.9  & G \\\\
\hline
8.1  & H \\\\
\hline
\end{tabular}


\subsection{Wilcox}
\label{sec::1111}
The group \'Wilcox\' has been analyzed using a two-sample Wilcoxon or Mann-Whitney two group test.

\begin{tabular}{|c|c|}
\hline
Group tag & sample id\\\\
\hline
\multirow{4}{*}{a}  & A \\\\
 & B \\\\
 & C \\\\
 & D \\\\
\hline
\multirow{4}{*}{b}  & E \\\\
 & F \\\\
 & G \\\\
 & H \\\\
\hline
\end{tabular}


\clearpage
' );
}
