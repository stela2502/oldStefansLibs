package stat_test;

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

use stefans_libs::root;
use stefans_libs::tableHandling;
use Statistics::R;

sub new {
	die
"you fool! this is an INTERFACE!\nYou must not create a object out of it!\n";
}

sub AddGroupingHash {

}

sub calculateTest {

}

sub processTableHeader {

}

sub getReport {
	my $self = shift;
	die "getReport is not implemented in $self!\n";
}

sub define_log {
	my ( $self, $logfile_name ) = @_;
	return 0 unless ( defined $logfile_name );

	$self->{'log_file'} = "$logfile_name" ;
	return 1;
}

sub add_2_log{
	my ($self, $str ) = @_;
	return unless ( defined $str);
	if ( defined $self->{'log_file'}){
		$self->{'log'} .= $str;
	}
	return 1;
}
sub close_log {
	my ($self) = @_;
	if ( defined $self->{'log_file'}  ) {
		if ( -f $self->{'log_file'}) {
			open ( LOG , ">>$self->{'log_file'}") or Carp::confess( "I could not add to logfile $logfile!");
		}
		else {
			open ( LOG , ">$self->{'log_file'}") or Carp::confess( "I could not create the logfile $logfile!");
		}
		print LOG $self->{'log'};
		print "Log was written to $self->{'log_file'}\n";
		close ( LOG );
	}
	return 1;
}

sub error {
	my ($self) = @_;
	return
	    "last statistical result: \n"
	  . $self->{lastR}
	  . "\nfor the command\n"
	  . $self->{'last_cmd'}
	  unless ( defined $self->{lastP} );
	return $self->{'error'} if ( $self->{'error'} =~ m/\w/ );
	return undef;
}

sub forceRunningR {
	my ($self) = @_;
	unless ( $self->{R}->is_started() ) {
		$self->{R}->restartR();
		die "could not restart R" unless ( $self->{R}->is_started() );
		print "UPS we had to restart R ion line $self->{statTest}\n";
	}
}

sub TestreinitR {
	my ( $self, $statTests_per_TableLine ) = @_;

	$self->{statTest}    += $statTests_per_TableLine;
	$self->{sinceReinit} += $statTests_per_TableLine;
	if ( $self->{sinceReinit} >= 5000 ) {
		print "ew are at line $self->{statTest}\n";

		#		print "new initialization of R on line $self->{statTest}\n";
		$self->{sinceReinit} = 0;

		#		$self->{R}->restartR();
	}
}

sub _createRvariable_fromArrayRef {
	my ( $self, $variableName, $arrayRef ) = @_;
	return "$variableName <- c ( " . join( ",", @$arrayRef ) . " )"
	  if ( defined $variableName );
	return "c ( " . join( ",", @$arrayRef ) . " )";

}

sub DESTROY {
	my $self = shift;
	if ( $self->{R}->is_started() ){
		$self->{R}->clean_up();
		$self->{R}->stopR();
	}
	$self->close_log();
	printf( "$self clean exit %s\n", scalar localtime ) if ( $self->{'debug'});
}

sub _createRlist_fromMultipleArrayRefs {
	my ( $self, $listName, @arrayRefs ) = @_;
	my @temp;

	#print "we try to make nice results from @arrayRefs\n";

	foreach my $arrayRef (@arrayRefs) {
		push( @temp, $self->_createRvariable_fromArrayRef( undef, $arrayRef ) );
	}
	return "$listName <- list ( " . join( ", ", @temp ) . " )"
	  if ( defined $listName );
	return "list ( " . join( ",", @temp ) . " )";

}

1;
