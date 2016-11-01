#! /usr/bin/perl -w

#  Copyright (C) 2008 Stefan Lang

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

=head1 get_Individuals_ids.pl

A script, that alows the generation of complex quries against the samples table

To get further help use 'get_array_dataset_ids.pl -help' at the command line.

=cut

use Getopt::Long;
use stefans_libs::database::array_dataset;
use strict;
use warnings;

my ( $help, $debug, @where_stm, @bind_var, @orderBy, $outfile );

Getopt::Long::GetOptions(
     "-where=s{,}"          => \@where_stm,
     "-bind_vars=s{,}"      => \@bind_var,
     "-outfile=s"           => \$outfile,
     "-orderBy=s{,}"           => \@orderBy,
	 "-help"             => \$help,
	 "-debug"            => \$debug,
);

if ( $help ){
	print helpString( ) ;
	exit;
}

my $error = '';
my $warning = '';

unless ( defined $where_stm[0]){
	$warning .= "We did not get any -where restrictions - we will simply select all the ids!";

}
if ( scalar ( @where_stm ) != scalar ( @bind_var )){
	$error .= "we need exactly the same amount of bind variables as we have got where statements!\n";
}
unless ( defined $outfile ){
	$error .= "we need to know where to save the results!\n";
}

warn $warning if ( $warning =~ m/\w/ );
if ( $error =~ m/\w/ ){
	print &helpString( $error);
	exit;
}
sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for get_Individuals_ids.pl
 
   -where          :a list of where statements like <column1>;<operator>;<column2>
   -bind_vars      :a list of bind variables that fill into all my_value entries in the where statements
   -orderBy        :a column name you want to order the dataset with (default array_datasets.id)
   -outfile        :the file to print the output to
   -help           :print this help
   -debug          :verbose output

"; 
}

my $array_dataset = array_dataset->new(root::getDBH('root'),0);


my $where = [];
foreach my $w ( @where_stm ){
	push (@$where,[split ( ";",$w)]);
}

for( my $b =0; $b < @bind_var; $b++ ){
	if ($bind_var[$b] =~ m/;/ ){
		## OK you have a list of variables here - verry good
		$bind_var[$b] = [ split (/ *; */, $bind_var[$b])];
	}
}
@orderBy = ($array_dataset->TableName().".id") unless ( defined $orderBy[0]);

my $data = $array_dataset-> getArray_of_Array_for_search({
 	'search_columns' => [$array_dataset->TableName().".id"],
 	'where' => $where,
 	'order_by' => [@orderBy],
 }, @bind_var
);

my @val = ();
open (OUT, ">$outfile" ) or die "could not create outfile '$outfile'\n";
print OUT  $array_dataset->{'complex_search'}."\n";
foreach my $d ( @$data) {
	print OUT join ("\t",@$d)."\n";
	push (@val, @$d );
}
print OUT join ( " ",@val)."\n";
print OUT join ( ";",@val)."\n";
close ( OUT );