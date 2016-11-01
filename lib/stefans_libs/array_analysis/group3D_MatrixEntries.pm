package group3D_MatrixEntries;

use stefans_libs::histogram_container;
use strict;

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

my $cutoff = 2;

sub new {

	my ( $class, $path, $ID ) = @_;

	my ( $self, @groups, @sortingValues );
	warn
"group3D_MatrixEntries can not report the internal state unless new obtains a ID and a path to report to!\n"
	  if ( !( defined $ID && defined $path ) );

	my @array =

#qw( a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
	  (
		'Cl  ', ' O  ', ' S  ', ' N  ', ' C  ', ' P  ', ' K  ', 'Ac  ',
		'Al  ', 'Am  ', 'Sb  ', 'Ar  ', 'As  ', 'At  ', 'Ba  ', 'Bk  ',
		'Be  ', 'Bi  ', 'Pb  ', 'Bh  ', 'Br  ', 'Cd  ', 'Cs  ', 'Ca  ',
		' B  ', 'Cf  ', 'Ce  ', 'Cr  ', 'Co  ', 'Cm  ', 'Ds  ', 'Db  ',
		'Dy  ', 'Fe  ', 'Es  ', 'Er  ', 'Eu  ', 'Fm  ', ' F  ', 'Fr  ',
		'Gd  ', 'Ga  ', 'Ge  ', 'Au  ', 'Hf  ', 'Hs  ', 'He  ', 'Ho  ',
		'In  ', ' I  ', 'Ir  ', 'Kr  ', 'Cu  ', 'La  ', 'Lr  ', 'Li  ',
		'Lu  ', 'Mg  ', 'Mn  ', 'Mt  ', 'Md  ', 'Mo  ', 'Na  ', 'Nd  ',
		'Ne  ', 'Np  ', 'Ni  ', 'Nb  ', 'No  ', 'Os  ', 'Pd  ', 'Pt  ',
		'Pu  ', 'Po  ', 'Pr  ', 'Pm  ', 'Pa  ', 'Hg  ', 'Ra  ', 'Rn  ',
		'Re  ', 'Rh  ', 'Rg  ', 'Rb  ', 'Ru  ', 'Rf  ', 'Sm  ', 'Sc  ',
		'Sg  ', 'Se  ', 'Ag  ', 'Si  ', 'Sr  ', 'Ta  ', 'Tc  ', 'Te  ',
		'Tb  ', 'Tl  ', 'Th  ', 'Tm  ', 'Ti  ', ' U  ', ' V  ', ' H  ',
		' W  ', 'Xe  ', 'Yb  ', ' Y  ', 'Zn  ', 'Sn  ', 'Zr  ',
	  );

	my @AS_code =
	  qw(Ala  Arg  Asn  Asp  Cys  Gln  Glu  Gly  His  Ile  Leu  Lys  Met  Phe  Pro  Ser  Thr  Trp  Tyr  Val
	);

	@sortingValues = ();
	my @ad =();
	
	$self = {
		groups        => \@groups,
		sortingValues => \@sortingValues,
		labels        => \@array,
		AS            => \@AS_code,
		'fileBase'    => $ID,
		'outPath'     => $path,
		debug  => 1==1,
		all_differences => \@ad
	};
	bless $self, $class if ( $class eq "group3D_MatrixEntries" );

	return $self;

}

sub getAS4columnID {
	my ( $self, $tag ) = @_;
	warn "you should first use \n",
	  "$self -> createExternalData2AS_table (<ref to the value array>) \n",
	  "to initialize this function\n"
	  unless ( defined $self->{externals2sort} );
	return $self->{sort2as}->{ $self->{externals2sort}->{$tag} };
}

sub getAS4sortCriteria {
	my ( $self, $tag ) = @_;
	warn "you should first use \n",
	  "$self -> createExternalData2AS_table (<ref to the value array>) \n",
	  "to initialize this function\n"
	  unless ( defined $self->{externals2sort} );
	return $self->{sort2as}->{$tag};
}

