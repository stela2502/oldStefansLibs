package stefans_libs_file_readers_svg_pathway_description;

#  Copyright (C) 2010-11-30 Stefan Lang 

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

A lib to read a manually created SVG file based on a bit map pathways descrioption to extract the XY positions for a gene or gene group. I expect, that all SVG objects in the file that are rectangles describe such a gene groups and that the id of the object is what you want as key to that region (x1, y1, x2, y2).

=cut
sub new {

    my ( $class, $debug ) = @_;
    my ($self);
    $self = {
        'debug'           => $debug,
        'arraySorter'     => arraySorter->new(),
        'header_position' => { 
            'key' => 0,
            'x1' => 1,
            'x2' => 2,
            'y1' => 3,
            'y2' => 4,
        },
        'default_value'   => [],
        'header'          => [
            'key',
            'x1',
            'x2',
            'y1',
            'y2',       ],
        'data'            => [],
        'index'           => {},
        'last_warning'    => '',
        'subsets'         => {}
    };
    bless $self, $class if ( $class eq "stefans_libs_file_readers_svg_pathway_description" );

    return $self;
}


sub read_file {
	my ( $self , $infile ) = @_;
	Carp::confess ( "There is no file named '$infile'\n") unless ( -f $infile );
	open ( IN , "<$infile" ) or die "I could not open the infile '$infile'\n$!\n";
	my ( $use, $dataset, $width, $height );
	$self->{'data'} = [];
	$use = 0;
	while ( <IN> ){
		if ( $_ =~ m/<rect$/){
			$use = 1;
			$width = undef;
			$dataset = undef;
			$height = undef;
			next;
		}
		next unless ( $use );
		if ( $_ =~ m/id="(.+)"/){
			$dataset -> {'key'} = $1;
		}
		elsif ( $_ =~ m/style/ ){
			next;
		}
		elsif ( $_ =~ m/width="([\d\.]+)"/){
			$width = $1;
			$width = int($width);
		}
		elsif ( $_ =~ m/height="([\d\.]+)"/){
			$height = $1;
			$height = int($height);
		}
		elsif ($_ =~ m/x="([\d\.]+)"/){
			Carp::confess ( "Sorry I do not know the width of the figure!") unless ( defined $width);
			$dataset ->{'x1'} = $1;
			$dataset ->{'x2'} = $1 + $width;
			$dataset ->{'x1'} = int( $dataset ->{'x1'} );
			$dataset ->{'x2'} = int( $dataset ->{'x2'} );
		}
		elsif ($_ =~ m/y="([\d\.]+)"/){
			Carp::confess ( "Sorry I do not know the height of the figure!") unless ( defined $height);
			$dataset ->{'y1'} = $1;
			$dataset ->{'y2'} = $1 + $height;
			$dataset ->{'y1'} = int( $dataset ->{'y1'} );
			$dataset ->{'y2'} = int( $dataset ->{'y2'} );
		}
		else {
			if (defined $dataset){
				#print root::get_hashEntries_as_string ($dataset, 3, "we add the datase ");
				$self->AddDataset( $dataset);
				$use = 0;
			}
			else {
				warn "Oh - one of the rects could not pe parsed!\n$_";
			}
		}
	}
	print "ready\n" if ( $self->{'debug'});
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
