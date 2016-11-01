package expression_net_reader;

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

use strict;
use warnings;
use stefans_libs::database::genomeDB::gene_description;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::pathways::kegg::kegg_genes;
use Statistics::R;

sub new {

	my ( $class, $filename, @initial_genes ) = @_;

	my ($self);

	$self = {
		'app_sections'     => [],
		'gene_description' => gene_description->new( root->getDBH(), 0 ),
		'desease'          => 'T2D',
		'table_header'     => {
			'gene1'     => 0,
			'gene2'     => 1,
			'p_value'   => 2,
			'S_value'   => 3,
			'R_squared' => 4
		},
		'clc'      => 0,
		'groupTag' => 'Gr.',
		'data'     => [],
		'gene1'    => {},
		'gene2'    => {}
	};

	bless $self, "expression_net_reader"
	  if ( $class eq "expression_net_reader"
		|| ref($class) eq "expression_net_reader" );
	$self->AddSEPT_HASH();
	if ( defined $filename ) {
		$self->Read_from_File( $filename, \@initial_genes ) if ( -f $filename );
	}

	return $self;

}

sub GetLatexFigure {
	my ( $self, $hash ) = @_;
	my ( $section_string, $latex_section );
	$section_string = $self->__get_section_string($hash);
	$hash->{'min_links'} = 2 unless ( defined $hash->{'min_links'} );

	$latex_section =
	    "\\$section_string"
	  . "{Graphical view of the expression net}\n"
	  . "\\label{r-network}\n\n";
	$latex_section .= $hash->{'section_text'};
	unless ( -d $hash->{'outpath'} ) {
		Carp::complain(
			ref($self)
			  . "::GetAsLatex_String - we can not create the figure as we do not know where to store it"
		);
	}
	else {
		unless ( -f "$hash->{'outpath'}/pic.svg" ) {
			my $R_cmd =
			  $self->getAs_R_matrix( $hash->{'outpath'}, $hash->{'min_links'} );

			my $R = Statistics::R->new();
			$R->{'START_CMD'} = "$R->{R_BIN} --slave --vanilla --gui=X11";
			$R->startR() unless ( $R->is_started() );
			my @cmd = split( "\n", $R_cmd );
			foreach my $cmd (@cmd) {
				$R->send($R_cmd);
				$cmd = $R->read();
				print "R output: '$cmd'\n" if ( $cmd =~ m/\w/ );
			}
			$R->stopR();
		}
		print ref($self)
		  . "::GetAsLatex_String -> we have crated/used the connection net figure $hash->{'outpath'}/pic.svg\n";
		if ( defined $hash->{'figure'}->{'caption'} ) {
			$latex_section .=
			    '\begin{figure}[tbp]' . "\n"
			  . "\\centering\n\\includegraphics[width=17cm]{pic}\n"
			  . "\\caption{\n$hash->{'figure'} ->{'caption'}\n}"
			  . "}\n\\end{figure}\n\n";
		}
	}
	return $latex_section;
}

sub __get_section_string {
	my ( $self, $hash ) = @_;
	$hash->{'header_level'} = 0 unless ( defined $hash->{'header_level'} );
	my $section_str = 'section';
	for ( my $i = 0 ; $i < $hash->{'header_level'} ; $i++ ) {
		$section_str = "sub$section_str";
	}
	return $section_str;
}

sub read_LogFile {
	my ( $self, $logfile ) = @_;
	unless ( -f $logfile ) {
		warn "sorry but the file $logfile is no file\n";
		return undef;
	}
	open( IN, "<$logfile" ) or die "could not open file '$logfile'\n$!\n";
	my ( $data, $gene_list, @line );
	while (<IN>) {
		chomp($_);
		next if ( $_ =~ m/^\s*$/ );

		#print "we read the line '$_'\n";
		if ( $_ =~ m/genes:\t(.+)$/ ) {
			if ( defined $gene_list ) {
				## we need to check if we got all information sets:
				foreach my $tag (
					'amount of seeder genes',
					'connection groups',
					'genes in connection groups',
					'overall genes',
					'group_size',
					'group_tags'
				  )
				{
					unless ( defined $data->{$gene_list}->{$tag} ) {
						Carp::confess(
"read_LogFile - sorry, but we miss the '$tag' line\n"
						);
					}
				}
			}
			$gene_list = $1;
			$data->{$gene_list} = {};
			next;
		}
		Carp::confess(
"read_LogFile - sorry, but the file $logfile has not the right format (missing the genes line)\n$_\n"
		) unless ( defined $gene_list );
		@line = split( "\t", $_ );
		$line[1] = 0 unless ( defined $line[1]);
		$data->{$gene_list}->{ $line[0] } = $line[1];
	}
	return $data;
}

sub Logfile {
	my ( $self, $logfile ) = @_;
	unless ( defined $self->{'logfile'} ) {
		if ( defined $logfile ) {
			if ( -f $logfile ) {
				## OK here we might get more problems - or?
				open( LOG, ">>$logfile" )
				  or die "could not open the logfile '$logfile' for writing\n";
			}
			else {
				open( LOG, ">$logfile" )
				  or die "could not create the logfile '$logfile'\n";
			}

			$self->{'logfile'} = \*LOG;

#die "you tried to set a logfine and I set that to $self->{'logfile'} \n".ref($self->{'logfile'})."\n";
		}
	}
	warn ref($self) . "::Logfile -> we do not have a logfile \n"
	  unless ( defined $self->{'logfile'} );
	return $self->{'logfile'};
}

sub print2log {
	my ( $self, @str ) = @_;
	return 1 unless ( defined $str[0] );
	unless ( ref( $self->{'logfile'} ) eq "GLOB" ) {
		warn ref($self)
		  . "::print2log - sorry, but we have no open log file here ('$self->{'logfile'}') - please open one using the function "
		  . ref($self)
		  . "->Logfile(<filename>)\n";
		print "\n\n" . join( "\n", @str ) . "\n";
		return 0;
	}

	#print "we print to logfile $self->{'logfile'}\n";
	print { $self->{'logfile'} } join( "\n", @str );
	return 1;

}

sub DESTROY {
	my ($self) = @_;
	if ( ref( $self->{'logfile'} ) eq "GOLB" ) {
		close( $self->{'logfile'} );
	}
}

sub __match_to_initial_genes {
	my ( $self, $gene, $initial_genes ) = @_;
	my $error = '';
	$error = 'No genes array\n' unless ( ref($initial_genes) eq "ARRAY" );
	if ( $error =~ m/\w/ ) {

		#warn "no initial genes check!\n$error";
		return 1;
	}
	$error = 'the first gene was undefined!'
	  unless ( defined @$initial_genes[0] );
	if ( $error =~ m/\w/ ) {

		#warn "no initial genes check!\n$error";
		return 1;
	}
	$error = 'the first gene did not contain a char!'
	  unless ( @$initial_genes[0] =~ m/\w/ );
	if ( $error =~ m/\w/ ) {

		#warn "no initial genes check!\n$error";
		return 1;
	}
	my $temp;

	#print "we check if we want to use the gene '$gene'\n";
	unless ( ref( $self->{'used'} ) eq "HASH" ) {
		print "\n";
		$self->{'used'} = {};
	}
	foreach (@$initial_genes) {
		if ( $_ eq $gene ) {
			print "we will use the gene $gene n="
			  . scalar( keys %{ $self->{'used'} } ) . "\n"
			  unless ( $self->{'used'}->{$gene} );
			$self->{'used'}->{$gene} = 1;
			return 1;
		}
	}

#print "we will not use the gene '$gene'\nNo match to array'".join("' '",@$initial_genes)."'\n";
	return 0;
}

=head2 Read_from_File

I wcan read from an co expression analysis results file thayt is created using the 
createConnectionNet_4_expressionArrays.pl scipt.

After I have read the file I will have an internal data sructure named 'data',
that is an array of arrays.The second arrays lokk like [ 'gene1', 'gene2' ,'p_value', 'S', 'R' ].

=cut

