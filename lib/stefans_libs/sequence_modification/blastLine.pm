package blastLine;

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
use stefans_libs::gbFile::gbFeature;
use stefans_libs::gbFile::gbRegion;
use stefans_libs::sequence_modification::inverseBlastHit;

sub new {

	my ( $class, $line, $what ) = @_;

	my ( $self );

	unless (
		"addPrimerdoIMGTsearchAllBlastHitsSequences" =~ m/$what/ )
	{
		die
"$what -> Bis jetzt wird leider nur die Auswertung von Primer Bindestellen, BlastHits und IMGT Sequenzen ermšglicht!\n",
"fŸr deep sequencing daten ist die Klasse deepSeq_blastLine zustŠndig!\n";
	}
	
	$self = {};

	bless( $self, $class ) if ( $class eq "blastLine" );

	$self->parseBlastHitEntry( $line, $what );

#	root::print_hashEntries($self, 3, "We hab«ve a problem with the blastLine (no data?)");
	return $self;

}

sub startOnQuery {
	my ($self) = @_;
	return $self->{q_start};
}

sub endOnQuery {
	my ($self) = @_;
	return $self->{q_end};
}

sub Print {
	my ($self) = @_;
	my $string =
"$self->{queryID}\t$self->{subjectID}\t$self->{identity}\t$self->{alignment_length}\t$self->{mismatches}\t$self->{gap_openings}\t$self->{q_start}\t$self->{q_end}\t$self->{s_start}\t$self->{s_end}\t$self->{e_value}\t$self->{bit_score}\n";
	return $string;
}

sub E_value {
	my ( $self, $e_value ) = @_;
	$self->{e_value} = $e_value if ( defined $e_value );
	return $self->{e_value};
}

sub HasIG_Features {
	my ($self) = @_;
	## Hier gibt es ein Problem:
	## V_segmente bestehen aus mehreren Teilen. Falls das 2. exon fehlt wÃ¼rde ich das V_segment nicht annotieren!
	## Falls also dieser Hit ein V_Segment representiert sollten die features mindestens eine DNA flÃ¤che von 200 bp abdecken!

	my ( $features, $sum, $feature, $V_segment, $gene, $isIgGene );

	$features = $self->{features};
	$sum      = $V_segment = 0;
	$isIgGene = 0 > 12;
	foreach $feature (@$features) {
		$sum += $feature->getLength();
		$V_segment = 1 if ( $feature->IsIg_gene() eq "V" );
		$isIgGene = $feature->IsIg_gene() unless ($isIgGene);
		$gene = 1 if ( defined $feature->Name );
	}

	#  print "\$sum = $sum! ";
	#  print "No V_Segment \n" unless ( $V_segment == 1);
	#  print "V_Segment \n" if ( $V_segment == 1);
	return $sum > 200 if ( $V_segment == 1 );
	return $isIgGene;

}

sub JoinWith {
	my ( $self, $other ) = @_;
	## falls other und diese BlastLine mšglicherweise zusammen gehšren wŸrden
	## und blast das aber auf grund von Sequenzierfehlern nicht gefunden hat
	## werden die Zeilen kombiniert.
	my ($insertion);
	return undef unless ( $self->{subjectID} eq $other->{subjectID} );
	return undef
	  unless ( $self->Complement() eq $other->Complement() )
	  ;    ## gleiche Orientierung?
	 #return undef if ( ($self->S_end() - $other->S_start())** 2 > 2500); ## weniger als 50bp Fehler?
	my $test =
	  ( $self->{s_start} - $other->{s_end} ) -
	  ( $self->{q_start} - $other->{q_end} );
	my $difference = $self->{s_start} - $other->{s_end};
	return undef if ( ( $test > 4 || $test < -4 ) && ( $difference**2 <= 1 ) );

	#print "BlastResult Reader JoinWith difference = $test\n";
	## weniger als 4bp gap!
	if ( $test**2 > 1 ) {
		$self->{insertion}->{start} = $other->{q_end} - $self->{q_start};
	}
	return $self->merge($other);
}

