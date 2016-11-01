package primer;
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

sub new{

   my ( $class, $hash ) = @_;

   my ( $self, %primer, $dbh, $sth) ;


#   print "primer->new hash = \n";
   foreach my $temp (keys %$hash){
     $hash = $hash->{$temp};
     last;
   }

 #   foreach my $temp (keys %$hash){
 #    print "\t$temp\t$hash->{$temp}\n";
 #  }

   $self = {
      id => $hash->{ID},
      tw => $hash->{TW},
      name => $hash->{Name},
      sequenz => $hash->{Sequenz}
   };

   bless ( $self, $class) if ( $class eq "primer");

   return $self;
}

sub TW{
	my ( $self, $tw)= @_;
	$self->{tw} = $tw if ( defined $tw);
	return $self->{tw};
}

sub Seq {
    my ( $self, $seq) = @_;
    $self->{sequenz} = $seq if ( defined $seq );
#    print "primer seq = $self->{sequenz}\n";
    my @return = split(" ",$self->{sequenz});
    return join ("" , @return);
}

sub AsFasta{
    my ( $self ) = @_;
    my $seq = $self->Seq();
    return ">$self->{name}\n$seq\n";
}

sub Length{
    my ( $self) = @_;
    return $self->{primerLength} if ( defined $self->{primerLength});
    $self->{primerLength} = length ( $self->Seq());
    return $self->{primerLength};
}

1;