sub Read_from_File {
	my ( $self, $file, $initial_genes, $relax ) = @_;
	unless ( -f $file ) {
		Carp::confess(
			ref($self)
			  . "..Read_from_File -> Sorry, but I could not find file $file\n"
		);
	}
	open( IN, "<$file" )
	  or Carp::confess(
		ref($self)
		  . "..Read_from_File -> we could not open the file $file ( $!)\n" );
	unless ( ref($initial_genes) eq "ARRAY" ) {
		Carp::confess(
"function has changed - we will now always check if you wanted to include the gene and therefoer we need an array of wanted genes at startup!"
		);
	}
	$self->{'initial_genes'} = $initial_genes;
	my (@line);
	while (<IN>) {
		next if ( $_ =~ m/^#/ );
		next if ( $_ =~ m/^gene\tcorrelating gene/);
		#next unless ( $self->__match_to_initial_genes($_, $initial_genes));
		chomp($_);
		$_ =~ s/,/\./g;
		@line = split( "\t", $_ );
		for ( my $i = 0 ; $i < 2 ; $i++ ) {
			$line[$i] = $1 if ( $line[$i] =~ m/^ *(.+) *$/ );
		}

#print "we read line $_\n";
#print "we try to add a CHCHD9 gene entry\n$_\n".join("; ",@line)."\n" if ($_ =~ m/CHCHD9/);
		unless ( scalar(@line) == 5 ) {
			if ($relax) {
				warn "we had a maleformed line ( $_ )\n";
				next;
			}
			Carp::confess(
				ref($self)
				  . "..Read_from_File -> the file $file has a maleformed line ( $_ )\n"
			);
		}

		$self->__addCorrelationDataArray( $initial_genes, @line );
	}
	my $error = '';
	foreach (@$initial_genes) {
		$error .= " $_" unless ( defined $self->{'gene1'}->{$_} );
	}
	unless ($relax) {
		Carp::confess(
			    "Sorry, but the file did not contain the initial genes $error\n"
			  . "But we have the genes "
			  . join( "; ", ( sort keys %{ $self->{'gene1'} } ) )
			  . "\n" )
		  if ( $error =~ m/\w/ );
	}
	else {
		warn "Sorry, but the file did not contain the initial genes $error\n"
		  . "But we have the genes "
		  . join( "; ", ( sort keys %{ $self->{'gene1'} } ) ) . "\n"
		  if ( $error =~ m/\w/ );
	}
	return 1;
}

sub __get_gene_symbol {
	my ( $self, $entry1, $entry2 ) = @_;
	my $rep = 0;

	($entry1) = split( / *\/\/ */, $entry1 );
	($entry2) = split( / *\/\/ */, $entry2 );
	if ( $entry1 =~ m/\d+_([\w\d\.\/\@\-]+)/ ) {
		return $1, 1;
	}
	if ( $entry1 =~ m/^ *([\w\d\.\/\@\-_]+) *$/ ) {
		return $1, 1;
	}
	if ( $entry1 =~ m/^\d+$/ && $entry2 =~ m/^ *([\w\d\.\/\@\-]+) *$/ ) {
		return $1, 2;
	}

	Carp::confess(
"Sorry, but we could not identfy a gene symbole in the two entries $entry1 and $entry2\n "
	);
}


sub __addCorrelationDataArray {
	my ( $self, $initial_genes, @line ) = @_;
	## I have messed that file format up!
	## A gene might contain
	## (1) only the gene symbol
	## (3) the probe_id and another column with the gene symbol
	## and as the version 3 is the most accurate one - I will now change the format!
	$self->{'line_count'} ||= 0;
	$self->{'line_count'}++;
	my ( $gene1, $gene2, $i, $i2, $orig_line );
	## I need to get rid of some problematic entries:
	## e.g.(RP11-38M15.10  // RP11-38M15.10  // RP11-38M15.10 )
	$orig_line = join( "; ", @line );
	if ( $orig_line =~ m/Sep/ ) {
		@line = $self->translate_SEPT_genes(@line);
	}
	for ( my $i = 0 ; $i < @line ; $i++ ) {
		next unless ( defined $line[$i] );
		$line[$i] =~ s/ *\/\/.*$//;
	}

#print "test:: '$orig_line' transormed into '".join("; ",@line)."\n" if ( $orig_line =~ m/\/\//);

	( $gene1, $i ) = $self->__get_gene_symbol( $line[0], $line[1] );

#print "we got the gene $gene1 for a line containing CHCHD9" if ( join(" ", @line ) =~ m/CHCHD9/);
	return 1
	  unless ( $self->__match_to_initial_genes( $gene1, $initial_genes ) );
	( $gene2, $i2 ) =
	  $self->__get_gene_symbol( $line[ 0 + $i ], $line[ 1 + $i ] );
	## we have another problem - there are genes that only have a number as name - we will not use them!
	return 1 if ( $gene2 =~ m/^\d+$/ );
	return 1 if ( $gene2 =~ m/^---$/ );
	if ( $gene2 =~ m/^\d\d\.$/ ) {

#warn "I got gene2=$gene2 we could not identify the second gene symbol this line:\n\t$orig_line\n\tI will ignore that line!\n" ;
		return 1;
	}
	Carp::confess(
		    "I fear we did an mistake as gene2 is not in the right formate "
		  . "( \$gene1, \$i, \$gene2, \$i2 ) = ( $gene1, $i, $gene2, $i2)\n"
		  . join( "; ", @line )
		  . "\nand the original line was $orig_line\non input line $self->{'line_count'} \n"
	) if ( $gene2 =~ m/^[\d\.\-eE]+$/ );

#warn "we would now like to add the line gene1 = $gene1; gene2 = $gene2 :". join ( "; ", ($gene1, $gene2, @line[($i+ $i2),  ($i+ $i2 + 1) , ($i+ $i2 + 2)]))."\n";
	push(
		@{ $self->{'data'} },
		[
			$gene1,
			$gene2,
			$line[ ( $i + $i2 ) ],
			$line[ ( $i + $i2 + 1 ) ],
			$line[ ( $i + $i2 + 2 ) ]
		]
	);

#print "we have added the info array ".join ("; ",@{@{ $self->{'data'} }[@{ $self->{'data'} } -1]})."\n";
	Carp::confess(
		    "We have a big problem here, as gene1 id an array - not an value ("
		  . join( " ", @line )
		  . ")" )
	  if ( ref($gene1) eq "ARRAY" );
	$self->{'gene1'}->{$gene1} = $self->{'gene2'}->{$gene2} =
	  scalar( @{ $self->{'data'} } ) - 1;
	return 1;
}

#This thing is not working!!!
#sub restrict_gene2_to_list {
#	my ( $self, @geneList ) = @_;
#	return $self;
#	my $return = $self->new();
#	foreach my $gene (@geneList) {
#		$return->__addCorrelationDataArray( [],
#			@{ $self->{'data'} }[ $self->{'gene2'}->{$gene} ] )
#		  if ( defined $self->{'gene2'}->{$gene} );
#	}
#	return $return;
#}

sub restrict_gene1_to_list {
	my ( $self, @geneList ) = @_;
	my $return = ref($self)->new();
	my ( $array, $hash );
	$return->{'gene1'}      = {};
	$return->{'gene2'}      = {};
	$return->{'connection'} = undef;
	foreach (@geneList) {
		( $_, $array ) = $self->__get_gene_symbol( $_, "12345" );

		#print "we restrict to gene1 and use the gene $_\n";
		$hash->{$_} = 1;
	}
	foreach $array ( @{ $self->{'data'} } ) {
		if ( $hash->{ @$array[0] } ) {
			$return->{'gene1'}->{ @$array[0] } = 0
			  unless ( $return->{'gene1'}->{ @$array[0] } );
			$return->{'gene1'}->{ @$array[0] }++;
			$return->{'gene2'}->{ @$array[1] } = 0
			  unless ( $return->{'gene2'}->{ @$array[1] } );
			$return->{'gene2'}->{ @$array[1] }++;
			push( @{ $return->{'data'} }, $array );
		}
	}
	$return->{'initial_genes'} = [@geneList];
	return $return;
}

sub restrict_p_value_lessThan {
	my ( $self, $cutoff ) = @_;
	my $return = expression_net_reader->new();
	foreach my $arrayRef ( @{ $self->{'data'} } ) {

		#print "we chaeck the p_value "
		#  . @$arrayRef[ $self->{'table_header'}->{'p_value'} ] . "\n";
		$return->__addCorrelationDataArray( [], @$arrayRef )
		  if ( $self->__get_p_value_from_line($arrayRef) <= $cutoff );
	}
	$return->{'max_p_value'} = $cutoff;
	return $return;
}

sub __get_p_value_from_line {
	my ( $self, $line ) = @_;
	Carp::confess("::__get_p_value_from_line -> line array is not an array!")
	  unless ( ref($line) eq "ARRAY" );
	return @$line[2];
}

sub __get_R_squared_from_line {
	my ( $self, $line ) = @_;
	warn ref($self)
	  . "::__get_R_squared_from_line -> line array is not an array!"
	  unless ( ref($line) eq "ARRAY" );
	return @$line[4];
}

sub restrict_R_squared_moreThan {
	my ( $self, $cutoff ) = @_;
	my $return = expression_net_reader->new();
	my $before = scalar( @{ $self->{'data'} } );
	foreach my $arrayRef ( @{ $self->{'data'} } ) {
		unless ( defined @$arrayRef[ $self->{'table_header'}->{'R_squared'} ] )
		{
			$return->__addCorrelationDataArray( [], @$arrayRef )
			  ;    ## there are no r_squared values in this file - CRAP!
		}
		else {

#print "we use the value @$arrayRef[ $self->{'table_header'}->{'R_squared'} ] as a number!\n";
			$return->__addCorrelationDataArray( [], @$arrayRef )
			  if ( $self->__get_R_squared_from_line($arrayRef)**2 >=
				($cutoff)**2 );
		}
	}
	$return->{'R_squared'} = $cutoff;

#die "we threw ". ($before - scalar ( @{$return->{'data'}} ) )." dataset away, because the r_squared was not good enough\n";
	return $return;
}

sub Write_to_File {
	my ( $self, $file ) = @_;
	open( OUT, ">$file" )
	  or Carp::confess(
		ref($self) . "..Write_to_File -> I could not create the file $file" );
	my @header;
	while ( my ( $tag, $position ) = each %{ $self->{'table_header'} } ) {
		$header[$position] = $tag;
	}
	print OUT join( "\t", @header ) . "\n";
	foreach my $data ( @{ $self->{'data'} } ) {
		unless ( ref($data) eq "ARRAY" ) {
			Carp::confess(
				root::get_hashEntries_as_string(
					{ 'entry' => $data, 'dataset' => $self->{'data'} },
					4, "Somehow our dataset is corrupted!"
				)
			);
		}
		foreach (@$data) {
			Carp::confess(
				root::get_hashEntries_as_string(
					{ 'entry' => $data, 'dataset' => $self->{'data'} },
					4, "Somehow our dataset is corrupted!"
				)
			) unless ( defined $_ );
		}
		print OUT join( "\t", @$data ) . "\n";
	}
	close(OUT);
	print "Data written to '$file'\n";
	return 1;
}

sub drop_connections_from_gene {
	my ( $self, @genes ) = @_;
	my $hash = {};
	foreach my $g (@genes) {
		$hash->{$g} = 1;
	}
	my $return = expression_net_reader->new();
	foreach my $arrayRef ( @{ $self->{'data'} } ) {
		$return->__addCorrelationDataArray(@$arrayRef)
		  unless ( $hash->{ @$arrayRef[ $self->{'header'}->{'gene1'} ] } );
	}
	return $return;
}

#\multicolumn{1}{c|}{\textbf{Triple chosen}} &
#\multicolumn{1}{c|}{\textbf{Other feasible triples}} \\ \hline
#\endhead
#
#\hline \multicolumn{3}{|r|}{{Continued on next page}} \\ \hline
#\endfoot
#
#\hline \hline
#\endlastfoot

sub has_connection_same_ori {
	my ( $self, $gene1, $gene2, $R ) = @_;
	my $line_nr = $self->connection_exists( $gene1, $gene2 );
	return 0 unless ( defined $line_nr );
	my $my_R =
	  $self->__get_R_squared_from_line( @{ $self->{'data'} }[$line_nr] );
	if ( $R > 0 ) {
		return 1 if ( $my_R > 0 );
		return -1;
	}
	if ( $R < 0 ) {
		return 1 if ( $my_R < 0 );
		return -1;
	}
	Carp::confess(
		    ref($self)
		  . "::has_connection_same_ori ($gene1, $gene2, $R) ->\n"
		  . " we could not determine if we have a simmilar connection!(\$line_nr = $line_nr; \$my_R = $my_R)\n"
	);
}

sub getGeneDigest {
	my ($self) = @_;
	my $return = $self->{'gene_description'}->digest_description();
	my $key;
	open( LOG, ">/home/stefan_l/words_log.txt" ) or return $return;
	foreach $key ( keys %$return ) {
		print LOG "$return->{$key} hits for word '$key'\n";
	}
	close(LOG);
	return $return;
}

sub __create_columnEntry_OtherDataset {
	my ( $self, $gene1, @otherDataset ) = @_;
	my $desc =
	  { 'Correlating gene' => "\\nameref{" . root->Latex_Label($gene1) . "}" };
	my ( $temp, $value );
	if ( scalar(@otherDataset) > 0 ) {
		for ( my $i = 0 ; $i < @otherDataset ; $i++ ) {
			($value) =
			  $otherDataset[$i]
			  ->get_value_for( 'Gene Symbol', "$gene1 ", 'p value' );

			#print "initially we got the value $value for gene '$gene1'\n";
			unless ( $value =~ /\d/ ) {

			  #print "we need to get the gene name without a trailing space!\n";
				($value) =
				  $otherDataset[$i]
				  ->get_value_for( 'Gene Symbol', "$gene1", 'p value' );
			}
			$temp = '-';
			if ( defined $value ) {
				$temp = int( -&log10($value) )
				  if ( $value =~ m/\d/ && $value < 0.6 && $value > 0 );
			}
			$desc->{ ( $i + 1 ) } = $temp;
		}
	}

	return $desc;
}

sub log10 {
	my ($value) = @_;
	return log($value) / log(10);
}

sub __describe_other_dataset {
	my ( $self, @otherDataset ) = @_;
	return '' unless ( defined $otherDataset[0] );

	#return '' unless ( $self->output_type() eq "long" );
	my $entry;
	my $desc .=
"The last columns contain the information from the other correlations as mentioned in section \\ref{corr-data-overview}.\n";
	$desc .= "the columns contain the \$-log10(p_value)\$" .

	  #" and primary statistic values".
	  " for the comparisons \n"
	  . "between the gene expression and these phenotypes: ";
	for ( my $i = 1 ; $i < @otherDataset + 1 ; $i++ ) {
		$desc .= " "
		  . $otherDataset[ $i - 1 ]->Name()
		  . " (\\hyperlink{data$i}{$i}), ";
	}
	chop($desc);
	chop($desc);
	return $desc . ".\n\n";
}

=head2 getCorrelationAppendix

This function will need an array of data_tables containing the correlations datasets. 
It will return an appendix latex section containing all the correlation data that has been described in the PDF.

=cut

sub getCorrelationAppendix {
	my ( $self, @otherDataset ) = @_;
	return '' unless ( ref( $otherDataset[0] ) eq "data_table" );
	my $appendix = "\\section{Appendix} \n\\label{app}\n\n";
	foreach my $section ( @{ $self->{'app_sections'} } ) {
		$appendix .= $section;
	}
	my ( @genes, $i, $data_table );
	$i = 0;
	foreach my $gene1 ( keys %{ $self->{'connection'} } ) {
		foreach my $gene2 ( keys %{ $self->{'connection'}->{$gene1} } ) {
			if ( $gene2 =~ m/\w/ ) {
				$genes[ $i++ ] = $gene2;
				$genes[ $i++ ] = "$gene2 ";
			}
		}
	}

	#warn "we had the genes @genes\n";
	@genes = ( sort @genes );

	#warn "and now we have the genes @genes\n";
	$i = 0;
	my @subset = ( 'Gene Symbol', 'p value', 'rho' );
	my @subset_TTest = ( 'Gene Symbol', 'p value', 'fold change');
	foreach my $dataset (@otherDataset) {
		$i++;

#Carp::confess ( "we need to modify the name function of this object: $dataset\n\n\n");
		$appendix .=
		    "\\subsection{Phenotype "
		  . $dataset->Name()
		  . "}\n\\label{"
		  . $dataset->Name() . "}\n";
		$appendix .=
"This is all the correlation data we have for the genes, that are described in this document.\n"
		  . "The dataset was always depicted with the number \\hypertarget{data$i}{$i}.\n";
		$data_table = $dataset->getCopy_4_values( 'Gene Symbol', @genes );
		if ( defined $data_table->Header_Position('fold change')){
			## OK this is a new correlation file - we have a fold change column - therefore it is a two group comparison
			$appendix .= "Keep in min, that the p values are calculated using a two group comparison,"
				." no linear correlation or multi group comparison.\n";
			$data_table->define_subset( 'print', \@subset_TTest);
		}
		else {
			$data_table->define_subset( 'print', \@subset );
		}
		

#warn "The dataset, that was always depicted with the number $i = \n".$data_table->AsLatexLongtable();
		$appendix .= $data_table->AsLatexLongtable('print');
	}
	return $appendix;
}

=head2 getDescription_table

We try to create a as informative table describing the correlations as somehow possible.
At the moment we can include the original correlation data and the same 
correlation data from an other correlation net. At the moment YOU have to make shure
that the genes, that we are interested in our main correlation dataset has also been analyzed in the other dataset. 
Otherwise we will add a lot of zeroes to the dataset. But that will be idenifiable by a lost 'to selve' correlation.

We can also get correlations from other correlation dataset (e.g. Glucose or something else).
These other correlations have to come as a fexible_data_structure::data_table objects 
including a ' Gene Symbol ', a 'p value' and a ['rho' or 'fold change'] key.

This function does the same as __create_connection_dataset, but while doing that 
it will create a LaTEX formated section, that describes each and every gene in 
the connection net dataset! That might create many web queries!!

=cut

sub getDescription_table {
	my ( $self, $hash ) =
	  @_;    #$other_expression_net, $description_of_connection,
	         #	@otherDataset )
	         #  = @_;
	$hash->{'other_expression_net'} = ''
	  unless ( defined $hash->{'other_expression_net'} );
	$hash->{'describe_oter_expr_net'} = ''
	  unless ( defined $hash->{'describe_oter_expr_net'} );

	return $self->{ 'descriptionTable' . "$hash->{other_expression_net}" }
	  if (
		defined $self->{ 'descriptionTable'
			  . "$hash->{other_expression_net}" } );
	my ( $gene_description, $arbitryry_score, $matching_string, $entry,
		$data_hash );
	my ( $section_string, $latex_section );
	$section_string = $self->__get_section_string($hash);

	$self->{'word_types'}        = {};
	$self->{'connection_groups'} = {};

	$latex_section = "\\$section_string"
	  . "{Correlation Data Overview}\n\\label{corr-data-overview}\n\n";
	$latex_section .= $hash->{'section_text'}
	  if ( defined $hash->{'section_text'} );
	$latex_section .= "\n\n";

	$latex_section .=
"In the following we describe the connection groups, showing the genes, \n"
	  . "that were found fo correlate in expression "
	  . "to at least two of the genes of interest.\n The correlations were calculated using a \n"
	  . "Spearman signed rank algorithm implemented in R.\n"
	  . "The sorrelation coefficient and "
	  . "the p value for these calculations is reported for each gene.\n";

#	$desc .=
#"In this section, the original correlation results are displayed for all genes,\n"
#	  . "that were in your main focus described in \\ref{introduction} on page \\pageref{introduction}.\n\n";
#	$desc .=
#"The data is displayed as tables containing the correlating gene name, the spearman rho (\$R^2\$)";
	if ( $hash->{'arbitrary_desease_score'} ) {
		my $app =
"\\subsection{Calculation of the arbitrary desease score}\n\\label{app.desease.score}\n\n"
		  . "The column 'arb. score' gives a short hint on the importance of the gene, \n"
		  . "based on the gene descriptions found on \\href{http://www.genecards.org}{www.genecards.org}.\n"
		  ## now we need to explain the way we match the strings
		  . "The arbitrary value is computed by matching a set of arbitrary 'words' to the description of the genes. Each found work has a arbitrary weight, that is added to the summary value if the string can be found in the description of the genes.\n"
		  . "The string-value pairs are described in table \\ref{arb_values_table}.\n ";

		$app .=
		  $self->{'gene_description'}
		  ->describe_Desease_Hash( $self->{'desease'} );

		$latex_section .=
"The column 'arb. score' gives a short hint on the importance of the gene, \n"
		  . "based on the gene descriptions found on \\href{http://www.genecards.org}{www.genecards.org}.\n";
		$latex_section .=
"The arbitrary desease score calculation is further described in section \\ref{app.desease.score} on page \\pageref{app.desease.score}.\n";

		push( @{ $self->{'app_sections'} }, $app );

	}
	if ( ref( $hash->{'other_expression_net'} ) eq ref($self) ) {
		$latex_section .= $hash->{'describe_other_expr_net'};
		$latex_section .=
"The column 'other group' reports, if any correlation could be found in the other expression net between the two genes.\n"
		  . " The reported states are '1': the genes were correlated in the same direction as in the original dataset; '-1': the genes were correlated, \n"
		  . "but the direction changes in the other dataset; '0': we saw no correlation in the other dataset.\n";

	}

	my $column_count = 0;
	my $data_table   = data_table->new();
	$data_table->Add_2_Header('Correlating gene');
	$data_table->Add_2_Header('$ R^2 $');
	$data_table->Add_2_Header('p value');
	$data_table->Add_2_Header('arb. score')
	  if ( $hash->{'arbitrary_desease_score'} );
	$data_table->Add_2_Header('other group')
	  if ( ref( $hash->{'other_expression_net'} ) eq ref($self) );
	$entry = 1;

	if ( ref( $hash->{'otherDataset'} ) eq "ARRAY" ) {
		if ( scalar( @{ $hash->{'otherDataset'} } ) > 0 ) {
			$hash->{'use_other_dataset'} = 1;
			for (
				my $entry = 1 ;
				$entry < @{ $hash->{'otherDataset'} } + 1 ;
				$entry++
			  )
			{
				$data_table->Add_2_Header($entry);
			}

			$latex_section .=
			  $self->__describe_other_dataset( @{ $hash->{'otherDataset'} } )
			  unless ( $hash->{'add_desciption_2_each_subsection'} );
		}
	}

	$self->{'gene_description'}->digest_description($gene_description);

	my @infomative_genes = $self->connection_exists();
	my ( $line, @multi_connections, $other_nodes, $multi_i, $key );
	foreach my $gene1 ( sort keys %{ $self->{'connection'} } ) {
		unless ( scalar( keys %{ $self->{'connection'}->{$gene1} } > 1 ) ) {
			## add the latex subsubsection
			$latex_section .=
			    "\\sub$section_string"
			  . "{No correlations with $gene1}\n\\label{"
			  . root->Latex_Label("correlations-$gene1") . "}\n\n"
			  . "Sorry, but we did not identify genes that correlates with the gene $gene1.\n"
			  if ( defined $self->{'gene1'}->{$gene1} );
			next;
		}
		## get infos about the gene
		( $gene_description, $arbitryry_score, $matching_string ) =
		  $self->{'gene_description'}
		  ->determineInfluence_of_gene_on_desease( $gene1, $self->{'desease'} );
		$self->{'gene_description'}->digest_description($gene_description);
		## add the latex subsubsection

		$latex_section .=
		    "\\sub$section_string"
		  . "{$gene1}\n\\label{"
		  . root->Latex_Label("correlations-$gene1") . "}\n\n";
		$latex_section .=
		    "The gene description can be found in section \\ref{"
		  . root->Latex_Label($gene1) . "}.\n"
		  . "And the gene has got an arbitrary $self->{'desease'} score of $arbitryry_score.\n"
		  if ( $hash->{'arbitrary_desease_score'} );
		$latex_section .=
		    "In this analysis, we could identify "
		  . scalar( keys %{ $self->{'connection'}->{$gene1} } )
		  . " genes where the expression is highly correlated with the expression of $gene1.\n"
		  if ( $hash->{'show_gene_lists'} );

		if ( $hash->{'add_desciption_2_each_subsection'}
			&& ref( $hash->{'otherDataset'} ) eq "ARRAY" )
		{
			if ( scalar( @{ $hash->{'otherDataset'} } ) > 0 ) {
				$latex_section .= $self->__describe_other_dataset(
					@{ $hash->{'otherDataset'} } );
			}
		}
		$data_table->delete_all_data();
		my @multi_connections = ();
		my $i = $multi_i = 0;
		foreach my $gene2 (
			sort {
				@{ @{ $self->{'data'} }[ $self->{'connection'}->{$gene1}->{$a} ]
				  }[2] <=> @{ @{ $self->{'data'} }
					  [ $self->{'connection'}->{$gene1}->{$b} ] }[2]
			} keys %{ $self->{'connection'}->{$gene1} }
		  )
		{
			$line =
			  @{ $self->{'data'} }[ $self->{'connection'}->{$gene1}->{$gene2} ];
			Carp::confess(
"we have a problem here, because we have got a crappy gene2 '$gene2' (line "
				  . $self->{'connection'}->{$gene1}->{$gene2} . ")\n"
				  . join( ";", @$line )
				  . root::get_hashEntries_as_string( $self->{'data'}, 3,
					"the data structure:" )
				  . root::get_hashEntries_as_string( $self->{'gene1'}, 2,
					"gene 1 structure" )
				  . root::get_hashEntries_as_string(
					$self->{'gene2'}, 2, "gene 2 structure"
				  )
			) if ( $gene2 =~ m/^[\d\.Ee\-]+$/ );
			( $gene_description, $arbitryry_score, $matching_string ) =
			  $self->{'gene_description'}
			  ->determineInfluence_of_gene_on_desease( $gene2,
				$self->{'desease'} );
			unless ( $gene_description =~ m/\w/ ) {
				Carp::confess(
"we have an seriouse error, as getDescription on file '$gene2' has failed to return ANY description!\n"
					  . root::get_hashEntries_as_string( $line, 3,
						"We have the line: " )
					  . root::get_hashEntries_as_string(
						$self->{'data'}, 3,
						"that was one entry in this dataset: "
					  )
					  . root::get_hashEntries_as_string( $self->{'gene1'}, 2,
						"gene 1 structure" )
					  . root::get_hashEntries_as_string(
						$self->{'gene2'}, 2, "gene 2 structure"
					  )
				);
			}
			$data_hash = {};
			$data_hash =
			  $self->__create_columnEntry_OtherDataset( $gene2,
				@{ $hash->{'otherDataset'} } )
			  if ( $hash->{'use_other_dataset'} );

			$data_hash->{'other group'} =
			  $hash->{'other_expression_net'}
			  ->has_connection_same_ori( $gene1, $gene2,
				$self->__get_R_squared_from_line($line) )
			  if ( ref( $hash->{'other_expression_net'} ) eq ref($self) );
			unless ( defined @$line[1] ) {
				Carp::confess(
"we have an error for the connection '$gene1' - '$gene2': we have no data!\n"
					  . root::get_hashEntries_as_string(
						$self->{'data'}, 3,
						"that was one entry in this dataset: "
					  )
					  . root::get_hashEntries_as_string(
						$line, 3, "We have the line: "
					  )
				);
				next;
			}
			$data_hash->{'Correlating gene'} =
			  "\\nameref{" . root->Latex_Label($gene2) . "}";
			$data_hash->{'$ R^2 $'} = $self->__get_R_squared_from_line($line);
			$data_hash->{'p value'} = $self->__get_p_value_from_line($line);
			$data_hash->{'arb. score'} = "$arbitryry_score"
			  if ( $hash->{'add_desciption_2_each_subsection'} );
			$data_table->Add_Dataset($data_hash);
			## I want to have the original correlation data in the PDF file!

			##invers_connection
			if (
				scalar( keys %{ $self->{'invers_connection'}->{$gene2} } ) > 1 )
			{
				$key = join( " ",
					sort ( keys %{ $self->{'invers_connection'}->{$gene2} } ) );
				unless ( defined $self->{'connection_groups'}->{$key} ) {
					$self->{'connection_groups'}->{$key} = {};

					#print "we create a connection group '$key'\n";
				}
				$self->{'connection_groups'}->{$key}->{$gene2} = 1;
				if ( defined $gene2 ) {
					$multi_connections[ $multi_i++ ] = "$gene2";
				}
			}
		}
		$latex_section .= $data_table->AsLatexLongtable();
	}
	foreach $key ( keys %{ $self->{'connection_groups'} } ) {
		$self->{'connection_groups'}->{$key} =
		  [ sort keys( %{ $self->{'connection_groups'}->{$key} } ) ];
	}

	$self->{ 'descriptionTable' . $hash->{'other_expression_net'} } =
	  $latex_section;
	return $latex_section;
}

=head2 __create_connection_dataset

Here I will create the 'connection_groups' dataset, that you will need for any LaTeX export.
This dataset will be an hash of arrays, where the hash keys are a space separated
list of seeder genes that are linked together by this group and the array contains all the genes, 
that are building up that group.

=cut

sub __create_connection_dataset {
	my ($self) = @_;
	return 1 if ( ref( $self->{'connection_groups'} ) eq "HASH" );
	$self->connection_exists()
	  ;    ## to create the connections if they are not existing!
	my ( $line, $key );

	foreach my $gene1 ( sort keys %{ $self->{'connection'} } ) {
		foreach my $gene2 (
			sort {
				@{ @{ $self->{'data'} }[ $self->{'connection'}->{$gene1}->{$a} ]
				  }[2] <=> @{ @{ $self->{'data'} }
					  [ $self->{'connection'}->{$gene1}->{$b} ] }[2]
			} keys %{ $self->{'connection'}->{$gene1} }
		  )
		{
			$line =
			  @{ $self->{'data'} }[ $self->{'connection'}->{$gene1}->{$gene2} ];
			Carp::confess(
"we have a problem here, because we have got a crappy gene2 '$gene2' (line "
				  . $self->{'connection'}->{$gene1}->{$gene2} . ")\n"
				  . join( ";", @$line )
				  . root::get_hashEntries_as_string( $self->{'data'}, 3,
					"the data structure:" )
				  . root::get_hashEntries_as_string( $self->{'gene1'}, 2,
					"gene 1 structure" )
				  . root::get_hashEntries_as_string(
					$self->{'gene2'}, 2, "gene 2 structure"
				  )
			) if ( $gene2 =~ m/^[\d\.Ee\-]+$/ );
			unless ( defined @$line[1] ) {
				Carp::confess(
"we have an error for the connection '$gene1' - '$gene2': we have no data!\n"
					  . root::get_hashEntries_as_string(
						$self->{'data'}, 3,
						"that was one entry in this dataset: "
					  )
					  . root::get_hashEntries_as_string(
						$line, 3, "We have the line: "
					  )
				);
			}

			## identify all seeder genes, this gene is correlated with!
			if (
				scalar( keys %{ $self->{'invers_connection'}->{$gene2} } ) > 1 )
			{
				## create the unique connection-group-name
				$key = join( " ",
					sort ( keys %{ $self->{'invers_connection'}->{$gene2} } ) );
				unless ( defined $self->{'connection_groups'}->{$key} ) {
					$self->{'connection_groups'}->{$key} = {};
				}
				## Add the gene to the group
				$self->{'connection_groups'}->{$key}->{$gene2} = 1;
			}
		}
	}
	foreach $key ( keys %{ $self->{'connection_groups'} } ) {
		$self->{'connection_groups'}->{$key} =
		  [ sort keys( %{ $self->{'connection_groups'}->{$key} } ) ];
	}
	return 1;
}

sub _store_connection_in_hash {
	my ( $self, $hash, $gene1, $gene2, $line ) = @_;
	my $return = 0;
	$hash->{$gene1} = {} unless ( defined $hash->{$gene1} );
	unless ( defined $hash->{$gene1}->{$gene2} ) {
		$return = 1;
	}
	$hash->{$gene1}->{$gene2} = $line;

	@{ $self->{'header'} }[ scalar( @{ $self->{'header'} } ) ] = $gene1
	  unless ( $self->{'defined'}->{$gene1} );
	$self->{'defined'}->{$gene1}   = 1;
	$self->{'notMarked'}->{$gene1} = 1;
	return $return;
}

sub Compare_to_Reference_list {
	my ( $self, $ref_gene_list ) = @_;
	return $self->{'percent overlap'}
	  . "\npercent all overlap\t$self->{'percent all overlap'}"
	  if ( defined $self->{'percent overlap'} );
	return undef unless ( ref($ref_gene_list) eq "ARRAY" );
	$self->connection_exists();
	my ( $match, $match_2_seeder );
	$match = $match_2_seeder = 0;

	foreach (@$ref_gene_list) {
		$match++          if ( $self->{'defined'}->{$_} );
		$match_2_seeder++ if ( $self->{'gene1'}->{$_} );
	}

	$self->{'percent overlap'} =
	  $match_2_seeder / scalar( @{ $self->{'initial_genes'} } );
	$self->{'percent all overlap'} =
	  $match / scalar( keys %{ $self->{'defined'} } );
	return $self->{'percent overlap'}
	  . "\npercent all overlap\t$self->{'percent all overlap'}";
}

=head2 connection_exists ( $gene1, $gene2 )

Here I initialize the internal variables 'connection', 
'invers_connection', 'defined', 'notMarked' and 'header'.

The 'connection' hash will contain a structure gene_1 => gene2 => 'data_id'.
The 'invers_connection' has the same structure, but a changed gene positions:
gene2 => gene_1 => 'data_id'.

I will return a ture value if I have any connection between $gene1 and $gene2
=cut

sub connection_exists {
	my ( $self, $gene1, $gene2 ) = @_;
	unless ( defined $self->{'connection'} ) {
		$self->{'connection'}        = {};
		$self->{'invers_connection'} = {};
		$self->{'defined'}           = {};
		$self->{'notMarked'}         = {};
		$self->{'header'}            = [];
		my $array;
		for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
			$array = @{ $self->{'data'} }[$i];
			$self->{'clc'} +=
			  $self->_store_connection_in_hash( $self->{'connection'},
				@$array[0], @$array[1], $i );

			#print "we had probably a connection add (?) ->$self->{'clc'}\n";
			$self->_store_connection_in_hash( $self->{'invers_connection'},
				@$array[1], @$array[0], $i );
		}
		my @new_genes;
		foreach ( keys %{ $self->{'defined'} } ) {
			push( @new_genes, $_ )
			  unless ( defined $self->{'connection'}->{$_} );
		}
		$self->{'initial_genes'} = [ keys %{ $self->{'connection'} } ];
		$self->{'new_genes'}     = \@new_genes;
	}
	return undef unless ( defined $gene1 );
	return $self->{'connection'}->{$gene1}->{$gene2}
	  if ( defined $self->{'connection'}->{$gene1}->{$gene2} );
	return $self->{'invers_connection'}->{$gene1}->{$gene2}
	  if ( defined $self->{'invers_connection'}->{$gene1}->{$gene2} );
	return undef;
}

