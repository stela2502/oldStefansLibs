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

=head1 install.pl

this is the automatic install script - do not modify\!

To get further help use 'install.pl -help' at the comman line.

=cut

use Getopt::Long;
use XML::Simple;
use FindBin;
use File::Copy;
use stefans_libs::database::system_tables::configuration;
use stefans_libs::database::system_tables::PluginRegister;
use stefans_libs::database::system_tables::executable_table;
use stefans_libs::database::system_tables::LinkList;

use strict;
use warnings;

my $VERSION = 'v1.3';

my ( $help, $debug, $database, $install_path );

Getopt::Long::GetOptions(
	"-install_path=s" => \$install_path,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $install_path ) {
	$error .= "the cmd line switch -install_path is undefined!\n";
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
 command line switches for install.pl

   -install_path       :your server path

   -help   :print this help
   -debug  :verbose output
   

";
}

## now we set up the logging functions....

my ( $task_description, $log_hash, $XML );

## and add a working entry

$task_description .= 'install.pl';
$task_description .= " -install_path $install_path"
  if ( defined $install_path );

unless ( -f $install_path . "/genexpress_catalist.conf" ) {
	warn
"Sorry, but $install_path is not a Genexpress_catalist source path - therefor I can not install this package to that path!\n";
	exit;
}
$XML = XML::Simple->new( ForceArray => [], AttrIndent => 1 );

unless ( -f $install_path . "/InstalledPlugins.xml" ) {
	$log_hash = { 'installed_plugins' => {}, 'files' => {} };
	open( OUT, ">" . $install_path . "/InstalledPlugins.xml" );
	print OUT $XML->XMLout($log_hash);
	close(OUT);
}

$log_hash = $XML->XMLin( $install_path . "/InstalledPlugins.xml" );

if ( defined $log_hash->{'installed_plugins'}->{'MY_NAME'} ) {
	warn "we uninstall a previouse version of the plugin!\n";
	eval {system("$install_path/scripts/uninstall_plugin.pl -plugin_name MY_NAME")};
	$log_hash = $XML->XMLin( $install_path . "/InstalledPlugins.xml" );
}

my $plugin_path = "$FindBin::Bin/../";
my $failed_deps = '';
my $dependancies = $XML->XMLin( $plugin_path . "/.DEPS.XML" );
foreach my $dep ( keys %$dependancies ){
	print "we depend on plugin $dep version >= $dependancies->{$dep}\n";
	unless ( $log_hash->{'installed_plugins'}->{$dep} >= $dependancies->{$dep} ){
		$failed_deps .= "$dep\t$dependancies->{$dep}\n";
	}
}
die "Sorry, but there were unsolved dependancies:\npluding\tversion\n$failed_deps" if ( $failed_deps =~ m/\w/ );
my ( @installed_files, $configuration );
$configuration = configuration->new();
push( @installed_files,
	&copy_files( $plugin_path . '/lib', $install_path . '/lib' ) );
push(
	@installed_files,
	&copy_files(
		$plugin_path . '/bin',
		$configuration->GetConfigurationValue_for_tag('script_base')
		  . "/MY_NAME"
	)
);
push(
	@installed_files,
	&copy_files(
		$plugin_path . '/formdefs',
		$configuration->GetConfigurationValue_for_tag('xml_formdef_path')
		  . "/MY_NAME"
	)
);
push( @installed_files,
	&copy_files( $plugin_path . '/doc', $install_path . '/doc/MY_NAME' ) );
push( @installed_files,
	&copy_files( $plugin_path . '/root/src/', $install_path . '/root/src/' ) );

## what do I need to install
## 1. all in lib
## 2. all in formdefs- but in a subfolder!
## 3. all in bin - but that into a subfolder inside the script_base folder!!
## 4. all in doc - but in a subfolder!
## AND I need to keep track of all the installed files!
open( IN, "<$plugin_path/.VERSION" );
my $version = <IN>;
close(IN);
print "We install the plugin MY_NAME in version $version\n";
$log_hash->{'installed_plugins'}->{'MY_NAME'} = $version;

foreach my $file (@installed_files) {
	$log_hash->{'files'} = $version;
}

