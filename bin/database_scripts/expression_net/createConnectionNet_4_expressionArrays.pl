#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::correlatingData;
use stefans_libs::root;

#use stefans_libs::database::experiment;
#use stefans_libs::database::expression_net;
#use stefans_libs::database::expression_estimate;

use Getopt::Long;
use FileHandle;

my (
	$infile,         $outfile,       $pattern,    $help,
	$phenothpeTable, $debug,         @phenotypes, @genes,
	$cutOff,         $start_at_line, @pattern,    $r_cutoff, $randomNumber, $format
);

Getopt::Long::GetOptions(
	"-array_values=s"            => \$infile,
	"-outfile=s"                 => \$outfile,
	"-p4cS=s{,}"                 => \@pattern,
	"-start_at_line=s"           => \$start_at_line,
	"-help"                      => \$help,
	"-p_value=s"                 => \$cutOff,
	"-r_cutoff=s"                => \$r_cutoff,
	"-debug"                     => \$debug,
	"-correlate_with_genes=s{,}" => \@genes,
	"-amount_of_random_genes=s"  => \$randomNumber,
	'-format=s'                  => \$format
) or die &helpString();

$pattern = $pattern[0];

die &helpString()
  unless ( defined $infile && defined $outfile );

die &helpString() if ($help);

my $warn = '';
my $error = '';

