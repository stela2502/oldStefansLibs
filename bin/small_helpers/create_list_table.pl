#! /usr/bin/perl -w

#  Copyright (C) 2011-08-22 Stefan Lang

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

=head1 create_list_table.pl

create a list table

To get further help use 'create_list_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $name, $target_table, $table_name );

Getopt::Long::GetOptions(
	"-name=s"         => \$name,
	"-target_table=s" => \$target_table,
	"-table_name=s"   => \$table_name,
	"-help"           => \$help,
	"-debug"          => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $name ) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $table_name ) {
	$error .= "the cmd line switch -table_name is undefined!\n";
}
unless ( -f $target_table ) {
	$error .= "the cmd line switch -target_table is undefined!\n";
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
 command line switches for create_list_table.pl

   -name            :the new list file
   -table_name      :the list table name
   -target_table    :the target table class file

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/create_list_table.pl';
$task_description .= " -name $name" if ( defined $name );
$task_description .= " -table_name $table_name";
$task_description .= " -target_table $target_table"
  if ( defined $target_table );

## first we need to get the other_table include name!
my ( @path, $package_name , $other_package_class_name, $this_package, $other_package_include, $temp );

## $other_package_class_name
open ( IN, "<$target_table" ) or die "I could not open target_table '$target_table'\n$!\n";
foreach ( <IN> ){
	$other_package_class_name = $1 if ( $_ =~m/package (.+);/ );
	last;
}
close ( IN );

## $other_package_include
$temp = &parse_lib_position($target_table);
$other_package_include = join("::",@$temp);
$other_package_include =~s/\.pm$//;

## $package_name

$temp = &parse_lib_position($name);
$package_name = join("_",@$temp);
$package_name  =~s/\.pm$//;

## outfile
$name = "$name.pm" unless ( $name =~m/\.pm$/ );
open ( OUT ,">$name" ) or die "I could not create the outfile '$name'\n$!\n";
print OUT &text( $package_name, $table_name, $other_package_include,
		$other_package_class_name );
close ( OUT );

print "we created the list table class '$name'\n";

sub parse_lib_position {
	my ($package) = @_;
	my ( $use, @package );
	$use = 0;
	if ( $package =~ m/\// ) {
		foreach ( split( "/", $package ) ) {
			print "we check the part $_\n";
			if ( $_ eq "lib" ) {
				$use = 1;
				next;
			}
			if ( $use == 1 ) {
				print "and this part is important!\n";
				push( @package, $_ );
			}
		}
		if ( scalar(@package) == 0 ) {
			foreach ( $package =~ m/.*\/(.*)/ ) {
				push( @package, $1 );
			}
		}
	}
	Carp::confess ( "Sorry, but I did not find the essencial 'lib' component in the lib path ('$package')!") unless ( $use );
	return \@package;
}


sub text {
	my ( $package_name, $table_name, $other_package_include,
		$other_package_class_name )
	  = @_;
	return 'package ' . $package_name . ';

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

use stefans_libs::database::lists::basic_list;
use ' . $other_package_include . ';

use base (\'basic_list\');

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like \'perldoc perlpod\'.

=head1 NAME

' . $package_name . '

=head1 DESCRIPTION

A list table that links to the table ' . $other_package_class_name . '.

=head2 depends on

' . $other_package_include . '

=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class ' . $package_name . '.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh)
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug           => $debug,
		dbh             => $dbh,
		\'my_table_name\' => "' . $table_name . '"
	};

	bless $self, $class if ( $class eq "' . $package_name . '" );

	$self->init_tableStructure();
	$self->{\'data_handler\'}->{\'otherTable\'} =
	  '.$other_package_class_name.'->new( $self->{\'dbh\'}, $self->{\'debug\'} );
	$self->{\'__actualID\'} = $self->readLatestID();

	return $self;

}

1;
'
}
