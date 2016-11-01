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

=head1 process_Group_files.pl

Simple script to remove probelms.

To get further help use 'process_Group_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for process_Group_files.pl

   -infiles       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

"; 
}

my ( $task_description, $i, $data_table, $data_line, $group_id, @genes );


## and add a working entry

$task_description .= 'process_Group_files.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);

open ( AmitabT ,">the_table_for_amitadb.tsv") or die "could not create the sommary file!\n";

foreach ( @infiles ) {
	unless ( -f $_ ) {
		warn "not a file! ($_)\n";
		next;
	}
	$data_table = data_table->new();
	$data_table -> read_file($_);
	$group_id = $1 if ( $_ =~ m/Gr\.(\d+)_/ ); 
	$i = 0;
	@genes = undef;
	foreach $data_line ( @{$data_table->{'data'}} ){
		if ( @$data_line[0] =~ m/\\nameref{(.+)}/ ){
			@$data_line[0] = $1;
			$i++;
		}
		else {
			print "No match @$data_line[0]\n";
		}
		push( @genes, @$data_line[0] );
	}
	shift ( @genes ) unless ( defined $genes[0]);
	print AmitabT "Group $group_id:\n".join("\t", @genes)."\n";
	print "$_ -> $i substitutions\n";
	$data_table -> print2file ( $_ );
}
close AmitabT;
print "The summary file for Amitabh is there: 'the_table_for_amitadb.tsv'\n";