unless ( -f $infile) {
        $error .= "the cmd line switch -array_values is undefined!\n";
}
unless ( defined $cutOff) {
		$cutOff = 0.05;
        $warn .= "-p_value was set to 0.05\n";
}
unless ( defined $outfile) {
        $error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( $format ){
	$format = 'long';
}
unless ( defined  $r_cutoff ){
	$r_cutoff = 0;
}
unless ( defined $pattern[0]) {
        $error .= "the cmd line switch -p4cS is undefined!\n";
}
unless ( defined $start_at_line) {
		$start_at_line = 1 unless ( defined $start_at_line );
        $warn .= "-start_at_line set to 1!\n";
}
if ( $start_at_line < 1 ){
	$start_at_line = 1;
}
unless ( defined $randomNumber) {
        $warn .= "the cmd line switch -amount_of_random_genes is undefined!\n";
}


if ( $help ){
        print helpString( ) ;
        exit;
}

if ( $error =~ m/\w/ ){
        print helpString( $error ) ;
        exit;
}


sub helpString {
	return "
 command line switches for createConnectionNet_4_expressionArrays.pl:
 
   -array_values   :the table file containing the expresion values (tab separated)
   -p_value        :the max p value for the reported test statistics
   -r_cutoff       :the min R_square value to be used (defaults to 0)
   -outfile        :the name of the outfile (<tab> separated table)
   -p4cS           :the pattern to select the data containing columns
   -start_at_line  :the first lie to start the calculation
   
   -correlate_with_genes
                   :a list of genes for which you want to calculate 
                    the correlation with all the other genes
   -amount_of_random_genes
                   :using this will add a a number of randomly selected genes to
                    the 'correlate_with_genes' genes
      
   -help   :print this help
   -debug  :verbose output
 "
}

my ( $correlatingData, $lineCount );
## 1. read the phenotype data

$correlatingData = correlatingData->new($debug);

my @outfile = split( "/", $outfile );
pop(@outfile);

my $outPath = join( "/", @outfile );
mkdir($outPath) unless ( -d $outPath );

my (
	@possibleGroupingValues, @statObjects,
	$groupTag,               @dataColumnHeaders,
	$tableHandling,          $filename,
	@temp,                   $infoPositions,
	$temp,                   $statTests_per_TableLine,
	$data_array,             $this_str,
	$dataPositions,          $already_processed
);

$tableHandling = tableHandling->new();


open( IN, "<$infile" )
  or die "could not open array data file '$infile' in batchStatistic.pl\n";
print "opened the expression array dataset $infile\n";
$lineCount = 0;
my $statObj;
my @data_array = (<IN>);
close(IN);

## which columns contain the data?
unless ( defined $pattern[1] ) {
	$dataPositions =
	  $tableHandling->identify_columns_of_interest_patternMatch( $data_array[0],
		$pattern );
}
else {
	$dataPositions =
	  $tableHandling->identify_columns_of_interest_bySearchHash( $data_array[0],
		$tableHandling->createSearchHash(@pattern) );
}
@dataColumnHeaders =
  $tableHandling->get_column_entries_4_columns( $data_array[0],
	$dataPositions );
##Get me the Gene Symbol column
die "we did not identify enough data columns using the header line "
  . join( "; ", split( "\t", $dataColumnHeaders[1] ) )."\n"
  unless ( defined $dataColumnHeaders[1] );
$infoPositions =
  $tableHandling->identify_columns_of_interest_bySearchHash( $data_array[0],
	$tableHandling->createSearchHash( "Gene Symbol", "Probe Set ID" ) );
	
#print "we have idenitfied the data columns ".join ("; ",@dataColumnHeaders)." using the line\n$data_array[0]\n";
my $header     = '';
my $log_header = '';
my $sign;
$correlatingData->{referenceLine} = $data_array[0];

if ( -f $outfile ) {
	$already_processed = &get_already_processed_seeder_genes ( $outfile );
	open( OUT, ">>$outfile" ) or die "could not create outfile '$outfile'\$!\n";
	open( LOG, ">>$outfile.log" )
	  or die "could not create log file '$outfile.log' \n$!\n";
}
else {
	$header = "gene\tcorrelating gene\tP_value\tS\tR_square\n";
	$log_header =
	  "correlating gene\tamount of genes correlating with p<$cutOff\n";
	open( OUT, ">$outfile" ) or die "could not create outfile '$outfile'\$!\n";
	print OUT $header;
	open( LOG, ">$outfile.log" )
	  or die "could not create log file '$outfile.log' \n$!\n";
	print LOG join("\t", @dataColumnHeaders)."\n" . $log_header;
}
close(OUT);

if ( defined $randomNumber ) {
	my ( $rand_genes, $i, @line );
	while ( scalar( keys %$rand_genes ) < $randomNumber ) {
		$i = int( rand( scalar(@data_array) - 1 ) ) + 1;
		@line = split( "\t", $data_array[$i] );
		$line[ @$infoPositions[1] ] =~ s/ *//g;
		next if ( $line[ @$infoPositions[1] ] eq "---");
		$rand_genes->{ $line[ @$infoPositions[1] ] } = 1;
	}
	print LOG "random Genes\t" . join( "\t", keys %$rand_genes ) . "\n";
	unless ( defined $genes[0] ) {
		@genes = ( keys %$rand_genes );
	}
	else {
		push( @genes, keys %$rand_genes );
	}

}

unless ( defined $genes[0] ) {
        $error .= "the cmd line switch -correlate_with_genes is undefined!\n";
}
elsif ( -f $genes[0]){
	print "the list of genes is a file - I expect to find ONLY gene names in that file!\n";
	open (G, "<$genes[0]") or die "could not open genes file '$genes[0]'\n";
	@genes = undef;
	my $i = 0;
	while ( <G> ){
		chomp $_;
		foreach my $gene ( split ( /[ \t]/,$_) ){
			$genes[$i++] = $gene;
		}
	}
	close ( G );
	print "we read the gens ".join("; ", @genes )."\n";
}

my $task_description = "createConnectionNet_4_expressionArrays.pl -array_values $infile -p_value $cutOff";
$task_description .= " -p4cS '".join("' '", @pattern)."'";
$task_description .= " -start_at_line $start_at_line";
$task_description .= " -correlate_with_genes '".join( "' '",@genes)."'" if ( defined $genes[0]);
$task_description .= " -amount_of_random_genes $randomNumber" if ( defined $randomNumber);
$task_description .= " -outfile $outfile";
$task_description .= " -r_cutoff $r_cutoff";

print LOG "#cmd (random genes are part of genes call!)\n$task_description";

if ( $randomNumber > 0){
	print LOG join("\n",@genes);
	if ( -f $outfile.'.gene_lists'){
		open ( GENES ,">>$outfile.gene_lists");
		
	}
	else {
		open ( GENES ,">$outfile.gene_lists");
	}
	print GENES join(" ",@genes)."\n";
	close ( GENES );
	print "gene list written to file $outfile.gene_lists\n";
#	close LOG;
#	die "I did not want to do anything else than to create a reandom list of genes!\n$outfile.log\n";
}
if ( $debug ) {
	print "our command:\n$task_description\n";
	exit;
}
my ( $correlating_data, $already_analyzed_datasets, $previous_datasets );
$already_analyzed_datasets = {};
if ( defined $genes[0] ) {
	## we only correlate some genes with all the other datasets
	$header = join( " ", @genes );

	$sign = 0;
	for ( my $i = 0 ; $i < @data_array ; $i++ ) {
		chomp( $data_array[$i] );
		$this_str = join(
			"_",
			$tableHandling->get_column_entries_4_columns(
				$data_array[$i], $infoPositions
			)
		);
		$this_str = $1 if ( $this_str =~ m/ *([\w-]+) *$/ );

		#print "we match '$header' to '$this_str'\n";
		next unless ( &geen_is_needed( $this_str, @genes ) );
		if ( $already_processed->{$this_str}){
			warn "we have already analyzed the gene $this_str\n\tSkipp gene $this_str\n";
			next;
		}
		#print " $header matches to $this_str\n";
		## now we have one gene we are interested in!
		$correlatingData->{data}->{$this_str} = $data_array[$i];
		$statObj = $correlatingData->getStatObj_4_dataLine_and_correlationValue(
			\@dataColumnHeaders, $this_str );
		$log_header = $data_array[0];
		$statObj->processTableHeader( $log_header, $infoPositions );
		$correlating_data = join(" ",@{$statObj->{'corelatingValues'}});
		foreach $previous_datasets ( keys %$already_analyzed_datasets ){
			if ($correlating_data eq $already_analyzed_datasets->{$previous_datasets}){
				&copy_results_from_to($previous_datasets, $this_str );
				$already_analyzed_datasets->{$this_str} = $correlating_data;
			}
		}
		next if ( defined $already_analyzed_datasets->{$this_str});
		$already_analyzed_datasets->{$this_str} = $correlating_data;
		open( OUT, ">>$outfile" ) or die "could not create outfile '$outfile'\$!\n";
		for ( my $data_nr = 0 ; $data_nr < @data_array ; $data_nr++ ) {

	   #warn "\ngetTest_result\n";
	   #print root::get_hashEntries_as_string ($statObj, 3, "the stat object ");
			$temp = $statObj->getTest_result( $data_array[$data_nr], 1 );

			#warn "warnings\n";
			if ( $statObj->error() ) {
				warn $statObj->error();
				next;
			}

			#warn "last P $statObj->{lastP}\n";
			#print $statObj->{lastP}."\n";
			if (   $statObj->{lastP} < $cutOff
				&& $statObj->{lastP} > 0 && ( $statObj->{lastR} <= -$r_cutoff || $statObj->{lastR} >= $r_cutoff) )
			{
				$sign++;
				@temp = split( "\t", $temp );
				print OUT join( "\t",
					( $this_str, $temp[0]."_". $temp[1], $temp[2], $temp[3], $temp[4] ) )
				  . "\n";
				#print "we got a rsquared of $temp[4]\n";#\t'".join("' '",@temp)."'\n";
			#	die "WE did not recieve a Rsquared value from these values\n$data_array[$data_nr]\n" unless (defined $temp[3]);
 #print OUT join ("\t",( $temp[0],$this_str,$temp[1],$temp[2],$temp[3] ) )."\n";
 #print "temp = ".$temp."\n";
			}

		}
		close(OUT);
		print LOG "$this_str\t$sign\n";
		$statObj->DESTROY();
	}
	print "we are ready with our gene search using the genes ".join("; ",@genes)."\n";

}
else {
	for (
		my $correlation_nr = $start_at_line ;
		$correlation_nr < @data_array ;
		$correlation_nr++
	  )
	{
		$sign = 0;
		chomp( $data_array[$correlation_nr] );
		$this_str = join(
			"_",
			$tableHandling->get_column_entries_4_columns(
				$data_array[$correlation_nr],
				$infoPositions
			)
		);
		$correlatingData->{data}->{$this_str} = $data_array[$correlation_nr];
		$statObj = $correlatingData->getStatObj_4_dataLine_and_correlationValue(
			\@dataColumnHeaders, $this_str );
		$statObj->processTableHeader( $data_array[0], $infoPositions );

		#$statObj -> AddGroupingHash ();

		for (
			my $data_nr = $correlation_nr + 1 ;
			$data_nr < @data_array ;
			$data_nr++
		  )
		{
			## correlate the data!
			$temp = $statObj->getTest_result( $data_array[$data_nr], 1 );
			if ( $statObj->error() ) {
				warn $statObj->error();
				next;
			}

			if (   $statObj->{lastP} < $cutOff
				&& $statObj->{lastP} > 0 )
			{
				$sign++;
				@temp = split( "\t", $temp );
				print OUT join( "\t",
					( $this_str, $temp[0], $temp[1], $temp[2], $temp[3] ) )
				  . "\n";
				print OUT join( "\t",
					( $temp[0], $this_str, $temp[1], $temp[2], $temp[3] ) )
				  . "\n";

				#print "temp = ".$temp."\n";
			}
		}
		print LOG "$this_str\t$sign\n";
		$statObj->DESTROY();
	}
}

sub get_already_processed_seeder_genes{
	my ( $filename ) = @_;
	return {} unless ( -f $filename);
	my ( @line, $return );
	open (IN , "<$filename");
	while ( <IN> ){
		next if ( $_ =~ m/^#/);
		@line = split( "\t",$_);
		$return->{$line[0]} = 1;
	}
	close ( IN );
	return $return;
}

sub copy_results_from_to{
	my ( $old_tag, $new_tag ) = @_;
	open ( IN , "<$outfile") or die "could not open the outfile $outfile\n$!\n";
	my (@add, @line );
	while ( <IN> ){
		if ( $_ =~ m/^$old_tag/){
			@line = split ( "\t", $_);
			$line[0] = $new_tag;
			push ( @add ,join("\t",@line));
		}
	}
	close ( IN );
	if ( defined $add[0]){
		open ( OUT ,">>$outfile") or die "could not open outfile $outfile for writing!\$!\n";
		print OUT join ("",@add);
		close ( OUT );
	}
	return 1;
}

sub geen_is_needed {
	my ( $gene, @genes ) = @_;
	$gene = $2 if ( $gene =~ m/^(.+)_(.+)$/ );
	#print "we got so valiadtae the gene '$gene'\n";
	$gene =~ s/^ *//;
	$gene =~ s/ *$//;
	foreach my $g (@genes) {
		return 1 if ( $g eq $gene );
	}
	return 0;
}

close(LOG);
