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

=head1 batch_import_2_Nimblegene_array_dataset.pl

a script, that reads an input table structure and recovers the INPUT, IP and GFF values from a list of possible datat directories.

To get further help use 'batch_import_2_Nimblegene_array_dataset.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::array_analysis::tableHandling;
use strict;
use warnings;

my (
	$help,                        $debug,
	$database,                    @GFF_dirs,
	@Pair_dirs,                   $tableFile,
	$IP_dye,                      $INPUT_dye,
	$script,                      $array_dataset_scientist_id,
	$scientistTable_name,         $scientistTable_workgroup,
	$scientistTable_position,     $array_dataset_sample_id,
	$sampleTable_sample_lable,    $sampleTable_subject_id,
	$sampleTable_tissue_id,       $array_dataset_access_right,
	$array_dataset_array_id,      $nucleotide_array_identifier,
	$array_dataset_experiment_id, $experiment_name,
	$array_dataset_array_type,
);

Getopt::Long::GetOptions(
	"-help"                          => \$help,
	"-debug"                         => \$debug,
	"-script=s"                      => \$script,
	"-database=s"                    => \$database,
	"-table_file=s"                  => \$tableFile,
	"-Pair_directories=s{,}"         => \@Pair_dirs,
	"-GFF_directories=s{,}"          => \@GFF_dirs,
	"-IP_dye=s"                      => \$IP_dye,
	"-INPUT_dye=s"                   => \$INPUT_dye,
	"-array_dataset_scientist_id=s"  => \$array_dataset_scientist_id,
	"-scientistTable_name=s"         => \$scientistTable_name,
	"-scientistTable_workgroup=s"    => \$scientistTable_workgroup,
	"-scientistTable_position=s"     => \$scientistTable_position,
	"-sampleTable_tissue_id=s"       => \$sampleTable_tissue_id,
	"-array_dataset_access_right=s"  => \$array_dataset_access_right,
	"-array_dataset_array_id=s"      => \$array_dataset_array_id,
	"-nucleotide_array_identifier=s" => \$nucleotide_array_identifier,
	"-array_dataset_experiment_id=s" => \$array_dataset_experiment_id,
	"-experiment_name=s"             => \$experiment_name,
	"-array_dataset_array_type=s"    => \$array_dataset_array_type
);

my $dataset = {
	'array_dataset_scientist_id' => $array_dataset_scientist_id,

	'array_dataset_scientist_id' => $array_dataset_scientist_id,

	#'scientistTable_name'     => $scientistTable_name,
	#'scientistTable_workgroup' => $scientistTable_workgroup,
	#'scientistTable_position'  => $scientistTable_position,

	'sampleTable_tissue_id' => $sampleTable_tissue_id,

	'array_dataset_access_right' => $array_dataset_access_right,
	'array_dataset_array_id'     => $array_dataset_array_id,

	#'nucleotide_array_identifier' => $nucleotide_array_identifier,
	'array_dataset_experiment_id' => $array_dataset_experiment_id,

	#'experiment_name' => $experiment_name,
	'array_dataset_array_type' => $array_dataset_array_type,
};

if ($help) {
	print helpString();
	exit;
}

my ( $error, $var_str ) = &check_dataset($dataset);

unless ( defined $script ) {
	$script = 'AddNimbleGene_Chip_on_chip_values.pl';
}
unless ( -f $tableFile ) {
	$error .= "we need the -table_file to be a file not '$tableFile'\n";
}
unless ( -d $Pair_dirs[0] ) {
	$error .= "we need at least one -Pair_directories\n";
}
unless ( -d $GFF_dirs[0] ) {
	$error .=
"we have no GFF directories - therefore we have to calculate the GFF values. But that is buggy at the moment!\n";
}

if ( $error =~ m/\w/ ) {
	warn &helpString($error);
	exit;
}

my $description =
    "batch_import_2_NimbleGene_array_dataset -table_file $tableFile "
  . "-Pair_directories "
  . join( ", ", @Pair_dirs )
  . " -GFF_directories "
  . join( ", ", @GFF_dirs )
  . " -INPUT_dye $INPUT_dye -IP_dye $IP_dye";