sub __count_links {
	my ( $self, $min_links ) = @_;
	return $self->{'informative_genes'}
	  if ( ref( $self->{'informative_genes'} ) eq "HASH" );
	$min_links = 0 unless ( defined $min_links );

	$self->connection_exists( 'RAG1', 'RAG2' );

	my ($informative_genes);
	$informative_genes = {};
	foreach my $A ( @{ $self->{'header'} } ) {
		$self->{'connection'}->{$A} = {}
		  unless ( defined $self->{'connection'}->{$A} );
		foreach my $B ( keys %{ $self->{'connection'}->{$A} } ) {
			$informative_genes->{$B} = 0
			  unless ( defined $informative_genes->{$B} );
			$informative_genes->{$B}++;
		}
		$informative_genes->{$A} = 0
		  unless ( defined $informative_genes->{$A} );
		$informative_genes->{$A} +=
		  scalar( keys %{ $self->{'connection'}->{$A} } );
	}
	return $self->{'informative_genes'} = $informative_genes;
}

sub __get_genes_with_more_than_x_links {
	my ( $self, $min_links ) = @_;
	my $informative_genes = $self->__count_links();
	my $links             = 0;
	my @infomative_genes;
	foreach my $gene ( sort keys %$informative_genes ) {
		$infomative_genes[ $links++ ] = $gene
		  if ( $informative_genes->{$gene} >= $min_links );
	}
	return @infomative_genes;
}

