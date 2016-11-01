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

=head1 extract_oligos_fromm_NimbleGene_GFF_file.pl

A script to search NimbleGene GFF oligo files and an oligo2DNA table file to 
identify the location of oligos in any genome. The oligo2DNA table has to be 
genome specific.

To get further help use 'MeDIP_extract_oligos_from_array_files.pl -help' 
at the command line.

=cut

use Getopt::Long;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo;
use stefans_libs::array_analysis::correlatingData::Wilcox_Test;
use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,                     $debug,
	$database,                 $GFF_file,
	$olgio2DNA_file,           $outfile,
	$cutoff,                   $organism_tag,
	@array_dataset_ids_groupA, @array_dataset_ids_groupB,
	$genome_version,           @expression_files,
	$orig_data_path,           $medip_A,
	$pairedStatistics,         $medip_B,
	$wilcox_log_file
);

Getopt::Long::GetOptions(
	"-GFF_file=s"                    => \$GFF_file,
	"-olgio2DNA_file=s"              => \$olgio2DNA_file,
	"-outfile=s"                     => \$outfile,
	"-cutoff=s"                      => \$cutoff,
	"-organism_tag=s"                => \$organism_tag,
	"-genome_version=s"              => \$genome_version,
	"-expression_files=s{,}"         => \@expression_files,
	"-array_dataset_ids_groupA=s{,}" => \@array_dataset_ids_groupA,
	"-array_dataset_ids_groupB=s{,}" => \@array_dataset_ids_groupB,
	"-orig_data_path=s"              => \$orig_data_path,
	"-pairedStatistics"              => \$pairedStatistics,
	"-stat_log_file=s"               => \$wilcox_log_file,
	"-help"                          => \$help,
	"-debug"                         => \$debug,
	"-database=s"                    => \$database
);

my $error   = '';
my $warning = '';

unless ( defined $GFF_file ) {
	$error .= 'the cmd line switch -GFF_file is undefined!' . "\n";
}
unless ( defined $olgio2DNA_file ) {
	$error .= 'the cmd line switch -olgio2DNA_file is undefined!' . "\n";
}
unless ( defined $outfile ) {
	$error .= 'the cmd line switch -outfile is undefined!' . "\n";
}
unless ( defined $cutoff ) {
	$error .= 'the cmd line switch -cutoff is undefined!' . "\n";
}
unless ( defined $array_dataset_ids_groupA[0] ) {
	$warning .=
	  'the cmd line switch -array_dataset_ids_groupA is undefined!' . "\n";
}
unless ( defined $array_dataset_ids_groupB[0] ) {
	$warning .=
	  'the cmd line switch  array_dataset_ids_groupB is undefined!' . "\n";
}
unless ( -d $orig_data_path ) {
	$warning .=
"we can not add the mean and std for the original data as you did not specifiy where we can look for the data (-orig_data_path)!\n";
}

unless ( -f $expression_files[0] ) {
	$warning .=
"we could add expression data to the result if you would provide any (expression_files)!\n";
}
elsif ( $warning =~ m/array_dataset_ids_group/ ) {
	$error .=
	    "we can not evaluate the expression files "
	  . join( ", ", @expression_files )
	  . " if we do not have both array_dataset_ids_groups!\n";
}
if ( $warning =~ m/\w/ ) {
	warn $warning . "But we can do without this information!\n";
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
 
 This script is a dirty hack to get the results from the MeDip chip exeriments as fast as possible.
 Once the database supports the results of the Wilcox over two serach results,
 this script has to be updated to use only the database and not the nimblegene info files!!
 
 command line switches for extract_oligos_fromm_NimbleGene_GFF_file.pl

   -GFF_file       :the NimbleGene GFF file containing the oligo informations
   -olgio2DNA_file :the NimbleGene Signalmap genome info file
   -outfile        :the file where the results table should be stored
   -cutoff         :the cutoff to apply to the GFF values ( >= cutoff will be used)
   -expression_files :some files containing expression estimates; 
                      the column headers have to match the 'array_dataset_ids'
   -orig_data_path :the path to a list of NimbleGene datasets. 
                    Please look at my 'read_original_data' function if you I not read from your path! 
   
   -array_dataset_ids_groupA : the array dataset ids that were used for the one group
   -array_dataset_ids_groupB : the array dataset ids, that were used for the second group
   
   -pairedStatistics :If you use that option, we will try to calculate the expression statistics in paired mode!
   -stat_log_file    :a file where we would report all statistics to ! will be huge !
   
   -help           :print this help
   -debug          :verbose output

";
}
my $task_description .= 'MeDIP_extract_oligos_from_array_files.pl';
$task_description .= " -GFF_file $GFF_file" if ( defined $GFF_file );
$task_description .= " -olgio2DNA_file $olgio2DNA_file"
  if ( defined $olgio2DNA_file );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -cutoff $cutoff"   if ( defined $cutoff );
