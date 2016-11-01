# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;
use lib stefans_libs;
name 'stefans_libs';

#licence 'gpl';
author 'Stefan Lang StefanLang@med.lu.se';
version '1.00';

requires ("Date::Simple");
requires 'Date::Calc';
requires "Number::Format";
requires "PerlIO::gzip";
requires "GD::SVG";
requires "DBI";
requires "inc::Module::Install";
requires "Statistics::R";
requires 'XML::LibXML';
requires 'PerlIO::gzip';
requires 'File::HomeDir';
requires 'DateTime::Format::MySQL';
requires 'Digest::MD5';
requires 'File::Copy';
requires 'FindBin';
requires 'WWW::Search::NCBI::PubMed';
requires 'Archive::Zip';
requires_external_bin ('megablast');
requires_external_bin ('formatdb');

test_requires 'Test::More';

install_script glob('bin/text/*.pl');
install_script glob('bin/array_analysis/*.pl');
install_script glob('bin/maintainance_scripts/*.pl');
install_script glob('bin/small_helpers/*.pl');
install_script glob('bin/database_scripts/*.pl');

auto_install;
WriteAll;