sub createExternalData2AS_table {
	my ( $self, $externalMatrix ) = @_;
	my ( $hash, @internalArray );

	## $externalMatrix is a ref to a array of arrays where the internal array = (<columnID>, <sortCriteria>)

	foreach my $entry (@$externalMatrix) {
		$hash->{ @$externalMatrix[0] } = @$externalMatrix[1];
	}

	@internalArray = ( sort values %$hash );
	warn
	  "some things will not be marked as more than 20 elements are available!"
	  if ( @internalArray > 19 );
	my $newHash;
	for ( my $i = 1 ; $i < @internalArray ; $i++ ) {
		$newHash->{ $internalArray[$i] } = $self->{AS}[$i];
	}
	$self->{externals2sort} = $hash;
	$self->{sort2as}        = $newHash;
	return 1;
}

sub print {
	my ($self) = @_;
	print "groups in the object $self:\n";
	my ( $ref, $group );
	$ref = $self->{groups};
	for ( my $i = 0 ; $i < @$ref ; $i++ ) {
		$group = @$ref[$i];
		print "group $i: ( \n\t", join( "\n\t", @$group ), " )\n";
	}
	$ref = $self->{sortingValues};
	for ( my $i = 0 ; $i < @$ref ; $i++ ) {
		$group = @$ref[$i];
		print "sortingValues $i: ( \n\t", join( "\n\t", @$group ), " )\n";
	}
	return 1;
}

sub getAS_code_4ID {
	my ( $self, $id ) = @_;
	return $self->{AS_code}[$id];
}

sub getGroupID {
	my ( $self, $tag ) = @_;

	my ( $labels, $position, $rest, $times, @groupID, $label );

	$labels   = $self->{labels};
	$position = $self->inWhichGroupIs($tag);

	print "groupPosition $position for tag $tag has the lable @$labels[$position]\n";
	## the position has to be recoded to a value in the range of aaa to xxx
	die "value $position is out of range a - X \n"
	  if ( $position > @$labels - 1 );

	return @$labels[$position];

}

sub CutOff {
	my ( $self, $value ) = @_;
	$self->{'__cut_off__'} = $value if ( defined $value );
	return $self->{'__cut_off__'};
}

sub createGroups {
	my ( $self, $matrix ) = @_;

	my ( @differences, $refPoint, @histoData, $groupA, $groupB, $array );

	for ( my $i = 0 ; $i < @$matrix  ; $i++ ) {
		$refPoint = @$matrix[$i];
		$groupA = $groupB = undef;

		if ( defined @$refPoint[0] ) {

			@differences = $self->getClosestNeighbours( $refPoint, $matrix );
		}
	}
	
	$array = $self->{all_differences};
	@$array = ( sort {$a <=> $b} @$array);
	$cutoff = $self->CutOff ();
	$cutoff = @$array[ int( (@$array - 1) / 30 ) ] unless ( defined $cutoff);
	
	warn "we have a new cutoff $cutoff\n";
	
	for ( my $i = 0 ; $i < @$matrix  ; $i++ ) {
		$refPoint = @$matrix[$i];
		$groupA = $groupB = undef;

		if ( defined @$refPoint[0] ) {

			@differences = $self->getClosestNeighbours( $refPoint, $matrix );
			$groupA = undef;

			foreach my $diff (@differences) {
				next if ( $diff->{point_label} eq @$refPoint[0] );
				if (   $diff->{difference} < $cutoff
					&& $diff->{difference} > 0 )
				{
					$groupA = 1;
					$self->createLink(
						@$refPoint[0],
						$diff->{'point_label'},
						$diff->{difference}
					);
				}
				else {
					last;
				}
			}
			if ( !defined $groupA ) {
				$self->notInAGroup( @$refPoint[0] );
			}

		}
	}

	#$self->orderByOccupation();
	$self->make_a_notInAGroup_group();
	#print "we are almost finished\n";
	print "We have a problem in group3D_MatrixEntries:\n",
		"several entries are part of the 'not in a group' group, but are shown in another group in the pdb file!\n"  if ( $self->{debug});
	$self->print()  if ( $self->{debug});
	return undef;
}

