package linear_regression;
#  Copyright (C) 2010-10-28 Stefan Lang

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

use FindBin;
use lib "/../lib/";
use strict;
use warnings;
use stefans_libs::array_analysis::correlatingData::stat_test;

use base ( 'stat_test' );

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::array_analysis::regression_models::linear_regression.pm

=head1 DESCRIPTION

A lib to call Rs lm functionallity using a set of variables

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class linear_regression.

=cut

sub new{

	my ($class, $R, $debug) = @_;

	my ($self);
	unless ( defined $R){
		$R = Statistics::R->new();
	}

	$self = {
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0,
		match2number  => '(\d?\.?\d+)'
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

  	bless $self, $class  if ( $class eq "linear_regression" );

  	return $self;

}

=head remove_influence_from_dataset ( 
	{ 	'influence_data_table' => data_table, 
		'variables_data_table' => data_table, 
		'list_of_vars_to_remove' => [ <var names> ],
		'vars_to_keep' => [ <var_names>]
	} )

I will internally call the R function lm ( data_variable ~ join ( '+', @list_of_vars_to_remove )) to
remove the influence of the variables from the initial dataset.
I expect to find a subset in the influence_data_table called <samples> that will 
tag all the sample IDs in the <influence_data_table> where we have information on.
In other words, you need to have the same table headers in the two data tables.
The columns that can contain data have to be tagged by a subset in the influence_data_table
and only these columns containing data in the influence data table and those that are named in
vars_to_keep data array will be kept in the returning data_table object.

Keep in mind, that only these original data variables can be processed where we have a influence_data_table value for.

=cut

sub remove_influence_from_dataset {
	my ( $self, $hash ) = @_;
	my ($return_data_table, $normaizing_var_hash, $data_hash, $normalizing_vars, $keep_this_things);
	
	foreach ( @{$hash->{'list_of_vars_to_remove'}}){
		$normaizing_var_hash -> {$_} = 1;
	}
	$return_data_table = data_table->new();
	$hash->{'vars_to_keep'} = [] unless ( ref($hash->{'vars_to_keep'}) eq "ARRAY");
	
	## I need to get all sample headers
	my @sample_headers = @{$hash->{'influence_data_table'}->{'header'}}[$hash->{'influence_data_table'}->Header_Position('samples')];
	my $sample_hash;
	foreach ( @sample_headers ){
		$sample_hash->{$_} = 1;
	}
	unless ( scalar ( @sample_headers ) > 1 ){
		Carp::confess ( "We do not have enough data do do ANYTHING with that dataset\nSample_Names =".join( ", ",@sample_headers )."\n" );
	}
	## I need to get all correlating data points - I will convert strings into numbers!
	for ( my $i = 0; $i < @{$hash->{'influence_data_table'}->{'data'}}; $i++){
		if ( $normaizing_var_hash->{@{@{$hash->{'influence_data_table'}->{'data'}}[$i]}[0]} ){
			my $data_hash =  $hash->{'influence_data_table'}->get_line_asHash($i);
			$normalizing_vars -> { @{@{$hash->{'influence_data_table'}->{'data'}}[$i]}[0] } = 
				$self->__process_single_vars_hash ( $data_hash, $sample_hash);
		}
	}
	## and now I need to create the list of sample IDs where I have all correlating data for
	my $data = $self->__process_vars_hash_array( $normalizing_vars, $sample_hash );
	
	## now I will create the columns in the resturn dataset
	foreach ( @{$hash->{'vars_to_keep'}} ){
		$keep_this_things -> {$_} = 1;
	}
	foreach ( @{$hash->{'variables_data_table'}->{'header'}}){
		$return_data_table->Add_2_Header ( $_ ) if ( $keep_this_things->{$_} );
	}
	foreach ( @{$data->{'used_sample_order'}} ){
		$return_data_table->Add_2_Header ( $_ );
	}
	## and finally I have to calculate all the normalized values - fetching the residuals!!
	my (@data, $temp, $sample_id, $new_data_hash);
	#$hash->{'variables_data_table'}->define_subset ('sample values', $data->{'used_sample_order'} );
	
	for ( my $i = 0; $i < @{$hash->{'variables_data_table'}->{'data'}}; $i++){
		$temp = $hash->{'variables_data_table'}->get_line_asHash( $i );
		@data = ();
		$new_data_hash = {};
		foreach $sample_id (@{$data->{'used_sample_order'}} ){
			$data[@data] = $temp ->{$sample_id};
		}
		@data = @{$self->_normalize_dataset( {'data_values' => \@data, 'normalizing_values' => $data->{'conditional_vars'}})};
		foreach ( @{$hash->{'vars_to_keep'}} ){
			$new_data_hash->{$_} = $temp->{$_};
		}
		for (my $a = 0; $a < @{$data->{'used_sample_order'}}; $a ++ ){
			$new_data_hash->{@{$data->{'used_sample_order'}}[$a]} = $data[$a];
		}
		$return_data_table -> AddDataset( $new_data_hash );
	}
	
 	return $return_data_table;
}

=head2 _normalize_dataset ( {
	'data_values' => [], 
	'normalizing_values' => $self->conditional_vars()-> {'conditional_vars'} 
})

Here we will call R to get the residuals after removing a 
linear influence of the variables stored in 'normaluzing_values' from the 'data_values'.
You will get the exact same array back as you send me in 'data_values',
but contaning now the residuals.

=cut

sub _normalize_dataset {
	my ( $self, $hash ) = @_;
	
	$self->{'last_command'} = $self->_createRvariable_fromArrayRef ( 'data', $hash->{'data_values'})."\n";
	my $norm_statement = 'result <- lm( data ~';
	foreach my $key ( keys %{$hash->{'normalizing_values'}}){
		$norm_statement .= " $key +";
		$self->{'last_command'} .= $self->_createRvariable_fromArrayRef ( $key , $hash->{'normalizing_values'} ->{$key} )."\n";
	}
	chop ($norm_statement);
	$norm_statement .= ")";
	$self->{'last_command'} .= $norm_statement."\ninformation <- resid (result)\nprint ( information )\n ";
	
	print $self->{'last_command'} if ( $self->{'debug'} );
	
	#print "We try to forceRunningR()\n";
	$self->forceRunningR();
	#print "Done - now we send the cmd\n";
	$self->{R}->send($self->{'last_command'});
	unless ( $self->{R}->is_started() ) {
		$self->forceRunningR();
		$self->{R}->send($self->{'last_command'});
	}
	#print "And now we try to read the result\n";
	my $return = $self->{R}->read();
	#print "we got the initial R result '$return'\n";
	## And now I need to parse the results!
	# the parse data looks like that:
	#           1           2           3           4           5           6 
	# -0.21115808 -0.21115808 -0.11169844 -0.17413176  0.11154629 -0.08115895
	#           7           8           9          10          11          12 
 	#  0.11641033  0.02289543  0.20424631  0.28478753  0.28478753  0.26451649 
 	# the second line is the data that we do want!
 	my @return;
 	$return = [ split("\n", $return)];
 	for ( my $i = 1; $i < @$return; $i+=2){
 		#print "we will parse the data line nr $i: '@$return[$i]'";
 		push ( @return, split(" ",@$return[$i]));
 	}
 	unless ( scalar ( @return) > 0){
 		warn "we could not parse any data from this R result:\n".join("\n",@$return)."\nhaving called that cmd:\n$self->{'last_command'}";
 	}
	return \@return;
}


sub _get_fitted_values {
	my ( $self, $hash ) = @_;
	
	$self->{'last_command'} = $self->_createRvariable_fromArrayRef ( 'data', $hash->{'data_values'})."\n";
	my $norm_statement = 'result <- lm( data ~';
	foreach my $key ( keys %{$hash->{'normalizing_values'}}){
		$norm_statement .= " $key +";
		$self->{'last_command'} .= $self->_createRvariable_fromArrayRef ( $key , $hash->{'normalizing_values'} ->{$key} )."\n";
	}
	chop ($norm_statement);
	$norm_statement .= ")";
	$self->{'last_command'} .= $norm_statement."\ninformation <-  fitted.values (result)\nprint ( information )\n ";
	
	print $self->{'last_command'};# if ( $self->{'debug'} );
	
	$self->forceRunningR();
	print "we forceds to be running once!\n";
	$self->{R}->send($self->{'last_command'});
	print "The command has been set\n";
	unless ( $self->{R}->is_started() ) {
		$self->forceRunningR();
		print "we will now send the command!\n";
		$self->{R}->send($self->{'last_command'});
		print "Done?? \n";
	}
	print "we now try to read!\n";
	my $return = $self->{R}->read();
	#print "we got the initial R result '$return'\n";
	## And now I need to parse the results!
	# the parse data looks like that:
	#           1           2           3           4           5           6 
	# -0.21115808 -0.21115808 -0.11169844 -0.17413176  0.11154629 -0.08115895
	#           7           8           9          10          11          12 
 	#  0.11641033  0.02289543  0.20424631  0.28478753  0.28478753  0.26451649 
 	# the second line is the data that we do want!
 	my @return;
 	$return = [ split("\n", $return)];
 	for ( my $i = 1; $i < @$return; $i+=2){
 		#print "we will parse the data line nr $i: '@$return[$i]'";
 		push ( @return, split(" ",@$return[$i]));
 	}
 	unless ( scalar ( @return) > 0){
 		warn "we could not parse any data from this R result:\n".join("\n",@$return)."\nhaving called that cmd:\n$self->{'last_command'}";
 	}
	return \@return;
}

=head2 __process_vars_hash_array ( $normalizing_vars, $sample_hash)

This function will check every dataset in the $normalizing_vars array for the existance of 
the samples, that are stored in $sample_hash.

At the end you will get the normalizing_vars back - but all entries, that are not present in ALL 
the sample hashes will be removed. In addition you will get two lists, one containing all usable 
sample ids and one including all samples, that have to be removed from the analysis.

=cut
sub __process_vars_hash_array {
	my ( $self,  $normalizing_vars, $sample_hash) = @_;
	my ( $usable_samples, $sampleID, $condition_count, @dropped_samples, @used_samples, $condition );
	## first count how many times we have each sample!
	foreach $condition ( keys %$normalizing_vars ){
		foreach $sampleID ( keys %{$normalizing_vars->{$condition}}){
			$usable_samples->{$sampleID} = 0 unless ( defined $usable_samples->{$sampleID});
			$usable_samples->{$sampleID} ++;
		}
	}
	$condition_count = scalar(keys %$normalizing_vars);
	## next we need to remove all samples, that ere not found in every condition
	foreach $sampleID (sort keys %$usable_samples ){
		if ( $usable_samples->{$sampleID} < $condition_count){
			delete $sample_hash->{$sampleID};
			push ( @dropped_samples, $sampleID);
		}
		else {
			push ( @used_samples, $sampleID);
		}
	}
	## and now we need to create the {condition => [<sample_values>]} return dataset
	my $return = {};
	foreach $condition ( keys %$normalizing_vars ){
		$return->{$condition} = [];
		foreach $sampleID ( @used_samples ){
			Carp::confess ( ref($self)." during the processing of the conditional variables: \n".
				"We were unable to remove the sampleID $sampleID from the sample_hash \n".
				"although this sample is missing in the conditional variable $condition\n") unless ( defined $sample_hash->{$sampleID});
			push ( @{$return->{$condition}}, $normalizing_vars->{$condition}->{$sampleID});
		}
	}
	## done with EVERYTHING!
	return { 'conditional_vars' => $return, 'used_sample_order' => \@used_samples, 'dropped_samples' => \@dropped_samples};
}

=head2 __process_single_vars_hash ( $var_hash, $usable_keys_hash )

This function will remove all variables from the $usable_keys_hash (keys) that are not defrined in the $var_hash dataset.
Un addition, this function will convert putative strings in the variable definition int integers ranging from 1 to infinite.

=cut

sub __process_single_vars_hash {
	my ( $self, $var_hash, $usable_keys_hash ) = @_;
	my $stings = {};
	my $i = 1;
	foreach my $key ( keys %$var_hash) {
		unless ( $usable_keys_hash->{$key}){
			delete $var_hash->{$key} ;
			next;
		}
		unless ( $var_hash->{$key} =~ m/\w/ ){
			delete $var_hash->{$key} ;
			next;
		}
		unless ( $var_hash->{$key} =~ m/^ *(\d?\.?\d+e?-?\d*) */ ){
			unless ( defined $stings->{$var_hash->{$key}}){
				$stings->{$var_hash->{$key}} = $i++;
			}
			$var_hash->{$key} = $stings->{$var_hash->{$key}};
		}
	}
	return $var_hash;
}

1;
