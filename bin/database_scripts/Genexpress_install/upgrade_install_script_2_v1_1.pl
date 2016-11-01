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

=head1 upgrade_install_script_2_v1_1.pl

A genexpress database plugin helper, to upgrade from install.pl version undef to v1.0 to v1.1, that now contains an additional PluginRegister table row (type) that can take either dataset, labbook or helper and thereby allows to group the Plugins. This became necessary during the implementation of the LabBook_2_Datasets implementation to identify those plugins, that contain data that should be linkable to the LabBook.

To get further help use 'upgrade_install_script_2_v1_1.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $install_script, $type );

Getopt::Long::GetOptions(
	"-install_script=s" => \$install_script,
	"-type=s"           => \$type,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $install_script ) {
	$error .= "the cmd line switch -install_script is undefined!\n";
}
unless ( defined $type ) {
	$warn .=
"in order to upgrade from version 1.0 to version 1.1 I need to know the type!\n";
}
elsif ( !( "labbook dataset helper" =~ m/$type/ ) ) {
	$error .= "sorry, but the plugin_type '$type' is not supported!\n";
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
 command line switches for upgrade_install_script_2_v1_1.pl

   -install_script :the absolute name of the install script
   -type       	   :one out of (helper, labbook, dataset)

   -help           :print this help
   -debug          :verbose output
   

";
}

## now we set up the logging functions....

open( IN, "<$install_script" ) or die "could not read from '$install_script'\n";
my @data = <IN>;
close(IN);

my ( $upgrades, $version, $pluginName );
$pluginName = 'leer';
$upgrades->{'1.0'} = {
	'to'         => '1.1',
	'match'      => "PluginRegister\-\>register_plugin",
	'substitute' => [ [ '\)', ", '$type')" ] ]
  }
  if ( defined $type );

