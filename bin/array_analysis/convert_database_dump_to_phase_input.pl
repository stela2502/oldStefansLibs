#! /usr/bin/perl -w

#  Copyright (C) 2010-08-31 Stefan Lang

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

=head1 convert_database_pump_to_affy_calls.pl

a script to convert the databse output format into the Affymetrix data file.

To get further help use 'convert_database_dump_to_phase_input.pl -help' at the command line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
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
 command line switches for convert_database_pump_to_affy_calls.pl

   -infile       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'convert_database_dump_to_phase_input.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);

my $table = data_table->new();

open ( IN ,"<$infile" ) or die "could not open infile '$infile'\n$!\n";
$table -> Add_2_Header( 'sample_id' );
$table -> line_separator( " " );
my ( @line, $dataset, $added, $rsID_info );
$dataset = { 'sample_id' => undef };

#PATIENT MARKER  ALLELE1 ALLELE2 MENDEL
#100     RS10818564      G       T       0
#100     RS10985285      A       C       0
#100     RS10985287      C       T       0
#100     RS306773        A       G       0
#100     RS7849996       C       T       0
#100     RS7873990       A       C       0
#1000    RS10818564      G       T       0
#1000    RS10985285      A       C       0
#1000    RS10985287      C       T       0
## I want to get the SNP frequencies as I do not want to include rarae SNPs ( MAF >5%)
my $FEQ = {};

while ( <IN> ) {
	chomp $_;
        @line = split( "\t", $_);
	next if ( $line[0] eq "PATIENT");
	$line[1] =~ s/RS/rs/;
	unless ( $line[2] eq $line[3] ){
		$FEQ -> { $line[1] } = { 'ma' => $line[2], $line[2] => 0, 'mi' => $line[3] ,  $line[3]=> 0};
		$rsID_info -> {$line[1]} = { 'ma' => $line[2], 'mi' => $line[3] } unless ( defined  $rsID_info -> {$line[1]} );
	}
}
close ( IN );
print root::get_hashEntries_as_string ($rsID_info , 3, "we got the rsID_info", 100) if ( $debug );
open ( IN ,"<$infile" ) or die "could not open infile '$infile'\n$!\n";
my $i = 1;

while ( <IN> ) {
	chomp $_;
	@line = split( "\t", $_);
	next if ( $line[0] eq "PATIENT");
	$line[1] =~ s/RS/rs/;
	$dataset->{'sample_id'} = $line[0] unless ( defined $dataset->{'sample_id'});
	unless ( $dataset->{'sample_id'} == $line[0] ){
		$table->AddDataset( $dataset );
		$dataset = {};
	}
	
	$FEQ -> { $line[1] } -> { $line[2] }++;
	$FEQ -> { $line[1] } -> { $line[3] }++;
	
	unless ( $added ->{$line[1]} ){
		 $table ->Add_2_Header( $line[1] );
		 $added ->{$line[1]} = $i ++;
	}
	if ( $line[2] eq $rsID_info -> {$line[1]}->{ 'ma' } &&  $line[3] eq $rsID_info -> {$line[1]}->{ 'ma' }){
		$dataset->{$line[1]} = 0;
	}
	elsif ( $line[2] eq $rsID_info -> {$line[1]}->{ 'ma' } &&  $line[3] eq $rsID_info -> {$line[1]}->{ 'mi' }){
		$dataset->{$line[1]} = 1;
	}
	else {
		$dataset->{$line[1]} = 2;
	}
}
if ( defined $dataset->{'sample_id'}){
	$table -> Add_2_Header( $line[1] );
}
print "we have read all the genotype data\n" if ( $debug );
close ( IN );
my  ($genomeDB, $SNP_interface);
$genomeDB = genomeDB->new();
$SNP_interface = $genomeDB->GetDatabaseInterface_for_Organism( 'H_sapiens' )->get_rooted_to('SNP_table');
my $complex = "#1, #2+ #3";

print "we will execute a DB search\n" if ( $debug);

