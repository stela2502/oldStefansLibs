#! /usr/bin/perl
use strict;

open( IN, "<$ARGV[0]" ) or die "could not open data file '$ARGV[0]'\n";

open( NDF, ">ndf_file.txt" ) or die "could nort create file ndf_file.txt";

print NDF "#ID = Chromosome and position
#CHR = chromosome information
##RANGE_GB = genome accession.VERSION
##RANGE_START = start position (relative to the RANGE_GB accession)
##SEQUENCE = the DNA sequence synthesized on the array
#ID      CHR     RANGE_GB        RANGE_START     SEQUENCE
";

open( F635, ">GSM304524_145252_635.pair" )
  or die "could not create the IP file 'GSM304524_145252_635.pair'\n";
open( F532, ">GSM304524_145252_532.pair" )
  or die "could not create INPUT file 'GSM304524_145252_532.pair'\n";
open( F635_2, ">GSM304524_145252_635_2.pair" )
  or die "could not create the IP file 'GSM304524_145252_635_2.pair'\n";
open( F532_2, ">GSM304524_145252_532_2.pair" )
  or die "could not create INPUT file 'GSM304524_145252_532_2.pair'\n";

my $i = 0;
my ( $oligoID, $start, $x, $y, $value, $rand_difference, $scale );
while (<IN>) {
    if ( $_ =~ m/ *(\d+) ([agct]+) ([agct]+) ([agct]+) ([agct]+) ([agct]+)/ ) {
        $i++;
        $oligoID = "CHR1P" . ( 201385 + $1 );
        $start = $1;
        print NDF "CHR1;$oligoID\tCHR1\tNT_113969.1\t$start\t"
          . uc($2)
          . uc($3)
          . uc($4)
          . uc($5)
          . uc($6) . "\n";
        ## now I want to create the pair files!
        # 1-39    -> 1.chain
        # 40-88   -> 2.chain
        # 89-129  -> 3.chain
        # 130-191 -> 4.chain
        # 192-204 -> 5.chain
        if ( $i < 50 || ( $i > 80 && $i < 170 ) || ( $i > 194 ) ) {
            ## we create an 'not enriched region'
            $x               = int( rand(1) * 1000 );
            $y               = int( rand(1) * 1000 );
            $value           = rand(1) * 1000;
            $rand_difference = rand(1) * 10;
            $scale           = 1;
            $scale           = -1 if ( $rand_difference > 5 );
            print F635 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . sprintf( "%.3f", $value )
              . "\t0.00\n";
            print F532 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . sprintf( "%.3f", ( $value + ( rand(100) * $scale ) ) )
              . "\t0.00\n";

            if ( $scale > 0 ) {
                $scale = -1;
            }
            else {
                $scale = 1;
            }
            print F635_2 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . sprintf( "%.3f", ( $value + $rand_difference ) )
              . "\t0.00\n";
            print F532_2 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . sprintf( "%.3f",
                ( $value + $rand_difference + ( rand(100) * $scale ) ) )
              . "\t0.00\n";
        }
        else {
            ## we want to create an enriched region
            $x               = int( rand(1) * 1000 );
            $y               = int( rand(1) * 1000 );
            $value           = rand(1) * 1000;
            $rand_difference = rand(1) * 10;
            print F635 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t$value\t0.00\n";
            print F532 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . ( $value + ( rand(100) ) )
              . "\t0.00\n";
            print F635_2 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . ($value + $rand_difference + ( rand(1000) ))
              . "\t0.00\n";
            print F532_2 "BLOCK1\tCHR1\t$oligoID\t$start\t$x\t$y\t"
              . ( 64541255 - $x + $y )
              . "\t\t"
              . ( $value + $rand_difference  )
              . "\t0.00\n";

        }
    }
}
close(NDF);
close(F635);
close(F532);
close(F635_2);
close(F532_2);
