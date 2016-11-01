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

=head1 create_Genexpress_Plugin.pl

This script will create the scelleton of a Genexpress plugin.

To get further help use 'create_Genexpress_Plugin.pl -help' at the comman line.

=cut

use Getopt::Long;
use XML::Simple;
use File::Copy;

use strict;
use warnings;

my $VERSION = 'v1.1';

my (
	$help,            $debug,
	$database,        $base_path,
	@source_db_class, $plugin_name,
	$developer,       $install_script,
	$force,           $plugin_description,
	$plugin_type,     $experimetType_name,
	$experimetType_description
);

Getopt::Long::GetOptions(
	"-base_path=s"                 => \$base_path,
	"-source_db_class=s{,}"        => \@source_db_class,
	"-force"                       => \$force,
	"-plugin_description=s"        => \$plugin_description,
	"-developer_name=s"            => \$developer,
	"-sample_install_script=s"     => \$install_script,
	"-plugin_type=s"               => \$plugin_type,
	"-experimetType_name=s"        => \$experimetType_name,
	"-experimetType_description=s" => \$experimetType_description,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $base_path ) {
	$error .= "the cmd line switch -base_path is undefined!\n";
}
elsif ( !( -d $base_path ) ) {
	$error .=
"I expect, that the -base_path already exists - please create the path!\n";
}
unless ( defined $plugin_type ) {
	$error .= "we need a plugin_type!\n";
}
elsif ( !( "labbook dataset helper" =~ m/$plugin_type/ ) ) {
	$error .= "sorry, but the plugin_type '$plugin_type' is not supported!\n";
}
if ( $plugin_type eq 'dataset' ) {
	unless ( defined $experimetType_name ) {
		$error .=
"As this plugin should be part of a dataset I need to know the name of that dataset (experimetType_name)\n";
	}
	unless ( defined $experimetType_description ) {
		$error .=
"As this plugin should be part of a dataset I need to get a description  of that experiment type (experimetType_description)\n";
	}
}

unless ( defined $source_db_class[0] ) {
	$error .= "the cmd line switch -source_db_class is undefined!\n";
}
unless ( defined $developer ) {
	$developer = "Stefan Lang";
}
unless ( defined $plugin_description && length($plugin_description) > 20 ) {
	$plugin_description = '' unless ( defined $plugin_description );
	$error .=
"Sorry, but we need a plugin_description of at least 20 chrs length, not '$plugin_description'\n";
}
unless ( -f $install_script ) {
	$error .=
"Sorry, but could you give me the absolute pathe to the sample install script (-sample_install_script)?\n";
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
 command line switches for create_Genexpress_Plugin.pl

   -base_path         :where to set_up the plugin
   -source_db_class   :the db_object file (absolute path please!)
   -plugin_type       :either 'helper', 'labbook' or 'dataset'
                       this value affects the usabillity of the plugin,
                       as only 'dataset' data can be linked to the LabBook
   -force             :delete the plugin If is did exist
   -developer_name    :You name - will be added as Autor to the newly created files.
   
   -plugin_description    :A test description of this plugin, that will be displayed as
                           description of this plugin.
   -sample_install_script :A script that could be used to install this a plugin
                           you should take bin/database/Genexpress_install/install.pl for that!
   
   -help           :print this help
   -debug          :verbose output
   
   ------------------------------------------------------------------------------------
   If you want to create a part of a 'dataset', you must supply the next two variables:
   
   -experimetType_name        :the name of the experiment type this 
                               plugin should be part of
   -experimetType_description :a short description of that experimentType
   ------------------------------------------------------------------------------------

";
}

## now we set up the logging functions....

my ( $task_description, $installed_files );

## and add a working entry

$task_description .= 'create_Genexpress_Plugin.pl';
$task_description .= " -base_path $base_path" if ( defined $base_path );
$task_description .= ' -source_db_class ' . join( ' ', @source_db_class )
  if ( defined $source_db_class[0] );
