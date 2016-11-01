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

=head1 calculate_MeDIP_test.pl

Calculate the statistics for MeDIP based on NimbleGene files

To get further help use 'calculate_MeDIP_test.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::array_analysis::correlatingData::Wilcox_Test;
use stefans_libs::file_readers::MeDIP_results;
my $VERSION = 'v1.0';

my ( $help, $debug, $database, $inpath, $outpath, $wilcox_log_file );

Getopt::Long::GetOptions(
	"-inpath=s"        => \$inpath,
	"-outpath=s"       => \$outpath,
	"-stat_log_file=s" => \$wilcox_log_file,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $inpath ) {
	$error .= "the cmd line switch -inpath is undefined!\n";
}
unless ( -d $inpath ) {
	$error .= "the inpath does not exist!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the outpath does not exist!\n";
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
 This script can only be used with Marloes MAC2 converted MeDIP data, as the sample IDs are hard coded into that script!
 But as an atvantage, we can automatically determine if the statistics should be done in paired mode ;-)
 
 $errorMessage
 
 command line switches for calculate_MeDIP_test.pl

   -inpath           :the path tothe MAC2 converted MeDIP files
   -outpath          :the path to store all the outfiles to
   -stat_log_file    :a file where we would report all statistics to ! will be huge !
   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'calculate_MeDIP_test.pl';
$task_description .= " -inpath $inpath" if ( defined $inpath );
$task_description .= " -outpath $outpath" if ( defined $outpath );
$task_description .= " -stat_log_file $wilcox_log_file"
  if ( defined $wilcox_log_file );

my $nimbelID_2_Sample_id = {
	'32238502' => '34907_2',
	'32238802' => '34901_1',
	'32266502' => '34901_2',
	'32266802' => '34908_2',
	'32269902' => '34912_2',
	'32270202' => '34908_1',
	'32270502' => '34902_1',
	'32286002' => '34910_1',
	'32286302' => '34904_2',
	'32291802' => '34907_1',
	'32292102' => '34906_1',
	'32333802' => '34912_1',
	'32334102' => '34906_2',
	'32339202' => '34904_1',
	'32339502' => '34900_1',
	'32392402' => '34893_2',
	'32397502' => '34900_2',
	'32397802' => '34910_2',
	'32404002' => '34902_2',
	'32434102' => '34896_1',
	'32434402' => '34897_1',
	'32434702' => '34894_2',
	'32435002' => '34894_1',
	'32449502' => '34895_2',
	'32474602' => '34915_1',
	'32482402' => '34925_1',
	'32482702' => '34915_2',
	'32496402' => '34919_2',
	'32496702' => '34930_1',
	'32497002' => '34927_2',
	'32497302' => '34928_2',
	'32518502' => '34931_1',
	'32522402' => '34921_2',
	'32523902' => '34926_1',
	'32524202' => '34921_1',
	'32532502' => '34926_2',
	'32550202' => '34923_1',
	'32550502' => '34925_2',
	'32564702' => '34930_2',
	'32574602' => '34932_2',
	'32607302' => '34919_1',
	'32613202' => '34927_1',
	'32613502' => '34928_1',
	'32628102' => '34923_2',
	'32709302' => '34931_2',
	'33147902' => '34899_2',
	'33156902' => '34892_1',
	'33163702' => '34895_1',
	'33164002' => '34893_1',
	'33164302' => '34898_2',
	'33164602' => '34885_2',
	'33174502' => '34896_2',
	'33175102' => '34885_1',
	'33175402' => '34899_1',
	'33175702' => '34892_2',
	'33203102' => '34932_1',
	'33232502' => '34897_2',
	'33308702' => '34898_1'
};

## Do whatever you want!