sub merge {
	my ( $self, $other ) = @_;
	my ( @temp, @region, $temp, $gbRegion );

	$gbRegion = $self->{region}->{regions};

	push( @$gbRegion, { start => $other->{q_start}, end => $other->{q_end} } );

	$self->{region}->Region( $self->{region}->Print( 0, $other->{q_end} ) );
	$self->{alignment_length} =
	  $self->{alignment_length} + $other->{alignment_length};
	$self->{mismatches}   = $self->{mismatches} + $other->{mismatches};
	$self->{gap_openings} = $self->{gap_openings} + $other->{gap_openings};
	$self->{identity} =
	  ( $self->{alignment_length} - $self->{mismatches} ) /
	  ( $self->{alignment_length} ) * 100;
	@temp = ( $self->EndOnQueryFile, $other->StartOnQueryFile );

	$self->S_end( $other->S_end() ) if ( $other->S_end() > $self->S_end() );
	$self->S_start( $other->S_start() )
	  if ( $other->S_start() < $self->S_start() );

	$self->{q_end} = $other->{q_end} if ( $other->{q_end} > $self->{q_end} );
	$self->{q_start} = $other->{q_start}
	  if ( $self->{q_start} > $other->{q_start} );
	$self->{e_value}   = $self->{e_value} - $other->{e_value};
	$self->{bit_score} = $self->{bit_score} + $other->{bit_score};
	return $self;
}

sub numeric {
	return $a <=> $b;
}

sub anti_numeric {
	return $b <=> $a;
}

sub print {
	my ($self) = @_;
	print
"$self->{mode}\t$self->{queryID}\t$self->{subjectID}\t$self->{identity}\t$self->{alignment_length}\t",
"$self->{mismatches}\t$self->{gap_openings}\t$self->{q_start}\t$self->{q_end}\t$self->{s_start}\t",
	  "$self->{s_end}\t$self->{e_value}\t$self->{bit_score}\n";
}

sub Complement {
	my ($self) = @_;
	return "complement" if ( $self->{s_start} > $self->{s_end} );
	return undef;
}

sub isCompatibleWithPrimer {
	my ( $self, $primer, $minPercIdent, $minLength ) = @_;

	my ($primerLength);

	$minPercIdent = 100 unless ( defined $minPercIdent );
	$minLength    = 20  unless ( defined $minLength );

	#print "Versuch!!\n$primer->{sequenz}\n";
	if ( defined $primer ) {
		$primerLength = length( $primer->Seq() )
		  if ( defined $primer->{sequenz} );
	}

	return 1 == 2 if ( $self->{alignment_length} < $minLength );
	return 1 == 2 if ( $self->{identity} < $minPercIdent );

	return 1 == 2
	  if ( $self->S_end() + $self->{"5prime_mismatch"} < $primerLength );
	$self->{tw} = $primer->{tw};
	return 1 == 1;
}

sub AddFeature {

	my ( $self, $feature ) = @_;

	## $feature  == gbFeature!!

	return undef unless ( defined $feature );
	my ($diff);
	my $features = $self->{features};
	if ( $self->{s_start} < $self->{s_end} ) {
		$feature->ChangeRegion_Add( $self->StartOnQueryFile - $self->S_start );
		if ( defined $self->{insertion} ) {
			if ( $self->{insertion}->{start} < $feature->Start() ) {
				$feature->ChangeRegion_Add(
					$self->{insertion}->{end} - $self->{insertion}->{start} );
			}
		}
		push( @$features, $feature );
	}
	else {

#      print "complement hit!\nregion ",$feature->Name()," $self->{q_end} + $self->S_start() = ",$self->{q_end} + $self->S_start(),"\n";
		$diff = $feature->Start();
		$feature->ChangeRegion_Diff( $self->EndOnQueryFile, $self->S_start );
		push( @$features, $feature );
	}
	push( @$features, $feature );
	return $feature;

	#   return inverseBlastHit->new($self->As_gbFeature(), $feature);
}

sub As_gbFeature {
	my ($self) = @_;
	my ($feature);

	#return undef if ( defined $self->{insertion});
	if ( $self->{mode} eq "addPrimer" ) {
		$feature = $self->hit_as_feature("primer_bind");
		return $self->{features};
	}
	if ( $self->{mode} eq "doIMGTsearch" ) {
		return undef unless ( defined $self->{features} );
		$feature = $self->hit_as_feature("unknown");
		return $self->{features};
	}
	if ( "BlastHit Sequences AllBlastHits" =~ m/$self->{mode}/ ) {
		$feature = $self->hit_as_feature("unsure");
		return $self->{features};
	}
	else { return undef; }

}

