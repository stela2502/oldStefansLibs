package imgt2gb;
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

sub new {

   my ( $class ) = @_;

   my ( $self, $imgt);
$imgt = {
    "(DJ)-C-CLUSTER"       => "misc_sequence",
    "(DJ)-J-C-CLUSTER"     => "misc_sequence",
    "(DJ)-J-CLUSTER"       => "misc_sequence",
    "(VDJ)-C-CLUSTER"      => "misc_sequence",
    "(VDJ)-J-C-CLUSTER"    => "misc_sequence",
    "(VDJ)-J-CLUSTER"      => "misc_sequence",
    "(VJ)-C-CLUSTER"       => "misc_sequence",
    "(VJ)-J-C-CLUSTER"     => "misc_sequence",
    "(VJ)-J-CLUSTER"       => "misc_sequence",
    "1st-CYS"              => "misc_sequence",
    "2nd-CYS"              => "misc_sequence",
#    "3'D-HEPTAMER"         => "misc_signal",
#    "3'D-NONAMER"          => "misc_signal",
#    "3'D-RS"               => "misc_signal",
    "3'D-SPACER"           => "misc_sequence",
#    "3'UTR"                => "3'UTR",
#    "5'D-HEPTAMER"         => "misc_signal",
#    "5'D-NONAMER"          => "misc_signal",
#    "5'D-RS"               => "misc_signal",
#    "5'D-SPACER"           => "misc_signal",
#    "ACCEPTOR-SPLICE"      => "misc_signal",
#    "C-CLUSTER"            => "gene",
#    "C-GENE"               => "gene",
    "C-LIKE-DOMAIN"        => "gene",
    "C-REGION"             => "C_region",
    "C-SEQUENCE"           => "C_region",
    "CAAT_SIGNAL"          => "CAAT_signal",
    "CAP_SITE"             => "misc_sequence",
    "CDR1"                 => "misc_sequence",
    "CDR1-IMGT"            => "misc_sequence",
    "CDR2"                 => "misc_sequence",
    "CDR2-IMGT"            => "misc_sequence",
    "CDR3"                 => "misc_sequence",
    "CDR3-IMGT"            => "misc_sequence",
    "CH-S"                 => "C_region",
    "CH-SD"                => "misc_sequence",
    "CH-T"                 => "misc_sequence",
    "CH-X"                 => "misc_sequence",
    "CH1"                  => "C_region",
    "CH1D"                 => "exon",
    "CH2"                  => "C_region",
    "CH2D"                 => "exon",
    "CH3"                  => "C_region",
    "CH3D"                 => "exon",
    "CH4"                  => "C_region",
    "CH4D"                 => "exon",
    "CH5"                  => "C_region",
    "CH6"                  => "C_region",
    "CH7"                  => "C_region",
    "CL"                   => "exon",
#    "CONFLICT"             => "conflict",
#    "CONNECTING-REGION"    => "exon",
    "CONSERVED-TRP"        => "misc_sequence",
    "CYTOPLASMIC-REGION"   => "misc_sequence",
    "D-(DJ)-C-CLUSTER"     => "misc_sequence",
    "D-(DJ)-CLUSTER"       => "misc_sequence",
    "D-(DJ)-J-C-CLUSTER"   => "misc_sequence",
    "D-(DJ)-J-CLUSTER"     => "misc_sequence",
    "D-CLUSTER"            => "misc_sequence",
#    "D-GENE"               => "D_segment",
    "D-J-C-CLUSTER"        => "misc_sequence",
    "D-J-C-SEQUENCE"       => "misc_sequence",
    "D-J-CLUSTER"          => "misc_sequence",
    "D-J-GENE"             => "misc_sequence",
    "D-J-REGION"           => "misc_sequence",
    "D-J-SEQUENCE"         => "misc_sequence",
    "D-REGION"             => "D_segment",
    "D-SEQUENCE"           => "D_segment",
#    "D1-REGION"            => "D_segment",
#    "D2-REGION"            => "D_segment",
#    "D3-REGION"            => "D_segment",
#    "DECAMER"              => "misc_signal",
#    "DELETION"             => "misc_recomb",
#    "DONOR-SPLICE"         => "misc_signal",
#    "DUPLICATION"          => "misc_recomb",
    "ENHANCER"             => "enhancer",
    "EX1"                  => "exon",
    "EX2"                  => "exon",
    "EX2A"                 => "exon",
    "EX2B"                 => "exon",
    "EX2C"                 => "exon",
    "EX2R"                 => "exon",
    "EX2T"                 => "exon",
    "EX3"                  => "exon",
    "EX4"                  => "exon",
    "EXON"                 => "exon",
    "FR1"                  => "misc_sequence",
    "FR1-IMGT"             => "misc_sequence",
    "FR2"                  => "misc_sequence",
    "FR2-IMGT"             => "misc_sequence",
    "FR3"                  => "misc_sequence",
    "FR3-IMGT"             => "misc_sequence",
    "FR4-IMGT"             => "misc_sequence",
    "GENE"                 => "gene",
#    "H"                    => "exon",
#    "H1"                   => "exon",
#    "H2"                   => "exon",
#    "H3"                   => "exon",
#    "H4"                   => "exon",
#    "H5"                   => "exon",
#    "HEPTANUCLEOTIDE"      => "misc_signal",
#    "HINGE-REGION"         => "exon",
#    "I-EXON"               => "exon",
#    "INDETERMINATION"      => "unknown",
    "INIT-CODON"           => "misc_sequence",
    "INIT-CONS"            => "misc_sequence",
    "INSERTION"            => "misc_recomb",
    "INT-DONOR-SPLICE"     => "misc_signal",
    "INTERNAL-HEPTAMER"    => "misc_signal",
#    "INTRON"               => "intron",
    "J-C-CLUSTER"          => "misc_sequence",
    "J-C-INTRON"           => "misc_sequence",
    "J-C-REGION"           => "misc_sequence",
    "J-C-SEQUENCE"         => "misc_sequence",
    "J-CLUSTER"            => "misc_sequence",
#    "J-HEPTAMER"           => "misc_recomb",
#    "J-NONAMER"            => "misc_recomb",
    "J-PHE"                => "misc_sequence",
#    "J-GENE"               => "J_region",
#    "J-RS"                 => "misc_recomb",
    "J-REGION"             => "J_segment",
#    "J-SPACER"             => "misc_recomb",
    "J-TRP"                => "misc_sequence",
    "JUNCTION"             => "misc_sequence",
    "L-INTRON-L"           => "misc_sequence",
    "L-PART1"              => "V_segment",
#    "L-PART2"              => "exon",
    "L-REGION"             => "V_segment",
    "L-V-D-J-C-REGION"     => "misc_sequence",
    "L-V-D-J-C-SEQUENCE"   => "misc_sequence",
    "L-V-D-J-REGION"       => "misc_sequence",
    "L-V-D-REGION"         => "misc_sequence",
    "L-V-D-SEQUENCE"       => "misc_sequence",
    "L-V-J-C-REGION"       => "misc_sequence",
    "L-V-J-C-SEQUENCE"     => "misc_sequence",
    "L-V-J-REGION"         => "misc_sequence",
    "L-V-REGION"           => "misc_sequence",
    "L-V-SEQUENCE"         => "misc_sequence",
    "LINKER"               => "misc_sequence",
#    "M"                    => "exon",
#    "M1"                   => "exon",
#    "M2"                   => "exon",
    "MISC_FEATURE"         => "misc_sequence",
#    "MISC_RECOMB"          => "misc_recomb",
#    "MODIFICATION"         => "variation",
#    "MUTATION"             => "variation",
    "N-AND-D-J-REGION"     => "misc_sequence",
    "N-AND-D-REGION"       => "misc_sequence",
    "N-GLYCOSYLATION-SITE" => "misc_sequence",
    "N-REGION"             => "misc_sequence",
    "N1-REGION"            => "misc_sequence",
    "N2-REGION"            => "misc_sequence",
    "N3-REGION"            => "misc_sequence",
    "N4-REGION"            => "misc_sequence",
    "OCTAMER"              => "enhancer",
    "P-REGION"             => "misc_sequence",
    "PENTADECAMER"         => "misc_sequence",
    "POLYA_SIGNAL"         => "polyA_signal",
#    "POLYA_SITE"           => "polyA_site",
#    "PRIMER_BIND"          => "misc_sequence",
    "PYR-RICH"             => "misc_sequence",
#    "REPEAT_UNIT"          => "repeat_region",
    "SILENCER"             => "terminator",
    "STERILE-TRANSCRIPT"   => "misc_sequence",
    "STOP-CODON"           => "misc_sequence",
#    "SWITCH"               => "misc_recomb",
    "TATA_BOX"             => "TATA_signal",
    "TRANSMEMBRANE-REGION" => "misc_sequence",
    "UNSURE"               => "unsure",
#    "UTR"                  => "UTR",
    "V-(DJ)-C-CLUSTER"     => "misc_sequence",
    "V-(DJ)-CLUSTER"       => "misc_sequence",
    "V-(DJ)-J-C-CLUSTER"   => "misc_sequence",
    "V-(DJ)-J-CLUSTER"     => "misc_sequence",
    "V-(VDJ)-C-CLUSTER"    => "misc_sequence",
    "V-(VDJ)-CLUSTER"      => "misc_sequence",
    "V-(VDJ)-J-C-CLUSTER"  => "misc_sequence",
    "V-(VDJ)-J-CLUSTER"    => "misc_sequence",
    "V-(VJ)-C-CLUSTER"     => "misc_sequence",
    "V-(VJ)-CLUSTER"       => "misc_sequence",
    "V-(VJ)-J-C-CLUSTER"   => "misc_sequence",
    "V-(VJ)-J-CLUSTER"     => "misc_sequence",
    "V-CLUSTER"            => "misc_sequence",
    "V-D-(DJ)-C-CLUSTER"   => "misc_sequence",
    "V-D-(DJ)-CLUSTER"     => "misc_sequence",
    "V-D-(DJ)-J-C-CLUSTER" => "misc_sequence",
    "V-D-(DJ)-J-CLUSTER"   => "misc_sequence",
    "V-D-EXON"             => "misc_sequence",
    "V-D-GENE"             => "misc_sequence",
    "V-D-J-C-CLUSTER"      => "misc_sequence",
    "V-D-J-C-REGION"       => "misc_sequence",
    "V-D-J-CLUSTER"        => "misc_sequence",
    "V-D-J-EXON"           => "misc_sequence",
    "V-D-J-GENE"           => "misc_sequence",
    "V-D-J-REGION"         => "misc_sequence",
    "V-D-REGION"           => "misc_sequence",
    "V-EXON"               => "V_segment",
    "V-GENE"               => "gene",
#    "V-HEPTAMER"           => "misc_recomb",
#    "V-INTRON"             => "intron",
    "V-J-C-CLUSTER"        => "misc_sequence",
    "V-J-C-REGION"         => "misc_sequence",
    "V-J-CLUSTER"          => "misc_sequence",
    "V-J-EXON"             => "misc_sequence",
    "V-J-GENE"             => "misc_sequence",
    "V-J-REGION"           => "misc_sequence",
    "V-LIKE-DOMAIN"        => "misc_sequence",
#    "V-NONAMER"            => "misc_recomb",
    "V-REGION"             => "V_segment",
#    "V-RS"                 => "misc_recomb",
#    "V-SPACER"             => "misc_recomb",
#    "VARIATION"            => "variation",
    "scFv"                 => "misc_sequence"
};
   $self = {
     imgt2gb => $imgt
   };

   bless ($self , $class ) if ( $class eq "imgt2gb");
   return $self;
}