$task_description .= " -experimetType_name $experimetType_name"
  if ( defined $experimetType_name );
$task_description .= " -experimetType_description $experimetType_description"
  if ( defined $experimetType_description );

my $XML_interface = XML::Simple->new( ForceArray => [], AttrIndent => 1 );
my $plugin_hash;

unless ( -f "$base_path/plugin_register.xml" ) {
	$plugin_hash = { 'registered_table_objects' => {}, };
	foreach my $class
	  qw( root arraySorter dataset_registration external_files grant_table
	  LabBook project_table scientistTable to_do_list variable_table dataset_list file_list ChapterStructure
	  LabBook_instance basic_list list_using_table action_group_list action_groups PW_table role_list roles
	  scientificComunity configuration errorTable jobTable LinkList loggingTable passwords PluginRegister
	  roles thread_helper workingTable jobTable object_list www_object_table linkage_info queryInterface
	  table_script_generator XML_handler data_table ) {

		$plugin_hash->{'available_classes'}->{$class} = 'Genexpress_catalist';
	  } open( OUT, ">$base_path/plugin_register.xml" )
	  or die "could not create the file '$base_path/plugin_register.xml'\n";
	print OUT $XML_interface->XMLout($plugin_hash);
	close OUT;
}
copy( "$base_path/plugin_register.xml", "$base_path/last_plugin_register.xml" );

$plugin_hash = $XML_interface->XMLin("$base_path/plugin_register.xml");
$plugin_hash->{'registered_table_objects'} = {}
  unless ( defined $plugin_hash->{'registered_table_objects'} );

## 1. check if the db_class has previously been used to create a plugin
my ( @temp, $db_class_name, $lib_path, @long_class_name, $use, $stop,$long_class_name );
@temp = split( "/", $source_db_class[0] );
$lib_path = '';
$use = $stop = 0;
for ( my $i = 0 ; $i < @temp ; $i++ ) {
	$use = 1 if ( $temp[$i] eq "stefans_libs" ); ## I expect you to create database plugins based on my databse interface...
	if ( $use ) {
		push (@long_class_name, $temp[$i] );
	}
	$lib_path .= '/' . $temp[$i] unless ( $stop );
	$stop = 1 if ( $temp[$i] eq "database" );
}
$long_class_name = join("_",@long_class_name);
$long_class_name =~ s/.pm$//;
#die "we would use that long class name '$long_class_name'\n";
$db_class_name = $temp[ @temp - 1 ];
$db_class_name =~ s/.pm$//;
$plugin_name = $db_class_name;
$plugin_name = "Genexpress_catalist_$db_class_name"
  unless ( $plugin_name =~ m/^Genexpress_catalist_/ );

if ( defined $plugin_hash->{'registered_table_objects'}->{$db_class_name} ) {
	unless ($force) {
		die
		  "Sorry, but you already have defined a plugin for this table object ("
		  . $plugin_hash->{'registered_table_objects'}->{$db_class_name}
		  . ")\n";
	}
	else {
		delete $plugin_hash->{'registered_table_objects'}->{$db_class_name};
		foreach
		  my $obj_name ( keys %{ $plugin_hash->{'available_db_objects'} } )
		{
			delete $plugin_hash->{'available_classes'}->{$obj_name}
			  if ( $plugin_hash->{'available_classes'}->{$obj_name} eq
				$plugin_name );
		}
		system("rm -R $base_path/$plugin_name");
	}
}

$plugin_hash->{'registered_table_objects'}->{$db_class_name} = $plugin_name;

## 2. create the folder structure
mkdir( $base_path . '/' . $plugin_name );
mkdir( $base_path . '/' . $plugin_name . '/lib' );
mkdir( $base_path . '/' . $plugin_name . '/lib/Genexpress_catalist' );
mkdir(
	$base_path . '/' . $plugin_name . '/lib/Genexpress_catalist/Controller' );
