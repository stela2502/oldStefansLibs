#! /usr/bin/perl -w

#  Copyright (C) 2011-11-23 Stefan Lang

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

=head1 splice_big_data_file.pl

This tool splits the big data table into several smaller tables - one including all sequence files that had duplicates, the duplicated, all sequences that wrer unusable a table containing all usable sequences without the duplicates and one table containing the without duplicates if functional and one like the last, but containing only the not functional sequences.

To get further help use 'splice_big_data_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $duplicates_table, $data_table, $sample,
	$outpath );

Getopt::Long::GetOptions(
	"-duplicates_table=s" => \$duplicates_table,
	"-data_table=s"       => \$data_table,
	"-sample=s"           => \$sample,
	"-outpath=s"          => \$outpath,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $duplicates_table ) {
	$warn .= "the cmd line switch -duplicates_table is undefined!\n";
}
unless ( -f $data_table ) {
	$error .= "the cmd line switch -data_table is undefined!\n";
}
unless ( defined $sample ) {
	$error .= "the cmd line switch -sample is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	mkdir($outpath) or die "$!\n";
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
 command line switches for splice_big_data_file.pl

   -duplicates_table :the data table containing information about duplicates
   -data_table       :the all reads table
   -sample           :which sample it has been
   -outpath          :where to put the data to

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/splice_big_data_file.pl';
$task_description .= " -duplicates_table $duplicates_table"
  if ( defined $duplicates_table );
$task_description .= " -data_table $data_table" if ( defined $data_table );
$task_description .= " -sample $sample"         if ( defined $sample );
$task_description .= " -outpath $outpath"       if ( defined $outpath );

## Do whatever you want!

my ( $data_table_2, $new_table, $duplicates, $bad_duplicates, $good_duplicates,
	$temp );

####
#Sequence number	Sequence ID	Functionality	V-GENE and allele	V-REGION score	V-REGION identity %	V-REGION identity nt	V-REGION identity % (with ins/del events)	V-REGION identity nt (with ins/del events)	J-GENE and allele	J-REGION score	J-REGION identity %	J-REGION identity nt	D-GENE and allele	D-REGION reading frame	CDR1-IMGT length	CDR2-IMGT length	CDR3-IMGT length	CDR-IMGT lengths	FR-IMGT lengths	AA JUNCTION	JUNCTION frame	Orientation	Functionality comment	V-REGION potential ins/del	J-GENE and allele comment	V-REGION insertions	V-REGION deletions	Sequence
#1	HB5P35S06HOEYB	unproductive (see comment)	Musmus IGHV1-77*01 F	1150	100.0	231/231 nt	Musmus IGHJ3*01 F	213	93.75	45/48 nt	Musmus IGHD2-5*01 F	2	8	8	X	8.8.X	[6.17.38.11]	CAR*GNYYSNYGLL#FAYW	out-of-frame	+	 stop codons				atatcctgcaaggcttctggctacaccttcactgactactatataaactgggtgaagcagaggcctggacagggccttgagtggattggaaagattggtcctggaagtggtagtacttactacaatgagaagttcaagggcaaggccacactgactgcagacaaatcctccagcacagcctacatgcagctcagcagcctgacatctgaggactctgcagtctatttctgtgcaagatgaggaaactactatagtaactacggtctactttctttgcttactggggccaagggactctggtcactgtctctgcag
###
$data_table_2 = data_table->new();
$data_table_2->read_file($data_table);
$data_table = $data_table_2;
my @outfiles;
##
#id	seq_number	seq_id
#1	4	HB5P35S06HP8N2 #good
#	413	HB5P35S06G70N2 #duplicate
##
my ( $duplicate_to_groups, $last_group_id, $new_duplicates_bad_table,
	$new_duplicates_good_table, $hash_bad, $hash_good, $detailed_duplicates )
  ;

if ( -f $duplicates_table ) {
	$duplicates = data_table->new();
	$duplicates->read_file($duplicates_table);
## now I need an Hash with the 'Sequence ID' => 'group_ids'
	for ( my $i = 0 ; $i < $duplicates->Lines() ; $i++ ) {
		$temp = $duplicates->get_line_asHash($i);
		$last_group_id = $temp->{'id'} if ( $temp->{'id'} =~ m/\d/ );
		Carp::confess("I do not have a last group id !\n")
		  unless ( defined $last_group_id );
		$duplicate_to_groups->{ $temp->{'seq_id'} } = $last_group_id;
	}
##the duplicates
	$bad_duplicates =
	  $duplicates->select_where( 'id',
		sub { return 0 if ( $_[0] =~ m/\d/ ); return 1 } );
## te duplicated sequences, but without the duplicates
	$good_duplicates =
	  $duplicates->select_where( 'id',
		sub { return 1 if ( $_[0] =~ m/\d/ ); return 0 } );
}
$new_table = $data_table->select_where(
	'Functionality',
	sub {
		my $return = 1;
		$return = 0 if $_[0] =~ m/productive/;

		#	$return = 0 if $_[0] =~ m/unproductive/;
		return $return;
	}
);
$new_table->write_file("$outpath/$sample-unusable_sequences");

#push ( @outfiles , { 'file' => "$outpath/$sample-unusable_sequences", 'column' => 'useless sequences'} );
$new_table  = undef;
$data_table = $data_table->select_where(
	'Functionality',
	sub {
		my $return = 0;
		$return = 1 if $_[0] =~ m/productive/;

		#	$return = 1 if $_[0] =~ m/unproductive/;
		return $return;
	}
);

##now the data table does only contain the functional and not functional sequences

my $new_data_table = $data_table->_copy_without_data();
if ( -f $duplicates_table ) {
	$new_duplicates_bad_table  = $data_table->_copy_without_data();
	$new_duplicates_good_table = $data_table->_copy_without_data();
	$hash_bad                  = $bad_duplicates->createIndex('seq_id');
	$hash_good                 = $good_duplicates->createIndex('seq_id');

	$detailed_duplicates = data_table->new();
	foreach ( 'group_id', @{ $data_table->{'header'} } ) {
		$detailed_duplicates->Add_2_Header($_);
	}

	for ( my $i = 0 ; $i < @{ $data_table->{'data'} } ; $i++ ) {
		$temp = $data_table->get_line_asHash($i);
		if ( defined $hash_bad->{ $temp->{'Sequence ID'} } ) {
			$new_duplicates_bad_table->AddDataset($temp);
		}
		else {
			$new_data_table->AddDataset($temp);
			if ( defined $hash_good->{ $temp->{'Sequence ID'} } ) {
				$new_duplicates_good_table->AddDataset($temp);
			}
		}
		if ( defined $duplicate_to_groups->{ $temp->{'Sequence ID'} } ) {
			$temp->{'group_id'} =
			  $duplicate_to_groups->{ $temp->{'Sequence ID'} };
			$detailed_duplicates->AddDataset($temp);
		}
	}
	$new_duplicates_bad_table->Add_2_Description(
"This file contains all information about the duplicates - including the group_id.\nAll duplictaed sequences are included!"
	);
	$detailed_duplicates->write_file(
		"$outpath/$sample-detailed_duplicate_analysis");
	$new_duplicates_bad_table->Add_2_Description(
"this file contains only the dublicated sequences. The first sequence is NOT included!"
	);
	$new_duplicates_bad_table->write_file(
		"$outpath/$sample-duplicate_sequences");

#push ( @outfiles ,  { 'file' =>"$outpath/$sample-duplicate_sequences", 'column' => $sample.' duplicated sequences'} );
	$new_data_table->write_file("$outpath/$sample-cleaned_sequences_all");
	push(
		@outfiles,
		{
			'file'   => "$outpath/$sample-cleaned_sequences_all",
			'column' => $sample . ' sequences no duplicates'
		}
	);
	$data_table = $new_data_table;
}
else {
	$data_table->write_file("$outpath/$sample-all_vdj_sequences");
	push(
		@outfiles,
		{
			'file'   => "$outpath/$sample-all_vdj_sequences",
			'column' => $sample . ' sequences including duplicates'
		}
	);
}
my $productive = $data_table->select_where(
	'Functionality',
	sub {
		my $return = 0;
		$return = 1
		  if $_[0] =~ m/^productive/;
		return $return;
	}
);
my $unproductive = $data_table->select_where(
	'Functionality',
	sub {
		my $return = 0;
		$return = 1 if $_[0] =~ m/unproductive/;
		return $return;
	}
);
if ( -f $duplicates_table ) {
	$productive->write_file("$outpath/$sample-cleaned_sequences_productive");
	$unproductive->write_file(
		"$outpath/$sample-cleaned_sequences_NOT_productive");
	push(
		@outfiles,
		{
			'file'   => "$outpath/$sample-cleaned_sequences_productive",
			'column' => $sample . ' all productive'
		}
	);
	push(
		@outfiles,
		{
			'file'   => "$outpath/$sample-cleaned_sequences_NOT_productive",
			'column' => $sample . ' all NOT productive'
		}
	);
	$new_data_table = $data_table->_copy_without_data();
	for ( my $i = 0 ; $i < @{ $productive->{'data'} } ; $i++ ) {
		$temp = $productive->get_line_asHash($i);
		if ( defined $hash_good->{ $temp->{'Sequence ID'} } ) {
			$new_data_table->AddDataset($temp);
		}
	}
	$new_data_table->write_file(
		"$outpath/$sample-sequences_with_more_than_one_read_productive");

#push ( @outfiles ,  { 'file' =>"$outpath/$sample-sequences_with_more_than_one_read_productive", 'column' => $sample.' duplicates productive'}  );

	$new_data_table = $data_table->_copy_without_data();
	for ( my $i = 0 ; $i < @{ $unproductive->{'data'} } ; $i++ ) {
		$temp = $unproductive->get_line_asHash($i);
		if ( defined $hash_good->{ $temp->{'Sequence ID'} } ) {
			$new_data_table->AddDataset($temp);
		}
	}
	$new_data_table->write_file(
		"$outpath/$sample-sequences_with_more_than_one_read_NOT_productive");

#push ( @outfiles , { 'file' => "$outpath/$sample-sequences_with_more_than_one_read_NOT_productive", 'column' => $sample.' duplicates NOT productive'}  );
}
else {
	$productive->write_file("$outpath/$sample-all_vdj_sequences_productive");
	$unproductive->write_file(
		"$outpath/$sample-all_vdj_sequences_NOT_productive");
	push(
		@outfiles,
		{
			'file'   => "$outpath/$sample-all_vdj_sequences_productive",
			'column' => $sample . ' all productive including duplicates'
		}
	);
	push(
		@outfiles,
		{
			'file'   => "$outpath/$sample-all_vdj_sequences_NOT_productive",
			'column' => $sample . ' all NOT productive including duplicates'
		}
	);
}
foreach (@outfiles) {
	if ( -f "$_->{'file'}.xls" ) {
		system(
"perl -I perl -I ~/LibsNewStructure/lib/ /home/stefan/LibsNewStructure/bin/FirmenProjekte/Thomas_Winkler/Details_V_Segment_Usage.pl -data_table $_->{'file'}.xls -target_column '$_->{'column'}' "
		);
	}
	else {
		warn "Hey I can not read from the file '$_->{'file'}.xls'!\n";
	}
}
print "I hope everything went well!\n";