$task_description .= " -organism_tag $organism_tag"
  if ( defined $organism_tag );
$task_description .= " -genome_version $genome_version"
  if ( defined $genome_version );
$task_description .= ' -expression_files ' . join( ' ', @expression_files )
  if ( defined $expression_files[0] );
$task_description .=
  ' -array_dataset_ids_groupA ' . join( ' ', @array_dataset_ids_groupA )
  if ( defined $array_dataset_ids_groupA[0] );
$task_description .=
  ' -array_dataset_ids_groupB ' . join( ' ', @array_dataset_ids_groupB )
  if ( defined $array_dataset_ids_groupB[0] );
$task_description .= " -pairedStatistics" if ($pairedStatistics);
$task_description .= " -stat_log_file $wilcox_log_file"
  if ( defined $wilcox_log_file );

print "\nCommand:\n$task_description\n\n";

my (
	$gffFile,         $oligo_Data, $oligoLocations, $genomeDB,
	$genomeInterface, $temp,       $var,            $array,
	@data,            $datafile,   $fastaDB,        @temp,
	$CpG_count
);

unless ( -f "$outfile.$cutoff.nearby_genes" ) {
	open( LOG, ">$outfile.$cutoff.nearby_genes.log" )
	  or die "could not create the log file $outfile.$cutoff.nearby_genes\n";
	print LOG $task_description . "\n";
	close(LOG);

	$gffFile = gffFile->new();
	$oligo_Data = $gffFile->GetData( $GFF_file, 'preserve_structure' );

	$datafile = data_table->new();

	$temp = $var = 0;
	my @good_data;
	foreach $array (@$oligo_Data) {
		warn
"$array->{'description'} we compare '$array->{'value'}' to '$cutoff'\n"
		  unless ( defined $array->{'value'} );
		if ( $array->{'value'} >= $cutoff ) {
			push( @good_data, $array );
			$temp++;
		}
		else {
			$var++;
		}
	}
	foreach (
		( 'oligoID', 'oligo_sequence', 'CpG content [n]', '-log10(p_value)' ) )
	{
		$datafile->Add_2_Header($_);
	}
	$datafile->createIndex('oligoID');
	foreach $array (@good_data) {
		@temp = ( $1, $2 )
		  if ( $array->{'description'} =~ m/=([AaGgTtCc]+);.*(CHR[\d\w]+\d+)/ );

		#die "$array->{'description'} was converted to ".join(", ",@temp)."\n";
		$CpG_count = 0;
		$temp[0] = uc( $temp[0] );
		while ( $temp[0] =~ s/CG/cg/ ) {
			$CpG_count++;
		}
		$datafile->Add_Dataset(
			{
				'oligoID'         => $temp[1],
				'CpG content [n]' => $CpG_count,
				'-log10(p_value)' => $array->{'value'},
				'oligo_sequence'  => $temp[0]
			}
		);
	}
	$datafile->print2file("$outfile.$cutoff.oligoIDs");
	$oligo_Data = \@good_data;
	print
"After applying the cutoff $cutoff we have $temp oligos left in the dataset, $var oligos were removed\n";

## now we need to set up the position identification
	my ( @temp, $temp_data );

	my $Nimblegene_GeneInfo = Nimblegene_GeneInfo->new($debug);
	foreach ( ( 'Gene Symbol', 'relative location [bp]' ) ) {
		$datafile->Add_2_Header($_);
	}

	$Nimblegene_GeneInfo->GetData($olgio2DNA_file);
	$temp_data =
	  $Nimblegene_GeneInfo->get_closeby_gene_PROMOTER_MODE($oligo_Data);
	foreach my $oligo ( sort $datafile->getIndex_Keys('oligoID') ) {
		print "we have the oligoId $oligo\n";
		next unless ( defined $oligo );
		next unless ( ref( $temp_data->{$oligo}->{'genes'} ) eq "ARRAY" );
		print "we got the genes "
		  . join( ", ", @{ $temp_data->{$oligo}->{'genes'} } )
		  . "for the oligoid $oligo\n";
		@temp = split( "\t", $oligo );
		for ( my $i = 0 ; $i < @{ $temp_data->{ $temp[0] }->{'genes'} } ; $i++ )
		{
			print
"we got the gene @{$temp_data->{$oligo}->{'genes'}}[$i] and the location @{$temp_data->{$oligo}->{'location'}}[$i]\n";
			$datafile->Add_dataset_for_entry_at_index(
				{
					'Gene Symbol' => @{ $temp_data->{$oligo}->{'genes'} }[$i],
					'relative location [bp]' =>
					  @{ $temp_data->{$oligo}->{'location'} }[$i]
				},
				$temp[0],
				'oligoID'
			);
		}
	}
	$datafile->print2file("$outfile.$cutoff.nearby_genes");

}
else {
	$datafile = data_table->new();
	$datafile->read_file("$outfile.$cutoff.nearby_genes");
}