mkdir( $base_path . '/' . $plugin_name . '/lib/Genexpress_catalist/Model' );
mkdir(
	$base_path . '/' . $plugin_name . '/lib/Genexpress_catalist/My_Plugins' );
mkdir( $base_path . '/' . $plugin_name . '/lib/Genexpress_catalist/View' );
mkdir( $base_path . '/' . $plugin_name . '/root' );
mkdir( $base_path . '/' . $plugin_name . '/root/src' );
mkdir( $base_path . '/' . $plugin_name . '/root/src/My_Plugins' );
mkdir(  $base_path . '/'
	  . $plugin_name
	  . '/root/src/My_Plugins/'
	  . lc($db_class_name) );
mkdir( $base_path . '/' . $plugin_name . '/bin' );
mkdir( $base_path . '/' . $plugin_name . '/doc' );
mkdir( $base_path . '/' . $plugin_name . '/formdefs' );
mkdir( $base_path . '/' . $plugin_name . '/scripts' );
mkdir( $base_path . '/' . $plugin_name . '/t' );

## 3. copy the needed database objects

## Here I need to read and understand the db_object!!
## And I will relay on the variable_table::linkage_info::table_script_generator object!!
require $source_db_class[0];
print "I tried to require the class  $source_db_class[0]\n";
my ( $db_lib_include, @other_libs ) = &copy_lib_file( $source_db_class[0] );
## we need to also copy the other required classes!!

my $temp;
my $depends_on      = {};
my $db_obj;
eval{ $db_obj = $db_class_name->new( root::getDBH('root') )};
unless ( ref( $db_obj) =~ m/\w/ ){
	print "we need to create the \$db_obj from the string $long_class_name\n";
	$db_obj = $long_class_name->new( root::getDBH('root') );
}
my $obj_description = $db_obj->_getLinkageInfo()->GetVariable_names();
&process_obj_description($obj_description);

## 4. create the Genexpress_catalist::Model::<db_class_name> file
open( OUT,
	    '>'
	  . $base_path . '/'
	  . $plugin_name
	  . '/lib/Genexpress_catalist/Model/'
	  . $db_class_name
	  . '.pm' );
print OUT &__db_model( $db_obj, $db_lib_include );
close(OUT);

## 5. create a sample Genexpress_catalist::Controller::<db_class_name> model
##    that implements the functions AddDataset; BatchAddDatasets; DropDataset;
##    ExportData; ExportAllData; Calculations

open( OUT,
	    '>'
	  . $base_path . '/'
	  . $plugin_name
	  . '/lib/Genexpress_catalist/Controller/'
	  . $db_class_name
	  . '.pm' );
print OUT &__db_controller( $db_obj, $db_lib_include );
close(OUT);

## now I might need to add some files to the path
## $base_path . '/' . $plugin_name . '/src/My_Plugins/'.$db_class_name

open( OUT,
	    ">"
	  . $base_path . '/'
	  . $plugin_name
	  . '/root/src/My_Plugins/'
	  . lc($db_class_name)
	  . "/index.tt2" )
  or die "could not create file "
  . $base_path . '/'
  . $plugin_name
  . '/root/src/My_Plugins/'
  . lc($db_class_name)
  . "/index.tt2" . "\n";
print OUT "<h3> the start page for the plugin $plugin_name</h3>
<p>";
print OUT " [% IF description %]
	<p> Description of this plugin:</p>
    <p> [% description %] </p>
    [% END %]
    ";
close(OUT);

## 6. create the install script, that is able to
##      check the previously installed version of other plugins
##      copy the files to the Genexpress_catalist installation folder
##      insert entries into the LinkList of the working Genexpress_Database
##         in order to make the plugin accessible for the users

## OK now to the install/unsinstall scripts....
## The uninstall script has to be part of the main distibution,
## as it has to read the install log to get rid of all the installed files!

