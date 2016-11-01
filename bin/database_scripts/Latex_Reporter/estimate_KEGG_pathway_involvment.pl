#! /usr/bin/perl -w

#  Copyright (C) 2010-08-17 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 estimate_KEGG_pathway_involvment.pl

The script needs to get two expression_net_statistic logs. It will use the KEGG information from the experiment log file and the control log file to estimate the p value, that the involvment of a KEGG pathway in the expression net is random.

To get further help use 'estimate_KEGG_pathway_involvment.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::expression_net_reader;
use stefans_libs::statistics::new_histogram;
use stefans_libs::histogram_container;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help, $debug, $database, $experiment_log, $control_log, $no_pdf,
	$outpath, $min_genes_in_pathway, $outfile
);
my $min_gene_hits = 0;

Getopt::Long::GetOptions(
	"-experiment_log=s" => \$experiment_log,
	"-control_log=s"    => \$control_log,
	"-outpath=s"        => \$outpath,
	"-outfile=s"        => \$outfile,
	"-min_genes_in_pathway=s" => \$min_genes_in_pathway,
	"-no_pdf"           => \$no_pdf,
	"-help"             => \$help,
	"-debug"            => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $experiment_log ) {
	$error .= "the cmd line switch -experiment_log is undefined!\n";
}
unless ( -f $control_log ) {
	$error .= "the cmd line switch -control_log is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	mkdir($outpath);
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
$min_genes_in_pathway = 0 unless ( defined $min_genes_in_pathway);

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for estimate_KEGG_pathway_involvment.pl

   -experiment_log  :the expression_net log file for the experimental connection net
   -control_log     :the expression_net log file for the negative control connection nets
   
   -no_pdf  :if set, we will not create the pdf output - 
             useful to find some errors in the script
             
   -min_genes_in_pathway: you can exclude pathways that show less than this value of 
                          genes in the real dataset (default = 0)
                          
   -outpath :an outpath to store the pdf in
   -outfile :the name of the pdf file

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'estimate_KEGG_pathway_involvment.pl';
$task_description .= " -experiment_log $experiment_log"
  if ( defined $experiment_log );
$task_description .= " -control_log $control_log" if ( defined $control_log );
$task_description .= " -outpath $outpath"         if ( defined $outpath );
$task_description .= " -outfile $outfile"         if ( defined $outfile );

$outfile =~ s/\.tex//;
$outfile .= "minGeneHit_$min_gene_hits";
## Do whatever you want!
my ( $real_gene_list, $control_data, $real_data, @var_names,
	$expression_net_reader, $data, $value, $number, $amount_of_tests );

$expression_net_reader = expression_net_reader->new();
$real_data             = $expression_net_reader->read_LogFile($experiment_log);
$control_data          = $expression_net_reader->read_LogFile($control_log);

( $data, $real_gene_list ) = &populate_data_structure($data);

#print root::get_hashEntries_as_string ( $data, 3, "the control dataset" );
#&create_var_plots();
print "we got the real gene list as '$real_gene_list'\n";
my $data_table = data_table->new();
$data_table->Add_2_Header('KEGG Pathway name');
$data_table->Add_2_Header('matched genes');
$data_table->Add_2_Header('estimated p value');
$data_table->Add_2_Header('number');
$amount_of_tests = 0;

foreach my $var_name (@var_names) {
	print "we estimate the p_value for variable '$var_name'\n";
	next unless ( defined  $real_data->{$real_gene_list}->{$var_name});
	next if ( $real_data->{$real_gene_list}->{$var_name} < $min_genes_in_pathway);
	($value, $number) = &estimated_p_value( $real_data->{$real_gene_list}->{$var_name}, $data->{$var_name}, "higher" );
	$amount_of_tests ++;
	$var_name =~ m/KEGG_(.*)/;
	$data_table->Add_Dataset(
		{
			'KEGG Pathway name'                => $1,
			'matched genes' => $real_data->{$real_gene_list}->{$var_name},
			'estimated p value' => $value,
			'number' => $number
		}
	);
	print "$1: $value\n";
}
$outfile = "$outfile.tex" unless ( $outfile =~ m/\.tex$/ );
my $tex_file = &_tex_file("$outpath/$outfile");
$tex_file =~
  s/##TITLE##/KEGG pathway involvment in the experimental expression net/;

$data_table = $data_table->Sort_by([ ['number', 'numeric' ], ['matched genes', 'antiNumeric'] ]);
$data_table->define_subset('printable', ['KEGG Pathway name', 'matched genes', 'estimated p value']);

my $corrected_p_value = 0.05 / $amount_of_tests;
$corrected_p_value = sprintf( '%.1e',  $corrected_p_value);
if ( $corrected_p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$corrected_p_value = "\$$1e^{-$2}\$";
}
my $corrected_p_value_1 = 0.01 / $amount_of_tests;
$corrected_p_value_1 = sprintf( '%.1e',  $corrected_p_value_1);
if ( $corrected_p_value_1 =~ m/([\.\d]+)e-(\d+)/ ) {
			$corrected_p_value_1 = "\$$1e^{-$2}\$";
}
my $text = "\\section{Introduction}

The genes, that were identified using the experimental expression net did overlap with several KEGG pathways.
In order to tell which pathways did contain more genes than expected by chance, I have created "
  . scalar( keys %$control_data )
  . " control expression nets and counted the amount of genes identified with the random nets for each of the KEGG pathways.
Using these the distribution of these values, I could estimate the p value, that a KEGG pathway was identifed by pure chance.
The values are summed up in the following table.\n";
 $text .= " To reduce the amount of these tests, I have restricted the tests to pathways where we did identify at least $min_gene_hits genes.\n" if ($min_gene_hits > 1 );
 $text .= " Keep in mind, that we did $amount_of_tests tests and the corrected p_values would be $corrected_p_value (0.05) and $corrected_p_value_1 (0.01).
 
" . $data_table->AsLatexLongtable('printable');
$text =~ s/_/\\_/g;

$tex_file =~ s/### DATA ##/$text\n/;

open( OUT, ">$outpath/$outfile" );
print OUT $tex_file;
close(OUT);

$outfile =~ s/\.tex$//;
open( MAKE, ">$outpath/makefile" )
  or die "could not create the LaTeX makefile\n";
print MAKE "all:
\tpdflatex $outfile.tex
\tpdflatex $outfile.tex
\tpdflatex $outfile.tex
\trm $outfile.aux
\trm $outfile.out
\trm $outfile.toc
\trm $outfile.log
";


unless ($no_pdf) {
	chdir($outpath);
	system("make");
	print "the output is there: $outpath/$outfile.pdf\n";
}
else {
	print "you can create a pdf file from the tex source $outpath/$outfile.tex";
}

sub estimated_p_value {
	my ( $value, $list, $mode ) = @_;
	my ( @temp, $p_value, $number );
	warn "the dataset is empty!\n" unless ( @$list > 0 );
	warn "we have a missing value in the data array\n"
	  if ( !defined @$list[0] );
	Carp::confess("please fix that - the \$value was not defined!\n")
	  unless ( defined $value );
	@temp = ( sort { $a <=> $b } @$list );
	if ( $mode eq "higher" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( $temp[$i] >= $value ) {
				$p_value = ( scalar(@temp) - $i ) / scalar(@temp);
				last;
			}
		}
		$p_value = 1 / scalar(@temp)
		  unless ( defined $p_value );
		$p_value = 1 / scalar(@temp) if ( $p_value == 0 );
		$number = $p_value;
		$p_value = sprintf( '%.1e', $p_value );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value, $number;
	}
	if ( $mode eq "lower" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( $temp[$i] >= $value ) {
				$p_value = 1 - ( scalar(@temp) - $i ) / scalar(@temp);
				last;
			}
		}
		$p_value = 1 / scalar(@temp)
		  unless ( defined $p_value );
		$p_value = 1 / scalar(@temp) if ( $p_value == 0 );
		$number = $p_value;
		$p_value = sprintf( '%.1e', $p_value );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value, $number;
	}
	if ( $mode eq "both" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( !defined $temp[$i] ) {
				warn "we do not have an entry for the dataset at pos $i!\n";
			}
			if ( $temp[$i] >= $value ) {
				$p_value = ( scalar(@temp) - $i ) / scalar(@temp);
				last;
			}
		}
		$p_value = 1 - $p_value if ( $p_value > 0.5 );
		$p_value = 1 / scalar(@temp)
		  unless ( defined $p_value );
		$p_value = 1 / scalar(@temp) if ( $p_value == 0 );
		$number = $p_value;
		$p_value = sprintf( '%.1e', $p_value * 2 );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value, $number;
	}
	Carp::confess(
		"Sorry, but we only support the modes higher, lower or both\n");
}