## Identify the files!
my ( $data_hash, $OligoIDs );
$data_hash = &read_files(1);
$error     = '';
foreach my $sampleID ( values %$nimbelID_2_Sample_id ) {
	$error .= "we miss the data for sample $sampleID\n"
	  unless ( defined $data_hash->{$sampleID} );
}
die $error if ( $error =~ m/\w/ );
my $phenotypes = {
	    ## Changes applied due to an error in the sample FH mapping
        ## reported on 11.02.11 by Charlotte Ling
        ## Sample 34901 is FH +
        ## Sample 34926 is FH -
        #'FH_p' => [
        #       qw(34885 34893 34894 34895 34896 34898 34900 34902 34906 34910 34912 34919 34926 34927 34928 34932)
        #],
        #'FH_p_before_ex' => [
        #       qw( 34885_1 34893_1 34894_1 34895_1 34896_1 34898_1 34900_1 34902_1 34906_1 34910_1 34912_1 34919_1 34926_1 34927_1 34928_1 34932_1 )
        #],
        #'FH_p_after_ex' => [
        #       qw( 34885_2 34893_2 34894_2 34895_2 34896_2 34898_2 34900_2 34902_2 34906_2 34910_2 34912_2 34919_2 34926_2 34927_2 34928_2 34932_2 )
        #],
        'FH_p' => [
                qw(34885 34893 34894 34895 34896 34898 34900 34906 34910 34912 34919 34901 34927 34928 34932)
        ],
        'FH_p_before_ex' => [
                qw( 34885_1 34893_1 34894_1 34895_1 34896_1 34898_1 34900_1 34906_1 34910_1 34912_1 34919_1 34901_1 34927_1 34928_1 34932_1 )
        ],
        'FH_p_after_ex' => [
                qw( 34885_2 34893_2 34894_2 34895_2 34896_2 34898_2 34900_2 34906_2 34910_2 34912_2 34919_2 34901_2 34927_2 34928_2 34932_2 )
        ],

        ## removed due to an issue with the sample FH connection reported 11.02.11 by Charlotte Ling
        #'FH_n' => [
        #       qw( 34892 34897 34899 34901 34904 34907 34908 34915 34921 34923 34925 34930 34931 )
        #],
        #'FH_n_before_ex' => [
        #        qw( 34892_1 34897_1 34899_1 34901_1 34904_1 34907_1 34908_1 34915_1 34921_1 34923_1 34925_1 34930_1 34931_1 )
        #],
        #'FH_n_after_ex' => [
        #        qw( 34892_2 34897_2 34899_2 34901_2 34904_2 34907_2 34908_2 34915_2 34921_2 34923_2 34925_2 34930_2 34931_2 )
        #],
        'FH_n' => [
               qw( 34892 34897 34899 34926 34904 34907 34908 34915 34921 34923 34925 34930 34931 )
        ],
        'FH_n_before_ex' => [
                qw( 34892_1 34897_1 34899_1 34926_1 34904_1 34907_1 34908_1 34915_1 34921_1 34923_1 34925_1 34930_1 34931_1 )
        ],
        'FH_n_after_ex' => [
                qw( 34892_2 34897_2 34899_2 34926_2 34904_2 34907_2 34908_2 34915_2 34921_2 34923_2 34925_2 34930_2 34931_2 )
          ],
        'before_ex' => [
                qw( 34885_1 34893_1 34894_1 34895_1 34896_1 34898_1 34900_1 34906_1 34910_1 34912_1 34919_1 34926_1 34927_1 34928_1 34932_1 ),
                qw( 34892_1 34897_1 34899_1 34901_1 34904_1 34907_1 34908_1 34915_1 34921_1 34923_1 34925_1 34930_1 34931_1 )
        ],
        'after_ex' => [
                qw( 34885_2 34893_2 34894_2 34895_2 34896_2 34898_2 34900_2 34906_2 34910_2 34912_2 34919_2 34926_2 34927_2 34928_2 34932_2 ),
                qw( 34892_2 34897_2 34899_2 34901_2 34904_2 34907_2 34908_2 34915_2 34921_2 34923_2 34925_2 34930_2 34931_2 )
        ]
};
$phenotypes->{'FH_p'} =
  [ @{ $phenotypes->{'FH_p_before_ex'} }, @{ $phenotypes->{'FH_p_after_ex'} } ];
$phenotypes->{'FH_n'} =
  [ @{ $phenotypes->{'FH_n_before_ex'} }, @{ $phenotypes->{'FH_n_after_ex'} } ];
$error = '';
foreach my $phenotype ( keys %$phenotypes ) {
	foreach my $sampleID ( @{ $phenotypes->{$phenotype} } ) {
		$error .=
"ther is an error in the pgenotype '$phenotype', as we do not know the sample id '$sampleID'\n"
		  unless ( defined $data_hash->{$sampleID} );
	}
}
die $error if ( $error =~ m/\w/ );

$data_hash = &read_files();