open( IN, "<$install_script" ) or die "could not open '$install_script'\n";
open( OUT, ">" . $base_path . '/' . $plugin_name . '/scripts/install.pl' )
  or die "could not create the sinstall script "
  . $base_path . '/'
  . $plugin_name
  . '/scripts/install.pl' . "\n";
my $done_lib = 0;
foreach (<IN>) {

	if ( $plugin_type eq "dataset" && !$done_lib ) {
		if ( $_ =~ "^use stefans_libs" ) {
			$_ .= "use stefans_libs::database::experimentTypes;\n";
			$done_lib = 1;
		}
	}
	if ( $plugin_type eq "dataset" ) {
		if ( $_ =~ m/## OK now we want to check all / ) {
			$_ = "## Hey - I am part of a Dataset Plugin!
my \$experimentTypes = experimentTypes->new(\$PluginRegister->{'dbh'} );
my \$experimet_type_id = \$experimentTypes ->AddDataset ( {
	'name' => '$experimetType_name',
	'description' => '$experimetType_description',
} );
\$experimentTypes->add_to_list( \$experimet_type_id, { 'id' => \$plugin_id });
" . $_;
		}
	}
	$_ =~ s/MY_NAME/$plugin_name/g;
	$_ =~ s/CONTROLLER_NAME/$db_class_name/g;
	$_ =~ s/PLUGIN_DESCRIPTION/$plugin_description/g;
	$_ =~ s/PLUGIN_TYPE/$plugin_type/g;
	print OUT $_;
}
close(OUT);
close(IN);

#die "we do not want to save the done work to the configuration hash, as there is a lot missing at the moment!\n";
#die root::print_hashEntries(
#	{
#		'$plugin_hash'     => $plugin_hash,
#		'$obj_description' => $obj_description,
#		'$depends_on'      => $depends_on
#	},
#	4,
#	"some interesting facts:"
#);

## 7. write the extended $plugin_hash
my $file_str = $XML_interface->XMLout($plugin_hash);
open( OUT, ">$base_path/plugin_register.xml" )
  or die "could not open $base_path/plugin_register.xml";
print OUT $file_str;
close(OUT);

open( OUT, ">" . $base_path . '/' . $plugin_name . "/" . '.VERSION' );
print OUT "0.01";
close(OUT);

$file_str = $XML_interface->XMLout($depends_on);
open( OUT, ">$base_path/$plugin_name/.DEPS.XML" )
  or die "could not create DEPS file $base_path/$plugin_name/.DEPS.XML";
print OUT $file_str;
close(OUT);
open( OUT, ">$base_path/$plugin_name/Makefile" );
print OUT &__Makefile($plugin_name);
close(OUT);

##create the config file

open( OUT, ">$base_path/$plugin_name/configure.pl" )
  or die "could not create configure.pl\n";
print OUT &configFile();
close(OUT);

sub process_obj_description {
	my ($obj_description) = @_;

	print "we process $obj_description\n";
	foreach my $variable_information (
		values %{ $obj_description->{variable_information} } )
	{
		next unless ( defined $variable_information->{'tableObj'} );
		$temp = ref( $variable_information->{'tableObj'} );
		if ( defined $plugin_hash->{'available_classes'}->{$temp}
			&& !( $plugin_hash->{'available_classes'}->{$temp} eq $plugin_name )
		  )
		{
			##OK we do not need to copy that dataset, but we need to add to the dependencies!
			$depends_on->{ $plugin_hash->{'available_classes'}->{$temp} } =
			  0.01;
			warn
"we need to depend on $plugin_hash->{'available_classes'}->{$temp} as this plugin defines $temp\n";
		}
		else {
			## OK now we need to find the definig data table
			my ( $my_path, $use );
			$use     = 0;
			$my_path = '';
			my $libFile = &get_db_class_file($temp);

			#print "and we got $libFile\n";
			Carp::confess("we can not identify a lib file that matches $temp")
			  unless ( defined $libFile );
			&copy_lib_file($libFile);
			warn
"we will now process the object desription for obj $variable_information->{'tableObj'}\n";
			&process_obj_description(
				$variable_information->{'tableObj'}->_getLinkageInfo()
				  ->GetVariable_names() );
		}
	}
	return;
}