sub orderByOccupation {
	my ($self) = @_;
	my $ref = $self->{groups};
	
	@$ref = ( sort { @$b <=> @$a } @$ref );
	return 1;
}

sub make_a_notInAGroup_group {
	my ($self) = @_;
	my ( $ref, @notInAGroup_entries, $group, $singlets, $sortingValues, $temp );

	$ref           = $self->{groups};
	$sortingValues = $self->{sortingValues};
	$singlets = 0;

	#print "We remove the #1 groups\n";

	for ( my $i = @$ref - 1 ; $i > -1 ; $i-- ) {
		$group = @$ref[$i];
		$temp  = @$sortingValues[$i];
		if ( @$group == 1 ) {

			#print
#"we remove a group (@$group) with the associated variances ( @$temp )!\n\tusing splice( \@$ref, $i, 1 )\n";
			push( @notInAGroup_entries, @$group );
			@$group = ();
			$temp = splice( @$ref, $i, 1 );    ## remove the entry
			#print "\tand we removed the singlet @$temp\n";
			## we also have to remove the empty arrays from the $self->{sortingValues} ref
			$temp = splice( @$sortingValues, $i, 1 );
			#print "\tthe variances @$temp were also removed\n";
			$singlets++;
		}
		else {
			$temp = @$sortingValues[$i];
			#print
			#  "group $i contained more than one value (@$group and @$temp)\n";
		}
	}
	$self->{amountOf_goodGroups} = @$ref;

	if ( $singlets > 0 ) {
		$self->{not_grouped_entries} = 1 == 1;
		$singlets                  = $self->newGroup();
		$self->{labels}[$singlets] = "aa  ";
		$group                     = @$ref[$singlets];

 #print "We create a new group at position $singlets\n(@notInAGroup_entries)\n";
		push( @$group, @notInAGroup_entries );
	}
	return 1;
}

sub join2groups {
	my ( $self, $groupA, $groupB, $difference ) = @_;

	my $ref     = $self->{groups};
	my $a_array = @$ref[$groupA];

	print "we join group $groupA and group $groupB deleing groupB\n" if ( $self->{debug});
	## 1. delete the groupB from the list, shifting all other groups down one.
	## that is done by the splice command:
	## splice(<theArray>,<position in the array>,<amount of deleted values>,<inserted strings>)
	my $b_array = splice( @$ref, $groupB, 1 );
	## 2. Add entries of groupB to groupA
	push( @$a_array, @$b_array );
	## 3. delete enrties from ArrayB
	@$b_array = undef;

	## do the same for the sortingValues!!!!
	my ( $ref2, $a2, $b2 );
	$ref2 = $self->{sortingValues};
	$a2   = @$ref2[$groupA];
	$b2   = splice( @$ref2, $groupB, 1 );
	push( @$a2, @$b2 );
	@$b2 = undef;
	#print
#"\tupon the joining of two groups, group $groupA and (deleted) group $groupB (@$a_array)\n\twe add the difference $difference to group @$a2\n";
	push( @$a2, $difference );

	return 1;
}

sub notInAGroup {
	my ( $self, $tag ) = @_;
	my $test = $self->inWhichGroupIs($tag);
	return $test if ( defined $test);
	print "Not in a group got tag $tag\n"  if ( $self->{debug});
	return $self->addValueToGroup( $self->newGroup(), $tag );
}

sub addValueToGroup {
	my ( $self, $groupID, $value, $difference ) = @_;
	my $ref = $self->{groups}[$groupID];
	push( @$ref, $value );
	print "we add $value to group $groupID (@$ref)\n"  if ( $self->{debug});
	return 1 unless ( defined $difference );
	#print "we try to add the variance $difference to group $groupID\n";
	$ref = $self->{sortingValues}[$groupID];
	push( @$ref, $difference );
	return 1;
}

