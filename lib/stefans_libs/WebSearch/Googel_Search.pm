package stefans_libs_WebSearch_Googel_Search;

#  Copyright (C) 2010-12-09 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::WebSearch::Googel_Search

=head1 DESCRIPTION

Simple way to automize a google search

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::WebSearch::Googel_Search.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = { 'www_mechanize' => WWW::Mechanize->new( 'stack_depth' => 0 ) };

	bless $self, $class if ( $class eq "stefans_libs_WebSearch_Googel_Search" );

	return $self;

}

=head seach_for


=cut 

sub search_for {
	my ( $self, $search_str, $type ) = @_;
	my $page;
	$type = 'norm' unless ( defined $type);
	my $search_add = "";
	if ( $type eq "picture" ) {
		$search_add = "&tbm=isch";
	}
	eval {
		print "Googel Search!\n";
	 $page =
	  $self->{'www_mechanize'}->get(
'http://www.google.se/search?hl=en&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial$search_add&q='
		  . $search_str );
	};
	my $i = 0;
	while (! defined $page ){
		$self->{'www_mechanize'} -> cookie_jar(HTTP::Cookies->new);
		warn "#####################\nAn error occured!\nNo resultsi for search '$search_str'!\n######################\nI try to wait for google to accept my queries once more\n";
		#sleep (60 );
		$self->{'www_mechanize'} = WWW::Mechanize->new( 'stack_depth' => 0 );
eval {
	 $page =
	  $self->{'www_mechanize'}->get(
'http://www.google.se/search?hl=en&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial$search_add&q='
		  . $search_str );
	};
	$i ++ ;
	if ( $i == 2) {
		unless ( defined $page ) {
			return []; ## it does not make sense to try it more than two times!
		}
	}
	 
	}
	my $str               = $page->content();
	my $next_is_important = 0;

	my @return;
	foreach ( split( /<div/, $str ) ) {
		foreach ( split( /"/, $_ ) ) {
			if ( $_ =~ m/http:/ ) {
				next if $_ =~ m/google/;
				push( @return, $_ );
			}
		}
	}

#print "We got the interesting external links:\n".join("\n",@return)."\n" if ( defined $return [0] );
	return \@return;
}

#sub seach_Yahoo_for_documents {
#	my ( $self, $search_str ) = @_;
#	 my @Results = Yahoo::Search->Results(Doc => $search_str,
#                                      AppId => "YahooDemo"
#                                     );
# warn $@ if $@; # report any errors
#
# for my $Result (@Results)
# {
#   #  printf "Result: #%d\n",  $Result->I + 1,
#     printf "Url:%s\n",       $Result->Url;
#    # printf "%s\n",           $Result->ClickUrl;
#     printf "Summary: %s\n",  $Result->Summary;
#     printf "Title: %s\n",    $Result->Title;
#    # printf "In Cache: %s\n", $Result->CacheUrl;
#     print "\n";
# }
#
#}

1;