sub copy_lib_file {
	my ($libFile) = @_;
	my ( $use, $my_path, $line, @otherLibFiles, $class_name, $libBasePath,
		$targetPath, @temp );
	$libBasePath = '/';
	unless ( -f $libFile ) {

		#warn "we can not copy the file $libFile\n";
		return undef;
	}
	foreach ( split( "/", $libFile ) ) {
		next if ( $_ eq "" );
		unless ($use) {
			$libBasePath .= $_ . "/";
		}
		if ( $_ eq "lib" ) {
			$use = 1;
			next;
		}
		next unless ($use);
		if ( $_ =~ m/(.+)\.pm/ ) {
			$class_name = $1;
			last;
			next;
		}
		$my_path .= '/' . $_;
	}
	$targetPath = $base_path . '/' . $plugin_name . '/lib' . $my_path . "/";
	unless ( defined $plugin_hash->{'available_classes'}->{$class_name} ) {
		## OK we need to add this class to our dataset!
		$plugin_hash->{'available_classes'}->{$class_name} = $plugin_name;
		system("mkdir -p $base_path/$plugin_name/lib/$my_path ");
		print "I try to create the path $base_path/$plugin_name/lib/$my_path\n";
		@temp = split( "/", $libFile );
		if ($force) {
			unlink( $targetPath . $temp[ @temp - 1 ] )
			  if ( -f $targetPath . $temp[ @temp - 1 ] );
		}
		unless ( -d $targetPath ) {
			system("mkdir -p $targetPath");
		}
		link( $libFile, $targetPath . $temp[ @temp - 1 ] )
		  or die "could not copy file \n$libFile\nto\n"
		  . $targetPath
		  . $temp[ @temp - 1 ] . "\n$!\n";
		system( "chmod 660 " . $targetPath . $temp[ @temp - 1 ] );
		print "we have created the file "
		  . $targetPath
		  . $temp[ @temp - 1 ] . "\n";
		## OK and now we need to take care of possible other lib parts!
		open( LIB, "<" . $targetPath . $temp[ @temp - 1 ] )
		  or die
		  "That is impossible - I can not open the file I created just now!\n";
		foreach $line (<LIB>) {
			if ( $line =~ m/ *use *(.+) *;/ ) {
				## OK we have another libFile, that we might need to take care of - or?
				$use = $1;
				$use =~ s!::!/!g;
				push( @otherLibFiles,
					&copy_lib_file( $libBasePath . $use . ".pm" ) );
			}

		}
		close(LIB);
	}
	elsif (
		!( $plugin_hash->{'available_classes'}->{$class_name} eq $plugin_name )
	  )
	{
		## OK we depend on another class!
		$depends_on->{ $plugin_hash->{'available_classes'}->{$class_name} } = 1;
	}
	unless ( ref(@otherLibFiles) eq "ARRAY" ) {
		return $my_path unless ( scalar(@temp) > 0 );
		return $my_path . "/" . $temp[ @temp - 1 ];
	}
	else {
		return $my_path, @otherLibFiles unless ( scalar(@temp) > 0 );
		return $my_path . "/" . $temp[ @temp - 1 ], @otherLibFiles;
	}
	return undef;
	return $my_path . "/" . $temp[ @temp - 1 ], @otherLibFiles;
}

sub get_db_class_file {
	my ($filename) = @_;
	my $lib_p = $lib_path;

	#print "we search for the file $filename\n";
	return undef unless ( defined $filename );
	return &__parse_dir( $lib_p, $filename );

}

