package blastResult;

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

use strict;
use stefans_libs::sequence_modification::blastLine;

#use imgt_queryDatabase;
use stefans_libs::sequence_modification::primerList;
use stefans_libs::sequence_modification::imgtFeatureDB;
use stefans_libs::sequence_modification::imgt2gb;
use stefans_libs::sequence_modification::ssake_info;
use stefans_libs::sequence_modification::deepSeq_blastLine;
use stefans_libs::sequence_modification::deepSequencingRegion;
use stefans_libs::fastaDB;

sub new {

	my ($class) = @_;

	my ( $self, $dbh_primer, $dbh_imgt, $imgtFeatureDB, $imgt2gb,
		@internalFeatureList );

	$imgtFeatureDB = imgtFeatureDB->new();
	$imgt2gb       = imgt2gb->new();

	#    $dbh_primer    = imgt_queryDatabase::getDBH("Primer") or die $_;
	#    $dbh_imgt      = imgt_queryDatabase::getDBH("IMGT") or die $_;
	$self = {
		imgtFeatureDB       => $imgtFeatureDB,
		acceptedBlastLines  => [],
		imgt2gb             => $imgt2gb,
		internalFeatureList => \@internalFeatureList,

		#        primerDB           => $dbh_primer,
		#        imgtDB             => $dbh_imgt,
		differenAcc  => 0,
		unmatchedAcc => 0,
		acepted      => 0,
		all          => 0,
		rejected     => 0
	};

	bless( $self, $class ) if ( $class eq "blastResult" );
	return $self;
}

sub FastaDB {
	my ( $self, $dbFile ) = @_;
	$self->{fastaDB} = fastaDB->new($dbFile)
	  if ( !defined $self->{fastaDB} && -f $dbFile );
	return $self->{fastaDB};
}

sub SSAKE_ClusterInfo {
	my ( $self, $file ) = @_;
	$self->{ssake_Info} = ssake_info->new($file)
	  if ( !defined $self->{ssake_Info} && -f $file );
	return $self->{ssake_Info};
}

sub onlyBestHit {
	my ($self) = @_;

	my ( $blastList, @partialList, $lastEnd, @newList );

	$blastList = $self->{acceptedBlastLines};

	@$blastList = sort byStart @$blastList;

	foreach my $blastLine (@$blastList) {
		if ( $blastLine->{q_start} > $lastEnd ) {
			if ( @partialList > 0 ) {
				@partialList = sort byE_value @partialList;

				#                $partialList[0]->print();
				push( @newList, $partialList[0] );
				@partialList = undef;
			}
		}
		push( @partialList, $blastLine );
		$lastEnd = $blastLine->{q_start};
	}
	$self->{acceptedBlastLines} = \@newList;
}

sub bestBlastHit_perAcc {
	my ( $self, $blastHits ) = @_;

	#    print "bestBlastHit_perAcc start @$blastHits[0]\n";

	@$blastHits = sort byE_value @$blastHits;

	#    print "bestBlastHit_perAcc end @$blastHits[0]\n";

	my (@return);
	push( @return, @$blastHits[0] );
	return \@return;
}

=head2 bestSequencingHit_perAcc

Aim is to remove holes in the blast hit which are 
the result of repretitive elements in the search sequence

=cut

sub bestSequencingHit_perAcc {
	my ( $self, $blastHits ) = @_;

	#    print "bestSequencingHit_perAcc\n";
	$blastHits  = $self->group_by_BlastSimilarity($blastHits);
	@$blastHits = sort byE_value @$blastHits;
	my (@return);
	push( @return, @$blastHits[0] );
	return \@return;
}

=head2 mergeOverlappingBlastHits

Used for deep sequencing data. A multitude of matches is merged to become a expressed region

=cut

