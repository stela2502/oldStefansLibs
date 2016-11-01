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

=head1 make_histogram_2.pl

give me a tab separated file and I will give you a histogram with the spread you want to have for the column you are interested in.

To get further help use 'make_histogram.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;
use stefans_libs::statistics::new_histogram;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';
my $rrot    = root->new();

my ( $help, $debug, $database, $table_file, $column, $outfile, $bars );

Getopt::Long::GetOptions(
	"-table_file=s" => \$table_file,
	"-column=s"     => \$column,
	"-outfile=s"    => \$outfile,
	"-bars=s"       => \$bars,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $table_file ) {
	$error .= "the cmd line switch -table_file is undefined!\n";
}
unless ( defined $column ) {
	$error .= "the cmd line switch -column is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $bars ) {
	$error .= "the cmd line switch -bars is undefined!\n";
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
 command line switches for make_histogram.pl

   -table_file :a tab separated file from which you want to plot the enries in one column
   -column     :the name of the column
   -outfile    :the figure file
   -bars       :into how manny columns should I split the data?

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/make_histogram_2.pl';
$task_description .= " -table_file $table_file" if ( defined $table_file );
$task_description .= " -column $column"         if ( defined $column );
$task_description .= " -outfile $outfile"       if ( defined $outfile );
$task_description .= " -bars $bars"             if ( defined $bars );

my $data_table = data_table->new();
$data_table->read_file($table_file);
Carp::confess(
	"Sorry, but the data file does not contain a column names '$column'\n". "I have the column names '".join("' '", @{$data_table->{'header'}})."'\n" )
  unless ( defined $data_table->Header_Position($column) );
my $histogram = new_histogram->new();
$histogram->CreateHistogram( $data_table->getAsArray($column), undef, $bars );
$histogram->plot(
	{
		'x_title'      => $table_file,
		'y_title'      => 'fraction',
		'x_resolution' => 600,
		'y_resolution' => 400,
		'outfile'      => $outfile
	}
);
