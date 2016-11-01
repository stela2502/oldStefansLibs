#! /usr/bin/perl

use strict;

use stefans_libs::array_analysis::correlatingData;
use stefans_libs::root;
use stefans_libs::tableHandling;    #this is actually
use Getopt::Long;
use FileHandle;
use FindBin;
use Shell qw(ps kill killall);
use Digest::MD5 qw(md5_hex);

my $path = "$FindBin::Bin";

my (
	@infile,           $outfile, @pattern,    $help,
	@phenothpeTable,   $debug,   @phenotypes, $cutOff,
	$no_heterozygotes, @gene_names, $prcoess_nr
);

Getopt::Long::GetOptions(
	"-array_values=s{,}"   => \@infile,
	"-outfile=s"           => \$outfile,
	"-p4cS=s{,}"           => \@pattern,
	"-gene_names=s{,}"     => \@gene_names,
	"-help"                => \$help,
	"-no_heterozygotes"    => \$no_heterozygotes,
	"-phenotypeTable=s{,}" => \@phenothpeTable,
	"-p_value=s"           => \$cutOff,
	"-phenotypes=s{,}"     => \@phenotypes,
	"-prcoess_nr=s"        => 
	"-debug"               => \$debug
) or die &helpString();

die &helpString()
  unless ( defined $infile[0]
	&& defined $outfile
	&& defined $phenothpeTable[0] );

die &helpString() if ($help);

my $error = '';
$error .= "we need to know which genes I should use to do the correlation!\n"
  unless ( defined $gene_names[0] );

die &helpString($error) if ( $error =~ m/\w/ );

warn "we got these patterns 4 column search: '"
  . join( "', '", @pattern ) . "'\n";

sub helpString {
	my ($error) = @_;
	$error |= '';
	return "
	$error
	
 command line switches for SNP_2_Gene_Expression.pl:
 
   -array_values   :the table file containing the expresion values (tab separated)
   -phenotypeTable :the table containing the phenotypic data set (tab separated)
   -phenotypes     :a semicolon separated list of wanted phenotypes (included in the phenotypeTable!)
   -p_value        :the max p value for the reported test statistics
   -gene_names     :a way to select only one or several genes to do the correlation for (needed!)
   -no_heterozygotes :exclude heterozygote samples (per genotype)
   -outfile        :the name of the outfile (<tab> separated table)
   -p4cS           :the pattern to select the data containing columns
   -help           :print this help
   -debug          :verbose output
 "
}

	unless ( -f $infile[0] ) {
		$error .= "the cmd line switch -array_values is undefined!\n";
	}
	unless ( -f  $phenothpeTable[0] ) {
		$error .= "the cmd line switch -phenotypeTable is undefined!\n";
	}
	unless ( defined $cutOff ) {
		$error .= "the cmd line switch -p_value is undefined!\n";
	}
	unless ( defined $gene_names[0] ) {
		$error .= "the cmd line switch -gene_names is undefined!\n";
	}
	unless ( defined $outfile ) {
		$error .= "the cmd line switch -outfile is undefined!\n";
	}
	unless ( defined $pattern[0] ) {
		$error .= "the cmd line switch -p4cS is undefined!\n";
	}


my ( $task_description);

