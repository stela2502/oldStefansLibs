package genomeImporter;

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

use vars qw($VERSION);
use Net::FTP;
use stefans_libs::database::genomeDB;
use stefans_libs::database::genomeDB::genbank_flatfile_db;
use stefans_libs::database::genomeDB::genomeImporter::NCBI_genome_Readme;
use stefans_libs::database::genomeDB::genomeImporter::seq_contig;
use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;

$VERSION = 0.01;

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a class to import NCBI refseq genomes from the internet and store it in a local database that can be interrogated by the lib file database::genomeDB. All files are handled as gbFiles.


=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class genomeImporter.

=cut

sub new {

	my ( $class, $databaseName, $debug ) = @_;

	my ($self);

	$self = {
		debug              => $debug,
		databaseDir        => "~/temp",
		NCBI_genome_Readme => NCBI_genome_Readme->new(),
		seq_contig         => seq_contig->new(),
		genomeDB           => genomeDB->new( $databaseName, $debug ),
	};
	$self->{'database_name'} = $self->{'genomeDB'}->{'database_name'};
	$self->{'loggingTable'} =
	  loggingTable->new( $self->{'database_name'}, $self->{'debug'} );
	$self->{'workingTable'} =
	  workingTable->new( $self->{'database_name'}, $self->{'debug'} );

#$self->{'errorTable'} = errorTable-> new( $self->{'database_name'}, $self->{'debug'});

	bless $self, $class if ( $class eq "genomeImporter" );

	return $self;

}

sub expected_dbh_type {

	#return 'dbh';
	return "not a database interface";

	#return "database";
}

sub import_refSeq_genome_for_organism {
	my ( $self, $organism ) = @_;
	my ( $files, $table_string, $rv, $gbFile, $dbLibFiles, $processed, $refTag );

	$files = $self->download_refseq_genome_for_organism($organism);

	$self->{seq_contig}->readFile( $files->{seq_contig} );
	$self->{NCBI_genome_Readme}->readFile( $files->{readme} );

	if ( $self->{debug} ) {
		print ref($self) . " we have got ", $self->{seq_contig}->readLines(),
		  " lines in the seq_contig file\n";
	}
	unless ( $self->{seq_contig}->readLines() > 1 ) {
		Carp::confess ref($self),
		  ":import_refSeq_genome_for_organism -> problem:",
		  "we do not have entries in the seq_contig file (",
		  $self->{seq_contig}->readLines(), ")!";
	}

	my $genbank_flatfile_db = genbank_flatfile_db->new();
	$genbank_flatfile_db->{tempPath} = "$self->{databaseDir}/originals";
	$self->Extract_gbFiles($files)
	  unless ( -f "$self->{databaseDir}/originals/extracted.txt" );

	## now we should have a pretty complete list of gbFiles for the refseq assemby (H_sapiens)
	## in the genbank_flatfile_db object

	$self->{genomeDB}->create() unless ( $self->{genomeDB}->tableExists() );

	$table_string = $self->{genomeDB}->AddDataset(
		{
			'version'      => $self->{NCBI_genome_Readme}->Version(),
			'organism'     => { 'organism_tag' => $organism },
			'creationDate' => $self->{NCBI_genome_Readme}->{data}->{releaseDate}
		}
	);

	my $chromosm_interface =
	  $self->{genomeDB}->GetDatabaseInterface_for_Organism($organism);
	$chromosm_interface = $chromosm_interface->get_rooted_to('gbFilesTable');

	my ( $sth, $sql, $dataset );

	$sql = $chromosm_interface->create_SQL_statement(
		{
			'search_columns' => [ 'gbFilesTable.id' ],
			'where'          => [ [ 'gbFilesTable.acc', '=', 'my_value' ] ]
		}
	);
	$sth = $chromosm_interface->{'dbh'}->prepare($sql);
	print "now we try to read all genomic regions using the object ".ref($self->{seq_contig})."\n";
	$processed = 0;
	$refTag = $self->{NCBI_genome_Readme}->ReferenceTag();
	while ( my $chrInfo = $self->{seq_contig}->getNext() ) {
		if ( $self->{debug} ) {
			print ref($self)
			  . ":import_refSeq_genome_for_organism we read the files from "
			  . "$self->{'databaseDir'} or better $genbank_flatfile_db->{tempPath}\n"
			  ;
			print ref($self)
			  . " \$chrInfo->{group_label} = $chrInfo->{group_label}\n";
			print ref($self)
			  . " \$self->{NCBI_genome_Readme}->ReferenceTag() = ",
			  $self->{NCBI_genome_Readme}->ReferenceTag(), "\n";
		}
		next
		  if ( $chrInfo->{feature_name} eq "start"
			|| $chrInfo->{feature_name} eq "end" );

		print ref($self)
		  . "_we try to match Version $chrInfo->{feature_name}; ReferenceTag:"
		  . $self->{NCBI_genome_Readme}->ReferenceTag() . " to "
		  . $chrInfo->{group_label} . "\n";# if ( $self->{'debug'});

		if ( defined $chrInfo->{group_label}
			&& $chrInfo->{group_label} =~m/$refTag/ )
		{
			next if ($chrInfo->{group_label} =~ m/PATCHES/);
			$chrInfo->{group_label} = $refTag;
			## first we might check, if the file is already in the database - or?
			$processed ++;
			if ( $sth->execute( $chrInfo->{feature_name} ) == 1 ) {
				print
"this gbFile has already been imported ($chrInfo->{feature_name})\n";
				next;
			}

			$gbFile =
			  $genbank_flatfile_db->get_gbFile_obj_for_version(
				$chrInfo->{feature_name} );

			print ref($self)
			  . ":we add the gbFile "
			  . $gbFile->Print()
			  . " to the Database\n"
			  if ( $self->{debug} );

			unless ( defined $gbFile->Version() ) {
				warn ref($self)
				  . " we got no gbFile entry for feature name '$chrInfo->{feature_name}'\n"
				  unless ( $chrInfo->{feature_name} eq "start" );
				next;
			}
			$rv = $chromosm_interface->AddDataset(
				{ 'gbFile' => $gbFile, 'chromosome' => $chrInfo } );

			$gbFile->DESTROY();
		}
		elsif ( $self->{debug} ) {
			print ref($self)
			  . " we do not insert the entry with group lable $chrInfo->{group_label}, ",
			  "as it does not match with the reference value ",
			  $self->{NCBI_genome_Readme}->ReferenceTag(), "\n";
		}
		
	}
	if ( $processed == 0 ){
			warn "Oh we had an issue here - we have not touched any sequence file!\n".
			"I suggest we have once more an issue with the ReferenceTag '".$self->{NCBI_genome_Readme}->ReferenceTag()."'\n";
	}
	return 1;
}