sub newGroup {
	my ($self) = @_;
	my ( @temp, $ref );
	$ref = $self->{groups};
	push( @$ref, \@temp );
	my @temp2;
	$ref = $self->{sortingValues};
	push( @$ref, \@temp2 );
	return @$ref - 1;
}

sub inWhichGroupIs {
	my ( $self, $value ) = @_;

	my $ref = $self->{groups};

	#print "DEBUG inWhichGroupIs ($value)\n";
	for ( my $i = 0 ; $i < @$ref ; $i++ ) {

		#print "\tIn group ";
		return $i if ( $self->isInArray( $value, @$ref[$i] ) );
	}
	return undef;
}

## get the name of a html formated file that contains a overview over the grouping ( includung the hitogram picture)
sub printReport2HTMLfile{
	my ( $self ) = @_;
	
	my ( $temp, $path, $baseName );

	$baseName = $self->{fileBase};
	$path     = $self->{outPath};

	open( OUT, ">$path/$baseName-grouping.html" )
	  or die
"could not create the log file '$path/$baseName-grouping.html' in $self getReportAsHTML\n";
	print OUT 
	"<head>
	<title>$baseName-grouping report</title>
	</head>
	<body>
	<table>\n";
	print OUT "\t\t<tr> <td> ", $self->histogramPic_as_HTML_Link(), 
	" </td> \n<td> " , $self->getGroupReportAsHTML_Table(), " </td> \n </tr>\n";
	
	print OUT "\t</table>\n</body>\n";
	close OUT;
	return "$path/$baseName-grouping.html";
	
}

sub histogramPic_as_HTML_Link{
	my ( $self, $x, $y) = @_;
	
	return $self->{pictureLink} if ( defined $self->{pictureLink});
	my ( $report, $temp, $path, $baseName, $histograms );

	$baseName = $self->{fileBase};
	$path     = $self->{outPath};
	
	$x = 300 unless ( defined $x);
	$y = 300 unless ( defined $y);

	( $report, $histograms ) = $self->getReport();

	$histograms->plot("$path/$baseName-grouping.histogram.svg");
	
	$self->{pictureLink} = "<p> <object data=\"$path/$baseName-grouping.histogram.svg\" type=\"image/svg+xml\" width=\"$x\" height=\"$y\">
    <param name=\"src\" value=\"$path/$baseName-grouping.histogram.svg\">
    Ihr Browser kann das Objekt leider nicht anzeigen!</object> </p>\n";
    return $self->{pictureLink};
}

sub transposeMatrix{
	my ( $self, $matrix) =@_;
	my ( @newMatrix, $oldLine);
	for ( my $new_column_count = 0; $new_column_count < @$matrix; $new_column_count++){
		$oldLine = @$matrix[$new_column_count];
		for (my $new_row_count = 0; $new_row_count < @$oldLine; $new_row_count ++){
			unless ( defined $newMatrix[$new_row_count]){
				my @temp = ();
				$newMatrix[$new_row_count] = \@temp;
			}
			$newMatrix[$new_row_count]->[$new_column_count] = @$oldLine[$new_row_count];
		}
	}
	return \@newMatrix;
}

sub getJmolHTMLTable4group {
	my ($self, $AdditionalInfo_gin ) = @_;

	my ( $report, $histograms, $return, $temp, $script );

	( $report, $histograms ) = $self->getReport();
	delete $report->{'amount of groups'};

	$return = "<table>\n";
	## make a matrix to plot
	my ( @matrix);

	foreach my $tag ( sort keys %$report ) {
		$temp   = $report->{$tag}->{'data'};
		$script = join(
			"",
			(
				"<script> jmolCheckbox(\"select *.",
				lc( $report->{$tag}->{pdb_id} ),
				"; spacefill 50% \", \"select *.",
				lc( $report->{$tag}->{pdb_id} ),
				" ; spacefill 20% \", '$tag'); </script>"
			)
		);
		my @temp = ($script, @$temp);
		push (@matrix, \@temp);
		#print "The script line: \n\t$script\n";
	}
	$temp = $self->transposeMatrix(\@matrix);
	@matrix = @$temp;
	foreach my $array ( @matrix ) {
		$return .= $self->_getAnHTML_tableLine4array(@$array, $AdditionalInfo_gin);
	}
	$return .= "</table>\n";
	print "The HTML table of the group entries\n $return\n";
	return $return;
}

