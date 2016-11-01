package marcowModel;
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
 use stefans_libs::statistics::new_histogram;
 
 sub new{
 
 	my ( $class ) = @_;
 
 	warn "the use of tis object is depricated!\n";
 	
 	my ( $self );
 
 	$self = {
 		possibleIdentifiers => {
 			'a1' => 1,
 			'a0' => 1,
 			'1-a1' => 1,
 			'1-a0' => 1,
 			'phi0' => 1,
 			'phi1' => 1,
 			'Pd0' => 1,
 			'Pd1' => 1,
 			'f0' => 1,
 			'f1' => 1
 		}
   	};
 
   	bless $self, $class  if ( $class eq "marcowModel" );
 
   	return $self;
 
 }
 
 sub load{
 	my ( $self, $filename) = @_;
 	die "to load a marcow model, a file has to be specified, not '$filename'\n"
 		unless  (-f $filename );
 		
 	my ( $identifer, $value, @data, $probFunct );
 	open (IN , "<$filename");
 	while ( <IN> ) {
 		next if ( $_ =~ m/^#/ );
 		chomp $_;
 		
 		if ( $_ =~ m/^([\w\d]+)\t([-\.\d]+)$/ ){
 			( $identifer, $value ) = ( $1, $2) ;
 			unless ( $self->{possibleIdentifiers}->{$identifer}){
 				warn "not usable identifier found: $identifer\n";
 				next;
 			}
 			$self->{$identifer} = $value;
 			next;
 		}
 		if ( $_ =~ m/ (f[01])/ ){
 			$probFunct = $1 ;
 			next;
 		}
 		
 		if ( defined $probFunct){
 			if ($_ =~ m!//! ){ ##end
 				$self->{$probFunct} = new_histogram($probFunct, \@data);
 				$probFunct = undef;
 				next;
 			}
 			push (@data, $_);
 		}	
 	}
 }
 
 sub save{
 	my ( $self, $filename ) = @_;
 	open ( OUT, ">$filename") or die "could not open save file '$filename'\n";
 	while ( <OUT> ){
 		## write the model!
 	}
 	close (OUT);
 }
 
 1;