## now we need to add the men and std of the two groups to the file
unless ( -f "$outfile.$cutoff.nearby_genes.with_expression_data" ) {

  #my ( $rv, $dataInterfaceA, $dataInterfaceB, $array_dataset, $nucleotoide_lib,
  #	$lastHeader );

	my (
		$expressions,        $insert2columns, @sample_ids_A,
		@sample_ids_B,       $description,    $tableHandling,
		$Wilcox_Test,        $root,           $mean,
		$std,                @p_value,        $unused,
		@dataA,              @dataB,          @P_value_columns,
		$pvalue_summary_col, $samples_added
	);

	$datafile->createIndex('Gene Symbol');
	$tableHandling = tableHandling->new();
	$Wilcox_Test   = Wilcox_Test->new();
	$Wilcox_Test->define_log($wilcox_log_file);
	$Wilcox_Test->add_2_log("Calcultaion of expression differences:");
	$Wilcox_Test->SET_pairedTest($pairedStatistics);
	$root = root->new();
	$samples_added =
	  0;    ## if we have added the sample information to the log file

	($pvalue_summary_col) = $datafile->Add_2_Header("all p values < 0.05");

	foreach my $expression_table (@expression_files) {
		$expressions = data_table->new();
		$expressions->read_file($expression_table);
		$expression_table =~ s/\.summary\.txt//;
		$expression_table =~ s/.*\///g;
		$description = $expression_table;
		$expressions->createIndex('Gene Symbol');
		$insert2columns->{'p_value'} =
		  $datafile->Add_2_Header( $description . " p value" );
		push( @P_value_columns, $insert2columns->{'p_value'} );
		$insert2columns->{'mean A'} =
		  $datafile->Add_2_Header( $description . " mean A" );
		$insert2columns->{'std A'} =
		  $datafile->Add_2_Header( $description . " std A" );
		$insert2columns->{'mean B'} =
		  $datafile->Add_2_Header( $description . " mean B" );
		$insert2columns->{'std B'} =
		  $datafile->Add_2_Header( $description . " std B" );
		## get the sample IDs for group A
		unless ( defined $array_dataset_ids_groupA[1] ) {
			@sample_ids_A = $tableHandling->get_column_entries_4_columns(
				join( "\t", @{ $expressions->{'header'} } ),
				$tableHandling->identify_columns_of_interest_patternMatch(
					join( "\t", @{ $expressions->{'header'} } ),
					$array_dataset_ids_groupA[0]
				)
			);
		}
		else {
			@sample_ids_A = $tableHandling->get_column_entries_4_columns(
				join( "\t", @{ $expressions->{'header'} } ),
				$tableHandling->identify_columns_of_interest_bySearchHash(
					join( "\t", @{ $expressions->{'header'} } ),
					$tableHandling->createSearchHash(@array_dataset_ids_groupA)
				)
			);
		}
		unless ($samples_added) {
			$Wilcox_Test->add_2_log( "sample_ids for group A\t"
				  . join( "\t", @sample_ids_A )
				  . "\n" );
			$Wilcox_Test->add_2_log( "sample_ids for group B\t"
				  . join( "\t", @sample_ids_B )
				  . "\n" );
		}
		$Wilcox_Test->add_2_log("Start for exprtession set $description:\n");
		$datafile->Add_2_Description(
"sample IDs for group A and for the expression estimate $description = "
			  . join( ";", @sample_ids_A )."\n" );
		$expressions->define_subset( 'groupA', \@sample_ids_A );
		## get the sample IDs for group B
		unless ( defined $array_dataset_ids_groupB[1] ) {
			@sample_ids_B = $tableHandling->get_column_entries_4_columns(
				join( "\t", @{ $expressions->{'header'} } ),
				$tableHandling->identify_columns_of_interest_patternMatch(
					join( "\t", @{ $expressions->{'header'} } ),
					$array_dataset_ids_groupB[0]
				)
			);
		}
		else {
			@sample_ids_B = $tableHandling->get_column_entries_4_columns(
				join( "\t", @{ $expressions->{'header'} } ),
				$tableHandling->identify_columns_of_interest_bySearchHash(
					join( "\t", @{ $expressions->{'header'} } ),
					$tableHandling->createSearchHash(@array_dataset_ids_groupB)
				)
			);
		}
		$Wilcox_Test->add_2_log("Calcultaion of expression differences:\n");
		$datafile->Add_2_Description(
"sample IDs for group B and for the expression estimate $description = "
			  . join( ";", @sample_ids_B )."\n" );
		$expressions->define_subset( 'groupB', \@sample_ids_B );
		## now I need to calculate the statistics and add all the wanted columns to the file!
		foreach my $gene ( $datafile->getIndex_Keys('Gene Symbol') ) {
			next
			  unless (
				defined $expressions->get_rowNumbers_4_columnName_and_Entry(
					'Gene Symbol', $gene
				)
			  );
			## OK - we have an entry for that gene in the expression dataset
			@dataA =
			  $expressions->get_value_for( 'Gene Symbol', $gene, 'groupA' );
			@dataB =
			  $expressions->get_value_for( 'Gene Symbol', $gene, 'groupB' );
			( $mean, $unused, $std ) = $root->getStandardDeviation( \@dataA );
			$datafile->Add_Dataset(
				{
					'Gene Symbol'            => $gene,
					$description . " mean A" => $mean,
					$description . " std A"  => $std
				}
			);
			( $mean, $unused, $std ) = $root->getStandardDeviation( \@dataB );
			$datafile->Add_Dataset(
				{
					'Gene Symbol'            => $gene,
					$description . " mean B" => $mean,
					$description . " std B"  => $std
				}
			);
			$Wilcox_Test->add_2_log( "calculation for gene $gene:\n");
			@p_value =
			  split( "\t",
				$Wilcox_Test->_calculate_wilcox_statistics( \@dataA, \@dataB )
			  );
			$datafile->Add_Dataset(
				{
					'Gene Symbol'             => $gene,
					$description . " p value" => $p_value[0]
				}
			);
		}
	}
	my $bin;
	foreach my $line_array ( @{ $datafile->{'data'} } ) {
		$bin = '';
		foreach ( @$line_array[@P_value_columns] ) {
			next unless ( defined $_ );
			next unless ( $_ =~ m/\d/ );
			if ( $_ <= 0.05 && !( $bin eq "NO" ) ) {
				$bin = 'YES';
			}
			else {
				$bin = 'NO';
			}
		}
		@$line_array[$pvalue_summary_col] = $bin;
	}

	$datafile->print2file("$outfile.$cutoff.nearby_genes.with_expression_data");
}
else {
	$datafile->read_file("$outfile.$cutoff.nearby_genes.with_expression_data");
}