print " ---- got all data (" . scalar( keys %$data_hash ) . ") ----\n";
print "And I got the oligoIDs " . join( " ", @$OligoIDs ) . "\n";
## Now we need to calculate the statistics!!

## OK - do some real work....
## we need to calculate
#  1. FH_p versus FH_n (add _1 and _2 to the datasets!)
&calculate_Wilcox( "$outpath/FH_p_vs_FH_n.txt", 'FH_p', 'FH_n', 0 );

#
##  2. FH_p_before_ex versus FH_p_after_ex (paried)
&calculate_Wilcox( "$outpath/FH_p_before_ex_vs_after_ex.txt",
	'FH_p_before_ex', 'FH_p_after_ex', 1 );

#
##  3. FH_n_before_ex versus FH_n_after_ex (paired)
&calculate_Wilcox( "$outpath/FH_n_before_ex_vs_after_ex.txt",
	'FH_n_before_ex', 'FH_n_after_ex', 1 );

#
##  4. FH_p_before_ex versus FH_n_before_ex
&calculate_Wilcox( "$outpath/FH_p_before_ex_vs_FH_n_before_ex.txt",
	'FH_p_before_ex', 'FH_n_before_ex', 0 );

#
##  5. FH_p_after_ex versus FH_n_after_ex
&calculate_Wilcox( "$outpath/FH_p_after_ex_vs_FH_n_after_ex.txt",
	'FH_p_after_ex', 'FH_n_after_ex', 0 );

&calculate_Wilcox( "$outpath/before_ex_vs_after_ex.txt",
	'before_ex', 'after_ex', 1 );

print "hopefully you find all the p_values in the oupath $outpath\n";

sub read_files {
	my ($test) = @_;

	my ( @dir, @subdir, $NimbleGene_ID, $data_file, $data_hash );
	opendir( DIR, $inpath ) or die "could not open inpath $inpath\n";
	@dir = readdir(DIR);
	closedir(DIR);
	foreach my $path1 (@dir) {
		next unless ( $path1 =~ m/^\d\d\d\d\d_/ );
		next unless ( -d "$inpath/$path1" );
		print "we access path $inpath/$path1\n";
		opendir( DIR, "$inpath/$path1" )
		  or die "could not open data path $inpath/$path1\n";
		@subdir = readdir(DIR);
		closedir(DIR);
		foreach my $file (@subdir) {
			unless ( $file =~ m/.mod$/ ) {
				print "File $file is not of interest!\n";
				next;
			}

			$NimbleGene_ID = undef;
			$NimbleGene_ID = $1
			  if ( $file =~ m/MA2C_(\d+)_normalized.txt.mod/ );
			unless ( defined $NimbleGene_ID ) {
				warn
"Sorry I could not get the Nimblegene ID from the file $file\n";
				next;
			}
			unless ( defined $nimbelID_2_Sample_id->{$NimbleGene_ID} ) {
				warn
				  "Sorry but I do not know the NimbelGene id $NimbleGene_ID!\n";
				next;
			}
			print "we read from file $file\n";
			if ($test) {
				$data_hash->{ $nimbelID_2_Sample_id->{$NimbleGene_ID} } = {};
				if ( defined $debug ) {
					system("mkdir -p ~/debug/$path1");
					system(
"head -n 2000 $inpath/$path1/$file > ~/debug/$path1/$file"
					);
				}
			}
			else {
				$data_file = data_table->new();
				if ($debug) {
					$data_file->read_file( "$inpath/$path1/$file", 6000 );
				}
				else {
					$data_file->read_file("$inpath/$path1/$file");
				}

				$data_hash->{ $nimbelID_2_Sample_id->{$NimbleGene_ID} } =
				  $data_file->getAsHash( 'PROBE_ID', 'NormalizedLog2Ratio' );
				$OligoIDs = [
					keys %{
						$data_hash->{ $nimbelID_2_Sample_id->{$NimbleGene_ID} }
					  }
				  ]
				  unless ( ref($OligoIDs) eq "ARRAY" );

				#print "I got the oligoIDs ".join("; ",@$OligoIDs )."\n";
			}
		}
	}
	return $data_hash;
}

