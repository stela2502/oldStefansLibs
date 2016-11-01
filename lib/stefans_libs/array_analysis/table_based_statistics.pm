package stefans_libs_array_analysis_table_based_statistics;

#  Copyright (C) 2011-12-14 Stefan Lang

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

use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::array_analysis::table_based_statistics::group_information;
use stefans_libs::array_analysis::correlatingData::QQplot;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_array_analysis_table_based_statistics

=head1 DESCRIPTION

This lib will create from a table including data and one including a grouping shema a list of project files that can be inserted into the project worker.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_array_analysis_table_based_statistics.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'                => $debug,
		'Do_not_run_automatic' => 1,
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_array_analysis_table_based_statistics" );

	return $self;

}

=head2 AddPath ($path)

With this function you can define the path to store the project files.
This function has to be used before you try to get any project!

=cut

sub AddPath {
	my ( $self, $path ) = @_;
	return -1 unless ( defined $path );
	unless ( -d $path ) {
		mkdir($path) or die "I could not create the outpath '$path\n$!\n";
	}
	$self->{'__path__'} = $path;
}

=head2 Path($path)

Simple accessor for the path - if you specify a path the path will be changed!

=cut

sub Path {
	my ( $self, $path ) = @_;
	$self->AddPath($path) if ( defined $path );
	return $self->{'__path__'};
}

=head2 GetStatProjects ( {
	'data_table' => <a data containing table>
	'grouping_table' => <the grouping table>
})

The data table has to contain the columns 'Probe Set ID' and 'Gene Symbol'.
The statistics system might work without, but you loose the information about the results if I do not have these columns!

=cut 

