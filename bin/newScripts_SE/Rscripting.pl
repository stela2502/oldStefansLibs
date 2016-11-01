#! /usr/bin/perl

use strict;
use Statistics::R;

my $R = Statistics::R->new();

$R->startR();
die "R was not started!!\n" unless ( $R->is_started());

$R->send(&R_script);

#$R->send("x<- c( 1,2,3,4,5,6,7,8,9,10)");
#$R->send("y<- c( 10,9,8,7,6,5,4,3,2,1)");
#$R->send("res <- cor.test(x,y,method='spearman')");
#$R->send("print(res)");

my $result =  $R->read();
print $result;

$R->stopR();

sub R_script{

return 
"x<- c( 1,2,3,4,5,6,7,8,9,10)
y<- c( 10,9,8,7,6,5,4,3,2,1)
res <- cor.test(x,y,method='spearman')
print (res)"
}
