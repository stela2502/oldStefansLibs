#! /usr/bin/perl
use strict;
use warnings;

use stefans_libs::Latex_Document;
use stefans_libs::flexible_data_structures::data_table;

my $object  = stefans_libs::Latex_Document->new();
my $chapter = $object->Section("Hausaufgabe");
my $text    = $chapter->AddText("Bitte rechne alles aus.");

my (@temp);

$text->AddTable( &multiplizieren_einfach() );
$chapter = $object->Section("Hausaufgabe 2");
$text    = $chapter->AddText(
	"Und jetzt habe ich noch ein paar andere Aufgaben für Dich.");

$text->AddTable( &multiplizieren_einfach() );

$chapter = $object->Section( "Hausaufgabe 3" );
$text = $chapter -> AddText ( "Und noch mal was :-)" );
print "Another table\n";
$text->AddTable( &teilen_einfach() );

my $Today = root::Today();
$object->write_tex_file( "./$Today" . "_Tabea_Hausaufgabe.tex" );

open( IN, "<./$Today" . "_Tabea_Hausaufgabe.tex" );
@temp = <IN>;
close(IN);
my $print;
open( OUT, ">./$Today" . "_Tabea_Hausaufgabe.tex" );
$print = 1;
my $endlastfoot = 0;
foreach (@temp) {
	$endlastfoot = 0 if ( $_ =~ m/longtable/ );
	unless ($endlastfoot) {
		print OUT $_ if ($print);
	}
	else {
		print OUT $_ . "\\hline\n";
	}
	$endlastfoot = 1 if ( $_ =~ m/endlastfoot/ );

	$print = 0 if ( $_ =~ m/begin{document}/ );
	$print = 1 if ( $_ =~ m/maketitle/ );
}
close(OUT);

sub _einer {
	my $eins = 0;
	while ( $eins <= 1 ) {
		$eins = int( rand(10) );
	}
	return $eins;
}

sub return_reverse_order {
	my ( $a, $b ) = @_;
	return $b, $a;
}

sub multiplizieren_einfach {
	my ( $hundert, $zehn, $eins, @temp, $already_calculated, $data_table );
	$data_table = data_table->new();
	foreach (qw(Aufgabe wird Ergebnis)) {
		$data_table->Add_2_Header($_);
	}
	$data_table->Add_2_Header('__');
	foreach (qw(Aufgabe wird Ergebnis)) {
		$data_table->Add_2_Header( $_ . "_2" );
	}
	for ( my $i = 0 ; $i < 26 ; $i++ ) {
		@temp = ( &_einer(), &_einer(), &_einer(), &_einer() );
		$hundert = $zehn = $eins = 0;
		$hundert = &_einer() . &_einer() . &_einer();
		$zehn    = &_einer() . &_einer();

#$data_table -> AddDataset ( {'Aufgabe' =>"\\huge{$hundert - $zehn}  ", 'wird' => '=', 'Ergebnis' => '                  '});
		$data_table->AddDataset(
			{
				'Aufgabe' => "\\huge{$temp[0] * $temp[1]}",

				#'Aufgabe'    => "$temp[0] * $temp[1]",
				'wird'     => '=',
				'Ergebnis' => '                  ',
				'__'       => '            ',

				#'Aufgabe_2'  => "$temp[2] * $temp[3]",
				'Aufgabe_2'  => "\\huge{$temp[2] * $temp[3]}",
				'wird_2'     => '=',
				'Ergebnis_2' => '                  '
			}
		);
	}
	return $data_table;
}

sub teilen_einfach {
	my ( @temp, $hundert, $zehn, $eins );
	my $data_table2 = data_table->new;
	foreach (qw( A x frage_1 C __ D x_2 frage_2 F )) {
		$data_table2->Add_2_Header($_);
	}

	for ( my $i = 0 ; $i < 26 ; $i++ ) {
		@temp = ( &_einer(), &_einer(), &_einer(), &_einer() );
		$hundert = $zehn = $eins = 0;
		$hundert = &_einer() . &_einer() . &_einer();
		$zehn    = &_einer() . &_einer();

#$data_table2 -> AddDataset ( {'Aufgabe' =>"\\huge{$hundert - $zehn}  ", 'wird' => '=', 'Ergebnis' => '                  '});
		$data_table2->AddDataset(
			{
				'A'       => "\\huge{$temp[0]}",
				'x'       => '*',
				'frage_1' => '   ',
				'C'       => "\\huge{= " . ( $temp[0] * $temp[1] ) . "}",
				'__'      => '               ',
				'D'       => "\\huge{$temp[2]}",
				'x_2'     => '*',
				'frage_2' => ' ',
				'F'       => "\\huge{= " . $temp[2] * $temp[3] . "}"
			}
		);
	}
	return $data_table2;
}
