#! /usr/bin/perl

use strict;

my @fileList = @ARGV;

my ( @people, $matchHash, @tag, @line );

$matchHash = {
	'islet_sample_id' => 'islet_sample_nr">(\d+)\.<',
	'nextTag'         => 'islet_sample_header">(.+)<',
	'nextValue'       => '"islet_sample_value">(.+)<',
};

foreach my $file (@fileList) {
	unless ( -f $file ) {
		warn "$file is no file!\n";
		next;
	}
	open( IN, "<$file" ) or die "could not open file $file\n";
	while (<IN>) {
		foreach my $key ( keys %$matchHash ) {
			if ( $_ =~ m/$matchHash->{$key}/ ) {
				if ( $key eq "islet_sample_id" ) {
					push( @people, {} );
				}
				die "$_ matches to $key but we have not got an id!\n"
				  if ( @people == 0 );
				$people[ @people - 1 ]->{$key} = $1;
			}
		}
		next if ( @people == 0 );
		if ( defined $people[ @people - 1 ]->{nextValue} ) {
			$people[ @people - 1 ]->{ $people[ @people - 1 ]->{nextTag} } =
			  $people[ @people - 1 ]->{nextValue};
			delete $people[ @people - 1 ]->{nextValue};
			delete $people[ @people - 1 ]->{nextTag};
		}

	}
}

my $person = $people[0];
die "no information gathered!" unless ( defined $person );

print "islet_sample_id";
$tag[0] = "islet_sample_id";

foreach my $tag ( sort keys %$person ) {
	push( @tag, $tag );
	print "\t$tag" unless ( $tag eq "islet_sample_id" );
}
print "\n";

foreach $person (@people) {
	for ( my $i = 0 ; $i < @tag ; $i++ ) {
		$line[$i] = $person->{ $tag[$i] };
	}
	if ( $line[0] < 10 ){
		$line[0] = "ISL000$line[0]";
	}
	elsif ( $line[0] < 100){
		$line[0] = "ISL00$line[0]";
	}
	elsif ( $line[0] < 1000){
		$line[0] = "ISL0$line[0]";
	}
	elsif ( $line[0] < 10000){
		$line[0] = "ISL$line[0]";
	}
	else {
		die "Sorry, but this are too many samples to fit in our Sample ID system ($line[0])!\n";
	}
	print join( "\t", @line ), "\n";
}
