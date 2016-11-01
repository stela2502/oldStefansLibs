#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok 'stefans_libs::file_readers::sequenome::resultsFile' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs_file_readers_sequenome_resultsFile -> new();
is_deeply ( ref($test_object) , 'stefans_libs_file_readers_sequenome_resultsFile', 'simple test of function stefans_libs_file_readers_sequenome_resultsFile -> new()' );

$value = $test_object->AddDataset ( {             'Well' => 0,
            'Assay' => 1,
            'Genotype' => 2,
            'Description' => 3,
            'Sample' => 4,
            'Operator' => 5, } );
is_deeply( $value, 1, "we could add a sample dataset");

$test_object = stefans_libs_file_readers_sequenome_resultsFile -> new();

$test_object-> parse_from_string ( &str() );
is_deeply( $test_object->{'addiational_header_hash'}, {
'Plate Result Report' => 0,
'Customer'    => 'Multiplex fam',
'Project' => 'Multiplex fam 101216',
'Plate' =>  'Multiplex fam pl1-4_Infinium_mix1',
'Experiment'   =>   'pl 1-4',
'Chip'	=>  1}, "the addiational_header_hash" );

is_deeply ( $test_object->print_report(), &report(), "print_report");


## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";








sub report {
	return '#######################
## Negative Controls ##
#######################
negative control tag=0
good calls=19
failed calls=1
failed assays= rs219950/C.Aggressive
#######################

#######################
##      Samples      ##
#######################
sample=1227
good calls=13
shaky calls=6
failed calls=1
shaky_assays= rs6512586/B.Moderate;rs1336163/B.Moderate;rs1871017/B.Moderate;rs160277/B.Moderate;rs4411641/C.Aggressive;rs2014286/B.Moderat
failed_assays= rs1024026/F.User Call
#######################
sample=1228
good calls=12
shaky calls=6
failed calls=2
shaky_assays= rs6512586/B.Moderate;rs1336163/B.Moderate;rs1871017/B.Moderate;rs160277/B.Moderate;rs4411641/C.Aggressive;rs2014286/B.Moderat
failed_assays= rs219950/F.User Call; rs1024026/F.User Call
#######################

#######################
##       Assays      ##
#######################
assay=rs1862737
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs1871017
good calls=0
shaky calls=2
failed calls=0
shaky_samples= 1227/B.Moderate; 1228/B.Moderate
#######################
assay=rs160277
good calls=0
shaky calls=2
failed calls=0
shaky_samples= 1227/B.Moderate; 1228/B.Moderate
#######################
assay=rs1060570
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs735877
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs4411641
good calls=0
shaky calls=2
failed calls=0
shaky_samples= 1227/C.Aggressive; 1228/C.Aggressive
#######################
assay=rs2307130
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs1336163
good calls=0
shaky calls=2
failed calls=0
shaky_samples= 1227/B.Moderate; 1228/B.Moderate
#######################
assay=rs260462
good calls=2
shaky calls=0
failed calls=0
#######################
assay=AMG_mid100
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs1367972
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs6512586
good calls=0
shaky calls=2
failed calls=0
shaky_samples= 1227/B.Moderate; 1228/B.Moderate
#######################
assay=rs1025412
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs1866561
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs2014286
good calls=0
shaky calls=2
failed calls=0
shaky_samples= 1227/B.Moderate; 1228/B.Moderate
#######################
assay=rs219950
good calls=1
shaky calls=0
failed calls=1
failed_samples= 1228/F.User Call
#######################
assay=rs1012315
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs1024026
good calls=0
shaky calls=0
failed calls=2
failed_samples= 1227/F.User Call; 1228/F.User Call
#######################
assay=rs3136618
good calls=2
shaky calls=0
failed calls=0
#######################
assay=rs1536556
good calls=2
shaky calls=0
failed calls=0
#######################
';
}