sub output_type {
	my ( $self, $type ) = @_;
	if ( defined $type ) {
		$self->{"__output_type"} = $type;
	}
	elsif ( !defined $self->{"__output_type"} ) {
		$self->{"__output_type"} = "long";
	}
	return $self->{"__output_type"};
}

sub Connection_Groups_Description {
	my ( $self, $hash ) = @_;
	my $section_string = $self->__get_section_string($hash);
	my $data_table     = data_table->new();
	my $tables_path;
	$hash->{'otherDataset'} = []
	  unless ( ref( $hash->{'otherDataset'} ) eq "ARRAY" );
	$data_table->Add_2_Header('Correlating gene');
	foreach my $header (
		sort { $a <=> $b }
		keys %{
			$self->__create_columnEntry_OtherDataset( 'RAG1',
				@{ $hash->{'otherDataset'} } )
		}
	  )
	{
		next if ( $header eq 'Correlating gene' );
		$data_table->Add_2_Header($header);
	}
	my $str =
	  "\\$section_string" . "{Connection Groups}\n\\label{connectingGroups}\n";
	$self->getDescription_table();
	$self->__define_connection_groups();
	my ( $gene_description, $arbitryry_score, $sum, $matching_string, @scores,
		$matchingStrings, $i, $temp );
	my $entry_count = 0;
	foreach my $groupName (
		sort {
			my ( $x, $y ) = ( $a, $b );
			$x =~ s/$self->{'groupTag'}//;
			$y =~ s/$self->{'groupTag'}//;
			$x =~ s/ \(\d+\)//;
			$y =~ s/ \(\d+\)//;
			return $x <=> $y;
		} keys %{ $self->{'connection_group_description'} }
	  )
	{
		$str .=
		    "\\sub$section_string"
		  . "{Connection group $groupName}\n\\label{"
		  . root->Latex_Label($groupName) . "}\n\n";
		$str .= "This connection group connects the expression of the gene(s)";
		$data_table->delete_all_data();
		foreach my $gene (
			@{
				$self->{'connection_group_description'}->{$groupName}
				  ->{'genes_connected'}
			}
		  )
		{
			$data_table->Add_Dataset(
				{
					%{
						$self->__create_columnEntry_OtherDataset( $gene,
							@{ $hash->{'otherDataset'} } )
					  }
				}
			) if ( defined @{ $hash->{'otherDataset'} }[0] );
			$str .=
			  " \\nameref{" . root->Latex_Label("correlations-$gene") . "},";
		}
		chop($str);
		$str .= ".\n\n";

		$str .= "The group is built of the genes "
		  if ( $self->output_type() eq "long" );
		@scores          = ();
		$i               = $sum = 0;
		$matchingStrings = {};
		foreach my $gene (
			@{
				$self->{'connection_group_description'}->{$groupName}
				  ->{'connecting_genes'}
			}
		  )
		{
			$str .= " $gene," if ( $self->output_type() eq "long" );
			( $gene_description, $arbitryry_score, $matching_string ) =
			  $self->{'gene_description'}
			  ->determineInfluence_of_gene_on_desease( $gene,
				$self->{'desease'} );
			$scores[ $i++ ] = $arbitryry_score;
			$sum += $arbitryry_score;
			foreach my $match ( split( " ", $matching_string ) ) {
				$matchingStrings->{$match} = []
				  unless ( ref( $matchingStrings->{$match} ) eq "ARRAY" );
				push( @{ $matchingStrings->{$match} }, $gene );
			}
			$data_table->Add_Dataset(
				{
					%{
						$self->__create_columnEntry_OtherDataset( $gene,
							@{ $hash->{'otherDataset'} } )
					  }
				}
			) if ( defined @{ $hash->{'otherDataset'} }[0] );
		}
		if ( $self->output_type() eq "long" ) {
			chop($str);
			$str .= ".\n\n";
		}
		$entry_count++;
		if ( defined @{ $hash->{'otherDataset'} }[0] ) {
			if ( $self->output_type() eq "long" ) {

				#print "we add a loing description of the dataset!\n";
				$str .= $self->__describe_other_dataset(
					@{ $hash->{'otherDataset'} } );
			}
			elsif ( $entry_count == 1 ) {
				$str .= $self->__describe_other_dataset(
					@{ $hash->{'otherDataset'} } );
			}

			$str .= $data_table->AsLatexLongtable();
			if ( -d $hash->{'outpath'} ) {
				$tables_path =
				  "$hash->{'outpath'}/expression_net_description_tables";
				mkdir("$hash->{'outpath'}/expression_net_description_tables");
				if ( -d $tables_path ) {
					$temp = $groupName;
					$temp =~ s/ /_/g;
					$data_table->print2file("$tables_path/$temp.txt");
				}
				else {
					Carp::confess(
						    "oops - we could not open the path '$tables_path'\n"
						  . "perhaps you forgott to give me the outpath has entry '$hash->{'outpath'}'\\n"
					);
				}
			}
		}
		if ( $sum > 0 && $self->output_type() eq "long" ) {
			$str .=
"The grouping genes have a total $self->{'desease'} score of $sum,\n"
			  . "and they match the strings \n";
			$str .= "\\begin{description}\n";
			foreach my $match ( keys %$matchingStrings ) {
				$str .= "\\item[$match] ( "
				  . join( ", ", @{ $matchingStrings->{$match} } ) . " )\n";
			}
			$str .= "\\end{description}\n";
			$str .= ".\n\n";
		}

	}

	#print "and we return the string (first 100 chars)".substr($str,0,122)."\n";
	return $str;
}