sub convert_imgtFeatures2gb {
  my ( $self, $imgtFeatures ) = @_;

  my ( $featureNames, $feature, @return, @range, $allele, $last, $blastLine_Features , $gene, $i, $alleleHash, $nameHash);
  return undef unless ( defined $imgtFeatures );
  return undef unless ( @$imgtFeatures > 0 );

  ($featureNames, $alleleHash, $nameHash) = $self->getFeatureNameList($imgtFeatures);

  ## in case of a V-segment:
  if ( join("",@$featureNames) =~ m/V-EXON/ || join("",@$featureNames) =~ m/V-REGION/ ||join("",@$featureNames) =~ m/L-PART1/ ){
     ## create region Information    
		$i = 0;
		@range = undef;
        foreach  $feature ( @$imgtFeatures ){
            if ( $feature->{name} eq "L-PART1" || $feature->{name} eq "L-REGION"){
               if ( $i == 0){
					push (@range, $feature->{region}->getAsGB());
					$i = 1;
				}
				elsif ( $i == 1 && $feature->Complement() eq "complement"){
					push (@range, $feature->{region}->getAsGB());
					$i = 2;
				}
				else{
					my $gbfeature = gbFeature->new("V_segment",join(",",@range));
					$gbfeature->AddInfo("note","IMGT_feature_tag=$feature->{name}");
					unless (defined $allele ) {
						$allele = $alleleHash->{$feature->{region}->Start()};
						unless (defined $allele ) { 
							$allele = join ( " ", values %$alleleHash);
						}
					}
					$gbfeature -> AddInfo ( "allele", $allele ) if (defined $allele);
					foreach my $featureArray (@$blastLine_Features){
						$gbfeature->AddInfo(@$featureArray[0],@$featureArray[1]);
					}
					unless (defined $gene){
						$gene = $nameHash->{$feature->{region}->Start()};
						unless (defined $gene){
							$gene = join ( " ", values %$nameHash);
						}
					}
					$gbfeature -> AddInfo ( "gene", $gene) if (defined $gene);
					push (@return,$gbfeature);
					@range = undef;
					$i = 0;
					$blastLine_Features = $feature->Features();
					foreach my $featureArray (@$blastLine_Features){
						$gbfeature->AddInfo(@$featureArray[0],@$featureArray[1]);
					}
					push (@range, $feature->{region}->getAsGB());
				}
			    $last = "L-PART1";
            }
			#elsif ( $feature->{name} eq "V-REGION" || $feature->{name} eq "V-GENE" ){
			elsif ($feature->{name} eq "V-GENE" ){
				$gene = $feature->Gene() if (defined $feature->Gene());
				$allele = $feature->Allele() if ( defined $feature->Allele());
			}
			
            elsif ( $feature->{name} eq "V-EXON" || $feature->{name} eq "V-REGION"){
				$last = "V-EXON";
				if ( $i == 1 || $i == 0){
					push (@range, $feature->{region}->getAsGB());
					$i = 2;
				}
				elsif ( $i == 1 && $feature->Complement() eq "complement"){
					push (@range, $feature->{region}->getAsGB());
					$i = 1;
				}
				else{
					my $gbfeature = gbFeature->new("V_segment",join(",",@range));
					unless (defined $allele ) {
						$allele = $alleleHash->{$feature->{region}->Start()};
						unless (defined $allele ) { 
							$allele = join ( " ", values %$alleleHash);
						}
					}
					$gbfeature -> AddInfo ( "allele", $allele ) if (defined $allele);
					$gbfeature->AddInfo("note","IMGT_feature_tag=$feature->{name}");
					
					$blastLine_Features = $feature->Features();
					foreach my $featureArray (@$blastLine_Features){
						$gbfeature->AddInfo(@$featureArray[0],@$featureArray[1]);
					}
					unless (defined $gene){
						$gene = $nameHash->{$feature->{region}->Start()};
						unless (defined $gene){
							$gene = join ( " ", values %$nameHash);
						}
					}
					push (@return,$gbfeature);
					@range = undef;
					$i = 0;
					push (@range, $feature->{region}->getAsGB());
				}
            }
			elsif ( $feature->{name} eq "V-GENE"){
				$allele = $feature->Allele();
                $gene = $feature->Gene();
            }
        }
        if ( defined  $range[0]){
			unless ( $last eq "V-EXON"){
				@range = undef;
				next;
			}
			my $gbfeature = gbFeature->new("V_segment",join(",",@range));
			$gbfeature -> AddInfo ( "allele", $allele ) if (defined $allele);
			$gbfeature -> AddInfo ( "gene", $gene) if (defined $gene);
			$gbfeature->AddInfo("note","IMGT_feature_tag=something unknown reslulted in a range!");
			push (@return,$gbfeature);
        } 
      
   }
   foreach  $feature ( @$imgtFeatures ){
      next if ( "V-EXON L-PART1 V-REGION V-GENE" =~ m/$feature->{name}/);
      next unless ( defined $self->{imgt2gb}->{$feature->{name}});
      next if ( $self->{imgt2gb}->{$feature->{name}} eq "misc_sequence");

      my $gbFeature = gbFeature->new($self->{imgt2gb}->{$feature->{name}}, $feature->{region}->getAsGB());
      $gbFeature->AddInfo("note","IMGT_feature_tag=$feature->{name}");
      $blastLine_Features = $feature->Features();
      foreach my $featureArray (@$blastLine_Features){
         $gbFeature->AddInfo(@$featureArray[0],@$featureArray[1]);
      }
      push(@return,$gbFeature);
   }
   return \@return;
}

sub IMGTtag2GBtag{
	my ( $self, $imgtTag) = @_;
	return $self->{imgt2gb}->{$imgtTag};
}

sub getFeatureNameList {
  my ( $self, $imgtFeatures) = @_;

  my ( $feature, @list, $name, $allele);

  foreach $feature ( @$imgtFeatures){
	push ( @list, $feature->{name}) if ( defined $feature->{name});
	$allele->{$feature->Start()} = $feature->Allele() if ( defined $feature->Allele());
	$name->{$feature->Start()} = $feature->Gene() if ( defined $feature->Gene());
  }
  print "getFeatureNameList: ", join (";",@list), "\nalleles: ",join (";",(values %$allele)),"\ngenes: ", join(";",(values %$name)),"\n";
  return \@list, $allele, $name;
}

1;