sub str{
	return "Plate Result Report
Customer\tMultiplex fam
Project\tMultiplex fam 101216
Plate\tMultiplex fam pl1-4_Infinium_mix1
Experiment\tpl 1-4
Chip\t1

Well	Assay	Genotype	Description	Sample	Operator
A01	AMG_mid100	T	A.Conservative	1227	Automatic
A01	rs1012315	G	A.Conservative	1227	Automatic
A01	rs1024026	NA	F.User Call	1227	charles
A01	rs1025412	A	A.Conservative	1227	Automatic
A01	rs1060570	G	A.Conservative	1227	Automatic
A01	rs1336163	CA	B.Moderate	1227	Automatic
A01	rs1367972	TC	A.Conservative	1227	Automatic
A01	rs1536556	AG	A.Conservative	1227	Automatic
A01	rs160277	C	B.Moderate	1227	Automatic
A01	rs1862737	C	A.Conservative	1227	Automatic
A01	rs1866561	A	A.Conservative	1227	Automatic
A01	rs1871017	G	B.Moderate	1227	Automatic
A01	rs2014286	AG	B.Moderate	1227	Automatic
A01	rs219950	C	A.Conservative	1227	Automatic
A01	rs2307130	T	A.Conservative	1227	Automatic
A01	rs260462	G	A.Conservative	1227	Automatic
A01	rs3136618	A	A.Conservative	1227	Automatic
A01	rs4411641	A	C.Aggressive	1227	Automatic
A01	rs6512586	GA	B.Moderate	1227	Automatic
A01	rs735877	G	A.Conservative	1227	Automatic
A02	AMG_mid100	T	A.Conservative	1228	Automatic
A02	rs1012315	G	A.Conservative	1228	Automatic
A02	rs1024026	NA	F.User Call	1228	charles
A02	rs1025412	A	A.Conservative	1228	Automatic
A02	rs1060570	G	A.Conservative	1228	Automatic
A02	rs1336163	CA	B.Moderate	1228	Automatic
A02	rs1367972	TC	A.Conservative	1228	Automatic
A02	rs1536556	AG	A.Conservative	1228	Automatic
A02	rs160277	C	B.Moderate	1228	Automatic
A02	rs1862737	C	A.Conservative	1228	Automatic
A02	rs1866561	A	A.Conservative	1228	Automatic
A02	rs1871017	G	B.Moderate	1228	Automatic
A02	rs2014286	AG	B.Moderate	1228	Automatic
A02	rs219950	NA	F.User Call	1228	charles
A02	rs2307130	T	A.Conservative	1228	Automatic
A02	rs260462	G	A.Conservative	1228	Automatic
A02	rs3136618	A	A.Conservative	1228	Automatic
A02	rs4411641	A	C.Aggressive	1228	Automatic
A02	rs6512586	GA	B.Moderate	1228	Automatic
A02	rs735877	G	A.Conservative	1228	Automatic
P02	AMG_mid100	NA	F.User Call	0	999
P02	rs1012315	NA	F.User Call	0	999
P02	rs1024026	NA	F.User Call	0	999
P02	rs1025412	NA	F.User Call	0	999
P02	rs1060570	NA	F.User Call	0	999
P02	rs1336163	NA	F.User Call	0	999
P02	rs1367972	NA	F.User Call	0	999
P02	rs1536556	NA	F.User Call	0	999
P02	rs160277	NA	F.User Call	0	999
P02	rs1862737	NA	F.User Call	0	999
P02	rs1866561	NA	F.User Call	0	999
P02	rs1871017	NA	F.User Call	0	999
P02	rs2014286	NA	F.User Call	0	999
P02	rs219950	A	C.Aggressive	0	Automatic
P02	rs2307130	NA	F.User Call	0	999
P02	rs260462	NA	F.User Call	0	999
P02	rs3136618	NA	F.User Call	0	999
P02	rs4411641	NA	F.User Call	0	999
P02	rs6512586	NA	F.User Call	0	999
P02	rs735877	NA	F.User Call	0	999
";
}