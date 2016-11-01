package UMS_old;
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
 

 #use statisticItem;
 use strict;
 use stefans_libs::root;
 use stefans_libs::statistics::HMM::state_values;
 use stefans_libs::statistics::new_histogram;
 use stefans_libs::statistics::newGFFtoSignalMap;
 use stefans_libs::NimbleGene_config;
 #use Graphics::GnuplotIF  qw(GnuplotIF);
 
 
 sub new {
 	my ($class) = @_;
 
 	my ( $dbh, $sth, %temp, %temp2, $ArrayDataRepresentation,
 		$newGFFtoSignalMap, $root, $datapath, $today );
 	$root              = root->new();
 	$dbh               = $root->getDBH("NimbleGene_Test") or die $_;
 	$newGFFtoSignalMap = newGFFtoSignalMap->new();
 	$datapath          = NimbleGene_config::DataPath();
 
 	#    $datapath = "$datapath/";
 	$today    = $root->Today();
 	$datapath = "$datapath/probabilityDistributions/$today";
 
 	my $self = {
 		root                   => $root,
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
 	system("mkdir $datapath -p ");
 	bless( $self, "UMS_old" );
 
 	system("mkdir $self->{data_path}");
 
 	return $self;
 }
 
 sub Category_steps {
 	my ( $self, $value ) = @_;
 	if ( defined $value ) {
 		die "$self category_steps has to be of type int! ($value)\n"
 		  if ( $value != int($value) );
 		$self->{category_steps} = $value;
 	}
 	return $self->{category_steps};
 }
 
 
 sub UMS_getDistributions {
 
 	my ( $self, $data ) = @_;
 
 	my ( @dataArray, $olgioHash, $rv, $ht, $h0, $h1, $all,
 		$definitionString );
 	my ( $f0_cutoff, $f1_cutoff, @f0_values, @f1_values);
 	my ( @values, $f0, $f1, $next_f0, $next_f1, $p10, $last );
 	
 	#@dataArray = (values %$data);
 
 	# dat kommt hier schon an!!
 	#$data = $self->{newGFFtoSignalMap}->matchOligoValues2OligoLocation($data, NimbleGene_config::DesignID());
 
 	print "create histo values: \n";
 	#open (DATA ,">oligoValues.dat" );
 	$self->{max_value} = -100;
 	$self->{min_value} = +100;
 	foreach my $oligoInfo ( @$data ){
 		$self->{max_value} = $oligoInfo->{value}
 			if ( $oligoInfo->{value} > $self->{max_value});
 		$self->{min_value} = $oligoInfo->{value}
 			if ( $oligoInfo->{value} < $self->{min_value});
 		push(@values,$oligoInfo->{value});
 	}
 	$ht = new_histogram->new("Ht");
 	$ht->Max($self->{max_value} + 0.0000000001);
 	$ht->Min($self->{min_value});
 	$ht->Category_steps(NimbleGene_config::CategorySteps());
 	
 	#close (DATA);
 	$f0_cutoff = root->quantilCutoff( \@values, 5 );
 	$f1_cutoff = root->quantilCutoff( \@values, 5 );
 	$self->{category_steps} = NimbleGene_config::CategorySteps;
 	
 	$ht -> CreateHistogram(\@values, undef, $self->{category_steps});
 	@values = ();
 	$next_f1 = $next_f0 = 0;
 	
 	$h0 = new_histogram->new("H0");
 	$h1 = new_histogram->new("H1");
 	$h0 -> copyLayout ($ht);
 	$h1 -> copyLayout ($ht);
 	
 	print "$self->UMS_getDistributions create F0 and F1 arrays with \$f0_cutoff = $f0_cutoff and \$f1_cutoff = $f1_cutoff\n";
 	
 	foreach $olgioHash (@$data) {
 
 		## the complete DataSet:
 
 		if ( $next_f0 == 1 ) {
 			$h0->AddValue($olgioHash->{value})
 			  unless ( $olgioHash->{start} > $last + NimbleGene_config::D0() );
 			$next_f0 = 0;
 		}
 		if ( $next_f1 == 1 ) {
 			$h1->AddValue($olgioHash->{value})
 			  unless ( $olgioHash->{start} > $last + NimbleGene_config::D0() );
 			$next_f1 = 0;
 		}
 		$last    = $olgioHash->{end};
 		$next_f0 = 1 if ( $olgioHash->{value} >= $f0_cutoff );
 		$next_f1 = 1 if ( $olgioHash->{value} <= $f1_cutoff );
 	}
 	$next_f0 = @f0_values;
 	$next_f1 = @f1_values;
 	
 	print "$next_f0 Werte fuer F0 und $next_f1 Werte fuer F1\n";
 
 	print "Malloc 5 ??\n";
 	
 #	my $gnuplot1 = Graphics::GnuplotIF->new({style => "boxes", title => "atTheBeginning"});
 #	$gnuplot1 -> gnuplot_cmd ( "set terminal png, set output \"atTheBeginning.png\" ");
 #	$gnuplot1 -> gnuplot_plot_xy( $h0->getOrderedXvalues(), $h0->getOrderedYvalues(), $h1->getOrderedYvalues() );
 	
 	$h0-> printHistogram2file ( "UMS_H0_atTheBeginning.txt" );
 	$h1-> printHistogram2file ( "UMS_H1_atTheBeginning.txt" );
 	
 	
 
 	$ht-> removeNullstellen();
 	$h0-> removeNullstellen();
 	$h1-> removeNullstellen();
 	
 #	$gnuplot1 -> gnuplot_cmd ( "set terminal png", "set output \"afterNullstellenRemoval.png\" ","set tile 'NullstellenRemoved'");
 #	$gnuplot1 -> gnuplot_plot_xy( $h0->getOrderedXvalues(), $h0->getOrderedYvalues(), $h1->getOrderedYvalues() );
 
 	$h0-> printHistogram2file ( "UMS_H0_afterNullstellenRemoval.txt" );
 	$h1-> printHistogram2file ( "UMS_H1_afterNullstellenRemoval.txt" );	
 	
 	
 	$ht->ScaleSumToOne();
 	$h0->ScaleSumToOne();
 	$h1->ScaleSumToOne();
 
 	$h0-> printHistogram2file ( "UMS_H0_afterScaleSumToOne.txt" );
 	$h1-> printHistogram2file ( "UMS_H1_afterScaleSumToOne.txt" );	
 	
 #	$gnuplot1 -> gnuplot_cmd ( "set terminal png","set output \"afterScaleSumToOne.png\" ","set title 'ScaleSum2One'");
 #	$gnuplot1 -> gnuplot_plot_xy( $h0->getOrderedXvalues(), $h0->getOrderedYvalues(), $h1->getOrderedYvalues() );
 	
 	#root::print_hashEntries ($ht,4,"the Ht histogram\n");
 	#root::print_hashEntries ($h0,4,"the H0 histogram\n");
 	#root::print_hashEntries ($h1,4,"the H1 histogram\n");
 	
 	
 	return ($ht, $h0, $h1);
 }
 
 sub antiNumeric {
 	return $b <=> $a;
 }
 
 sub UMS {
 	my ( $self, $dataFileHandle, $antibody, $celltype ) = @_;
 	## Prizip:
 	## 2 unterschiedliche Gruppen bilden
 	## Gruppe 0: negative Kontroll Gruppe
 	## ( DMP1 & Collagen3_alpha4 )
 	## Gruppe 1: positive Kontroll Gruppe
 	## ( VpreB 1 / 2 , Pax5, Rag1/2 )
 	## Problem: Gruppe 2 hat 1623 Oligos mehr als Gruppe 1
 	## Lösung:  die ersten 1623 Oligos vom Pax% Locus abschneiden ( Pax5 fängt erst bei bp 47430 an)
 
 	my (
 		$ht, $h0, $h1, @h0_values, @h1_values, $f1, $hash, @InternalInfosHt, $PHI0, @ht_values, $fileInfo, $temp_h1, $temp_h0
 	);
 	
 	print "getDistributions\n";
 	( $ht, $h0, $h1 ) =
 	  $self->UMS_getDistributions( $dataFileHandle );
 	
 	$fileInfo = "$antibody-$celltype";
 	$fileInfo = join( "_", split( " ", $fileInfo ) );
 	
 	## save histograms as txt files
 	$ht->printHistogram2file("$self->{data_path}/Ht.$fileInfo.dat");
 	$h0->printHistogram2file("$self->{data_path}/H0.$fileInfo.dat");
 	$h1->printHistogram2file("$self->{data_path}/H1.$fileInfo.dat");
 	print "Histograms saved to path $self->{data_path}\n";
 
 
 	my $r = $self->calculateR ($ht, $h0, $h1, $fileInfo);
 
 	print "claculate f(1)\n";
 	@h0_values = $h0->getOrderedYvalues();
 	@h1_values = $h1->getOrderedYvalues();
 	@InternalInfosHt = $ht->getOrderedXvalues();
 	@ht_values = $ht->getOrderedYvalues();
 	
 	$PHI0 = $self->Match_f1_and_h0_to_ht( \@h1_values, \@h0_values, \@ht_values);
 	
 	## Print f1.dat
 #	$f1 = new_histogram->new();
 #	$f1->Category_steps($self->{category_steps});
 #	$f1->Max($ht->Max);
 #	$f1->Min($ht->Min);
 #	$f1->{data} = $hash;
 	
 	open( ERR, ">$self->{data_path}/ERR.txt" );
 
 	print "possible errors are written to $self->{data_path}/ERR.txt\n";
 	print "Removing F0 influence from F1\n";
 
 	for ( my $iterator = 0 ;$iterator < @h0_values; $iterator ++ ) {
 		$temp_h1 = $InternalInfosHt[$iterator];
 		print ERR "$InternalInfosHt[$iterator]\t$h1_values[$iterator]\t$h0_values[$iterator]\t$r\t";
 		$h1->{data}->{$temp_h1} = ( $h1_values[$iterator] - $r * $h0_values[$iterator] ) / ( 1 - $r );
 		print ERR "$f1->{data}->{$InternalInfosHt[$iterator]}\n";
 	}
 	close ERR;
 	$h1->ScaleSumToOne();
 	@h1_values = $h1->getOrderedYvalues();
 
 	print "Match complete\n";
 
 #	open( Prob, ">$self->{data_path}/ProbabilityDistr.txt" )
 #	  or die "konnte file ProbabilityDistr.txt nicht anlegen\n";
 
 	for( my $i = 0; $i < @ht_values; $i++) {
 		$temp_h1 = $h1_values[$i];
 		$temp_h0 = $h0_values[$i];
 		$h1_values[$i] = $h1_values[$i] / ( $h1_values[$i] + $temp_h0 );
 		$h0_values[$i] = $h0_values[$i] / ( $temp_h1 + $h0_values[$i] );
 	}
 	
 #	close(Prob);
 
 	#    $PHI0 = int ( $PHI0 * 100) / 100;
 	$h0-> ScaleSumToOne();
 	$h1-> ScaleSumToOne();
 	
 	$h1->printHistogram2file("UMS._final_F1.txt");
 	$h0->printHistogram2file("UMS._final_F0.txt");
 	
 	$self->{newGFFtoSignalMap} = undef;
 	$self->{arrayData}         = undef;
 	
 	print "which PHI0 do we have? -> $PHI0\n";
 	
 	return $h0, $h1, $PHI0;
 }
 
 sub Match_f1_and_h0_to_ht {
 
 	my ( $self, $f1, $h0, $ht ) = @_;
 
 	my ( $PHI0, $bestFit, $delta, $save, $min );
 	## finding $PHI0 by fitting h(t) to $PHI0 * $ho->{t} + ( 1- $PHI0) * f1->{t}
 	## get h(t)
 	open( MATCH, ">$self->{data_path}/match.txt" )
 	  or die "konnte File Match.txt nicht erstellen!\n";
 
 	$min = 1e30;
 
 	print "Match_f1_and_h0_to_ht\n";
 
 	for ( $PHI0 = 0.001 ; $PHI0 <= 1 ; $PHI0 += 0.001 ) {
 
 		$delta = 0;
 		for ( my $i = 0; $i < @$ht; $i ++ ) {
 
 			$delta +=
 			  ( ( @$ht[$i]) -
 				  ( $PHI0 * @$h0[$i] + ( 1 - $PHI0 ) * @$f1[$i] ) )**2;
 		}
 
 		#        print "The delta for \$PHI0 $PHI0 = $delta\n";
 		$save->{$PHI0} = $delta;
 		$min = $delta if ( $delta < $min );
 		print MATCH "$PHI0\t$delta\n";
 		print "DEBUG $self->Match_f1_and_h0_to_ht phi0 = $PHI0 and delta = $delta\n";
 	}
 
 	print "lowest delta Value = $min\n";
 
 	foreach $PHI0 ( keys %$save ) {
 		
 		if ( $min == $save->{$PHI0} ) {
 			print "best PHI0 = $PHI0 (value = $min)\n";
 			return  $PHI0;
 		}
 
 	}
 }
 
 sub numeric {
 	return $a <=> $b;
 }
 
 
 sub calculateR {
 	my ($self, $ht, $h0, $h1, $fileInfo) = @_;
 
 	my ($min, $r, $max, $temp, $i, @h0_values, @h1_values, @ht_values);
 	
 	@h0_values = $h0->getOrderedYvalues();
 	@h1_values = $h1->getOrderedYvalues();
 	@ht_values = $ht->getOrderedYvalues();
 	
 	$min = 10;
 
 	## Calculate r ,lim t -> t0 => g1(t) / g0(t) -> r
 	$r   = 1000000000000;
 	$max = 0;
 
 	open( Sum, ">$self->{data_path}/r_calculation_$fileInfo.csv" )
 	  or die
 	  "Konnte Datei $self->{data_path}/r_calculation.csv nicht anlegen!\n";
 
 	for ( my $iterator = 0; $iterator < @ht_values; $iterator ++){
 
 		$temp = $h1_values[$iterator] / $h0_values[$iterator];
 
 		$i = $h0_values[$iterator] / $h1_values[$iterator];
 
 		if ( $max < $i ) {
 			$r = $temp if ( $temp != 0 );
 			$max = $i;
 		}
 		print Sum "$i\t$temp\n";
 	}
 	close(Sum);
 
 	print "r = $r\n";
 	return $r;
 }
 
 
 1;
