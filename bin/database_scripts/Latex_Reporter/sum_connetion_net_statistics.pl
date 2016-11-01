#! /usr/bin/perl -w

#  Copyright (C) 2010-07-01 Stefan Lang

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

=head1 sum_connetion_net_statistics.pl

A tool to summ up the negative controls for the statistcs.

To get further help use 'sum_connetion_net_statistics.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::plot::simpleXYgraph;
use File::Copy;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @in_paths, $outfile, $in_filename );

Getopt::Long::GetOptions(
	"-in_paths=s{,}" => \@in_paths,
	"-outfile=s"     => \$outfile,
	"-in_filename=s" => \$in_filename,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -d $in_paths[0] ) {
	$error .= "the cmd line switch -in_paths is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $in_filename ) {
	$error .= "the cmd line switch -in_filename is undefined!\n";
}
else {
	$error .=
	  "sorry, but I can not find the first infile $in_paths[0]/$in_filename\n"
	  unless ( -f $in_paths[0] . "/" . $in_filename );
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
 command line switches for sum_connetion_net_statistics.pl

   -in_paths       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>
   -in_filename       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'sum_connetion_net_statistics.pl';
$task_description .= ' -in_paths ' . join( ' ', @in_paths )
  if ( defined $in_paths[0] );
$task_description .= " -outfile $outfile"         if ( defined $outfile );
$task_description .= " -in_filename $in_filename" if ( defined $in_filename );

my ( $intro, $results, $end, $R, $n, $result, @temp, $outpath, $outfilename );
my $p_values = {};
$outfile .= "$outfile.tex" unless ( $outfile =~ m/\.tex$/ );
@temp = split( "/", $outfile );
$outfilename = pop(@temp);

$outpath = join( "/", @temp );
unless ( -d $outpath ) {
	mkdir($outpath);
	print "I created the outpath $outpath\n";
}

( $intro, $result, $end, $R, $n ) =
  &parse_LaTeX_file( $in_paths[0], $in_filename );
$results->{$R} = {} unless ( defined $results->{$R} );
$results->{$R}->{$n} = $result;

for ( my $i = 1 ; $i < @in_paths ; $i++ ) {
	( $a, $result, $b, $R, $n ) =
	  &parse_LaTeX_file( $in_paths[$i], $in_filename );
	$results->{$R} = {} unless ( defined $results->{$R} );
	$results->{$R}->{$n} = $result;
}

open( OUT, ">$outfile" ) or die "could not create outfile $outfile\n$!\n";
print OUT $intro;
## now I want to get an overview over the change in the P_values over the dataset!
print OUT "\\section{Change in p values}\n\n"
  . "This section will depict the influence of a changed R\$^2\$ on the different p values,
as the intention of a negative control is to estimate the best point between specificity and sensitivity.
\n";
my $pic_path = "$outfilename" . "_pics";
my $figure_printed = {};
foreach my $repetitions ( keys %$p_values ) {
	print "we analyze the repetion $repetitions\n";
	my (@p_keys);
	foreach my $R ( keys ( %{$p_values->{$repetitions}})){
		print root::get_hashEntries_as_string ($p_values, 3, "and we got a R_sqaure of $R\n");
		@p_keys = (keys %{$p_values->{$repetitions}->{$R}});
		last;
	}
	print "leading to the p_keys ".join("; ",@p_keys)."\n";
	my $figure = simpleXYgraph->new();
	foreach my $p_key ( @p_keys){
		my (@x, @y);
		foreach my $R ( keys ( %{$p_values->{$repetitions}})){
			push ( @x, $R);
			push ( @y, $p_values->{$repetitions}->{$R}->{$p_key});
		}
		print "we will add the data for the p_value $p_key\n";
		$figure->AddDataset(
		{
			'title' => $p_key,
			'x'     => \@x,
			'y'     => \@y
		}
		);
	}
	$figure->plot({
			'x_res' => 1900, 
	'y_res' => 1000,
	'x_min' => 120,
	'x_max' => 1800,
	'y_min' => 100,
	'y_max' => 900,
	'outfile' => "$outpath/$pic_path/pValues$repetitions"
	});
	system ( "trimPictures.pl " 
			  .  "$outpath/$pic_path/pValues$repetitions.svg "
			  . "$outpath/$pic_path/pValues$repetitions.png" );
	unless ( $figure_printed -> { $repetitions }){
	print OUT "\\begin{figure}[htb]\n";
	print OUT "\\includegraphics[width=\\linewidth]{$pic_path/pValues$repetitions}\n";
	print OUT "\\caption{In this figure you can see the influence of the R\$^2\$ cutoff on the x axis on the p values on the y axis.
		The p value is displayed as -log10(p value).
	}\n";
	print OUT "\\end{figure}\n\n";
	$figure_printed -> { $repetitions } = 1;
	}
}

