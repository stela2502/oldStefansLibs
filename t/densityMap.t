#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::plot::densityMap' }

## test for new
my $densityMap = densityMap->new();

is_deeply ( ref($densityMap) , "densityMap", "simple twst for densityMap->new()");

## test for quantilCutoff

## test for createRegions_basedOnQuantile

## test for get_relPosition

## test for plot_2_image

## test for _plotAxies

## test for initAxies

## test for getXaxis

## test for getYaxis

## test for plot

## test for createPicture

## test for Color

## test for writePicture

## test for Max

## test for Min

## test for AddData

## test for DataMatrix

