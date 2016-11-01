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

=head1 exportROIs_as_simple_fastaDB.pl

This script exports the ROIs, that can be created by using the HMM modules in connection with NimbelGene ChIP on chip data to fetch the underlying sequence and export it as simple fasta DB that can be read my MDscan.

To get further help use 'exportROIs_as_simple_fastaDB.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::genomeDB;

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,    $debug,               $database,    $ROI_tag,
	@ROI_ids, $genome_organism_tag, @search_tags, $max_regions,
	$outfile, $minLength,           $sort
);

Getopt::Long::GetOptions(
	"-ROI_tag=s"             => \$ROI_tag,
	"-ROI_ids=s{,}"          => \@ROI_ids,
	"-genome_organism_tag=s" => \$genome_organism_tag,
	"-search_tags=s{,}"      => \@search_tags,
	"-outfile=s"             => \$outfile,
	'-minLength=s'           => \$minLength,
	"-max_regions=s"         => \$max_regions,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $ROI_tag ) {
	$warn .= "the cmd line switch -ROI_tag is undefined!\n";
}
unless ( defined $ROI_ids[0] ) {
	$warn .= "the cmd line switch -ROI_ids is undefined!\n";
}
unless ( defined $search_tags[0] ) {
	$warn .=
	  "you cold create a order in the dataset by specifying -search_tags !\n";
}
else {
	$sort = [];
	foreach my $info (@search_tags) {
		my $hash;
		$hash = { 'matching_str' => $1, 'test' => $2 }
		  if ( $info =~ m/^(.*);(.*)$/ );
		unless ( defined($hash) ) {
			$error .= "we can not parse the sort_tag $info";
			next;
		}
		unless ( "lexical numeric antiNumeric" =~ m/$hash->{'test'}/ ) {
			$error .= "we can not parse the sort_tag $info";
			next;
		}
		push( @$sort, $hash );
	}
}
unless ( defined $minLength ) {
	$warn .=
"you could specifiy a -minLength that woiuld exclude ROIs below a certain length from the analysis!\n"
	  . "\tas you have not specified one I have set that to the minimum of 10bp\n";
	$minLength = 10;
}
unless ( defined $ROI_tag || defined $ROI_ids[0] ) {
	$warn = '';
	$error .= "you need to specify either -ROI_ids or a -ROI_tag\n";
}
unless ( defined $genome_organism_tag ) {
	$error .= "the cmd line switch -genome_organism_tag is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

unless ( defined $max_regions ) {
	$warn .=
	  'You could add only the first -max_regions to the output if you want!';
	$max_regions = 100e10;
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
 command line switches for exportROIs_as_simple_fastaDB.pl

   -ROI_tag             :the tag of the ROI that you want to select
   -ROI_ids             :the ROI_ids that you want to select (separated by ' ')
   -search_tags         :the search_tags are a complictaed datastructure, that you can use 
                         to order the ROIs. Usage of this value implies, that the ROIs have some stored information!
                         One search_tag looks like that: \"<matching str>;<numeric||antiNumeric||lexical>\"
                         The <matching string> will be used to identfy the ROI_tag and the other value specifies a sort order.
   -genome_organism_tag :the genome string where the ROIs are stored to
   -outfile             :where to write the sime fastaDB to

   -help           :print this help
   -debug          :verbose output
   

";
}

## now we set up the logging functions....

my (
	$task_description, $genomeDB,         $interface,
	$seq,              $ROI_obj,          $data_table,
	$info,             @additional_infos, $ROI_Tags
);

## and add a working entry

$task_description .= 'exportROIs_as_simple_fastaDB.pl';
$task_description .= " -ROI_tag $ROI_tag" if ( defined $ROI_tag );
$task_description .= ' -ROI_ids ' . join( ' ', @ROI_ids )
  if ( defined $ROI_ids[0] );
$task_description .= " -genome_organism_tag $genome_organism_tag"
  if ( defined $genome_organism_tag );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -search_tags " . join( " ", @search_tags )
  if ( defined $search_tags[0] );
$task_description .= " -max_regions  $max_regions";

open( OUT, ">$outfile.log" ) or die "could not create logfile $outfile.log\n";
print OUT "$task_description\n";
close(OUT);
print "Log written to $outfile.log\n";

$genomeDB  = genomeDB->new();
$interface =
  $genomeDB->getGenomeHandle_for_dataset(
	{ 'organism_tag' => $genome_organism_tag } );
$interface = $interface->get_rooted_to('ROI_table');

if ( defined $ROI_tag ) {
	@ROI_ids = @{ $interface->select_RIO_ids_for_ROI_tag($ROI_tag) };
}
my $i = 0;
foreach my $id (@ROI_ids) {
	$i++;
	( $seq, $ROI_obj ) = $interface->getSequence_and_ROIobj_4_ROI_id($id);
	next unless ( length($seq) >= $minLength );
	unless ( ref($data_table) eq "data_table" ) {
		$data_table = data_table->new();
		foreach my $header (qw(acc sequence)) {
			$data_table->Add_2_Header($header);
		}
		while ( my ( $key, $value ) = each %{ $ROI_obj->INFORMATION() } ) {
			## I search for information tags to add them to the data_table as searchable columns!
		#print "we analyze the key $key and the value ".join(" ", @$value)."\n";
			foreach my $sort_hash (@$sort) {

#warn "we match $key and $sort_hash->{'matching_str'}\n".root::get_hashEntries_as_string ($ROI_obj, 3, "the key = $key and the whole ROI_hash =");
				if ( $key =~ m/$sort_hash->{'matching_str'}/ ) {
					if ( defined $sort_hash->{'feature_tag'} ) {
						die
"Sorry, but the feature tag $key and the feature tag $sort_hash->{'feature_tag'} correspond to the same search_tag '"
						  . $sort_hash->{'matching_str'}
						  . ";" .. $sort_hash->{'test'} . "\n";
					}
					$sort_hash->{'feature_tag'} = $key;
					$sort_hash->{'position'} = $data_table->Add_2_Header($key);
				}
			}
		}
		$error = '';
		foreach my $sort_hash (@$sort) {
			unless ( defined $sort_hash->{'feature_tag'} ) {
				$error .=
"Sorry, but we did not find a ROI tag for the search_sring $sort_hash->{'matching_str'}\n";
			}
		}
		if ( $error =~ m/\w/ ) {
			Carp::confess(
				$error . "using the ROI feature:\n" . $ROI_obj->getAsGB() );
		}
	}
	$info = $interface->get_data_table_4_search(
		{
			'search_columns' =>
			  [ 'chromosomesTable.chromosome', 'chromosomesTable.chr_start' ],
			'where' => [ [ 'ROI_table.id', '=', 'my_value' ] ]
		},
		$id
	)->get_line_asHash(0);
	Carp::confess("I could not get the information_hash for the ROI_id $id!\n")
	  unless ( defined $info );
	## now I need to add the line to the data_table!
	my $hash = {};
	$hash->{'sequence'} = $seq;
	$hash->{'acc'}      =
	    $ROI_obj->Tag()
	  . "_Chr$info->{'chromosomesTable.chromosome'}"
	  . "_id=$id" . "_"
	  . ( $info->{'chromosomesTable.chr_start'} + $ROI_obj->Start() ) . ".."
	  . (   $info->{'chromosomesTable.chr_start'} + $ROI_obj->End() . " "
		  . $ROI_obj->Info_AsString() );
	$ROI_Tags = $ROI_obj->INFORMATION();

	#print root::get_hashEntries_as_string ($ROI_Tags, 3, "the ROI tags: ");
	foreach my $sort_hash (@$sort) {
		$hash->{ $sort_hash->{'feature_tag'} } =
		  $ROI_Tags->{ $sort_hash->{'feature_tag'} };

#warn "we initially got the value $hash->{$sort_hash->{'feature_tag'}} for the tag $sort_hash->{'feature_tag'}\n";

		if ( ref( $hash->{ $sort_hash->{'feature_tag'} } ) eq "ARRAY" ) {
			$hash->{ $sort_hash->{'feature_tag'} } =
			  join( ' ', @{ $hash->{ $sort_hash->{'feature_tag'} } } );
		}
		$hash->{ $sort_hash->{'feature_tag'} } =~ s/"//g;

#warn "we got the value $hash->{$sort_hash->{'feature_tag'}} for the tag $sort_hash->{'feature_tag'}\n";
		$hash->{'acc'} .=
		    $sort_hash->{'feature_tag'} . "="
		  . $hash->{ $sort_hash->{'feature_tag'} };
	}
	$data_table->Add_Dataset($hash);
	print "we process the $id. ROI ($i)\n" if ( int( $id / 1 ) == $id / 1 );
}

open( OUT, ">$outfile" ) or die "could not create outfile $outfile\n";
foreach my $data_array ( @{ $data_table->{'data'} } ) {
	last if ( $i++ == $max_regions );
	print OUT ">@$data_array[0]\n@$data_array[1]\n";
}
close(OUT);
print "Unsorted data written to $outfile\n";

my ( @sortArray, $exit );
$exit = 1;
foreach my $sort_hash (@$sort) {
	push( @sortArray, [ $sort_hash->{'feature_tag'}, $sort_hash->{'test'} ] );
	$exit = 0;
}
exit 1 if ($exit);
$data_table = $data_table->Sort_by( \@sortArray );
$i          = 0;
open( OUT, ">$outfile" ) or die "could not create outfile $outfile\n";
foreach my $data_array ( @{ $data_table->{'data'} } ) {
	last if ( $i++ == $max_regions );
	print OUT ">@$data_array[0]\n@$data_array[1]\n";
}
close(OUT);
print "Data written to $outfile\n";
