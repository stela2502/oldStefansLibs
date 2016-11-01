#! /usr/bin/perl -w

#  Copyright (C) 2010-08-30 Stefan Lang

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

=head1 Max_Performance_SNP_2_Gene_Expression.pl

the script will estimate the best SNP file size and create a set of 
temporary SNP data files. Afterwards the script will create the necessary 
SNP_2_Gene_Expression.pl calls to calculate everything. In order to work 
perfectly, the scipt needs to know the available memory and the number of 
CPU cores that it will be able to use.

To get further help use 'Max_Performance_SNP_2_Gene_Expression.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::tableHandling;
use stefans_libs::root;
use Shell qw(grep ps kill);

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,           $debug,     $database,   @array_values,
	$phenotypeTable, $p_value,   @gene_names, $outfile,
	$p4cS,           $CpU_CORES, $FREE_MEM
);

Getopt::Long::GetOptions(
	"-array_values=s{,}" => \@array_values,
	"-phenotypeTable=s"  => \$phenotypeTable,
	"-p_value=s"         => \$p_value,
	"-gene_names=s{,}"      => \@gene_names,
	"-outfile=s"         => \$outfile,
	"-p4cS=s"            => \$p4cS,
	"-CpU_CORES=s"       => \$CpU_CORES,
	"-FREE_MEM=s"        => \$FREE_MEM,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ($debug) {
	unless ( -f $array_values[0] ) {
		$error .= "the cmd line switch -array_values is undefined!\n";
	}
	unless ( -f $phenotypeTable ) {
		$error .= "the cmd line switch -phenotypeTable is undefined!\n";
	}
	unless ( defined $p_value ) {
		$error .= "the cmd line switch -p_value is undefined!\n";
	}
	unless ( defined $gene_names[0] ) {
		$error .= "the cmd line switch -gene_names is undefined!\n";
	}
	unless ( defined $outfile ) {
		$error .= "the cmd line switch -outfile is undefined!\n";
	}
	unless ( defined $p4cS ) {
		$error .= "the cmd line switch -p4cS is undefined!\n";
	}
}
unless ( defined $CpU_CORES ) {
	$CpU_CORES = 1;
	warn "we set the CPU cores to 1\n";
}
unless ( defined $FREE_MEM ) {
	$error .= "the cmd line switch -FREE_MEM is undefined!\n";
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
 command line switches for Max_Performance_SNP_2_Gene_Expression.pl


   -array_values   :the table file containing the expresion values (tab separated)
   -phenotypeTable :the table containing the phenotypic data set (tab separated)
   -p_value        :the max p value for the reported test statistics
   -gene_names     :a way to select only one or several genes to do the correlation for (needed!)
   -outfile        :the name of the outfile (<tab> separated table)
   -p4cS           :the pattern to select the data containing columns

   -CpU_CORES      :the amount of CPUs I should try to use to 100%
   -FREE_MEM       :the amount of memory I am allowed to use (GB)

   -help           :print this help
   -debug          :verbose output
   

";
}

my $sh = Shell->new();
my $tableHandling = tableHandling->new(" +");

my ( $task_description, $SNP_2_Gene_Expression_call, $string, @string );

$SNP_2_Gene_Expression_call =
"perl ".root->perl_include()." ~/Link_2_My_Libs/bin/My_Project/SNP_2_Gene_Expression.pl";
$SNP_2_Gene_Expression_call .= ' -array_values ' . join( ' ', @array_values )
  if ( defined $array_values[0] );
$SNP_2_Gene_Expression_call .= " -p_value $p_value" if ( defined $p_value );
$SNP_2_Gene_Expression_call .= " -gene_names ".join(" ",@gene_names) if ( defined $gene_names[0]);

$SNP_2_Gene_Expression_call .= " -outfile $outfile" if ( defined $outfile );
$SNP_2_Gene_Expression_call .= " -p4cS '$p4cS'"       if ( defined $p4cS );

$task_description .= 'Max_Performance_SNP_2_Gene_Expression.pl';
$task_description .= ' -array_values ' . join( ' ', @array_values )
  if ( defined $array_values[0] );
$task_description .= " -phenotypeTable $phenotypeTable"
  if ( defined $phenotypeTable );
$task_description .= " -p_value $p_value"       if ( defined $p_value );
$task_description .= " -gene_names ".join(" ",@gene_names) if ( defined $gene_names[0]);
$task_description .= " -outfile $outfile"       if ( defined $outfile );
$task_description .= " -p4cS '$p4cS'"             if ( defined $p4cS );
$task_description .= " -CpU_CORES $CpU_CORES"   if ( defined $CpU_CORES );
$task_description .= " -FREE_MEM $FREE_MEM"     if ( defined $FREE_MEM );

my (
	$outpath, @SNP_files, $max_process, $kb_per_model, $max_models,
	$header,  $line,      @temp,        $temp
);

@temp = split( "/", $outfile );
pop(@temp);
$outpath = join( "/", @temp );
mkdir($outpath) unless ( -d $outpath );
$outpath .= "/temp";
mkdir($outpath) unless ( -d $outpath );
print "we will copy the data files to a temp folder: $outpath\n";
## Do whatever you want!

## first I need to estimate how many processes I should start
## that depends on the amount of available CPUs I would say,
## that 6 processes per CPU should be OK, as the R-Perl interface slows things down a lot!

$max_process = $CpU_CORES * 4;

## next we need to read the maximum amount of models in the file -
## perhaps each process can get all models to execute...
## I have estimated that each model takes about 1.1e-5 Gb of memory (including a 10% bonus)

$line       = -1;
$max_models = int( $FREE_MEM / $max_process * 1.1e+5 );
print
"I estimated for your settings ( $FREE_MEM Gb free memory and $CpU_CORES CPU cores $max_process prcesses and $max_models models per process.\n";

my $out;
open( IN, "<$phenotypeTable" )
  or die "Sorry, but I can not read from the phenotype table $phenotypeTable\n";
$line = 0; 
while (<IN>) {
	$line++;
};
close ( IN );

if ( int($line / $max_models) <  $max_process ){
	$max_models = int ($line / ( 2* $max_process ));
	print "we had to set the \$max_models to $max_models\n";
}

$line = -1; 
open( IN, "<$phenotypeTable" )
  or die "Sorry, but I can not read from the phenotype table $phenotypeTable\n";
while (<IN>) {
	$line++;
	if ( $line == 0 ) {
		$header = $_;
		next;
	}
	if ( ( $line % $max_models ) == 1 ) {
		print "line = $line; we would now create a SNP file for $line-"
		  . ( $line + $max_models ) . "\n"
		  if ($debug);
		if ( ref($out) eq "GLOB" ) {
			close($out) or die "I could not close the GLOB $out\n";
		}
		$temp = "SNPs_$line-" . ( $line + $max_models ) . ".txt";
		open( OUT, ">$outpath/$temp" )
		  or die "I could not create the models temp file $outpath/$temp\n$!\n";
		push( @SNP_files, "$outpath/$temp" );
		$out = \*OUT;
		print $out $header;
	}
	print $out $_;
}
if ( ref($out) eq "GLOB" ) {
	close(*$out);
}
if ($debug) {
	print
"I hope you now have a set of files in the folder '$outpath' that contain exactly "
	  . ( $max_models + 1 )
	  . " lines\n";
	print "I have created "
	  . scalar(@SNP_files)
	  . " SNP file\n"
	  . join( "\n", @SNP_files ), "\n";
}

## Now I have to find the best mode of creating the SNP_2_Gene_Expression calls...
## Use all genes and a subset of SNPs should be best!
my $SNP_files_perl_process = int( scalar(@SNP_files) / $max_process );
print "each process would need to calculate over $SNP_files_perl_process SNP files\n";

for (my $i = 0; $i < @SNP_files; $i ++){
	if ( $i % $SNP_files_perl_process == 0 ){
		$temp = $SNP_2_Gene_Expression_call. " -phenotypeTable";
		for ( my $a = $i; $a < $i+ $SNP_files_perl_process; $a ++ ){
			last if ($a == @SNP_files );
			$temp .= " $SNP_files[$a]";
		}
		print $temp."\n" if ( $debug );
		system ( $temp );
	}
}
&start_r_controler ();

print "All processes should now be started!\nplease look at the system load!";
sleep ( 10 );
while ( &downstream_process_working ){
	sleep ( 20 );
}
print "we have no more processes matching our SNP_2_Gene_Expression script\n";
exit 1;

sub downstream_process_working {
	$string =  $sh->ps("-A -f");
	@string = split ("\n", $string);
	my ($header);
	qx(rm -R /tmp/Rtmp*);
	foreach  $string ( @string ){	
		 if ( $string =~ m/SNP_2_Gene_Expression/ ) {
		 	next if $string =~m/$$/;
		 	return 1;
		 }		
	}
	return 0;
}

sub start_r_controler {
	my $path = "/home/stefan_l/Link_2_My_Libs";

	print "we expect the scripts to be downstream of $path/bin\n";

	my $r_controller_cmd =
	  "perl ".root->perl_include()." $path/bin/array_analysis/r_controler.pl $$";
	my ( @r_out, $last_r_pid, $temp );
	@r_out = qx( $r_controller_cmd );
	$temp = join( " ", @r_out );
	$temp =~ m/r_controler_log is '(.*)'/;
	open( R_LOG, "<$1" ) or die "could not open r_controller log '$1'\n";
	while (<R_LOG>) {
		$last_r_pid = $1
		  if ( $_ =~ m/started a r_controller instance \((\d+)\) at/ );
	}
	close(R_LOG);
	return $last_r_pid;
}

sub stop_r_controler {
	my ($last_r_pid) = @_;
	system("kill $last_r_pid");
}