$upgrades->{'1.1'} = {
	'to'         => '1.2',
	'match'      => '## OK now almoast everything should bu ready!',
	'substitute' => [
		[
			'OK now almoast everything should bu ready',
			"OK now almost everything should be ready"
		]
	],
	'add_before_line' => '
## OK now we want to check all the possible scripts we might provide!

opendir( DIR, $plugin_path . "/bin" ) or Carp::confess( "Could not open my controller path $plugin_path/bin!\n");
my @files = readdir(DIR);
closedir(DIR);
my $executable_table = executable_table->new($PluginRegister->{\'dbh\'}, 0 );

foreach my $file ( @files ) { 
	next unless ($file =~ m/(.+)\.pl$/);
	$executable_table->install_script( \'PLUGIN_NAME\', $plugin_id, $plugin_path."/bin/$file", $plugin_path."/formdefs/$1.XML" );
}

'
};

$upgrades->{'add_2_use'} = [ 'use stefans_libs::database::system_tables::executable_table;' ];

$upgrades->{'1.2'} = {
	'to'             => '1.4',
	'match'          => '.subpath = .. unless . defined .subpath .;',
	'add_after_line' => '	return if ($subpath eq "CVS" );
		'
};

$upgrades->{'1.3'} = {
	'to'             => '1.4',
	'match'          => '.subpath = .. unless . defined .subpath .;',
	'add_after_line' => '	return if ($subpath eq "CVS" );
		'
};



my (@use_lines, $match, $to_version);

$to_version = "1.4";
while ( 1 ){

if ($debug) {
	open( OUT, ">$install_script.update" )
	  or die "could not open the install script for writing!\n$!";
}
else {
	open( OUT, ">$install_script" )
	  or die "could not open the install script for writing!\n$!";
}
$match = 0;
foreach (@data) {
	$pluginName = $1
	  if ( $_ =~
		m/\$log_hash->{'installed_plugins'}->{'(Genexpress_catalist_.*)'} / );
	if ( $pluginName =~ m/Genexpress_catalist_/ ) {
		foreach my $data ( values %$upgrades ) {
			next if ( ref($data) eq "ARRAY");
			if ( defined $data->{'match'} ) {
				$data->{'match'} =~ s/PLUGIN_NAME/$pluginName/g;
			}
			if ( defined $data->{'substitute'} ) {
				foreach my $array ( @{ $data->{'substitute'} } ) {
					@{$array}[0] =~ s/PLUGIN_NAME/$pluginName/g;
					@{$array}[1] =~ s/PLUGIN_NAME/$pluginName/g;
				}

			}
			if ( defined $data->{'add_before_line'} ) {
				$data->{'add_before_line'} =~ s/PLUGIN_NAME/$pluginName/g;
			}
			if ( defined $data->{'add_after_line'} ) {
				$data->{'add_after_line'} =~ s/PLUGIN_NAME/$pluginName/g;
			}
		}
		$pluginName = 'leer';
	}
	if ( $_ =~ m/^use / ){
		push ( @use_lines , $_ );
		next;
	}
	if ( $_ =~ m/my \$VERSION = 'v(.*)';/ ) {
		$version = $1;
		
		if ( ref( $upgrades->{'add_2_use'} ) eq "ARRAY"){
			my $str = join ('', @use_lines);
			foreach my $new_use (@{$upgrades->{'add_2_use'}}){
				$str .= $new_use unless ( $str =~ m/$new_use/);
			}
			print OUT $str."\n";
		}
		unless ( defined $upgrades->{$version} ) {
			## OK - first we need toremove the mess we made!
			close(OUT);
			if ($debug) {
				open( OUT, ">$install_script.update" )
				  or die "could not open the install script for writing!\n$!";
			}
			else {
				open( OUT, ">$install_script" )
				  or die "could not open the install script for writing!\n$!";
			}
			print OUT join("", @data);
			close ( OUT );
			if ( $version eq $to_version){
				print "Ready!\n";
				exit;
			}
			die
"sorry, but I can not update a install script of version $version - only version(s) "
			  . join( ", ", keys %$upgrades )
			  . ". are supported!\n";
		}
		die "sorry, but the update dataset is not complete"
		  unless ( defined $upgrades->{$version}->{'to'} );
		$_ =~ s/$version/$upgrades->{$version}->{'to'}/;
	}
	elsif ( !defined $version ) {
		## Shit just Do exactly NOTHING!
	}
	else {
		## now we need to start the conversion
		if ( defined $upgrades->{$version}->{'match'} ) {
			# OK only one Substitution for this change!
			if ( $_ =~ m/$upgrades->{$version}->{'match'}/ ) {
				$match = 1;
				print "We have a match to $version match tag( $upgrades->{$version}->{'match'} )\n";
				if ( ref( $upgrades->{$version}->{'substitute'} ) eq "ARRAY" ) {
					my $substitution =
					  @{ $upgrades->{$version}->{'substitute'} }[0];
					$_ =~ s/@$substitution[0]/@$substitution[1]/;
				}
				if ( defined $upgrades->{$version}->{'add_before_line'} ) {
					$_ = $upgrades->{$version}->{'add_before_line'} . $_;
				}
				if ( defined $upgrades->{$version}->{'add_after_line'} ) {
					$_ = $_ . $upgrades->{$version}->{'add_after_line'};
				}
			}
		}
		else {
			foreach
			  my $substitution ( @{ $upgrades->{$version}->{'substitute'} } )
			{
				$_ =~ s/@$substitution[0]/@$substitution[1]/;
			}
		}

	}
	print OUT $_;
}
close OUT;
unless ( $match ){
	##OhOh - we culd not do the last upgrade from $version to the other $upgrades->{$version}->{'to'}
	warn "Sorry we could not update to version $upgrades->{$version}->{'to'}, as we did not find the matching line for '$upgrades->{$version}->{'match'}'\n";
	if ($debug) {
	open( OUT, ">$install_script.update" )
	  or die "could not open the install script for writing!\n$!";
}
else {
	open( OUT, ">$install_script" )
	  or die "could not open the install script for writing!\n$!";
}
	print OUT join("", @data );
	close OUT;
	die root::get_hashEntries_as_string ($upgrades->{$version}, 3, "could you please fix that update statement:");
}
}

print "ready!\n";