sub calculate_Wilcox {
	my ( $filename, $group_1, $group_2, $paired ) = @_;
	my ( $rv, $Wilcox_Test, $data_table, $i, @temp );
	return 1 if ( -f $filename );
	$Wilcox_Test = Wilcox_Test->new();
	$Wilcox_Test->define_log($wilcox_log_file);
	$Wilcox_Test->add_2_log(
		"Starting to calculate the statistice written to file '$filename'\n");
	$Wilcox_Test->add_2_log( "Sample_ids for group A:\t"
		  . join( "\t", @{ $phenotypes->{$group_1} } )
		  . "" );
	$Wilcox_Test->add_2_log( "Sample_ids for group B:\t"
		  . join( "\t", @{ $phenotypes->{$group_1} } )
		  . "" );
	$data_table = stefans_libs_file_readers_MeDIP_results->new();

	unless ($paired) {
		$data_table->Add_2_Description(
			    "the p value comes from a Wilcox Test between #"
			  . scalar( @{ $phenotypes->{$group_1} } )
			  . "samples in the first group and #"
			  . scalar( @{ $phenotypes->{$group_1} } )
			  . "samples in the second group\n" );
	}
	else {
		$data_table->Add_2_Description(
			    "the p value comes from a PAIRED Wilcox Test between #"
			  . scalar( @{ $phenotypes->{$group_1} } )
			  . "samples in the first group and #"
			  . scalar( @{ $phenotypes->{$group_1} } )
			  . "samples in the second group\n" );
		$Wilcox_Test->SET_pairedTest(1);
	}
	$data_table->Add_2_Description(
		"group 1:\t" . join( "\t", @{ $phenotypes->{$group_1} } ) . "\n" );
	$data_table->Add_2_Description(
		"group 2:\t" . join( "\t", @{ $phenotypes->{$group_2} } ) . "\n" );

	$i = 0;
	my ( $log_val, $groupA, $groupB, $n ,$stdA, $stdB );
	foreach my $oligoName (@$OligoIDs) {
		$rv = undef;
		$Wilcox_Test->add_2_log("statistics for oligo $oligoName:\n");
		$groupA = &getValues_ArrayRef( $phenotypes->{$group_1}, $oligoName );
		$groupB = &getValues_ArrayRef( $phenotypes->{$group_2}, $oligoName );
		$rv = $Wilcox_Test->_calculate_wilcox_statistics( $groupA, $groupB );
		($groupA, $n ,$stdA)  = root->getStandardDeviation($groupA);
		($groupB, $n ,$stdB) = root->getStandardDeviation($groupB);
		unless ( defined $rv ) {
			@temp = (1);
		}
		else {
			@temp = split( "\t", $rv );
		}
		$i++;
		if ( $i % 5000 == 0 ) {
			print
"we have done $i calculations - still alive! (oligo_name = $oligoName)\n";
			if ($debug) {
				print
"but as we are in debug mode we will stop that calculation!\n";
				last;
			}
		}
		$log_val = -( &log10( $temp[0] ) );
		print
"we got the statistics for oligo $oligoName: $rv\n\tlog_val = $log_val\n"
		  if ( $log_val > 3.5 );
		$groupB = 0.000001 if ( $groupB == 0);
		$data_table->Add_Dataset(
			{
				'Oligo_id'          => $oligoName,
				'p value'           => -( &log10( $temp[0] ) ),
				'mean1'             => $groupA,
				'mean2'             => $groupB,
				'std1' => $stdA,
				'std2' => $stdB,
				'fold_change [A/B]' => ( $groupA / $groupB )
			}
		);
	}
	$data_table->print2file($filename);
	return $data_table;
}

sub log10 {
	my $n = shift;
	unless ( $n > 0 ) {
		warn "we can not take the log of that entry ($n)!\n";
		return undef;
	}
	return log($n) / log(10);
}

sub getValues_ArrayRef {
	my ( $sampleIDs, $oligoID ) = @_;
	die "Sorry, but I need an array of sampleIDs, not $sampleIDs \n"
	  unless ( ref($sampleIDs) eq "ARRAY" );
	my @return;
	for ( my $i = 0 ; $i < @$sampleIDs ; $i++ ) {
		die "sorry, but I do not know the sample_id @$sampleIDs[$i] \n"
		  unless ( ref( $data_hash->{ @$sampleIDs[$i] } ) eq "HASH" );
		$return[$i] = $data_hash->{ @$sampleIDs[$i] }->{$oligoID};
	}
	return \@return;
}
