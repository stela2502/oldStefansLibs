package geneInfo;
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

sub new{

	my ( $class, $probeSet, $info ) = @_;

	my ( $self );

		#Probe Set -> <Probe Set ID>
		#Description -> U48705 /FEATURE=mRNA /DEFINITION=HSU48705 Human receptor tyrosine kinase DDR gene, complete cds
	$self = {
		'probeSet' => $probeSet
  	};

  	bless $self, $class  if ( $class eq "geneInfo" );

	$self->parseInfo($info);

  	return $probeSet, $self if ( defined $probeSet);
  	return $self;

}

sub parseInfo{
	my ( $self, $info) = @_;
	
	my ( @array , $id, $gbID );
	#info could be: 
	# U48705 /FEATURE=mRNA /DEFINITION=HSU48705 Human receptor tyrosine kinase DDR gene, complete cds
	# or:
	# Cluster Incl. X72631:H.sapiens mRNA encoding Rev-ErbAalpha /cds=UNKNOWN /gb=X72631 /gi=732801 /ug=Hs.211606 /len=2335
	# gb:BC006309.1 /DEF=Homo sapiens, Similar to RIKEN cDNA 5730589L02 gene, clone MGC:13124, mRNA, complete cds.  /FEA=mRNA /PROD=Similar to RIKEN cDNA 5730589L02 gene /DB_XREF=gi:13623420 /FL=gb:BC006309.1
	
	# for the three possibilities the best matching hit in gene cards was the first entry U48705, X72631 resp. BC006309.1
	# therefore my first try is to search for the first word, that is matches to 
	# /(\w+\d+\.?\d*)/ (starting chars followed by a set of digits and possible one '.' )
	@array = split( /[ :=]/, $info);
	foreach my $potID ( @array ) {
		if ( $potID =~ m/(\w+\d+\.?\d*)/ ){
			if ( $gbID ){
				$gbID = $1;
			}
			else{
				$id = $1;
			}
			last if ( defined $gbID && defined $id );
		}
		$gbID = 1==1 if ($potID =~ m/gb$/);
	}
	$self->{id} = $id;
	$self->{gbID} = $gbID;
	return 1;
}

sub getNCBI_Link{
	my ( $self ) = @_;
	return "  " unless ( defined $self->{gbID});
	return  "<a href=\"http://www.ncbi.nlm.nih.gov/projects/mapview/map_search.cgi?taxid=9606&query=$self->{gbID}&qchr=&strain=All\">NCBI Locusview $self->{gbID}</a>";
}

sub getGeneCards_Link{
	my ( $self ) = @_;
	return "  " unless ( defined $self->{id});
	return  "<a href=\"http://www.genecards.org/cgi-bin/carddisp.pl?gene=$self->{id}\">GeneCard $self->{id}</a>";
}

sub getKegg_Link{
	my ( $self ) = @_;
	return "  " unless ( defined $self->{id});
	return "<a href=\"http://www.genome.jp/dbget-bin/www_bfind_sub?mode=bfind&max_hit=1000&dbkey=kegg&keywords=$self->{id}\">KEGG $self->{id}<\a>";
}

1;
