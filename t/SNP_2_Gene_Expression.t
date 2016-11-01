#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

my $value = &start_r_controler();
is_deeply( $value > 0, 1, "we got a PID $value");
&stop_r_controler($value );


sub start_r_controler {
	my @path = split( "/", $0 );
	splice( @path, @path - 2, 4 );
	print "we expect the scripts to be downstream of "
	  . join( "/", @path )
	  . "/bin\n";
	my $r_controller_cmd = "perl -I " . join( "/", @path ) . "/lib ". join( "/", @path ).	
		"/bin/array_analysis/r_controler.pl";
	my (@r_out, $last_r_pid, $temp);
	@r_out = qx( $r_controller_cmd );
	$temp = join ( " ",@r_out);
	$temp =~ m/r_controler_log is '(.*)'/;
	open ( R_LOG ,"<$1") or die "could not open r_controller log '$1'\n";
	while  ( <R_LOG> ){
 		$last_r_pid = $1 if ( $_ =~ m/started a r_controller instance \((\d+)\) at/ );
	}
	close ( R_LOG );
	return $last_r_pid;
}


sub stop_r_controler{
	my ( $last_r_pid)  = @_;
	system ("kill $last_r_pid");
}