sub GetStatProjects {
	my ( $self, $hash ) = @_;
	my $error = '';
	$error .= "I need to get a 'grouping_table'!\n"
	  if ( !defined $hash->{'grouping_table'}
		&& !defined $self->{'group_data'} );
	$error .= "I need a 'data_table'\n"
	  unless ( defined $hash->{'data_table'} );
	Carp::confess($error) if ( $error =~ m/\w/ );
	$self->__process_group_file( $hash->{'grouping_table'} )
	  if ( defined $hash->{'grouping_table'} );

	## OK - now I do really need to do some work!
	my (
		$group_definition_hash, $actual_definition_hash,
		@ordered_group_names,   @output_columns,
		$translate_columns,     $group_name,
		$COMPARISON, @return, $temp, @not_complete_sets,

		$groups, $return,
		$i,      $row,
		$use_this_columns, $all_values, $dataset, $data_table
	);
	$groups     = $self->{'group_data'}->GetGroups();
	$data_table = data_table->new();
	$data_table->read_file( $hash->{'data_table'} );
	my $phenotypes;
	unless ( ref( $hash->{'phenotypes'} ) eq "ARRAY" ) {
		warn "I have not got an phenotype list!\n!";
		foreach ( keys %$groups ) {
			$phenotypes->{$_} = 1;
		}
	}
	elsif ( !defined @{ $hash->{'phenotypes'} }[0] ) {
		warn "I have not got an phenotype list!\n!";
		foreach ( keys %$groups ) {
			$phenotypes->{$_} = 1;
		}
	}
	else {
		print "I am processing the phenotype list '"
		  . join( "' '", @{ $hash->{'phenotypes'} } ) . "'\n";
		foreach ( @{ $hash->{'phenotypes'} } ) {
			$phenotypes->{$_} = 1;
		}
	}

	#Carp::confess ( "we have this data table:\n".$data_table->AsString());
	foreach $COMPARISON ( keys %$groups ) {
		unless ( defined $phenotypes->{$COMPARISON} ) {
			warn "I do not process the phenotype '$COMPARISON'\n";
			next;
		}
		print "I process the phenoptype '$COMPARISON'\n";
		@not_complete_sets     = ();
		$group_definition_hash = $groups->{$COMPARISON};
		## I need to create the table!
		my $this_data_table;
		$i                = 1;
		$use_this_columns = {};
		if ( $group_definition_hash->{'stat_type'} eq "linear" ) {
			@ordered_group_names = (
				sort { $a <=> $b }
				  keys %{ $group_definition_hash->{'groups'} }
			);
		}
		else {
			@ordered_group_names =
			  ( sort keys %{ $group_definition_hash->{'groups'} } );
		}

		@output_columns  = ();
		$this_data_table = data_table->new();
		$this_data_table->Add_2_Header('Probe Set ID');
		$this_data_table->Add_2_Header('p');
		$this_data_table->Add_2_Header('statistics');
		$translate_columns      = {};
		$actual_definition_hash = $group_definition_hash->{'groups'};
		for ( my $i = 0 ; $i < @ordered_group_names ; $i++ ) {
			$group_name = $ordered_group_names[$i];
			my $row = 1;
			foreach
			  my $column_name ( @{ $actual_definition_hash->{$group_name} } )
			{
				$translate_columns->{$column_name} =
				  "G" . ( $i + 1 ) . "R" . $row++;
				$this_data_table->Add_2_Header($column_name);
			}
		}
		for ( my $line = 0 ; $line < $data_table->Lines() ; $line++ ) {
			$all_values = $data_table->get_line_asHash($line);
			$dataset    = {};
			$temp       = 1;
			foreach ( keys %$all_values ) {
				if ( defined $this_data_table->Header_Position($_) ) {
					$dataset->{$_} = $all_values->{$_};
					next if ( $this_data_table->Header_Position($_) == 0 );
					unless ( $dataset->{$_} =~ m/\d/ ) {
						$temp = 0;

			  #warn "the column '$_' does not contain a digit on line $line!\n";
					}

				}
			}
			$dataset->{'p'}          = 100.11;
			$dataset->{'statistics'} = 100.11;
			if ($temp) {
				$this_data_table->AddDataset($dataset);
			}
			else {

				push( @not_complete_sets,
					"@{@{$data_table->{'data'}}[$i]}[0]" );
			}

		}
		foreach ( keys %$translate_columns ) {
			$this_data_table->Rename_Column( $_, $translate_columns->{$_} );
		}
		$this_data_table->{'no_doubble_cross'} = 1;
		## Now I have
		## an array containing an ordered list of group labels @ordered_group_names
		## a has linking the original group names to the group names in the R table $translate_columns
		## a group description in $actual_definition_hash->{<@ordered_group_names>}= []
		## and the R_ table $this_data_table

		## I need to create the R script!

		## I support three options:
		my ( $r_call, $optional_modifications, $test );
		$optional_modifications = '';
		## A linear correlation using spearman
		if ( $group_definition_hash->{'stat_type'} eq "linear" ) {
			$test = 'spearman';
			my $correlating_data_array = [];
			$optional_modifications = "z <- c (";
			foreach (@ordered_group_names) {
				foreach my $column_name ( @{ $actual_definition_hash->{$_} } ) {
					$optional_modifications .= "$_, ";
					push( @$correlating_data_array, $_ );
				}
			}
			$optional_modifications =~ s/, $//;
			$optional_modifications .= ")";
			$r_call = " cor.test( z, c(";
			foreach (@ordered_group_names) {
				foreach my $column_name ( @{ $actual_definition_hash->{$_} } ) {
					$r_call .=
					  'table[x,' . $translate_columns->{$column_name} . '], ';
				}
			}
			$r_call =~ s/, $//;
			$r_call .= ") ,method='spearman')
			table[x,2] <- res[3]
			table[x,3] <-res[4]";
			$this_data_table->Add_2_Description( "Correlating data in order:\t"
				  . join( ";", @$correlating_data_array ) );

#Carp::confess ( "I should have the correlation data in the description here (".join(";",@$correlating_data_array).": \n".$this_data_table->AsString());
			$this_data_table->Rename_Column( 'statistics', 'spearman rho' );
		}
		## B two group comparison using Wilcox signed rank
		elsif ( scalar(@ordered_group_names) == 2 ) {
			if ( !defined $hash->{'data_type'} ) {
				$test = 'wilcox';
			}
			elsif ( $hash->{'data_type'} eq "non_parametric" ) {
				$test = 'wilcox';
			}
			elsif ( $hash->{'data_type'} eq "parametric" ) {
				##Carp::confess ( "We have a student-t here!\n");
				$test = 'student-t';
			}
			else {
				Carp::confess(
"Sorry, but a two grpoups comparison with the 'data_type' $group_definition_hash->{'data_type'} is not defined!\n"
				);
			}
			if ( $test eq 'wilcox' ) {
				$r_call = 'wilcox.test( ';
				foreach (@ordered_group_names) {
					$r_call .= "c(";
					foreach
					  my $column_name ( @{ $actual_definition_hash->{$_} } )
					{
						$r_call .= 'table[x,'
						  . $translate_columns->{$column_name} . '], ';
					}
					$r_call =~ s/, $//;
					$r_call .= "), ";
				}
				$r_call .=
				    'exact = 0, '
				  . $group_definition_hash->{'pairedTest'} . ")\n"
				  . 'table[x,2] <- res[3]' . "\n";
				$r_call .= 'table[x,3] <- res[1]' . "\n";
				$this_data_table->Add_2_Description( "in order group names:\t"
					  . join( ";", @ordered_group_names ) );
				$this_data_table->Rename_Column( 'statistics', 'Wilcoxon W' );
			}
			elsif ( $test eq 'student-t' ) {
				$r_call = 't.test( ';
				foreach (@ordered_group_names) {
					$r_call .= "c(";
					foreach
					  my $column_name ( @{ $actual_definition_hash->{$_} } )
					{
						$r_call .= 'table[x,'
						  . $translate_columns->{$column_name} . '], ';
					}
					$r_call =~ s/, $//;
					$r_call .= "), ";
				}
				$r_call .=
				    'exact = 0, '
				  . $group_definition_hash->{'pairedTest'} . ")\n"
				  . 'table[x,2] <- res[3]' . "\n";
				$r_call .= 'table[x,3] <- res[1]' . "\n";
				$this_data_table->Add_2_Description( "in order group names:\t"
					  . join( ";", @ordered_group_names ) );
				$this_data_table->Rename_Column( 'statistics', 't-statistic' );
			}
		}
		## C multi group comparison using Kruskal Wallis statisti
		else {
			$test   = 'kruskal wallis';
			$r_call = 'kruskal.test( list (';
			foreach (@ordered_group_names) {
				$r_call .= "c(";
				foreach my $column_name ( @{ $actual_definition_hash->{$_} } ) {
					$r_call .=
					  'table[x,' . $translate_columns->{$column_name} . '], ';
				}
				$r_call =~ s/, $//;
				$r_call .= "), ";
			}
			$r_call =~ s/, $//;
			$r_call .= ' ) )
			table[x,2] <- res[3]
			table[x,3] <- res[1]';
			$this_data_table->Add_2_Description(
				"in order group names:\t" . join( ";", @ordered_group_names ) );
			$this_data_table->Rename_Column( 'statistics',
				'Kruskal-Wallis chi-squared' );
		}
		my $rscript =
		    'library(data.table)'
		  . "#Analysis for the comparison $COMPARISON using a $test statistics\n"
		  . 'myfct <- function( table ) {
 ' . $optional_modifications . '
 for ( x in 1:' . $this_data_table->Lines . ') {
  res <- ' . $r_call . '
 }
 return(table)
}
tt <- read.table ( "table.xls", sep="\t", header=T)
TT <- data.table(tt)
tt <- myfct ( TT )
write.table (tt, file="results.xls",sep="\t" )
';
		## I create a tar file from that and write it to the outpath
		chdir( $self->Path() );
		foreach (qw(script.R table.xls results.xls outfile.log)) {
			unlink($_);
		}
		$this_data_table->write_file("./table");
		open( R, ">script.R" )
		  or die "I could not create the file script.R!\n$!\n";
		print R $rscript;
		close(R);
		$COMPARISON =~ s/\//_/g;
		$COMPARISON =~ s/\&/_/g;
		$COMPARISON =~ s/ /_/g;

		if ( $self->{'Do_not_run_automatic'} ) {
			warn "I will not calculate anything here!\n";
		}
		else {
			system("R CMD BATCH script.R outfile.log");
		}

		if ( defined $not_complete_sets[0] ) {
			open( ERR, ">not_complete_datasets.txt" );
			print ERR "We have not gotten a whole dataset for probesets "
			  . scalar(@not_complete_sets)
			  . " probe-sets. Namely:\n"
			  . join( "\n", @not_complete_sets ) . "\n";
			close ERR;
			system(
"tar -cf $COMPARISON.tar script.R table.xls results.xls outfile.log not_complete_datasets.txt"
			);
		}
		else {
			system(
"tar -cf $COMPARISON.tar script.R table.xls results.xls outfile.log"
			);
		}
		if ( defined $hash->{'execution_log'} ) {
			open( LOG, ">statistics_file_creation.log" );
			print LOG $hash->{'execution_log'} . "\n";
			close(LOG);
			system(
				"tar -f $COMPARISON.tar --append statistics_file_creation.log");
		}

		## then I push the tar file into my retrun array
		push( @return, $self->Path() . "/$COMPARISON.tar" );
		$this_data_table = undef;
	}
	return @return;
}

