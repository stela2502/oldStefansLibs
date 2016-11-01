#! /usr/bin/perl -w

#  Copyright (C) 2011-12-23 Stefan Lang

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

=head1 AddGroupInfos_to_expression_table.pl

This program can add grouping information to the expression files so that they can be plotted using the 'stefans_libs_file_readers_affymetrix_expression_result' lib file.

To get further help use 'AddGroupInfos_to_expression_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::affymetrix_expression_result;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile, $group_name, $color, $x_tag, @x_values, @samples, @pattern);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,
	 "-group_name=s"    => \$group_name,
	 "-color=s"    => \$color,
	 "-x_tag=s"    => \$x_tag,
	 "-p4Cs=s{,}"  => \@pattern,
	 "-x_values=s{,}"    => \@x_values,
	 "-samples=s{,}"    => \@samples,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $group_name) {
	$error .= "the cmd line switch -group_name is undefined!\n";
}
unless ( defined $color) {
	$error .= "the cmd line switch -color is undefined!\n";
}
unless ( defined $x_tag) {
	$error .= "the cmd line switch -x_tag is undefined!\n";
}
unless ( defined $x_values[0]) {
	$warn .= "In the end the datafile doesn need a  -x_values definition!\n";
}
unless ( defined $samples[0]) {
	$error .= "the cmd line switch -samples is undefined!\n";
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
 command line switches for AddGroupInfos_to_expression_table.pl

   -infile       :the source affymeztrix file
   -outfile      :the outfile (can also be the same as the infile ;-)
   -group_name   :a group name as plotted in the legend
   -color        :a color - please look into the color.pm lib file to get a list of possible colors
   -x_tag        :some tag for the x axis - like '2h' or 'before treatment' 
   -x_values     :youneed to supply this value only once. It defined the x axis tags in a global setting
   -samples      :a list of column names that should be plotted in this group
                  All values will be grouped into a box plot
   -p4Cs         :a Pattern to select the data columns or a list of column names

   -help   :print this help
   -debug  :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/AddGroupInfos_to_expression_table.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -group_name $group_name" if (defined $group_name);
$task_description .= " -color $color" if (defined $color);
$task_description .= " -x_tag $x_tag" if (defined $x_tag);
$task_description .= ' -x_values '.join( ' ', @x_values ) if ( defined $x_values[0]);
$task_description .= ' -samples '.join( ' ', @samples ) if ( defined $samples[0]);
$task_description .= ' -p4cS "'.join( '" "', @pattern ).'"' if ( defined $pattern[0]);

## Do whatever you want!

my $affy_file = stefans_libs_file_readers_affymetrix_expression_result ->new();
$affy_file -> p4cS ( @pattern );
$affy_file -> read_file ( $infile );

$affy_file -> Sample_Groups ( "$group_name$x_tag$color", \@samples, "x=$x_tag;color=$color;label=$group_name"  );
die "We have an seriouse issue here - missing data columns - have you given me the p4Cs command line option??\n".$affy_file->{'error'} if ( $affy_file->{'error'} =~m/\w/);
if ( defined $x_values[0]){
	## oh cool - lets see whether the sample information has been added previousely...
	my @temp = (split( "\t", @{ $affy_file->Description('x_values') }[0] ));
	unless ( defined $temp[0] ){
		## OK - no description up to now - I will add mine here
		$affy_file->Add_2_Description( join("\t",'x_values', @x_values));
		@temp = (split( "\t", @{ $affy_file->Description('x_values') }[0] ));
	}
	shift(@temp);
	my $OK = 0;
	foreach ( @temp ) {
		$OK = 1 if ( $_ eq $x_tag);
	}
	Carp::confess ( "Sorry, but I got an issue here - I do not find the x_tag '$x_tag' in the x_values ".join(";",@temp) ) unless ( $OK );
}
$affy_file -> write_file ( $outfile );

print "Done!\n";
