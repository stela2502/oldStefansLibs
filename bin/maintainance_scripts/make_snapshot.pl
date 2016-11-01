#! /usr/bin/perl -w

#  Copyright (C) 2012-05-08 Stefan Lang

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

=head1 make_snapshot.pl

A backup script using rsync as backup tool.

Inspiration for this script comes from 
http://www.mikerubel.org/computers/rsync_snapshots/

To get further help use 'make_snapshot.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::database::variable_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $outpath, $config);

Getopt::Long::GetOptions(
	 "-outpath=s"    => \$outpath,
	 "-config=s"    => \$config,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -d $outpath) {
	$error .= "the cmd line switch -outpath is undefined or does not exist!\n";
}
unless ( defined $config) {
	$warn .= "the cmd line switch -config is undefined!\n";
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
 command line switches for make_snapshot.pl

   -outpath       :<please add some info!>
   -config       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/make_snapshot.pl';
$task_description .= " -outpath $outpath" if (defined $outpath);
$task_description .= " -config $config" if (defined $config);

unless ( -f 'make_snapshot.log' ) {
	open ( LOG, ">make_snapshot.log" ) or die "I could not create the log file 'make_snapshot.log'\n$!\n";
}
else {
	open ( LOG, ">>make_snapshot.log" ) or die "I could not create the log file 'make_snapshot.log'\n$!\n";
}

print LOG $task_description."\n";
close ( LOG );

## I want to store the backups in a daily fashion - I can delete backups whenever I need more space...
my ( $NOW, @dir, $last_backup, $str, $str_2 );

$NOW = variable_table->NOW();

opendir ( DIR, "$outpath") or die "I could not access the dir '$outpath' \n$!\n";
@dir = readdir ( DIR );
closedir ( DIR );
$last_backup = "$outpath/".$dir[@dir - 1];
print "This is the last backup here:";
if ( $last_backup =~m/\.$/ ){
	$last_backup = '';
}
$str = "$outpath/$NOW";
$str =~s/ /\\ /g;
$str =~s/:/\\:/g;
$str_2 = $last_backup;
$str_2 =~s/ /\\ /g;
$str_2 =~s/:/\\:/g;

print "the new outpath = '$str'\n" if ( $debug );
unless ( -d "$outpath/$NOW"){
	mkdir ( "$outpath/$NOW" ) or die "I could not create the outpath '$outpath/$NOW'\n$!\n";
	system ( "cp -al $str_2/* $str") if ( -d $last_backup );
	system ( "rsync -va --delete /home/stefan  $str");
}
else {
	die "The outpath did already exist!\n";
}