unless ( defined $IP_dye ) {
	$IP_dye = 635;
}
elsif ( $IP_dye eq "Cy5" ) {
	$IP_dye = 635;
}
elsif ( $IP_dye eq "Cy3" ) {
	$IP_dye = 532;
}
else {
	print helpString("The IP_dye can only be Cy3 or Cy5 not $IP_dye");
	exit;
}
unless ( defined $INPUT_dye ) {
	$INPUT_dye = 532;
}
elsif ( $INPUT_dye eq "Cy5" ) {
	$INPUT_dye = 635;
}
elsif ( $INPUT_dye eq "Cy3" ) {
	$INPUT_dye = 532;
}
else {
	print helpString("The INPUT_dye can only be Cy3 or Cy5 not $INPUT_dye");
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for batch_import_2_Nimblegene_array_dataset.pl
 
  NEEDED values:
 -array_dataset_access_right
       a access right (scientis, group, all)
 -array_dataset_array_type
       the same as in nucleotide_array_libs.array_type
       
 LINKAGE variables:
 -array_dataset_scientist_id
       a link to the scientists table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -scientistTable_name
          the name of the scientif (you)
    -scientistTable_workgroup
          the name of your group leader
    -scientistTable_position
          your position (PhD student, postdoc, .. )

 -sampleTable_tissue_id
       the link to the tissues table
 -array_dataset_array_id
       a link to the nucleotides array
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -nucleotide_array_identifier
          a identifier for this particular array design
 -array_dataset_experiment_id
       a link to the experiment table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -experiment_name
          The name for the experiment. This name has to be uniwue over all the emperiments.
          
 
 
   -table_file        :a tab separated table file that contains the named columns
                       subject id, sample lable and NimbleGen_ID
   -script            :the location of the AddNimbleGene_Chip_on_chip_values.pl script
   -IP_directories    :a list of directories containing the pair IP files
   -INPUT_directories :a list of directories containing the pair INPUT files
   -GFF_directories   :a list of directories containing the GFF files
   -INPUT_dye         :the dye used to colorize the INPUT material (Cy5 or Cy3) default Cy3
   -IP_dye            :the dye used to colorize the IP material (Cy5 or Cy3) deualt Cy5
   -help              :print this help
   -debug             :verbose output

";
}

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad, $loggingEntries );