unless ( -f "$outfile.$cutoff.nearby_genes.with_expression_data.MeDIP_data" ) {
	unless ( defined $orig_data_path ) {
		warn
"we can not analyze the original MeDIP data, as you have not supplied the right path!\n";
	}
	else {
		## Here I now have to change to my new script!
		my $dataset = &read_original_data($orig_data_path);
		my $math    = root->new();
		my ( @valuesA, @valuesB, $groupA, $groupB, $hash );
		$groupA = data_table->new();
		$groupB = data_table->new();
		foreach ( ( 'oligoID', @array_dataset_ids_groupA ) ) {
			$groupA->Add_2_Header($_);
		}
		foreach ( ( 'oligoID', @array_dataset_ids_groupB ) ) {
			$groupB->Add_2_Header($_);
		}
		foreach (
			(
				'MeDIP mean difference [B - A]',
				"MeDIP mean Group A",
				"MeDIP std Group A",
				"MeDIP mean Group B",
				"MeDIP std Group B"
			)
		  )
		{
			$datafile->Add_2_Header($_);
		}
		foreach my $oligoID ( @{ $datafile->get_column_entries('oligoID') } ) {

			# now we need to get the data
			# using &getValues_ArrayRef( $sampleIDs, $oligoID, $data_hash )

			@valuesA = @valuesB = undef;
			@valuesA = @{
				&getValues_ArrayRef( \@array_dataset_ids_groupA, $oligoID,
					$dataset )
			  };

			$hash = { 'oligoID' => $oligoID };
			for ( my $i = 0 ; $i < @array_dataset_ids_groupA ; $i++ ) {
				$hash->{ $array_dataset_ids_groupA[$i] } = $valuesA[$i];
			}
			$groupA->Add_Dataset($hash);
			@valuesA = $math->getStandardDeviation( \@valuesA );
			@valuesB = @{
				&getValues_ArrayRef( \@array_dataset_ids_groupB,
					, $oligoID, $dataset )
			  };
			$hash = { 'oligoID' => $oligoID };
			for ( my $i = 0 ; $i < @array_dataset_ids_groupB ; $i++ ) {
				$hash->{ $array_dataset_ids_groupB[$i] } = $valuesB[$i];
			}
			$groupB->Add_Dataset($hash);
			@valuesB = $math->getStandardDeviation( \@valuesB );

			$datafile->Add_Dataset(
				{
					'oligoID'                       => $oligoID,
					'MeDIP mean difference [B - A]' => $valuesB[0] -
					  $valuesA[0],
					"MeDIP mean Group A" => $valuesA[0],
					"MeDIP std Group A"  => $valuesA[2],
					"MeDIP mean Group B" => $valuesB[0],
					"MeDIP std Group B"  => $valuesB[2],
				}
			);
		}

#Add a possibillity to add mean and std together with raw MeDIP gff values to the scripts.
		$groupA->print2file(
"$outfile.$cutoff.nearby_genes.with_expression_data.MeDIP_data.groupA"
		);
		$groupB->print2file(
"$outfile.$cutoff.nearby_genes.with_expression_data.MeDIP_data.groupB"
		);
		$datafile->merge_with_data_table($groupA);
		$datafile->Add_2_Header("<- group A vs. group B ->");
		$datafile->merge_with_data_table($groupB);
		$datafile->print2file(
			"$outfile.$cutoff.nearby_genes.with_expression_data.MeDIP_data");
		print
"The final data file has been created as '$outfile.$cutoff.nearby_genes.with_expression_data.MeDIP_data'\n";
	}

}

