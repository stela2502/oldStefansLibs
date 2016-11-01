#! /usr/bin/perl -w

#  Copyright (C) 2011-01-10 Stefan Lang

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

=head1 create_random_cnnection_nets_from_connection_net_data.pl

tzhe script reads a conecction net and will create a configurable number of random connection nets.

To get further help use 'create_random_connection_nets_from_connection_net_data.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::expression_net_reader;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,      $debug,     $database,     $infile, $outpath,
	$R_squared, $min_links, $replications, $seeder_genes
);

Getopt::Long::GetOptions(
	"-infile=s"       => \$infile,
	"-outpath=s"      => \$outpath,
	"-R_squared=s"    => \$R_squared,
	"-min_links=s"    => \$min_links,
	"-replications=s" => \$replications,
	"-seeder_genes=s" => \$seeder_genes,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	mkdir($outpath);
}
unless ( defined $R_squared ) {
	$R_squared = 0.8;
}
unless ( defined $min_links ) {
	$min_links = 2;
}
unless ( defined $replications ) {
	$error .= "the cmd line switch -replications is undefined!\n";
}
unless ( defined $seeder_genes ) {
	$error .= "the cmd line switch -seeder_genes is undefined!\n";
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
 command line switches for create_random_connection_nets_from_connection_net_data.pl

   -infile       :the source coexpression data file
   -outpath      :the outpath
   -R_squared    :a usable r cutoff (default == 0.8)
   -min_links    :the minimal amount of links between a gene and the seeder genes (default = 2)
   -replications :how many random connection nets do you want to produce?
   -seeder_genes :the number of random seeder genes to use for a connection net

   -help           :print this help
   -debug          :verbose output
   

";
}

my ( $task_description, $expression_net_reader, $fileHandle, $restricted_net );

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/create_random_cnnection_nets_from_connection_net_data.pl';
$task_description .= " -infile $infile"       if ( defined $infile );
$task_description .= " -outpath $outpath"     if ( defined $outpath );
$task_description .= " -R_squared $R_squared" if ( defined $R_squared );
$task_description .= " -min_links $min_links" if ( defined $min_links );
$task_description .= " -replications $replications"
  if ( defined $replications );
$task_description .= " -seeder_genes $seeder_genes"
  if ( defined $seeder_genes );

## Do whatever you want!

$expression_net_reader = expression_net_reader->new( $infile, () );
$expression_net_reader =
  $expression_net_reader->restrict_R_squared_moreThan($R_squared);

## And now we need to create the random expression nets
for ( my $i = 0 ; $i < $replications ; $i++ ) {
	$restricted_net = $expression_net_reader->restrict_gene1_to_list(
		&create_random_list_of(
			$seeder_genes, keys %{ $expression_net_reader->{'gene1'} }
		)
	);
	$fileHandle =
	  $restricted_net->Logfile( $outpath . "/expression_net_statistcs.txt" );
	die "Hej, we did not get a open file handle by setting the LogFile!\n"
	  unless ( ref($fileHandle) eq "GLOB" );
	$restricted_net->output_type();
	$restricted_net->__create_connection_dataset();
	$restricted_net->__define_connection_groups($min_links);
	unless (-f "$outpath/genes.txt") {
	open( OUT, ">$outpath/genes.txt" )
	  or die
	  "sorry, but I could not create the genes report '$outpath/genes.txt'\n";
	}
	else {
		open( OUT, ">>$outpath/genes.txt" );
	}
	print OUT join( " ", sort keys %{ $restricted_net->{'defined'} } )
	  . "\n";
	close ( OUT );
	unless (-f "$outpath/connection_group_genes.txt") {
	open ( OUT ,">$outpath/connection_group_genes.txt") or die
	  "sorry, but I could not create the genes report '$outpath/connection_group_genes.txt'\n";
	}
	else {
		open( OUT, ">>$outpath/connection_group_genes.txt" );
	}
	#my $R_cmd = $expression_net_reader->getAs_R_matrix( $outpath, $min_links );
	if ( ref($restricted_net->{'cg_gene_list'}) eq "ARRAY"){
		print OUT join( " ", sort @{$restricted_net->{'cg_gene_list'}} )."\n";
		print scalar (@{$restricted_net->{'cg_gene_list'}} )." connection_net_genes\n";
	}
	else {
		print OUT "---\n";
		print "0 connection_net_genes\n";
	}
	
	close ( OUT );
}
print "You should find the statistics in the file $outpath/expression_net_statistcs.txt\n";

sub create_random_list_of{
	my ( $max, @genes ) = @_;
	my ($hash, $r );
	while ( scalar ( keys %$hash) < $max ){
		$r = int (rand ( scalar(@genes -1)));
		$hash->{$genes[$r]} = 1;
	}
	print "we got the genes ".join( " ", (keys %$hash ) ). "from the overall list!\n" if ( $debug);
	return (keys %$hash );
}