sub __Makefile {
	my ($plugin_name) = @_;
	return "SERVER_PATH = /storage/www/Genexpress_catalist/
VERSION = 0_01
MODULE = $plugin_name

install:
	perl -I \${SERVER_PATH}/lib scripts/install.pl -install_path \${SERVER_PATH}
dist:
	tar -c --exclude-vcs -f  ../\${MODULE}_v\${VERSION}.tar ../\${MODULE}
	gzip --best ../\${MODULE}_v\${VERSION}.tar
	rm -rf ../\${MODULE}_v\${VERSION}.tar
";
}

sub __parse_dir {
	my ( $dir, $file ) = @_;
	opendir( DIR, $dir ) or die "we could not open the path $dir\n";
	my @contents = readdir(DIR);
	my $return;
	closedir(DIR);
	foreach (@contents) {

		print "we scan $dir/$_ for $file\n";
		last unless ( defined $_ );
		next if ( $_ =~ m/^.?\./ );
		if ( -d "$dir/$_" ) {
			$return = &__parse_dir( "$dir/$_", $file );
			return $return if ( defined $return );
		}
		elsif ($file.".pm" =~ /$_$/ ) {
			return "$dir/$_";
		}
	}
	return undef;
}

sub __db_model {
	my ( $dbObj, $db_obj_include_str ) = @_;
	$db_obj_include_str =~ s!^/+!!;
	$db_obj_include_str =~ s/\//::/g;
	$db_obj_include_str =~ s/\.pm//;
	my $name    = ref($dbObj);
	my $new_str = $name . '->new(';
	if ( $dbObj->expected_dbh_type() eq "dbh" ) {
		$new_str .= " root::getDBH( 'root' ) )";
	}
	else {
		$new_str .= "'', 0,  \@arguments)";
	}
	return "package Genexpress_catalist::Model::$name;

use strict;
use warnings;
use parent 'Catalyst::Model';

use $db_obj_include_str;


sub new {
	my ( \$app, \@arguments ) = \@_;
	my \$self = $new_str;
	## I need to set some basic configuration options!!
	## warn ref(\$self). '  I was called from'. \$0.\"\\n\\n\" ;
	return \$self;
}

=head1 NAME

Genexpress_catalist::Model::$name - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

$developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;";

}

