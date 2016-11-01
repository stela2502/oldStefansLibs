#! /usr/bin/perl -w

#  Copyright (C) 2012-02-21 Stefan Lang

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

=head1 plot_density_plot.pl

This tool takes a tab separated table and a list of column names to produce a set of density plots from the data.

To get further help use 'plot_density_plot.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::plot::densityMap;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $table_file, @column_names, $outfile, $log_transform);

Getopt::Long::GetOptions(
	 "-table_file=s"    => \$table_file,
	 "-column_names=s{,}"    => \@column_names,
	 "-outfile=s"    => \$outfile,
	 "-log_transform"  => \$log_transform,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $table_file) {
	$error .= "the cmd line switch -table_file is undefined!\n";
}
unless ( defined $column_names[0]) {
	$error .= "the cmd line switch -column_names is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for plot_density_plot.pl

   -table_file     :the table containing the data you want to plot
   -column_names   :the column names for the values you want to plot
   -outfile        :the outfile (only the path infotrmation is used
   -log_transform  :transforms the values to the -log10(value) before plotting
   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/plot_density_plot.pl';
$task_description .= " -table_file $table_file" if (defined $table_file);
$task_description .= ' -column_names '.join( ' ', @column_names ) if ( defined $column_names[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);


## Do whatever you want!
my $data_table = data_table->new();
$data_table->read_file ( $table_file );
$error = '';
foreach ( @column_names ){
	$error .= "I do not have the column '$_' in the data file!\n" unless ( defined  $data_table->Header_Position($_) );
}
if ( $error =~m/\w/){
	die "Sorry I found an error:\n$error\nI have the columns: '".join("' '",@{$data_table->{'header'}} )."'\n";
}

$data_table -> define_subset ( 'DATA',\@column_names );
$data_table = $data_table->select_where ('DATA' , sub { my $ok = 1; foreach ( @_ ) { $ok = 0 unless ( $_ = ~m/\d/ ); } ; return $ok; } );
my @data = ();
foreach ( @column_names ){
	push ( @data, $data_table->getAsArray( $_ ) );
}
if ( $log_transform ){
	foreach my $array ( @data ){
		for ( my $i = 0; $i < @$array; $i ++) {
			@$array[$i] = - &log10(@$array[$i]);
		}
	}
}

my ($path, @temp, $filename);

@temp = split ( "/", $outfile );
$filename = pop(@temp );
$path = join("/",@temp );
unless ( $path =~m/\w/ ){
	$path = "./";
}

## Now lets write a log-file!
my $logfile = $path."/density_plot".root->Today().".log";
if ( -f $logfile ){
	open ( LOG, ">>$logfile" ) or die "Sorry I had problems opening the existing logfile '$logfile'\n$!\n";
}
else {
	open ( LOG, ">$logfile" ) or die "Sorry I had problems creating the logfile '$logfile'\n$!\n";
}
print LOG $task_description."\n";
close ( LOG );

for ( my $i = 0; $i < @column_names; $i ++) {
	$column_names[$i] =~ s/ /_/g;
}

&createPictures ( \@column_names, @data);

sub createPictures{
 	my ( $namesArray, $array1, @arrays2compare ) = @_;
 	my ( $temp, $value, $compareArray );
 	for ( my $i = 0; $i < @arrays2compare; $i++ ) {
 		$compareArray = $arrays2compare[$i];
 		my $xyWith_Histo = densityMap->new();
 		$xyWith_Histo -> AddData( [$array1, $compareArray] );
 		$xyWith_Histo->plot( "$path/$filename-@$namesArray[0]"."_@$namesArray[1+$i].svg" ,800 , 800 , @$namesArray[0] , @$namesArray[1+$i] );
 	}
 	shift ( @$namesArray);
 	return createPictures($namesArray, @arrays2compare) if ( @arrays2compare > 1 );
}

sub log10 {
	my ($value) = @_;
	return '' unless ( $value =~m/\d/ );
	Carp::confess("You must not give me a value <= 0 to take the log from (not '$value')\n")
	  unless ( $value > 0 );
	return log($value) / log(10);
}