sub create_var_plots {

	my ( $var_name, $max, $x_title, $bar_count, $temp, $new_histogram );
	$bar_count = 30;
	foreach $var_name (@var_names) {
		print "\nwe wil create the plot for the data structure '$var_name'\n";
		$max = 0;
		foreach my $val ( @{ $data->{$var_name} } ) {
			$max = $val if ( $val > $max );
		}
		$x_title = $var_name;
		$x_title =~ s/^KEGG_//;

		print "We will plot '$bar_count' potential bars in the histogram!\n"
		  if ($debug);

		my $new_histogram = histogram_container->new();
		Carp::confess("we have no data for the var $var_name!")
		  if ( scalar( @{ $data->{$var_name} } ) == 0 );
		$new_histogram->CreateHistogram( 'all', $data->{$var_name}, undef,
			$bar_count );

		if ( ref($new_histogram) eq 'histogram_container' ) {
			foreach my $var_names ( sort keys %$data ) {
				if ( $var_names =~ m/^$var_name ([\w\d\s]+)/ ) {
					if ( scalar( @{ $data->{$var_names} } ) == 0 ) {
						warn "we have no data for the var $var_names!";
						next;
					}
					$new_histogram->CreateHistogram( $1, $data->{$var_names},
						undef, $bar_count );
				}
			}
		}
		## Mark the experimental value
		$new_histogram->Mark_position(
			$real_data->{$real_gene_list}->{$var_name} );
		$temp = $_;
		$var_name =~ s/_/-/g;
		$new_histogram->plot(
			{
				'outfile' => $outpath . "/"
				  . join( "_", split( " ", $var_name ) ) . ".svg",
				'x_resolution' => 600,
				'y_resolution' => 400,
				'x_title'      => $x_title
			}
		);
		system( "trimPictures.pl " 
			  . $outpath . "/"
			  . join( "_", split( " ", $var_name ) ) . ".svg "
			  . $outpath . "/"
			  . join( "_", split( " ", $var_name ) )
			  . ".png" );
		$new_histogram = undef;
	}
}

