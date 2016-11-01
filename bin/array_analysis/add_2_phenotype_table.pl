#! /usr/bin/perl -w

#  Copyright (C) 2010-06-07 Stefan Lang

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

=head1 add_2_phenotype_table.pl

A tool to add to a phenotype table

To get further help use 'add_2_phenotype_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $phenotype_file,  $phenotype_name);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-phenotype_file=s"    => \$phenotype_file,
	 "-phenotype_name=s"    => \$phenotype_name,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( -f $phenotype_file) {
	$error .= "the cmd line switch -phenotype_file is undefined!\n";
}
unless ( defined $phenotype_name) {
	$error .= "the cmd line switch -phenotype_name is undefined!\n";
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
 
 The comman can add data rows to phenotype values, 
 if you have a phenotype file, that contains samples 
 in rows and the phenotypes in lines, whereas you have a new infile, 
 that contains the phenotype as sample - phenotype coded lines.
 The first lie in the infile will always used as description line!
 
 command line switches for add_2_phenotype_table.pl

   -infile         :the simple sample_id phenotype_value file
   -phenotype_file :the name of the phenotype file to add the data to
   -phenotype_name :the name of the phenotype

   -help           :print this help
   -debug          :verbose output
   
"; 
}


my ( $task_description);

$task_description .= 'add_2_phenotype_table.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -phenotype_file $phenotype_file" if (defined $phenotype_file);
$task_description .= " -phenotype_name $phenotype_name" if (defined $phenotype_name);


## Do whatever you want!
my ($data_table_in, $data, $phenotype_table );
$data_table_in = data_table->new();
$data_table_in ->read_file ( $infile );
$phenotype_table = data_table->new();
$phenotype_table -> read_file ( $phenotype_file );
my @warnings ;

foreach my $line ( @{$data_table_in->{'data'}}){
	$data -> { @$line[0] } = "@$line[1]";
	unless ( defined $phenotype_table -> Header_Position (@$line[0] )){
		$phenotype_table -> Add_2_Header ( @$line[0] );
		print "we had to add the sample @$line[0] to the phenotype file!\n";
		push ( @warnings, "we had to add the sample @$line[0] to the phenotype file!\n" );
	}
}

$data -> {'rs_id' } = $phenotype_name;
$phenotype_table -> Add_Dataset ( $data );

$phenotype_table -> print2file ( $phenotype_file );
