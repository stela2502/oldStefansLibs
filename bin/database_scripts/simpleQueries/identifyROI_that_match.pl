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

=head1 identifyROI_that_match.pl

a simple DB query interface, that can search the region defined by a ROI for a sequence match.

To get further help use 'identifyROI_that_match.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::genomeDB;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::fastaFile;
use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,                $debug,   $database,
	$sequence,            $ROI_tag, $ROI_id,
	$genome_organism_tag, $outfile, $add2region
);

Getopt::Long::GetOptions(
	"-sequence=s"            => \$sequence,
	"-ROI_tag=s"             => \$ROI_tag,
	"-ROI_id=s"              => \$ROI_id,
	"-genome_organism_tag=s" => \$genome_organism_tag,
	"-add2region=s"          => \$add2region,
	"-outfile=s"             => \$outfile,
	"-help"                  => \$help,
	"-debug"                 => \$debug,
	"-database=s"            => \$database
);

if ($help) {
	print helpString();
	exit;
}
unless ( defined $genome_organism_tag ) {
	print helpString(
"Sorry, but without the name of the genome, I can not select the right ROI table name!"
	);
	exit;
}
unless ( defined $ROI_tag || defined $ROI_id ) {
	print helpString(
"we need either the ROI_tag or the ROI_id to lelect a ROI from the database!"
	);
	exit;
}
unless ( defined $sequence ) {
	print helpString("we need the sequence in fasta format!");
	exit;
}
my $fastaSeq = fastaFile->new();
unless ( -f $sequence ) {
	$fastaSeq->parseString($sequence);
}
else {
	$fastaSeq->AddFile($sequence);
}
unless ( defined $fastaSeq->Name() && defined $fastaSeq->Seq() ) {
	print helpString("sorry, but we could not parse the sequence $sequence");
	exit;
}

my ( $already_evaluated, $genomeDB, $interface, @data, @ROI_ids, $seq,
	$ROI_obj, $add2region_str );

$genomeDB  = genomeDB->new();
$interface = $genomeDB->getGenomeHandle_for_dataset(
	{ 'organism_tag' => $genome_organism_tag } );
$interface = $interface->get_rooted_to('ROI_table');
my $sql =
  "update " . $interface->TableName() . " set gbString = '?' where id = ?";
if ( defined $ROI_tag ) {
	@ROI_ids = @{ $interface->select_RIO_ids_for_ROI_tag($ROI_tag) };
}
else {
	@ROI_ids = ($ROI_id);
}
unless ( defined $ROI_ids[0] ) {
	warn "Sorry, but we got no regions of interest for this function call!\n";
	exit;
}

my $matchHash = {
	'a' => { 'a' => 1, 'c' => 0, 'g' => 0, 't' => 0 },
	'c' => { 'a' => 0, 'g' => 0, 't' => 0, 'c' => 1 },
	'g' => { 'a' => 0, 'c' => 0, 't' => 0, 'g' => 1 },
	't' => { 'a' => 0, 'c' => 0, 'g' => 0, 't' => 1 },
	'm' => { 'g' => 0, 't' => 0, 'a' => 1, 'c' => 1 },
	'r' => { 'c' => 0, 't' => 0, 'a' => 1, 'g' => 1 },
	'w' => { 'c' => 0, 'g' => 0, 'a' => 1, 't' => 1 },
	's' => { 'a' => 0, 't' => 0, 'c' => 1, 'g' => 1 },
	'y' => { 'a' => 0, 'g' => 0, 'c' => 1, 't' => 1 },
	'k' => { 'a' => 0, 'c' => 0, 'g' => 1, 't' => 1 },
	'v' => { 't' => 0, 'a' => 1, 'c' => 1, 'g' => 1 },
	'h' => { 'g' => 0, 'a' => 1, 'c' => 1, 't' => 1 },
	'd' => { 'c' => 0, 'a' => 1, 'g' => 1, 't' => 1 },
	'b' => { 'a' => 0, 'c' => 1, 'g' => 1, 't' => 1 },
	'x' => { 'a' => 1, 'c' => 1, 'g' => 1, 't' => 1 },
	'n' => { 'a' => 1, 'c' => 1, 'g' => 1, 't' => 1 }
};
my $complement = {
	'a' => 't',
	't' => 'a',
	'c' => 'g',
	'g' => 'c'
};

my $acc = $fastaSeq->Name();

## we have to update our database!!
if ( defined $add2region){
	$add2region_str = " $add2region";
}
else{
	$add2region_str = '';
}

$sql =
  "update " . $interface->TableName() . " set gbString = '?' where id = ?";
my @searchArray = split( "", lc( $fastaSeq->Seq() ) );
my $actual;
my $temp;
foreach my $id (@ROI_ids) {
	( $seq, $ROI_obj ) = $interface->getSequence_and_ROIobj_4_ROI_id($id, $add2region, $add2region);
	$temp = $ROI_obj->getAsGB();
	if ( $temp =~ m/N?O? ?match to $acc$add2region_str"/ ){
		print "we have already evaluated this ROI \n$temp\n";
		next;
	}
	print "we got no match against "."N?O? ?match to $acc$add2region_str\"\n"."with this ROI\n".$ROI_obj->getAsGB()."\n";
	#print "we got a seq '$seq' and a ROI object ".$ROI_obj->getAsGB()."\n";
	if ( defined @{ &evaluateSeq( lc($seq), @searchArray ) }[0] ) {
		$ROI_obj->AddInfo( 'misc_signal', "match to $acc$add2region_str" );
	}
	else {
		$ROI_obj->AddInfo( 'misc_signal', "NO match to $acc$add2region_str" );
	}
	$actual = $sql;
	$seq    = $ROI_obj->getAsGB();
	$actual =~ s/\?/$seq/;
	$actual =~ s/\?/$id/;
	$interface->{'dbh'}->do($actual);
}

