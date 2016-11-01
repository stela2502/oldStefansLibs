#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::system_tables::thread_helper' }

my $thread_helper = thread_helper -> new();
is_deeply ( ref($thread_helper) , 'thread_helper', 'simple test of function thread_helper -> new()' );

## test for new

