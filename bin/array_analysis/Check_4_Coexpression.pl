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

=head1 Check_4_Coexpression.pl

A script to check whether two genes are coexpressed in a expresion set or not.
To get further help use 'Check_4_Coexpression.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::tableHandling;
use stefans_libs::array_analysis::correlatingData::SpearmanTest;
use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, $expression_table, $description, @sample_names,
	$gene_connnections, $p_value );

Getopt::Long::GetOptions(
	"-expression_table=s"  => \$expression_table,
	"-p4cs=s{,}"      => \@sample_names,
	"-gene_connnections=s" => \$gene_connnections,
	"-p_value=s"           => \$p_value,
	"-work_description"    => \$description,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $expression_table ) {
	$error .= "the cmd line switch -expression_table is undefined!\n";
}
unless ( defined $sample_names[0] ) {
	$error .= "the cmd line switch -sample_names is undefined!\n";
}
unless ( -f $gene_connnections ) {
	$error .= "the cmd line switch -gene_connnections is undefined!\n";
}
unless ( defined $description ) {
	$error .=
"we need a -work_description to name the columns that will contain the correlation results!\n";
}

unless ( defined $p_value ) {
	$error .= "the cmd line switch -p_value is undefined!\n";
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
 command line switches for Check_4_Coexpression.pl

   -expression_table    :the expreesion estimates table
   -p4cs                :the pattern to select the samples_ids or a list of sample_ids
   -gene_connnections   :a file containing two rows named gene1 and gene2
   -outfile             :the outfile to store the connections in
   -p_value             :the max p value to report a connection
   -work_description    :a short tag to name the correlations you are doing at the moment

   -help           :print this help
   -debug          :verbose output
   
";
}
my ( @A, @B, $gene_gene_interactions, $expressions, $tableHandling,
	@columnNames, @insert2columns, $Spearman, $p, $s, $rho);

$gene_gene_interactions = data_table->new();
$gene_gene_interactions->read_file($gene_connnections);
$gene_gene_interactions->Name( "Gene gene interactions");
$expressions = data_table->new();
$expressions ->Name('expressions');
$expressions->read_file($expression_table);

$expressions->createIndex('Gene Symbol');
push ( @insert2columns,$gene_gene_interactions->Add_2_Header( $description . " p value" ));
push ( @insert2columns,$gene_gene_interactions->Add_2_Header( $description . " rho" ));

print "we can insert to the columns @insert2columns\n";

$tableHandling = tableHandling->new();
unless ( defined $sample_names[1] ) {
	@columnNames = $tableHandling->get_column_entries_4_columns(
		join( "\t", @{ $expressions->{'header'} } ),
		$tableHandling->identify_columns_of_interest_patternMatch(
			join( "\t", @{ $expressions->{'header'} } ),
			$sample_names[0]
		)
	);
}
else {
	@columnNames = $tableHandling->get_column_entries_4_columns(
		join( "\t", @{ $expressions->{'header'} } ),
		$tableHandling->identify_columns_of_interest_bySearchHash(
			join( "\t", @{ $expressions->{'header'} } ),
			$tableHandling->createSearchHash(@sample_names)
		)
	);
}
print "we create a subset of the columns ". join(", ", @columnNames),"\n";

$expressions->define_subset( 'columns_of_interest', \@columnNames);

$Spearman = SpearmanTest->new();
my $dataArray;
my $till = scalar(@{ $gene_gene_interactions->{'data'} });
$till = 500 if ( $debug);
for ( my $i = 0 ; $i < $till; $i++ ) {
	$dataArray = @{$gene_gene_interactions->{'data'} }[$i];
	@A = $expressions->get_value_for('Gene Symbol', @$dataArray[0], 'columns_of_interest');
	@B = $expressions->get_value_for('Gene Symbol', @$dataArray[1], 'columns_of_interest');
	unless ( $A[0]  =~ m/\d/){
		print "Missing values for '@$dataArray[0]'\n".join(", ", @A)."\n";
		@$dataArray[$insert2columns[0]] = "@$dataArray[0] missing values";
		@$dataArray[$insert2columns[1]] = "--";
		next;
	}
	unless ( $B[0]  =~ m/\d/){
		print "Missing values for '@$dataArray[1]'\n".join(", ", @B)."\n";
		@$dataArray[$insert2columns[0]] = "@$dataArray[1] missing values";
		@$dataArray[$insert2columns[1]] = "--";
		next;
	}
	($p,$s,$rho) = split( "\t", $Spearman->_calculate_spearmanWeightFit_statistics( \@A, \@B ));
	Carp::confess(
		"we could not correlate the values \n".join(",",@A)."\nand the values\n".join(",",@B)."\nas we got the p_value $p and the R_square $rho\n") 
		unless ( defined $rho);
	@$dataArray[$insert2columns[0]] = $p;
	@$dataArray[$insert2columns[1]] = $rho;
	
}
print "we try to print to file '$gene_connnections.mod\n";
$gene_gene_interactions->print2file($gene_connnections.".mod");
print "Done!\n";
