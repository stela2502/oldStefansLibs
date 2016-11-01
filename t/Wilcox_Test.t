#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok 'stefans_libs::array_analysis::correlatingData::Wilcox_Test' }
## test for new
my $logfile = "/home/stefan_l/wilcox.log";
my $test = Wilcox_Test->new();
is_deeply( ref($test), 'Wilcox_Test', "we can get the object");

my @a = ( 6,9,11,16,13,12,15,10 );+
my @b = (0.8,0.16,0.17,0.19,0.15,0.21,0.14,0.20);
is_deeply ( $test->define_log( $logfile ), 1, "we can set up the logging system");

is_deeply ( $test->_calculate_wilcox_statistics( \@a, \@b ), "0.0009391\t64\t0.0219565217391304", "we get the right p value for an unsigned test");

is_deeply($test->SET_pairedTest(1), "paired = TRUE", "we can set a paired test");

is_deeply ( $test->_calculate_wilcox_statistics( \@a, \@b ), "0.01427\t36\t0.0219565217391304", "we get the right p value for an unsigned test");

$test = undef;

open (LOG , "<$logfile" ) or die "could not open the log file$logfile";

is_deeply ( join("", <LOG>), "x<- c(6,9,11,16,13,12,15,10)
y<-c(0.8,0.16,0.17,0.19,0.15,0.21,0.14,0.2)
res <- wilcox.test( x, y, exact = 0, paired = FALSE)
print ( res )
p=0.0009391;W=64;rho=0.0219565217391304
x<- c(6,9,11,16,13,12,15,10)
y<-c(0.8,0.16,0.17,0.19,0.15,0.21,0.14,0.2)
res <- wilcox.test( x, y, exact = 0, paired = TRUE)
print ( res )
p=0.01427;W=36;rho=0.0219565217391304
" , "the log file did contain the expected lines" );
close ( LOG );
unlink ( $logfile );