sub not_in_second_array {
	my ( $first, $second ) = @_;
	return "we need two arrays!! not $first and $second\n"
	  unless ( ref($first) eq "ARRAY" && ref($second) eq "ARRAY" );
	my ( @return, $OK, $a, $b );
	foreach $a (@$first) {
		$OK = 0;
		foreach $b (@$second) {
			$OK = 1 if ( $a eq $b );
		}
		push( @return, $a ) unless ($OK);
	}
	return @return;
}

sub read_original_data {
	my ($inpath) = @_;
	die "Sorry, but I can not open the path '$inpath'\n" unless ( -d $inpath );
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
			next
			  unless ( __is_used( $nimbelID_2_Sample_id->{$NimbleGene_ID} ) );
			print "we read from file $file\n";

			$data_file = data_table->new();
			if ($debug) {
				$data_file->read_file( "$inpath/$path1/$file", 6000 );
			}
			else {
				$data_file->read_file("$inpath/$path1/$file");
			}
			$data_hash->{ $nimbelID_2_Sample_id->{$NimbleGene_ID} } =
			  $data_file->getAsHash( 'PROBE_ID', 'NormalizedLog2Ratio' );
		}
	}
	return $data_hash;

}

sub getValues_ArrayRef {
	my ( $sampleIDs, $oligoID, $data_hash ) = @_;
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

sub __is_used {
	my ($sample_id) = @_;
	return 0 unless ( defined $sample_id );
	foreach ( ( @array_dataset_ids_groupA, @array_dataset_ids_groupB ) ) {
		return 1 if ( $_ eq $sample_id );
	}
	return 0;
}
