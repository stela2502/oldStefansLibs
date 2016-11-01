#! /usr/bin/perl
#  Copyright (C) 2008 Stefan Lang

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


=head1 bibCreate.pl
A tool to craete new perl library files that should contain a gpl header.

=head2 usage
The script takes 4 command line options:
1. the package name relative to the lib path
2. a description of the new class that is included into the class's POD part
3. a optional library path (default to libFile /home/stefan_l/workspace/Stefans_Libraries/lib )
4. a optional path for the test file ( default to /home/stefan_l/workspace/Stefans_Libraries/t )
=cut

use warnings;
use strict;
use stefans_libs::root;

my ($package, $usageInfo, $libFile, $testPath) = @ARGV ;

warn "new usage: <package>, <usageInfo>, <libFile>, <testPath> \n",
"default libFile /home/stefan_l/workspace/Stefans_Libraries/lib\n",
"defualt testPath /home/stefan_l/workspace/Stefans_Libraries/t\n"  unless ( defined $usageInfo);

die "arg[0] = packageName!\n" unless ( defined $package);

my ( @package, $includeStr );

$libFile = "/home/stefan_l/workspace/Stefans_Libraries/lib" unless ( defined $libFile);
$testPath ="/home/stefan_l/workspace/Stefans_Libraries/t" unless ( defined $testPath);


@package = split( "/", $package );

die "usage has changed! we need not only the package name but also the position in the lib structure!\n" 
    unless ( @package > 1 );

$includeStr = "";
foreach (my $i =0; $i < @package -1; $i++ ){
	 $includeStr .= "$package[$i]::";
	 $libFile .= "/$package[$i]";
	 mkdir ($libFile) unless ( -d $libFile);
}
$package = "$package[@package -1]";
$includeStr .= "$package[@package -1]";
$libFile .= "/$package[@package -1].pm";


&createLibFile($libFile, $package);
&createTestFile( $libFile, $testPath, $includeStr, $package);


sub createLibFile{
	my ( $libFile, $package) = @_;
open (OUT , ">$libFile" ) or die "konnte $libFile nicht anlegen!\n";

my $package_whole = $libFile;
$package_whole =~ s/\//::/g;
print OUT 


"package $package;
#  Copyright (C) ".root->Today()." Stefan Lang

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
#use lib \"\$FindBin::Bin/../lib/\";
use strict;
use warnings;


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

$package_whole

=head1 DESCRIPTION

$usageInfo

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class $package.

=cut

sub new{

	my ( \$class ) = \@_;

	my ( \$self );

	\$self = {
  	};

  	bless \$self, \$class  if ( \$class eq \"$package\" );

  	return \$self;

}


1;
";

close (OUT);

print "Package $package wirtten as $libFile \n";
}

sub createTestFile{
  my ( $file, $testPath, $includeStr, $package ) = @_;
  return 0 unless ( $file =~ m/\.pm$/ );
 # my ( $testFile, @file, $temp, $include );
  open ( INFILE , "<$file" ) or die "could not open file $file\n";
  print "opened file $file\n";

  if ( -f "$testPath/$package.t" ){
	print "test file is already present ($testPath/$package.t)\n";
	return 1;
  }
  open ( Test , ">$testPath/$package.t" ) or die "could not open testFile $testPath/$package.t\n";

  ## we have to create a stup for each sub in the INFILE!
  print Test 
"#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok '$includeStr' }

my ( \$value, \@values, \$exp );
my \$$package = $package -> new();
is_deeply ( ref(\$$package) , '$package', 'simple test of function $package -> new()' );

#print \"\$exp = \".root->print_perl_var_def(\$value ).\";\\n\";
\n\n";



  while ( <INFILE> ) {
     if ( $_ =~ m/sub *(\w+) *{/ ){
        print "match!\n";
			print Test "## test for $1\n\n";
      }
  }
  close ( Test );
  print "created testfile $testPath/$package.t\n";
  close ( INFILE ); 	
}
