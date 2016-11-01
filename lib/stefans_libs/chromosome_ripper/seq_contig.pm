package seq_contig;
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
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::chromosome_ripper::seq_contig

=head1 DESCRIPTION

seq_contig is a database wrapper class. It is used to identify the NCBI genbank formated sequences that correspond to a given genomic region.

=head2 Depends on

L<::root>

=head2 Provides

L<CreateDB|"CreateDB">

L<insertDataFile|"insertDataFile">

L<getContigsInRegion|"getContigsInRegion">

=head1 METHODS

=head2 new

=head3 arguments

none

=head 3 return value

A new object of the class seq_contig

=cut

sub new {

    my ($class) = @_;

    my ( $self, $dbh, $root );

    $root = root->new();
    $dbh  = $root->getDBH("NCBI");

    $self = {
        root => $root,
        dbh  => $dbh
    };

    bless( $self, $class ) if ( $class eq "seq_contig" );
    return $self;
}

=head2 CreateDB

Creates a new table to store the NCBI genome information.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub CreateDB {
    my ($self) = @_;
    $self->{dbh}->do("DROP TABLE IF EXISTS Chromosome_Data")
      or die $self->{dbh}->errstr();
    $self->{dbh}->do( "
	CREATE TABLE Chromosome_Data (
	  id  INTEGER autoincremant,
	  taxId int(11) NOT NULL default '0',
	  chromosome int(11) NOT NULL default '0',
	  chr_start int(11) NOT NULL default '0',
	  chr_end int(11) NOT NULL default '0',
	  orientation char(1) NOT NULL default '',
	  feature_name varchar(20) NOT NULL default '',
	  feature_id varchar(20) NOT NULL default '',
	  feature_type varchar(20) NOT NULL default '',
	  group_label varchar(20) NOT NULL default '',
	  weight char(1) default NULL,
	  NCBI_build_ID varchar(10) NOT NULL default '0',
	  local_file varchar (255) default '',
	  primary key ID ( id ),
	  unique KEY position (chr_start, chr_end, NCBI_build_ID, chromosome),
	  INDEX location ( chr_start, chr_end, chromosome, taxId)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1
    " ) or die $self->{dbh}->errstr();
    return 1;

}

=head2 insertDataFile

=head3 arguments

[0]: the NCBI mapview/seq_contig.md file defining the chromosomes

[1]: the NCBI genome build version

=head3 return values

the count of sequence files defining all chromosomes in this NCBI genome build

=cut

sub insertDataFile {
    my ( $self, $seq_contig_file, $build ) = @_;

    open( Seq_Contig, "<$seq_contig_file" )
      or die "Konnte seq_contig.md ($seq_contig_file) nicht öffnen!\n";

    my (
        $sth,        $i,            $taxID,       $chromosome,
        $chr_start,  $chr_end,      $orientation, $feature_name,
        $feature_id, $feature_type, $group_label, $weight
    );

    $self->CreateDB();
    $sth = $self->{dbh}->prepare(
        "INSERT into Chromosome_Data 
         (taxId, chromosome, chr_start, chr_end, orientation, feature_name, feature_id,
         feature_type, group_label, weight, NCBI_build_ID ) values (?,?,?,?,?,?,?,?,?,?,?)"
      )
      or die $self->{dbh}->errstr();

    $i = 0;
    while (<Seq_Contig>) {
        chop $_;
        next if ( $_ =~ /^#/ );
        $i++;
        (
            $taxID,       $chromosome,   $chr_start,  $chr_end,
            $orientation, $feature_name, $feature_id, $feature_type,
            $group_label, $weight
          )
          = split( "\t", $_ );

        $weight = "NULL" if ( $weight eq "" || $weight eq "nq" );
        $sth->execute(
            $taxID,         $chromosome,     $chr_start,    $chr_end,
            "$orientation", "$feature_name", "$feature_id", "$feature_type",
            "$group_label", $weight,         "$build"
          )
          or die $!;
        print
"INSERT into Chromosome_Data values ($taxID, $chromosome, $chr_start, $chr_end, \"$orientation\", \"$feature_name\" ,\"$feature_id\", \"$feature_type\", \"$group_label\", $weight, \"$build\"); \n"
          if ( $i / 5000 == int( $i / 5000 ) );
    }
    close(Seq_Contig);

    print "$i Werte in die Datenbank eingegeben\n";

    return $i;
}

=head2 getContigsInRegion

=head3 arguments

[0]: the number of the chromosome

[1]: the start point of the genomic region of interest in basepairs

[2]: the end point of the genomic region of interest in basepairs

[3]: the strain string as used in the mapview/seq_contig.md that should be used to create the list of accession numbers

[4]: the NCBI genome build version that should be used to create the list of accession numbers

=head3 return values

a reference to a array of hashes. The hashes contain the region information: {type => 'Accession Number' or "GAP", 
start_old => first bp corresponding to the region of interest in this NCBI sequence, 
end_old => last bp corresponding to the region of interest in this NCBI sequence,
length => the length of the GAP }.
The array contains the hashes in chromosomal orientation.

=cut

sub getContigsInRegion {
    my ( $self, $chromosome, $chr_start, $chr_end, $group_label, $build ) = @_;
    my (
        $sth,        $orientation, $start,    $end, $last_end,
        $frag_start, $frag_end,    @ergebnis, $i,   $feature_name
    );

    $sth = $self->{dbh}->prepare( "
	Select feature_name, orientation, chr_start, chr_end 
	from Chromosome_Data 
	where chromosome = ?  && group_label = ? && NCBI_build_ID = ? && chr_start > 1
        order by chr_start
        " ) or die $self->{dbh}->errstr();
    $chr_start = $self->getValue($chr_start);
    $chr_end   = $self->getValue($chr_end);
    $sth->execute( $chromosome, "$group_label", $build ) or die $sth->errstr();
    $sth->bind_columns( \$feature_name, \$orientation, \$start, \$end )
      or die $sth->errstr();

    $i = 0;

    while ( $sth->fetch() ) {

        next if ( $start == 1 || $feature_name eq "" );
        if ( $start < $chr_end && $end > $chr_start ) {    ## match
            $last_end = $start unless ( defined $last_end );
            $frag_start = $start - $chr_start;
            $frag_end   = $end - $chr_start;
            $last_end   = $start unless ( defined $last_end );
            if ( $start - $last_end > 0 ) {    ## Lücke im Chromosom!!
                my $hash = {
                    type         => "GAP",
#                    line         => $_,
#                    start_on_new => $last_end - $chr_start,
                    'length'     => $start - $last_end
                };
                $ergebnis[ $i++ ] = $hash;
                $last_end = $end;
            }
            my $hash = {
                type         => $feature_name,
#                line         => $_,
                start_old    => $start - $chr_start,
                end_old      => $chr_end - $end
            };

            ## if start_old lies in the roi
            $hash->{start_old} = 0 if ( $hash->{start_old} > 0 );
            ## if start_old starts in front of the roi
            $hash->{start_old} = - $hash->{start_old} if ( $hash->{start_old} < 0 );

            ## if end_old lies in the roi
            $hash->{end_old} = $end - $start if ( $hash->{end_old} >= 0); ## length of gbFile
            ## if end_old lies after the roi
            $hash->{end_old} = $end - $start + $hash->{end_old} if ( $hash->{end_old} < 0);

            $ergebnis[ $i++ ] = $hash;
            $last_end = $end;
        }
    }
    return \@ergebnis;
}

sub getValue($) {
    my ( $self, $start ) = @_;

    my ($return, $multiplicator,@values, $wert );

    $multiplicator = 1;
    $multiplicator = 1000000 if ( $start =~ m/\dM/ );
    $multiplicator = 1000 if ( $start =~ m/\dK/ );

    $start = $values[0];
    @values = split( ",", $start );
    $wert = @values;

    #   print "Wert:  $start \@values = $wert\n";
    if ( @values > 1 ) {
        $values[1] =~ m/(\d*)/;
        $values[1] = $1;
        $start = "$values[0].$values[1]";
    }

    #   print $start * $multiplicator, "\n";
    return $start * $multiplicator;

}

1;
