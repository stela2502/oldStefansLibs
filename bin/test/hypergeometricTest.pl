#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use warnings;

my ( $debug, $help, $good, $bad, $min_good, $draws);

Getopt::Long::GetOptions(
	"-good_entries=s"   => \$good,
	"-bad_entries=s" => \$bad,
	"-draws=s" => \$draws,
	"-min_good_drawn=s" => \$min_good, 
	"-help"         => \$help,
	"-debug"        => \$debug
);

if ($help) {
	print helpString();
	exit;
}

unless ( defined $good && defined $bad && defined $min_good && defined $draws){
	print helpString("we need some values!");
	exit;	
}


print "The probability to draw at least $min_good good entries from a group consisting of $good good- and $bad bad entries entries is: ".
	&hypergeom($good, $bad, $draws, $min_good)."\n";

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for hypergeometricTest.pl

   -good_entries   :the amount of wanted entries in a group
   -bad_entries    :the amount of NOT wanted entries in a group
   -min_good_drawn :the minimum amount of good entries drawn in -draw tries
   -draw           :the amount of draws from the group
   -help           :print this help
   -debug          :verbose output


";
}

sub logfact {
   return gammln(shift(@_) + 1.0);
}

sub hypergeom {
   # There are m "bad" and n "good" balls in an urn.
   # Pick N of them. The probability of i or more successful selection +s:
   # (m!n!N!(m+n-N)!)/(i!(n-i)!(m+i-N)!(N-i)!(m+n)!)
   my ($n, $m, $N, $i) = @_;

   my $loghyp1 = logfact($m)+logfact($n)+logfact($N)+logfact($m+$n-$N);
   my $loghyp2 = logfact($i)+logfact($n-$i)+logfact($m+$i-$N)+logfact($N-$i)+logfact($m+$n);
   return exp($loghyp1 - $loghyp2);
}


sub gammln {
  my $xx = shift;
  my @cof = (76.18009172947146, -86.50532032941677,
             24.01409824083091, -1.231739572450155,
             0.12086509738661e-2, -0.5395239384953e-5);
  my $y = my $x = $xx;
  my $tmp = $x + 5.5;
  $tmp -= ($x + .5) * log($tmp);
  my $ser = 1.000000000190015;
  for my $j (0..5) {
     $ser += $cof[$j]/++$y;
  }
  -$tmp + log(2.5066282746310005*$ser/$x);
}
