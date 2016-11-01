#! /usr/bin/perl
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
use Getopt::Long;
use stefans_libs::root;
use stefans_libs::chromosome_ripper::seq_contig;
use stefans_libs::chromosome_ripper::gbFileMerger;

 
my ( $seq_contig, $seq_contig_file, $path2NCBI_Chromosomes, $regionListFile,
    $help, $outpath, $NCBI_Genome_Build, $Organism, $group_label, $gbFileMerger );

$seq_contig = seq_contig->new();
$gbFileMerger = gbFileMerger->new();

$group_label = "C57BL/6J";

Getopt::Long::GetOptions(
    'seq_contig_file=s'       => \$seq_contig_file,
    'NCBI_Genome_Build=s'    => \$NCBI_Genome_Build,
    'Organism=s'              => $Organism,
    'path2NCBI_Chromosomes=s' => \$path2NCBI_Chromosomes,
    'regionListFile=s'        => \$regionListFile,
    'outpath=s'               => \$outpath,
    'help'                    => \$help
  )
  or helpText();
#helpText() unless ( @ARGV > 2);
helpText() if ( defined  $help);

helpText() unless ( defined $seq_contig_file);

$seq_contig->insertDataFile( $seq_contig_file, $NCBI_Genome_Build, $Organism );

$gbFileMerger->Create_GBfiles($regionListFile,$outpath,$group_label,$NCBI_Genome_Build, $path2NCBI_Chromosomes);


sub helpText {

    die "\ncreateSeqFiles_from_ChromosomalRegions.pl <OPTIONS>\n",
          "\tOPTIONS:\n",
"\t-seq_contig_file       : absolute location of the NCBI seq_contig.md file\n",
"\t-NCBI_Genome_Build     : version number of the used NCBI genome build\n",
"\t-Organism              : String for the organism used\n",
"\t-path2NCBI_Chromosomes : path where the NCBI chromosome data lies\n",
"\t-regionListFile        : file where the regions of the chromosomes are defined,\n",
"\t                         that have to be converted to genbank\n",
"\t                         each line has to consist of one entry in the form:\n",
"\t                         Chr<number of chromosome>:<start position>-<end position> (<name of the region i. e. IgH>)\n",
"\t                         the start and end positions can be of type bp, Kb (1,000 bp) or Mb (1,000,000bp)\n",
"\t-outpath               : path where the genbank formated chromosomal regions are written to\n",
"\t-help                  : print this help message\n\n\n";
}