=head2 create_QQ_plot ( $results_archive, $task_description )

=cut

sub create_QQ_plot {
	my ( $self, $results_archive, $task_description ) = @_;
	unless ( defined $self->{'QQplot'} ) {
		$self->{'QQplot'} =
		  stefans_libs_array_analysis_correlatingData_QQplot->new();
	}
	my $variables_table = $self->_get_purged_results_table($results_archive);

#	unless ( defined $variables_table->Header_Position('Wilcoxon W') ) {
#		warn
#"Sorry, but this file is no Wilcox test result ('$results_archive')\n";
#		foreach (
#			qw(purged_results.xls qvalues.R outfile_q.log p_array.txt q_array.txt QQplot.png)
#		  )
#		{
#			unlink($_) unless ( $self->{'debug'} );
#		}
#		return 0;
#	}
	$variables_table =
	  $variables_table->select_where( 'p',
		sub { return 1 if $_[0] =~ m/\d/; return 0; } );
	my ( $groupA, $groupB, $tmp );
	$groupA = $groupB = 0;
	$tmp = @{ $variables_table->Description('Samples_Columns:') }[0];
	$tmp =~ s/Samples_Columns:\s?//;
	foreach ( split( ";", $tmp ) ) {
		$groupA++ if ( $_ =~ m/G1/ );
		$groupB++ if ( $_ =~ m/G2/ );
	}
	my $title = $results_archive;
	$title =~ s!/.+/!!;
	$title =~ s/\.tar//;
	if ( defined $variables_table->Header_Position('Wilcoxon W') ) {
		$self->{'QQplot'}->qq_plot(
			{
				## for creating W plots
				## 'random_dist' => 'x <- rwilcox ( '
				##  . scalar( $variables_table->Lines() )
				##  . ",$groupA, $groupB )",
				'random_dist' => ' pwilcox( rwilcox ( '
				  . scalar( $variables_table->Lines() )
				  . ",$groupA, $groupB ), $groupA, $groupB )",
				#'values'   => $variables_table->getAsArray('Wilcoxon W'),
				'values'   => $variables_table->getAsArray('p'),
				'outpath'  => $self->Path(),
				'filename' => "QQplot.png",
				'title'    => $title
			}
		);
	}
	elsif ( defined $variables_table->Header_Position('t statistic') ) {
		$self->{'QQplot'}->qq_plot(
			{
				# 2*pt(-abs(rt(33297,df=7)),df=7)
				'random_dist' => ' 2*pt(-abs(rt('
				  . scalar( $variables_table->Lines() ) . ',df='
				  . ( ($groupA + $groupB)/2 -1 ) . ')),df='
				  . ( ($groupA + $groupB)/2 -1  )
				  . ')',
				    #'values'   => $variables_table->getAsArray('t statistic'),
				'values'   => $variables_table->getAsArray('p'),
				'outpath'  => $self->Path(),
				'filename' => "QQplot.png",
				'title'    => $title
			}
		);
	}
	else {
		Carp::confess(
"Sorry, but I do not know which kind of random p distribution to use here!\n"
			  . "Neither a Wilcox test ('Wilcoxon W') nor a Students T test ('t.statistic') were detected!\n"
			  . "'"
			  . join( "', ", @{ $variables_table->{'header'} } )
			  . "'\n" );
	}
	open( LOG, '>QQplot.R' )
	  or die "I could not open the log file 'QQplot.R'\n$!\n";
	print LOG $self->{'QQplot'}->{'last_cmd'} . "\n";
	close(LOG);
	$self->_add2_tar_after_task( $results_archive, $task_description,
		"QQplot.png", "QQplot.R" );

	foreach (
		qw(purged_results.xls qvalues.R outfile_q.log p_array.txt q_array.txt QQplot.png QQplot.R)
	  )
	{
		unlink($_) unless ( $self->{'debug'} );
	}
	return 1;
}