sub __db_controller {
	my ( $dbObj, $db_obj_include_str ) = @_;

	my $name = ref($dbObj);
	my $link = lc($name);

	return "package Genexpress_catalist::Controller::$name;

use strict;
use warnings;
use Genexpress_catalist::base_db_controler;
use base 'Genexpress_catalist::base_db_controler';

=head1 NAME

Genexpress_catalist::Controller::$name - Catalyst Controller

=head1 DESCRIPTION

This class should provide the all the functionallity for the data stored in the table model $name.

=head1 METHODS

=cut

=head2 index

=cut

" . "
sub index : Local {
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	\$c->stash->{'description'} = \$c->model('PluginRegister')->get_data_table_4_search({
 	'search_columns' => [ref(\$c->model('PluginRegister')).'.description'],
 	'where' => [[ref(\$c->model('PluginRegister')).'.name','=','my_value']]
 }, '$plugin_name')->get_line_asHash(0)->{ref(\$c->model('PluginRegister')).'.description'};
	\$self->AddLinkOut(\$c);
	\$self->finalize(\$c);
	\$c->stash->{'template'} = 'My_Plugins/$link/index.tt2';
}
" . "

=head2 AddDataset 

This function simply calles for the /add_2_model/$name functionallity in the automatically 
created version of this function. But it can of cause be chenged to some script call!

=cut

sub AddDataset  : Local: Form  { ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	\$self->Add_add_form ( \$c, {'db_obj' => \$c->model('$name'), 'redirect_on_success' => '/$link/ViewTable'} );
	foreach my \$hash (\@{\$self->{'form_array'}}){
		\$self->formbuilder->field(\%\$hash);
	}
	\$self->finalize(\$c);
	\$c->stash->{'template'} = 'Form.tt2';
}

" . "
=head2 ViewTable

This function simply redirects to  /add_2_model/View_Table/$name

=cut
	
sub ViewTable : Local { ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	\$c->res->redirect('/add_2_model/List_Table/$name');
	\$c->detach();
}

" . "
=head2 BatchAddDatasets

This function is absolutely useless for the heavy data storage tables like
GenomeDB or array_datasets, as the upload to these tables is ALWAYS a BatchAddDatasets.
But for other tables, like scientistsTable or subjectsTable, this function could provide extra features.
But you have to keep in mind, that there is NO POSSIBILLITY to add to the downstream tables!

=cut

sub BatchAddDatasets : Local : Form { ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
    \$self->formbuilder->method('post');
	\$self->formbuilder->field(
		'name'  => 'data_file',
		'label' => 'Data File',
		'type'  => 'file',
		'text' => 'I need a TAB separated table file!'

	);
	\$self->formbuilder->field(
         'name'  => 'description',
         'label' => 'Description',
         'type'  => 'textarea',
         'text'  => 'please describe why you want to do that'
 
     );
	
	my ( \$upload, \$filename);
    if ( \$self->formbuilder->submitted() ) {
    	my \$dataset = \$self->__process_returned_form(\$c);
        \$c->model('jobTable')->{'debug'} = 0;
        my \$username = \$c->user();
        my \$jobId = \$c->model('jobTable')->AddDataset(
            {
                'cmd' => 'perl -I '
                   . \$c->model('configuration')
                   ->GetConfigurationValue_for_tag('perl_include_path') . ' '
                   . \$c->model('configuration')
                   ->GetConfigurationValue_for_tag('script_base')
                   . '/BatchInsertDatafile.pl -infile '
                   . \$dataset->{'data_file'}
                   . ' -db_class /stefans_libs/database/$name.pm',
                 'executable' => 'BatchInsertDatafile.pl',
                 'state'      => '0',
                 'scientist'  => { 'username' => \"\$username\" },
                 'labbook_instance_id' =>
                   \$c->session->{'labbook_instance_id'},
                 'labbook_id'  => \$c->session->{'labbook_id'},
                 'job_type'    => 'perl_script',
                 'description' => \$dataset->{'description'}
             }
         );
         \$c->res->redirect('/add_2_model/List_Table/jobTable');
         \$c->detach();
        }
	\$c->stash->{'title'} = 'BatchAddDatasets';
	\$c->stash->{'template'} = 'Form.tt2';
	\$self->AddLinkOut(\$c);
	\$self->finalize(\$c);
}
" . "
sub DropDataset : Local : Form {   ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	\$self->stash->{'function'} = 'DropDataset';
	\$self->stash->{'template'} = 'please_implement_me.tt2';
	\$self->AddLinkOut(\$c);
	\$self->finalize(\$c);
}
" . "
sub ExportData : Local : Form {  ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	my \$return = \$self->Add_select_form( \$c, 'id', \$c->model('$name') );
	if ( ref(\$return->{'selected'}) eq 'ARRAY'){
		my \$filename = 'table_slice.'.DateTime::Format::MySQL->format_datetime(
				DateTime->now()->set_time_zone('Europe/Berlin') ). '.tsf';
		\$c->model('configuration')->GetConfigurationValue_for_tag('perl_include_path');
				\$c->model('jobTable') -> AddDataset ( { 
					'cmd' => 'perl -I '.\$c->model('configuration')
			  ->GetConfigurationValue_for_tag('perl_include_path').' '.\$c->model('configuration')
			  ->GetConfigurationValue_for_tag('script_base').'/ExportDatasets.pl -outfile '.\$filename.' -db_class $db_obj_include_str'
			  . ' -IDs '.join(' ',\@{\$return->{'selected'}}),
					'executable' => 'ExportDatasets.pl',
					'state' => '0',
				});
				\$c->res->redirect('/add_2_model/List_Table/jobTable');
				\$c->res->detach();
	}
	\$c->stash->{'title'} = 'ExportData from table set $name';
	\$c->stash->{'template'} = 'Form.tt2';
	\$self->AddLinkOut(\$c);
	\$self->finalize(\$c);
}
" . "
sub ExportAllData : Local : Form {  ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	\$c->stash->{'function'} = 'ExportAllData';
	\$c->stash->{'template'} = 'please_implement_me.tt2';
	\$self->AddLinkOut(\$c);
	\$self->finalize(\$c);
}
" . "
sub Calculations : Local : Form {  ##exported
	my ( \$self, \$c, \@args ) = \@_;
	\$self->__check_user(\$c);
	\$c->stash->{'function'} = 'Calculations';
	\$c->stash->{'template'} = 'please_implement_me.tt2';
	\$self->AddLinkOut(\$c);
	\$self->finalize(\$c);
}
" . "
sub AddLinkOut {
	my ( \$self, \$c, \@args ) = \@_;
	\$c->stash->{'LinkOut'} = [
		{
			'href' => '/$link/index',
			'tag'  => 'Back to Start'
		},
		{
			'href' => '/$link/ViewTable',
			'tag'  => 'Show the table contents'
		},
		{
			'href' => '/$link/AddDataset',
			'tag'  => 'Add a Dataset'
		},
		{
			'href' => '/$link/BatchAddDatasets',
			'tag'  => 'Add a Dataset File'
		},
		{
			'href' => '/$link/Calculations',
			'tag'  => 'Use data for calculations'
		},
		{
			'href' => '/$link/ExportData',
			'tag'  => 'Export a Subset'
		},
		{
			'href' => '/$link/ExportAllData',
			'tag'  => 'Dump All data'
		}
	];
}
" . "
=head1 AUTHOR

$developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
"
}

sub configFile {
	return '#! /usr/bin/perl -w

#  Copyright (C) 2010 Stefan Lang

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

=head1 configure.pl

A generic configure script, that can create my makefiles - SIMPLE.

To get further help use \'configure.pl -help\' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use FindBin;

my $VERSION = \'v1.0\';


my ( $help, $debug, $database, $server_path, $version, $module);

Getopt::Long::GetOptions(
	 "-server_path=s"    => \$server_path,
	 "-version=s"    => \$version,
	 "-module=s"    => \$module,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = \'\';
my $error = \'\';

unless ( defined $server_path) {
	$error .= "the cmd line switch -server_path is undefined!\n";
}
unless ( defined $version) {
	$warn .= "the cmd line switch -version is undefined (set to 0.01)!\n";
	$version = "0.01";
}
unless ( defined $module) {
	$error .= "the cmd line switch -module is undefined!\n";
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
	$errorMessage = \' \' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for configure.pl

   -server_path   :the location, where the server would lie
   -version       :the version of the lig ( default 0.01)
   -module        :the name of this lib

   -help           :print this help
   -debug          :verbose output
   

"; 
}

my ( $task_description );

$task_description .= \'configure.pl\';
$task_description .= " -server_path $server_path" if (defined $server_path);
$task_description .= " -version $version" if (defined $version);
$task_description .= " -module $module" if (defined $module);

my $plugin_path = "$FindBin::Bin";

my $str = 
"SERVER_PATH = $server_path
VERSION = $version
MODULE = $module

install:
\tperl -I \${SERVER_PATH}/lib  scripts/install.pl -install_path \${SERVER_PATH}
dist:
\ttar -cf  ../\${MODULE}_v\${VERSION}.tar ../\${MODULE}
\tgzip --best ../\${MODULE}_v\${VERSION}.tar
\t:x
\trm -rf ../\${MODULE}_v\${VERSION}.tar
";

open ( OUT ,">$plugin_path/Makefile") or die "could not create Makefile \'$plugin_path/Makefile\'\n";
print OUT $str;
close ( OUT );
print "Ready!\n";

';
}

sub __install_script {
	return "";
}
