package deepSeq_blastLine;

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
@ISA = qw(blastLine);
use strict;

sub new {

	my ( $class, $line, $what, $referenceToFastaDB, $referenceToSSAKEinfo,
		$deepSeq_ID )
	  = @_;

	my ($self);

	unless ( "deepSequencing" =~ m/$what/ ) {
		die
"$what -> hier nur deep sequencing daten - sinst ist die Klasse blastLine zustŠndig!\n";
	}
	
	$self = { 
		debug => 1==1
	};

	bless $self, $class if ( $class eq "deepSeq_blastLine" );
	
	$self->{fastaDB}    = $referenceToFastaDB;
	$self->{SSAKE}      = $referenceToSSAKEinfo;
	$self->{deepSeq_ID} = $deepSeq_ID;
	
	$self->parseBlastHitEntry( $line, $what );

	return $self;

}

sub isFullLength {
	my ($self) = @_;
	print
	  "debug deepSeq_blastLine isFullLength ($self->{subjectID}) hit length = ",
	  $self->hitLength, " cluster length = ",
	  $self->{SSAKE}->Length( $self->{subjectID} ), "\n";
	return $self->hitLength == $self->{SSAKE}->Length( $self->{subjectID} );
}

sub Coverage{
	my ($self) = @_;
	return $self->{SSAKE}->Coverage( $self->{subjectID} );
}

sub RegionConsistsOf{
	my ( $self, $start, $end, $chars) = @_;
	if ( $end - $start > 4 && $self->{debug}){
		print "we test if ", $self->{fastaDB}->Get_SubSeq( $self->{subjectID}, $start, $end), " consists only of $chars:\n";
	}
	return $self->{fastaDB}->Get_SubSeq( $self->{subjectID}, $start, $end)  =~ m/^[$chars]+$/ ;
}

sub Check4polyA {
	my ($self) = @_;
	return $self->{polyA} if ( defined $self->{polyA} );
	my $sequenceLength = $self->{SSAKE}->Length( $self->{subjectID} ) ;
	## two possibilities:
	## a: the 'notMatched' region is on the chromosomal 5' end AND contains only 'A's (sens transcript)
	## b: the 'notMatched' region is on the chromosomal 3' end AND contains only 'T's (antisens transcript)

	return unless ( $self->RegionConsistsOf( 1, 2, "aAtT" ) || 
		$self->RegionConsistsOf( $sequenceLength, $sequenceLength + 1, "aAtT" ) );
	
	if ( $self->{debug}){
	print "We check for the existance of a polyA tail in contig \n", $self->{fastaDB}->getAsFasta($self->{subjectID}),"\n";
	print "the length of the cluster: ",$self->{SSAKE}->Length( $self->{subjectID} ),"\n";
	print "matching portion = ",$self->{fastaDB}->Get_SubSeq( $self->{subjectID},$self->{s_start},$self->{s_end} + 1),"\n";
	print "is eitehr the first nucleotide (",$self->{fastaDB}->Get_SubSeq( $self->{subjectID}, 0, 1 ),
		") or the last nucleotid (",$self->{fastaDB}->Get_SubSeq( $self->{subjectID}, $sequenceLength , $sequenceLength +1 )
		,") a 't' or 'a'?\n";
	}
	
	if ( !defined $self->Complement() ) {
		## sens orientation match -> a: only As b: only Ts
		if ( $self->{s_start} > 4 ) {
			## mismatch at the beginning of the contig -> has to be a antisense read -> only Ts in the overlapping sequence
			## >4 -> p(onlyT's)< 0.01
			$self->{polyA} =
			  $self->create_polyA_site( $self->startOnQuery(),
				$self->startOnQuery() + 5,
				1 == 0 )
			  if ( $self->RegionConsistsOf( 1, $self->{s_start}  , "tT" ) );
		}
		if ( $self->{s_end} < $sequenceLength - 3 ) {
			## mismatch at the end of the contig -> has to be a sens read -> only As in the overlapping sequence
			$self->{polyA} =
			  $self->create_polyA_site( $self->endOnQuery() - 5,
				$self->startOnQuery(), 1 == 0 )
			  if ( $self->RegionConsistsOf($self->{s_end} + 1 , $sequenceLength + 1, "Aa") );
		}
	}
	else{
		if ( $self->{s_start} < $sequenceLength - 3 ) {
			$self->{polyA} =
			  $self->create_polyA_site( $self->startOnQuery(),
				$self->startOnQuery() + 5,
				1 == 1 )
			  if ( $self->RegionConsistsOf($self->{s_end} +1 , $sequenceLength + 1, "Tt") );
		}
		if ( $self->{s_end} > 1 ){
			$self->{polyA} =
			  $self->create_polyA_site( $self->endOnQuery() -5 ,
			   $self->endOnQuery(), 1 ==1)
			  if ( $self->RegionConsistsOf(0 , $self->{s_end} , "Aa") );
		}
	}
	return $self->{polyA};
}

sub create_polyA_site {
	my ( $self, $start, $end, $complement ) = @_;
	my $polyA;
	$polyA = gbFeature->new( "polyA_signal", "$start..$end" )
	  unless ($complement);
	$polyA = gbFeature->new( "polyA_signal", "complement($start..$end)" )
	  if ($complement);

	$polyA->AddInfo( "note",
		"RNA end found while processing the contig $self->{subjectID} in deepSequening Run $self->{deepSeq_ID}" );
	return $polyA;
}

1;