sub getConnectionGroup_for_gene {
	my ( $self, $gene ) = @_;
	return '' unless ( defined $gene );
	return $self->{'connection'}->{$gene}
	  if ( defined $self->{'connection'}->{$gene} );
	return $self->{'invers_connection'}->{$gene}
	  if ( defined $self->{'invers_connection'}->{$gene} );
	return '';
}

=head2 __define_connection_groups

This function will group the genes that we have read from the input file into connection groups
using the internal function __create_connection_dataset().
While doing that it will count the amount of genes, that partizipate in the connection groups 
and the amount of connection groups created and store these value as
$self->{'cgg'} (connection group genes) and $self->{'cgc'} (connection group count).

After having used that function you could access the connection groups genes at 
$self->{'connection_group_description'}
		  ->{"$self->{'groupTag'}$group ($gene_count)"}->{'connecting_genes'} = [ <genes> ];
And the connected seeder genes at
$self->{'connection_group_description'}
		  ->{"$self->{'groupTag'}$group ($gene_count)"}->{'genes_connected'} = [ <genes> ];

When finished the function will return the the connection groups data structure (array).
=cut

sub __define_connection_groups {
	my ($self, $min_links ) = @_;
	return @{ $self->{'informative_genes'} }
	  if ( ref( $self->{'informative_genes'} ) eq "ARRAY" );

	my ( $group, @infomative_genes, $connections );
	$self->__create_connection_dataset();
	$self->{'connection_group_description'} = {};
	$group = 1;
	$min_links = 2 unless ( defined $min_links);
	my ( $gene_count, $temp, @temp );
	$self->{'cgc'} = $self->{'cgg'} = 0;
	$self->{'group_size'}       = [];
	$self->{'group_tags'}       = [];
	$self->{'max_seeder_group'} = 0;
	my $gene_names = {};

	foreach my $connected_genes (
		sort {
			scalar( @{ $self->{'connection_groups'}->{$b} } ) <=>
			  scalar( @{ $self->{'connection_groups'}->{$a} } )
		} keys %{ $self->{'connection_groups'} }
	  )
	{
		push( @{ $self->{'group_tags'} }, $connected_genes );
		@temp                       = split( " ", $connected_genes );
		$temp                       = scalar(@temp);
		$self->{'max_seeder_group'} = $temp
		  if ( $self->{'max_seeder_group'} < $temp );
		next if ($temp  < $min_links );
		print "We use the seeder group $connected_genes with $temp genes\n";
		$gene_count =
		  scalar( @{ $self->{'connection_groups'}->{$connected_genes} } );
		
		$self->{'cgc'}++;
		push( @{ $self->{'group_size'} }, $gene_count );
		

		foreach my $con ( split( " ", $connected_genes ) ) {
			unless ( defined $connections->{$con} ) {
				$connections->{$con} = {};
				$infomative_genes[@infomative_genes] = $con;
			}
			$connections->{$con}->{"$self->{'groupTag'}$group ($gene_count)"} =
			  1;
		}
		foreach ( @{ $self->{'connection_groups'}->{$connected_genes} } ) {
			$gene_names->{$_} = 1;
		}
		foreach ( split (" ",$connected_genes)){
			$gene_names->{$_} = 1;
		}
		$self->{'connection_group_description'}
		  ->{"$self->{'groupTag'}$group ($gene_count)"} = {};
		$self->{'connection_group_description'}
		  ->{"$self->{'groupTag'}$group ($gene_count)"}->{'connecting_genes'} =
		  $self->{'connection_groups'}->{$connected_genes};
		$self->{'connection_group_description'}
		  ->{"$self->{'groupTag'}$group ($gene_count)"}->{'genes_connected'} =
		  [ split( " ", $connected_genes ) ];
		$infomative_genes[@infomative_genes] =
		  "$self->{'groupTag'}$group ($gene_count)";
		$group++;
	}
	$self->{'cg_gene_list'} = [keys %{$gene_names}];
	$self->{'cgg'}        = scalar( keys %{$gene_names} );
	$self->{'gene_names'} = {};
	foreach ( keys %{ $self->{'gene2'} } ) {
		$self->{'gene_names'}->{$_} = 1;
	}
	$self->print2log( $self->__statistical_log_entry() );
	$self->{'informative_genes'}   = \@infomative_genes;
	$self->{'grouped_connections'} = $connections;
	$self->compare_to_phenotypes();
	$self->__internal_adding_function1();
	$self->identify_kegg_pathways();
	return @infomative_genes;
}

