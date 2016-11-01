#! /usr/bin/perl -w

#  Copyright (C) 2010-09-17 Stefan Lang

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

=head1 prioritize_SNP_highlighted_regions.pl

A script, that will create a summary table over all the SNP_highlight files created for a larger study.

To get further help use 'prioritize_SNP_highlighted_regions.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $inpath, $outfile);

Getopt::Long::GetOptions(
	 "-inpath=s"    => \$inpath,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -d $inpath) {
	$error .= "the cmd line switch -inpath is undefined!\n";
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
 command line switches for prioritize_SNP_highlighted_regions.pl

   -inpath   :a path containing the result paths from multiple 
              describe_SNP_2_gene_expression_results.pl calls
   -outfile  :a outfile where information about all chromosomal 
              regions is summed up

   -help     :print this help
   -debug    :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'prioritize_SNP_highlighted_regions.pl';
$task_description .= " -inpath $inpath" if (defined $inpath);
$task_description .= " -outfile $outfile" if (defined $outfile);

my (@dirs, @files, $file, $cutoff,$hash, $out_table, $gene, $this_table, $line_hashes );

opendir ( DIR, "$inpath" );
@dirs = readdir(DIR);
closedir ( DIR );

$out_table = data_table->new();
foreach ('islet expression gene','high p value cutoff', 'chromosome','start','end','low stat cutoff [n]','hight stat cut off [n]','rsIDs' ) {
	$out_table->Add_2_Header ( $_ );
}

foreach my $dir ( @dirs ) {
	print "we look into the subdir $dir\n" if ( $debug );
	if (-d "$inpath/$dir" ){
		opendir ( DIR, "$inpath/$dir" );
		@files = readdir(DIR);
		closedir ( DIR );
		foreach $file ( @files ) {
			print "we have got a file named $file\n" if ( $debug );
			if ( $file =~ m/SNP_highlight_([\de\-]+).tsv/){
				print "and we have identfied a target file!\n" if ( $debug );
				$cutoff = $1;
				$gene = $dir;
				$this_table = undef;
				$this_table = data_table->new();
				$this_table->read_file ("$inpath/$dir/$file");
				$line_hashes = $this_table->GetAll_AsHashArrayRef();
				foreach $hash ( @$line_hashes ){
					$hash->{'islet expression gene'} = $gene;
					$hash->{'high p value cutoff'} = $cutoff;
					$out_table->AddDataset($hash);
				}
			}
		}
	}
}

$out_table->print2file( $outfile );
print "We have saved the data in table $outfile \n";
## Do whatever you want!

