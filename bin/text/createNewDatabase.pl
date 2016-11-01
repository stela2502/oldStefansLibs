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
 
 use stefans_libs::database::dataset::oligo_array_values;
 use stefans_libs::database_old::array_GFF;
 use stefans_libs::database_old::array_TStat;
 use stefans_libs::database::antibodyTable;
 use stefans_libs::database_old::cellTypeDB;
 use stefans_libs::database_old::hybInfoDB;
 use stefans_libs::database_old::designDB;
 use stefans_libs::database_old::fileDB;
 use stefans_libs::database::nucleotide_array::oligo2dnaDB;
 use stefans_libs::chromosome_ripper::seq_contig;
 
 use stefans_libs::NimbleGene_config;
 
 my ($stdin, $NimbleGene_config, $database);
 
 
 $NimbleGene_config = NimbleGene_config->new();
 
 while ( !( defined $stdin)){
 print "Sollen alle Tabellen der Datenbank $NimbleGene_config->{database} für die NimbelGene_Auswertung neu initialisiert werden? (j/N)\n";
 
 $stdin = <STDIN>;
 chomp $stdin;
 
 if ( $stdin eq "J" || $stdin eq "j" ){
    print "reinitialisation of databases!\n";
 }
 elsif ( $stdin eq "" || lc($stdin) eq "n" ){
    print "Abbruch\n";
    die "";
 }
 else {
   $stdin = undef;
 }
 }
 
 print "chromosome_ripper? (j/N)\n";
 if (getSTDIN()){
 $database = seq_contig->new();
 $database->CreateDB();
 }
 
 
 print "array_TStat ? (j/N)\n";
 if (getSTDIN()){
 $database = array_TStat->new();
 $database->CreateDB();
 }
 
 
 print "array_Hyb ? (j/N)\n";
 if (getSTDIN()){
 $database = array_Hyb->new();
 $database->CreateDB();
 }
 print "array_GFF ? (j/N)\n";
 if (getSTDIN()){
 $database = array_GFF->new();
 $database->CreateDB();
 }
 print "antibodyDB ? (j/N)\n";
 if (getSTDIN()){
 $database = antibodyDB->new();
 $database->CreateDB();
 }
 print "cellTypeDB ? (j/N)\n";
 if (getSTDIN()){
 $database = cellTypeDB->new();
 $database->CreateDB();
 }
 print "hybInfoDB ? (j/N)\n";
 if (getSTDIN()){
 $database = hybInfoDB->new();
 $database->CreateDB();
 }
 print "designDB ? (j/N)\n";
 if (getSTDIN()){
 $database = designDB->new();
 $database->CreateDB();
 }
 
 print "fileDB ? (j/N)\n";
 if (getSTDIN()){
 $database = fileDB->new();
 $database->CreateDB();
 }
 
 print "oligo2dnaDB ? (j/N)\n";
 if (getSTDIN()){
 $database = oligo2dnaDB->new();
 $database->CreateDB();
 }
 
 print "Fertig\n";
 
 
 sub getSTDIN {
   my $stdin;
   while ( !( defined $stdin)){
   $stdin = <STDIN>;
   chomp $stdin;
   if ( $stdin eq "J" || $stdin eq "j" ){
      return 1 == 1;
   }
   elsif ( $stdin eq "" || lc($stdin) eq "n" ){
      return 2 == 0;
   }
   else {
     $stdin = undef;
   }
   }
 }
 