my $SNP_positions = $SNP_interface -> get_data_table_4_search ({
 	'search_columns' => ['SNP_table.rsID', 'SNP_table.position', 'chromosomesTable.chr_start'],
 	'where' => [['SNP_table.rsID','=','my_value']],
 	'complex_select' => \$complex,
 	'order by' => [ ['SNP_table.position', '+', 'chromosomesTable.chr_start']]
}, [sort { $added->{$a} <=> $added->{$b} } keys %$added] );

$SNP_positions->rename_column (@{ $SNP_positions->{'header'} }[0], 'rsID');
$SNP_positions->rename_column (@{ $SNP_positions->{'header'} }[1], 'position');
$SNP_positions->createIndex( 'rsID' );
$SNP_positions = $SNP_positions ->getAsHash ( 'rsID', 'position');

print root::get_hashEntries_as_string ($SNP_positions, 3, "we got the SNP data as hash:" ,100) if ( $debug );
open ( OUT ,">$outfile" ) or die "could not open the outfile $outfile\n$!\n";
print OUT scalar( @{$table->{'data'}} )."\n";
print OUT scalar( keys %$SNP_positions)."\n";
print OUT "P ";

my $next_line = '';
my @columns = (0);
foreach my $rsID ( sort { $SNP_positions->{$a} <=> $SNP_positions->{$b} } keys %$SNP_positions ){
	print OUT "$SNP_positions->{$rsID} ";
	$next_line .= "S";
	push (@columns, $added->{$rsID} );
}
print "we got the column oder '".join('-',@columns)."'\n";
print OUT "\n$next_line\n";
## Now I need to print the genotypes - on two consecutive lines - SHIT format!
foreach my $line ( @{$table->{'data'}} ){
	print OUT "#@$line[0]\n";
	$next_line = '';
	if ( $debug ){
		print "the info:\t".join("\t", @$line)."\n";
		next;
	}
	for ( $i = 1; $i < @$line; $i++ ){
		@$line[0] = @{$table->{'header'}}[$columns[$i]];
		if ( @$line[$columns[$i]] == 0 ){
			print OUT "$rsID_info->{@$line[0]}->{'ma'} ";
			$next_line .= "$rsID_info->{@$line[0]}->{'ma'} ";
		}
		elsif ( @$line[$columns[$i]] == 1 ){
			print OUT "$rsID_info->{@$line[0]}->{'ma'} ";
			$next_line .= "$rsID_info->{@$line[0]}->{'mi'} ";
		}
		else {
			print OUT "$rsID_info->{@$line[0]}->{'mi'} ";
			$next_line .= "$rsID_info->{@$line[0]}->{'mi'} ";
		}
	}
	print OUT "\n$next_line\n";
}

close ( OUT );

open ( DESC ,">$outfile.descr")  or die "could not open the outfile $outfile.descr\n$!\n";
my ( $A, $B );
print DESC "rsID\tposition\tA\tA [n]\tB\tB [n]\tMAF\n";
foreach my $rsID ( sort { $SNP_positions->{$a} <=> $SNP_positions->{$b} } keys %$SNP_positions ){
	if ($FEQ -> {$rsID}->{ $FEQ->{'ma'} } > $FEQ -> {$rsID}-> { $FEQ->{'mi'}} ){
		$A = $FEQ->{$rsID}->{'ma'}; 
		$B = $FEQ->{$rsID}->{'mi'};
	}
	else { 
		$A = $FEQ->{$rsID}->{'mi'};
		$B = $FEQ->{$rsID}->{'ma'};
	}
	if ( $FEQ->{$rsID}->{$B} == 0 ){
		warn "rsID $rsID: we have no sample with the nimor allele $B\n";
	}
	print DESC "$rsID\t$SNP_positions->{$rsID}\t$A\t$FEQ->{$rsID}->{$A}\t$B\t$FEQ->{$rsID}->{$B}\t".
		($FEQ->{$rsID}->{$B} / ( $FEQ->{$rsID}->{$A} + $FEQ->{$rsID}->{$B}))."\n";
}
close ( DESC );

print "we have written a PHASE input file $outfile\n";

## Do whatever you want!