sub mergeOverlappingBlastHits2FeatureList {
	my ( $self, $blastHits ) = @_;
	my ( $lastHit, @newBlastHits, $newFeatureCount );
	
	$newFeatureCount = 0;
	
	foreach my $blastHit ( sort { $a->startOnQuery() <=> $b->startOnQuery() }
		@$blastHits )
	{
		unless ( defined $lastHit ) {
			$lastHit = $blastHit;
			next;
		}
		if ( $lastHit->endOnQuery() >= $blastHit->startOnQuery() ) {
			print
"got an overlapp between hit $lastHit->{subjectID} and $blastHit->{subjectID}\n";
			unless ( defined $newBlastHits[$newFeatureCount] ) {
				print "Create a new deepSequencingRegion Nr. $newFeatureCount (2, $lastHit, $blastHit)\n";
				$newBlastHits[$newFeatureCount] =
				  deepSequencingRegion->new( 2, $lastHit, $blastHit );
			}
			else {
				$newBlastHits[$newFeatureCount]->AddDeepRead($blastHit);
			}
		}
		elsif ( defined $newBlastHits[$newFeatureCount] ) {
			print "We got a new deepSequencing region ($newBlastHits[$newFeatureCount])\n",
			  $newBlastHits[$newFeatureCount]->getAsGB();
			$newFeatureCount++;
		}
		$lastHit = $blastHit;
	}

	return \@newBlastHits;
}

sub group_by_BlastSimilarity {
	my ( $self, $blastHits ) = @_;

	my ( $lastHit, $join, @return, $blastHit, $start );
	$start = @$blastHits;
	foreach $blastHit (@$blastHits) {
		unless ( defined $lastHit ) {
			$lastHit = $blastHit;
			next;
		}
		$join = $blastHit->JoinWith($lastHit);
		if ( defined $join ) {
			$lastHit = $join;

			#            print "got a join!!\n";
		}
		else {
			push( @return, $lastHit );
			$lastHit = $blastHit;
		}
	}
	push( @return, $lastHit ) if ( defined $lastHit );
	$blastHit = @return;

	print "$blastHit/$start Hits from accession $lastHit->{subjectID}\n";
	return \@return;
}

sub byStart {
	return $a->{p_start} <=> $b->{p_start};
}

sub byE_value {

	return $a->E_value <=> $b->E_value;
}

sub AddBlastResultsToFile {
	my ( $self, $gbFile, $match ) = @_;

	print "AddBlastResultsToFile ", $gbFile->Name(),
	  " ($gbFile) with mode $match\n";

	unless ( $match eq "deepSequencing" ) {
		my ( $acceptedBlastLines, $features, $feature, $temp );
		$acceptedBlastLines = $self->{acceptedBlastLines};

		$features = $gbFile->Features() if ( defined $match );
		unless ( defined $features ) {
			my @temp = ();
			$features = \@temp;
		}

		foreach my $blastLine (@$acceptedBlastLines) {
			foreach $feature (@$features) {
				$feature->MatchesWith("$match")
				  if (
					$feature->Match(
						$blastLine->StartOnQueryFile(),
						$blastLine->EndOnQueryFile()
					)
				  );
			}
			$temp = ref($blastLine);
			$gbFile->Features( $blastLine->As_gbFeature() )
			  if ( "blastLine inverseBlastHit" =~ m/$temp/ );
		}
	}
	else {
		my $featureList =
		  $self->mergeOverlappingBlastHits2FeatureList(
			$self->{acceptedBlastLines} );
		foreach my $feature (@$featureList) {
			#print "we got a new feature ($feature):\n", 
			print $feature->getAsGB();
			#  "\n";
			$gbFile->AddFeature($feature->asGBfeature());
		}
	}
	return $gbFile;
}

sub getVDJ_Hits {
	my ( $self, $gbFile ) = @_;
	my ( $acceptedBlastLines, $features, $feature, $return, $i, $temp, $p_val );

	$acceptedBlastLines = $self->{acceptedBlastLines};
	$features           = $gbFile->Features();

	unless ( defined $features ) {
		my @temp = ();
		$features = \@temp;
	}
	$i = 0;
	foreach my $blastLine ( sort byStartOnQueryFile @$acceptedBlastLines ) {
		foreach $feature (@$features) {
			unless ( defined $return->{ $feature->Name() }
				&& $feature->Name() =~ m/J558/ )
			{
				my %temp;
				$return->{ $feature->Name() }              = \%temp;
				$return->{ $feature->Name() }->{'n'}       = 0;
				$return->{ $feature->Name() }->{'feature'} = $feature;
				print "getVDJ_Hits Initializing ", $feature->Name(), "\n";
			}

			if (
				$feature->Match(
					$blastLine->StartOnQueryFile(),
					$blastLine->EndOnQueryFile()
				)
			  )
			{
				$return->{ $feature->Name() }->{'n'}++;
				$i++;
			}
		}

#        $gbFile->Features( $blastLine->As_gbFeature() ) if ( $blastLine =~ m/blastLine/ );
	}
	$temp = 1 / $i;
	$temp = int( $temp * 1000 ) / 1000;
	foreach my $featureName ( keys %$return ) {
		unless ( $return->{$featureName}->{'n'} == 0 ) {
			$p_val = $return->{$featureName}->{'n'} / $i;
			$p_val = int( $p_val * 1000 ) / 1000;
			$return->{$featureName}->{'p_value'} =
			  $return->{$featureName}->{'feature'}->Name($p_val);
			print "$featureName -> p_value = ",
			  $return->{$featureName}->{'p_value'}, "\n";
		}
		else {
			$return->{$featureName}->{'p_value'} =
			  $return->{$featureName}->{'feature'}->Name("<$temp");
			print "$featureName -> p_value = ",
			  $return->{$featureName}->{'p_value'}, "\n";

		}
	}
	return $return;
}