sub hit_as_feature {
	my ( $self, $tag ) = @_;

	my ( $feature, $features, @temp );

	return $self->{$tag} if ( defined $self->{$tag} );

	@temp = ( $self->StartOnQueryFile(), $self->EndOnQueryFile() );
	$features = join( "..", @temp );
	if ( defined $self->Complement() ) {
		$feature = gbFeature->new( $tag, $self->{region}->getAsGB() );
	}
	else {
		$feature = gbFeature->new( $tag, $self->{region}->getAsGB() );
	}
	$feature->IsComplement( $self->Complement() );
	$feature->AddInfo( "gene", "\"TW$self->{tw} - $self->{subjectID}\"" );
	$feature->AddInfo( "note", "\"TW$self->{tw}\"" ) if ( defined $self->{tw} );
	$feature->AddInfo( "note",
"\"\%identity = $self->{identity}, alignment_length = $self->{alignment_length}, mismatches = $self->{mismatches}, gap_openings = $self->{gap_openings} E_value = $self->{e_value}, q_start = $self->{q_start}, q_end = $self->{q_end}, s_start = $self->{s_start}, s_end = $self->{s_end}\""
	);
	$feature->AddInfo( "note", "\"holes in alignment: ($self->{add_gap})\"" )
	  if ( defined $self->{add_gap} );
	$feature->AddInfo( "note",
"Insertion-from-$self->{insertion}->{start}-to- $self->{insertion}->{end}"
	);
	$feature->Add_noGB_Info( "identity",         $self->{identity} );
	$feature->Add_noGB_Info( "alignment_length", $self->{alignment_length} );
	$feature->Add_noGB_Info( "mismatches",       $self->{mismatches} );
	$feature->Add_noGB_Info( "gap_openings",     $self->{gap_openings} );
	$feature->Add_noGB_Info( "E_value",          $self->{e_value} );

	$features = $self->{features};
	push( @$features, $feature );
	return $feature;
}

sub meatsCriteria {
	my ( $self, $minPercIdent, $minLength ) = @_;
	return 1 == 1
	  if ( $minPercIdent <= $self->{identity}
		&& $minLength <= $self->{alignment_length} );
	return 1 == 2;
}

sub meatsEnhancedCriteria {
	my ( $self, $minPercIdent, $minLength, $maxGapOpen ) = @_;
	return 1 == 2 unless ( $self->meatsCriteria( $minPercIdent, $minLength ) );
	return 1 == 2 if ( $maxGapOpen > $self->{gap_openings} );
	return 1 == 1;
}

sub Region {
	my ( $self, $what ) = @_;

	if ( $what eq "hit" ) {
		return gbRegion->new( join( "..", ( $self->S_start, $self->S_end ) ) );
	}
	elsif ( $what eq "onSeq" ) {
		return gbRegion->new(
			join( "..", ( $self->StartOnQueryFile, $self->EndOnQueryFile ) ) );
	}
}

sub S_start {
	my ( $self, $start ) = @_;
	if ( defined $start ) {
		if ( $start < $self->{s_end} || !( defined $self->{s_start} ) ) {
			$self->{s_start} = $start;
		}
		else {
			$self->{s_end} = $start;
		}
	}
	return $self->{s_start} if ( $self->{s_start} < $self->{s_end} );
	$self->{complement} = "complement";
	return $self->{s_end};
}

sub S_end {
	my ( $self, $end ) = @_;
	if ( defined $end ) {
		if ( $self->{s_start} < $end || !( defined $self->{s_end} ) ) {
			$self->{s_end} = $end;
		}
		else {
			$self->{s_start} = $end;
		}
	}
	return $self->{s_start} if ( $self->{s_start} > $self->{s_end} );
	return $self->{s_end};
}

sub StartOnQueryFile {
	my ($self) = @_;
	return $self->{q_end} if ( $self->{q_end} < $self->{q_start} );
	return $self->{q_start};
}

sub EndOnQueryFile {
	my ($self) = @_;
	return $self->{q_start} if ( $self->{q_end} < $self->{q_start} );
	return $self->{q_end};
}

sub parseBlastHitEntry {
	my ( $self, $input, $what ) = @_;
	my ( $insertion, @features, @line );
	
	@line = split( "\t", $input );

	my $temp = {
		'5prime_mismatch' => 0,
		region            => gbRegion->new("$line[6]..$line[7]"),
		insertion         => $insertion,
		tw                => undef,
		features          => \@features,
		mode              => $what,
		queryID           => $line[0],
		subjectID         => $line[1],
		identity          => $line[2],
		alignment_length  => $line[3],
		mismatches        => $line[4],
		gap_openings      => $line[5],
		q_start           => $line[6],
		q_end             => $line[7],
		s_start           => $line[8],
		s_end             => $line[9],
		e_value           => $line[10],
		bit_score         => $line[11]
	};
	#print "DEBUG blastLine parseBlastHitEntry subjectID = $temp->{subjectID} changed to ";
	$temp->{subjectID} = $1 if ($temp->{subjectID} =~ m/lcl.(.+)/ );
	#print "$temp->{subjectID}\n";
	while ( my ( $key, $value ) = each %$temp){
		$self->{$key}= $value;
	}
	return 1;
}

sub hitLength{
	my ( $self) = @_;
	return $self->{s_start} - $self->{s_end} +1 if ( $self->{s_start} > $self->{s_end});
	return $self->{s_end} - $self->{s_start} +1;
}

1
;