=head2 calculate_FDR ( $results_archive, $algo, $task_description )

This function will call the R function p.adjust using the $algo algorithm.
The function will modify the purged_results.xls files in the tar results_archive
and add a q_value column to them next to the p-value column (p).

=cut

sub _get_purged_results_table {
	my ( $self, $results_archive ) = @_;
	chdir( $self->Path() );
	unlink('purged_results.xls')
	  ;  # just in case we have an old file here and no new file in the archive!
	system("tar -xf $results_archive");
	unless ( -f 'purged_results.xls' ) {
		warn "I could not find the "
		  . $self->Path()
		  . "/purged_results.xls file that should be part of the tar archive '$results_archive'\n";
		return 0;
	}
	my $values_table = data_table->new();
	$values_table->read_file('purged_results.xls');
	return $values_table;
}

sub _add2_tar_after_task {
	my ( $self, $results_archive, $task_description, @file_list ) = @_;
	open( LOG, ">>outfile_q.log" )
	  or die "I could not add to the log file 'outfile_q.log'\n$!\n";
	print LOG $task_description . "\n";
	close(LOG);
	foreach ( @file_list, 'outfile_q.log' ) {
		system("tar --delete $_ -f $results_archive") if ( -f $_ );
	}
	my @OK;
	foreach ( @file_list ){
		push ( @OK, $_ ) if ( -f $_);
	}
	system( "tar -r "
		  . join( " ", @OK )
		  . " outfile_q.log -f $results_archive" ) if ( defined $OK[0]);
	return 1;
}

