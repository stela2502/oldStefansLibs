#! /usr/bin/perl -w

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

=head1 open_query_interface.pl

A generic tool to do tiny database queries - closest to the open Query. It is able to add and retrieve data, but it is not able to delete data.

To get further help use 'open_query_interface.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::flexible_data_structures::data_table;
use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @sql_cmd, $function, $outfile );

Getopt::Long::GetOptions(
	"-sql_cmd=s"  => \@sql_cmd,
	"-function=s" => \$function,
	"-outfile=s"  => \$outfile,

	"-help"       => \$help,
	"-debug"      => \$debug,
	"-database=s" => \$database
);

my $warn  = '';
my $error = '';

unless ( defined $sql_cmd[0] ) {
	$error .= "the cmd line switch -sql_cmd is undefined!\n";
}
elsif( -f $sql_cmd[0]){
	open ( IN , $sql_cmd[0] );
	@sql_cmd = <IN>;
	close ( IN );
}
#unless ( defined $function ) {
#	$error .= "the cmd line switch -function is undefined!\n";
#}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 $errorMessage
 command line switches for open_query_interface.pl

   -sql_cmd       :a list of sql commands to execute" .

	  #"   -function       :<please add some info!>\n".
	  "   -outfile       :the file you want to store some infos in

   -help           :print this help
   -debug          :verbose output

";
}

## now we set up the logging functions....

my (
	$task_description, $workingTable, $loggingTable,
	$workLoad,         $loggingEntries
);

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );

## and add a working entry

$task_description =
    "open_query_interface.pl -sql_cmd "
  . join( " ", @sql_cmd )
  . "-outfile $outfile";

## so now we need to try to get the SQL to run - containing the search for uncommon chars!
my $danger = {};
my $result = 0;
my @danger = qw( { [ } ] | );

foreach my $sql_cmd (@sql_cmd) {
	foreach ( split( "", $sql_cmd ) ) {
		$danger->{$_} = 0 unless ( defined $danger->{$_} );
		$danger->{$_}++;
	}
}

foreach (@danger) {
	$result += $danger->{$_} if ( defined $danger->{$_} );
}
Carp::confess(
	"The sql_command contained not acceptable strings!\n" . $task_description )
  if ( $result > 0 );
$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'open_query_interface.pl',
		'description' => $task_description
	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description($task_description);

unless ( defined @$loggingEntries[0] ) {

	my $dbh = root->getDBH();
	my ( $sth, $data, $data_table, $i );
	open( OUT, ">$outfile" ) or die "could not create the outfile '$outfile'\n";
	$data_table = data_table->new();
	$i          = 0;
	foreach my $sql_cmd (@sql_cmd) {
		$i++;
		unless ( $sth = $dbh->prepare($sql_cmd) ) {
			print OUT "The eql query failed during 'prepare':\n$!\n";
			next;
		}
		unless ( $data = $sth->execute() ) {
			print OUT "The eql query failed during 'execute':\n$!\n";
			next;
		}
		if ( $sql_cmd =~
			m/^ *[Ss][Ee][Ll][Ee][Cc][Tt] *(.*) *[Ff][Rr][Oo][Mm] / )
		{
			my @columnNames = ( split( / *, */, $1 ) );
			unless ( $data = $sth->fetchall_arrayref() ) {
				print OUT
				  "The eql query failed during 'fetchall_arrayref':\n$!\n";
				exit;
			}
			## now we need to identify the column titles
			print "we got the column names: "
			  . join( ", ", @columnNames ) . "\n";
			$data_table->Add_db_result( \@columnNames, $data );
			$data_table->print2file("$outfile$i.data");
			print OUT
"the results for the sql query $sql_cmd are stored in the file $outfile$i.data\n";
			next;
		}
		else {
			print OUT "We have added $data new sets.\n";
			next;
		}
	}
	close(OUT);

	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

}

$workingTable->delete_workload_for_PID($$);