$task_description .= "perl ".root->perl_include()." $0";
$task_description .= ' -array_values '.join( ' ', @infile ) if ( defined $infile[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= ' -p4cS "'.join( '" "', @pattern ).'"' if ( defined $pattern[0]);
$task_description .= ' -gene_names '.join( ' ', @gene_names ) if ( defined $gene_names[0]);
$task_description .= " -no_heterozygotes $no_heterozygotes" if (defined $no_heterozygotes);
$task_description .= " -p_value $cutOff" if (defined $cutOff);
$task_description .= " -phenotypes '".join("' '",@phenotypes)."'" if (defined $phenotypes[0]);
$task_description .= " -debug" if ( $debug);

if ( -f $gene_names[0]){
	my @genes;
	open ( IN ,"<$gene_names[0]") or die "could not open the genes file $gene_names[0]\n";
	while ( <IN> ){
		chomp ($_);
		push ( @genes, split( /[ \t]/,$_));
	}
	@gene_names = @genes;
}

my @outpath = split("/",$outfile);
$outfile = pop @outpath;
my $logpath = join( "/", @outpath )."/log";
my $outPath;
my $temp = $outPath = join( "/", @outpath );
if ( $logpath =~ m!^/log! ) {
	$logpath = "." . $logpath;
}

mkdir($outPath) unless ( -d $outPath );
mkdir($logpath) unless ( -d $logpath );
#die "we have some path entries and an outfile:\
#outPath = $outPath\nlogpath = $logpath\noutfile = $outfile\n";


my $PID = 0;
unless ( $debug ) {
$PID = fork();
if ( $PID < 0 ) {
	print "I can not create a child!\n";
	exit(-1);
}
if ( $PID > 0 ) {
	print "OK the master is down as expected!\n";
	exit(1);
}
}

#if ( scalar ( @phenothpeTable ) > 1 ){
#
#	print "we should have ".scalar(@phenothpeTable)." downstream scripts that do the work! I ($$) will exit now\n";
#	if ( !-f "$outPath/makefile" ){
#		open ( MAKE, ">$outPath/makefile") or die "could not open makefile $outPath/makefile\n$!\n";
#		print MAKE "all:\n";
#		foreach my $gene (  @gene_names ){
#			print MAKE "\techo ''> $gene-$outfile\n";
#		}
#		print MAKE "\trm log/*\n";
#		close ( MAKE );
#	}
#	foreach my $phenoFile ( @phenothpeTable ){
#		qx($task_description -phenotypeTable $phenoFile);
#	}
#	exit 1;
#}


$task_description .= " -phenotypeTable $phenothpeTable[0]" if ( defined $phenothpeTable[0]);

unless ( $debug ){
if ( -f "$logpath/".$$."SNP_2_Gene_Expression.std.log" ) {
	open( STD, ">>$logpath/".$$."SNP_2_Gene_Expression.std.log" )
	  or die
	  "could not create logfile $logpath/".$$."SNP_2_Gene_Expression.std.log\n$!\n";
	open( ERR, ">>$logpath/".$$."SNP_2_Gene_Expression.err.log" )
	  or die
	  "could not create logfile $logpath/".$$."SNP_2_Gene_Expression.err.log\n$!\n";
}
else {
	open( STD, ">$logpath/".$$."SNP_2_Gene_Expression.std.log" )
	  or die
	  "could not create logfile $logpath/".$$."SNP_2_Gene_Expression.std.log\n$!\n";
	open( ERR, ">$logpath/".$$."SNP_2_Gene_Expression.err.log" )
	  or die
	  "could not create logfile $logpath/".$$."SNP_2_Gene_Expression.err.log\n$!\n";
}
print "std_out will be in \n$logpath/".$$."SNP_2_Gene_Expression.std.log "
  . "std_err wil be in \n$logpath/".$$."SNP_2_Gene_Expression.err.log\n";
}

print "CMD:\n$task_description\n";

unless ( $debug ){
	STDOUT->fdopen( \*STD, 'w' ) or die $!;
	STDERR->fdopen( \*ERR, 'w' ) or die $!;
}
print "CMD:\n$task_description\n";

my (  $lineCount, $last_r_pid );
## 1. read the phenotype data
$cutOff = 0.05 unless ( defined $cutOff );
my (
	@possibleGroupingValues, @statObjects,
	$groupTag,               @dataColumnHeaders,
	$tableHandling,          $filename,
	@temp,                   $infoPositions,
	$statTests_per_TableLine,
	$gene_col,               $genes
);
my ( $gene_name, $started_r_controller );

open ( MAKE, ">>$outPath/makefile") or die "could not open makefile $outPath/makefile\n$!\n";
foreach my $gene ( @gene_names ){
	print MAKE "\tcat $gene-".$$."-$outfile >> $gene-$outfile\n\trm $gene-".$$."-$outfile\n";
}
close ( MAKE );

foreach my $phenothpeTable (@phenothpeTable) {
	&process_phenotype_file_and_calculate_statistics($phenothpeTable);
}

sub process_phenotype_file_and_calculate_statistics {
	my ($phenothpeTable) = @_;
	my ( $correlatingData );
	$correlatingData = correlatingData->new();
	#print "we created a new correlating data hash $correlatingData\n";
	$correlatingData->AddFile($phenothpeTable);
	print "We got these phenotypic datasets: \n\t",
	  join( "\n\t", $correlatingData->getPossible_CorrelationDataSets() ), "\n"
	  if ($debug);

	if ( defined $phenotypes[0] ) {
		@possibleGroupingValues = @phenotypes;
	}
	else {
		@possibleGroupingValues =
		  $correlatingData->getPossible_CorrelationDataSets();
	}

	foreach (@gene_names) {
		#print "store the gene '$_'\n";
		$genes->{$_} = 1;
	}
	die "No evaluation as no grouping datasets are available!\n"
	  unless ( defined $possibleGroupingValues[0] );

#	root::print_hashEntries( \@possibleGroupingValues, 3,
#		"the grouping values in batchStatistics?" )
#	  if ($debug);
	$tableHandling = tableHandling->new();

	foreach my $infile (@infile) {
		#print "we will open the expression file $infile\n";
		&open_expression_file_and_calculate_statistics($infile, $correlatingData);
	}

}

sub open_expression_file_and_calculate_statistics {
	my ($infile, $correlatingData) = @_;
	my ( @statObjects, $analyzed );
	unless ( -f $infile ) {
		warn "we could not read from the infile $infile\n";
		next;
	}
	open( IN, "<$infile" )
	  or die "could not open array data file '$infile' in batchStatistic.pl\n";
	print "opened the expression array dataset $infile\n" if ($debug);
	$lineCount = 0;

	$last_r_pid = &start_r_controler();
	GENES:while (<IN>) {
		$lineCount++;
		chomp $_;
		$_ =~
		  s/,/\./g;  ## change from european decimal separator',' to english '.'

		if ( $lineCount == 1 ) {
			## we have to create groups for each test type
			print
"\nwe try to select the data containing columns using the pattern "
			  . join( " ", @pattern ) . "\n"
			  if ($debug);
			unless ( defined $pattern[1] ) {
				@dataColumnHeaders =
				  $tableHandling->get_column_entries_4_columns(
					$_,
					$tableHandling->identify_columns_of_interest_patternMatch(
						$_, $pattern[0]
					)
				  );
			}
			else {
				@dataColumnHeaders =
				  $tableHandling->get_column_entries_4_columns(
					$_,
					$tableHandling->identify_columns_of_interest_bySearchHash(
						$_, $tableHandling->createSearchHash(@pattern)
					)
				  );
			}

			$infoPositions =
			  $tableHandling->identify_columns_of_interest_bySearchHash(
				$_,
				$tableHandling->createSearchHash(
					"Gene Symbol", "mRna - Description",
					"Probe Set ID"
				)
			  );
			$gene_col =
			  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
				$tableHandling->createSearchHash("Gene Symbol") );
			die
"we got no data to evaluate! ( @dataColumnHeaders )\nheader line\n$_\n"
			  unless ( defined $dataColumnHeaders[0] );
			for ( my $i = 0 ; $i < @possibleGroupingValues ; $i++ ) {
				my $statObj =
				  $correlatingData->getStatObj_4_dataLine_and_correlationValue(
					\@dataColumnHeaders, $possibleGroupingValues[$i] );

				unless ( defined $statObj ) {
					print "we got no StatObj for phenotypeDataset $possibleGroupingValues[$i]\n"
					  if ($debug);
					next;
				}
				push(
					@statObjects,
					{
						group    => $possibleGroupingValues[$i],
						statObj  => $statObj,
						filename => $filename,

						#					fileHandle => $fh,
						#					logFile    => $log,
						tableHeader =>
						  $statObj->processTableHeader( $_, $infoPositions )
					}
				);

				#print {$fh} $statObj->processTableHeader( $_, $infoPositions );

				print
"the phenotypic data set $possibleGroupingValues[$i] is evaluated using a ",
				  ref($statObj), " statistical object\n"
				  if ($debug);
#				root::print_hashEntries( $statObjects[$#statObjects], 4,
#"a statistical object returned for the grouping variable $possibleGroupingValues[$i]"
#				) if ($debug);

			}
			$statTests_per_TableLine = $#statObjects;
			next
			  ; # we do not want to calculate anything using the column header line!
		}
		else {
			next GENE if (&calculate_statistics_for_gene($_, \@statObjects, $analyzed) == -1 );
		}

	}
	&stop_r_controler($last_r_pid);

	close(IN);
}

sub calculate_statistics_for_gene {
	my ($line, $statObjects, $analyzed) = @_;
	my ( $gene_name, $md5_sum );
	($gene_name) =
	  $tableHandling->get_column_entries_4_columns( $line, $gene_col );
	$gene_name = $1 if ( $gene_name =~ m/ ?(.+) / );

	if ( $genes->{$gene_name} ) {
		print "now (".root->time().") we evalute gene expression for gene $gene_name\n";
		unless ( -f "$outPath/$gene_name-".$$."-$outfile" ) {
			open( OUT, ">$outPath/$gene_name-".$$."-$outfile" )
			  or die "could not create file $outPath/$gene_name-".$$."-$outfile\n";
		}
		else {
			open( OUT, ">>$outPath/$gene_name-".$$."-$outfile" )
			  or die "could not open file $outPath/$gene_name-".$$."-$outfile for writing\n";
		}
		print "we try to calculate the statistcs!\n";
		foreach my $hashRef (@$statObjects) {
			#print "we evaluate a stat object!\n";
			$temp = $hashRef->{statObj}->getTest_result( $_, 1 );
			unless ( defined $md5_sum ){
			$md5_sum =  md5_hex("$temp $hashRef->{'group'}");
			return -1 if ( $analyzed -> {$md5_sum});
			$analyzed -> {$md5_sum} = 1;
			}
			if ( $hashRef->{statObj}->error() ) {
				warn $hashRef->{statObj}->error();
			}
			elsif ($hashRef->{statObj}->{lastP} <= $cutOff
				&& $hashRef->{statObj}->{lastP} > 0 )
			{
				print OUT "rsID\t" . $hashRef->{'tableHeader'};
				print OUT $hashRef->{'group'} . "\t" . $temp . "\n";
			}
		}
		close(OUT);
		return 1;
	}
	return 0;
}

sub createFileHandle {
	my ( $outPath, $outfile, $info ) = @_;

	my (@temp);

# my ($fh, $filename ) = createFileHandle ( $outPath, $outfile, $possibleGroupingValues[$i]);
	unless ( -d $outPath ) {
		warn "we have to create the directory $outPath\n";
		mkdir($outPath) or die "$!\n";
	}
	@temp = split( /[ ()\/]+/, $info );
	my $filename = join( '_', @temp );
	$filename = "$outPath/$filename-".$$."-$outfile";
	my $fh = new FileHandle ">$filename";
	die "Cannot open $filename: $!" unless ( defined $fh );
	return $fh, $filename;
}

sub start_r_controler {
	my $path = "/home/stefan_l/Link_2_My_Libs";

	print "we expect the scripts to be downstream of $path/bin\n";

	my $r_controller_cmd =
	  "perl ".root->perl_include()." $path/bin/array_analysis/r_controler.pl $$";
	my ( @r_out, $last_r_pid, $temp );
	@r_out = qx( $r_controller_cmd );
	$temp = join( " ", @r_out );
	$temp =~ m/r_controler_log is '(.*)'/;
	open( R_LOG, "<$1" ) or die "could not open r_controller log '$1'\n";
	while (<R_LOG>) {
		$last_r_pid = $1
		  if ( $_ =~ m/started a r_controller instance \((\d+)\) at/ );
	}
	close(R_LOG);
	return $last_r_pid;
}

sub stop_r_controler {
	my ($last_r_pid) = @_;
	#system("kill $last_r_pid");
}