open( OUT, ">" . $install_path . "/InstalledPlugins.xml" );
print OUT $XML->XMLout($log_hash);
close(OUT);
## Add the Main PluginRegister entries for this dataset!
my $PluginRegister = PluginRegister->new( root::getDBH('root') );
my $plugin_id = $PluginRegister->register_plugin( 'MY_NAME', $version, 'PLUGIN_DESCRIPTION', 'PLUGIN_TYPE' );
## OK - now I need to read through the Controller files to set the exported functions
my ( @other_ids, $hash );
foreach $hash (
	&parse_controllers( $plugin_path . '/lib/Genexpress_catalist/Controller' ) )
{
	push( @other_ids, $PluginRegister->Add_managed_Dataset($hash) );
}
$PluginRegister->Add_2_list(
	{
		'my_id'     => $plugin_id,
		'var_name'  => 'export_id',
		'other_ids' => \@other_ids
	}
);

## OK now we want to check all the possible scripts we might provide!
opendir( DIR, $plugin_path . "/bin" ) or Carp::confess( "Could not open my controller path $plugin_path/bin!\n");
my @files = readdir(DIR);
closedir(DIR);
my $executable_table = executable_table->new($PluginRegister->{'dbh'}, 0 );

foreach my $file ( @files ) { 
	next unless ($file =~ m/(.+)\.pl$/);
	$executable_table->install_script( 'MY_NAME', $plugin_id, $plugin_path."/bin/$file", $plugin_path."/formdefs/$1.XML" );
}

## OK now almoast everything should bu ready!
## I only need to make the Plugin known to the user!

my $LinkList = LinkList->new($PluginRegister->{'dbh'});
my @link_ids;
my $master_id = $LinkList->AddDataset(
		{ 'name' => 'Plugins', 'link' => '/datasets/index', 'role' => 'user' }
	);
push(
	@link_ids,
	$LinkList->Add_managed_Dataset(
		{
			'name'          => 'MY_NAME',
			'link_position' => '/MY_NAME/index'
		}
	)
);
$LinkList->Add_2_list(
	{
		'my_id'     => $master_id,
		'var_name'  => 'object_list_id',
		'other_ids' => \@link_ids
	}
);
warn "THE DEVELOPER HAS NOT CHANGED THE LINK STRUCTURE!!!!\n";

sub parse_controllers {
	my ( $base_path, $subpath ) = @_;
	$subpath = '' unless ( defined $subpath );
	opendir( DIR, $base_path . $subpath )
	  or Carp::confess( "Could not open my controller path $base_path.$subpath!\n");
	my @controllers = readdir(DIR);
	closedir(DIR);
	my ( @return, $line, $module, @temp );
	foreach my $file (@controllers) {
		next if ( $file =~ m/^\./);
		if ( -d $base_path . $subpath . "/$file" ) {
			push( @return,
				&parse_controllers( $base_path, $subpath . "/$file" ) );
		}
		elsif ( $file =~ m/(.+)\.pm/ ) {
			$module = $subpath . "/$1";
			open( IN, "<$base_path$subpath/$file" )
			  or Carp::confess( "could not open the file $base_path$subpath/$file\n");
			foreach $line (<IN>) {
				#print "we read the line $line";
				if ( $line =~ m/^sub/){
					chomp $line;
					@temp = split ( /[ :#]/,$line );
					if ( $temp[@temp-1] eq "exported"){
						#print "and we identified a exported controller function $temp[1]\n";
						push( @return, { 'name' =>  $temp[1], 'link' => lc($module)."/$temp[1]" } );
					}
				}
			}
			close(IN);
		}
	}
	return @return;
}

sub copy_files {
	my ( $source_path, $target_path, $subpath ) = @_;
	$subpath = '' unless ( defined $subpath );
	my @return;
	opendir( DIR, $source_path . $subpath )
	  or Carp::confess( "could not open path '$source_path/$subpath'\n");
	my @contents = readdir(DIR);
	closedir(DIR);
	foreach my $file (@contents) {
		next if ( $file =~ m/^\./);
		if ( -d $source_path . $subpath . "/$file" ) {
			push(
				@return,
				&copy_files(
					$source_path, $target_path,
					$subpath  . "/$file"
				)
			);
		}
		else {
			unless ( -d $target_path . $subpath ) {
				system( "mkdir -p " . $target_path . $subpath );
			}
			copy(
				$source_path . $subpath . "/$file",
				$target_path . $subpath . "/$file"
			);
			push( @return, $subpath . "/$file" );
		}
	}
	return @return;
}
