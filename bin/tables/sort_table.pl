#! /usr/bin/perl -w

#  Copyright (C) 2011-03-17 Stefan Lang

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

=head1 sort_table.pl

A command line tool to sort even a little larger tables.

To get further help use 'sort_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile, @sort_statements);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,
	 "-sort_statements=s{,}"    => \@sort_statements,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';
my $sort_by_array = [];
unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $sort_statements[0]) {
	$error .= "the cmd line switch -sort_statements is undefined!\n";
}
else {
	my @temp;
	foreach ( @sort_statements ){
		@temp = split(/;/,$_);
		unless ( scalar ( @temp == 2 )) {
			$error .= "sort_statements '$_':".
				"\n\tsorry, but each sort statement has to have the structure '<column_name>;<sort_type>'\n";
			$temp[1] = 'undef';
		}
		unless ( 'numeric antiNumeric lexical' =~ m/$temp[1]/){
			$error .= "we do not support the sort option '$temp[1]'\n";
		}
		push ( @$sort_by_array, [ @temp ] );
	}
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
 command line switches for sort_table.pl

   -infile            :the taget table
   -outfile           :where to store the target table to
   -sort_statements   :a list of sort statements like 'column_name;sort_type'
                       the sort type has to be one of 'numeric', 'antiNumeric' or 'lexical'
                       each sort will be table as if you would use excel to sort on multiple columns

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/sort_table.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= ' -sort_statements '.join( ' ', @sort_statements ) if ( defined $sort_statements[0]);


## Do whatever you want!
my $data_table = data_table->new();
$data_table->read_file ( $infile );
$data_table = $data_table->Sort_by( $sort_by_array );
$data_table ->write_file ( $outfile );