sub identify_kegg_pathways {
	my ($self) = @_;
	if ( defined $self->use_organism() ) {
		my ( $kegg_genes, $table, @lines );
		$kegg_genes = kegg_genes->new( root->getDBH(), $self->{'debug'} );
		$table = $kegg_genes->get_data_table_4_search(
			{
				'search_columns' => [ 'Gene_Symbol', 'pathway_name' ],
				'where'          => [
					[ 'Gene_Symbol',  '=', 'my_value' ],
					[ 'organism_tag', '=', 'my_value' ]
				],
				'order_by' => ['pathway_name']
			},
			[ keys %{ $self->{'defined'} } ],
			$self->use_organism()
		);
		unless ( ref($table->get_line_asHash(0)) eq "HASH" ){
			warn "you tried to add some KEGG pathway statistics, "
				."but unfortunately I could not get information on the gene list "
				."from the database using the search" . $kegg_genes->{'complex_search'}."\n";
			return 0;
		}
		$table->createIndex('pathway_name');
		foreach my $pathway_name ( $table->getIndex_Keys('pathway_name') ){
			@lines =
	 		 $table->get_rowNumbers_4_columnName_and_Entry( 'pathway_name', $pathway_name);
	 		$self->print2log( "KEGG_$pathway_name\t".scalar(@lines)."\n");
		}
	}
	return 1;
}