sub _getAnHTML_tableLine4array {
	my ($self, @array) = @_;
	return "" if ( "@array" =~ m/^[ <>]*$/ );
	
	#the tags have to be changed to links if $AdditionalInfo_gin is defined!
	
	
	my $string = "<tr> <td>";
	$string .= join( " </td> <td> ", @array );
	$string .= " </td> >/tr>\n";
	print "new HTML table line: $string";
	return $string;
}

sub _group2HTML{
	my ( $self ) = @_;
	
	my ( $report, $histograms, $return, $temp);
	
	( $report, $histograms ) = $self->getReport();
	delete $report->{'amount of groups'};

	$return = $self-> _getAnHTML_tableLine4array('group ID', 'group tag (element)','group entries');
	foreach my $tag ( sort keys %$report ) {
		$temp = $report->{$tag}->{'data'};
		$return .= $self-> _getAnHTML_tableLine4array ("$tag","$report->{$tag}->{pdb_id}", @$temp);
	}
	return $return;
}

sub getGroupReportAsHTML_Table{
	my ( $self ) = @_;
	return "\t\t<table>\n". $self->_group2HTML. "\t\t</table>\n";
}

sub printReport2file {
	my ($self) = @_;
	my ( $report, $temp, $path, $baseName, $histograms );

	$baseName = $self->{fileBase};
	$path     = $self->{outPath};

	( $report, $histograms ) = $self->getReport();
	open( LOG, ">$path/$baseName-grouping.log" )
	  or die
"could not create the log file '$path/$baseName-grouping.log' in $self printReport2file\n";

	print LOG "amount of groups\t$report->{'amount of groups'}\n";
	delete $report->{'amount of groups'};
	print LOG
	  "group ID\tgroup label in the pdb file\tgroup values separated by ';'\n";
	print LOG
"histogram picture is written to '$path/$baseName-grouping.histogram.svg'\n";
	$histograms->plot("$path/$baseName-grouping.histogram.svg");

	foreach my $tag ( sort keys %$report ) {
		$temp = $report->{$tag}->{'data'};
		#print "we might have forgotten one ?$tag?\n";
		print LOG "$tag\t$report->{$tag}->{pdb_id}\t", join( ";", @$temp ),
		  "\n";
	}
	close(LOG);

	return "$path/$baseName-grouping.log", "$path/$baseName-grouping-histo.svg";
}

sub getReport {
	my ($self) = @_;
	## we have to report what is going on in the evaluation!
	## what is interesting?
	## 1. how many groups did we create by analyzing the 3D values of the matrix?
	##    we have to take care, that we only return the amount of real groups,
	##    not the amount not grouped values (!). Therefore the info has to be generated
	##    by the 'make_a_notInAGroup_group' function.
	## 2. which values are in the groups (if there are any groups)
	## 3. how reliable is the grouping (that will be hardest, as I have no idea of how to compute that)
	my ( $report, $ref, $labels );
	return $self->{report}, $self->{histo_container} if ( defined $self->{report} && defined $self->{histo_container});
	$report->{'amount of groups'} = $self->{amountOf_goodGroups};
	$labels                       = $self->{labels};
	$ref                          = $self->{groups};

	## care about the histo data set!
	my $overAll = $self->{all_differences};
	@$overAll = ( sort { $a <=> $b } @$overAll );
	
	my ( $min, $max ) = ( @$overAll[0], @$overAll[ @$overAll - 1 ] );
	$min = int($min);
	$max = int( $max + 0.9);
	my $spread = ( $max - $min ) / 10;    ## 10 splots for the data!
	warn "do we have a problem?? $min to $max in 10 steps -> spread = $spread\n";
	my $histo_container = histogram_container->new($spread);
	$histo_container->AddDataArray( "all entries", $overAll );

	if ( $self->{not_grouped_entries} ) {
		for ( my $i = 0 ; $i < @$ref - 1 ; $i++ ) {
			unless ( @$labels[$i] eq "aa"){
			$report->{"group $i"} = {
				data   => @$ref[$i],
				pdb_id => @$labels[$i],
				histo  => $self->{sortingValues}[$i]
			};
			$histo_container->AddDataArray( "@$labels[$i] (group $i)",
				$self->{sortingValues}[$i] );
			}
		}
		$report->{"not grouped"} =
		  { data => @$ref[ @$ref - 1 ], pdb_id => @$labels[ @$ref - 1 ] };
	}
	else {
		for ( my $i = 0 ; $i < @$ref ; $i++ ) {
			unless ( @$labels[$i] eq "aa"){
			$report->{"group $i entries"} = {
				data   => @$ref[$i],
				pdb_id => @$labels[$i],
				histo  => $self->{sortingValues}[$i]
			};
			$histo_container->AddDataArray( "@$labels[$i] (group $i)",
				$self->{sortingValues}[$i] );
			}
		}
		my @temp = ();
		$report->{"not grouped entries"} = { data => \@temp, pdb_id => " " };
	}
	$histo_container->scaleSum21();
	($self->{report}, $self->{histo_container}) =  ($report, $histo_container);
	return $self->{report}, $self->{histo_container} ;
}