sub download_refseq_genome_for_organism {
	my ( $self, $organism ) = @_;
	my ( @directory, @CHR_dir, $return, $already_read, @wget );

	$self->{databaseDir} .= "/$organism";
	print "Database Dir = $self->{databaseDir} \n" if ( $self->{debug} );
	if ( -d "$self->{databaseDir}" ) {
		warn "the dataset has already been downloaded!\nSTOP?\n";
		opendir( DIR, "$self->{databaseDir}/" );
		my @entries = readdir(DIR);
		closedir(DIR);

		foreach my $file (@entries) {
			$return->{seq_contig} = "$self->{databaseDir}/$file"
			  if ( $file eq "seq_contig.md.gz" );
			$return->{readme} = "$self->{databaseDir}/$file"
			  if ( $file eq "README_CURRENT_BUILD" );
			if ( $file =~ m/gbk.gz/ ){
			   push( @{ $return->{gbLibs} }, "$self->{databaseDir}/$file" );
			   $already_read->{"$self->{databaseDir}/$file"} = 1;
			}
		}
		return $return;
	}
	else {
		mkdir("$self->{databaseDir}");
	}

	my $ftp = Net::FTP->new( 'ftp.ncbi.nlm.nih.gov', Debug => 1 )
	  or die "Cannot connect to some.host.name: $@";

	$ftp->login( "anonymous", 'stefan@gmx.de' )
	  or die "Cannot login ", $ftp->message;

	$ftp->cwd("/genomes/$organism/")
	  or die "Cannot change working directory ", $ftp->message;

	$ftp->get( "README_CURRENT_BUILD",
		"$self->{databaseDir}/README_CURRENT_BUILD" )
	  or die "cannot access the README_CURRENT_BUILD\n",
	  $ftp->message();
	$return->{readme} = "$self->{databaseDir}/README_CURRENT_BUILD";

	$ftp->binary();
	unless ( -f "$self->{databaseDir}/seq_contig.md.gz"
		|| -f "$self->{databaseDir}/seq_contig.md" )
	{
		$ftp->get( "mapview/seq_contig.md.gz",
			"$self->{databaseDir}/seq_contig.md.gz" )
		  or die "Cannot load the file mapview/seq_contig.md.gz ",
		  $ftp->message;
		$return->{seq_contig} = "$self->{databaseDir}/seq_contig.md.gz";
	}
	my $rv;
	@directory = $ftp->ls();
	foreach my $entry (@directory) {
		$return->{gbLibs} = [];
		if ( $entry =~ m/(CHR_)([\d\w]+)/ ) {
			#next if ( $2 < 11);
			$ftp->cwd("$1$2");
			@CHR_dir = $ftp->ls();
			## hs_ref_GRCh37.p2_chr6.gbk.gz
			foreach my $file (@CHR_dir) {
				if ( $file =~ m/ref/ ) {
					if ( $file =~ m/gbk/ ) {
						if ( $already_read->{"$self->{databaseDir}/$file"} ){
							warn "we already had the file $file\n";
							next;
						}
						push ( @wget, "wget  ftp.ncbi.nlm.nih.gov/genomes/$organism/$entry/$file");
						#$rv = $ftp->get( "$file", "$self->{databaseDir}/$file" )

						#  or die "Cannot load the file '$file' ", $ftp->message;

						push(
							@{ $return->{gbLibs} },
							"$self->{databaseDir}/$file"
						);
					}
				}
			}
			$ftp->cwd('../');
		}
		if ( $entry =~ m/(CHR_X)/ ) {
			$ftp->cwd("$1");
			@CHR_dir = $ftp->ls();
			foreach my $file (@CHR_dir) {
				if ( $file =~ m/ref/ ) {
					if ( $file =~ m/gbk/ ) {
						next if ( $already_read->{"$self->{databaseDir}/$file"} );
						push ( @wget, "wget  ftp.ncbi.nlm.nih.gov/genomes/$organism/$entry/$file");
						#$rv = $ftp->get( "$file", "$self->{databaseDir}/$file" )

						#  or die "Cannot load the file '$file' ", $ftp->message;

						push(
							@{ $return->{gbLibs} },
							"$self->{databaseDir}/$file"
						);
					}
				}
			}
			$ftp->cwd('../');
		}
		if ( $entry =~ m/(CHR_Y)/ ) {
			$ftp->cwd("$1");
			@CHR_dir = $ftp->ls();
			foreach my $file (@CHR_dir) {
				if ( $file =~ m/ref/ ) {
					if ( $file =~ m/gbk/ ) {
						next if ( $already_read->{"$self->{databaseDir}/$file"} );
						push ( @wget, "wget  ftp.ncbi.nlm.nih.gov/genomes/$organism/$entry/$file");
						
						#$rv = $ftp->get( "$file", "$self->{databaseDir}/$file" )

						#  or die "Cannot load the file '$file' ", $ftp->message;

						push(
							@{ $return->{gbLibs} },
							"$self->{databaseDir}/$file"
						);
					}
				}
			}
			$ftp->cwd('../');
		}
	}
	print "downloaded the files?\n".join("\n", @wget)."\n";
	$ftp->quit;
	if ( scalar ( @wget ) > 0 ){
		die "could you please download the files using this script:\n".join("\n",@wget )."\n";
	}
## now we have to import the info into the database!!
	$self->Extract_gbFiles($return);

	return $return;
}

sub Extract_gbFiles {
	my ( $self, $files ) = @_;
	## now we have to import the info into the database!!
	my $genbank_flatfile_db = genbank_flatfile_db->new();
	$genbank_flatfile_db->{tempPath} = "$self->{databaseDir}/originals";
	mkdir("$self->{databaseDir}/originals")
	  unless ( -d "$self->{databaseDir}/originals" );
	my $dbLibFiles = 0;
	foreach my $gbLibFile ( @{ $files->{gbLibs} } ) {
		$dbLibFiles++;
		$genbank_flatfile_db->loadFlatFile($gbLibFile);
	}
	open( LOG, ">$self->{databaseDir}/originals/extracted.txt" );
	print LOG "No problems\n";
	close(LOG);
	return 1;
}

1;
