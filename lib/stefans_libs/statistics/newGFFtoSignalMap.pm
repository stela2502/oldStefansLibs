package newGFFtoSignalMap;
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
use stefans_libs::database_old::array_TStat;
use stefans_libs::database::dataset::oligo_array_values;
use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use stefans_libs::database_old::fileDB;
use stefans_libs::root;

sub new {

    my ( $class, $exportPath ) = @_;

    my ( $self, @temp, $oligo2dnaDB, $fileDB, $root );

    $oligo2dnaDB = oligo2dnaDB->new();
    $fileDB = fileDB->new();
    $root = root->new();
    #print "newGFFtoSignalMap initialized with ( $class , $exportPath )\n";
    $self = {
        root => $root,
        fileDB => $fileDB,
        oligo2dnaDB => $oligo2dnaDB,
        data => \@temp,
        path => $exportPath,
        MaxOligoRep => 4
    };

    bless( $self, $class ) if ( $class eq "newGFFtoSignalMap" );
    return $self;
}


sub matchOligoValues2OligoLocation {

    my ( $self, $data, $designID) = @_;

    my ( $temp, $Oligos, $tempfiles, $files, $OligoID, $unmatchedOligos, @returnData );
    
    #print "DEBUG $self->matchOligoValues2OligoLocation got $data, $designID\n";
    
    ## Array ref for all the Oligo Localisation for Array Design $hash->{designID}
    $Oligos = $self->{oligo2dnaDB}->GetOligoLocationArray($designID);

    ## hash with the file Informations ordered by filename 
    $tempfiles = $self->{fileDB}->SelectFiles_ByDesignId($designID);
    foreach my $fileHash (values %$tempfiles){
       $temp = $self->{root}->getPureSequenceName($fileHash->{fileName});
       if ( $temp->{filename} =~ m/([\w\d-]+).gb/){
           $temp->{filename} = $1;
       }
       $files->{$fileHash->{ID}} = $temp->{filename};
    }

    ## Get Data Info

        foreach my $OligoInfo (@$Oligos ) {
         ##Oligo_ID, Oligo_start, Oligo_end, FileID, Sequence
            $OligoID = @$OligoInfo[0];
            next if ( @$OligoInfo[5] > $self->{MaxOligoRep});
            
            unless ( defined $data->{$OligoID} ) {
            	warn "$self Oligo '$OligoID' defined in the oligo2DNA database was not found in the oligo values\n";
                $unmatchedOligos ++;
                next;
            }

            push(
                @returnData,
                {
                    filename => $files->{ @$OligoInfo[3] },
                    identifier => $temp,
                    oligoID    => $OligoID,
                    value      => $data->{$OligoID},
                    start      => @$OligoInfo[1],
                    end        => @$OligoInfo[2],
                    sequence   => @$OligoInfo[4]
                }
            );
        }
        print "$unmatchedOligos Olgios waren nicht in den Array Daten enthalten!\n";
        $self->{data} = \@returnData;
#    }
    return \@returnData;
}

sub ExportData {
    my ( $self, $data, $path ) = @_;

    my ( $hash, @temp, $temp );


    foreach $hash (@$data) {

        unless ( $temp eq $hash->{identifier} ) {
            close(Data) if ( defined <Data> );
            ## Open Files

            open( Data, ">$path/$hash->{identifier}.gff" )
              or die "konnte file $path/$hash->{identifier}.gff nicht öffnen!\n";
            $temp = $hash->{identifier};
            print "Exporting Data for Hybs '$temp' to $path/$hash->{identifier}.gff\n";
        }
        $temp[0] = $hash->{filename};
        $temp[1] = "$self->{dataType}_Values";
        $temp[2] = "$self->{dataType} $temp";
        $temp[3] = $hash->{start};
        $temp[4] = $hash->{end};
        $temp[5] = $hash->{value};
        $temp[6] = "";
        $temp[7] = "";
        $temp[8] = "oligoID=\"$hash->{oligoID}\";seq=\"$hash->{sequence}\"";

        print Data join( "\t", @temp ), "\n" if ( defined $hash->{value});

    }
    close(Data);
}


1;