$seq = $interface->getArray_of_Array_for_search(
	{
		'search_columns' => [ 'ROI_table.id', 'ROI_table.gbString' ],
		'where' => [ [ 'ROI_table.id', '=', 'my_value' ] ]
	},
	\@ROI_ids
);

my ( $match, $no_match);
$match = $no_match = 0;

if ( defined $outfile ) {
	open( OUT, ">$outfile" ) or die "could not create outfile '$outfile'\n";
	print OUT "ROI_id\tmatch\n";
	foreach my $info (@$seq) {
		if ( @$info[1] =~ m/NO match to $acc$add2region_str"/ ) {
			print OUT "@$info[0]\tmatch\n";
			$no_match ++;
		}
		elsif ( @$info[1] =~ m/match to $acc$add2region_str"/ ) {
			print OUT "@$info[0]\tNO match\n";
			$match ++;
		}
		else {
			die
"We have an error here - there has been no evaluation for ROI_id @$info[0] ( @$info[1] )\n";
		}
	}
	print OUT "Final result:\n   match=$match\nno_match=$no_match\n";
	close(OUT);
	print "Data written to $outfile";
}
else {
	foreach my $info (@$seq) {
		if ( @$info[1] =~ m/NO match to $acc$add2region_str/ ) {
			print "@$info[0]\tNO match\n";
			$no_match ++;
		}
		elsif ( @$info[1] =~ m/match to $acc$add2region_str/ ) {
			print "@$info[0]\tmatch\n";
			$match ++;
		}
		else {
			die
"We have an error here - there has been no evaluation for ROI_id @$info[0] ( @$info[1] )\n";
		}
	}
	print "Final result:\n   match=$match\nno_match=$no_match\n";
}



sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for identifyROI_that_match.pl

   -sequence       :a sequence file in fasta format
   -ROI_tag        :the tag for the regions of interest we should analyze
   -ROI_id         :the id of the ROI we should analyze (will not be used if 'ROI_tag' is set)
   -genome_organism_tag       
                   :we need the organism tag to get access to the ROI table
   -add2region     :an optional amount of bp the region has to be enlarged on both ends
   -outfile        :an optional outfile
   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

";
}

sub evaluateSeq {
	my ( $seq, @bindingSite ) = @_;

#print "we start with seq (1-100) '",substr($seq,0,100),"' and the binding site: '",join(";",@bindingSite),"'\n";
	my ( @seq, $matching, @returnStrings, $start );    #

	@seq           = split( "", $seq );
	$matching      = 0;
	@returnStrings = ();

	#	for ( my $i = 0; $i < @bindingSite ;$i++) {
	#		print "bindingSite $i = $bindingSite[$i]\n";
	#	}

	for ( my $i = 0 ; $i < @seq ; $i++ ) {

#print "we try to match \@bindingSite[$matching] ",$bindingSite[$matching]," to \$seq[$i] $seq[$i]\n";
		if ( &match_IUPACbase_to_base( $bindingSite[$matching], $seq[$i] ) ) {

			#print "we found a forward match!\n";
			$start = $i - 1 if ( $matching == 0 );
			$matching++;
			if ( $matching == scalar(@bindingSite) ) {    ## complete match!
				print "we found a complete match: misc_binding $start..$i\n";
				push( @returnStrings, "misc_binding $start..$i" );
				$i -= $matching - 1;
				$matching = 0;
			}
		}
		else {
			$i -= $matching;
			$matching = 0;
		}
	}
	$matching = 0;
	for ( my $i = @seq - 1 ; $i >= 0 ; $i-- ) {

		if (
			&match_IUPACbase_to_base(
				$bindingSite[$matching], &complement( $seq[$i] )
			)
		  )
		{
			$start = $i if ( $matching == 0 );
			$matching++;
			if ( $matching == @bindingSite ) {    ## complete match!
				push( @returnStrings,
					"misc_binding complement(" . ( $i - 1 ) . "..$start)" );
				$i += $matching - 1;
				$matching = 0;
			}
		}
		else {
			$i += $matching;
			$matching = 0;
		}
	}
	return \@returnStrings;
}

sub complement {
	my ($base) = @_;

	return $complement->{$base};
}

sub match_IUPACbase_to_base {
	my ( $IUPACbase, $base ) = @_;

	die "not an IUPAC base ($IUPACbase)\n"
	  unless ( defined $matchHash->{ lc($IUPACbase) } );

	#print "match_IUPACbase_to_base: we try to match $IUPACbase to $base\n";
	return 0 if ( lc($base) eq 'n' || lc($base) eq 'x' );
	return 0 unless ( defined $base );
	return 0 unless ( defined $complement->{$base} );
	die "OOOOOPS!! we have a unrecognized base here :'$base'\n"
	  unless ( defined $matchHash->{ lc($IUPACbase) }->{$base} );
	return $matchHash->{ lc($IUPACbase) }->{$base};

	my $match = $matchHash->{ lc($IUPACbase) };

	#return 1 == 1 if ( lc($base) =~ m/$match/ );
	if ( lc($base) =~ m/$match/ ) {

		#print "got a match! base $base matches to $match\n";
		return 1 == 1;
	}

	#print "NO match! base $base matches to $match\n";
	return 1 == 0;
}
