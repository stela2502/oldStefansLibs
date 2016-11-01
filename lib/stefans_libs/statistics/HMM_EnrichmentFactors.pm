package HMM_EnrichmentFactors;
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

use stefans_libs::statistics::HMM;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::statistics::HMM::UMS_EnrichmentFactors;


@ISA = qw(HMM);

sub new{

  my ( $class ) = @_;

    my $ums               = UMS_EnrichmentFactors->new();
    my $newGFFtoSignalMap = newGFFtoSignalMap->new();
    my $datapath = NimbleGene_config::DataPath;
    $datapath = "$datapath/HMM_EnrichemntFacorBased";
    my ( $today, $root );
    $root = root->new();
    $today = $root->Today();
    $datapath = "$datapath/$today";
 
    my $self = {
#	    UMS_test => 1,
        root => $root,
		gffFile => gffFile->new(),
        newGFFtoSignalMap => $newGFFtoSignalMap,
        arrayData         => undef,
        UMS               => $ums,
        d0                => NimbleGene_config::D0,
        disribution_data_path         => $ums->{data_path},
        results_data_path => $datapath
    };
    print "HMM datapath = $datapath\n";
    system ( "mkdir $datapath -p ");

  bless $self, $class  if ( $class eq "HMM_EnrichmentFactors" );

  return $self;

}

sub CalculateHMM {

    my ( $self, $hash, $file ) = @_;

    my ( $ArrayData, $HMM_Data, $i, $hole, $temp, $last, $now, $Markov_Table, $Preset_hash );

    unless ( defined $hash->{antibody} ) {
        die "CalculateHMM muss wissen, welchen Hyb Type es auswerten soll!\n";
        $hash->{antibody} = "H3Ac";
        $hash->{celltype} = "Rag-KO proB";
        $hash->{organism} = "Mus musculus";
        $hash->{designID} = "2005-09-08_RZPD1538_MM6_ChIP";
    }
    print "CalculateHMM with $hash->{antibody} $hash->{celltype} $hash->{organism}\n";
    $self->{antibody} = $hash->{antibody};
    $self->{celltype} = $hash->{celltype};
    $self->{organism} = $hash->{organism};
    $self->{designID} = $hash->{designID};

    print "Insert arrayData\n";
    $hash->{what} = "TStat";
    $self->{arrayData} =
      $self->{gffFile}->GetData_HMM( $file, "position", $hash->{antibody}, 
	  $hash->{celltype}, $hash->{organism}, $hash->{designID} );
    $ArrayData = $self->{arrayData};
    $temp      = @$ArrayData;
    print "$temp OligoDaten wurden übergeben!\n";

    $i = $hole = 0;
    foreach $temp (@$ArrayData) {
        unless ( defined $last ) {
            $last = (( $temp->{end} - $temp->{start} )**2)**0.5 / 2 + $temp->{start};
            $i++;
            next;
        }
        $i++;
        $now = (( $temp->{end} - $temp->{start} )**2)**0.5 / 2 + $temp->{start};
        $hole++ if ( $now - $last > $self->{d0} ); ## d0 default == 500
        $last = $now;
    }
    print " Löcher in der Marcow Kette (do = $self->{d0}): $hole, Glieder in der Kette : $i\n";
    $Preset_hash->{Pd0} = $hole / $i;
    print "Warscheinlichkeit einer Lücke in der Markow Reihe: $self->{Pd0}\n";

    print "calculate starting MarkowModel\n";

    ( $Preset_hash->{f0}, $Preset_hash->{f1}, $Preset_hash->{phi0} ) = $self->{UMS}->UMS($hash->{antibody},$hash->{celltype},$hash->{organism},$hash->{designID}, $self->{arrayData});

    $Preset_hash->{a1}     = 1 / 40;
    $Preset_hash->{"1-a1"} = 1 - $Preset_hash->{a1};
    $Preset_hash->{a0}     = $Preset_hash->{a1} * ( 1 - $Preset_hash->{phi0} ) / $Preset_hash->{phi0};
    $Preset_hash->{"1-a0"} = 1 - $Preset_hash->{a0};
    $Preset_hash->{phi1}   = 1 - $Preset_hash->{phi0};

    $self->setPresets($Preset_hash);

    $self->PrintReestimate("firstEstimation");    
#    print "a1 = $self->{a1}\n1-a1 = $self->{\"1-a1\"}\na0 = $self->{a0}\n1-a0 = $self->{\"1-a0\"}\nphi0 = $self->{phi0}\nphi1 = $self->{phi1}\n";

    print "Initializion of the MarkowTable\n";

	if ( defined $self->{UMS_test}){
		warn "Abbruch nach der HM-Modell erstellung, da UMS_test gesetzt!\n";
		return 0;
	}
    $Markov_Table = $self->InitHMM();
#    $self->ExportMarkowTest( $Markov_Table, 0, "ONLY f0 and f1!" );
    $last = 10;
    for ( my $i = 1 ; $i <= $last; $i++ ) {
        print "Calculation Round $i\n";
#    print "a1 = $self->{a1}\n1-a1 = $self->{\"1-a1\"}\na0 = $self->{a0}\n1-a0 = $self->{\"1-a0\"}\nphi0 = $self->{phi0}\nphi1 = $self->{phi1}\n";

#        $self->ExportMarkowTest( $Markov_Table, $i, "ONLY f0 and f1!" );
        print "\tCalculateForwardProbability\n";
        $self->CalculateForwardProbability($Markov_Table);
        print "\tCalculateBackwardProbability\n";
        $self->CalculateBackwardProbability($Markov_Table);
        print "\tCalculateTotalProbabilityFromStartToEnd\n";
        $self->CalculateTotalProbabilityFromStartToEnd($Markov_Table);
        if ( $i < 20 ){
           print "\tExportMarkowForSignalMap\n";
           $self->ExportMarkowForSignalMap( $Markov_Table, $i );
        }
        elsif ( $i / 5 == int ( $i / 5)){
           print "\tExportMarkowForSignalMap\n";
           $self->ExportMarkowForSignalMap( $Markov_Table, $i );
        }
        print "\tReestimateMarkowModel\n";
		$self->ReestimateMarkowModel_noSummUp ($Markov_Table, $i ) unless ($i == $last);
       # $self->ReestimateMarkowModel( $Markov_Table, $i ) unless ($i == $last);
    }
    print "Fertig!\n";
    return 1;
}

1;
