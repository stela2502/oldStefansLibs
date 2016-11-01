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

=head1 add_configuartion.pl

Add a configuartion entry for the database. This script is so easy - it may be evan easier to do that by hand...

To get further help use 'add_configuartion.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::system_tables::configuration;

my ( $help, $debug, $tag, $value );

Getopt::Long::GetOptions(
	"-tag=s"   => \$tag,
	"-value=s" => \$value,
	"-help"    => \$help,
	"-debug"   => \$debug
);

if ($help) {
	print helpString();
	exit;
}

unless ( defined $tag && defined $value ) {
	print helpString(
		"we need a tagt AND a value to insert that into the databse...");
	exit;
}

my $config = configuration->new();

$config->AddConfiguration( { 'tag' => $tag, 'value' => $value } );
if ( $config->GetConfigurationValue_for_tag($tag) eq $value ) {
	print "we have added the variable $tag -> $value to the configuartion\n";
}
else {
	warn
"add_configuartion -> we were not able to add the config value $tag -> $value to the databse!\n",
	  "we got ", $config->GetConfigurationValue_for_tag($tag), "!\n";
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for add_configuartion.pl
 
   -tag            :the variable name
   -value          :the value for the variable
   -help           :print this help
   -debug          :verbose output


";
}
