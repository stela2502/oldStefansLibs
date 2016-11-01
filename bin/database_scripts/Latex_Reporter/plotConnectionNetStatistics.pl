#! /usr/bin/perl -w

#  Copyright (C) 2010-06-23 Stefan Lang

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

=head1 plotConnectionNetStatistics.pl

A script to compare connection net statistics values for a experimental net and a set of control nets. It is expected, that you give two sets of statistical log files.

To get further help use 'plotConnectionNetStatistics.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::expression_net_reader;
use stefans_libs::statistics::new_histogram;
use stefans_libs::histogram_container;
use stefans_libs::plot::simpleBarGraph;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,                  $debug,                  $database,
	$experiment_statistics, $control_connection_net, $R_cutoff,
	$seeder_gene_count,     $repetitions,            $bar_count,
	$outpath,               $no_pdf,                 @otherCorrelationFiles,
	$max_random_genes,      $organism_tag,           $fixed_control_netorks
);

Getopt::Long::GetOptions(
	"-experiment_statistics=s"         => \$experiment_statistics,
	"-fixed_control_netorks=s"         => \$fixed_control_netorks,
	"-control_connection_net=s"        => \$control_connection_net,
	"-R_cutoff=s"                      => \$R_cutoff,
	"-seeder_gene_count=s"             => \$seeder_gene_count,
	"-repetitions=s"                   => \$repetitions,
	"-further_correlatio_results=s{,}" => \@otherCorrelationFiles,
	"-outpath=s"                       => \$outpath,
	"-bar_count=s"                     => \$bar_count,
	"-max_random_genes=s"              => \$max_random_genes,
	"-no_pdf"                          => \$no_pdf,
	"-KEGG_organism_tag=s"             => \$organism_tag,
	"-help"                            => \$help,
	"-debug"                           => \$debug
);

my $warn  = '';
my $error = '';

if ( defined $max_random_genes ) {
	warn "You should not restrict the reandom genes to a certain number!\n";
}

unless ( -f $experiment_statistics ) {
	$experiment_statistics |= '';
	$error .=
"I can not read the file -experiment_statistics ($experiment_statistics)!\n";
}
if ( -f $fixed_control_netorks ) {
	## We use a predefined expression network to plot it!
}
else {
	unless ( -f $control_connection_net ) {
		$control_connection_net |= '';
		$error .=
"I can not read the file -control_connection_net ($control_connection_net)!\n";
	}
	unless ( defined $R_cutoff ) {
		$error .= "the cmd line switch -R_cutoff is undefined!\n";
	}
	unless ( defined $repetitions ) {
		$error .= "the cmd line switch -repetitions is undefined!\n";
	}
	elsif ( $repetitions / 10 < 2 ) {
		unless ( -f "$outpath/expression_net_statistcs.txt" ) {
			$error .=
" we need at least 20 repetitions to built up something like a negative distribution!\n";
		}
	}
	elsif ( $repetitions / 10 < 10 ) {
		unless ( -f "$outpath/expression_net_statistcs.txt" ) {
			warn
"\n\nit would be better if you would craete more than 100 repetitions, as we want to get a usefull distribution - or?\n\n";
		}
	}
}

unless ( defined $seeder_gene_count ) {
	$error .= "the cmd line switch -seeder_gene_count is undefined!\n";
}

unless ($bar_count) {
	$bar_count = 10;
}

unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	qx( mkdir -p $outpath );
}

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
 command line switches for plotConnectionNetStatistics.pl

   -experiment_statistics :the experiment connection net statistics file
   -seeder_gene_count     :how many genes built up the experimental connection net
   
   ## creating a control set of coexpression networks
   -control_connection_net       
                :the file containing the control co-expression data
   -R_cutoff    :how many gene gene correlations should we use from the 
                 expression_net (0.7 too many; 0.75 still too many; 0.8 OK; >0.8 untested)
   -repetitions :how many times should i randomly draw from the expression net
   
   ## using a precalculated co-expression network instead of the calculated one
   -fixed_control_netorks :A co-expression network statistics file like the one
   						   used for in the experiment_statistics option
   ##
   
   -outpath     :the path to put the pictures, the tex and makefile to
   -bar_count   :the amount of bars to show in the histograms (default 10)
   -no_pdf      :if set, we will not create the pdf output - useful to find some errors in the script
   
   -max_random_genes :this option should not be used, but you could reduce the number 
                      of initial random genes to choose from for the connection net 
                      calculation - but using as many as possible would be good!
   -further_correlatio_results
                      :other correlation result files that are 
                       created using the batchStatistics.pl script 
                       FROM that gene to other genes
   -KEGG_organism_tag :an optional organism_tag that will add the amount of hits 
                       to all KEGG pathways in the database to the expression_net_statistics_log file
                       This data could be used to identify those KEGG pathways that were hit more 
                       frequently than expected by chance!
                       
   -help  :print this help
   -debug :verbose output
   

";
}

my ($task_description);

$task_description .= 'plotConnectionNetStatistics.pl';
$task_description .= " -experiment_statistics $experiment_statistics"
  if ( defined $experiment_statistics );
$task_description .= " -control_connection_net $control_connection_net"
  if ( defined $control_connection_net );
$task_description .= " -R_cutoff $R_cutoff" if ( defined $R_cutoff );
$task_description .= " -seeder_gene_count $seeder_gene_count"
  if ( defined $seeder_gene_count );
$task_description .= " -repetitions $repetitions" if ( defined $repetitions );
$task_description .= " -outpath $outpath"         if ( defined $outpath );
$task_description .= " -bar_count $bar_count";
$task_description .=
  " -further_correlatio_results '" . join( "' '", @otherCorrelationFiles ) . "'"
  if ( defined $otherCorrelationFiles[0] );
