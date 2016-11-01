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

=head1 GEO_sample_desciption.pl

A tool to get information about a array dataset stored on the NCBI GEO database. This script will extract some information from the GEO web page - it will not access the database.

To get further help use 'GEO_sample_desciption.pl -help' at the comman line.

=cut

use Getopt::Long;
use WWW::Mechanize;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, @GEO_ids, $outfile);

Getopt::Long::GetOptions(
	 "-GEO_ids=s{,}"    => \@GEO_ids,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug,
);

my $warn = '';
my $error = '';

unless ( defined $GEO_ids[0]) {
	$error .= "the cmd line switch -GEO_id is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for GEO_sample_desciption.pl

   -GEO_ids       :the id of the dataset you want to get description about
   -outfile       :the file where to store the description

   -help           :print this help
   -debug          :verbose output
   

"; 
}

my ( $www, $GEO_id, $data, @data, $use_data, $result) ;

$www = WWW::Mechanize->new( 'stack_depth' => 0 );
foreach $GEO_id (@GEO_ids ){
	$www->get('http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc='.$GEO_id);
	$data = $www->content();
	@data = split( "\n", $data );
	warn "we got " . scalar(@data) . " lines\n" if ( $debug);
	$result ->{$GEO_id} = { 'Organism' => 0 , 'CellType' => 0, 'Array_Identifier' => 0};
	foreach ( @data ){
		if ( $_ =~ m/nowrap>Description</ ){
			$use_data = 1;
			next;
		}
		if ( $_ =~ m/<td>Organism\(s\)<\/td>/ ){
			$use_data = 1;
			next;
		}
		if ( $_ =~ m/<td>Platform ID<\/td>/){
			$use_data = 1;
			next;
		}
		if ( $use_data ){
			$use_data = 0;
			if ( $_ =~ m/geoaxema_organismus\)">(.*)<\/a><\/td>/){
				$result ->{$GEO_id} ->{'Organism'} = $1;
			}
			elsif ( $_ =~ m/>(.*)<br><\/td>/ ){
				$result ->{$GEO_id} ->{'CellType'} = $1;
			}
			elsif ( $_ =~ m/>(.*)<\/a><\/td>/ ){
				$result ->{$GEO_id} ->{'Array_Identifier'} = $1;
			}
		}
	}
}

if (open ( OUT , ">$outfile" ) ){
	print OUT "#GEO_id\tcell_type\torganism\tArray_Identifer\n";
	foreach $GEO_id ( sort keys %$result ){
		print OUT "$GEO_id\t$result->{$GEO_id}->{'CellType'}\t$result->{$GEO_id}->{'Organism'}\t$result->{$GEO_id}->{'Array_Identifier'}\n";
	}
	close ( OUT );
	print "Data written to '$outfile'\n";
}
else {
	print "#GEO_id\tcell_type\torganism\tArray_Identifer\n";
	foreach $GEO_id ( sort keys %$result ){
		print "$GEO_id\t$result->{$GEO_id}->{'CellType'}\t$result->{$GEO_id}->{'Organism'}\t$result->{$GEO_id}->{'Array_Identifier'}\n";
	}
}

