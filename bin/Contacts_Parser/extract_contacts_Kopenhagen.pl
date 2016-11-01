#! /usr/bin/perl

use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

my $html = "http://www.research.med.lu.se/en_projektdetaljer.php?Proj=";

#<b>Agardh, Carl-David</b><br />
#Project: Mechanisms behind the development of diabetic microangiopati<br />
#The molecular pathophysiology of diabetic complications is still not f............<br />
#<a href="en_projektdetaljer.php?Proj=214">Show Project (eng)</a> - <a href="sv_projektdetaljer.php?Proj=214&amp;Lang=Sv">Visa beskrivning (swe)</a><hr />

open( IN, "<$ARGV[0]" )
  or die
"Sorry I could not open the infile '$ARGV[0]' - or didn't you give me one?\n$!\n";

#### for the web_page #####
my $server = 'http://inf.ku.dk';#http://bmi.ku.dk/'; #'http://icmm.ku.dk';

my $table = data_table->new();
foreach (qw(title firstname surname WORK_email WORK_telephone web_page)) {
    $table->Add_2_Header($_);
}
my $convert_strings = [
	{ 
		'html' => '&oslash;',
		'unicode' => 'ø',
		'latex' => ,
	},
{ 
		'html' => '&oacute;',
		'unicode' => 'ó',
		'latex' => ,
	},{ 
		'html' => '&aelig;',
		'unicode' => 'æ',
		'latex' => ,
	},{ 
		'html' => '&euml;',
		'unicode' => 'ë',
		'latex' => ,
	},{ 
		'html' => '&auml;',
		'unicode' => 'ä',
		'latex' => ,
	},{ 
		'html' => '&ouml;',
		'unicode' => 'ö',
		'latex' => ,
	},{ 
		'html' => '&uuml;',
		'unicode' => 'ü',
		'latex' => ,
	},{ 
		'html' => '&Auml;',
		'unicode' => 'Ä',
		'latex' => ,
	},{ 
		'html' => '&Ouml;',
		'unicode' => 'Ö',
		'latex' => ,
	},{ 
		'html' => '&Uuml;',
		'unicode' => 'Ü',
		'latex' => ,
	},{ 
		'html' => '&Oslash;',
		'unicode' => 'Ø',
		'latex' => ,
	},{ 
		'html' => '&aacute;',
		'unicode' => 'á',
		'latex' => ,
	},{ 
		'html' => '&aring;',
		'unicode' => 'å',
		'latex' => ,
	},{ 
		'html' => '&eacute;',
		'unicode' => 'é',
		'latex' => ,
	},{ 
		'html' => '&eth;',
		'unicode' => 'ð',
		'latex' => ,
	},
];
my ( $hash, @temp, $warn );
$warn = '';
while (<IN>) {
    next unless ( $_ =~ m/E\-mail/ );
    foreach my $line ( split( "</tr>", $_ ) ) {
	    next if ( $line =~ m/<.?table/ );
	$line = &convert_string ( $line );


        #print $line. "\n";
        my $i = 0;
        @temp = ( split( "td", $line ) );
        $hash = {
            'title'          => undef,
            'firstname'       => undef,
            'surname'        => undef,
            'WORK_email'     => undef,
            'WORK_telephone' => undef,
            'web_page'       => undef,
        };

#row 0 = <tr><
#row 1 =  valign='top'><a href="/english/staff/?id=64722&vis=medarbejder">Zeuthen, Thomas</a></
#row 2 = ><
#row 3 =  valign='top'>professor, DMSc&nbsp;</
#row 4 = ><
#row 5 =  valign='top'>+45 353-27583</
#row 6 = ><
#row 7 =  valign='top'><a href="#" onclick="this.href='mai' + 'lto:' + 'tzeuthen' + '@' + 'sund.ku.dk' ; return true;" onmouseover="this.title='tzeuthen' + '@' + 'sund.ku.dk' ; return true;">E-mail</a></
#<a href="/english/staff/?id=69159&vis=medarbejder">Lund, Leif R.</a>
        if ( $line =~
m/a href="(.+)">([áØéëåæóðøäöü\w\- ]+), ([áØëåéðæóøäöü\w\-\. ]+)<\/a>/
          )
        {
            $hash->{'web_page'} = $server . $1;
            $hash->{'firstname'} = $3;
            $hash->{'surname'}  = $2;
            print
"web_page = $hash->{'web_page'}\nforename = $hash->{'forename'}\nsurname = $hash->{'surname'}\n";
        }
	elsif ($line =~
	       m/a href="(.+)">([áØéëåæóðøäöü\w\-]+) ([áØëåéðæóøäöü\w\-\. ]+)<\/a>/
                 )
        {
		$hash->{'web_page'} = $server . $1;
		            $hash->{'firstname'} = $2;
			                $hash->{'surname'}  = $3;
					            print
						    "web_page = $hash->{'web_page'}\nforename = $hash->{'forename'}\nsurname = $hash->{'surname'}\n";
		$warn .= "firstname and surname might not be OK - MANUAL CHECK FORCED!\n" unless ( $warn =~m/firstname and surname might not be OK - MANUAL CHECK FORCED!/);
	}

        if ( $line =~ m/valign='top'>([ \-\.\,\w]+).nbsp;</ ) {
            $hash->{'title'} = $1;
            print "Title= $hash->{'title'}\n";
        }
        if ( $line =~ m/'top'>\+([\d\- ]+)</ ) {
            $hash->{'WORK_telephone'} = "00" . $1;
            $hash->{'WORK_telephone'} =~ s/-/ /;
            print "Work phone = $hash->{'WORK_telephone'}\n";
        }

        if ( $line =~ m/this.title='([\.\w]+)' \+ '\@' \+ '([\.\w]+)'/ ) {
            $hash->{'WORK_email'} = $1 . '@' . $2;
            print "Mail = $hash->{'WORK_email'}\n";
        }
        if (
            defined $hash->{'firstname'}

            #   && defined $hash->{'WORK_telephone'}
            && defined $hash->{'WORK_email'}
          )
        {
            $table->AddDataset($hash);# if ( $hash->{'title'} =~m/professor/);
        }
        elsif ( defined $hash->{'firstname'} ) { next }
        else {
            warn "The line $line did not give me a complete contact!\n";
            for ( my $i = 0 ; $i < @temp ; $i++ ) {
                warn "line $i = $temp[$i]\n";
            }
            foreach ( keys %$hash ) {
                warn "$_" . " = $hash->{$_}\n";
            }
            exit -2;
        }

    }
}
close(IN);

print "The final table looks like that:\n";
print $table->AsString();
$table->print2file($ARGV[0]);
print "Done!\n";


sub convert_string {
	my $str = shift;
	foreach ( @$convert_strings ) {
		$str =~ s/$_->{'html'}/$_->{'text'}/g;
	}
	return $str;
}