foreach $R ( sort { $b <=> $a } keys %$results ) {
	foreach $n ( sort { $a <=> $b } keys %{ $results->{$R} } ) {
		print OUT $results->{$R}->{$n};
	}
}
print OUT $end;
close(OUT);
my $temp = $outfilename;
$temp =~ s/\.tex$//;
open( MAKE, ">$outpath/makefile" )
  or die "could not create the LaTeX makefile\n";
print MAKE "all:
\tpdflatex $outfilename
\tbibtex $temp.aux
\tpdflatex $outfilename
\tbibtex $temp.aux
\tpdflatex $outfilename
\trm $temp.aux
\trm $temp.out
\trm $temp.toc
\trm $temp.bbl
\trm $temp.blg
";
close(MAKE);
chdir($outpath);
system("make");

print "you can now open $temp.pdf\n";
## Do whatever you want!

sub parse_LaTeX_file {
	my ( $inpath, $infile ) = @_;
	my (
		$intro,   $result,    $end,        $pic_file,
		$is_into, $is_result, $is_end,     $R,
		$n,       $pic_path,  $outPic_ext, $is_table
	);
	$pic_path = "$outfilename" . "_pics";
	open( IN, "<$inpath/$infile" )
	  or die "could not open first infile $infile\n$!";
	print "we have opened the file $inpath/$infile\n";
	$is_into = 1;
	$is_result = $is_end = $is_table = 0;
	foreach (<IN>) {

		if ( $_ =~ m/\\section\{R\$\^2\$ = 0.(\d+), n = (\d+)\}/ ) {
			( $R, $n ) = ( $1, $2 );
			$p_values->{$n} = {} unless ( ref( $p_values->{$n} ) eq "HASH" );
			$p_values->{$n}->{"0.$R"} = {};
			print "we got the R 0.$R and n $n\n";
			$outPic_ext = "_0_" . $R . "_" . $n;
			$R          = "0." . $R;
			$is_result  = 1;
			$is_end     = $is_into = 0;
		}
		if ( $_ =~ m/begin{longtable}/ ) {
			$is_table = 1;
		}
		if ( $_ =~ m/\\section{Methods}/ ) {
			$is_end = 1;
			$is_result = $is_into = 0;
		}
		if ($is_into) {
			$intro .= $_;
		}
		elsif ($is_result) {
			if ( $_ =~ m/\\includegraphics\[width=\\linewidth\]{([\w\-\d]+)}/ )
			{
				$pic_file = $1;
				$_ =~ s/$pic_file/$pic_path\/$pic_file$outPic_ext/;
				mkdir("$outpath/$pic_path") unless ( -d "$outpath/$pic_path" );
				copy( "$inpath/$pic_file.png",
					"$outpath/$pic_path/$pic_file$outPic_ext.png" );
				print
"I copied the pic file inpath/$pic_file.png to outpath/$pic_path/$pic_file$outPic_ext.png\n";
			}
			$result .= $_;
		}
		elsif ($is_end) {
			$end .= $_;
		}
		if ($is_table) {
			if ( $_ =~ m/\\end{longtable}/ ) {
				$is_table = 0;
				next;
			}
			if ( $_ =~ m/(.+) & \$(\d\.\d+)e\^\{-(\d+)\}\$/ ) {
				$p_values->{$n}->{$R}->{$1} = -log($2 * 10**-$3);
				print "p_value for R_square '$R' and p_key '$1' is "
				  . $p_values->{$n}->{$R}->{$1} . "\n";
			}
		}
	}
	copy( "$inpath/library.bib", "$outpath/library.bib" );
	close(IN);
	print "And now we are done with the file $inpath/$infile\n";
	return $intro, $result, $end, $R, $n;
}