sub getEntries4group {
	my ( $self, $groupID ) = @_;
	my $ref = $self->{groups}[$groupID];
	return @$ref;
}

sub isInArray {
	my ( $self, $value, $array ) = @_;

	#print "@$array ??\n";
	foreach my $entry (@$array) {
		return 1 == 1 if ( $entry eq $value );
	}
	return 1 == 0;
}

sub getClosestNeighbours {
	my ( $self, $point, $matrix ) = @_;

	my ( @differences, $all_differences, $ref );
	$all_differences = $self->{all_differences};
	
	for ( my $i = 0 ; $i < @$matrix ; $i++ ) {
		$ref = @$matrix[$i];
		push(
			@differences,
			{
				'point_label' => @$ref[0],
				'difference'  => $self->calculate3DVectorLength( $point, $ref )
			}
		);
		push ( @$all_differences, @differences[@differences-1]->{difference});
	}
	## the return Data structure: array of hashes the nearest, the second nearest, the third nearest point
	## the hash = { point_label => $@$matrix[$i][0], difference =>  $differences->{$i} }
	## therefore we have to sort the differences array by @$differences[][1]

	return ( sort { $a->{'difference'} <=> $b->{'difference'} } @differences );
}

sub calculate3DVectorLength {
	my ( $self, $arrayRef1, $arrayRef2 ) = @_;
	return (
		(
			( @$arrayRef1[1] - @$arrayRef2[1] )**2 +    #deltaX * deltaX
			  ( @$arrayRef1[2] - @$arrayRef2[2] )**2    #deltaY * deltaY
		) + ( @$arrayRef1[3] - @$arrayRef2[3] )**2      #deltaZ * deltaZ
	)**0.5;
}

sub createLink {
	my ( $self, $tagA, $tagB, $difference ) = @_;

	my ( $groupA, $groupB, $temp );
	$groupA = $self->inWhichGroupIs($tagA);
	if ( !defined $groupA ) {    ## we have to create a new group
		                         #print "DEBUG OPS!: a new group\n";
		$groupA = $self->newGroup;
		$self->addValueToGroup( $groupA, $tagA, undef );
	}

	$groupB = $self->inWhichGroupIs($tagB);

	if ( defined $groupB ) {     ## ups - we ceate a new connection!
		return 1 if ( $groupB == $groupA );
		if ( $groupA > $groupB){
			$temp = $groupA;
			$groupA = $groupB;
			$groupB = $temp;
		}
		$self->join2groups( $groupA, $groupB, $difference );
	}
	else {                       ## simply push in the new one!
		$self->addValueToGroup( $groupA, $tagB, $difference );
	}
	return 1;
}
1;
