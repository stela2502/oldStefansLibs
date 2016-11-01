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

To get further help use 'get_Individuals_ids.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::subjectTable;
use strict;
use warnings;

my ( $help, $debug, @phenotypes, @where_stm, @bind_var, $outfile, $searchColumn );

Getopt::Long::GetOptions(
     "-search_column=s"     =>\$searchColumn,
     "-phenotypes=s{,}"     =>\@phenotypes,
     "-where=s{,}"          => \@where_stm,
     "-bind_vars=s{,}"      => \@bind_var,
     "-outfile=s"           => \$outfile,
     "-help"             => \$help,
	 "-debug"            => \$debug,
);

if ( $help ){
	print helpString( ) ;
	exit;
}

my $error = '';
my $warning = '';
unless ( defined $phenotypes[0]){
	$warning .= "We did not get any -phenotypes - therefore we will not be able to query any!\n";
}
unless ( defined $where_stm[0]){
	$warning .= "We did not get any -where restrictions - we will simply select all the ids!";
	if ( defined $phenotypes[0]){
		$error .= "You have given me some phenotypes, but no where statement - "
		."that is an error as you do not need to connect to a phenotype if you do not use it afterwards!\n"
	}
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

   -search_column  :one column that you can query for (default subjects.id)
   -phenotypes     :a list of phenotype names that you would like include into your query
   -where          :a list of where statements like <column1>;<operator>;<column2>
   -bind_vars      :a list of bind variables that fill into all my_value entries in the where statements
   -outfile        :the file to print the output to
   -help           :print this help
   -debug          :verbose output

"; 
}

my $subjectTable = subjectTable->new(root::getDBH('root'),0);

foreach my $pheno ( @phenotypes ){
	$subjectTable->connect_2_phenotype ( $pheno );
}
my $where = [];
foreach my $w ( @where_stm ){
	push (@$where,[split ( ";",$w)]);
}
$searchColumn = $subjectTable->TableName().".id" unless ( defined  $searchColumn);

my $data = $subjectTable-> getArray_of_Array_for_search({
 	'search_columns' => [$searchColumn],
 	'where' => $where,
 	'order_by' => [$subjectTable->TableName().".id"],
 }, @bind_var
 );
my @val = ();
open (OUT, ">$outfile" ) or die "could not create outfile '$outfile'\n";
print OUT  $subjectTable->{'complex_search'}."\n";
foreach my $d ( @$data) {
	print OUT join ("\t",@$d)."\n";
	push (@val, @$d );
}
print OUT join ( " ",@val)."\n";
print OUT join ( ";",@val)."\n";
close ( OUT );