#! /usr/bin/perl

use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

my $data_table = data_table->new();
foreach ( qw (id seq_number seq_id) ){
	$data_table->Add_2_Header ( $_ );
}

foreach my $file ( @ARGV ){
open ( IN , "<$file" ) or warn "Sorry I could not open the infile $ARGV[0]\n$!\n";
my ($OK, $hash );
$OK = 0;
while ( <IN> ){
	#print "$_ and I find ".scalar (  $_ =~s/\t/\t/g )." tabs!\n";
	next unless ( scalar ( $_ =~ s/    */\t/g ) == 2 );
	chomp ($_ );
	unless ( $OK ) {
		$OK = 1;
		next  if ( $_ =~m/Sequence/);
	}
	( $hash->{'id'}, $hash->{'seq_number'}, $hash->{'seq_id'} ) = split ( "\t", $_ );
	$data_table->AddDataset ( $hash );
}
close ( IN );

$data_table->write_file ( "$file.modified" );
}