my ( @line, $header, $nimbleGeneFiles, $cmd );
$nimbleGeneFiles = &red_directories( \@Pair_dirs, \@GFF_dirs );
## and now - do some work!
open( TABLE, "<$tableFile" ) or die "could not open '$tableFile'\n$!\n";
while (<TABLE>) {
	next if ( $_ =~ m/^#/ );
	chomp($_);
	@line = split( "\t", $_ );
	unless ( defined $header ) {
		$header = {};
		for ( my $i = 0 ; $i < @line ; $i++ ) {
			if ( $line[$i] eq "subject id" ) {
				$header->{"subject id"} = $i;
			}
			elsif ( $line[$i] eq "sample lable" ) {
				$header->{"sample lable"} = $i;
			}
			elsif ( $line[$i] eq "NimbleGen_ID" ) {
				$header->{"NimbleGen_ID"} = $i;
			}
			else {
				warn "we do not use the data in the column '$line[$i]'\n";
			}
		}
		unless ( scalar( keys %$header ) == 3 ) {
			die
"we need the column titles 'subject id', 'sample lable' and 'NimbleGen_ID' in the table file!\n";
		}
		next;
	}
	$cmd = "$script ";
	foreach my $key (%$dataset) {
		$cmd .= "-$key $dataset->{$key} "
		  if ( defined $dataset->{$key} && $dataset->{$key} =~ m/[\w\d]+/ );
	}
	
	$cmd .= " -sampleTable_sample_lable "
	  . $line[ $header->{"sample lable"} ]
	  . " -sampleTable_subject_id  "
	  . $line[ $header->{"subject id"} ];
	if ( defined $nimbleGeneFiles->{ $line[ $header->{"NimbleGen_ID"} ] } ) {
		$cmd .= " -data_IP "
		  . $nimbleGeneFiles->{ $line[ $header->{"NimbleGen_ID"} ] }->{'IP'}
		  . " -data_INPUT "
		  . $nimbleGeneFiles->{ $line[ $header->{"NimbleGen_ID"} ] }->{'INPUT'}
		  . " -data_GFF "
		  . $nimbleGeneFiles->{ $line[ $header->{"NimbleGen_ID"} ] }->{'GFF'}
		  . "\n";
		  print $cmd;
	}
	else { print " wont work - no data\n"; }

}

sub red_directories {
	my ( $INPUT, $GFF ) = @_;
	my ( $dir, $data, $file, $n_id, $nm );
	$data = {};
	foreach $dir (@$INPUT) {
		next unless ( -d $dir );
		opendir( DIR, "$dir" ) or die "could not access the dir $dir\n$!\n";
		foreach my $file ( readdir(DIR) ) {
			unless ( $file =~ m/(\d+)_(\d+).pair/ ) {
				warn "not a nimblegene_Data_file :$file\n";
				next;
			}
			else {
				( $n_id, $nm ) = ( $1, $2 );
				$data->{$n_id} = {} unless ( ref ($data->{$n_id} ) eq "HASH" );
				if ( $nm == $IP_dye ) {
					$data->{$n_id}->{'IP'} = "$dir/$file";
				}
				elsif ( $nm == $INPUT_dye ) {
					$data->{$n_id}->{'INPUT'} = "$dir/$file";
				}
			}
		}
		closedir(DIR);
	}

	## AND now the GFF dir
	foreach $dir (@$GFF) {
		next unless ( -d $dir );
		opendir( DIR, "$dir" ) or die "could not access the dir $dir\n$!\n";
		foreach my $file ( readdir(DIR) ) {
			unless ( $file =~ m/(\d+)_ratio.gff/ ) {
				warn "not a nimblegene_Data_file :$file\n";
				next;
			}
			else {
				( $n_id ) = ( $1 );
				#$data->{$n_id} = {} unless ( ref( $data->{$n_id} ) eq "HASH" );
				$data->{$n_id}->{'GFF'} = "$dir/$file";
			}
		}
		closedir(DIR);
	}
	## we need to make the check
	my $error = '';
	foreach my $nimbleID ( keys %$data ){
		foreach my $key ( 'IP', "INPUT", "GFF"){
			$error .= " we miss the data file for nimbleGene id $nimbleID and filetype $key\n"
			unless ( defined $data->{$nimbleID} ->{$key});
		}
		
	}
	die "we have an error during the directory parse function\n".$error."\n" if ( $error =~ m/\w/);
	return $data;
}

sub check_dataset {
	my ( $dataset, $variable_name ) = @_;
	my $error   = '';
	my $dataStr = '';
	my ( $temp, $temp_data );
	foreach my $value_tag ( keys %$dataset ) {
		next if ( $value_tag eq "id" );
		$dataStr .= "-$value_tag => $dataset->{$value_tag}, "
		  if ( defined $dataset->{$value_tag}
			&& !( ref( $dataset->{$value_tag} ) eq "HASH" ) );

		#next if ( ref( $dataset->{$value_tag} ) eq "HASH" );
		unless ( defined $dataset->{$value_tag} ) {
			$temp = $value_tag;
			$temp =~ s/_id//;
			if ( ref( $dataset->{$temp} ) eq "HASH" ) {
				( $temp, $temp_data ) = check_dataset( $dataset->{$temp} );
				$dataStr .= $temp_data;
				$error .=
"we miss the data for value $value_tag and the downstream table:\n"
				  . $temp
				  if ( $temp =~ m/\w/ );
			}
			else {
				$error .= "we miss the data for value -$value_tag\n";
			}
		}
	}

	return ( $error, $dataStr );
}