sub Add_Phenotype_Informations {
	my ( $self, @phenotype_files ) = @_;
	my $data_table = data_table->new();
	my @temp;
	foreach my $file (@phenotype_files) {
		$self->{'phenotypes'} = {}
		  unless ( ref( $self->{'phenotypes'} ) eq "HASH" );
		next unless ( -f $file );
		$data_table->delete_all_data();
		$data_table->read_file($file);
		@temp = split( "/", $file );
		$file = $temp[ @temp - 1 ];
		$file =~ s/\.txt$//;
		$self->{'phenotypes'}->{$file} = {};
		
		foreach ( @{ $data_table->getAsArray('Gene Symbol') } ) {
			$self->{'phenotypes'}->{$file}->{$_} = 1;

			#print "we added the gene '$_' for phenotype $file\n";
		}
	}
	return 1;
}

sub compare_to_phenotypes {
	my ($self) = @_;
	my ( $gene_name, $phenotype_name, $genes_in_phenotype, $total_genes,
		@temp );

	if ( ref( $self->{'phenotypes'} ) eq "HASH" ) {
		$self->print2log("\n");
		@temp               = keys %{ $self->{'gene_names'} };
		$total_genes        = scalar(@temp);
		$genes_in_phenotype = 0;
		foreach $phenotype_name ( keys %{ $self->{'phenotypes'} } ) {
			foreach $gene_name (@temp) {
				if ( $self->{'phenotypes'}->{$phenotype_name}->{$gene_name} ) {
					$genes_in_phenotype++;

#print "we had a match to gene '$gene_name' in the phenotype $phenotype_name\n";
				}
			}
			$self->print2log( "$phenotype_name\t"
				  . ( $genes_in_phenotype / $total_genes )
				  . "\n" );
		}
	}
	return 1;
}

sub __statistical_log_entry {
	my ($self) = @_;
	if ( defined $self->Compare_to_Reference_list() ) {
		return
		    "\ngenes:\t"
		  . join( ';', ( sort @{ $self->{'initial_genes'} } ) ) . "\n"
		  . "data type\tvalue",
		  "amount of seeder genes\t" . scalar( @{ $self->{'initial_genes'} } ),
		  "connection groups\t$self->{'cgc'}",
		  "genes in connection groups\t$self->{'cgg'}",
		  "group_size\t" . join( ";", @{ $self->{'group_size'} } ),
		  "group_tags\t" . join( ";", @{ $self->{'group_tags'} } ),
		  "max seeder group\t$self->{'max_seeder_group'}",
		  "overall links\t$self->{'clc'}",
		  "overall genes\t" . scalar( keys %{ $self->{'gene_names'} } ),
		  "percent overlap\t" . $self->Compare_to_Reference_list();
	}
	return
	    "\ngenes:\t"
	  . join( ';', ( sort @{ $self->{'initial_genes'} } ) ) . "\n"
	  . "data type\tvalue",
	  "amount of seeder genes\t" . scalar( @{ $self->{'initial_genes'} } ),
	  "connection groups\t$self->{'cgc'}",
	  "genes in connection groups\t$self->{'cgg'}",
	  "group_size\t" . join( ";", @{ $self->{'group_size'} } ),
	  "group_tags\t" . join( ";", @{ $self->{'group_tags'} } ),
	  "max seeder group\t$self->{'max_seeder_group'}",
	  "overall links\t$self->{'clc'}",
	  "overall genes\t" . scalar( keys %{ $self->{'gene_names'} } );
}

sub __internal_adding_function1 {
	my ($self) = @_;
	foreach my $A ( $self->__define_connection_groups() ) {
		$self->{'grouped_connections'}->{$A} = {}
		  unless ( defined $self->{'grouped_connections'}->{$A} );
		foreach my $B ( $self->__define_connection_groups() ) {
		}
	}
	return 1;
}

sub getAs_R_matrix {
	my ( $self, $outfile, $min_links ) = @_;

	my $str = "library(network)\n";

	$self->__get_genes_with_more_than_x_links($min_links);
	$self->getDescription_table()
	  unless ( ref( $self->{'connection_groups'} ) eq "HASH" );

	my @infomative_genes = $self->__define_connection_groups($min_links);
	my @matrix;

	foreach my $A ( $self->__define_connection_groups($min_links) ) {
		$self->{'grouped_connections'}->{$A} = {}
		  unless ( defined $self->{'grouped_connections'}->{$A} );
		foreach my $B ( $self->__define_connection_groups($min_links) ) {
			if ( $self->{'grouped_connections'}->{$A}->{$B} ) {
				push( @matrix, 1 );
			}
			else {
				push( @matrix, 0 );
			}
		}
	}

	my $res = int( scalar(@matrix) / 1000 );
	$res = 30 if ( $res > 30 );
	$res = 10 if ( $res < 10 );
	$str .=
	    "A <- matrix (c ("
	  . join( ", ", @matrix ) . "), "
	  . scalar( $self->__define_connection_groups() ) . ", "
	  . scalar( $self->__define_connection_groups() ) . ")\n\n";
	$str .=
	    "colnames(A) <- c('"
	  . join( "', '", $self->__define_connection_groups() ) . "')\n"
	  . "rownames(A) <- c('"
	  . join( "', '", $self->__define_connection_groups() ) . "')\n"
	  . "net <- as.network(A,  loops = TRUE,  directed =FALSE)\n"
	  . "svg('$outfile/pic.svg', width= $res, height = $res)\n"
	  . "\nplot(net, boxed.labels = TRUE, displaylabels = TRUE)\n"
	  ;    #dev.new(pdf,file='$outfile/pic.pdf')\n";
	$self->{'outfile'} = "$outfile/pic.svg";
	$str .= "dev.off()\n";
	return $str;
}

sub getAs_R_matrix_only_seeder_connections {
	my ( $self, $outfile, $min_links ) = @_;

	my $str = "library(network)\n";

	$self->__get_genes_with_more_than_x_links($min_links);
	$self->getDescription_table()
	  unless ( ref( $self->{'connection_groups'} ) eq "HASH" );

	my @infomative_genes = $self->__define_connection_groups();
	my @matrix;

	foreach my $A ( $self->__define_connection_groups() ) {
		$self->{'grouped_connections'}->{$A} = {}
		  unless ( defined $self->{'grouped_connections'}->{$A} );
		foreach my $B ( $self->__define_connection_groups() ) {
			if ( $self->{'grouped_connections'}->{$A}->{$B} ) {
				push( @matrix, 1 );
			}
			else {
				push( @matrix, 0 );
			}
		}
	}

	my $res = int( scalar(@matrix) / 1000 );
	$res = 30 if ( $res > 30 );
	$res = 10 if ( $res < 10 );
	$str .=
	    "A <- matrix (c ("
	  . join( ", ", @matrix ) . "), "
	  . scalar( $self->__define_connection_groups() ) . ", "
	  . scalar( $self->__define_connection_groups() ) . ")\n\n";
	$str .=
	    "colnames(A) <- c('"
	  . join( "', '", $self->__define_connection_groups() ) . "')\n"
	  . "rownames(A) <- c('"
	  . join( "', '", $self->__define_connection_groups() ) . "')\n"
	  . "net <- as.network(A,  loops = TRUE,  directed =FALSE)\n"
	  . "svg('$outfile/pic.svg', width= $res, height = $res)\n"
	  . "\nplot(net, boxed.labels = TRUE, displaylabels = TRUE)\n"
	  ;    #dev.new(pdf,file='$outfile/pic.pdf')\n";
	$self->{'outfile'} = "$outfile/pic.svg";
	$str .= "dev.off()\n";
	return $str;
}


