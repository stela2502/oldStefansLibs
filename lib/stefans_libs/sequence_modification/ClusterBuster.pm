package ClusterBuster;
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

sub new{

	my ( $class ) = @_;

	my ( $self, @data );

	$self = {
		data => \@data,
		matrix => undef
  	};

  	bless $self, $class  if ( $class eq "ClusterBuster" );

  	return $self;

}

sub getAs_gbFeatureArray{
	my ( $self, $cbust_attr, $today) = @_;
	## Alle daten aus $self->{data} in gbFeatures umwandeln!;
	my (@gbFeatures, $TF_matches, $arrayRef, $dataArray, $matrix_hash);
	$dataArray = $self->{data};
	$matrix_hash = $self->{matrix};
	
	foreach my $hash (  @$dataArray){
		my ($gbFeature_Cluster);
		$gbFeature_Cluster = gbFeature->new("misc_feature","$hash->{start}..$hash->{end}");
		$gbFeature_Cluster->AddInfo("note", "sequence=$hash->{sequence}");
		$gbFeature_Cluster->AddInfo("note", "Score = $hash->{score}");
		$gbFeature_Cluster->AddInfo("note", "cbust_attr=$cbust_attr") if ( defined $cbust_attr);
		$gbFeature_Cluster->AddInfo("note", "creationDate=$today") if ( defined $today);
		push(@gbFeatures, $gbFeature_Cluster);
		$TF_matches = $hash->{features};
		foreach my $HashRef (@$TF_matches){
			my $gbFeature;
			while ( my ( $key, $value ) = each %$HashRef){
				print "DEBUG $self: new TF_match with $key and $value\n";
			}
			$gbFeature = gbFeature->new("misc_feature", "$HashRef->{start}..$HashRef->{end}")
				if ($HashRef->{orientation} eq "+");
			$gbFeature = gbFeature->new("misc_feature", 
				"complement($HashRef->{start}..$HashRef->{end})")
				if ($HashRef->{orientation} eq "-");
			$gbFeature->AddInfo("db_xref",$HashRef->{db_xref});
			$gbFeature->AddInfo("note","Score=$HashRef->{score}");
			if ( defined $matrix_hash->{$HashRef->{db_xref}}){
				$gbFeature->AddInfo("note","TF_type=$matrix_hash->{$HashRef->{db_xref}}->{type}");
				$gbFeature->Name($matrix_hash->{$HashRef->{db_xref}}->{name});
			}
			print "DEBUG $self gbFeature on creation:\n", $gbFeature->getAsGB();
			push(@gbFeatures, $gbFeature);
		}
	}
	foreach my $t ( @gbFeatures){
		print "DEBUG $self: final gbFeatures\n",$t->getAsGB();
	}
	return \@gbFeatures;
}

sub readMatrixFile{
	my ( $self, $matrix) = @_;
	open ( IN ,"<$matrix") or die "could not open $matrix\n";
	
	## data structure of $self->{matrix}:
	## hash with the structure:
	## <db_xref> => { name => string, type => string}
	my ($hash, $name, $db_xref, $type);
	$self->{matrix} = $hash unless ( defined $self->{matrix});
	
	while (<IN>){
		next unless ( $_ =~ m/^>/);
		chomp $_;
		($db_xref, $name, $type ) = ( $1, $2, $3)
			if ( $_ =~ m/>(.+) (.+) (.*)/ );
		print "DEBUG: $self, readMatrixFile $db_xref, $name, $type\n";
		$self->{matrix}->{$db_xref} = {name => $name, type => $type};
	} 
	close (IN);
	return;
}

sub readCbustData{
	my ( $self, $file) = @_;
	open (IN, "<$file") or die "could not open $file\n";
	
	## data structure:
	## array of clusters!
	## cluster = hash with the structure:
	## start => int, end => int, score => float, sequence => string, features => <array>
	## der hits_array besteht wiederum aus hashes mit der struktur:
	## start => int, end => int, score => float, sequence => string, db_xref => string, orientation => string
	
	my ($results, $inCluster, $hash, $arrayRef);
	$results  = $self->{data};
	
	while (<IN>){
		chomp $_;
		unless ( $inCluster){
			if ( $_ =~ m/^CLUSTER \d+/){
				$inCluster = 1 == 1;
				$hash = {};
				print "DEBUG $self: new gbFeatreu for Cluster: $hash\n";
			}
			next;
		}
		if ( $_ =~ m/Location: (\d+) to (\d+)/){
			($hash->{start}, $hash->{end}) = ($1, $2);
			print "DEBUG $self: add 2 hash $hash Cluster start/end = $hash->{start}..$hash->{end}\n";
			#print "DEBUG $self: $hash\n";
			next;
		}
		if ( $_ =~ m/Score: (.*)/){
			$hash->{score} = $1;
		}
		next if ( $_ =~ m/\w+: /);
		if ( $_ =~ m/\t/){
			unless ( defined $hash->{features}){
				my @temp;
				$hash->{features} = \@temp;
			}
			$arrayRef = $hash->{features};
			my $f;
			##MA0108  3430    3444    +       4.26    aaataaaaagccctt
			#print "DEBUG $self: we create a new feature out of the following line:\n\t$_\n";
			($f->{db_xref}, $f->{start}, $f->{end}, $f->{orientation}, $f->{score}, $f->{sequence}) =
				split ( "\t" , $_ );
			push (@$arrayRef, $f);
		}
		if ( $_ =~ m/^[AGTCagtc]+$/){
			$hash->{sequence} = $_;
			#print "DebUG $self: Cluster sequence = $_\n";
			next;
		}
		if ($_ eq ""){
			push(@$results, $hash);
			$inCluster = 1 == 0 ;
		}
	}	
	
	close(IN);
}

1;