sub calculate_FDR {
	my ( $self, $results_archive, $algo, $task_description ) = @_;
	my ( $values_table, $q_position, $temp, @q_values );
	$values_table = $self->_get_purged_results_table($results_archive);
	$values_table->drop_subset('___DATA___');
	## Now I need to get the p values into a file that can be fead into R
	unless ( defined $values_table->Header_Position('p') ) {
		Carp::Confess( "Sorry, but the file "
			  . $self->Path()
			  . "/purged_results.xls does not contain a 'p' column!\n" );
	}
	open( "OUT", ">p_array.txt" )
	  or die "I could not create the file 'p_array.txt'\n$!\n";
	my $array = $values_table->get_column_entries('p');
	for ( my $i = 0 ; $i < scalar(@$array) ; $i++ ) {
		@$array[$i] = 1 unless ( @$array[$i] =~ m/\d/ );
	}
	print OUT join( " ", @$array );
	close(OUT);
	open( R, ">qvalues.R" )
	  or die "I could not create the file 'qvalues.R'\n$!\n";
	print R
"data <- scan('p_array.txt')\nq_values <-  p.adjust(data, method = '$algo')\ncat(q_values , file='q_array.txt', sep=' ' )\n";
	close(R);
	system("R CMD BATCH qvalues.R outfile_q.log");
	$q_position = $values_table->Add_2_Header( 'q_value (' . $algo . ')' );
	open( IN, "<q_array.txt" )
	  or die "I could not read from the q_array.txt data file!\n$!\n";

	foreach (<IN>) {
		chomp($_);
		push( @q_values, split( " ", $_ ) );
	}
	close(IN);
	Carp::confess(
"I have an missmatch between the expected and the recieved number of q_values( exp="
		  . $values_table->Lines()
		  . "; rec = "
		  . scalar(@q_values)
		  . ")\nfor infile '$results_archive'\n" )
	  unless ( $values_table->Lines() == scalar(@q_values) );
	for ( my $i = 0 ; $i < $values_table->Lines() ; $i++ ) {
		@{ @{ $values_table->{'data'} }[$i] }[$q_position] = $q_values[$i];
	}
	unlink( $self->Path() . '/purged_results.xls' );
	$values_table->write_file( $self->Path() . '/purged_results', undef );
	$self->_add2_tar_after_task(
		$results_archive,     $task_description,
		'purged_results.xls', 'qvalues.R'
	);
	foreach (
		qw(purged_results.xls qvalues.R outfile_q.log p_array.txt q_array.txt))
	{
		unlink($_) unless ( $self->{'debug'} );
	}
	print "FDR Calculation processed the file '$results_archive'\n";
	return 1;
}