$task_description .= " -KEGG_organism_tag $organism_tag"
  if ( defined $organism_tag );

## set up the normalization
my (
	$do_not_mark_value, @additional_figure_descriptions,
	$normalizing_var,   @normalized_vars,
	$normalized_vars,   @var_names,
	$var_name,          @reference_genes,
	@path,              $genes_4_bar_graph,
	$str_normalized,    $str_orig
);

#&Setup();

## read the connection net to get the random seeder gene names

open( LOG, ">$outpath/plotConnectionNetStatistics.log" )
  or die "could not open the logfile!\n";
print LOG $task_description . "\n";
close(LOG);

my ( $expression_net_reader, $restricted_expression_net, $gene_names, @line,
	@gene_names_array, $temp, $ok, $selected_genes, $cmd, $gene_name );

$expression_net_reader = expression_net_reader->new();
## which genes have been analyzed?
print "Opening the control connection net\n";
STDOUT->autoflush();
unless ( -f $fixed_control_netorks){
open( IN, "<$control_connection_net" )
  or die
  "could not open the control connection net '$control_connection_net'!\n";
$temp = 0;
while (<IN>) {
	next if ( $_ =~ m/^#/ );
	$temp++;
	print "-" if ( $temp % 10000 == 0 );
	@line = split( "\t", $_ );
	( $gene_name, $ok ) =
	  $expression_net_reader->__get_gene_symbol( $line[0], "12345" );
	$gene_names->{$gene_name} = 0 unless ( defined $gene_names->{$gene_name} );
	$gene_names->{$gene_name}++;
}
close(IN);
print "\ndone\n";

## I need the real gene names!
@gene_names_array = ( keys %$gene_names );
for ( my $i = 0 ; $i < @gene_names_array ; $i++ ) {
	( $gene_names_array[$i], $temp ) =
	  $expression_net_reader->__get_gene_symbol( $gene_names_array[$i], '---' );
}

## calculate the expression nets - if you want some!
&create_random_expression_net_statistics() if ( $repetitions > 0 );
$fixed_control_netorks = "$outpath/expression_net_statistcs.txt";
}

## we now should have a lot of connection net statistics in the file $outpath/expression_net_statistcs.txt

my $control_data =
  $expression_net_reader->read_LogFile ( $fixed_control_netorks );

my $real_data = $expression_net_reader->read_LogFile($experiment_statistics);

die "Sorry, but I can only handle one real data statistical result, not the "
  . scalar( keys %$real_data )
  . " that you gave me!\n"
  if ( scalar( keys %$real_data ) > 1 );

#($real_data) = values %$real_data;

## now I need to get the data!
my ( $max, $x_title, $data, $p_values, $real_gene_list );

&Setup();
( $data, $real_data ) = &populate_data_structure( $data, $real_data );

## we could now create some smaller lists - to highlight some other variable set!
#&define_subGroups();
&define_subGroup_links();

my ($label);
my $str = &add_Introduction();
$str .= &add_results_section();

my $add_2_figure_section = &estimate_all_p_values();

## add the experimental value to get the right scale for the x axis
foreach $var_name (@var_names) {
	next if ( $do_not_mark_value->{$var_name} );
	unless ( $normalized_vars->{$var_name} ) {
		push(
			@{ $data->{$var_name} },
			$real_data->{$real_gene_list}->{$var_name}
		);
	}
	else {
		push(
			@{ $data->{$var_name} },
			&compute(
				$real_data->{$real_gene_list}->{$var_name},
				$real_data->{$real_gene_list}->{$normalizing_var}
			)
		);
	}
}

## create the figures
&create_var_plots();

## create a pdf including the informations

$str .= &create_LaTeX_figure( $str_normalized, $str_orig, \@var_names, $data );
$str .= $add_2_figure_section;
$str .= &createMethods();

my $LatextStr = &_tex_file();
$LatextStr =~
s/##TITLE##/Estimating the probability, that the connection net reports important coregulated genes/;
$LatextStr =~ s/### DATA ##/$str/;

open( LATEX, ">$outpath/Summary.tex" )
  or die "could not craete the latex file $outpath/Summary.tex\n";
print LATEX $LatextStr;
close(LATEX);

#create the bib
open( BIB, ">$outpath/library.bib" ) or die "could not write the library!\n";
print BIB &get_lib_str();
close(BIB);

# create the makefile

open( MAKE, ">$outpath/makefile" )
  or die "could not create the LaTeX makefile\n";
print MAKE "all:
\tpdflatex Summary.tex
\tbibtex Summary
\tpdflatex Summary.tex
\tbibtex Summary
\tpdflatex Summary.tex
\trm Summary.aux
\trm Summary.out
\trm Summary.toc
\trm Summary.bbl
\trm Summary.blg
";
unless ($no_pdf) {
	chdir($outpath);
	system("make");
}
print "the output is there: $outpath/Summary.pdf\n";

##DONE!!

sub add_Introduction {
	return "\\section{Introduction}\n\n"
	  . "This PDF is created to estimate the probability, that a given connection 
net was identified based on pure chance or if the connection net contains describes genes, that are co-expressed due to a coregulation in the cell.
As this information will definitifely depend on the choosen R\$^2\$ value, you should set up this process multipe times.\n";
}

sub add_results_section {

  #die root::get_hashEntries_as_string ($data, 3, "is the data string empty? ");
	my $str = "\\section{R\$^2\$ = $R_cutoff, n = "
	  . ( scalar( @{ $data->{'overall genes'} } ) - 1 ) . "}\n";
	$str .=
"\nThis analysis is based on a conection net file containing the correlations 
for " . scalar(@gene_names_array) . " random seeder genes.
To estimate the null distribution we have pulled "
	  . ( scalar( @{ $data->{'overall genes'} } ) - 1 )
	  . " times a random set of $seeder_gene_count 
"
	  . "seeder genes from the dataset and created a connection net with these genes.\n\n";
	$str .=
"To characterize the connection nets, we have counted the overall amount of genes "
	  . "
that correlate with any seeder gene, the amount of connection groups, that were created and the amount of genes in the connection groups.
As the later two values should be dependant on the amount of genes, that do correlate with either of the seeder genes, the values,
that will be used to estimte the importance of the real connection net will be depiced as fration of the overall genes.\n\n";

	$label = "fig-$R_cutoff-$seeder_gene_count-"
	  . ( scalar( @{ $data->{'overall genes'} } ) - 1 );
	$str .= "The data is shown in figure \\ref{$label}\n";
	return $str;
}

sub estimate_all_p_values {
## estimte the p values
	my ( $extension, $temp, $short_var_name, $var_key );
	foreach $var_name ( keys %$data ) {
		$extension = '';
		$p_values->{$var_name} = 'n.d.';
		## see if we should normalize the referece data point
		$temp = 0;
		foreach $short_var_name ( keys %$normalized_vars ) {
			if ( $var_name =~ m/^$short_var_name (.*)/ ) {
				$temp = 1;
			}
			if ( $short_var_name eq $var_name ) {
				$temp = 1;
			}
		}
		foreach $short_var_name (@var_names) {
			if ( $var_name =~ m/^$short_var_name (.*)/ ) {
				## we have a subgroup!
				$var_name  = $short_var_name;
				$extension = $1;
				last;
			}
		}
		next
		  if ( $do_not_mark_value->{$var_name} )
		  ;    ## the real dataset is not in the same scale was the random data
		unless ($temp) {    ## not to be normalized
			unless ($extension) {    ## and no problem with sub-groups
				$p_values->{$var_name} =
				  estimated_p_value( $real_data->{$real_gene_list}->{$var_name},
					$data->{$var_name}, 'both', $var_name );
			}
			else {

				#print "we try to get a p-value for $var_name $extension!\n";
				$p_values->{"$var_name $extension"} = estimated_p_value(
					$real_data->{$real_gene_list}->{$var_name},
					$data->{"$var_name $extension"},
					'both', "$var_name $extension"
				);

			  #print "\tand we got ". $p_values->{"$var_name $extension"} ."\n";
			}
		}
		else {    ## OK - please normalize
			unless ($extension) {    ## but no problem with sub-groups
				$p_values->{$var_name} = estimated_p_value(
					&compute(
						$real_data->{$real_gene_list}->{$var_name},
						$real_data->{$real_gene_list}->{$normalizing_var}
					),
					$data->{$var_name},
					'both',
					$var_name
				);
			}
			else {                   ## ok with sub-groups :-(
				$p_values->{"$var_name $extension"} = estimated_p_value(
					&compute(
						$real_data->{$real_gene_list}->{$var_name},
						$real_data->{$real_gene_list}->{$normalizing_var}
					),
					$data->{"$var_name $extension"},
					'both',
					"$var_name $extension"
				);
			}
		}
	}
	my $add_2_figure_section = "\n\n"
	  . '\begin{table}' . "\n"
	  . "\\caption{ All estimated p values for R\$^2\$ $R_cutoff and "
	  . ( scalar( @{ $data->{'overall genes'} } ) )
	  . " permutations. Also look at figure \\ref{$label} } \n"
	  . "\\label{p:values:$label}\n"
	  . "\\centering\n"
	  . '\begin{longtable}[hpbt]{|c|c|}' . "\n"
	  . '\hline' . "\n";
	$add_2_figure_section .= "var name & p value \\\\\n" . '\hline' . "\n";
	foreach $var_name ( sort keys %$data ) {
		$var_key = $var_name;
		$var_name =~ s/_/-/g;
		$add_2_figure_section .= "$var_name & $p_values->{$var_key}\\\\\n";
	}
	$add_2_figure_section .= '\hline' . "\n";
	$add_2_figure_section .= "\\end{longtable}\n\\end{table}\n\n";
	print $add_2_figure_section;
	return $add_2_figure_section;
}

sub create_LaTeX_figure {

	## I want to create several Latex figures, as with the many comparisons I do here
	## the simple old version did no longer create a usable figure!
	## I need to split the connection net statistics from the Phenotype correlation statistics!
	## And that is quite important!
	## 1. get the var_names, that are for the Phenotypes:
	my $str = '';
	my ( $number_of_connection_net_vars, $phenotypes_hash,
		@phenotype_var_names );
	@phenotype_var_names = &AdditionalPhenotypes();
	foreach (@phenotype_var_names) {
		$_ =~ s/_/-/g;
		$phenotypes_hash->{$_} = 1;
	}
	$number_of_connection_net_vars =
	  scalar(@var_names) - scalar(@phenotype_var_names);
	if ( -f "$outpath/gene_usage_distribution.png" ) {
		push( @var_names, "gene usage distribution" );
		$str_orig->{"gene usage distribution"} =
"the distribution of the amount of random connection nets, that contains a specific gene";
	}
	my @connection_net_vars;
	foreach (@var_names) {
		push( @connection_net_vars, $_ ) unless ( $phenotypes_hash->{$_} );
	}

#Carp::confess ( root::get_hashEntries_as_string ( {'@connection_net_vars' => [@connection_net_vars], 'phenotype_hash' => $phenotypes_hash }, 3, "we have these two datasets - why do we have so manny vars in \@connection_net_vars? "));
	$str =
	  &create_figureStr_using_these_vars(
		&__get_connection_net_caption(@connection_net_vars),
		@connection_net_vars );
	$number_of_connection_net_vars = 0;
	@connection_net_vars           = ();
	my @temp = sort (@phenotype_var_names);
	@phenotype_var_names = @temp;
	for ( my $i = 0 ; $i < @phenotype_var_names ; $i++ ) {
		if ( $i == 0 ) {
			$number_of_connection_net_vars++;
		}
		elsif ( $i % 6 == 0 ) {
			$str .=
			  &create_figureStr_using_these_vars(
				&get_phenotype_caption_string(@connection_net_vars),
				@connection_net_vars );
			@connection_net_vars = ();
		}
		$connection_net_vars[@connection_net_vars] = $phenotype_var_names[$i];
	}
	if ( scalar(@connection_net_vars) > 0 ) {
		$str .=
		  &create_figureStr_using_these_vars(
			&get_phenotype_caption_string(@connection_net_vars),
			@connection_net_vars );
	}
	return $str;
}

sub get_phenotype_caption_string {
	my @var_names = @_;
	my @tic       = qw( a b c d e f g h i j k );
	my $str =
"Estimation of the infuence of the experimental co-expressed genes on of the phenotypes "
	  . join( ", ", @var_names ) . ".
	The null distribution was created using "
	  . ( scalar( @{ $data->{'overall genes'} } ) - 1 )
	  . " random co-expression anaylses.\n"
	  . "The sub figures depict the phenotypes as follows: ";
	for ( my $i = 0 ; $i < @var_names ; $i++ ) {
		$str .= "($tic[$i]) $var_names[$i]; ";
	}
	$str =~ s/_/\\_/g;
	return $str;
}

sub create_figureStr_using_these_vars {
	my ( $caption, @var_names ) = @_;
	my ( $str, $var_name, $number_of_connection_net_vars, $width, @tic, $cut );
	@tic                           = qw( a b c d e f g h i j k );
	$cut                           = 1;
	$number_of_connection_net_vars = scalar(@var_names);
	if ( $number_of_connection_net_vars % 2 == 0 ) {
		$width = 0.98 * ( 2 / $number_of_connection_net_vars );
	}
	else {
		$width = 0.98 * ( 2 / ( 1 + $number_of_connection_net_vars ) );
	}
	$str = "\n\n\\begin{figure}[htb]";
	for ( my $i = 0 ; $i < @var_names ; $i++ ) {
		$var_name = $var_names[$i];
		$var_name =~ s/_/-/g;
		$str .= "\\begin{minipage}[b]{$width\\linewidth}
	\\centering
	\\subfigure[]{
	\\includegraphics[width=\\linewidth]{"
		  . join( "_", split( /[ \.]/, $var_name ) ) . "}
	\\label{$label-$tic[$i]}
	}
	\\end{minipage}";
		if ( ( ( $i + 1 ) * $width ) / 0.97 > $cut ) {
			$str .= "\\\\\n";
			$cut++;
		}

	}
	$str .= "
\\caption{$caption} 
\\label{$label}
\\end{figure} 
";
	return $str;
}

sub __get_connection_net_caption {
	my @var_names = @_;
	my @tic       = qw( a b c d e f g h i j k );
	my $str =
" \$R^2\$: $R_cutoff; seeder genes: $seeder_gene_count; permutation count: "
	  . ( scalar( @{ $data->{'overall genes'} } ) )
	  . ". The red line marks the position of the experimental connection net . The experimental connection net shows 
	$real_data->{$real_gene_list}->{'overall links'} overall links,
	$real_data->{$real_gene_list}->{'overall genes'} overall genes,
	$real_data->{$real_gene_list}->{'genes in connection groups'} genes in connection groups and
	$real_data->{$real_gene_list}->{'connection groups'} connection groups.
	Black bars show the distribution of the "
	  . ( scalar( @{ $data->{'overall genes'} } ) - 1 )
	  . " contol connection nets"
	  . join( " ", @additional_figure_descriptions ) . ".";
	my $i = 0;
	foreach $var_name (@var_names) {
		unless ( $normalized_vars->{$var_name} ) {
			$str .= "($tic[$i])" . $str_orig->{$var_name};
			if ( defined $p_values->{$var_name} ) {
				$str .= "(p\$_{exp}\$=$p_values->{$var_name}); ";
			}
			else {
				$str .= "; ";
			}

		}
		else {
			$str .= $str_normalized->{$var_name};
			if ( defined $p_values->{$var_name} ) {
				$str .= "(p\$_{exp}\$=$p_values->{$var_name}); ";
			}
			else {
				$str .= "; ";
			}

		}
		$i++;
	}
	chop($str);
	chop($str);
	$str .=
	  ". A list of all p values can be found in table \\ref{p:values:$label}.";
	$str =~ s/_/\\_/g;
	return $str;
}

sub createMethods {
	return "
\\section{Methods}

The control connection groups were created as described for the experimental connection group.
We applied the 'Monte Carlo method' \\cite{Nicholas:Ulam:1949} to estimate p values for the described connection net.
To determine the null distribution we creating connection nets for $seeder_gene_count randomly choosen seeder genes (n="
	  . ( scalar( @{ $data->{'overall genes'} } ) - 1 ) . ").
The seeder genes were not completely randomly choosen from the whole array dataset,
but from a precalculated set of " . scalar(@gene_names_array) . " seeder genes. 
The control connection groups were created as described for the experimental connection group.

%The variables, that are depicted in the figures are: (a) the amount of gene-gene interactions, that passed the reported R\$^2\$ cutoff;
%(b) the amount of genes, that passed the R\$^2\$ cutoff. For this variable, each gene was counted only once, even if it did correlate with several seeder genes. 
%Therefore this dataset includes a measurement of the connectivity of the resulting connection-net. (c) the amount of genes in the connection groups, 
%but as this variable is dependant on the total amount of genes in (a), this variable is depicted as fration of (a). The same is true for (d) the amount of connection groups.

\\appendix

\\section{pdf creation}
";
	$task_description =~ s/_/\\_/g;
	$task_description =~ s!/!\\-/!g;
	$str .= "
The LaTeX source for this pdf was created using the command (one line!) \\\\'$task_description'.

";
}

sub populate_data_structure {
	my ( $data, $real_dataset ) = @_;
	my ($kegg_pathways);
## init potentially missing vars in the real dataset
	($real_gene_list) = ( keys %$real_data );
	$real_data->{$real_gene_list}->{'percent overlap'} = 1;

##first we need to check which variables could be used for the test!
	my @temp;
	foreach my $gene_list ( keys %$control_data ) {
		foreach $var_name (@var_names) {
			if ( $var_name =~ m/\^KEGG_/ ) {
				$control_data->{$gene_list}->{$var_name} = 0
				  unless ( defined $control_data->{$gene_list}->{$var_name} );
				print
"we have a KEGG dataset : $var_name = $control_data->{$gene_list}->{$var_name}\n";
			}
			push( @temp, $var_name )
			  if ( defined $control_data->{$gene_list}->{$var_name} );
		}
		last;
	}
	warn
"I have manually removed the vars 'seeder genes match', 'all genes match'\n";

	# @var_names = ( @temp, 'seeder genes match', 'all genes match' );
	## init the variable store
	foreach $var_name (@var_names) {
		$data->{$var_name} = [];
	}
	my $max_values = {
		'seeder genes match' => $seeder_gene_count,
		'all genes match'    => 1
	};

## populate the variable store
	foreach my $gene_list ( keys %$control_data ) {
		if ( defined $control_data->{$gene_list}->{'percent overlap'} ) {
			$control_data->{$gene_list}->{'seeder genes match'} =
			  int( $control_data->{$gene_list}->{'percent overlap'} *
				  $seeder_gene_count + 0.0001 )
			  ;    #$control_data->{$gene_list}->{'overall genes'} );#
			 #print "we have $control_data->{$gene_list}->{'seeder genes match'} genes ($control_data->{$gene_list}->{'percent overlap'} * $control_data->{$gene_list}->{'overall genes'})!\n";
		}
		if ( defined $control_data->{$gene_list}->{'percent all overlap'} ) {
			$control_data->{$gene_list}->{'all genes match'} =
			  int( $control_data->{$gene_list}->{'percent all overlap'} *
				  $control_data->{$gene_list}->{'overall genes'} );
		}
		foreach $temp ( split( ";", $gene_list ) ) {
			$genes_4_bar_graph->{$temp} = { 'y' => 0 }
			  unless ( defined $genes_4_bar_graph->{$temp} );
			$genes_4_bar_graph->{$temp}->{'y'}++;
		}

		foreach $var_name (@var_names) {
			next unless ( defined $control_data->{$gene_list}->{$var_name} );
			unless ( $normalized_vars->{$var_name} ) {
				push(
					@{ $data->{$var_name} },
					$control_data->{$gene_list}->{$var_name}
				);
			}
			else {
				push(
					@{ $data->{$var_name} },
					&compute(
						$control_data->{$gene_list}->{$var_name},
						$control_data->{$gene_list}->{$normalizing_var}
					)
				);
			}
		}
	}
	## now I need to check if we could create the 'seeder genes match' and 'all genes match' data structures!
	@temp = ();
	my $i = 0;
	my $new_cols = { 'seeder genes match' => 1, 'all genes match' => 1 };
	foreach my $gene_list ( keys %$control_data ) {
		foreach $var_name (@var_names) {
			if ( scalar( @{ $data->{$var_name} } ) > 0 ) {
				print "we have "
				  . scalar( @{ $data->{$var_name} } )
				  . " data points for variable $var_name\n";
				$temp[ $i++ ] = $var_name;
				if ( $new_cols->{$var_name} ) {
					$real_dataset->{$real_gene_list}->{$var_name} =
					  $max_values->{$var_name};
				}
			}
		}
		last;
	}
	@var_names = @temp;
	return ( $data, $real_dataset );
}

sub estimated_p_value {
	my ( $value, $list, $mode, $var_name ) = @_;
	my ( @temp, $p_value );
	warn "the dataset for var $var_name is empty!\n" unless ( @$list > 0 );
	warn "we have a missing value in the data array for var $var_name\n"
	  if ( !defined @$list[0] );
	unless ( defined $value ) {
		print
"we have a critical problem, as we do not have a value for the real dataset $var_name:\n"
		  . "the possible list of datasets is:\n"
		  . join( "\n", ( keys %{ $real_data->{$real_gene_list} } ) ) . "\n";
		Carp::confess(
			"please fix that - the \$value $var_name was not defined!\n");
	}

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

		$p_value = sprintf( '%.1e', $p_value );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value;
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
		$p_value = sprintf( '%.1e', $p_value );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value;
	}
	if ( $mode eq "both" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( !defined $temp[$i] ) {
				warn
				  "we do not have an entry for the dataset $var_name pos $i!\n";
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
		$p_value = sprintf( '%.1e', $p_value * 2 );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value;
	}
	Carp::confess(
		"Sorry, but we only support the modes higher, lower or both\n");
}

sub create_var_plots {

	foreach $var_name (@var_names) {
		print "\nwe wil create the plot for the data structure '$var_name'\n";
		$max = 0;
		foreach my $val ( @{ $data->{$var_name} } ) {
			$max = $val if ( $val > $max );
		}
		$x_title = $var_name;
		if ( $normalized_vars->{$var_name} ) {
			$x_title .= " / $normalizing_var";
		}
		print "We will plot '$bar_count' potential bars in the histogram!\n"
		  if ($debug);

	  #my $new_histogram = new_histogram->new();
	  #$new_histogram->CreateHistogram( $data->{$var_name}, undef, $bar_count );

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
		unless ( $do_not_mark_value->{$var_name} ) {
			unless ( $normalized_vars->{$var_name} ) {
				$new_histogram->Mark_position(
					$real_data->{$real_gene_list}->{$var_name} );
			}
			else {
				$new_histogram->Mark_position(
					&compute(
						$real_data->{$real_gene_list}->{$var_name},
						$real_data->{$real_gene_list}->{$normalizing_var}
					)
				);
			}
		}
		$temp = $_;
		$var_name =~ s/_/-/g;
		$new_histogram->plot(
			{
				'outfile' => $outpath . "/"
				  . join( "_", split( /[ \.]/, $var_name ) ) . ".svg",
				'x_resolution' => 600,
				'y_resolution' => 400,
				'x_title'      => $x_title
			}
		);
		system( "trimPictures.pl -infile " 
			  . $outpath . "/"
			  . join( "_", split( /[ \.]/, $var_name ) ) . ".svg -outfile "
			  . $outpath . "/"
			  . join( "_", split( /[ \.]/, $var_name ) )
			  . ".png" );
		$new_histogram = undef;
	}

## add a description of the used genes:
	#	my $simpleBarGraph = simpleBarGraph->new();
	my ( $x, $y );
	$x = scalar( keys %$genes_4_bar_graph ) * 10 + 200;
	$y = 400;

	# my $im = $simpleBarGraph->createPicture( $x, $y );
	#	$simpleBarGraph->AddDataset(
	#		{
	#			'name'        => 'genes',
	#			'data'        => $genes_4_bar_graph,
	#			'order_array' => [
	#				sort {
	#					$genes_4_bar_graph->{$a}->{'y'} <=> $genes_4_bar_graph->{$b}
	#					  ->{'y'}
	#				  } keys %$genes_4_bar_graph
	#			],
	#			'color'        => $simpleBarGraph->{'color'}->{'black'},
	#			'border_color' => $simpleBarGraph->{'color'}->{'black'}
	#		}
	#	);
	#	$simpleBarGraph->Ytitel('amount of nets containing gene');
	#	$simpleBarGraph->Xtitel('gene name');
	my @temp = undef;
	my $i    = 0;

	foreach ( keys %$genes_4_bar_graph ) {
		$temp[ $i++ ] = $genes_4_bar_graph->{$_}->{'y'};
	}
	my ( $mean, $n, $std ) = root->getStandardDeviation( \@temp );
	my $new_histogram = histogram_container->new();
	$new_histogram->CreateHistogram( '  ', \@temp, undef, $bar_count );
	$new_histogram->Title( "mean usage of "
		  . ( $n + 1 ) . "/"
		  . ( scalar(@gene_names_array) )
		  . " genes (R=$R_cutoff)" );
	$new_histogram->plot(
		{
			'outfile'      => "$outpath/gene_usage_distribution.svg",
			'x_resolution' => 600,
			'y_resolution' => 400,
			'x_title'      => "times in a connetion net",

		}
	);
	system( "trimPictures.pl "
		  . " $outpath/gene_usage_distribution.svg "
		  . " $outpath/gene_usage_distribution.png" );

	#	$simpleBarGraph->plot_2_image(
	#		{
	#			'outfile' => "$outpath/detailed_gene_description",
	#			'x_res' => $x,
	#			'y_res' => $y,
	#			'x_min'   => 50,
	#			'x_max'   => $x - 40,
	#			'y_min'   => 20,                                      # oben
	#			'y_max'   => 340,                                     # unten
	#			'mode'    => 'landscape',
	#			'size'    => 'min',
	#			'color'   => $simpleBarGraph->{'color'},
	#			'font'    => Font->new('min'),
	#			'title'   => "mean = $mean, std_dev = $std, n = $n"
	#		}
	#	);
	system( "trimPictures.pl "
		  . " $outpath/detailed_gene_description.svg"
		  . " $outpath/detailed_gene_description.png" );
}

sub define_subGroup_links {

	## create subgroups
	return 1;
	foreach $var_name (@var_names) {
		$data->{"$var_name lower 25 percent links"}      = [];
		$data->{"$var_name upper 25 percent links"}      = [];
		$data->{"$var_name central 50 percent of links"} = [];
	}
	push( @additional_figure_descriptions,
". To estimate the effect of the amount of overall links on all other values I have created the lower 25, upper 25 and centryl 50 percent groups."
	);
	my ( @data, $values_hash );
	foreach my $gene_list ( keys %$control_data ) {
		push( @data, $control_data->{$gene_list}->{'overall links'} );
	}
	my ( $_25, $_75 );
	$_25 = root->quantilCutoff( \@data, 25 );
	$_75 = root->quantilCutoff( \@data, 75 );
	foreach my $gene_list ( keys %$control_data ) {
		if ( $control_data->{$gene_list}->{'overall links'} < $_25 ) {
			&push_values_into_array( $gene_list, ' lower 25 percent links' );
		}
		elsif ( $control_data->{$gene_list}->{'overall links'} < $_75 ) {
			&push_values_into_array( $gene_list,
				' central 50 percent of links' );
		}
		else {
			&push_values_into_array( $gene_list, ' upper 25 percent links' );
		}
	}
	return 1;
}

sub push_values_into_array {
	my ( $gene_list, $array_name ) = @_;
	$array_name |= '';
	my $values_hash =
	  &get_calculated_hash_for_values( $control_data->{$gene_list} );
	foreach $var_name (@var_names) {
		push(
			@{ $data->{ $var_name . $array_name } },
			$values_hash->{$var_name}
		);
	}
	return 1;
}

sub get_calculated_hash_for_values {
	my ($values_hash) = @_;
	my $return = {};
	foreach $var_name (@var_names) {
		unless ( $normalized_vars->{$var_name} ) {
			$return->{$var_name} = $values_hash->{$var_name};
		}
		else {
			$return->{$var_name} = &compute( $values_hash->{$var_name},
				$values_hash->{$normalizing_var} );
		}
	}
	return $return;
}

sub define_subGroups {

	my $cutoff = 2;
## create subgroups
	foreach $var_name (@var_names) {
		$data->{"$var_name more than $cutoff gene(s) match"} = [];
		$data->{"$var_name $cutoff or less gene(s) match"}   = [];
	}
	push(
		@additional_figure_descriptions,
". The multi group plots show the total distribution and partial distributions for the connection nets, 
that contain equal or less / more than $cutoff genes in their respective seeder gene lists"
	);

	foreach my $gene_list ( keys %$control_data ) {
		## I now want to create a seeder gene matches dataset lists!
#print "we have $control_data->{$gene_list}->{'seeder genes match'} seeder genes matches!\n";
		if ( $control_data->{$gene_list}->{'seeder genes match'} > $cutoff ) {
			foreach $var_name (@var_names) {
				unless ( $normalized_vars->{$var_name} ) {
					push(
						@{
							$data->{"$var_name more than $cutoff gene(s) match"}
						  },
						$control_data->{$gene_list}->{$var_name}
					);
				}
				else {
					push(
						@{
							$data->{"$var_name more than $cutoff gene(s) match"}
						  },
						&compute(
							$control_data->{$gene_list}->{$var_name},
							$control_data->{$gene_list}->{$normalizing_var}
						)
					);
				}
			}
		}
		elsif ( $control_data->{$gene_list}->{'seeder genes match'} <= $cutoff )
		{

			foreach $var_name (@var_names) {
				unless ( $normalized_vars->{$var_name} ) {
					push(
						@{
							$data->{"$var_name $cutoff or less gene(s) match"}
						  },
						$control_data->{$gene_list}->{$var_name}
					);
				}
				else {
					push(
						@{
							$data->{"$var_name $cutoff or less gene(s) match"}
						  },
						&compute(
							$control_data->{$gene_list}->{$var_name},
							$control_data->{$gene_list}->{$normalizing_var}
						)
					);
				}
			}
		}
		else {
			foreach $var_name (@var_names) {
				delete $data->{"$var_name $cutoff or less gene(s) match"};
				delete $data->{"$var_name more than $cutoff gene(s) match"};
			}
			last;
		}
	}

}

sub get_lib_str {
	return '
	
@article{Nicholas:Ulam:1949,
     jstor_articletype = {primary_article},
     title = {The Monte Carlo Method},
     author = {Metropolis, Nicholas and Ulam, S.},
     journal = {Journal of the American Statistical Association},
     jstor_issuetitle = {},
     volume = {44},
     number = {247},
     jstor_formatteddate = {Sep., 1949},
     pages = {335--341},
     url = {http://www.jstor.org/stable/2280232},
     ISSN = {01621459},
     abstract = {We shall present here the motivation and a general description of a method dealing with a class of problems in mathematical physics. The method is, essentially, a statistical approach to the study of differential equations, or more generally, of integro-differential equations that occur in various branches of the natural sciences.},
     language = {},
     year = {1949},
     publisher = {American Statistical Association},
     copyright = {Copyright © 1949 American Statistical Association},
  }


	';
}

sub Setup {

	@path = split( "/", $experiment_statistics );
	pop(@path);
	if ( -f join( "/", @path ) . "/genes.txt" ) {
		open( G, "<" . join( "/", @path ) . "/genes.txt" )
		  or die "sorry, but I could not open the file "
		  . join( "/", @path )
		  . "/genes.txt\n$!\n";
		my $i = 0;
		while (<G>) {
			chomp($_);
			foreach my $gene ( split( /\s+/, $_ ) ) {
				$reference_genes[ $i++ ] = $gene;
			}
		}
		close(G);
	}

	@var_names = (
		'overall links',
		'overall genes',
		'genes in connection groups',
		'connection groups',

		#'percent seeder overlap',
		#'percent all overlap',
		'max seeder group'
	);

	#TODO The Phenotypes have to be added separately!
	push( @var_names, &AdditionalPhenotypes() );

	@normalized_vars                      = ();           #@var_names[ 2 .. 3 ];
	$normalizing_var                      = $var_names[0];
	$do_not_mark_value->{ $var_names[4] } = 1;
	$do_not_mark_value->{ $var_names[5] } = 1;
	$do_not_mark_value->{'percent all overlap'} = 1;
	$do_not_mark_value->{'seeder genes match'}  = 1;

	foreach $var_name (@normalized_vars) {
		$normalized_vars->{$var_name} = 1;
	}

	$str_orig->{ $var_names[0] } =
	    "the amount of connections between any seeder gene and "
	  . "any other gene on the array ";
	$str_normalized->{ $var_names[0] } =
	  $str_orig->{ $var_names[0] } . " normalized to $normalizing_var";

	$str_orig->{ $var_names[1] } =
"the amount of genes that did correlate to at least one of the seeder genes at the given R\$^2\$ cutoff ";
	$str_normalized->{ $var_names[1] } =
	  $str_orig->{ $var_names[1] } . " normalized to $normalizing_var";

	$str_orig->{ $var_names[2] } =
	  "the amount of genes that did correlate to at least two seeder genes ";
	$str_normalized->{ $var_names[2] } =
	  $str_orig->{ $var_names[2] } . " normalized to $normalizing_var";

	$str_orig->{ $var_names[3] } =
"the amount of connection groups that connect at least two of the seeder genes and contain at least one gene ";
	$str_normalized->{ $var_names[3] } =
	  $str_orig->{ $var_names[3] } . " normalized to $normalizing_var";

	Carp::confess(
"Sorry, but please fix the script at this position - you want to normalize some vars, but you do nhot define a normalizing var!\n"
	) if ( scalar(@normalized_vars) > 0 && !defined $normalizing_var );
	return (
		$do_not_mark_value, @additional_figure_descriptions,
		$normalizing_var,   @normalized_vars,
		$normalized_vars,   @var_names,
		$var_name,          @reference_genes,
		@path,              $genes_4_bar_graph,
		$str_normalized,    $str_orig
	);
## done with normalization setup
}

sub AdditionalPhenotypes {

#Carp::confess(root::get_hashEntries_as_string ($control_data, 3, "We need to identify the Phenotype Vars in the dataset:" ));
	my ( @return, @temp );
	foreach (@otherCorrelationFiles) {
		@temp = split( "/",  $_ );
		@temp = split( /\./, $temp[ @temp - 1 ] );
		push( @return, $temp[0] );
	}
	return @return;
}

sub compute {
	my ( $a, $b ) = @_;
	return $a / $b;
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
\author{Stefan Lang}
\date{' . root->Today() . '}
\maketitle

### DATA ##

\bibliographystyle{plain}
\bibliography{library}

\end{document}
';
}

sub select_random_gene_hash {
	my ( $gene_count, @genes ) = @_;
	my $selected_genes = {};
	for ( my $random_gene = 0 ; $random_gene < $gene_count ; $random_gene++ ) {
		$ok = 0;
		while ( !$ok ) {
			$temp = rand( scalar(@genes) - 1 );
			unless ( $selected_genes->{ $genes[$temp] } ) {
				$selected_genes->{ $genes[$temp] } = 1;
				$ok = 1;
			}
		}
	}
	return $selected_genes;
}

sub create_random_expression_net_statistics {

	if ( $max_random_genes && $max_random_genes < scalar(@gene_names_array) ) {
		@gene_names_array = (
			keys %{
				&select_random_gene_hash(
					$max_random_genes, @gene_names_array
				)
			  }
		);
	}
	$expression_net_reader->Read_from_File( $control_connection_net,
		\@gene_names_array, 1 );

	$expression_net_reader =
	  $expression_net_reader->restrict_R_squared_moreThan($R_cutoff);
## now please select a random number of genes from the list of genes $repetitions times
	$expression_net_reader->Add_Phenotype_Informations(@otherCorrelationFiles);
	my (@path);

	@path = split( "/", $0 );
	splice( @path, @path - 4, 4 );
	print "we expect the scripts to be downstream of "
	  . join( "/", @path )
	  . "/bin\n";
	print
"we create $repetitions random co-expression networks using a R cutoff of $R_cutoff\n";
	for ( my $i = 0 ; $i < $repetitions ; $i++ ) {
		$selected_genes =
		  select_random_gene_hash( $seeder_gene_count, @gene_names_array );
		$restricted_expression_net =
		  $expression_net_reader->restrict_gene1_to_list(
			sort keys %$selected_genes );
		$restricted_expression_net->{'phenotypes'} =
		  $expression_net_reader->{'phenotypes'};
		$error = '';
		foreach ( keys %{ $restricted_expression_net->{'gene1'} } ) {
			unless ( $selected_genes->{$_} ) {
				$error .= "gene $_ was not expected in the list!\n";
			}
			else {
				$selected_genes->{$_}++;
			}
		}
		foreach ( keys %$selected_genes ) {
			$error .=
"the gene $_ had no entry in the genes1 hash ($selected_genes->{$_})\n"
			  unless ( $selected_genes->{$_} == 2 );
		}
		die
"we have more/less than the expected number of genes in the list!\n$error"
		  . "but we would have data for these genes:\n'"
		  . join( "'\n'", sort keys %{ $restricted_expression_net->{'gene1'} } )
		  . "'\n"
		  if ( $error =~ m/\w/ );

		$restricted_expression_net->Logfile(
			"$outpath/expression_net_statistcs.txt");
		$restricted_expression_net->__create_connection_dataset();
		if ( defined $reference_genes[0] ) {
			$restricted_expression_net->Compare_to_Reference_list(
				\@reference_genes );
		}
		$restricted_expression_net->use_organism($organism_tag);
		$restricted_expression_net->__define_connection_groups();
		print "\nStatistical result for run $i:"
		  . join( "\n", $restricted_expression_net->__statistical_log_entry() )
		  if ($debug);
		print "-"         if ( $i % 10 == 0 );
		print "+"         if ( $i % 100 == 0 );
		print "$i nets\n" if ( $i % 1000 == 0 );
		$restricted_expression_net = undef;
	}

}
