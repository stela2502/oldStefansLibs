package stefans_libs_Address_Parser;

#  Copyright (C) 2012-04-26 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;

use stefans_libs::Latex_Document::Text;
use stefans_libs::flexible_data_structures::data_table;
use WWW::Mechanize;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_Address_Parser

=head1 DESCRIPTION

A small tool to help the address parsing for the university pages.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_Address_Parser.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {};

	bless $self, $class if ( $class eq "stefans_libs_Address_Parser" );

	return $self;

}

sub __select_string {
	return '\wøóæëäöγüÄÖÅÜØáåéð';
}

=head2 get_web_page ( $link, $filename )

=cut

sub get_web_page {
	my ( $self, $link, $filename ) = @_;
	my $error = '';
	$error .= "I miss the link - I can not get the file fropm the web!\n"
	  unless ( defined $link );
	$error .= "I miss the filename - I can not get the file fropm the web!\n"
	  unless ( defined $filename );
	Carp::confess($error) if ( $error =~ m/\w/ );
	return $filename if ( -f $filename);

	system("wget -O $filename $link");
	unless ( -f "$filename" ) {
	my $Mech = WWW::Mechanize->new( 'stack_depth' => 2 );
	$Mech->get($link);
	open( OUT, ">$filename" )
	  or die "I could not create the temp file '$filename'!\n$!\n";
	print OUT $Mech->content();
	close(OUT);
	}
	unless ( -f "$filename" ) {
		die "I could not fetch the file from the internet!\n";
	}
	return $filename;
}

=head2 parse_file(
	{
		'filename'      => $filename,
		'searchdef' => {
			'forename' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'surname' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'title' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'company' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'WORK_telephone' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'FAX_telephone' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'WORK_email' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'web_page' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'description' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'address' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'MOBILE_telephone' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
			'web_page' => {
				'line_select' => 'RegExp', # in case you do not want to check every line
				'value_select' => 'RegExp', #giving back one (!) varaiable
				'test' => 'RegExp', #an optional test
			},
		},
		'functions'  => { ## the functions can be used to create different variables from an initial pattern match
			'source variable name' => {
				'do not overwrite' => [ <var name 1>],
				'target_vars' => [ <var name 1>, <var name 2>],
				'sub' => sub  { ##returns exactly the amount of variables I need to fill 'target_vars' }
			}
		}
	} , $debug
);

This function requires a filename and a definition of what to search for
and where to sore the data in. By default it will create a address file,
which is a tab separated text table with the column headers : 
'forename', 'surname', 'title', 'company', 'WORK_telephone', 'FAX_telephone',
'WORK_email', 'web_page', 'description', 'address', 'MOBILE_telephone', 'web_page'

Values without RegExp will not be searched for!

The function:
The file is opened and each line is searched for each 'searchdef'. 
If there is a 'line_select' this RegExp will be evaluated first.
If positive the 'value_select' will be executed and if that one is also positive,
the 'functions' will be checked for a match to the positively evaluated 'searchdef' key.
If you have defined a function to process the match, the 'searchdef' key will NOT be added 
to the table object; instead, the 'target_vars' array of the function will used as
variable names. The 'sub' will be applied to the initial result of the RegExp.

Finally you get the data_table with the matches back.

=cut

sub parse_file {
	my ( $self, $hash, $debug ) = @_;
	unless ( -f $hash->{'filename'}) {
		Carp::confess ( "Sorry, but without filename I will not even start to do anything!". root::get_hashEntries_as_string ( $hash , 5 , "the variables" ));
	}
	my $data_table = data_table->new();
	foreach ( 'forename', 'surname', 'title', 'company', 'WORK_telephone', 'FAX_telephone',
'WORK_email', 'web_page', 'description', 'address', 'MOBILE_telephone', 'web_page') {
	$data_table->Add_2_Header($_);
	}
	my ( $var_name, $def, $datahash, @temp, $target_vars, $this_variable, $text_obj, $line, $do_not_overwrite );
	$text_obj             = stefans_libs::Latex_Document::Text->new();
	open ( DATA, "<$hash->{'filename'}" ) or die "Could not open filename '$hash->{'filename'}'\n$!\n";
	while ( <DATA> ){
		$line = $_;
		$line = $text_obj->convert_coding( $line, 'html','text' );
		foreach $var_name ( %{$hash->{'searchdef'}}) {
			$def = $hash->{'searchdef'}->{$var_name};
			next unless ( defined $def->{'value_select'});
			if ( defined $def->{'line_select'} ){
				next unless ($line =~m/$def->{'line_select'}/) ;
				print "line_select for varaiable $var_name identified line $line" if ( $debug); ##OK
				## Now I try to identify the real value!
				if ( $line =~ m/$def->{'value_select'}/){
					$this_variable = $1;
					print "And we have identified the value as '$this_variable'\n" if ( $debug );
					if ( defined $hash->{'functions'}->{$var_name}) {
						print "We got a function for the match!\n" if ( $debug );
						$target_vars = $hash->{'functions'}->{$var_name}->{'target_vars'};
						@temp = &{$hash->{'functions'}->{$var_name}->{'sub'}}( $this_variable );
						$do_not_overwrite = {};
						if ( ref($hash->{'functions'}->{$var_name}->{'do not overwrite'}) eq "ARRAY"){
							foreach (@{$hash->{'functions'}->{$var_name}->{'do not overwrite'}}) {
								$do_not_overwrite -> { $_ } = 1;
							}
						}
						for ( my $i = 0; $i < @$target_vars; $i++ ){
							next unless ( $temp[$i] =~m/\w/ );
							unless ( $do_not_overwrite->{@$target_vars[$i]}) {
								$datahash = $self->__check_hash ( $datahash, @$target_vars[$i], $data_table);
								$datahash->{@$target_vars[$i]} = $temp[$i];
							}
							else {
								$datahash->{@$target_vars[$i]} .= $temp[$i];
							}
							
							print "We define the variable '@$target_vars[$i]' as '$temp[$i]'\n" if ( $debug );
						}
					}
					else {
						$datahash = $self->__check_hash ( $datahash, $var_name, $data_table);
						$datahash->{$var_name} = $this_variable;
						print "We define the variable '$var_name' as '$this_variable'\n" if ( $debug );
					}
				}
				else {
					print "Sorry I did not match '$def->{'value_select'}'\n" if ( $debug );
				}
			}
		}
	}
	close ( DATA);
	return $data_table;
}


sub __check_hash {
	my ( $self, $hash, $varname, $data_table ) = @_;
	if ( defined $hash->{$varname} ) {
		return $hash unless ( $hash->{$varname} =~m/\w/);
		$data_table -> AddDataset ( $hash );
		#die root::get_hashEntries_as_string ( $hash , 3 , "I have added the first dataset because I found a '$varname' entry!\n" );
		$hash = {};
	}
	
	return $hash;
}

1;
