package PubMed_queries;

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

use stefans_libs::database::lists::list_using_table;
use base list_using_table;
use stefans_libs::database::publications::PubMed_list;

##use some_other_table_class;

use strict;
use warnings;
use WWW::Search;
use WWW::Mechanize::GZip;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug         => $debug,
		dbh           => $dbh,
		www_search    => WWW::Search->new('NCBI::PubMed'),
		www_mechanize => WWW::Mechanize::GZip->new( 'stack_depth' => 0 )
	};
	$self->{'www_search'}->maximum_to_retrieve(10);
	bless $self, $class if ( $class eq "PubMed_queries" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "PubMed_queries";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'GeneSymbol',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'Query_time',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'query_string',
			'type'        => 'VARCHAR (300)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'results',
			'type'        => 'INTEGER',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'Publication_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'link_to' => 'list_id',
			'data_handler' => 'PubMed_list',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['query_string'] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['query_string'];
	$self->{'INDICES'}          = ['GeneSymbol'];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	$self->{'linked_list'} = $self->{'data_handler'}->{'PubMed_list'} =
	  PubMed_list->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

sub get_T2D_hit_count_4_GeneSymbol {
	my ( $self, $gene_symbol ) = @_;
	my $id = $self->_add_Pubmed_info_for_gene_and_T2D_to_database($gene_symbol);
	my $data_hash = $self->get_data_table_4_search(
		{
			'search_columns' => ['results'],
			'where'          => [ [ ref($self) . '.id', '=', 'my_value' ] ]
		},
		$id
	)->get_line_asHash(0);
	unless ( defined $data_hash ) {

   #	warn
   #"we did not get any information for the query $self->{'complex_search'}!\n";
		return undef;
	}
	return $data_hash->{'results'};
}

sub get_Targeted_count_4_GeneSymbol {
	my ( $self, $gene_symbol ) = @_;
	my $id =
	  $self->_add_Pubmed_info_for_gene_and_Targeted_to_database($gene_symbol);
	my $data_hash = $self->get_data_table_4_search(
		{
			'search_columns' => ['results'],
			'where'          => [ [ ref($self) . '.id', '=', 'my_value' ] ]
		},
		$id
	)->get_line_asHash(0);
	unless ( defined $data_hash ) {

   #	warn
   #"we did not get any information for the query $self->{'complex_search'}!\n";
		return undef;
	}
	return $data_hash->{'results'};
}

sub _add_Pubmed_info_for_gene_and_Targeted_to_database {
	my ( $self, $gene ) = @_;

	my $query_pubmed =
"[All Fields] (\"$gene -/-\" or \"$gene Knock out\") AND ( Mouse OR RAT)  NOT (\"review\"[All Fields])";
	my $id = $self->_return_unique_ID_for_dataset(
		{ 'query_string' => $query_pubmed } );
	return $id if ($id);

	my ( $url, $file );

	$self->{'www_search'}->native_query($query_pubmed);

	my @error = eval {
		$url  = $self->{'www_search'}->next_url();
		$file = $self->{'www_mechanize'}->get($url);
		$file = $file->content();
	};
	unless ( $file =~ m/\w/ ) {
		warn
"Oh we got no search web page using the url\n$self->{'www_search'}->next_url()\nError="
		  . join( ' ', @error ) . "\n";
		next;
	}
	return $self->store_Pubmed_results( $gene, $query_pubmed, $file, $url );
}

sub _add_Pubmed_info_for_gene_and_T2D_to_database {
	my ( $self, $gene ) = @_;

	my $query_pubmed =
	    $gene
	  . '[All Fields]  AND ("fat"[All Fields] OR ("insulin"[MeSH Terms] OR'
	  . ' "insulin"[All Fields] NOT "Insulin like growth factor"[All Fields]) OR T2D[All Fields] OR ("mitochondria"[MeSH Terms] OR '
	  . '"mitochondria"[All Fields]) OR ("channel"[All Fields])) NOT ("review"[All Fields])';
	my $id = $self->_return_unique_ID_for_dataset(
		{ 'query_string' => $query_pubmed } );
	return $id if ($id);

	my ( $url, $file );

	$self->{'www_search'}->native_query($query_pubmed);

	my @error = eval {
		$url  = $self->{'www_search'}->next_url();
		$file = $self->{'www_mechanize'}->get($url);
		$file = $file->content();
	};
	unless ( $file =~ m/\w/ ) {
		warn
"Oh we got no search web page using the url\n$self->{'www_search'}->next_url()\nError="
		  . join( ' ', @error ) . "\n";
		next;
	}
	return $self->store_Pubmed_results( $gene, $query_pubmed, $file, $url );
}

sub store_Pubmed_results {
	my ( $self, $gene, $query_pubmed, $file, $url ) = @_;
	my (
		@lines, $data,       $title,     $journal,
		$PMID,  $authors,    $year,      @authors,
		@temp,  $first_name, $last_name, $issue,
		$pages, $month,      $day,       $match_condition,
		$temp
	);
	$data = {
		'results'      => 0,
		'PubMed_list'  => [],
		"GeneSymbol"   => $gene,
		'query_string' => $query_pubmed
	};

	$data->{'results'} = $1 if ( $file =~ m/Results: (\d+)/ );
	$data->{'results'} = $1
	  if ( $file =~ m/Results: \d+ to \d+ of (\d+)/ );

	@lines = split( "\n", $file );
	my $initial_matches = 0;
	foreach (@lines) {
		if ( $_ =~
m/EntrezSystem2.PEntrez.Pubmed.Pubmed_ResultsPanel.Pubmed_RVDocSum.uid/
		  )
		{

			#foreach my $div ( split( /\<div/, $_ ) ) {
			@authors = undef;
			$journal = 'unknown';
			$title   = 'unknown';
			$PMID    = -1;
			$issue   = 0;
			if ( $_ =~ m/ *class="rslt"/ ) {
				$year = -1;
				$initial_matches++;

				# warn "please - what did change?\n$div\n";
				foreach my $class ( split "class=", $_ ) {
					next
					  if ( $_ =~
						m/for the Diabetes Prevention Program Research Group/ );
					if ( $class =~
						m/\/pubmed\/(\d+)" *ref="ordinalpos=\d+"\>(.+)<\/a>/ )
					{
						$PMID  = $1;
						$title = $2;
					}

#="jrnl" title="The Journal of biological chemistry">J Biol Chem</span>. 1994 Aug 19;269(33):21003-9.</span><span
					#jrnl" title="The Journal of neuroscience : the official journal of the Society 
					#   for Neuroscience">J Neurosci</span>. 1999 Aug 15;19(16):7007-24.
					#   </p></div><div class="aux"><div class="resc"><dl class="rprtid"><dt>PMID:</dt> 
					#   <dd>10436056</dd> <dd>[PubMed - indexed for MEDLINE] </dd></dl><span 
					if ( $class =~
						m/jrnl" title="(.*)">[\w ]*<\/span>. (.+).<\/[span]+>/ )
					{
						$journal         = $1;
						$year            = $2;
						$temp            = $year;
						$match_condition = 0;
						
						($year, $month, $day, $pages, $issue) = $self->_parse_reference ( $year);
						Carp::confess(
"please help me to understand this bib information:\n$year\n for entry:\n$class\non web page:$url\n"
							) if ( $year eq "error");
						

#							foreach ( $year, $month, $day, $issue, $pages ){
#								if ( ! defined $_  || $_ eq ""){
#									$_ = 'not defined';
#									warn "we have a not defined variable:\n".
#									"\$year = $year\n\$month = $month\n\$day = $day\n\$issue = $issue\n\$pages = $pages\n".
#									"condition $match_condition has to be checked with string '$temp'\n";
#
#								}
#							}
					}
					if ( $class =~ m/rprtbody"\>(.*)\.?\</ ) {

						#rprtbody">Knisely AS, Bull L, Shneider BL</p>
						foreach $authors ( split( ",", $1 ) ) {
							@temp       = split( " ", $authors );
							$first_name = pop(@temp);
							$last_name  = join( " ", @temp );
							push(
								@authors,
								{
									'first_name' => $first_name,
									'last_name'  => $last_name
								}
							);
						}
						shift(@authors) unless ( defined $authors[0] );
						unless ( scalar(@authors) > 0 ) {
							@authors = (
								{
									'first_name' => 'unknown',
									'last_name'  => 'unknown'
								}
							);
						}
						$authors = [@authors] if ( defined $authors[0]);
						unless ( ref($authors) eq "ARRAY" ) {
							Carp::confess(
"(1) sorry, but I could not identify the authors in this publication entry:\n$class\n$url\n"
							);
						}
					}
					if ( $class =~ m/"desc">([\w, ]+)\.?<\/p>/ ) {

#die "we would seartch for the authorst in this string\n$class\tthat we pared into the array".join("\n",split( ", ", $class ) )."\n";
#<p class="desc">Cuccurazzu B, Leone L, Podda MV, Piacentini R, Riccardi E, Ripoli C, Azzena GB, Grassi C.</p>
						my $die;
						foreach my $name ( split( ", ", $class ) ) {
							if ( $name =~ m/([\w-]+) (\w+)\.?/ ) {
								push(
									@authors,
									{
										'first_name' => $2,
										'last_name'  => $1
									}
								);
								$die .= "FN='$2'; LN='$1'\n"
							}
						}
						$authors = [@authors];
						#die "I have parsed the string $class into the names\n$die\n";
					}
				}
				
				unless ( ref($authors) eq "ARRAY" ) {
					Carp::confess(
"$_\n(2) sorry, but I could not identify the authors in this publication entry:\n$url\n"
					);
				}
				push(
					@{ $data->{'PubMed_list'} },
					{
						'PMID'      => $PMID,
						'title'     => $title,
						'journal'   => { 'name' => $journal },
						'authors'   => $authors,
						'pub_year'  => $year,
						'issue'     => $issue,
						'pub_month' => $month,
						'pub_day'   => $day,
						'pages'     => $pages
					}
				);
				warn root::get_hashEntries_as_string(
					{
						'PMID'      => $PMID,
						'title'     => $title,
						'journal'   => { 'name' => $journal },
						'authors'   => $authors,
						'pub_year'  => $year,
						'issue'     => $issue,
						'pub_month' => $month,
						'pub_day'   => $day,
						'pages'     => $pages
					},
					3,
					"from page $url\n we have added a entry"
				);
			}
		}
	}
	my $root = root->new();
	if ( $data->{'results'} > 0 && scalar( @{ $data->{'PubMed_list'} } ) == 0 )
	{
		Carp::confess(
			"We could not extract the publications from this file:\n"
			  . join( "\n", @lines ),
"\nbut we have analyzed $initial_matches lines that potentially contain the necessary information\n"
		);
	}
	sleep(2);
	return $self->AddDataset($data);
}


sub _parse_reference{
	my ( $self, $year ) =@_;
	my ( $month, $day, $pages, $issue, $match_condition );
	#1994 Aug 19;269 (33) : 21003 - 9
						#2010 Aug;21(7-8):350-60
						#2010 Mar 23;20(6)
						#2009 May 15;587(Pt 10):2313-26. Epub 2009 Mar 30
						#2005 Dec;26(36):7548-54
						if ( $year =~
m/(\d\d\d\d) (\w\w\w)[ ]?(\d?\d?)\-?\d?\d?;([\d]+\w?) ?\(?[Pt \-\d]*\)? ?: ?(\w?[\d \-]+)/
						  )
						{
							( $year, $month, $day, $issue, $pages ) =
							  ( $1, $2, $3, $4, $5 );
							$match_condition = 1;
						}

						#2009;587(Pt 10):2313-26. Epub 2009 Mar 30
						elsif ( $year =~
m/(\d\d\d\d);([\d]+\w?) ?\(?[Pt \-\d]*\)? ?: ?(\w?[\d \-]+)/
						  )
						{
							( $year, $issue, $pages ) = ( $1, $2, $3, $4, $5 );
							$month = $day = "";
							$match_condition = 2;
						}

						#1999 Nov-Dec;77(3-4):215-24.
						elsif ( $year =~
m/(\d\d\d\d) (\w\w\w\-\w\w\w)[ ]?(\d?\d?)\-?\d?\d?;([\d]+\w?) ?\(?[Pt \-\d]*\)? ?: ?(\w?[\d \-]+)/
						  )
						{
							( $year, $month, $day, $issue, $pages ) =
							  ( $1, $2, $3, $4, $5 );
							$match_condition = 3;
						}

						#2009 Aug 21;9(16). [Epub ahead of print]
						elsif ( $year =~
m/(\d\d\d\d) (\w\w\w) (\d+);(\d+)\(\d+\).*(Epub ahead of print)/
						  )
						{
							( $year, $month, $day, $issue, $pages ) =
							  ( $1, $2, $3, $4, $5 );
							$match_condition = 4;
						}

						# 2010 Aug 1. [Epub ahead of print]
						elsif ( $year =~
							m/(\d\d\d\d) (\w\w\w) (\d+). .(Epub ahead of print)/
						  )
						{
							( $year, $month, $day, $issue ) =
							  ( $1, $2, $3, $4 );
							$pages           = '--';
							$match_condition = 4;
						}

						#2010 Aug 25;5(8). pii: e12399
						#2010 Feb 19;6(2):e1000847
						elsif ( $year =~
m/(\d\d\d\d) (\w\w\w)[ ]?(\d?\d?)\-?\d?\d?;([\d]+\w?) ?\(?[\.\w \-\d]*\)?[\. pii]*: *(e\d+)/
						  )
						{
							( $year, $month, $day, $issue, $pages ) =
							  ( $1, $2, $3, $4 );
							$pages           = '--';
							$match_condition = 5;
						}

						#2010;20 Suppl 2:S513-26.
						elsif (
							$year =~ m/(\d\d\d\d);(\d+\w?).*:(\w?[\d \-]+)/ )
						{
							( $year, $issue, $pages ) = ( $1, $2, $3 );
							$month = $day = '--';
							$match_condition = 6;
						}

						#2009 Dec 19;79 Suppl 2:26-30. Spanish.
						elsif ( $year =~
m/(\d\d\d\d) (\w\w\w)[ ]?(\d?\d?)\-?\d?\d?;(\d+\w?) .*:(\w?[\d \-]+)/
						  )
						{
							( $year, $month, $day, $issue, $pages ) =
							  ( $1, $2, $3, $4, $5 );
							$match_condition = 7;
						}

						#2009 Dec;79 Suppl 2:26-30. Spanish.
						elsif ( $year =~
							m/(\d\d\d\d) (\w\w\w);(\d+\w?) .*:(\w?[\d \-]+)/ )
						{
							( $year, $month, $issue, $pages ) =
							  ( $1, $2, $3, $4 );
							$day             = '--';
							$match_condition = 7;
						}

						#2008;(9):40-5. Russian.
						elsif (
							$year =~ m/(\d\d\d\d);\((\d+\w?)\):(\w?[\d \-]+)/ )
						{
							( $year, $issue, $pages ) = ( $1, $2, $3 );
							$month = $day = '--';
							$match_condition = 8;
						}

						#2010 Jun;(6):3-17. Russian.
						elsif (m/(\d\d\d\d) ?(\w+) ?(\d+)[ ]*;/) {
							( $year, $month, $day ) = ( $1, $2, $3 );
							$pages = $issue = '--';
							$match_condition = 9;
							warn
"we have only extracted the pub date: $year-$month-$day\n";
						}
						else {
							return 'error';
							
						}
	$pages = 0 unless ( defined $pages);
	return ($year, $month, $day, $pages, $issue );
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	unless ( ref( $dataset->{'PubMed_list'} ) eq "ARRAY" ) {
		$self->{'error'} .= ref($self)
		  . ":post_INSERT_INTO_DOWNSTREAM_TABLES - we do not have a list of publications!\n";
	}
	else {
		my $list_id = $self->{'data_handler'} -> {'PubMed_list'} -> AddDataset ($dataset->{'PubMed_list'});
		$self->UpdateDataset ( {'id' => $id, 'Publication_list_id' => $list_id});
	}
	return 1 unless ( $self->{'error'} =~ m/\w/ );
	return 0;
}

sub get_publications_for_T2D_gene {
	my ( $self, $gene_symbol ) = @_;
	unless ( defined $gene_symbol ) {
		return undef;
	}
	return $self->get_data_table_4_search(
		{
			'search_columns' => [ref($self).".GeneSymbol", 'PubMed.title','PubMed.PMID', 'Authors.first_name'. 'Authors.last_name', 'Journals.name' ],
			'where' => [ [ ref($self) . ".GeneSymbol", '=', 'my_value' ] ],
		},
		$gene_symbol
	);
}

1;
