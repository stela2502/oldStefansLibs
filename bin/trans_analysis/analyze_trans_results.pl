#! /usr/bin/perl -w

#  Copyright (C) 2010-12-20 Stefan Lang

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

=head1 analyze_trans_results.pl

I try to estimte the probabillity that any given trany model shows an influence. The script will create a LaTeX results file.

To get further help use 'analyze_trans_results.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::stat_results;
use stefans_libs::Latex_Document;
use stefans_libs::statistics::new_histogram;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @infiles, $outfile );

Getopt::Long::GetOptions(
	"-infiles=s{,}" => \@infiles,
	"-outfile=s"    => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';
my ( $outpath, $filename );
unless ( defined $infiles[0] ) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
else {
	my @temp = split( "/", $outfile );
	$filename = pop(@temp);
	$outpath  = join( "/", @temp );
	$outpath  = "./" unless ( $outpath =~ m/\// );
	mkdir($outpath) unless ( -d $outpath );
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
 command line switches for analyze_trans_results.pl

   -infiles       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description, $stat_results);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/analyze_trans_results.pl';
$task_description .= ' -infiles ' . join( ' ', @infiles )
  if ( defined $infiles[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

## Do whatever you want!

my $summary_table = data_table->new();
$summary_table->Add_2_Header('SNP');
$summary_table->Add_2_Header('best model');
$summary_table->Add_2_Header('estimated p value');
$summary_table->Add_2_Header('section');

my $Latex_document = stefans_libs::Latex_Document->new();
$Latex_document->Outpath($outpath);
$stat_results = stat_results->new();

$Latex_document->Section( 'Introduction', 'intro' )
  ->AddText( "This ducument will sum up a "
	  . " trans effect analysis in order to estimate which SNPs and which model most probably does affect the expression of the genes the most.\n"
	  . "You might see from that formualtion, that there is no great statistics behind this estimate to make sense from the data.\n"
	  . "I have made a summary table to show which model did detect more nominally significant genes than expected by pure chance."
  )->Add_Table($summary_table);

$Latex_document->Section( 'Results', 'res' );
$Latex_document->Section( 'Methods', 'meth' )->Section('Statistics')
  ->AddText(
"The statistics were calculated using my batchStatistics script which utilzes "
	  . " the none parametric Spearman, Wilcox and Kruskal Wallis tests implemented in R.\n"
	  ." But here we were not interested in the results per se, "
	  . "but in a possible overrepresentation of low p values.\n"
	  . "To estimate if we get more than the expected amount of high significant "
	  . "test results we estimated the null distribution using the number of tests retuning a p_value between 0.04 and 0.05."
	  . "Those that show more significants genes in the range from 0 to 0.01 than the 75% quantile in the 0.05 group were estimated as being interesting."
  );

my ( $hash, $all_values, $dataset, $text, $figure );
$all_values = data_table->new();
$all_values->Add_2_Header('comparison');
my $i = 0;
foreach my $infile (@infiles) {
	$i++;
	$hash = &plot_data_file($infile);
	next unless ( defined $hash);
	foreach ( sort { $a <=> $b } @{ $hash->{'data_table'}->getAsArray('x') } ) {
		$all_values->Add_2_Header($_);
	}
	$dataset = { 'comparison' => $hash->{'comparison'} };
	foreach ( @{ $hash->{'data_table'}->GetAll_AsHashArrayRef() } ) {
		$dataset->{ $_->{'x'} } = $_->{'y'};
	}
	$all_values->AddDataset($dataset);
	$text =
	  $Latex_document->Section('Results')->Section( $hash->{'comparison'} )
	  ->AddText('');
	$figure = $text->Add_Figure();
	$figure->AddPicture(
		{
			'placement' => 'tbp',
			'files'     => [ $hash->{'figure_file'} ],
			'caption' =>
"The distrubution of the p values below 0.05 for the comparision $hash->{'compartison'} as histogram.",
			'width' => 0.5,
			'label' => "res::fig::$i"
		}
	);
	$text->AddText(
'The dirstibution for the p values below 0.05 is shown in the figure \\ref{'
		  . $figure->Label().
		'}. The folowing table shows the numeric values.'
	)->Add_Table( $hash->{'data_table'} );
}

## And now I need to estimate the overall outcome based on the values
my ( $key_05, $key_01 );




my ( $data );
my $whisker_data = root->whisker_data( $all_values->getAsArray($key_05) );
$all_values->Add_2_Header('estimated p value (two sided!)');
$all_values->createIndex('comparison');
foreach $hash ( @{ $all_values->GetAll_AsHashArrayRef() } ) {
	next unless (ref ($hash->{'data_table'}) eq "data_table" );
	$key_05 = $hash->{'data_table'}->get_line_asHash(4)->{'x'};
	$key_01 = $hash->{'data_table'}->get_line_asHash(0)->{'x'};
	$hash->{'estimated p value (two sided!)'} =
	  root->estimate_p_value( $hash->{$key_01},
		$all_values->getAsArray($key_05) );
	## now I need to stre the other data

	if ( $_ =~ m/(additive_model)_(.*)-named_probes.txt/ ) {
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  unless ( defined $data->{$2} );
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  if ( $data->{$2}->{'estimated p value'} >
			$hash->{'estimated p value (two sided!)'} );
	}
	elsif ( $_ =~ m/(recessive_model)_(.*)-named_probes.txt/ ) {
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  unless ( defined $data->{$2} );
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  if ( $data->{$2}->{'estimated p value'} >
			$hash->{'estimated p value (two sided!)'} );
	}
	elsif ( $_ =~ m/(three_group_model)_(.*)-named_probes.txt/ ) {
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  unless ( defined $data->{$2} );
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  if ( $data->{$2}->{'estimated p value'} >
			$hash->{'estimated p value (two sided!)'} );
	}
	elsif ( $_ =~ m/(domit_model)_(.*)-named_probes.txt/ ) {
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  unless ( defined $data->{$2} );
		$data->{$2} = {
			'best model'        => $1,
			'SNP'               => $2,
			'estimated p value' => $hash->{'estimated p value (two sided!)'}
		  }
		  if ( $data->{$2}->{'estimated p value'} >
			$hash->{'estimated p value (two sided!)'} );
	}
	else {
		$data->{ $hash->{'comparison'} } = {
			'best model'      => 'unknown',
			'SNP' => $hash->{'comparison'},
			'estimated p value'    => $hash->{'estimated p value (two sided!)'}
		};
	}
}

foreach ( keys %$data){
	$hash = $data->{$_};
	$hash -> {'section'} = "\\ref{".$Latex_document->Section('Results')->Section( $hash->{'comparison'} ) ->Label()."}";
	$summary_table -> AddDataset ( $hash );
}

$Latex_document->write_tex_file ( $filename );

sub plot_data_file {
	my ($table_file) = @_;
	my $data_table = $stat_results->read_file($table_file);
	return undef unless ( scalar (@{$data_table->{'data'}}) > 1);
	my ( @temp, $outfile );
	@temp = split( "/", $table_file );
	$outfile = pop(@temp);
	$outfile =~ s/\.svg$//;
	Carp::confess(
		"Sorry, but the data file does not contain a column names 'p-value'\n")
	  unless ( defined $data_table->Header_Position('p-value') );
	my $histogram = new_histogram->new();
	$histogram->CreateHistogram( $data_table->getAsArray('p-value'), undef, 20 );
	my $figure_file = $histogram->plot(
		{
			'x_title'      => $table_file,
			'y_title'      => 'fraction',
			'x_resolution' => 600,
			'y_resolution' => 400,
			'outfile'      => "$outpath/$outfile"
		}
	);
	return {
		'figure_file' => $figure_file,
		'data_table'  => $histogram->get_as_table(),
		'comparison'  => $outfile
	};
}