sub populate_data_structure {
	my ($data) = @_;
	my ( $kegg_pathways, $var_name, $seen_vars );

## init potentially missing vars in the real dataset
	($real_gene_list) = ( keys %$real_data );
	foreach $var_name ( keys %{ $real_data->{$real_gene_list} } ) {
		if ( $var_name =~ m/^KEGG_/ ) {
			print "we got a KEGG entry: $var_name\n";
			push( @var_names, $var_name ) if ($real_data->{$real_gene_list}->{$var_name} > $min_gene_hits );
		}
	}
	unless ( scalar(@var_names) > 0 ) {
		Carp::confess(
"Sorry, but the experimental log file did not contain information about the KEGG pathway hits!"
		);
	}
	foreach $var_name (@var_names) {
		$data->{$var_name} = [];
	}

## populate the variable store
	foreach my $gene_list ( keys %$control_data ) {
		foreach $var_name (@var_names) {
			$control_data->{$gene_list}->{$var_name} = 0
			  unless ( defined $control_data->{$gene_list}->{$var_name} );
			push(
				@{ $data->{$var_name} },
				$control_data->{$gene_list}->{$var_name}
			);
		}
	}
	foreach my $gene_list ( keys %$control_data ) {
		foreach $var_name (@var_names) {
			if ( scalar( @{ $data->{$var_name} } ) > 0 ) {
				print "we have "
				  . scalar( @{ $data->{$var_name} } )
				  . " data points for variable $var_name\n";
			}
		}
		last;
	}
	return  $data, $real_gene_list ;
}

sub _tex_file {
	my ($tex_skeleton) = @_;
	$tex_skeleton |= '';
	if ( -f $tex_skeleton ) {
		my $str = '';
		open( IN, "<$tex_skeleton" )
		  or die "could not open tex file '$tex_skeleton'\n";
		while (<IN>) {
			$str .= $_;
		}
		close(IN);
		if (   $str =~ m/##INTRODUCTION##/
			&& $str =~ m/##GENE GROUPS##/
			&& $str =~ m/##SPECIAL GENES##/
			&& $str =~ m/##EXPRESSION-NET-FIGURE##/
			&& $str =~ m/##GENE DESCRIPTION##/
			&& $str =~ m/##APPENDIX##/ )
		{
			## OK this sceleton is usable!
			return $str;
		}
		else {
			warn
"The tex sceleton $tex_skeleton does not contain the necessary tags - I will use the inbuilt tex template!\n";
		}
	}

	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ ##TITLE## }
\author{Stefan Lang}\\
\date{' . root->Today() . '}
\maketitle

### DATA ##

\bibliographystyle{plain}
\bibliography{library}

\end{document}
';
}
