package imgtFile;
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
use stefans_libs::sequence_modification::imgtFeature;

sub new {
    my ( $class, $arrayRef, $accession ) = @_;

    my ( $self, @features );

    $self = { 
		features => \@features,
		accession => $accession
	};

    bless( $self, $class ) if ( $class eq "imgtFile" );

    $self->parseDBarray($arrayRef) if ( defined $arrayRef );

    return $self;
}

sub parseDBarray {

    my ( $self, $arrayRef, $accession ) = @_;

    my ( @oneFeature, $features, $temp, $i, $line, $imgtFeature );
	
    $features = $self->{features};
	$self->{accession} = $accession;
#    print "imgtFile : parseDBarray got lines:\n";
    
    foreach $line (@$arrayRef) {
#        $i = 0;
#        print "\n";
#        foreach $temp ( @$line){
#           print $i++,"->$temp\t";
#        }
#        print "\n";

        if ( @$line[2] eq "range" ) {
#           print "range\n";
           push (@$features, $self->{act_imgtFeature} ) if ( defined $self->{act_imgtFeature} );
		   $self->{act_imgtFeature} = imgtFeature->new();
		   $self->{act_imgtFeature}->AddRange($line);
		   next;
		}
		unless ( defined $self->{act_imgtFeature}) {
			#print "Komisch hier passt was nicht inimgtFile! line = ",join(";",@$line),"\n";
			next;
		}
		$self->{act_imgtFeature}->AddFeatureLine($line);
    }
    push (@$features, $self->{act_imgtFeature} ) if ( defined $self->{act_imgtFeature} );
	$i = @$features;
	#print "IMGT feature file got $i feature entries\n";
	return 1;
}

sub Print {
   my ( $self) = @_;
   my ( $feature, $featureList) ;
   $featureList = $self->Features();
   foreach $feature ( @$featureList){
      $feature->As_gbFeature();
   }
}

sub Features {

    my ( $self, $feature ) = @_;

    return $self->{features} unless ( defined $feature );

    if ( $feature =~ m/imgtFeature/ ) {
        my $features = $self->{features};
        push ( @$features, $feature);
    }
    return $self->{features};
}

sub GetFeaturesInRange{
	my ( $self, $start, $end, $imgt2gb, $wantedIMGTfeatures) = @_;
	my ( $features, @return, $feature, $report, $feature_array, $temp, @regionNames);
	$features = $self->Features();
	#$report = 1 if ( $self->{accession} eq "AE000663");
	
	foreach $feature ( @$features){
		push (@regionNames, { start =>  $feature->Start(), end => $feature->End(), gene => $feature->Gene() })
			if ( defined $feature->Gene());
		#if ( defined $report && defined $feature->Gene()){
	#		print "GetFeaturesInRange possible gene name: ",$feature->Start(),"..",$feature->End(),"->",$feature->Gene(),"\n";
	#	}
		push ( @return, $feature) if ( $feature->Start() >= $start -10 && $feature->End() <= $end +10);
	}
	foreach $feature ( @return ) {
		foreach my $infoLocation ( @regionNames){
			$feature->Gene($infoLocation->{gene})
				if ( $feature->Start >= $infoLocation->{start} && $feature->End <= $infoLocation->{end});
		}
		#print "used gene names: ",$feature->Start,"..",$feature->End,",->",$feature->Gene(),"\n"
		#	if ( defined $report);
	}
	return undef if ( @return == 0);
	return \@return;
}


1;
