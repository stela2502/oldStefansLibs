#! /usr/bin/perl

use strict;
use Shell qw(grep ps kill);
use stefans_libs::tableHandling;
use stefans_libs::root;
use File::HomeDir;
use IO::Handle;

print "this script will keep a look at the 'R --slave --vanilla --gui=X11' command 
from the Statistics::R packge and kill it, if it is stuck.\n",
"As long as the process $ARGV[0] is up and running\n";

my ( $sh, $string, @string, @temp, $R_ids, $lastR_ID, $PID, $master_pid);
$master_pid = $ARGV[0];
my $home    = File::HomeDir->my_home();
mkdir ("$home/logs" )unless ( -d "$home/logs");
print "r_controler_log is '$home/logs/r_controler.std.log'\n";


$PID = 0;
$PID = fork();
if ( $PID < 0){
	print "I can not create a child!\n";
	exit( -1 );
}
if ( $PID > 0 ){
	print "OK the master is down as expected!\n";
	exit ( 1 );
}


if ( -f "$home/logs/r_controler.std.log"){
	open ( STD , ">>$home/logs/r_controler.std.log") or die "could not create logfile $home/logs/r_controler.std.log\n$!\n";
	open ( ERR , ">>$home/logs/r_controler.err.log") or die "could not create logfile $home/logs/r_controler.err.log\n$!\n";
}
else {
	open ( STD , ">$home/logs/r_controler.std.log") or die "could not create logfile $home/logs/r_controler.std.log\n$!\n";
	open ( ERR , ">$home/logs/r_controler.err.log") or die "could not create logfile $home/logs/r_controler.err.log\n$!\n";
}
print "std_out will be in \n$home/logs/r_controler.std.log "
	."std_err wil be in \n$home/logs/r_controler.err.log\n";
	
STDOUT->fdopen( \*STD, 'w' ) or die $!;
STDERR->fdopen( \*ERR, 'w' ) or die $!;


$sh = Shell->new();
my $tableHandling = tableHandling->new(" +");

if ( &I_am_already_running() ){
	print "This process should not be started twice - but lets see...\n";
	exit 1;
}
print "started a r_controller instance ($$) at ".root::time()."\n";

while ( &controlledMasterIsRunning($master_pid) ){
	$R_ids = &getR_processID_andRunTime();
	foreach $PID ( keys %$R_ids){
		unless ( defined $lastR_ID->{$PID}){
			$lastR_ID->{$PID} = $R_ids->{$PID} ;
			next;
		}
		if ( defined $lastR_ID->{$PID} && $lastR_ID->{$PID} eq $R_ids->{$PID} ){
			$sh->kill( $PID );
			print  root::time()." -> I had to kill the R process '$PID' as last time '$lastR_ID->{$PID}' == '$R_ids->{$PID}'\n";
			delete ( $lastR_ID->{$PID} );
			next;
		}
		$lastR_ID->{$PID} = $R_ids->{$PID} ;
	}
	sleep(10);
}
print "no running master process $ARGV[0]\nI am done\n";

sub I_am_already_running{
	$string =  $sh->ps("-Af");
	@string = split ("\n", $string);
	my ($header);
	foreach  $string ( @string ){
		 if ($string =~ m/r_controler.pl/ ) {
		 	next if ( $string =~ m/$$/);
		 	print "therefore we are not starting!\n\t$string\n";
		 	return 1;
		 }		
	}
	return 0;
}

sub controlledMasterIsRunning{
	my ( $controled ) = @_;
	return 1 unless ( defined $controled); ## always on!
	$string =  $sh->ps("-A -l");
	@string = split ("\n", $string);
	my ($header,$return);
	foreach  $string ( @string ){
		unless ( defined $header ) {
			$header = $tableHandling -> identify_columns_of_interest_bySearchHash (
			 $string , {'PID' => 1, 'TIME' => 1, 'CMD' =>1 } );
			next;
		} 
		
		@temp = $tableHandling -> get_column_entries_4_columns ( $string, $header);
		#print "is there A R process in the string? $temp[1]\n";
		 if ( $temp[0] == $controled ) {
		 	return 1;
		 }		
	}
	return 0;
}

sub getR_processID_andRunTime{
	$string =  $sh->ps("-A -l");
	@string = split ("\n", $string);
	my ($header,$return);
	foreach  $string ( @string ){
		unless ( defined $header ) {
			$header = $tableHandling -> identify_columns_of_interest_bySearchHash (
			 $string , {'PID' => 1, 'TIME' => 1, 'CMD' =>1 } );
			next;
		} 
		
		@temp = $tableHandling -> get_column_entries_4_columns ( $string, $header);
		#print "is there A R process in the string? $temp[1]\n";
		 if ( $temp[2] =~ m/^R */ ) {
		 	$return -> { $temp[0] } = $2 if ($temp[1] =~ m/\d\d:(\d\d):(\d\d)/);
		 	#print "NO???\n";
		 }		
	}
	return $return;
}
