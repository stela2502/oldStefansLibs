package ssake_info;
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

	my ( $class, $filename ) = @_;

	my ( $self );

	$self = {
		data => undef
  	};

  	bless $self, $class  if ( $class eq "ssake_info" );
	$self->Add_ssake_info($filename) if ( defined $filename);
	
  	return $self;

}

sub Add_ssake_info{
	my ( $self, $file) = @_;
	
	print "ssake_info Add_ssake_info for file $file\n";
	if ( -f $file ){
	open (IN, "<$file" );
	my @line;
	while ( <IN> ){
		chomp $_;
		@line = split("\t", $_);
		die "$self Add_ssake_info duplicate entry for acc $line[0]\n "if ( defined $self->{data}->{$line[0]});
		$self->{data}->{$line[0]} = {
			acc => $line[0],
			'length' => $line[2],
			contig => $line[1],
			reads => $line[3],
			coverage => $line[4]
		}
	}
	close (IN);
	}
}

sub Length{
	my ( $self, $acc) = @_;
	return $self->{data}->{$acc}->{'length'} if ( defined $self->{data}->{$acc});
	warn "$self Length no data for acc $acc\n";
	root::print_hashEntries($self,2,"Is there anithing missing??\n");
	return undef;
}

sub Reads{
	my ( $self, $acc) = @_;
	return $self->{data}->{$acc}->{reads} if ( defined $self->{data}->{$acc});
	warn "$self Reads no data for acc $acc\n";
	root::print_hashEntries($self,2,"Is there anithing missing??\n");
	return undef;
}

sub Coverage{
	my ( $self, $acc) = @_;
	return $self->{data}->{$acc}->{coverage} if ( defined $self->{data}->{$acc});
	warn "$self Coverage no data for acc $acc\n";
	root::print_hashEntries($self,2,"Is there anithing missing??\n");
	return undef;
}
1;
