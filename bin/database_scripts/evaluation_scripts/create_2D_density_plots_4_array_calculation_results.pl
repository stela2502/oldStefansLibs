#! /usr/bin/perl -w

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

=head1 create_2D_density_plots_4_array_datasets.pl

A tool, that can create a list of 2D densitiy plot based on array datasets using the stefans_libs::plot::densityPlot class. At the moment, this script can only use datasets downstream of array_calulation_results.

To get further help use 'create_2D_density_plots_4_array_datasets.pl -help' at the comman line.

=cut

use Getopt::Long;

use stefans_libs::database::array_calculation_results;
use stefans_libs::plot::densityMap;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @IDs, $path);

Getopt::Long::GetOptions(
	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 "-database=s"       => \$database,
	 "-array_calculation_result_IDs=s{,}" => \@IDs,
	 "-outpath=s" => \$path
);

if ( $help ){
	print helpString( ) ;
	exit;
}
unless ( defined $path){
	print helpString( "we need to know where to write the pictures to ('outpath')") ;
	exit;
}
unless ( defined $IDs[1] ){
	print helpString( "we need at least two array_calculation_result_IDs in order to compare anything") ;
	exit;
}
unless ( -d $path){
	mkdir ( $path );
}


sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for create_2D_density_plots_4_array_datasets.pl
 
   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   -array_calculation_result_IDs
                   :the IDs from the 'array_calculation_results' table (min two)
   -outpath        :the outpath to store the data in

"; 
}

## now we set up the logging functions....

my ( $task_description );


## and add a working entry

$task_description = "";


	my ( $array_calculation_results, $database_interface, $tableDescriptions, $rv, $sth, $sql );
	
	## get the search interface
	$array_calculation_results = array_calculation_results->new($database, $debug);
	($database_interface, $tableDescriptions) = $array_calculation_results->GetSearchInterface ( \@IDs );
	
	## create the SQL statement
	$sql = $database_interface -> create_SQL_statement ( {'search_columns' => [ 'oligo_name', 'oligo_array_values.value' ] });
	print "we will execute '$sql;'\n" if ( $debug);
	
	## get the data
	unless ( $sth = $database_interface->{'dbh'}->prepare ( $sql ) ){
		die "the search '$sql;' raised an mysql error:\n".$database_interface->{'dbh'}->errstr();
	};
	$rv = $sth->execute();
	print "we got $rv datasets\n" if ( $debug );
	$rv = $sth->fetchall_arrayref();
	
	my $transposed_matrix = transposeMatrix ( $rv );
	$rv = shift ( @$transposed_matrix) ; ## get rid of the oligoIDs
	## create the plots
	&createPictures ($tableDescriptions, @$transposed_matrix );

## work is finfished - we add a log entry and remove the workload entry!



sub createPictures{
 	my ( $namesArray, $array1, @arrays2compare ) = @_;
 	my ( $temp, $value, $compareArray );
 	for ( my $i = 0; $i < @arrays2compare; $i++ ) {
 		$compareArray = $arrays2compare[$i];
 		my $xyWith_Histo = densityMap->new();
 		$xyWith_Histo -> AddData( [$array1, $compareArray] );
 		$xyWith_Histo->plot( "$path/secondLevelComparison-@$namesArray[0]->{'name'}"."_@$namesArray[1+$i]->{'name'}.svg" ,800 , 800 , @$namesArray[0]->{'name'} , @$namesArray[1+$i]->{'name'} );
 	}
 	shift ( @$namesArray);
 	return createPictures($namesArray, @arrays2compare) if ( @arrays2compare > 1 );
}

sub transposeMatrix{
 	my (  $matrix) =@_;
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
