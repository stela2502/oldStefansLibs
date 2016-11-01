#! /usr/bin/perl -w

#  Copyright (C) 2010-06-21 Stefan Lang

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

=head1 create_control_4_connection_net.pl

A tool to create the statistical values for the Connection net control

To get further help use 'create_control_4_connection_net.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;
use IO::Handle;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,    $debug,        $database,     $expression_data,
	@p4Cs,    $seeder_genes, $replications, $R_cutoff,
	$outpath, $min_connections
);

Getopt::Long::GetOptions(
	"-expression_data=s" => \$expression_data,
	"-p4Cs=s{,}"         => \@p4Cs,
	"-seeder_genes=s"    => \$seeder_genes,
	"-replications=s"    => \$replications,
	"-R_cutoff=s"        => \$R_cutoff,
	"-outpath=s"         => \$outpath,
	"-min_connections=s" => \$min_connections,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $expression_data ) {
	$error .= "the cmd line switch -expression_data is undefined!\n";
}
unless ( defined $p4Cs[0] ) {
	$error .= "the cmd line switch -p4Cs is undefined!\n";
}
unless ( defined $seeder_genes ) {
	$error .= "the cmd line switch -seeder_genes is undefined!\n";
}
unless ( defined $replications ) {
	warn
"we set the replications to 1 - that is most probably not what you wanted me to do!";
	$replications = 1;
}
unless ( defined $R_cutoff ) {
	warn
	  "we set the R_cutoff to 0.75 - that should be fine for most settings!\n";
	$R_cutoff = 0.75;
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
unless ( defined $min_connections ) {
	$min_connections = 2;
}
if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 	The tool will help you so create as many random connection nets as 
 	you want and report some statistical values on these nets.
 	These values could and should be used to estimate the p_value 
 	to get your connection net of interest.
 	
 $errorMessage
 command line switches for create_control_4_connection_net.pl

   -expression_data  :the array expression values
   -p4Cs             :the pattern to selest the samples
   -seeder_genes     :the amount of random seeder genes to use
   -replications     :how many times should I cretate a random connection net 
   -R_cutoff         :please give me a reasonably high cutoff so that the data 
                      file will stay acceptably small - that will speed up the analysis!
   -min_connections  :how many seeder genes ahve to be interconnected in order to note that gene
                      default = 2
   -outpath          :the path to store the connection net and all statistical values

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'create_control_4_connection_net.pl';
$task_description .= " -expression_data $expression_data"
  if ( defined $expression_data );
$task_description .= " -p4Cs " . join( " ", @p4Cs ) if ( defined $p4Cs[0] );
$task_description .= " -seeder_genes $seeder_genes"
  if ( defined $seeder_genes );
$task_description .= " -replications $replications"
  if ( defined $replications );
$task_description .= " -R_cutoff $R_cutoff" if ( defined $R_cutoff );
$task_description .= " -outpath $outpath"   if ( defined $outpath );
$task_description .= " -min_connections $min_connections";

## OK I want to make that thing a daemin - otherwise I get a lot of problems that I do not want to have!

my $PID = 0;
$PID = fork();
if ( $PID < 0 ) {
	print "I can not create a child!\n";
	exit(-1);
}
if ( $PID > 0 ) {
	print "OK the master is down as expected!\n";
	exit(1);
}

## redirect std outputs!
mkdir "$outpath/logs" unless ( -d "$outpath/logs" );

open( STD, ">$outpath/logs/create_control_4_connection_net.std.log" )
  or die
"could not open the normal log file ($outpath/logs/create_control_4_connection_net.std.log)!\n";
open( ERR, ">$outpath/logs/create_control_4_connection_net.err.log" )
  or die "could not open the error log file!\n";

print
  "std_out will be in \n$outpath/logs/create_control_4_connection_net.std.log\n"
  . "and std_err will be in\n$outpath/logs/create_control_4_connection_net.err.log\n";

STDOUT->fdopen( \*STD, 'w' ) or die $!;
STDERR->fdopen( \*ERR, 'w' ) or die $!;

print "started a create_control_4_connection_net instance ($$) at "
  . root::time() . "\n"
  . "using the command:\n$task_description\n";

## Do whatever you want!
my ( $cmd, @path );

@path = split( "/", $0 );
splice( @path, @path - 4, 4 );
print "we expect the scripts to be downstream of "
  . join( "/", @path )
  . "/bin\n";
$cmd = "perl -I " . join( "/", @path ) . "/lib ";
$cmd .=
    join( "/", @path )
  . "/bin/database_scripts/expression_net/createConnectionNet_4_expressionArrays.pl"
  . " -p4cS "
  . join( " ", @p4Cs )
  . " -amount_of_random_genes $seeder_genes"
  . "  -outfile $outpath/connection_net.txt"
  . " -array_values $expression_data"
  . " -r_cutoff $R_cutoff";

open( EXP_LOG, ">$outpath/createConnectionNet.log" )
  or die "could not create the createConnectionNet.log file\n";
print EXP_LOG "PID $$ start on "
  . root::time()
  . "\nusing the command:\n$cmd\n";
close(EXP_LOG);
my $r_controller_cmd =
    "perl -I "
  . join( "/", @path ) . "/lib "
  . join( "/", @path )
  . "/bin/array_analysis/r_controler.pl";
my ( @r_out, $last_r_pid );

for ( my $i = 0 ; $i < $replications ; $i++ ) {
	open( EXP_LOG, ">>$outpath/createConnectionNet.log" );
	print EXP_LOG "#$i (" . root::time() . ")\n";
	close(EXP_LOG);
	@r_out = qx( $r_controller_cmd );
	system($cmd );
	join( "\n", @r_out ) =~ m/(\/home.*r_controler.std.log)/;
	open( R_LOG, "<$1" )
	  or die "could not open r_controller log '$1'\n";
	while (<R_LOG>) {
		$last_r_pid = $1
		  if ( $_ =~ m/started a r_controller instance \((\d+)\) at/ );
	}
	close(R_LOG);
	system("kill $last_r_pid");
}

my @genes;
open( GENE_LIST, "<$outpath/connection_net.txt.gene_lists" )
  or die
"I could not open the log file '$outpath/connection_net.txt.gene_lists' \n$!\n";
$cmd = "perl -I " . join( "/", @path ) . "/lib ";
$cmd .=
    join( "/", @path )
  . "/bin/database_scripts/expression_net/expression_net_to_R_network.pl"
  . " -R_squared $R_cutoff"
  . " -infile $outpath/connection_net.txt"
  . " -outpath $outpath"
  . " -only_statistics";
my $command_log;
open( OUT, ">$outpath/expression_net_to_R_network_commands.log" );
print OUT
"## if you want any figure for the connection nets please remove the -only_statistics from the respective command!\n";
close(OUT);

while (<GENE_LIST>) {
	chomp($_);
	@genes = split( " ", $_ );
	warn "we had a problem with the reported seeder genes, as we only got "
	  . scalar(@genes)
	  . " but expected to get $seeder_genes\n"
	  if ( scalar(@genes) != $seeder_genes );
	open( OUT, ">>$outpath/expression_net_to_R_network_commands.log" );
	print OUT root::time()
	  . "\n$cmd -initial_genes "
	  . join( " ", @genes ) . "\n";
	close(OUT);
	system( $cmd. " -initial_genes " . join( " ", @genes ) );

}

print
"I hope all the data you need is in the connection_net log file  $outpath/expression_net_statistcs.txt\n\n";

