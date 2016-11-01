#! /usr/bin/perl
use strict;
use warnings;

use stefans_libs::Latex_Document;
use stefans_libs::flexible_data_structures::data_table;

my $object = stefans_libs::Latex_Document->new();
my $chapter = $object -> Section( "Hausaufgabe");
my $text = $chapter -> AddText ( "Bitte rechne alles aus.");
my $data_table = data_table->new();
foreach ( qw(Aufgabe wird Ergebnis) ){
	$data_table -> Add_2_Header( $_ );
}
my ( $hundert, $zehn, $eins );

for ( my $i = 0; $i < 20; $i++ ){
		$hundert = $zehn = $eins = 0;
        #$hundert = int(rand(10)). "00";
        #$zehn = int (rand(10)). "0";
        while ( $eins <= 1){
        	$eins = int(rand(10));
        }
        while ( $zehn < 10){
      	  $zehn = int(rand(20));
        }
        $data_table -> AddDataset ( {'Aufgabe' => "$zehn - $eins", 'wird' => '=', 'Ergebnis' => '                  '});
}
$text -> AddTable( $data_table );
$chapter = $object -> Section( "Hausaufgabe 2");
$text = $chapter -> AddText ( "Und jetzt habe ich noch ein paar andere Aufgaben für Dich.");
my $data_table2 = data_table->new();
foreach ( qw(Aufgabe wird Ergebnis) ){
	$data_table2 -> Add_2_Header( $_ );
}
for ( my $i = 0; $i < 20; $i++ ){
        $data_table2 -> AddDataset ( {'Aufgabe' => &_einer()." + ".&_einer(), 'wird' => '=', 'Ergebnis' => '                  '});
}

$text -> AddTable( $data_table2 );
my $Today = root::Today();
$object -> write_tex_file ( "./$Today"."_Hausaufgabe.tex" );

sub _einer {
	my $eins = 0;
	while ( $eins <= 1){
        $eins = int(rand(10));
    }
    return $eins;
}

sub return_reverse_order{
	my ( $a, $b ) = @_;
	return $b, $a ;
}