sub use_organism {
	my ( $self, $organism_tag ) = @_;
	$self->{'organism_tag'} = $organism_tag if ( defined $organism_tag );
	return $self->{'organism_tag'};
}

sub translate_SEPT_genes {
	my ( $self, @line ) = @_;
	my $entry;
	for ( my $i = 0 ; $i < @line ; $i++ ) {
		if ( $line[$i] =~ m/(\d+)_(.*)/ ) {
			$line[$i] = $self->{'SEPT'}->{$1}
			  if ( defined $self->{'SEPT'}->{$1} );
			if ( "$1_$2" eq $line[$i] ) {
				## fuck - the probe descriptions were not OK - try to get the right return value
				$entry = $2;
				if ( $entry =~ m/(\d)(\d). Sep/ ) {
					if ( $1 > 0 ) {
						$line[$i] = "SEPT$1$2";
					}
					else {
						$line[$i] = "SEPT$2";
					}
				}
			}

			#print "We exchanged $1_$2 to $line[$i]\n";
		}
	}
	return @line;
}

sub AddSEPT_HASH {
	my ($self) = @_;
	$self->{'SEPT'} = {
		"7999207" => "SEPT12",
		"7999208" => "SEPT12",
		"7999209" => "SEPT12",
		"7999210" => "SEPT12",
		"7999211" => "SEPT12",
		"7999212" => "SEPT12",
		"7999213" => "SEPT12",
		"7999214" => "SEPT12",
		"7999215" => "SEPT12",
		"7999216" => "SEPT12",
		"8000870" => "SEPT1",
		"8000871" => "SEPT1",
		"8000872" => "SEPT1",
		"8000873" => "SEPT1",
		"8000874" => "SEPT1",
		"8000875" => "SEPT1",
		"8000876" => "SEPT1",
		"8000877" => "SEPT1",
		"8000878" => "SEPT1",
		"8000879" => "SEPT1",
		"8000880" => "SEPT1",
		"8000881" => "SEPT1",
		"8010162" => "SEPT9",
		"8010163" => "SEPT9",
		"8010164" => "SEPT9",
		"8010165" => "SEPT9",
		"8010166" => "SEPT9",
		"8010167" => "SEPT9",
		"8010168" => "SEPT9",
		"8010169" => "SEPT9",
		"8010170" => "SEPT9",
		"8010171" => "SEPT9",
		"8010172" => "SEPT9",
		"8010173" => "SEPT9",
		"8010174" => "SEPT9",
		"8010175" => "SEPT9",
		"8010176" => "SEPT9",
		"8010177" => "SEPT9",
		"8010178" => "SEPT9",
		"8010179" => "SEPT9",
		"8010180" => "SEPT9",
		"8010181" => "SEPT9",
		"8010182" => "SEPT9",
		"8010183" => "SEPT9",
		"8017040" => "SEPT4",
		"8017041" => "SEPT4",
		"8017042" => "SEPT4",
		"8017043" => "SEPT4",
		"8017044" => "SEPT4",
		"8017045" => "SEPT4",
		"8017046" => "SEPT4",
		"8017047" => "SEPT4",
		"8017048" => "SEPT4",
		"8017049" => "SEPT4",
		"8017050" => "SEPT4",
		"8017051" => "SEPT4",
		"8017052" => "SEPT4",
		"8017053" => "SEPT4",
		"8017054" => "SEPT4",
		"8017055" => "SEPT4",
		"8017056" => "SEPT4",
		"8049828" => "SEPT2",
		"8049829" => "SEPT2",
		"8049830" => "SEPT2",
		"8049831" => "SEPT2",
		"8049832" => "SEPT2",
		"8049833" => "SEPT2",
		"8049834" => "SEPT2",
		"8049835" => "SEPT2",
		"8049836" => "SEPT2",
		"8049837" => "SEPT2",
		"8049838" => "SEPT2",
		"8049839" => "SEPT2",
		"8049840" => "SEPT2",
		"8049841" => "SEPT2",
		"8049842" => "SEPT2",
		"8049843" => "SEPT2",
		"8049844" => "SEPT2",
		"8049845" => "SEPT2",
		"8049846" => "SEPT2",
		"8054468" => "SEPT10",
		"8054469" => "SEPT10",
		"8054470" => "SEPT10",
		"8054471" => "SEPT10",
		"8054472" => "SEPT10",
		"8054473" => "SEPT10",
		"8054474" => "SEPT10",
		"8054475" => "SEPT10",
		"8054476" => "SEPT10",
		"8071235" => "SEPT5",
		"8071236" => "SEPT5",
		"8071237" => "SEPT5",
		"8071238" => "SEPT5",
		"8071239" => "SEPT5",
		"8071240" => "SEPT5",
		"8071241" => "SEPT5",
		"8071242" => "SEPT5",
		"8071243" => "SEPT5",
		"8071244" => "SEPT5",
		"8071245" => "SEPT5",
		"8071246" => "SEPT5",
		"8071247" => "SEPT5",
		"8071248" => "SEPT5",
		"8071249" => "SEPT5",
		"8071250" => "SEPT5",
		"8071251" => "SEPT5",
		"8071252" => "SEPT5",
		"8071253" => "SEPT5",
		"8071254" => "SEPT5",
		"8071255" => "SEPT5",
		"8071256" => "SEPT5",
		"8071257" => "SEPT5",
		"8071258" => "SEPT5",
		"8071260" => "SEPT5",
		"8071261" => "SEPT5",
		"8071262" => "SEPT5",
		"8071263" => "SEPT5",
		"8071264" => "SEPT5",
		"8071265" => "SEPT5",
		"8071266" => "SEPT5",
		"8071269" => "SEPT5",
		"8071270" => "SEPT5",
		"8071271" => "SEPT5",
		"8073549" => "SEPT3",
		"8073550" => "SEPT3",
		"8073551" => "SEPT3",
		"8073552" => "SEPT3",
		"8073553" => "SEPT3",
		"8073554" => "SEPT3",
		"8073555" => "SEPT3",
		"8073556" => "SEPT3",
		"8073557" => "SEPT3",
		"8073558" => "SEPT3",
		"8073559" => "SEPT3",
		"8073560" => "SEPT3",
		"8073561" => "SEPT3",
		"8095855" => "SEPT11",
		"8095856" => "SEPT11",
		"8095857" => "SEPT11",
		"8095858" => "SEPT11",
		"8095859" => "SEPT11",
		"8095860" => "SEPT11",
		"8095861" => "SEPT11",
		"8095862" => "SEPT11",
		"8095863" => "SEPT11",
		"8095864" => "SEPT11",
		"8095865" => "SEPT11",
		"8095866" => "SEPT11",
		"8095867" => "SEPT11",
		"8114051" => "SEPT8",
		"8114052" => "SEPT8",
		"8114053" => "SEPT8",
		"8114054" => "SEPT8",
		"8114055" => "SEPT8",
		"8114056" => "SEPT8",
		"8114057" => "SEPT8",
		"8114058" => "SEPT8",
		"8114059" => "SEPT8",
		"8114060" => "SEPT8",
		"8114062" => "SEPT8",
		"8114063" => "SEPT8",
		"8114064" => "SEPT8",
		"8114065" => "SEPT8",
		"8114066" => "SEPT8",
		"8114067" => "SEPT8",
		"8132293" => "SEPT7",
		"8132294" => "SEPT7",
		"8132295" => "SEPT7",
		"8132296" => "SEPT7",
		"8132297" => "SEPT7",
		"8132298" => "SEPT7",
		"8132299" => "SEPT7",
		"8132300" => "SEPT7",
		"8132301" => "SEPT7",
		"8139728" => "SEPT14",
		"8139729" => "SEPT14",
		"8139730" => "SEPT14",
		"8139731" => "SEPT14",
		"8139732" => "SEPT14",
		"8139733" => "SEPT14",
		"8139734" => "SEPT14",
		"8139735" => "SEPT14",
		"8139736" => "SEPT14",
		"8174693" => "SEPT6",
		"8174694" => "SEPT6",
		"8174695" => "SEPT6",
		"8174696" => "SEPT6",
		"8174697" => "SEPT6",
		"8174698" => "SEPT6",
		"8174699" => "SEPT6",
		"8174700" => "SEPT6",
		"8174701" => "SEPT6",
		"8174702" => "SEPT6",
		"8174703" => "SEPT6",
		"8174704" => "SEPT6",
		"8174705" => "SEPT6",
		"8174706" => "SEPT6",
		"8174707" => "SEPT6",
		"8174708" => "SEPT6",
		"8174709" => "SEPT6"
	};
	return 1;
}

1;
