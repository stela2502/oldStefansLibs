package UMS_EnrichmentFactors;
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

use stefans_libs::statistics::HMM::UMS;

@ISA = qw(UMS);

sub new{

  my ( $class ) = @_;

    my ( $dbh, $sth, %temp, %temp2, $ArrayDataRepresentation,$newGFFtoSignalMap, $root, $datapath, $today );
    $root = root->new();
    $dbh = $root->getDBH("NimbleGene_Test") or die $_;
    $newGFFtoSignalMap = newGFFtoSignalMap->new();
    $datapath = NimbleGene_config::DataPath();
#    $datapath = "$datapath/";
    $today = $root->Today();
    $datapath = "$datapath/probabilityDistributions/$today";

    my $self = {
        root                   => $root,
		category_steps         => 100,
        celltype               => undef,
        specificity            => undef,
        organism               => undef,
        data                   => \%temp2,
        meanVarianz            => undef,
        quadErrorVarianz       => undef,
        meanShrinkageEstimator => undef,
        oligoCount             => 0,
        chipInfos              => undef,
        dbh                    => $dbh,
        data_path              => $datapath, 
        newGFFtoSignalMap      => $newGFFtoSignalMap
    };
    system ( "mkdir $datapath -p ");
	
    bless $self, $class  if ( $class eq "UMS_EnrichmentFactors" );

    system ( "mkdir $self->{data_path}");

  return $self;

}

sub UMS_getDistributions {

    my ( $self, $antibody, $celltype, $organism, $design, $data ) = @_;

    my (
      $group1, $group0, $olgioHash , $rv, $ht, $h0, $h1, $all, $definitionString
    );
    my @definitionString = ("$antibody.$celltype.$organism","_0-design$design");
    $definitionString = join("", @definitionString);
    @definitionString = split ( " ", $definitionString);
	$definitionString = join ("_",@definitionString);
	
    my $hash = {
     antibody => $antibody,
     celltype => $celltype,
     organism => $organism,
     designID => $design ,
     what => "TStat" };

    print "UMS UMS UMS UMS !! $antibody $celltype $organism $design\n UMS! UMS!";
	unless ( defined $data){
		$self->{newGFFtoSignalMap} = newGFFtoSignalMap->new();
		$data = $self->{newGFFtoSignalMap}->AddData( $hash );
    }
	
    $self->{arrayData} = $data;
      

    $group1 = $group0 = 0;


	my (@values, $f0, $f1, $next_f0, $next_f1, $p10, $last);
	
    for ( my $i = 0; $i < @$data; $i ++ ) {
	   $olgioHash  = @$data[$i];
	   $values[$i] = $olgioHash->{value};
	}   
	$f0 = root->quantilCutoff(\@values, 95 );
	$f1 = root->quantilCutoff(\@values, 95 );   
	$self->{max_val} = root->Max(@values);
	$self->{min_val} = root->Min(@values);
	$self->{spread} = ($self->{max_val} -$self->{min_val} ) / $self->{category_steps};

    print "Cutoff Values for h0 = all values >= $f0\nCutoff Values for f1 = all values < $f1\n";

    foreach $olgioHash ( @$data){

       ## the complete DataSet:
       $rv = $self->getCategoryOfTi($olgioHash->{value});
       unless ( defined $ht->{$rv} ) {
          $ht->{$rv} = 0;
       }
       $ht->{$rv}++;
       if ( defined $next_f0){
	      unless ( defined $h0->{$rv} ){
		     $h0->{$rv} = 0;
		  }
		  $h0->{$rv} ++ unless ( $olgioHash->{start} > $last + NimbleGene_config::D0() );
		  $next_f0 = undef;
		}
       if ( defined $next_f1){
	      unless ( defined $h0->{$rv} ){
		     $h1->{$rv} = 0;
		  }
		  $h1->{$rv} ++  unless ( $olgioHash->{start} > $last + NimbleGene_config::D0() );
		  $next_f1 = undef;
		}
		$last = $olgioHash->{end};
       $next_f0 = 1 if ( $olgioHash->{value} <= $f0);
	   $next_f1 = 1 if ( $olgioHash->{value} >= $f1);
    }

	my ( $changeH1, $changeH0);
    foreach $rv ( sort numeric keys %$ht ) {

		$changeH1 = $changeH0 = undef;
        $changeH1 = 1 unless ( defined $h1->{$rv} );
        $changeH1 = 1 if ( $h1->{$rv} == 0);
		
        $changeH0 = 1 unless ( defined $h0->{$rv} );
        $changeH0 = 1 if ( $h0->{$rv} == 0);
				
        if ( $rv < 0  ) {
		    $h1->{$rv} = 2 if ( defined $changeH1 );
			$h0->{$rv} = 1 if ( defined $changeH0 );
		}
		if ( $rv >= 0 ) {
		    $h1->{$rv} = 1 if ( defined $changeH1 );
			$h0->{$rv} = 2 if ( defined $changeH0 );
		}
		
    }

    $self->ScaleSumToOne( $ht, "Ht_$definitionString.txt" );
    $self->ScaleSumToOne( $h0, "F0_$definitionString.txt" );
    $self->ScaleSumToOne( $h1, "F1_$definitionString.txt" );
    warn "Print Problem in ScaleSumToOne for ht()\n" unless ( defined $ht);
    warn "Print Problem in ScaleSumToOne for h0()\n" unless ( defined $h0);
    warn "Print Problem in ScaleSumToOne for h1()\n" unless ( defined $h1);

    return $ht, $h0, $h1;
}

sub numeric {
	return $a<=> $b;
}

1;