sub byStartOnQueryFile {
	return ( $a->StartOnQueryFile() <=> $b->StartOnQueryFile() );
}

sub ModeList {
	return (
		'addPrimer', 'AllBlastHits', 'doIMGTsearch',
		'BlastHit',  'Sequences',    'deepSequencing'
	);
}

sub ModeList_help {
	## List of help messages for the list selector
	return
"A list of primers used as blast database can be added to the wanted input sequence",
	  "All Blast matches, that are selected are added to the input file",
"Search for Ig and TCR segments in the input sequence.\n the blast database has to be a especially pre-processed IMGT LIGM database!",
	  "The best matching blast hit is added to the input sequence",
	  "Sorry - no idea what that was!";
}

sub readBlastResults {

	my ( $self, $file, $minLength, $minPercIdent, $maxGapOpen, $DoIMGTsearch, $oligo2DNA_table ) =
	  @_;

	my (
		$acc,              $last,        $id,
		$mittelWert_Summe, $mittelMatch, $end,
		@return,           $startA,      $endA,
		$valueA,           @temp,        $matched,
		@file,             $iterator,    @lastBlastGroup,
		$line,             $hits,        $temp,
		@result
	);

	$matched = 1;    #Falls die Acc nicht in der DB steht wird diese Variable 0

	die "Match mode '$DoIMGTsearch' is not supported!\n"
	  unless ( join( " ", ModeList ) =~ m/$DoIMGTsearch/ );

	print
"\tminimal length = $minLength\n\tminimal percent identity = $minPercIdent\n",
	  "\tmaximal number of gaps = $maxGapOpen\nmode = $DoIMGTsearch\n";

	open( FILE, "<$file" )
	  or die
"Blast output file $file k√∂nnte nicht ge√∂ffnet werden!\n";
	@file = <FILE>;
	close(FILE);

	chop @file;

	$iterator = 1;

	$last = 1;
	my $next = 0;
	$mittelWert_Summe = $mittelMatch = 0;

	foreach $line (@file) {
		next if ( $line =~ m/^ *#/ );
		my $blastLine;
		$blastLine = blastLine->new( $line, $DoIMGTsearch )
		  unless ( $DoIMGTsearch eq 'deepSequencing' );
		$blastLine = deepSeq_blastLine->new(
			$line, $DoIMGTsearch, $self->FastaDB(),
			$self->SSAKE_ClusterInfo(),
			$self->{deepSeq_runID}
		) if ( $DoIMGTsearch eq 'deepSequencing' );
		push( @temp, $blastLine );
	}

	$self->{acceptedBlastLines} = \@temp;
	$self->printNew_ResultFile("/Mass/temp/new.blastResult.txt");
	$matched = 1;

  FOREACH: foreach my $blastLine (@temp) {

		$self->{all}++;
		if ( $DoIMGTsearch eq "addPrimer" ) {    ## Primer einfuegen!
			    #print "We search for a primer!!\n";
			$self->{primerList} = primerList->new()
			  unless ( defined $self->{primerList} );
			if (
				$blastLine->isCompatibleWithPrimer(
					$self->{primerList}->GetPrimer( $blastLine->{subjectID} ),
					$minPercIdent, $minLength
				)
			  )
			{
				$self->{acepted}++;
				push( @return, $blastLine );
			}
			else {
				$self->{rejected}++;
				next FOREACH;
			}
		}

		if ( $DoIMGTsearch eq "deepSequencing" ) {
			## 1. ist der Hit OK (Laenge, % etc)
			## 2. ist die Sequenz ganz drauf?
			if ( $blastLine->meatsCriteria( $minPercIdent, $minLength, 0 ) ) {
				$self->{acepted}++;
				push( @return, $blastLine );
				$temp = $blastLine->Check4polyA()
				  unless ( $blastLine->isFullLength() );
				print
"we identified a polyA site in contig $blastLine->{subjectID}\n",
				  $temp->getAsGB()
				  if ( defined $temp );
				print "\nwe throw away a polyA information!!!\n\n"
					if ( defined $temp );
			}
			else {
				$self->{rejected}++;
			}
			next FOREACH;
		}

		if ( $blastLine->{gap_openings} > $maxGapOpen ) {
			$self->{rejected}++;
			next;
		}
		if ( $blastLine->{alignment_length} < $minLength ) {
			$self->{rejected}++;
			next;
		}
		if ( $blastLine->{identity} < $minPercIdent ) {
			$self->{rejected}++;
			next;
		}

		if ( $DoIMGTsearch eq "AllBlastHits" ) {
			if ( $blastLine->meatsCriteria( $minPercIdent, $minLength, 0 ) ) {
				$self->{acepted}++;
				push( @return, $blastLine );
			}
			else {
				$self->{rejected}++;
			}
			next FOREACH;
		}

		if ( "doIMGTsearch BlastHit Sequences" =~ m/$DoIMGTsearch/ ) {

			unless ( $acc eq $blastLine->{subjectID} ) {
				## Es wurde eine neue Acc gefunden!
				$self->{differentAcc}++;

				if ( defined $lastBlastGroup[0] ) {
					$hits = $self->EvaluateBlastHits( \@lastBlastGroup, $acc )
					  if ( $DoIMGTsearch eq "doIMGTsearch" );
					$hits = $self->bestBlastHit_perAcc( \@lastBlastGroup )
					  if ( $DoIMGTsearch eq "BlastHit" );
					$hits = $self->bestSequencingHit_perAcc( \@lastBlastGroup )
					  if ( $DoIMGTsearch eq "Sequences" );
					foreach $temp (@$hits) {
						push( @return, $temp ) if ( defined $temp );
						$self->{acepted}++;
					}
					@lastBlastGroup = ();
				}

				## Neuinitialisierung
				$id  = undef;
				$acc = $blastLine->{subjectID};
			}

			## Das Einlesen der Informationen!

			push( @lastBlastGroup, $blastLine );
		}
	}    # ende foreach
	if ( "doIMGTsearch BlastHit Sequences" =~ m/$DoIMGTsearch/ ) {
		$self->{differentAcc}++;
		if ( defined $lastBlastGroup[0] ) {
			$hits = $self->EvaluateBlastHits( \@lastBlastGroup, $acc )
			  if ( $DoIMGTsearch eq "doIMGTsearch" );
			$hits = $self->bestBlastHit_perAcc( \@lastBlastGroup )
			  if ( $DoIMGTsearch eq "BlastHit" );
			$hits = $self->bestSequencingHit_perAcc( \@lastBlastGroup )
			  if ( $DoIMGTsearch eq "Sequences" );
			foreach $temp (@$hits) {
				push( @return, $temp );
				$self->{acepted}++;
			}
		}
	}
	if ( $DoIMGTsearch eq "doIMGTsearch" ) {
		@result =
		  $self->BestHitOnSequence( $self->{internalFeatureList} )
		  ;    ## \@return );
	}
	else {
		@result = @return;
	}
	$id                         = @result;
	$self->{acepted}            = @return;
	$self->{used}               = $id;
	$self->{acceptedBlastLines} = \@result;
	print "All Blast Hits read! \n";
	return \@result;
}

sub printNew_ResultFile {
	my ( $self, $outfile ) = @_;
	my ( @result, $blastLines );
	$blastLines = $self->{acceptedBlastLines};
	warn "No blast hits selected for output to file $outfile\n"
	  unless ( defined @$blastLines );
	@result = ( sort byHitStart @$blastLines );
	open( OUT, ">$outfile" ) or die "konnte file $outfile nicht anlegen!\n";
	for ( my $i = 0 ; $i < @result ; $i++ ) {
		unless ( defined $result[$i] ) {
			print "no entry!  \n";
			next;
		}
		print OUT $result[$i]->Print();
	}
	close(OUT);
	return 1;
}

sub byHitStart {
	return $a->startOnQuery <=> $b->startOnQuery;
}

sub BestHitOnSequence {
	my ( $self, $acceptedBlastLines ) = @_;
	## Hier m√ºssen (1) alle Blast Treffer nach dem Start auf der Sequenz sortiert werden und
	## (2) bei ewtl. √úberlappungen nur der besste Treffer genutzt werden!

	print "BestHitOnSequence:\n";
	my ( @return, $blastLine, @overlapping, $end, $i, $actualBest, $start );

	foreach $blastLine ( sort bySequenceStart @$acceptedBlastLines ) {
		$start = $blastLine->StartOnQueryFile() unless ( defined $start );
		print "BestHitOnSequence start of region = $start\n";

		#       print "BestHitOnSequence blastLine:\n";
		#       $blastLine->print;
		if ( $end + 1 < $blastLine->StartOnQueryFile() ) {
			## keine √úberlappung
			if ( defined $end ) {
				$actualBest = $self->returnBestHit( \@overlapping );

				print
"actualBest of $i hits representing genomic region from $start to $end  (",
				  $actualBest->Name, "):\n", $actualBest->getAsGB();

				push( @return, $actualBest ) if defined($actualBest);
			}
			@overlapping = undef;
			$i           = 0;
			$start       = $blastLine->StartOnQueryFile();
		}
		$overlapping[ $i++ ] = $blastLine;
		$end = $blastLine->EndOnQueryFile()
		  if ( $blastLine->EndOnQueryFile() > $end );
	}
	if ( defined $overlapping[0] ) {
		$actualBest = $self->returnBestHit( \@overlapping );

		print
"actualBest of $i hits representing genomic region from $start to $end  (",
		  $actualBest->Name, "):\n", $actualBest->getAsGB();
		push( @return, $self->returnBestHit( \@overlapping ) );
	}
	return @return;
}

sub returnBestHit {
	my ( $self, $hitRef ) = @_;

	#    @$hitRef = sort byE_value @$hitRef;
	$hitRef = $self->top_by_E_value($hitRef) if ( @$hitRef > 1 );
	foreach my $inverseBlastHit (@$hitRef) {
		return $inverseBlastHit if ( defined $inverseBlastHit->Gene );
	}

	#    $hitRef = $self->top_by_Missmatches($hitRef) if (@$hitRef > 1);
	return @$hitRef[0];
}

sub top_by_E_value {
	my ( $self, $hitRef ) = @_;
	my ( @possibles, $criteria, $return, $ref );
	$return = 0;
	foreach $criteria ( sort byE_value @$hitRef ) {
		$ref = ref($criteria);

#      print "top_by_E_value e_value = ",$criteria->E_value()," ref = ",$ref,"\n";
#	   print "actual hit:  (",
#					$criteria->Name,"):\n", $criteria->getAsGB();
		$possibles[ $return++ ] = $criteria
		  if ( "inverseBlastHit blastLineref" =~ m/$ref/ );
		$return-- if ( $criteria->E_value() == 1 );
	}
	return \@possibles;
}

#sub top_by_E_value{
#    my ( $self, $hitRef) = @_;
#    my ( @possibles, $criteria, $return );
#    $return = 0;
#    @$hitRef = sort byMissmatches @$hitRef;
#    for ( my $i = 0 ; $i < @$hitRef; $i++){
#      if (defined $criteria){
#         last if ( $criteria != @$hitRef[$i]->{e_value});
#      }
#      if ( @$hitRef[$i] =~ m/blastLine/ ){
#         $criteria = @$hitRef[$i]->{e_value};
#         $possibles[$return ++] = @$hitRef[$i];
#      }
#    }
#    return \@possibles;
#}

sub byMissmatches {
	return $b <=> $a;
}

sub bySequenceStart {
	return $a->StartOnQueryFile() <=> $b->StartOnQueryFile();
}

sub Print_results {
	my ( $self, $DoIMGTsearch ) = @_;

	my ($results);
	$results = $self->{acceptedBlastLines};

	#    foreach my $temp (@$results){
	#       print "Print_results: $temp\n";
	#       $temp->print() if ( defined $temp);
	#    }
	if ( $DoIMGTsearch == 2 || $DoIMGTsearch == 3 ) {
		print "read hits:              | ", $self->{all}, "\n",
		  "accepted hits:          | ", $self->{acepted}, "\n";
	}

	if ( $DoIMGTsearch eq "doIMGTsearch" ) {
		print "different Acc's:        | ", $self->{differentAcc}, "\n";
		print "read hits:              | ", $self->{all},          "\n";
		print "accepted hits:          | ", $self->{acepted},      "\n";
		print "used features:          | ", $self->{used},         "\n";
	}
	else {
		print "read hits:              | ", $self->{all}, "\n",
		  "accepted hits:          | ", $self->{acepted},  "\n",
		  "rejected hits:          | ", $self->{rejected}, "\n";
	}
	return {
		differentAcc => $self->{differentAcc},
		all          => $self->{all},
		acepted      => $self->{acepted},
		used         => $self->{used}
	};

}

sub EvaluateBlastHits {
	my ( $self, $blastHits, $acc ) = @_;
	## Hier wird eine ganze List von Bast Treefern einer such Sequenz √ºbergeben.
	## Was gemacht werden soll:
	## 1. Alle Blast Treffer werden in gruppen organisiert.
	##    Sollten einige so nahe aneinander liegen und eine gemeinsame L√ºcke haben
	##    ist es warscheinlich, dass in beiden Sequenzen an dieser Stelle eine
	##    Repetetive Sequenz liegt, die vom BLAST nicht ausgewertet wird, aber den eigentlichen
	##    Blast Treffer nicht unterbrechen sollte. Diese beiden Treffer werden dann zusammengef√ºhrt.
	## 2. In dieser Analyse sind nur Sequenzen sinnvoll, die auch in der IMGT Datenbank ein
	##    Feature tragen. Alle anderen Treffer sollen verworfen werden.

	my (
		$imgtFeatureDB, $imgtFile,     $gbRegion,
		$region,        $imgtFeatures,
		@return,        $i,            $now,
		$feature,       $features,     $fun,
		@i,             $delta,        $internalFeatureList,
		$mappedfeatures
	);

#    $blastHits = $self->group_by_BlastSimilarity($blastHits); ## Gruppen bilden!
	$internalFeatureList = $self->{internalFeatureList};
	$imgtFile            = $self->{imgtFeatureDB}->GetIMGT_entry_forACC($acc);

#print "Search for IMGT features: feature $acc as features stored in $imgtFile\n";
#$imgtFile->Print();

	## jetzt m√ºssen noch die Features mit den Blast Hits abgeglichen werden!

	$i = @$blastHits;
	$i = 0;

	foreach my $blastHit (@$blastHits) {
		next unless ( defined $blastHit );
		$now      = 0;
		$features = undef;
		$features = $imgtFile->GetFeaturesInRange(
			$blastHit->S_start(), $blastHit->S_end(),
			$self->{imgtTOgb},    $self->{imgtFeatures}
		);
		$features = $self->{imgt2gb}->convert_imgtFeatures2gb($features);
		my @temp;
		$mappedfeatures = \@temp;

		## $features == array of gbFeatures in region $start to $end in imgt file
		if ( defined $features ) {
			foreach $feature (@$features) {
				## Change the feature location from the blast subject sequence to the blast query sequence,
				## add this Feature to the BlastHit List and insert this Feature into the internal Feature List of inverseBlastHit(s)
				push( @$mappedfeatures, $blastHit->AddFeature($feature) );
			}

#           push ( @$internalFeatureList, inverseBlastHit->new($blastHit->As_gbFeature(),$mappedfeatures));
#$features = $self->group_gbFeatures_byOverlap($mappedfeatures);
			print "New Blast Hit\n";
			foreach $feature (@$features) {
				my $temp =
				  inverseBlastHit->new( $blastHit->hit_as_feature("unsure"),
					$feature );
				push( @$internalFeatureList, $temp );
				print "POSSIBLE FEATURE:\n", $temp->getAsGB(),
				  "----------------------------------\n";
			}
			push( @return, $blastHit ) if ( $blastHit->HasIG_Features() );
			$i++;
		}
	}
	return \@return;
}

sub group_gbFeatures_byOverlap {
	my ( $self, $features ) = @_;

	my ( $lastEnd, @return, $gbFeature, $temp );
	$lastEnd = -2;

	foreach $gbFeature (@$features) {
		if ( $gbFeature->Start() > $lastEnd + 1 ) {
			push( @return, $temp ) if ( defined @$temp );
			my @temp;
			$temp = \@temp;
		}
		push( @$temp, $gbFeature );
	}
	push( @return, $temp ) if ( defined @$temp );
	return \@return;
}

1;