=head2 process_result_file ( $file )

This function will use the resulting tar file to regenerate a usefull dataset.
After this conversion you need to add the description values to the result file.

=cut

sub process_result_file {
	my ( $self, $file, $description_file, $log_information ) = @_;
	## R wirtes a stupid data file that has one column more than it should!
	chdir( $self->Path() );
	foreach (qw(script.R table.xls results.xls outfile.log)) {
		unlink($_);
	}
	system("tar -xf $file");
	unless ( -f 'results.xls' ) {
		warn "I could not find the "
		  . $self->Path()
		  . "/results.xls file that ahould be part of the tar file '$file'\n";
		return 0;
	}
	open( IN,  "<results.xls" );
	open( OUT, ">purged_results.xls" )
	  or die "I could not create the outfile 'purged_results.xls'\n$!\n";
	my $first = 1;
	while ( my $line = <IN> ) {
		if ($first) {
			$line =~ s/\./ /g;
			$first = 0;
		}
		if ( $line =~ m/^"\d+"\t/ ) {
			$line =~ s/^"\d+"\t//;
		}
		$line =~ s/"//g;
		print OUT $line;
	}
	close(IN);
	close(OUT);
	my $values_table = data_table->new();
	$values_table->read_file('purged_results.xls');

#Carp::confess ( print root::get_hashEntries_as_string ($values_table->{'header'}   , 3 ,  "I would try to look at the headers of the statistics results table 3 to ".($values_table->Columns - 1 ), 300 ));
	$values_table->Add_2_Description(
		'Samples_Columns:'
		  . join( ";",
			@{ $values_table->{'header'} }
			  [ 3 .. ( $values_table->Columns - 1 ) ] )
	);
	my $description = data_table->new();
	$description->read_file($description_file);
	$values_table = $description->merge_with_data_table($values_table);
	## I need to fetch the desciptions from the table.xls file - probably
	if ( defined $values_table->Header_Position('spearman rho') ) {
		open( IN, "<table.xls" )
		  or die "I could not open the table source data\n$!\n";
		foreach (<IN>) {
			if ( $_ =~ m/Correlating data in order:\t(.+)$/ ) {
				$values_table->Add_2_Description(
					"Correlating data in order:\t$1");
				last;
			}
		}
		close(IN);
	}
	else {
		open( IN, "<table.xls" )
		  or die "I could not open the table source data\n$!\n";
		foreach (<IN>) {
			if ( $_ =~ m/in order group names:\t(.+)$/ ) {
				$values_table->Add_2_Description("in order group names:\t$1");
				last;
			}
		}
		close(IN);
	}
	$values_table->write_file('purged_results.xls');

	if ( defined $log_information ) {
		open( LOG, ">purged_results.log" );
		print LOG $log_information;
		close LOG;
		system("tar -rf $file purged_results.xls purged_results.log");
	}
	else {
		system("tar -rf $file purged_results.xls");
	}
	foreach (qw(txt xls log)) {
		unlink( $self->Path() . "/*.$_" );
	}
	return $self->Path() . "/purged_results.xls";
}

=head2 the standard R script

library(data.table)
myfct <- function( table ) {
 for ( x in 1:33296 ) {
  res <- wilcox.test( c ( table[x,a], table[x,b], table[x,c], table[x,d]), c ( table[x,e], table[x,f], table[x,g], table[x,h]), exact=0 )
  table[x,2] = res[3]
  res
  x
 }
 return(table)
}
tt <- read.table ( 'table2.txt', sep="\t", header=T)
TT <- data.table(tt)
TT$result <- vector(33296, mode="numeric")
tt <- myfct ( TT )
write.table (tt, file="results.txt",sep="\t" )

=head2 __process_group_file ( filename )

This function will read the group definition in table format and process each data line 
to produce an has representation of this dataset.

=cut

sub __process_group_file {
	my ( $self, $group_file ) = @_;
	unless ( defined $self->{'group_data'} ) {
		$self->{'group_data'} =
		  stefans_libs_array_analysis_table_based_statistics_group_information
		  ->new();
	}
	return $self->{'group_data'}->AddFile($group_file);
}

1;
