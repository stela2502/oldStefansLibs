#! /usr/bin/perl

use strict;
use warnings;

my $data =
"onClick=\"doFocus('aaa')\">AASDHPPT</a>:</b><br /><dd> The protein encoded by this gene is similar to Saccharomyces cerevisiae LYS5, which is required for<br /><dd>the activation of the alpha-aminoadipate dehydrogenase in the biosynthetic pathway of lysine.<br /><dd>Yeast alpha-aminoadipate dehydrogenase converts alpha-biosynthetic-aminoadipate semialdehyde to<br /><dd>alpha-aminoadipate. It has been suggested that defects in the human gene result in pipecolic<br /><dd>acidemia. [provided by RefSeq] </dd><br /><font size=-1></p></dd><Font size=-1><b>UniProtKB/Swiss-Prot: </font></b><a href=\"http://www.uniprot.org/uniprot/Q9NRN7#section_comments\" target=\"aaa\"";

$data = $ARGV[0] if ( defined $ARGV[0] );

print "and we matched pattern 1\n"
  if ( $data =~ s/onClick="doFocus\('aaa'\)".+<dd> // );
print "and we matched pattern 2\n" if ( $data =~ s/\s*<b>Function<\/b>: // );
print "and we matched pattern 3\n" if ( $data =~ s/.+<\/font><dd>// );
$data =~ s/<br \/><dd>/ /g;

if ( $data =~ m/(.*)<\/dd><\/font><p(.*) / ) {
    my $temp = $1;

    if ( defined $temp && !( $temp =~ m/>/ ) ) {
        $data = $1;
    }
}

if ( $data =~ m/(.*)<\/dd><br(.*)/ ) {
    my $temp = $1;
    if ( defined $temp && !( $temp =~ m/>/ ) ) {
        $data = $1;
    }
}

#$data =~ s/<.*/ /;
print $data."\n";
