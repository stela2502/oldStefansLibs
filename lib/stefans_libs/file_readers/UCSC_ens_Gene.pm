package stefans_libs_file_readers_UCSC_ens_Gene;

#  Copyright (C) 2011-02-07 Stefan Lang 

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
use warnings;

use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=head1 General description

Reads UCSC ens_Gene database flat files

=cut
sub new {

    my ( $class, $debug ) = @_;
    my ($self);
    $self = {
        'debug'           => $debug,
        'arraySorter'     => arraySorter->new(),
        'header_position' => { 
        	'bin' => 0, # 585
 			 'name'=> 1, # ENST00000423562
 			 'chrom' => 2, # chr1
 			 'strand' => 3, # + || -
 			 'txStart' => 4, # 11868
 			 'txEnd' => 5, # 14409
 			 'cdsStart' => 6, # 14409
 			 'cdsEnd' => 7, # 14409
 			 'exonCount' => 8, # 3
 			 'exonStarts' => 9, # 11868,12612,13220,
 			 'exonEnds' => 10, # 12227,12721,14409,
 			 'score' => 11, # 0
 			 'name2' => 12, # DDX11L10
 			 'cdsStartStat' => 13 , # none
 			 'cdsEndStat' => 14, # none
 			 'exonFrames' => 15, # -1,-1,-1,
        },
        'default_value'   => [],
        'header'          => ['bin' => 0, # 585
 			 'name', # ENST00000423562
 			 'chrom' , # chr1
 			 'strand' , # + || -
 			 'txStart', # 11868
 			 'txEnd' , # 14409
 			 'cdsStart' , # 14409
 			 'cdsEnd' , # 14409
 			 'exonCount' , # 3
 			 'exonStarts' , # 11868,12612,13220,
 			 'exonEnds' , # 12227,12721,14409,
 			 'score', # 0
 			 'name2' , # DDX11L10
 			 'cdsStartStat' , # none
 			 'cdsEndStat' , # none
 			 'exonFrames', # -1,-1,-1,
                   ],
        'data'            => [],
        'index'           => {},
        'last_warning'    => '',
        'subsets'         => {}
    };
    bless $self, $class if ( $class eq "stefans_libs_file_readers_UCSC_ens_Gene" );

    return $self;
}


sub Add_2_Header {
    my ( $self, $value ) = @_;
    return undef unless ( defined $value );
    unless ( defined $self->{'header_position'}->{$value} ) {
        Carp::confess( "You try to change the table structure - That is not allowed!\n".
            "If you really want to change the data please use ".
            "the original data_table class to modify the table structure!\n"
        ) ;
    }
    return $self->{'header_position'}->{$value};
}



1;
