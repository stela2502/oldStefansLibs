# This Makefile is for the stefans_libs extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.55_02 (Revision: 65502) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     AUTHOR => q[Stefan Lang StefanLang@med.lu.se]
#     BUILD_REQUIRES => {  }
#     DIR => []
#     DISTNAME => q[stefans_libs]
#     EXE_FILES => [q[bin/text/add_cbust2gbFile.pl], q[bin/text/addOligoInfos.pl], q[bin/text/bibCreate.pl], q[bin/text/ChromosomalRegions2SeqFiles.pl], q[bin/text/compareIdentifiedEnrichedRegions.pl], q[bin/text/convert2png.pl], q[bin/text/convert4.pl], q[bin/text/createNewDatabase.pl], q[bin/text/createRegionList.pl], q[bin/text/DensityPlots.pl], q[bin/text/EraseFeature.pl], q[bin/text/findBindingSiteInPromoterElements.pl], q[bin/text/gbFile_Pictures.pl], q[bin/text/GetNimbelGeneIDs.pl], q[bin/text/getOligoValues4regions.pl], q[bin/text/GFF_Calculator_median.pl], q[bin/text/GFFfile2histogram.pl], q[bin/text/HMM.pl], q[bin/text/hmm_execute.pl], q[bin/text/IdentifyMultiHitOligos.pl], q[bin/text/identifyPossibleAmplificates.pl], q[bin/text/importHyb.pl], q[bin/text/KlammernTest.pl], q[bin/text/MakeNormlizedGFF.pl], q[bin/text/MAplot.pl], q[bin/text/match_sorter.pl], q[bin/text/mRNA_Plot.pl], q[bin/text/ncbiBLAST_Wrap.pl], q[bin/text/newTrim.pl], q[bin/text/NimbleGeneNormalization_NoHypothesis.pl], q[bin/text/old_V_segment_blot.pl], q[bin/text/oligoEnrichmentFactorsForRegion.pl], q[bin/text/QuantilNormalization.pl], q[bin/text/Region_XY_Value_Table.pl], q[bin/text/regionXY_plot.pl], q[bin/text/tabellaricreport.pl], q[bin/text/trimPictures.pl], q[bin/text/UMS.pl], q[bin/text/V_SegmentBlot.pl], q[bin/text/V_segmentHMM_report.pl], q[bin/text/XY_plot.pl], q[bin/array_analysis/add_2_phenotype_table.pl], q[bin/array_analysis/affy_csv_to_tsv.pl], q[bin/array_analysis/arrayDataRestrictor.pl], q[bin/array_analysis/batchStatistics.pl], q[bin/array_analysis/calculateMean_std_over_genes.pl], q[bin/array_analysis/change_endung.pl], q[bin/array_analysis/Check_4_Coexpression.pl], q[bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl], q[bin/array_analysis/compareStatisticalResults.pl], q[bin/array_analysis/convert_affy_cdf_to_DBtext.pl], q[bin/array_analysis/convert_affy_cel_to_DBtext.pl], q[bin/array_analysis/convert_database_dump_to_phase_input.pl], q[bin/array_analysis/convert_Jasmina_2_phenotype.pl], q[bin/array_analysis/createConnectionNet_4_expressionArrays.pl], q[bin/array_analysis/createPhaseInputFile.pl], q[bin/array_analysis/describe_SNPs.pl], q[bin/array_analysis/download_affymetrix_files.pl], q[bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl], q[bin/array_analysis/expressionList_toBarGraphs.pl], q[bin/array_analysis/extractSampleInfo_from_HTML.pl], q[bin/array_analysis/findPutativeRegulativeElements.pl], q[bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl], q[bin/array_analysis/get_GeneDescription_from_GeneCards.pl], q[bin/array_analysis/get_location_for_gene_list.pl], q[bin/array_analysis/identify_groups_in_PPI_results.pl], q[bin/array_analysis/identifyHaplotypes.pl], q[bin/array_analysis/make_histogram.pl], q[bin/array_analysis/meanExpressionList_toBarGraphs.pl], q[bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl], q[bin/array_analysis/merge2tab_separated_files.pl], q[bin/array_analysis/parse_PPI_data.pl], q[bin/array_analysis/pca_calculation.pl], q[bin/array_analysis/plot_HistoneProbabilities_on_gbFile.pl], q[bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl], q[bin/array_analysis/printGenotypeList.pl], q[bin/array_analysis/r_controler.pl], q[bin/array_analysis/remove_heterozygot_SNPs.pl], q[bin/array_analysis/remove_variable_influence_from_expression_array.pl], q[bin/array_analysis/simpleXYplot.pl], q[bin/array_analysis/sum_up_Batch_results.pl], q[bin/array_analysis/tab_table_reformater.pl], q[bin/array_analysis/test_for_T2D_predictive_value.pl], q[bin/array_analysis/transpose.pl], q[bin/maintainance_scripts/add_configuartion.pl], q[bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl], q[bin/maintainance_scripts/add_nimbleGene_NDF_file.pl], q[bin/maintainance_scripts/bib_create.pl], q[bin/maintainance_scripts/binCreate.pl], q[bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl], q[bin/maintainance_scripts/calculateNucleosomePositionings.pl], q[bin/maintainance_scripts/changeLib_position.pl], q[bin/maintainance_scripts/compare_two_files.pl], q[bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl], q[bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl], q[bin/maintainance_scripts/get_NCBI_genome.pl], q[bin/maintainance_scripts/makeSenseOfLists.pl], q[bin/maintainance_scripts/makeTest_4_lib.pl], q[bin/maintainance_scripts/match_nucleotideArray_to_genome.pl], q[bin/maintainance_scripts/mege_two_tabSeparated_files.pl], q[bin/maintainance_scripts/old_bibCreate.pl], q[bin/maintainance_scripts/open_query_interface.pl], q[bin/small_helpers/check_database_classes.pl], q[bin/small_helpers/create_database_importScript.pl], q[bin/small_helpers/create_exec_2_add_2_table.pl], q[bin/small_helpers/create_generic_db_script.pl], q[bin/small_helpers/create_hashes_from_mysql_create.pl], q[bin/small_helpers/get_XML_helper_dataset_definition.pl], q[bin/small_helpers/make_in_paths.pl], q[bin/small_helpers/txt_table_to_latex.pl], q[bin/database_scripts/batch_insert_phenotypes.pl], q[bin/database_scripts/create_Genexpress_Plugin.pl], q[bin/database_scripts/create_phenotype_definition.pl], q[bin/database_scripts/extract_gbFile_fromDB.pl], q[bin/database_scripts/findBindingSite_in_genome.pl], q[bin/database_scripts/getFeatureNames_in_chromosomal_region.pl], q[bin/database_scripts/insert_into_dbTable_array_dataset.pl], q[bin/database_scripts/insert_phenotype_table.pl], q[bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl], q[bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl], q[bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl], q[bin/database_scripts/trimPictures.pl]]
#     NAME => q[stefans_libs]
#     NO_META => q[1]
#     PL_FILES => {  }
#     PREREQ_PM => { GD::SVG=>q[0], DateTime::Format::MySQL=>q[0], FindBin=>q[0], Archive::Zip=>q[0], formatdb=>q[0], WWW::Search::NCBI::PubMed=>q[0], PerlIO::gzip=>q[0], Statistics::R=>q[0], Date::Simple=>q[0], Digest::MD5=>q[0], megablast=>q[0], DBI=>q[0], File::Copy=>q[0], inc::Module::Install=>q[0], File::HomeDir=>q[0], ExtUtils::MakeMaker=>q[6.55], Number::Format=>q[0], Test::More=>q[0], Date::Calc=>q[0], XML::LibXML=>q[0] }
#     VERSION => q[1.00]
#     dist => {  }
#     realclean => { FILES=>q[MYMETA.yml] }
#     test => { TESTS=>q[t/_3Ddata2_Jmol_htmlPage.t t/affy_cell_flat_file.t t/affy_geneotypeCalls.t t/affy_SNP_annot.t t/affymerix_snp_data.t t/affymerix_snp_description.t t/Allele_2_Phenotype_correlator.t t/alleleFreq.t t/antibodyDB.t t/array_GFF.t t/array_Hyb.t t/array_TStat.t t/array_values.t t/arraySorter.t t/axis.t t/BESTPAIRS_SUMMARY.t t/blastLine.t t/blastResult.t t/CEL_file_storage.t t/cellTypeDB.t t/ChapterStructure.t t/chi_square.t t/chromosomal_histogram.t t/Chromosomes_plot.t t/ClusterBuster.t t/color.t t/compare_SNP_2_Gene_expression_results.t t/correlatingData.t t/creaturesTable.t t/data_table.t t/dataRow.t t/dataset_registaration.t t/db_0.0_configuration.t t/db_0.0_errorTable.pm.t t/db_0.0_fulfilledTask.t t/db_0.0_job_description.t t/db_0.0_loggingTable.t t/db_0.0_workingTable.t t/db_1.1_gbFilesTable.t t/db_1.2_gbFeaturesTable.t t/db_1_genomeImporter.t t/db_2.1.0.1_experiment.t t/db_2.1.0_scientistTable.t t/db_2.1.1.1_materialList.t t/db_2.1.1_nucleosomePositioning.t t/db_2.1.2_phenotype_registration.t t/db_2.1.2_protocol_table.t t/db_2.1.3_tissueTable.t t/db_2.1.4_external_files.t t/db_2.2.1_nucleotide_array_0.t t/db_2.3.1_oligo2dna_register.t t/db_2.3_match_oligoArray_to_genome.t t/db_2.4.0_array_dataset.t t/db_2.5.1_calculation_summary_statistics.t t/db_2.5.2_calculation_HMM.t t/db_3.1.Affy_description.t t/db_3.2_expression_estimates.t t/db_4.0_LabBook.t t/db_4_0_WGAS.t t/db_system_linkage_info.t t/deepSeq_blastLine.t t/deepSeq_region.t t/deepSequencingRegion.t t/densityMap.t t/designDB.t t/designImporter.t t/enrichedRegions.t t/evaluateHMM_data.t t/expression_net_reader.t t/familyTree.t t/fastaDB.t t/fastaFile.t t/Figure.t t/fileDB.t t/fixed_values_axis.t t/Font.t t/fulfilledTask_handler.t t/gbAxis.t t/gbFeature.t t/gbFeature_X_axis.t t/gbFile.t t/gbFile_X_axis.t t/gbFile_X_axis_with_NuclPos.t t/gbFileMerger.t t/gbHeader.t t/gbRegion.t t/genbank_flatfile_db.t t/geneDescription.t t/geneInfo.t t/genomeDB.t t/genomeSearchResult.t t/GFF_data_Y_axis.t t/gffFile.t t/gin_file.t t/gnuplotParser.t t/grant_table.t t/group3D_MatrixEntries.t t/haplotype.t t/haplotypeList.t t/hapMap_phase.t t/histogram.t t/histogram_container.t t/HMM.t t/HMM_EnrichmentFactors.t t/HMM_hypothesis.t t/HMM_state_values.t t/hmmReportEntry.t t/HTML_helper.t t/hybInfoDB.t t/hypothesis.t t/hypothesis_table.t t/imgt2gb.t t/imgtFeature.t t/imgtFeatureDB.t t/imgtFile.t t/import_KEGG_pathway.t t/importHyb.t t/inverseBlastHit.t t/KruskalWallisTest.t t/Latex_Document.t t/legendPlot.t t/linear_regression.t t/List4enrichedRegions.t t/LIST_SUMMARY.t t/list_using_table.t t/logHistogram.t t/map_file.t t/MAplot.t t/marcowChain.t t/marcowModel.t t/MDsum_output.t t/multi_axis.t t/multiline_gb_Axis.t t/multiline_HMM_Axis.t t/multilineAxis.t t/multiLineLable.t t/multiLinePlot.t t/multilineXY_axis.t t/NCBI_genome_Readme.t t/ndfFile.t t/NEW_GFF_data_Y_axis.t t/new_histogram.t t/NEW_Summary_GFF_Y_axis.t t/newGFFtoSignalMap.t t/NimbleGene_Chip_on_chip.t t/NimbleGene_config.t t/Nimblegene_GeneInfo.t t/nimbleGeneArrays.t t/normalizeGFFvalues.t t/nuclDataRow.t t/nucleotidePositioningData.t t/oligo2dnaDB.t t/oligoBin.t t/oligoBinReport.t t/oligoDB.t t/organismDB.t t/pairFile.t t/partizipatingSubjects.t t/ped_file.t t/peopleDB.t t/PHASE_outfile.t t/pictureLayout.t t/plink.t t/plot.t t/plottable.t t/plottable_gbFile.t t/primer.t t/primerList.t t/probabilityFunction.t t/project_table.t t/pubmed_search.t t/PW_table.t t/quantilNormalization.t t/queryInterface.t t/qValues.t t/R_glm.t t/Rbridge.t t/root.t t/rs_dataset.t t/ruler_x_axis.t t/sampleTable.t t/scientificComunity.t t/Section.t t/selected_regions_dataRow.t t/seq_contig.t t/simple_multiline_gb_Axis.t t/simpleBarGraph.t t/simpleWhiskerPlot.t t/simpleXYgraph.t t/singleLinePlot.t t/singleLinePlotHMM.t t/SNP_2_Gene_Expression.t t/SNP_2_gene_expression_reader.t t/SNP_cluster.t t/SpearmanTest.t t/ssake_info.t t/stat_results.t t/stat_test.t t/statisticItem.t t/stefans_libs_database_DeepSeq_genes.t t/stefans_libs_database_Protein_Expression.t t/stefans_libs_file_readers_affymetrix_expression_result.t t/stefans_libs_file_readers_CoExpressionDescription.t t/stefans_libs_file_readers_CoExpressionDescription_KEGG_results.t t/stefans_libs_file_readers_MeDIP_results.t t/stefans_libs_file_readers_phenotypes.t t/stefans_libs_file_readers_PPI_text_file.t t/stefans_libs_file_readers_stat_results_KruskalWallisTest_result.t t/stefans_libs_file_readers_svg_pathway_description.t t/stefans_libs_file_readers_UCSC_ens_Gene.t t/stefans_libs_flexible_data_structures_sequenome_resultsFile.t t/stefans_libs_Latex_Document_Chapter.t t/stefans_libs_Latex_Document_Figure.t t/stefans_libs_Latex_Document_gene_description.t t/stefans_libs_WebSearch_Googel_Search.t t/storage_table.t t/subjectTable.t t/SubPlot_element.t t/summaryLine.t t/table_script_generator.t t/tableHandling.t t/tableLine.t t/template4deepEvaluation.t t/Text.t t/thread_helper.t t/UMS.t t/UMS_EnrichmentFactors.t t/UMS_old.t t/unifiedDataHandler.t t/V_segment_summaryBlot.t t/VbinaryEvauation.t t/VbinElement.t t/Wilcox_Test.t t/X_feature.t t/XML_handler.t t/XY_Evaluation.t t/xy_graph_withHistograms.t t/XY_withHistograms.t t/XYvalues.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/perl/5.10/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -O2 -g -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = /lib/libc-2.11.1.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.6.24-27-server
RANLIB = :
SITELIBEXP = /usr/local/share/perl/5.10.1
SITEARCHEXP = /usr/local/lib/perl/5.10.1
SO = so
VENDORARCHEXP = /usr/lib/perl5
VENDORLIBEXP = /usr/share/perl5


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = stefans_libs
NAME_SYM = stefans_libs
VERSION = 1.00
VERSION_MACRO = VERSION
VERSION_SYM = 1_00
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 1.00
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1p
MAN3EXT = 3pm
INSTALLDIRS = site
DESTDIR = 
PREFIX = /usr
PERLPREFIX = $(PREFIX)
SITEPREFIX = $(PREFIX)/local
VENDORPREFIX = $(PREFIX)
INSTALLPRIVLIB = $(PERLPREFIX)/share/perl/5.10
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = $(SITEPREFIX)/share/perl/5.10.1
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = $(VENDORPREFIX)/share/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = $(PERLPREFIX)/lib/perl/5.10
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = $(SITEPREFIX)/lib/perl/5.10.1
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = $(VENDORPREFIX)/lib/perl5
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = $(PERLPREFIX)/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = $(SITEPREFIX)/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = $(VENDORPREFIX)/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = $(PERLPREFIX)/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = $(SITEPREFIX)/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = $(VENDORPREFIX)/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = $(PERLPREFIX)/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(SITEPREFIX)/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = $(VENDORPREFIX)/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = $(PERLPREFIX)/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(SITEPREFIX)/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = $(VENDORPREFIX)/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB =
PERL_ARCHLIB = /usr/lib/perl/5.10
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/perl/5.10/CORE
PERL = /usr/bin/perl "-Iinc"
FULLPERL = /usr/bin/perl "-Iinc"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/share/perl/5.10/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.55_02
MM_REVISION = 65502

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = stefans_libs
BASEEXT = stefans_libs
PARENT_NAME = 
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = bin/array_analysis/Check_4_Coexpression.pl \
	bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl \
	bin/array_analysis/add_2_phenotype_table.pl \
	bin/array_analysis/affy_csv_to_tsv.pl \
	bin/array_analysis/calculateMean_std_over_genes.pl \
	bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl \
	bin/array_analysis/convert_Jasmina_2_phenotype.pl \
	bin/array_analysis/convert_database_dump_to_phase_input.pl \
	bin/array_analysis/describe_SNPs.pl \
	bin/array_analysis/download_affymetrix_files.pl \
	bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl \
	bin/array_analysis/expressionList_toBarGraphs.pl \
	bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl \
	bin/array_analysis/get_GeneDescription_from_GeneCards.pl \
	bin/array_analysis/get_location_for_gene_list.pl \
	bin/array_analysis/identify_groups_in_PPI_results.pl \
	bin/array_analysis/make_histogram.pl \
	bin/array_analysis/meanExpressionList_toBarGraphs.pl \
	bin/array_analysis/merge2tab_separated_files.pl \
	bin/array_analysis/parse_PPI_data.pl \
	bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl \
	bin/array_analysis/remove_heterozygot_SNPs.pl \
	bin/array_analysis/remove_variable_influence_from_expression_array.pl \
	bin/array_analysis/simpleXYplot.pl \
	bin/array_analysis/sum_up_Batch_results.pl \
	bin/array_analysis/tab_table_reformater.pl \
	bin/array_analysis/test_for_T2D_predictive_value.pl \
	bin/database_scripts/batch_insert_phenotypes.pl \
	bin/database_scripts/create_Genexpress_Plugin.pl \
	bin/database_scripts/create_phenotype_definition.pl \
	bin/database_scripts/extract_gbFile_fromDB.pl \
	bin/database_scripts/getFeatureNames_in_chromosomal_region.pl \
	bin/database_scripts/insert_into_dbTable_array_dataset.pl \
	bin/database_scripts/insert_phenotype_table.pl \
	bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl \
	bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl \
	bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl \
	bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl \
	bin/maintainance_scripts/add_configuartion.pl \
	bin/maintainance_scripts/add_nimbleGene_NDF_file.pl \
	bin/maintainance_scripts/bib_create.pl \
	bin/maintainance_scripts/binCreate.pl \
	bin/maintainance_scripts/calculateNucleosomePositionings.pl \
	bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl \
	bin/maintainance_scripts/compare_two_files.pl \
	bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl \
	bin/maintainance_scripts/get_NCBI_genome.pl \
	bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl \
	bin/maintainance_scripts/makeSenseOfLists.pl \
	bin/maintainance_scripts/match_nucleotideArray_to_genome.pl \
	bin/maintainance_scripts/mege_two_tabSeparated_files.pl \
	bin/maintainance_scripts/old_bibCreate.pl \
	bin/maintainance_scripts/open_query_interface.pl \
	bin/small_helpers/check_database_classes.pl \
	bin/small_helpers/create_database_importScript.pl \
	bin/small_helpers/create_exec_2_add_2_table.pl \
	bin/small_helpers/create_generic_db_script.pl \
	bin/small_helpers/create_hashes_from_mysql_create.pl \
	bin/small_helpers/get_XML_helper_dataset_definition.pl
MAN3PODS = lib/Statistics/R.pm \
	lib/Statistics/R/Bridge.pm \
	lib/Statistics/R/Bridge/Linux.pm \
	lib/Statistics/R/Bridge/Win32.pm \
	lib/Statistics/R/Bridge/pipe.pm \
	lib/stefans_libs/Latex_Document.pm \
	lib/stefans_libs/Latex_Document/Chapter.pm \
	lib/stefans_libs/Latex_Document/Figure.pm \
	lib/stefans_libs/Latex_Document/Section.pm \
	lib/stefans_libs/Latex_Document/Text.pm \
	lib/stefans_libs/Latex_Document/gene_description.pm \
	lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm \
	lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm \
	lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm \
	lib/stefans_libs/MyProject/PHASE_outfile.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm \
	lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm \
	lib/stefans_libs/SNP_2_Gene_Expression.pm \
	lib/stefans_libs/V_segment_summaryBlot.pm \
	lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/dataRow.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm \
	lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm \
	lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm \
	lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm \
	lib/stefans_libs/WWW_Reader/pubmed_search.pm \
	lib/stefans_libs/WebSearch/Googel_Search.pm \
	lib/stefans_libs/XY_Evaluation.pm \
	lib/stefans_libs/array_analysis/correlatingData.pm \
	lib/stefans_libs/array_analysis/correlatingData/chi_square.pm \
	lib/stefans_libs/array_analysis/correlatingData/qValues.pm \
	lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm \
	lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm \
	lib/stefans_libs/array_analysis/outputFormater/dataRep.pm \
	lib/stefans_libs/array_analysis/regression_models/linear_regression.pm \
	lib/stefans_libs/array_analysis/tableHandling.pm \
	lib/stefans_libs/chromosome_ripper/gbFileMerger.pm \
	lib/stefans_libs/chromosome_ripper/seq_contig.pm \
	lib/stefans_libs/database.pm \
	lib/stefans_libs/database/DeepSeq/genes.pm \
	lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm \
	lib/stefans_libs/database/LabBook.pm \
	lib/stefans_libs/database/LabBook/ChapterStructure.pm \
	lib/stefans_libs/database/LabBook/LabBook_instance.pm \
	lib/stefans_libs/database/LabBook/figure_table.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm \
	lib/stefans_libs/database/Protein_Expression.pm \
	lib/stefans_libs/database/WGAS.pm \
	lib/stefans_libs/database/WGAS/SNP_calls.pm \
	lib/stefans_libs/database/WGAS/rsID_2_SNP.pm \
	lib/stefans_libs/database/antibodyDB.pm \
	lib/stefans_libs/database/array_GFF.pm \
	lib/stefans_libs/database/array_Hyb.pm \
	lib/stefans_libs/database/array_TStat.pm \
	lib/stefans_libs/database/array_calculation_results.pm \
	lib/stefans_libs/database/array_dataset.pm \
	lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm \
	lib/stefans_libs/database/array_dataset/genotype_calls.pm \
	lib/stefans_libs/database/array_dataset/oligo_array_values.pm \
	lib/stefans_libs/database/cellTypeDB.pm \
	lib/stefans_libs/database/creaturesTable.pm \
	lib/stefans_libs/database/creaturesTable/familyTree.pm \
	lib/stefans_libs/database/dataset_registaration/dataset_list.pm \
	lib/stefans_libs/database/dataset_registration.pm \
	lib/stefans_libs/database/designDB.pm \
	lib/stefans_libs/database/experiment.pm \
	lib/stefans_libs/database/experiment/hypothesis.pm \
	lib/stefans_libs/database/experiment/partizipatingSubjects.pm \
	lib/stefans_libs/database/experimentTypes.pm \
	lib/stefans_libs/database/experimentTypes/type_to_plugin.pm \
	lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm \
	lib/stefans_libs/database/expression_estimate/expr_est_list.pm \
	lib/stefans_libs/database/expression_estimate/probesets_table.pm \
	lib/stefans_libs/database/external_files.pm \
	lib/stefans_libs/database/external_files/file_list.pm \
	lib/stefans_libs/database/fileDB.pm \
	lib/stefans_libs/database/fulfilledTask.pm \
	lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm \
	lib/stefans_libs/database/genomeDB.pm \
	lib/stefans_libs/database/genomeDB/ROI_table.pm \
	lib/stefans_libs/database/genomeDB/SNP_table.pm \
	lib/stefans_libs/database/genomeDB/chromosomesTable.pm \
	lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm \
	lib/stefans_libs/database/genomeDB/gbFilesTable.pm \
	lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm \
	lib/stefans_libs/database/genomeDB/gene_description.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm \
	lib/stefans_libs/database/genomeDB/genomeSearchResult.pm \
	lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm \
	lib/stefans_libs/database/grant_table.pm \
	lib/stefans_libs/database/hybInfoDB.pm \
	lib/stefans_libs/database/hypothesis_table.pm \
	lib/stefans_libs/database/lists/list_using_table.pm \
	lib/stefans_libs/database/materials/materialList.pm \
	lib/stefans_libs/database/materials/materialsTable.pm \
	lib/stefans_libs/database/nucleotide_array.pm \
	lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm \
	lib/stefans_libs/database/nucleotide_array/oligoDB.pm \
	lib/stefans_libs/database/oligo2dnaDB.pm \
	lib/stefans_libs/database/oligo2dna_register.pm \
	lib/stefans_libs/database/organismDB.pm \
	lib/stefans_libs/database/pathways/kegg/kegg_genes.pm \
	lib/stefans_libs/database/project_table.pm \
	lib/stefans_libs/database/protocol_table.pm \
	lib/stefans_libs/database/publications/Authors_list.pm \
	lib/stefans_libs/database/publications/PubMed_list.pm \
	lib/stefans_libs/database/sampleTable.pm \
	lib/stefans_libs/database/sampleTable/sample_list.pm \
	lib/stefans_libs/database/scientistTable.pm \
	lib/stefans_libs/database/scientistTable/scientificComunity.pm \
	lib/stefans_libs/database/storage_table.pm \
	lib/stefans_libs/database/subjectTable.pm \
	lib/stefans_libs/database/system_tables/LinkList.pm \
	lib/stefans_libs/database/system_tables/LinkList/object_list.pm \
	lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm \
	lib/stefans_libs/database/system_tables/configuration.pm \
	lib/stefans_libs/database/system_tables/errorTable.pm \
	lib/stefans_libs/database/system_tables/executable_table.pm \
	lib/stefans_libs/database/system_tables/jobTable.pm \
	lib/stefans_libs/database/system_tables/loggingTable.pm \
	lib/stefans_libs/database/system_tables/thread_helper.pm \
	lib/stefans_libs/database/system_tables/workingTable.pm \
	lib/stefans_libs/database/tissueTable.pm \
	lib/stefans_libs/database/variable_table.pm \
	lib/stefans_libs/database/variable_table/linkage_info.pm \
	lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm \
	lib/stefans_libs/database/variable_table/queryInterface.pm \
	lib/stefans_libs/designImporter.pm \
	lib/stefans_libs/evaluation/evaluateHMM_data.pm \
	lib/stefans_libs/evaluation/tableLine.pm \
	lib/stefans_libs/exec_helper/XML_handler.pm \
	lib/stefans_libs/fastaDB.pm \
	lib/stefans_libs/fastaFile.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm \
	lib/stefans_libs/file_readers/MDsum_output.pm \
	lib/stefans_libs/file_readers/MeDIP_results.pm \
	lib/stefans_libs/file_readers/PPI_text_file.pm \
	lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm \
	lib/stefans_libs/file_readers/UCSC_ens_Gene.pm \
	lib/stefans_libs/file_readers/affymerix_snp_data.pm \
	lib/stefans_libs/file_readers/affymerix_snp_description.pm \
	lib/stefans_libs/file_readers/affymetrix_expression_result.pm \
	lib/stefans_libs/file_readers/expression_net_reader.pm \
	lib/stefans_libs/file_readers/phenotypes.pm \
	lib/stefans_libs/file_readers/plink.pm \
	lib/stefans_libs/file_readers/plink/bim_file.pm \
	lib/stefans_libs/file_readers/plink/ped_file.pm \
	lib/stefans_libs/file_readers/sequenome/resultsFile.pm \
	lib/stefans_libs/file_readers/stat_results.pm \
	lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm \
	lib/stefans_libs/file_readers/stat_results/Spearman_result.pm \
	lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm \
	lib/stefans_libs/file_readers/stat_results/base_class.pm \
	lib/stefans_libs/file_readers/svg_pathway_description.pm \
	lib/stefans_libs/flexible_data_structures/data_table.pm \
	lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm \
	lib/stefans_libs/gbFile.pm \
	lib/stefans_libs/gbFile/gbFeature.pm \
	lib/stefans_libs/gbFile/gbRegion.pm \
	lib/stefans_libs/histogram.pm \
	lib/stefans_libs/importHyb.pm \
	lib/stefans_libs/multiLinePlot.pm \
	lib/stefans_libs/multiLinePlot/multiLineLable.pm \
	lib/stefans_libs/nimbleGeneFiles/gffFile.pm \
	lib/stefans_libs/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/nimbleGeneFiles/pairFile.pm \
	lib/stefans_libs/normalize/normalizeGFFvalues.pm \
	lib/stefans_libs/normlize/normalizeGFFvalues.pm \
	lib/stefans_libs/plot/Chromosomes_plot.pm \
	lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm \
	lib/stefans_libs/plot/axis.pm \
	lib/stefans_libs/plot/figure.pm \
	lib/stefans_libs/plot/plottable_gbFile.pm \
	lib/stefans_libs/plot/simpleWhiskerPlot.pm \
	lib/stefans_libs/root.pm \
	lib/stefans_libs/sequence_modification/blastResult.pm \
	lib/stefans_libs/sequence_modification/deepSequencingRegion.pm \
	lib/stefans_libs/statistics/HMM.pm \
	lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm \
	lib/stefans_libs/statistics/HMM/UMS.pm \
	lib/stefans_libs/statistics/HMM/marcowChain.pm \
	lib/stefans_libs/statistics/HMM/probabilityFunction.pm \
	lib/stefans_libs/statistics/HMM/state_values.pm \
	lib/stefans_libs/statistics/new_histogram.pm \
	lib/stefans_libs/tableHandling.pm \
	plot_differences_4_gene_SNP_comparisons.pl

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = delete.pl \
	lib/Statistics/R.pm \
	lib/Statistics/R/Bridge.pm \
	lib/Statistics/R/Bridge/Linux.pm \
	lib/Statistics/R/Bridge/Win32.pm \
	lib/Statistics/R/Bridge/pipe.pm \
	lib/stefans_libs/.dat \
	lib/stefans_libs/.dat.oligoIDs.dat \
	lib/stefans_libs/Latex_Document.pm \
	lib/stefans_libs/Latex_Document/Chapter.pm \
	lib/stefans_libs/Latex_Document/Figure.pm \
	lib/stefans_libs/Latex_Document/Section.pm \
	lib/stefans_libs/Latex_Document/Text.pm \
	lib/stefans_libs/Latex_Document/gene_description.pm \
	lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm \
	lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm \
	lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm \
	lib/stefans_libs/MyProject/PHASE_outfile.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm \
	lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm \
	lib/stefans_libs/NimbleGene_config.pm \
	lib/stefans_libs/SNP_2_Gene_Expression.pm \
	lib/stefans_libs/V_segment_summaryBlot.pm \
	lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/List4enrichedRegions.pm \
	lib/stefans_libs/V_segment_summaryBlot/NEW_GFF_data_Y_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/NEW_Summary_GFF_Y_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/SubPlot_element.pm \
	lib/stefans_libs/V_segment_summaryBlot/dataRow.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/test.pl \
	lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis_with_NuclPos.pm \
	lib/stefans_libs/V_segment_summaryBlot/hmmReportEntry.pm \
	lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm \
	lib/stefans_libs/V_segment_summaryBlot/oligoBinReport.pm \
	lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm \
	lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm \
	lib/stefans_libs/V_segment_summaryBlot/testgbFeature_X_axis.pl \
	lib/stefans_libs/WWW_Reader/pubmed_search.pm \
	lib/stefans_libs/WebSearch/Googel_Search.pm \
	lib/stefans_libs/XY_Evaluation.pm \
	lib/stefans_libs/array_analysis/Rbridge.pm \
	lib/stefans_libs/array_analysis/affy_files/gin_file.pm \
	lib/stefans_libs/array_analysis/correlatingData.pm \
	lib/stefans_libs/array_analysis/correlatingData/KruskalWallisTest.pm \
	lib/stefans_libs/array_analysis/correlatingData/R_glm.pm \
	lib/stefans_libs/array_analysis/correlatingData/SpearmanTest.pm \
	lib/stefans_libs/array_analysis/correlatingData/Wilcox_Test.pm \
	lib/stefans_libs/array_analysis/correlatingData/chi_square.pm \
	lib/stefans_libs/array_analysis/correlatingData/qValues.pm \
	lib/stefans_libs/array_analysis/correlatingData/stat_test.pm \
	lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot/alleleFreq.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/SNP_cluster.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/rs_dataset.pm \
	lib/stefans_libs/array_analysis/dataRep/geneInfo.pm \
	lib/stefans_libs/array_analysis/dataRep/hapMap_phase.pm \
	lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotype.pm \
	lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotypeList.pm \
	lib/stefans_libs/array_analysis/dataRep/oligo2DNA_table.pm \
	lib/stefans_libs/array_analysis/group3D_MatrixEntries.pm \
	lib/stefans_libs/array_analysis/outputFormater/HTML_helper.pm \
	lib/stefans_libs/array_analysis/outputFormater/XY_withHistograms.pm \
	lib/stefans_libs/array_analysis/outputFormater/_3Ddata2_Jmol_htmlPage.pm \
	lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm \
	lib/stefans_libs/array_analysis/outputFormater/dataRep.pm \
	lib/stefans_libs/array_analysis/outputFormater/sortOrderTest.pl \
	lib/stefans_libs/array_analysis/regression_models/linear_regression.pm \
	lib/stefans_libs/array_analysis/tableHandling.pm \
	lib/stefans_libs/array_analysis/template4deepEvaluation.pm \
	lib/stefans_libs/axis_template.txt \
	lib/stefans_libs/binaryEvaluation/VbinElement.pm \
	lib/stefans_libs/binaryEvaluation/VbinaryEvauation.pm \
	lib/stefans_libs/chromosome_ripper/gbFileMerger.pm \
	lib/stefans_libs/chromosome_ripper/seq_contig.pm \
	lib/stefans_libs/database.pm \
	lib/stefans_libs/database/Affymetrix_expression_lib.pm \
	lib/stefans_libs/database/DeepSeq/genes.pm \
	lib/stefans_libs/database/DeepSeq/genes/gene_names.pm \
	lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/exons.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm \
	lib/stefans_libs/database/LabBook.pm \
	lib/stefans_libs/database/LabBook/ChapterStructure.pm \
	lib/stefans_libs/database/LabBook/LabBook_instance.pm \
	lib/stefans_libs/database/LabBook/figure_table.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm \
	lib/stefans_libs/database/Protein_Expression.pm \
	lib/stefans_libs/database/Protein_Expression/gene_ids.pm \
	lib/stefans_libs/database/PubMed_queries.pm \
	lib/stefans_libs/database/ROI_registration.pm \
	lib/stefans_libs/database/WGAS.pm \
	lib/stefans_libs/database/WGAS/SNP_calls.pm \
	lib/stefans_libs/database/WGAS/rsID_2_SNP.pm \
	lib/stefans_libs/database/antibodyDB.pm \
	lib/stefans_libs/database/array_GFF.pm \
	lib/stefans_libs/database/array_Hyb.pm \
	lib/stefans_libs/database/array_TStat.pm \
	lib/stefans_libs/database/array_calculation_results.pm \
	lib/stefans_libs/database/array_dataset.pm \
	lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm \
	lib/stefans_libs/database/array_dataset/Affymetrix_SNP_array.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm \
	lib/stefans_libs/database/array_dataset/genotype_calls.pm \
	lib/stefans_libs/database/array_dataset/oligo_array_values.pm \
	lib/stefans_libs/database/cellTypeDB.pm \
	lib/stefans_libs/database/creaturesTable.pm \
	lib/stefans_libs/database/creaturesTable/familyTree.pm \
	lib/stefans_libs/database/dataset.sql \
	lib/stefans_libs/database/dataset_registaration/dataset_list.pm \
	lib/stefans_libs/database/dataset_registration.pm \
	lib/stefans_libs/database/designDB.pm \
	lib/stefans_libs/database/experiment.pm \
	lib/stefans_libs/database/experiment/hypothesis.pm \
	lib/stefans_libs/database/experiment/partizipatingSubjects.pm \
	lib/stefans_libs/database/experimentTypes.pm \
	lib/stefans_libs/database/experimentTypes/type_to_plugin.pm \
	lib/stefans_libs/database/expression_estimate.pm \
	lib/stefans_libs/database/expression_estimate/Affy_description.pm \
	lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm \
	lib/stefans_libs/database/expression_estimate/expr_est.pm \
	lib/stefans_libs/database/expression_estimate/expr_est_list.pm \
	lib/stefans_libs/database/expression_estimate/probesets_table.pm \
	lib/stefans_libs/database/expression_net.pm \
	lib/stefans_libs/database/expression_net/expression_net_data.pm \
	lib/stefans_libs/database/external_files.pm \
	lib/stefans_libs/database/external_files/file_list.pm \
	lib/stefans_libs/database/fileDB.pm \
	lib/stefans_libs/database/fulfilledTask.pm \
	lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm \
	lib/stefans_libs/database/genomeDB.pm \
	lib/stefans_libs/database/genomeDB/ROI_table.pm \
	lib/stefans_libs/database/genomeDB/SNP_table.pm \
	lib/stefans_libs/database/genomeDB/chromosomesTable.pm \
	lib/stefans_libs/database/genomeDB/db_xref_table.pm \
	lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm \
	lib/stefans_libs/database/genomeDB/gbFilesTable.pm \
	lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm \
	lib/stefans_libs/database/genomeDB/gene_description.pm \
	lib/stefans_libs/database/genomeDB/gene_description/gene_aliases.pm \
	lib/stefans_libs/database/genomeDB/gene_description/genes_of_importance.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm \
	lib/stefans_libs/database/genomeDB/genomeSearchResult.pm \
	lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm \
	lib/stefans_libs/database/grant_table.pm \
	lib/stefans_libs/database/hybInfoDB.pm \
	lib/stefans_libs/database/hypothesis_table.pm \
	lib/stefans_libs/database/lists/basic_list.pm \
	lib/stefans_libs/database/lists/list_using_table.pm \
	lib/stefans_libs/database/materials/materialList.pm \
	lib/stefans_libs/database/materials/materialsTable.pm \
	lib/stefans_libs/database/nucleotide_array.pm \
	lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_array.pm \
	lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/enrichedRegions.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm \
	lib/stefans_libs/database/nucleotide_array/oligoDB.pm \
	lib/stefans_libs/database/oligo2dnaDB.pm \
	lib/stefans_libs/database/oligo2dna_register.pm \
	lib/stefans_libs/database/organismDB.pm \
	lib/stefans_libs/database/pathways/kegg/hypergeometric_max_hits.pm \
	lib/stefans_libs/database/pathways/kegg/kegg_genes.pm \
	lib/stefans_libs/database/pathways/kegg/kegg_pathway.pm \
	lib/stefans_libs/database/project_table.pm \
	lib/stefans_libs/database/protocol_table.pm \
	lib/stefans_libs/database/publications/Authors.pm \
	lib/stefans_libs/database/publications/Authors_list.pm \
	lib/stefans_libs/database/publications/Journals.pm \
	lib/stefans_libs/database/publications/PubMed.pm \
	lib/stefans_libs/database/publications/PubMed_list.pm \
	lib/stefans_libs/database/sampleTable.pm \
	lib/stefans_libs/database/sampleTable/sample_list.pm \
	lib/stefans_libs/database/sampleTable/sample_types.pm \
	lib/stefans_libs/database/scientistTable.pm \
	lib/stefans_libs/database/scientistTable/PW_table.pm \
	lib/stefans_libs/database/scientistTable/action_group_list.pm \
	lib/stefans_libs/database/scientistTable/action_groups.pm \
	lib/stefans_libs/database/scientistTable/role_list.pm \
	lib/stefans_libs/database/scientistTable/roles.pm \
	lib/stefans_libs/database/scientistTable/scientificComunity.pm \
	lib/stefans_libs/database/script.sql \
	lib/stefans_libs/database/sequenome_data.pm \
	lib/stefans_libs/database/sequenome_data/sequenome_assays.pm \
	lib/stefans_libs/database/sequenome_data/sequenome_chips.pm \
	lib/stefans_libs/database/sequenome_data/sequenome_quality.pm \
	lib/stefans_libs/database/storage_table.pm \
	lib/stefans_libs/database/subjectTable.pm \
	lib/stefans_libs/database/subjectTable/phenotype/binary_mono.pm \
	lib/stefans_libs/database/subjectTable/phenotype/binary_multi.pm \
	lib/stefans_libs/database/subjectTable/phenotype/continuose_mono.pm \
	lib/stefans_libs/database/subjectTable/phenotype/continuose_multi.pm \
	lib/stefans_libs/database/subjectTable/phenotype/familyHistory.pm \
	lib/stefans_libs/database/subjectTable/phenotype/ph_age.pm \
	lib/stefans_libs/database/subjectTable/phenotype/phenotype_base_class.pm \
	lib/stefans_libs/database/subjectTable/phenotype_registration.pm \
	lib/stefans_libs/database/system_tables/LinkList.pm \
	lib/stefans_libs/database/system_tables/LinkList/object_list.pm \
	lib/stefans_libs/database/system_tables/LinkList/www_object_table.pm \
	lib/stefans_libs/database/system_tables/PluginRegister.pm \
	lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm \
	lib/stefans_libs/database/system_tables/PluginRegister/exportables.pm \
	lib/stefans_libs/database/system_tables/configuration.pm \
	lib/stefans_libs/database/system_tables/errorTable.pm \
	lib/stefans_libs/database/system_tables/executable_table.pm \
	lib/stefans_libs/database/system_tables/jobTable.pm \
	lib/stefans_libs/database/system_tables/loggingTable.pm \
	lib/stefans_libs/database/system_tables/passwords.pm \
	lib/stefans_libs/database/system_tables/roles.pm \
	lib/stefans_libs/database/system_tables/thread_helper.pm \
	lib/stefans_libs/database/system_tables/workingTable.pm \
	lib/stefans_libs/database/tissueTable.pm \
	lib/stefans_libs/database/to_do_list.pm \
	lib/stefans_libs/database/variable_table.pm \
	lib/stefans_libs/database/variable_table/linkage_info.pm \
	lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm \
	lib/stefans_libs/database/variable_table/queryInterface.pm \
	lib/stefans_libs/database/wish_list.pm \
	lib/stefans_libs/db_report/plottable_gbFile.pm \
	lib/stefans_libs/designImporter.pm \
	lib/stefans_libs/doc/NimbleGene_config.html \
	lib/stefans_libs/doc/Script.sh \
	lib/stefans_libs/doc/chromosome_ripper/gbFileMerger.html \
	lib/stefans_libs/doc/chromosome_ripper/seq_contig.html \
	lib/stefans_libs/doc/createHTMP_help.pl \
	lib/stefans_libs/doc/database/antibodyDB.html \
	lib/stefans_libs/doc/database/array_GFF.html \
	lib/stefans_libs/doc/database/array_Hyb.html \
	lib/stefans_libs/doc/database/array_TStat.html \
	lib/stefans_libs/doc/database/cellTypeDB.html \
	lib/stefans_libs/doc/database/designDB.html \
	lib/stefans_libs/doc/database/fileDB.html \
	lib/stefans_libs/doc/database/hybInfoDB.html \
	lib/stefans_libs/doc/database/oligo2dnaDB.html \
	lib/stefans_libs/doc/designImporter.html \
	lib/stefans_libs/doc/evaluation/GBpict.html \
	lib/stefans_libs/doc/evaluation/evaluateHMM_data.html \
	lib/stefans_libs/doc/evaluation/plotGFF_Files_HMM.html \
	lib/stefans_libs/doc/evaluation/summaryLine.html \
	lib/stefans_libs/doc/evaluation/tableLine.html \
	lib/stefans_libs/doc/fastaFile.html \
	lib/stefans_libs/doc/gbFile.html \
	lib/stefans_libs/doc/gbFile/gbFeature.html \
	lib/stefans_libs/doc/gbFile/gbHeader.html \
	lib/stefans_libs/doc/gbFile/gbRegion.html \
	lib/stefans_libs/doc/histogram.html \
	lib/stefans_libs/doc/importHyb.html \
	lib/stefans_libs/doc/list.files \
	lib/stefans_libs/doc/nimbleGeneFiles/gffFile.html \
	lib/stefans_libs/doc/nimbleGeneFiles/ndfFile.html \
	lib/stefans_libs/doc/nimbleGeneFiles/pairFile.html \
	lib/stefans_libs/doc/pod2htmd.tmp \
	lib/stefans_libs/doc/pod2htmi.tmp \
	lib/stefans_libs/doc/root.html \
	lib/stefans_libs/doc/sequence_modification/blastLine.html \
	lib/stefans_libs/doc/sequence_modification/blastResult.html \
	lib/stefans_libs/doc/sequence_modification/imgt2gb.html \
	lib/stefans_libs/doc/sequence_modification/imgtFeature.html \
	lib/stefans_libs/doc/sequence_modification/imgtFeatureDB.html \
	lib/stefans_libs/doc/sequence_modification/imgtFile.html \
	lib/stefans_libs/doc/sequence_modification/inverseBlastHit.html \
	lib/stefans_libs/doc/sequence_modification/primer.html \
	lib/stefans_libs/doc/sequence_modification/primerList.html \
	lib/stefans_libs/doc/statistics/HMM.html \
	lib/stefans_libs/doc/statistics/MAplot.html \
	lib/stefans_libs/doc/statistics/UMS.html \
	lib/stefans_libs/doc/statistics/newGFFtoSignalMap.html \
	lib/stefans_libs/doc/statistics/statisticItem.html \
	lib/stefans_libs/doc/statistics/statisticItemList.html \
	lib/stefans_libs/evaluation/evaluateHMM_data.pm \
	lib/stefans_libs/evaluation/probTest.pl \
	lib/stefans_libs/evaluation/summaryLine.pm \
	lib/stefans_libs/evaluation/tableLine.pm \
	lib/stefans_libs/exec_helper/XML_handler.pm \
	lib/stefans_libs/fastaDB.pm \
	lib/stefans_libs/fastaFile.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm \
	lib/stefans_libs/file_readers/MDsum_output.pm \
	lib/stefans_libs/file_readers/MeDIP_results.pm \
	lib/stefans_libs/file_readers/PPI_text_file.pm \
	lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm \
	lib/stefans_libs/file_readers/UCSC_ens_Gene.pm \
	lib/stefans_libs/file_readers/affymerix_snp_data.pm \
	lib/stefans_libs/file_readers/affymerix_snp_description.pm \
	lib/stefans_libs/file_readers/affymetrix_expression_result.pm \
	lib/stefans_libs/file_readers/expression_net_reader.pm \
	lib/stefans_libs/file_readers/phenotypes.pm \
	lib/stefans_libs/file_readers/plink.pm \
	lib/stefans_libs/file_readers/plink/bim_file.pm \
	lib/stefans_libs/file_readers/plink/ped_file.pm \
	lib/stefans_libs/file_readers/sequenome/resultFile/report.pm \
	lib/stefans_libs/file_readers/sequenome/resultsFile.pm \
	lib/stefans_libs/file_readers/stat_results.pm \
	lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm \
	lib/stefans_libs/file_readers/stat_results/Spearman_result.pm \
	lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm \
	lib/stefans_libs/file_readers/stat_results/base_class.pm \
	lib/stefans_libs/file_readers/svg_pathway_description.pm \
	lib/stefans_libs/flexible_data_structures/data_table.pm \
	lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm \
	lib/stefans_libs/fonts/LinLibertineFont-2.3.2.tgz \
	lib/stefans_libs/fonts/LinLibertineFont/Bugs \
	lib/stefans_libs/fonts/LinLibertineFont/ChangeLog.txt \
	lib/stefans_libs/fonts/LinLibertineFont/GPL.txt \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH-2.1.8.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_Bd-2.1.8.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_BdIt-2.1.6.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_It-2.1.6.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/README-hinted \
	lib/stefans_libs/fonts/LinLibertineFont/LICENCE.txt \
	lib/stefans_libs/fonts/LinLibertineFont/LaTex/LibertineInConTeXt.txt \
	lib/stefans_libs/fonts/LinLibertineFont/LaTex/README-TEX.txt \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.otf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_Bd-2.1.0.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_R-2.1.0.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.otf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.otf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.otf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.otf \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.ttf \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine-2.1.9.dfont \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_Bd-2.1.6.dfont \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_It-2.1.6.dfont \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinuxLibertine-BdIt-2.1.6.dfont \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/README-MAC.txt \
	lib/stefans_libs/fonts/LinLibertineFont/OFL.txt \
	lib/stefans_libs/fonts/LinLibertineFont/Readme \
	lib/stefans_libs/gbFile.pm \
	lib/stefans_libs/gbFile/gbFeature.pm \
	lib/stefans_libs/gbFile/gbHeader.pm \
	lib/stefans_libs/gbFile/gbRegion.pm \
	lib/stefans_libs/graphical_Nucleosom_density/nuclDataRow.pm \
	lib/stefans_libs/graphical_Nucleosom_density/nucleotidePositioningData.pm \
	lib/stefans_libs/histogram.pm \
	lib/stefans_libs/histogram_container.pm \
	lib/stefans_libs/importHyb.pm \
	lib/stefans_libs/multiLinePlot.pm \
	lib/stefans_libs/multiLinePlot/XYvalues.pm \
	lib/stefans_libs/multiLinePlot/multiLineLable.pm \
	lib/stefans_libs/multiLinePlot/multilineAxis.pm \
	lib/stefans_libs/multiLinePlot/multilineXY_axis.pm \
	lib/stefans_libs/multiLinePlot/multiline_HMM_Axis.pm \
	lib/stefans_libs/multiLinePlot/multiline_gb_Axis.pm \
	lib/stefans_libs/multiLinePlot/ruler_x_axis.pm \
	lib/stefans_libs/multiLinePlot/simple_multiline_gb_Axis.pm \
	lib/stefans_libs/nimbleGeneFiles/enrichedRegions.pm \
	lib/stefans_libs/nimbleGeneFiles/gffFile.pm \
	lib/stefans_libs/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/nimbleGeneFiles/pairFile.pm \
	lib/stefans_libs/normalize/normalizeGFFvalues.pm \
	lib/stefans_libs/normalize/quantilNormalization.pm \
	lib/stefans_libs/normlize/normalizeGFFvalues.pm \
	lib/stefans_libs/normlize/quantilNormalization.pm \
	lib/stefans_libs/plot.pm \
	lib/stefans_libs/plot/Chromosomes_plot.pm \
	lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm \
	lib/stefans_libs/plot/Font.pm \
	lib/stefans_libs/plot/axis.pm \
	lib/stefans_libs/plot/color.pm \
	lib/stefans_libs/plot/densityMap.pm \
	lib/stefans_libs/plot/dimensionTest.pl \
	lib/stefans_libs/plot/figure.pm \
	lib/stefans_libs/plot/fixed_values_axis.pm \
	lib/stefans_libs/plot/gbAxis.pm \
	lib/stefans_libs/plot/legendPlot.pm \
	lib/stefans_libs/plot/multi_axis.pm \
	lib/stefans_libs/plot/plottable_gbFile.pm \
	lib/stefans_libs/plot/simpleBarGraph.pm \
	lib/stefans_libs/plot/simpleWhiskerPlot.pm \
	lib/stefans_libs/plot/simpleXYgraph.pm \
	lib/stefans_libs/plot/xy_graph_withHistograms.pm \
	lib/stefans_libs/qantilTest.pl \
	lib/stefans_libs/r_Birdge/testR.pl \
	lib/stefans_libs/root.pm \
	lib/stefans_libs/sequence_modification/ClusterBuster.pm \
	lib/stefans_libs/sequence_modification/blastLine.pm \
	lib/stefans_libs/sequence_modification/blastResult.pm \
	lib/stefans_libs/sequence_modification/deepSeq_blastLine.pm \
	lib/stefans_libs/sequence_modification/deepSeq_region.pm \
	lib/stefans_libs/sequence_modification/deepSequencingRegion.pm \
	lib/stefans_libs/sequence_modification/imgt2gb.pm \
	lib/stefans_libs/sequence_modification/imgtFeature.pm \
	lib/stefans_libs/sequence_modification/imgtFeatureDB.pm \
	lib/stefans_libs/sequence_modification/imgtFile.pm \
	lib/stefans_libs/sequence_modification/imgtFileTester.pl \
	lib/stefans_libs/sequence_modification/inverseBlastHit.pm \
	lib/stefans_libs/sequence_modification/primer.pm \
	lib/stefans_libs/sequence_modification/primerList.pm \
	lib/stefans_libs/sequence_modification/ssake_info.pm \
	lib/stefans_libs/sequence_modification/testInversBlastHit.pl \
	lib/stefans_libs/singleLinePlot.pm \
	lib/stefans_libs/singleLinePlotHMM.pm \
	lib/stefans_libs/statistics/GetCategoryOfTI.pl \
	lib/stefans_libs/statistics/HMM.pm \
	lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm \
	lib/stefans_libs/statistics/HMM/UMS.pm \
	lib/stefans_libs/statistics/HMM/UMS_EnrichmentFactors.pm \
	lib/stefans_libs/statistics/HMM/UMS_old.pm \
	lib/stefans_libs/statistics/HMM/logHistogram.pm \
	lib/stefans_libs/statistics/HMM/marcowChain.pm \
	lib/stefans_libs/statistics/HMM/marcowModel.pm \
	lib/stefans_libs/statistics/HMM/probabilityFunction.pm \
	lib/stefans_libs/statistics/HMM/state_values.pm \
	lib/stefans_libs/statistics/HMM_EnrichmentFactors.pm \
	lib/stefans_libs/statistics/MAplot.pm \
	lib/stefans_libs/statistics/gnuplotParser.pm \
	lib/stefans_libs/statistics/newGFFtoSignalMap.pm \
	lib/stefans_libs/statistics/new_histogram.pm \
	lib/stefans_libs/statistics/statisticItem.pm \
	lib/stefans_libs/statistics/statisticItemList.pm \
	lib/stefans_libs/tableHandling.pm \
	lib/stefans_libs/testBins/Testplot.pl \
	lib/stefans_libs/testBins/xy_test.pl \
	makeTest_4_lib.pl \
	plot_differences_4_gene_SNP_comparisons.pl

PM_TO_BLIB = lib/stefans_libs/doc/list.files \
	blib/lib/stefans_libs/doc/list.files \
	lib/stefans_libs/database/genomeDB/gene_description.pm \
	blib/lib/stefans_libs/database/genomeDB/gene_description.pm \
	lib/Statistics/R/Bridge/pipe.pm \
	blib/lib/Statistics/R/Bridge/pipe.pm \
	lib/stefans_libs/gbFile/gbFeature.pm \
	blib/lib/stefans_libs/gbFile/gbFeature.pm \
	lib/stefans_libs/database/subjectTable/phenotype/phenotype_base_class.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/phenotype_base_class.pm \
	lib/stefans_libs/database/LabBook/figure_table.pm \
	blib/lib/stefans_libs/database/LabBook/figure_table.pm \
	lib/stefans_libs/database/scientistTable/role_list.pm \
	blib/lib/stefans_libs/database/scientistTable/role_list.pm \
	lib/stefans_libs/V_segment_summaryBlot/testgbFeature_X_axis.pl \
	blib/lib/stefans_libs/V_segment_summaryBlot/testgbFeature_X_axis.pl \
	lib/stefans_libs/nimbleGeneFiles/enrichedRegions.pm \
	blib/lib/stefans_libs/nimbleGeneFiles/enrichedRegions.pm \
	lib/stefans_libs/database/LabBook/ChapterStructure.pm \
	blib/lib/stefans_libs/database/LabBook/ChapterStructure.pm \
	lib/stefans_libs/database/dataset_registaration/dataset_list.pm \
	blib/lib/stefans_libs/database/dataset_registaration/dataset_list.pm \
	lib/stefans_libs/sequence_modification/imgtFileTester.pl \
	blib/lib/stefans_libs/sequence_modification/imgtFileTester.pl \
	lib/stefans_libs/database/array_dataset/Affymetrix_SNP_array.pm \
	blib/lib/stefans_libs/database/array_dataset/Affymetrix_SNP_array.pm \
	lib/stefans_libs/array_analysis/outputFormater/HTML_helper.pm \
	blib/lib/stefans_libs/array_analysis/outputFormater/HTML_helper.pm \
	lib/stefans_libs/V_segment_summaryBlot/List4enrichedRegions.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/List4enrichedRegions.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinuxLibertine-BdIt-2.1.6.dfont \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinuxLibertine-BdIt-2.1.6.dfont \
	lib/stefans_libs/doc/database/fileDB.html \
	blib/lib/stefans_libs/doc/database/fileDB.html \
	lib/stefans_libs/array_analysis/correlatingData/qValues.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/qValues.pm \
	lib/stefans_libs/array_analysis/dataRep/geneInfo.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/geneInfo.pm \
	lib/stefans_libs/Latex_Document/Section.pm \
	blib/lib/stefans_libs/Latex_Document/Section.pm \
	lib/stefans_libs/plot/Chromosomes_plot.pm \
	blib/lib/stefans_libs/plot/Chromosomes_plot.pm \
	lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm \
	blib/lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm \
	lib/stefans_libs/database/fileDB.pm \
	blib/lib/stefans_libs/database/fileDB.pm \
	lib/stefans_libs/V_segment_summaryBlot/dataRow.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/dataRow.pm \
	lib/stefans_libs/file_readers/MDsum_output.pm \
	blib/lib/stefans_libs/file_readers/MDsum_output.pm \
	lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_array.pm \
	blib/lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_array.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.otf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.otf \
	lib/stefans_libs/normlize/quantilNormalization.pm \
	blib/lib/stefans_libs/normlize/quantilNormalization.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_It-2.1.6.dfont \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_It-2.1.6.dfont \
	lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm \
	blib/lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm \
	lib/stefans_libs/database/array_GFF.pm \
	blib/lib/stefans_libs/database/array_GFF.pm \
	lib/stefans_libs/array_analysis/affy_files/gin_file.pm \
	blib/lib/stefans_libs/array_analysis/affy_files/gin_file.pm \
	lib/stefans_libs/database/Protein_Expression.pm \
	blib/lib/stefans_libs/database/Protein_Expression.pm \
	makeTest_4_lib.pl \
	$(INST_LIB)/makeTest_4_lib.pl \
	lib/stefans_libs/doc/Script.sh \
	blib/lib/stefans_libs/doc/Script.sh \
	lib/stefans_libs/array_analysis/outputFormater/_3Ddata2_Jmol_htmlPage.pm \
	blib/lib/stefans_libs/array_analysis/outputFormater/_3Ddata2_Jmol_htmlPage.pm \
	lib/stefans_libs/multiLinePlot/multilineAxis.pm \
	blib/lib/stefans_libs/multiLinePlot/multilineAxis.pm \
	lib/stefans_libs/doc/statistics/newGFFtoSignalMap.html \
	blib/lib/stefans_libs/doc/statistics/newGFFtoSignalMap.html \
	lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm \
	blib/lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm \
	lib/stefans_libs/root.pm \
	blib/lib/stefans_libs/root.pm \
	lib/stefans_libs/database/protocol_table.pm \
	blib/lib/stefans_libs/database/protocol_table.pm \
	lib/stefans_libs/database/experimentTypes/type_to_plugin.pm \
	blib/lib/stefans_libs/database/experimentTypes/type_to_plugin.pm \
	lib/stefans_libs/gbFile/gbRegion.pm \
	blib/lib/stefans_libs/gbFile/gbRegion.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm \
	blib/lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm \
	blib/lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm \
	lib/stefans_libs/chromosome_ripper/gbFileMerger.pm \
	blib/lib/stefans_libs/chromosome_ripper/gbFileMerger.pm \
	lib/stefans_libs/doc/evaluation/plotGFF_Files_HMM.html \
	blib/lib/stefans_libs/doc/evaluation/plotGFF_Files_HMM.html \
	lib/stefans_libs/database/publications/Authors_list.pm \
	blib/lib/stefans_libs/database/publications/Authors_list.pm \
	lib/stefans_libs/plot/fixed_values_axis.pm \
	blib/lib/stefans_libs/plot/fixed_values_axis.pm \
	lib/stefans_libs/sequence_modification/ClusterBuster.pm \
	blib/lib/stefans_libs/sequence_modification/ClusterBuster.pm \
	lib/stefans_libs/database/hybInfoDB.pm \
	blib/lib/stefans_libs/database/hybInfoDB.pm \
	lib/stefans_libs/database/array_TStat.pm \
	blib/lib/stefans_libs/database/array_TStat.pm \
	lib/stefans_libs/array_analysis/correlatingData.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_BdIt-2.1.6.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_BdIt-2.1.6.ttf \
	lib/stefans_libs/database/experiment/partizipatingSubjects.pm \
	blib/lib/stefans_libs/database/experiment/partizipatingSubjects.pm \
	lib/stefans_libs/array_analysis/Rbridge.pm \
	blib/lib/stefans_libs/array_analysis/Rbridge.pm \
	lib/stefans_libs/statistics/HMM/marcowChain.pm \
	blib/lib/stefans_libs/statistics/HMM/marcowChain.pm \
	lib/stefans_libs/array_analysis/outputFormater/dataRep.pm \
	blib/lib/stefans_libs/array_analysis/outputFormater/dataRep.pm \
	lib/stefans_libs/array_analysis/correlatingData/KruskalWallisTest.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/KruskalWallisTest.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm \
	blib/lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm \
	lib/stefans_libs/database/expression_estimate/expr_est_list.pm \
	blib/lib/stefans_libs/database/expression_estimate/expr_est_list.pm \
	lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotype.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotype.pm \
	lib/stefans_libs/database/genomeDB/gene_description/gene_aliases.pm \
	blib/lib/stefans_libs/database/genomeDB/gene_description/gene_aliases.pm \
	lib/stefans_libs/Latex_Document/Chapter.pm \
	blib/lib/stefans_libs/Latex_Document/Chapter.pm \
	lib/stefans_libs/sequence_modification/blastLine.pm \
	blib/lib/stefans_libs/sequence_modification/blastLine.pm \
	lib/stefans_libs/database/subjectTable/phenotype/binary_multi.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/binary_multi.pm \
	lib/stefans_libs/database/expression_net/expression_net_data.pm \
	blib/lib/stefans_libs/database/expression_net/expression_net_data.pm \
	lib/stefans_libs/database/dataset_registration.pm \
	blib/lib/stefans_libs/database/dataset_registration.pm \
	lib/stefans_libs/database/Affymetrix_expression_lib.pm \
	blib/lib/stefans_libs/database/Affymetrix_expression_lib.pm \
	lib/stefans_libs/array_analysis/dataRep/hapMap_phase.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/hapMap_phase.pm \
	lib/stefans_libs/V_segment_summaryBlot/oligoBinReport.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/oligoBinReport.pm \
	lib/Statistics/R/Bridge.pm \
	blib/lib/Statistics/R/Bridge.pm \
	lib/stefans_libs/array_analysis/correlatingData/SpearmanTest.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/SpearmanTest.pm \
	lib/stefans_libs/doc/fastaFile.html \
	blib/lib/stefans_libs/doc/fastaFile.html \
	lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotypeList.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotypeList.pm \
	lib/stefans_libs/doc/NimbleGene_config.html \
	blib/lib/stefans_libs/doc/NimbleGene_config.html \
	lib/stefans_libs/file_readers/plink/ped_file.pm \
	blib/lib/stefans_libs/file_readers/plink/ped_file.pm \
	lib/stefans_libs/database/storage_table.pm \
	blib/lib/stefans_libs/database/storage_table.pm \
	lib/stefans_libs/database/nucleotide_array/oligoDB.pm \
	blib/lib/stefans_libs/database/nucleotide_array/oligoDB.pm \
	lib/stefans_libs/database/WGAS/SNP_calls.pm \
	blib/lib/stefans_libs/database/WGAS/SNP_calls.pm \
	lib/stefans_libs/database/external_files.pm \
	blib/lib/stefans_libs/database/external_files.pm \
	lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm \
	blib/lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm \
	lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm \
	blib/lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm \
	lib/stefans_libs/database/system_tables/thread_helper.pm \
	blib/lib/stefans_libs/database/system_tables/thread_helper.pm \
	lib/stefans_libs/tableHandling.pm \
	blib/lib/stefans_libs/tableHandling.pm \
	lib/stefans_libs/doc/sequence_modification/blastResult.html \
	blib/lib/stefans_libs/doc/sequence_modification/blastResult.html \
	lib/stefans_libs/database/scientistTable/action_groups.pm \
	blib/lib/stefans_libs/database/scientistTable/action_groups.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter.pm \
	blib/lib/stefans_libs/database/genomeDB/genomeImporter.pm \
	lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm \
	lib/stefans_libs/database/DeepSeq/genes.pm \
	blib/lib/stefans_libs/database/DeepSeq/genes.pm \
	lib/stefans_libs/doc/nimbleGeneFiles/pairFile.html \
	blib/lib/stefans_libs/doc/nimbleGeneFiles/pairFile.html \
	lib/stefans_libs/singleLinePlotHMM.pm \
	blib/lib/stefans_libs/singleLinePlotHMM.pm \
	lib/stefans_libs/database/external_files/file_list.pm \
	blib/lib/stefans_libs/database/external_files/file_list.pm \
	lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm \
	lib/stefans_libs/database/sequenome_data/sequenome_assays.pm \
	blib/lib/stefans_libs/database/sequenome_data/sequenome_assays.pm \
	lib/stefans_libs/histogram_container.pm \
	blib/lib/stefans_libs/histogram_container.pm \
	lib/Statistics/R/Bridge/Win32.pm \
	blib/lib/Statistics/R/Bridge/Win32.pm \
	lib/Statistics/R.pm \
	blib/lib/Statistics/R.pm \
	lib/stefans_libs/database/sampleTable/sample_types.pm \
	blib/lib/stefans_libs/database/sampleTable/sample_types.pm \
	delete.pl \
	$(INST_LIB)/delete.pl \
	lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm \
	blib/lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm \
	lib/stefans_libs/statistics/HMM/logHistogram.pm \
	blib/lib/stefans_libs/statistics/HMM/logHistogram.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm \
	blib/lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm \
	lib/stefans_libs/file_readers/affymerix_snp_description.pm \
	blib/lib/stefans_libs/file_readers/affymerix_snp_description.pm \
	lib/stefans_libs/database/system_tables/LinkList/object_list.pm \
	blib/lib/stefans_libs/database/system_tables/LinkList/object_list.pm \
	lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm \
	lib/stefans_libs/doc/chromosome_ripper/seq_contig.html \
	blib/lib/stefans_libs/doc/chromosome_ripper/seq_contig.html \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm \
	lib/stefans_libs/sequence_modification/ssake_info.pm \
	blib/lib/stefans_libs/sequence_modification/ssake_info.pm \
	lib/stefans_libs/database/LabBook.pm \
	blib/lib/stefans_libs/database/LabBook.pm \
	lib/stefans_libs/database/scientistTable.pm \
	blib/lib/stefans_libs/database/scientistTable.pm \
	lib/stefans_libs/database/PubMed_queries.pm \
	blib/lib/stefans_libs/database/PubMed_queries.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis.pm \
	lib/stefans_libs/doc/sequence_modification/imgtFile.html \
	blib/lib/stefans_libs/doc/sequence_modification/imgtFile.html \
	lib/stefans_libs/nimbleGeneFiles/gffFile.pm \
	blib/lib/stefans_libs/nimbleGeneFiles/gffFile.pm \
	lib/stefans_libs/XY_Evaluation.pm \
	blib/lib/stefans_libs/XY_Evaluation.pm \
	lib/stefans_libs/statistics/HMM/probabilityFunction.pm \
	blib/lib/stefans_libs/statistics/HMM/probabilityFunction.pm \
	lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm \
	blib/lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm \
	lib/stefans_libs/database/pathways/kegg/kegg_pathway.pm \
	blib/lib/stefans_libs/database/pathways/kegg/kegg_pathway.pm \
	lib/stefans_libs/file_readers/affymerix_snp_data.pm \
	blib/lib/stefans_libs/file_readers/affymerix_snp_data.pm \
	lib/stefans_libs/doc/database/hybInfoDB.html \
	blib/lib/stefans_libs/doc/database/hybInfoDB.html \
	lib/stefans_libs/database/publications/Authors.pm \
	blib/lib/stefans_libs/database/publications/Authors.pm \
	lib/stefans_libs/database/wish_list.pm \
	blib/lib/stefans_libs/database/wish_list.pm \
	lib/stefans_libs/plot/dimensionTest.pl \
	blib/lib/stefans_libs/plot/dimensionTest.pl \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/enrichedRegions.pm \
	blib/lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/enrichedRegions.pm \
	lib/stefans_libs/doc/database/cellTypeDB.html \
	blib/lib/stefans_libs/doc/database/cellTypeDB.html \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.ttf \
	lib/stefans_libs/multiLinePlot/multilineXY_axis.pm \
	blib/lib/stefans_libs/multiLinePlot/multilineXY_axis.pm \
	lib/stefans_libs/database/antibodyDB.pm \
	blib/lib/stefans_libs/database/antibodyDB.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis_with_NuclPos.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis_with_NuclPos.pm \
	lib/stefans_libs/sequence_modification/deepSeq_region.pm \
	blib/lib/stefans_libs/sequence_modification/deepSeq_region.pm \
	lib/stefans_libs/database/sequenome_data.pm \
	blib/lib/stefans_libs/database/sequenome_data.pm \
	lib/stefans_libs/array_analysis/correlatingData/stat_test.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/stat_test.pm \
	lib/stefans_libs/database/system_tables/errorTable.pm \
	blib/lib/stefans_libs/database/system_tables/errorTable.pm \
	lib/stefans_libs/database/genomeDB/chromosomesTable.pm \
	blib/lib/stefans_libs/database/genomeDB/chromosomesTable.pm \
	lib/stefans_libs/doc/pod2htmd.tmp \
	blib/lib/stefans_libs/doc/pod2htmd.tmp \
	lib/stefans_libs/database/experiment.pm \
	blib/lib/stefans_libs/database/experiment.pm \
	lib/stefans_libs/multiLinePlot/multiline_gb_Axis.pm \
	blib/lib/stefans_libs/multiLinePlot/multiline_gb_Axis.pm \
	lib/stefans_libs/database/pathways/kegg/kegg_genes.pm \
	blib/lib/stefans_libs/database/pathways/kegg/kegg_genes.pm \
	lib/stefans_libs/histogram.pm \
	blib/lib/stefans_libs/histogram.pm \
	lib/stefans_libs/doc/gbFile/gbRegion.html \
	blib/lib/stefans_libs/doc/gbFile/gbRegion.html \
	lib/stefans_libs/exec_helper/XML_handler.pm \
	blib/lib/stefans_libs/exec_helper/XML_handler.pm \
	lib/stefans_libs/database/LabBook/LabBook_instance.pm \
	blib/lib/stefans_libs/database/LabBook/LabBook_instance.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm \
	lib/stefans_libs/file_readers/plink.pm \
	blib/lib/stefans_libs/file_readers/plink.pm \
	lib/stefans_libs/database/sampleTable.pm \
	blib/lib/stefans_libs/database/sampleTable.pm \
	lib/stefans_libs/database/project_table.pm \
	blib/lib/stefans_libs/database/project_table.pm \
	lib/stefans_libs/Latex_Document.pm \
	blib/lib/stefans_libs/Latex_Document.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf \
	lib/stefans_libs/normalize/quantilNormalization.pm \
	blib/lib/stefans_libs/normalize/quantilNormalization.pm \
	lib/stefans_libs/database/publications/PubMed_list.pm \
	blib/lib/stefans_libs/database/publications/PubMed_list.pm \
	lib/stefans_libs/database/system_tables/LinkList.pm \
	blib/lib/stefans_libs/database/system_tables/LinkList.pm \
	lib/stefans_libs/database/array_dataset.pm \
	blib/lib/stefans_libs/database/array_dataset.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/test.pl \
	blib/lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/test.pl \
	lib/stefans_libs/doc/sequence_modification/primer.html \
	blib/lib/stefans_libs/doc/sequence_modification/primer.html \
	lib/stefans_libs/database/system_tables/passwords.pm \
	blib/lib/stefans_libs/database/system_tables/passwords.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.ttf \
	lib/stefans_libs/doc/sequence_modification/primerList.html \
	blib/lib/stefans_libs/doc/sequence_modification/primerList.html \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine-2.1.9.dfont \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine-2.1.9.dfont \
	lib/stefans_libs/plot/multi_axis.pm \
	blib/lib/stefans_libs/plot/multi_axis.pm \
	lib/stefans_libs/binaryEvaluation/VbinaryEvauation.pm \
	blib/lib/stefans_libs/binaryEvaluation/VbinaryEvauation.pm \
	lib/stefans_libs/array_analysis/group3D_MatrixEntries.pm \
	blib/lib/stefans_libs/array_analysis/group3D_MatrixEntries.pm \
	lib/stefans_libs/file_readers/sequenome/resultsFile.pm \
	blib/lib/stefans_libs/file_readers/sequenome/resultsFile.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm \
	blib/lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm \
	blib/lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm \
	lib/stefans_libs/statistics/GetCategoryOfTI.pl \
	blib/lib/stefans_libs/statistics/GetCategoryOfTI.pl \
	lib/stefans_libs/database/experimentTypes.pm \
	blib/lib/stefans_libs/database/experimentTypes.pm \
	lib/stefans_libs/fonts/LinLibertineFont/ChangeLog.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/ChangeLog.txt \
	lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm \
	blib/lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm \
	lib/stefans_libs/doc/chromosome_ripper/gbFileMerger.html \
	blib/lib/stefans_libs/doc/chromosome_ripper/gbFileMerger.html \
	lib/stefans_libs/doc/database/oligo2dnaDB.html \
	blib/lib/stefans_libs/doc/database/oligo2dnaDB.html \
	lib/stefans_libs/doc/database/designDB.html \
	blib/lib/stefans_libs/doc/database/designDB.html \
	lib/stefans_libs/chromosome_ripper/seq_contig.pm \
	blib/lib/stefans_libs/chromosome_ripper/seq_contig.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LaTex/LibertineInConTeXt.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LaTex/LibertineInConTeXt.txt \
	lib/stefans_libs/file_readers/MeDIP_results.pm \
	blib/lib/stefans_libs/file_readers/MeDIP_results.pm \
	lib/stefans_libs/database/tissueTable.pm \
	blib/lib/stefans_libs/database/tissueTable.pm \
	lib/stefans_libs/database/dataset.sql \
	blib/lib/stefans_libs/database/dataset.sql \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_Bd-2.1.6.dfont \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_Bd-2.1.6.dfont \
	lib/stefans_libs/database/lists/list_using_table.pm \
	blib/lib/stefans_libs/database/lists/list_using_table.pm \
	lib/stefans_libs/plot/xy_graph_withHistograms.pm \
	blib/lib/stefans_libs/plot/xy_graph_withHistograms.pm \
	lib/stefans_libs/doc/gbFile/gbFeature.html \
	blib/lib/stefans_libs/doc/gbFile/gbFeature.html \
	lib/stefans_libs/database/variable_table/linkage_info.pm \
	blib/lib/stefans_libs/database/variable_table/linkage_info.pm \
	lib/stefans_libs/array_analysis/correlatingData/chi_square.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/chi_square.pm \
	lib/stefans_libs/evaluation/tableLine.pm \
	blib/lib/stefans_libs/evaluation/tableLine.pm \
	lib/stefans_libs/doc/sequence_modification/imgtFeature.html \
	blib/lib/stefans_libs/doc/sequence_modification/imgtFeature.html \
	lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot/alleleFreq.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot/alleleFreq.pm \
	lib/stefans_libs/file_readers/stat_results/Spearman_result.pm \
	blib/lib/stefans_libs/file_readers/stat_results/Spearman_result.pm \
	lib/stefans_libs/database/sampleTable/sample_list.pm \
	blib/lib/stefans_libs/database/sampleTable/sample_list.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm \
	blib/lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm \
	lib/stefans_libs/database/system_tables/loggingTable.pm \
	blib/lib/stefans_libs/database/system_tables/loggingTable.pm \
	lib/stefans_libs/database/genomeDB/SNP_table.pm \
	blib/lib/stefans_libs/database/genomeDB/SNP_table.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.otf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.otf \
	lib/stefans_libs/plot/figure.pm \
	blib/lib/stefans_libs/plot/figure.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm \
	blib/lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm \
	lib/stefans_libs/database/system_tables/roles.pm \
	blib/lib/stefans_libs/database/system_tables/roles.pm \
	lib/stefans_libs/SNP_2_Gene_Expression.pm \
	blib/lib/stefans_libs/SNP_2_Gene_Expression.pm \
	lib/stefans_libs/database/subjectTable/phenotype/continuose_mono.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/continuose_mono.pm \
	lib/stefans_libs/array_analysis/correlatingData/R_glm.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/R_glm.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_Bd-2.1.8.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_Bd-2.1.8.ttf \
	lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm \
	blib/lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm \
	lib/stefans_libs/doc/statistics/UMS.html \
	blib/lib/stefans_libs/doc/statistics/UMS.html \
	lib/stefans_libs/plot/color.pm \
	blib/lib/stefans_libs/plot/color.pm \
	lib/stefans_libs/statistics/statisticItem.pm \
	blib/lib/stefans_libs/statistics/statisticItem.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Readme \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Readme \
	lib/stefans_libs/array_analysis/dataRep/oligo2DNA_table.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/oligo2DNA_table.pm \
	lib/stefans_libs/WWW_Reader/pubmed_search.pm \
	blib/lib/stefans_libs/WWW_Reader/pubmed_search.pm \
	lib/stefans_libs/database/subjectTable/phenotype/binary_mono.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/binary_mono.pm \
	lib/stefans_libs/doc/gbFile.html \
	blib/lib/stefans_libs/doc/gbFile.html \
	lib/stefans_libs/database/genomeDB/gene_description/genes_of_importance.pm \
	blib/lib/stefans_libs/database/genomeDB/gene_description/genes_of_importance.pm \
	lib/stefans_libs/database/creaturesTable/familyTree.pm \
	blib/lib/stefans_libs/database/creaturesTable/familyTree.pm \
	lib/stefans_libs/sequence_modification/primerList.pm \
	blib/lib/stefans_libs/sequence_modification/primerList.pm \
	lib/stefans_libs/statistics/statisticItemList.pm \
	blib/lib/stefans_libs/statistics/statisticItemList.pm \
	lib/stefans_libs/fastaFile.pm \
	blib/lib/stefans_libs/fastaFile.pm \
	lib/stefans_libs/sequence_modification/primer.pm \
	blib/lib/stefans_libs/sequence_modification/primer.pm \
	lib/stefans_libs/statistics/HMM.pm \
	blib/lib/stefans_libs/statistics/HMM.pm \
	lib/stefans_libs/qantilTest.pl \
	blib/lib/stefans_libs/qantilTest.pl \
	lib/stefans_libs/file_readers/sequenome/resultFile/report.pm \
	blib/lib/stefans_libs/file_readers/sequenome/resultFile/report.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_R-2.1.0.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_R-2.1.0.ttf \
	lib/stefans_libs/database/DeepSeq/lib_organizer/exons.pm \
	blib/lib/stefans_libs/database/DeepSeq/lib_organizer/exons.pm \
	lib/stefans_libs/doc/sequence_modification/imgtFeatureDB.html \
	blib/lib/stefans_libs/doc/sequence_modification/imgtFeatureDB.html \
	lib/stefans_libs/database/cellTypeDB.pm \
	blib/lib/stefans_libs/database/cellTypeDB.pm \
	lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm \
	blib/lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm \
	lib/stefans_libs/file_readers/PPI_text_file.pm \
	blib/lib/stefans_libs/file_readers/PPI_text_file.pm \
	lib/stefans_libs/binaryEvaluation/VbinElement.pm \
	blib/lib/stefans_libs/binaryEvaluation/VbinElement.pm \
	lib/stefans_libs/r_Birdge/testR.pl \
	blib/lib/stefans_libs/r_Birdge/testR.pl \
	lib/stefans_libs/database/publications/Journals.pm \
	blib/lib/stefans_libs/database/publications/Journals.pm \
	lib/stefans_libs/plot/gbAxis.pm \
	blib/lib/stefans_libs/plot/gbAxis.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH-2.1.8.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH-2.1.8.ttf \
	lib/stefans_libs/V_segment_summaryBlot/SubPlot_element.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/SubPlot_element.pm \
	lib/stefans_libs/doc/designImporter.html \
	blib/lib/stefans_libs/doc/designImporter.html \
	lib/stefans_libs/database/WGAS.pm \
	blib/lib/stefans_libs/database/WGAS.pm \
	lib/stefans_libs/database/sequenome_data/sequenome_chips.pm \
	blib/lib/stefans_libs/database/sequenome_data/sequenome_chips.pm \
	lib/stefans_libs/doc/statistics/MAplot.html \
	blib/lib/stefans_libs/doc/statistics/MAplot.html \
	lib/stefans_libs/database/sequenome_data/sequenome_quality.pm \
	blib/lib/stefans_libs/database/sequenome_data/sequenome_quality.pm \
	lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm \
	blib/lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm \
	lib/stefans_libs/database/subjectTable.pm \
	blib/lib/stefans_libs/database/subjectTable.pm \
	lib/stefans_libs/nimbleGeneFiles/pairFile.pm \
	blib/lib/stefans_libs/nimbleGeneFiles/pairFile.pm \
	lib/stefans_libs/database/oligo2dna_register.pm \
	blib/lib/stefans_libs/database/oligo2dna_register.pm \
	lib/stefans_libs/database/materials/materialList.pm \
	blib/lib/stefans_libs/database/materials/materialList.pm \
	lib/stefans_libs/database/expression_net.pm \
	blib/lib/stefans_libs/database/expression_net.pm \
	lib/stefans_libs/doc/evaluation/summaryLine.html \
	blib/lib/stefans_libs/doc/evaluation/summaryLine.html \
	lib/stefans_libs/database/system_tables/jobTable.pm \
	blib/lib/stefans_libs/database/system_tables/jobTable.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm \
	blib/lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm \
	lib/stefans_libs/database/system_tables/executable_table.pm \
	blib/lib/stefans_libs/database/system_tables/executable_table.pm \
	lib/stefans_libs/doc/evaluation/GBpict.html \
	blib/lib/stefans_libs/doc/evaluation/GBpict.html \
	lib/stefans_libs/gbFile.pm \
	blib/lib/stefans_libs/gbFile.pm \
	lib/stefans_libs/plot/simpleXYgraph.pm \
	blib/lib/stefans_libs/plot/simpleXYgraph.pm \
	lib/stefans_libs/V_segment_summaryBlot/NEW_GFF_data_Y_axis.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/NEW_GFF_data_Y_axis.pm \
	lib/stefans_libs/database/creaturesTable.pm \
	blib/lib/stefans_libs/database/creaturesTable.pm \
	lib/stefans_libs/statistics/new_histogram.pm \
	blib/lib/stefans_libs/statistics/new_histogram.pm \
	lib/stefans_libs/database/array_dataset/oligo_array_values.pm \
	blib/lib/stefans_libs/database/array_dataset/oligo_array_values.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription.pm \
	blib/lib/stefans_libs/file_readers/CoExpressionDescription.pm \
	lib/stefans_libs/database/genomeDB/genomeSearchResult.pm \
	blib/lib/stefans_libs/database/genomeDB/genomeSearchResult.pm \
	lib/stefans_libs/plot/legendPlot.pm \
	blib/lib/stefans_libs/plot/legendPlot.pm \
	lib/stefans_libs/plot/axis.pm \
	blib/lib/stefans_libs/plot/axis.pm \
	lib/stefans_libs/singleLinePlot.pm \
	blib/lib/stefans_libs/singleLinePlot.pm \
	lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm \
	blib/lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm \
	blib/lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm \
	lib/stefans_libs/graphical_Nucleosom_density/nuclDataRow.pm \
	blib/lib/stefans_libs/graphical_Nucleosom_density/nuclDataRow.pm \
	lib/stefans_libs/database/system_tables/PluginRegister.pm \
	blib/lib/stefans_libs/database/system_tables/PluginRegister.pm \
	lib/stefans_libs/sequence_modification/blastResult.pm \
	blib/lib/stefans_libs/sequence_modification/blastResult.pm \
	lib/stefans_libs/multiLinePlot/multiLineLable.pm \
	blib/lib/stefans_libs/multiLinePlot/multiLineLable.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_It-2.1.6.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_It-2.1.6.ttf \
	lib/stefans_libs/statistics/HMM/UMS.pm \
	blib/lib/stefans_libs/statistics/HMM/UMS.pm \
	lib/stefans_libs/plot.pm \
	blib/lib/stefans_libs/plot.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm \
	blib/lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm \
	lib/stefans_libs/database/variable_table/queryInterface.pm \
	blib/lib/stefans_libs/database/variable_table/queryInterface.pm \
	lib/stefans_libs/database/variable_table.pm \
	blib/lib/stefans_libs/database/variable_table.pm \
	lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm \
	blib/lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm \
	lib/stefans_libs/importHyb.pm \
	blib/lib/stefans_libs/importHyb.pm \
	lib/stefans_libs/doc/statistics/statisticItemList.html \
	blib/lib/stefans_libs/doc/statistics/statisticItemList.html \
	lib/stefans_libs/file_readers/plink/bim_file.pm \
	blib/lib/stefans_libs/file_readers/plink/bim_file.pm \
	lib/stefans_libs/database/scientistTable/action_group_list.pm \
	blib/lib/stefans_libs/database/scientistTable/action_group_list.pm \
	lib/stefans_libs/plot/simpleWhiskerPlot.pm \
	blib/lib/stefans_libs/plot/simpleWhiskerPlot.pm \
	lib/stefans_libs/database/lists/basic_list.pm \
	blib/lib/stefans_libs/database/lists/basic_list.pm \
	lib/stefans_libs/sequence_modification/imgtFile.pm \
	blib/lib/stefans_libs/sequence_modification/imgtFile.pm \
	lib/stefans_libs/normlize/normalizeGFFvalues.pm \
	blib/lib/stefans_libs/normlize/normalizeGFFvalues.pm \
	lib/stefans_libs/statistics/HMM/UMS_EnrichmentFactors.pm \
	blib/lib/stefans_libs/statistics/HMM/UMS_EnrichmentFactors.pm \
	lib/stefans_libs/database/genomeDB/gbFilesTable.pm \
	blib/lib/stefans_libs/database/genomeDB/gbFilesTable.pm \
	lib/stefans_libs/database/scientistTable/roles.pm \
	blib/lib/stefans_libs/database/scientistTable/roles.pm \
	lib/stefans_libs/statistics/HMM/state_values.pm \
	blib/lib/stefans_libs/statistics/HMM/state_values.pm \
	lib/stefans_libs/fastaDB.pm \
	blib/lib/stefans_libs/fastaDB.pm \
	lib/stefans_libs/database/scientistTable/scientificComunity.pm \
	blib/lib/stefans_libs/database/scientistTable/scientificComunity.pm \
	lib/stefans_libs/statistics/HMM/UMS_old.pm \
	blib/lib/stefans_libs/statistics/HMM/UMS_old.pm \
	lib/stefans_libs/V_segment_summaryBlot/hmmReportEntry.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/hmmReportEntry.pm \
	lib/stefans_libs/doc/nimbleGeneFiles/gffFile.html \
	blib/lib/stefans_libs/doc/nimbleGeneFiles/gffFile.html \
	lib/stefans_libs/sequence_modification/imgtFeatureDB.pm \
	blib/lib/stefans_libs/sequence_modification/imgtFeatureDB.pm \
	lib/stefans_libs/statistics/newGFFtoSignalMap.pm \
	blib/lib/stefans_libs/statistics/newGFFtoSignalMap.pm \
	lib/stefans_libs/doc/evaluation/evaluateHMM_data.html \
	blib/lib/stefans_libs/doc/evaluation/evaluateHMM_data.html \
	lib/stefans_libs/NimbleGene_config.pm \
	blib/lib/stefans_libs/NimbleGene_config.pm \
	lib/stefans_libs/Latex_Document/gene_description.pm \
	blib/lib/stefans_libs/Latex_Document/gene_description.pm \
	lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm \
	blib/lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm \
	lib/stefans_libs/statistics/gnuplotParser.pm \
	blib/lib/stefans_libs/statistics/gnuplotParser.pm \
	lib/stefans_libs/doc/database/antibodyDB.html \
	blib/lib/stefans_libs/doc/database/antibodyDB.html \
	lib/stefans_libs/doc/sequence_modification/inverseBlastHit.html \
	blib/lib/stefans_libs/doc/sequence_modification/inverseBlastHit.html \
	lib/stefans_libs/array_analysis/correlatingData/Wilcox_Test.pm \
	blib/lib/stefans_libs/array_analysis/correlatingData/Wilcox_Test.pm \
	lib/stefans_libs/db_report/plottable_gbFile.pm \
	blib/lib/stefans_libs/db_report/plottable_gbFile.pm \
	lib/stefans_libs/database/publications/PubMed.pm \
	blib/lib/stefans_libs/database/publications/PubMed.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm \
	lib/stefans_libs/database/designDB.pm \
	blib/lib/stefans_libs/database/designDB.pm \
	lib/stefans_libs/evaluation/evaluateHMM_data.pm \
	blib/lib/stefans_libs/evaluation/evaluateHMM_data.pm \
	lib/stefans_libs/plot/simpleBarGraph.pm \
	blib/lib/stefans_libs/plot/simpleBarGraph.pm \
	lib/stefans_libs/database/expression_estimate/expr_est.pm \
	blib/lib/stefans_libs/database/expression_estimate/expr_est.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/rs_dataset.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/rs_dataset.pm \
	lib/stefans_libs/doc/database/array_TStat.html \
	blib/lib/stefans_libs/doc/database/array_TStat.html \
	lib/stefans_libs/database/system_tables/PluginRegister/exportables.pm \
	blib/lib/stefans_libs/database/system_tables/PluginRegister/exportables.pm \
	lib/stefans_libs/doc/importHyb.html \
	blib/lib/stefans_libs/doc/importHyb.html \
	lib/stefans_libs/database/pathways/kegg/hypergeometric_max_hits.pm \
	blib/lib/stefans_libs/database/pathways/kegg/hypergeometric_max_hits.pm \
	lib/stefans_libs/gbFile/gbHeader.pm \
	blib/lib/stefans_libs/gbFile/gbHeader.pm \
	lib/stefans_libs/database/genomeDB.pm \
	blib/lib/stefans_libs/database/genomeDB.pm \
	lib/stefans_libs/doc/evaluation/tableLine.html \
	blib/lib/stefans_libs/doc/evaluation/tableLine.html \
	lib/stefans_libs/file_readers/stat_results.pm \
	blib/lib/stefans_libs/file_readers/stat_results.pm \
	lib/stefans_libs/doc/gbFile/gbHeader.html \
	blib/lib/stefans_libs/doc/gbFile/gbHeader.html \
	lib/stefans_libs/database/scientistTable/PW_table.pm \
	blib/lib/stefans_libs/database/scientistTable/PW_table.pm \
	lib/stefans_libs/sequence_modification/deepSeq_blastLine.pm \
	blib/lib/stefans_libs/sequence_modification/deepSeq_blastLine.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Mac/README-MAC.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/README-MAC.txt \
	lib/stefans_libs/fonts/LinLibertineFont/Gehintet/README-hinted \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/README-hinted \
	lib/stefans_libs/array_analysis/outputFormater/sortOrderTest.pl \
	blib/lib/stefans_libs/array_analysis/outputFormater/sortOrderTest.pl \
	lib/stefans_libs/database/subjectTable/phenotype/continuose_multi.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/continuose_multi.pm \
	lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm \
	blib/lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm \
	lib/stefans_libs/axis_template.txt \
	blib/lib/stefans_libs/axis_template.txt \
	lib/stefans_libs/database/system_tables/workingTable.pm \
	blib/lib/stefans_libs/database/system_tables/workingTable.pm \
	lib/stefans_libs/database/DeepSeq/genes/gene_names.pm \
	blib/lib/stefans_libs/database/DeepSeq/genes/gene_names.pm \
	lib/stefans_libs/multiLinePlot/simple_multiline_gb_Axis.pm \
	blib/lib/stefans_libs/multiLinePlot/simple_multiline_gb_Axis.pm \
	lib/stefans_libs/database.pm \
	blib/lib/stefans_libs/database.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer.pm \
	blib/lib/stefans_libs/database/DeepSeq/lib_organizer.pm \
	lib/stefans_libs/sequence_modification/imgtFeature.pm \
	blib/lib/stefans_libs/sequence_modification/imgtFeature.pm \
	lib/stefans_libs/Latex_Document/Figure.pm \
	blib/lib/stefans_libs/Latex_Document/Figure.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LICENCE.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LICENCE.txt \
	lib/stefans_libs/designImporter.pm \
	blib/lib/stefans_libs/designImporter.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.otf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.otf \
	lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm \
	blib/lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm \
	lib/stefans_libs/doc/histogram.html \
	blib/lib/stefans_libs/doc/histogram.html \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/SNP_cluster.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/SNP_cluster.pm \
	lib/stefans_libs/doc/statistics/statisticItem.html \
	blib/lib/stefans_libs/doc/statistics/statisticItem.html \
	lib/stefans_libs/database/array_Hyb.pm \
	blib/lib/stefans_libs/database/array_Hyb.pm \
	lib/stefans_libs/flexible_data_structures/data_table.pm \
	blib/lib/stefans_libs/flexible_data_structures/data_table.pm \
	lib/stefans_libs/database/WGAS/rsID_2_SNP.pm \
	blib/lib/stefans_libs/database/WGAS/rsID_2_SNP.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LaTex/README-TEX.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LaTex/README-TEX.txt \
	lib/stefans_libs/database/genomeDB/db_xref_table.pm \
	blib/lib/stefans_libs/database/genomeDB/db_xref_table.pm \
	lib/stefans_libs/plot/plottable_gbFile.pm \
	blib/lib/stefans_libs/plot/plottable_gbFile.pm \
	lib/stefans_libs/array_analysis/outputFormater/XY_withHistograms.pm \
	blib/lib/stefans_libs/array_analysis/outputFormater/XY_withHistograms.pm \
	lib/stefans_libs/file_readers/phenotypes.pm \
	blib/lib/stefans_libs/file_readers/phenotypes.pm \
	lib/stefans_libs/statistics/HMM_EnrichmentFactors.pm \
	blib/lib/stefans_libs/statistics/HMM_EnrichmentFactors.pm \
	lib/stefans_libs/database/hypothesis_table.pm \
	blib/lib/stefans_libs/database/hypothesis_table.pm \
	lib/stefans_libs/array_analysis/tableHandling.pm \
	blib/lib/stefans_libs/array_analysis/tableHandling.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_Bd-2.1.0.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_Bd-2.1.0.ttf \
	lib/stefans_libs/file_readers/affymetrix_expression_result.pm \
	blib/lib/stefans_libs/file_readers/affymetrix_expression_result.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.otf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.otf \
	lib/stefans_libs/MyProject/PHASE_outfile.pm \
	blib/lib/stefans_libs/MyProject/PHASE_outfile.pm \
	lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm \
	lib/stefans_libs/Latex_Document/Text.pm \
	blib/lib/stefans_libs/Latex_Document/Text.pm \
	lib/stefans_libs/database/materials/materialsTable.pm \
	blib/lib/stefans_libs/database/materials/materialsTable.pm \
	lib/stefans_libs/sequence_modification/inverseBlastHit.pm \
	blib/lib/stefans_libs/sequence_modification/inverseBlastHit.pm \
	lib/Statistics/R/Bridge/Linux.pm \
	blib/lib/Statistics/R/Bridge/Linux.pm \
	lib/stefans_libs/normalize/normalizeGFFvalues.pm \
	blib/lib/stefans_libs/normalize/normalizeGFFvalues.pm \
	lib/stefans_libs/database/genomeDB/ROI_table.pm \
	blib/lib/stefans_libs/database/genomeDB/ROI_table.pm \
	lib/stefans_libs/multiLinePlot/multiline_HMM_Axis.pm \
	blib/lib/stefans_libs/multiLinePlot/multiline_HMM_Axis.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm \
	blib/lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm \
	lib/stefans_libs/database/Protein_Expression/gene_ids.pm \
	blib/lib/stefans_libs/database/Protein_Expression/gene_ids.pm \
	lib/stefans_libs/multiLinePlot.pm \
	blib/lib/stefans_libs/multiLinePlot.pm \
	lib/stefans_libs/sequence_modification/imgt2gb.pm \
	blib/lib/stefans_libs/sequence_modification/imgt2gb.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot.pm \
	blib/lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot.pm \
	lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm \
	blib/lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm \
	lib/stefans_libs/multiLinePlot/XYvalues.pm \
	blib/lib/stefans_libs/multiLinePlot/XYvalues.pm \
	lib/stefans_libs/database/subjectTable/phenotype/familyHistory.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/familyHistory.pm \
	lib/stefans_libs/doc/database/array_Hyb.html \
	blib/lib/stefans_libs/doc/database/array_Hyb.html \
	lib/stefans_libs/database/experiment/hypothesis.pm \
	blib/lib/stefans_libs/database/experiment/hypothesis.pm \
	lib/stefans_libs/database/expression_estimate/probesets_table.pm \
	blib/lib/stefans_libs/database/expression_estimate/probesets_table.pm \
	lib/stefans_libs/evaluation/probTest.pl \
	blib/lib/stefans_libs/evaluation/probTest.pl \
	lib/stefans_libs/V_segment_summaryBlot/NEW_Summary_GFF_Y_axis.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/NEW_Summary_GFF_Y_axis.pm \
	lib/stefans_libs/file_readers/stat_results/base_class.pm \
	blib/lib/stefans_libs/file_readers/stat_results/base_class.pm \
	lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm \
	lib/stefans_libs/database/to_do_list.pm \
	blib/lib/stefans_libs/database/to_do_list.pm \
	lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm \
	blib/lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm \
	lib/stefans_libs/file_readers/UCSC_ens_Gene.pm \
	blib/lib/stefans_libs/file_readers/UCSC_ens_Gene.pm \
	lib/stefans_libs/statistics/HMM/marcowModel.pm \
	blib/lib/stefans_libs/statistics/HMM/marcowModel.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm \
	blib/lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/.dat.oligoIDs.dat \
	blib/lib/stefans_libs/.dat.oligoIDs.dat \
	plot_differences_4_gene_SNP_comparisons.pl \
	$(INST_LIB)/plot_differences_4_gene_SNP_comparisons.pl \
	lib/stefans_libs/testBins/xy_test.pl \
	blib/lib/stefans_libs/testBins/xy_test.pl \
	lib/stefans_libs/file_readers/svg_pathway_description.pm \
	blib/lib/stefans_libs/file_readers/svg_pathway_description.pm \
	lib/stefans_libs/doc/statistics/HMM.html \
	blib/lib/stefans_libs/doc/statistics/HMM.html \
	lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm \
	blib/lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm \
	lib/stefans_libs/file_readers/expression_net_reader.pm \
	blib/lib/stefans_libs/file_readers/expression_net_reader.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm \
	blib/lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm \
	lib/stefans_libs/database/nucleotide_array.pm \
	blib/lib/stefans_libs/database/nucleotide_array.pm \
	lib/stefans_libs/doc/sequence_modification/blastLine.html \
	blib/lib/stefans_libs/doc/sequence_modification/blastLine.html \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.ttf \
	lib/stefans_libs/database/organismDB.pm \
	blib/lib/stefans_libs/database/organismDB.pm \
	lib/stefans_libs/plot/Font.pm \
	blib/lib/stefans_libs/plot/Font.pm \
	lib/stefans_libs/fonts/LinLibertineFont/Bugs \
	blib/lib/stefans_libs/fonts/LinLibertineFont/Bugs \
	lib/stefans_libs/doc/pod2htmi.tmp \
	blib/lib/stefans_libs/doc/pod2htmi.tmp \
	lib/stefans_libs/database/fulfilledTask.pm \
	blib/lib/stefans_libs/database/fulfilledTask.pm \
	lib/stefans_libs/database/script.sql \
	blib/lib/stefans_libs/database/script.sql \
	lib/stefans_libs/database/ROI_registration.pm \
	blib/lib/stefans_libs/database/ROI_registration.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.ttf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.ttf \
	lib/stefans_libs/multiLinePlot/ruler_x_axis.pm \
	blib/lib/stefans_libs/multiLinePlot/ruler_x_axis.pm \
	lib/stefans_libs/V_segment_summaryBlot.pm \
	blib/lib/stefans_libs/V_segment_summaryBlot.pm \
	lib/stefans_libs/database/subjectTable/phenotype/ph_age.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype/ph_age.pm \
	lib/stefans_libs/statistics/MAplot.pm \
	blib/lib/stefans_libs/statistics/MAplot.pm \
	lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm \
	blib/lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm \
	lib/stefans_libs/testBins/Testplot.pl \
	blib/lib/stefans_libs/testBins/Testplot.pl \
	lib/stefans_libs/doc/createHTMP_help.pl \
	blib/lib/stefans_libs/doc/createHTMP_help.pl \
	lib/stefans_libs/fonts/LinLibertineFont-2.3.2.tgz \
	blib/lib/stefans_libs/fonts/LinLibertineFont-2.3.2.tgz \
	lib/stefans_libs/plot/densityMap.pm \
	blib/lib/stefans_libs/plot/densityMap.pm \
	lib/stefans_libs/database/oligo2dnaDB.pm \
	blib/lib/stefans_libs/database/oligo2dnaDB.pm \
	lib/stefans_libs/WebSearch/Googel_Search.pm \
	blib/lib/stefans_libs/WebSearch/Googel_Search.pm \
	lib/stefans_libs/database/array_calculation_results.pm \
	blib/lib/stefans_libs/database/array_calculation_results.pm \
	lib/stefans_libs/.dat \
	blib/lib/stefans_libs/.dat \
	lib/stefans_libs/database/grant_table.pm \
	blib/lib/stefans_libs/database/grant_table.pm \
	lib/stefans_libs/array_analysis/regression_models/linear_regression.pm \
	blib/lib/stefans_libs/array_analysis/regression_models/linear_regression.pm \
	lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.otf \
	blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.otf \
	lib/stefans_libs/array_analysis/template4deepEvaluation.pm \
	blib/lib/stefans_libs/array_analysis/template4deepEvaluation.pm \
	lib/stefans_libs/sequence_modification/testInversBlastHit.pl \
	blib/lib/stefans_libs/sequence_modification/testInversBlastHit.pl \
	lib/stefans_libs/fonts/LinLibertineFont/GPL.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/GPL.txt \
	lib/stefans_libs/doc/database/array_GFF.html \
	blib/lib/stefans_libs/doc/database/array_GFF.html \
	lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm \
	blib/lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm \
	lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm \
	blib/lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm \
	lib/stefans_libs/fonts/LinLibertineFont/OFL.txt \
	blib/lib/stefans_libs/fonts/LinLibertineFont/OFL.txt \
	lib/stefans_libs/nimbleGeneFiles/ndfFile.pm \
	blib/lib/stefans_libs/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/database/system_tables/LinkList/www_object_table.pm \
	blib/lib/stefans_libs/database/system_tables/LinkList/www_object_table.pm \
	lib/stefans_libs/evaluation/summaryLine.pm \
	blib/lib/stefans_libs/evaluation/summaryLine.pm \
	lib/stefans_libs/database/system_tables/configuration.pm \
	blib/lib/stefans_libs/database/system_tables/configuration.pm \
	lib/stefans_libs/database/expression_estimate/Affy_description.pm \
	blib/lib/stefans_libs/database/expression_estimate/Affy_description.pm \
	lib/stefans_libs/database/subjectTable/phenotype_registration.pm \
	blib/lib/stefans_libs/database/subjectTable/phenotype_registration.pm \
	lib/stefans_libs/graphical_Nucleosom_density/nucleotidePositioningData.pm \
	blib/lib/stefans_libs/graphical_Nucleosom_density/nucleotidePositioningData.pm \
	lib/stefans_libs/doc/sequence_modification/imgt2gb.html \
	blib/lib/stefans_libs/doc/sequence_modification/imgt2gb.html \
	lib/stefans_libs/doc/nimbleGeneFiles/ndfFile.html \
	blib/lib/stefans_libs/doc/nimbleGeneFiles/ndfFile.html \
	lib/stefans_libs/doc/root.html \
	blib/lib/stefans_libs/doc/root.html \
	lib/stefans_libs/database/array_dataset/genotype_calls.pm \
	blib/lib/stefans_libs/database/array_dataset/genotype_calls.pm \
	lib/stefans_libs/database/expression_estimate.pm \
	blib/lib/stefans_libs/database/expression_estimate.pm \
	lib/stefans_libs/sequence_modification/deepSequencingRegion.pm \
	blib/lib/stefans_libs/sequence_modification/deepSequencingRegion.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 6.55_02
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = stefans_libs
DISTVNAME = stefans_libs-1.00


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	bin/database_scripts/insert_phenotype_table.pl \
	bin/database_scripts/insert_into_dbTable_array_dataset.pl \
	bin/maintainance_scripts/match_nucleotideArray_to_genome.pl \
	bin/array_analysis/affy_csv_to_tsv.pl \
	bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl \
	bin/array_analysis/tab_table_reformater.pl \
	bin/maintainance_scripts/bib_create.pl \
	bin/database_scripts/batch_insert_phenotypes.pl \
	bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl \
	bin/maintainance_scripts/mege_two_tabSeparated_files.pl \
	bin/small_helpers/create_database_importScript.pl \
	bin/maintainance_scripts/old_bibCreate.pl \
	bin/maintainance_scripts/get_NCBI_genome.pl \
	bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl \
	bin/maintainance_scripts/compare_two_files.pl \
	bin/maintainance_scripts/calculateNucleosomePositionings.pl \
	bin/maintainance_scripts/binCreate.pl \
	bin/array_analysis/expressionList_toBarGraphs.pl \
	bin/array_analysis/add_2_phenotype_table.pl \
	bin/maintainance_scripts/open_query_interface.pl \
	bin/array_analysis/describe_SNPs.pl \
	bin/array_analysis/parse_PPI_data.pl \
	bin/database_scripts/getFeatureNames_in_chromosomal_region.pl \
	bin/array_analysis/convert_Jasmina_2_phenotype.pl \
	bin/small_helpers/create_hashes_from_mysql_create.pl \
	bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl \
	bin/array_analysis/remove_heterozygot_SNPs.pl \
	bin/maintainance_scripts/makeSenseOfLists.pl \
	bin/maintainance_scripts/add_configuartion.pl \
	bin/database_scripts/extract_gbFile_fromDB.pl \
	bin/small_helpers/create_exec_2_add_2_table.pl \
	bin/array_analysis/simpleXYplot.pl \
	bin/database_scripts/create_phenotype_definition.pl \
	bin/array_analysis/test_for_T2D_predictive_value.pl \
	bin/array_analysis/convert_database_dump_to_phase_input.pl \
	bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl \
	bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl \
	bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl \
	bin/small_helpers/create_generic_db_script.pl \
	bin/array_analysis/meanExpressionList_toBarGraphs.pl \
	bin/array_analysis/sum_up_Batch_results.pl \
	bin/maintainance_scripts/add_nimbleGene_NDF_file.pl \
	bin/small_helpers/get_XML_helper_dataset_definition.pl \
	bin/array_analysis/calculateMean_std_over_genes.pl \
	bin/array_analysis/identify_groups_in_PPI_results.pl \
	bin/small_helpers/check_database_classes.pl \
	bin/array_analysis/merge2tab_separated_files.pl \
	bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl \
	bin/array_analysis/Check_4_Coexpression.pl \
	bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl \
	bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl \
	bin/array_analysis/remove_variable_influence_from_expression_array.pl \
	bin/database_scripts/create_Genexpress_Plugin.pl \
	bin/array_analysis/download_affymetrix_files.pl \
	bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl \
	bin/array_analysis/make_histogram.pl \
	bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl \
	bin/array_analysis/get_location_for_gene_list.pl \
	bin/array_analysis/get_GeneDescription_from_GeneCards.pl \
	lib/stefans_libs/database/genomeDB/gene_description.pm \
	lib/stefans_libs/database/creaturesTable/familyTree.pm \
	lib/Statistics/R/Bridge/pipe.pm \
	lib/stefans_libs/gbFile/gbFeature.pm \
	lib/stefans_libs/database/LabBook/figure_table.pm \
	lib/stefans_libs/fastaFile.pm \
	lib/stefans_libs/statistics/HMM.pm \
	lib/stefans_libs/database/LabBook/ChapterStructure.pm \
	lib/stefans_libs/database/dataset_registaration/dataset_list.pm \
	lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm \
	lib/stefans_libs/database/cellTypeDB.pm \
	lib/stefans_libs/file_readers/PPI_text_file.pm \
	lib/stefans_libs/database/WGAS.pm \
	lib/stefans_libs/array_analysis/correlatingData/qValues.pm \
	lib/stefans_libs/Latex_Document/Section.pm \
	lib/stefans_libs/plot/Chromosomes_plot.pm \
	lib/stefans_libs/database/fileDB.pm \
	lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm \
	lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm \
	lib/stefans_libs/V_segment_summaryBlot/dataRow.pm \
	lib/stefans_libs/database/subjectTable.pm \
	lib/stefans_libs/file_readers/MDsum_output.pm \
	lib/stefans_libs/nimbleGeneFiles/pairFile.pm \
	lib/stefans_libs/database/materials/materialList.pm \
	lib/stefans_libs/database/oligo2dna_register.pm \
	lib/stefans_libs/database/system_tables/jobTable.pm \
	lib/stefans_libs/database/system_tables/executable_table.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm \
	lib/stefans_libs/gbFile.pm \
	lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm \
	lib/stefans_libs/database/array_GFF.pm \
	lib/stefans_libs/database/creaturesTable.pm \
	lib/stefans_libs/statistics/new_histogram.pm \
	lib/stefans_libs/database/array_dataset/oligo_array_values.pm \
	lib/stefans_libs/file_readers/CoExpressionDescription.pm \
	lib/stefans_libs/database/Protein_Expression.pm \
	lib/stefans_libs/database/genomeDB/genomeSearchResult.pm \
	lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm \
	lib/stefans_libs/root.pm \
	lib/stefans_libs/database/protocol_table.pm \
	lib/stefans_libs/plot/axis.pm \
	lib/stefans_libs/database/experimentTypes/type_to_plugin.pm \
	lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm \
	lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm \
	lib/stefans_libs/gbFile/gbRegion.pm \
	lib/stefans_libs/chromosome_ripper/gbFileMerger.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm \
	lib/stefans_libs/sequence_modification/blastResult.pm \
	lib/stefans_libs/multiLinePlot/multiLineLable.pm \
	lib/stefans_libs/database/publications/Authors_list.pm \
	lib/stefans_libs/database/variable_table/queryInterface.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm \
	lib/stefans_libs/statistics/HMM/UMS.pm \
	lib/stefans_libs/database/hybInfoDB.pm \
	lib/stefans_libs/database/array_TStat.pm \
	lib/stefans_libs/array_analysis/correlatingData.pm \
	lib/stefans_libs/database/variable_table.pm \
	lib/stefans_libs/database/experiment/partizipatingSubjects.pm \
	lib/stefans_libs/statistics/HMM/marcowChain.pm \
	lib/stefans_libs/array_analysis/outputFormater/dataRep.pm \
	lib/stefans_libs/importHyb.pm \
	lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm \
	lib/stefans_libs/database/expression_estimate/expr_est_list.pm \
	lib/stefans_libs/Latex_Document/Chapter.pm \
	lib/stefans_libs/database/dataset_registration.pm \
	lib/stefans_libs/file_readers/plink/bim_file.pm \
	lib/stefans_libs/plot/simpleWhiskerPlot.pm \
	lib/Statistics/R/Bridge.pm \
	lib/stefans_libs/normlize/normalizeGFFvalues.pm \
	lib/stefans_libs/database/genomeDB/gbFilesTable.pm \
	lib/stefans_libs/database/storage_table.pm \
	lib/stefans_libs/file_readers/plink/ped_file.pm \
	lib/stefans_libs/statistics/HMM/state_values.pm \
	lib/stefans_libs/fastaDB.pm \
	lib/stefans_libs/database/scientistTable/scientificComunity.pm \
	lib/stefans_libs/database/nucleotide_array/oligoDB.pm \
	lib/stefans_libs/database/external_files.pm \
	lib/stefans_libs/database/WGAS/SNP_calls.pm \
	lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm \
	lib/stefans_libs/tableHandling.pm \
	lib/stefans_libs/database/system_tables/thread_helper.pm \
	lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter.pm \
	lib/stefans_libs/Latex_Document/gene_description.pm \
	lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm \
	lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm \
	lib/stefans_libs/database/DeepSeq/genes.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm \
	lib/stefans_libs/database/external_files/file_list.pm \
	lib/stefans_libs/database/designDB.pm \
	lib/stefans_libs/evaluation/evaluateHMM_data.pm \
	lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm \
	lib/stefans_libs/database/genomeDB.pm \
	lib/Statistics/R/Bridge/Win32.pm \
	lib/Statistics/R.pm \
	lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm \
	lib/stefans_libs/file_readers/stat_results.pm \
	lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm \
	lib/stefans_libs/file_readers/affymerix_snp_description.pm \
	lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm \
	lib/stefans_libs/database/system_tables/LinkList/object_list.pm \
	lib/stefans_libs/database/system_tables/workingTable.pm \
	lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm \
	lib/stefans_libs/database.pm \
	lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm \
	lib/stefans_libs/database/LabBook.pm \
	lib/stefans_libs/Latex_Document/Figure.pm \
	lib/stefans_libs/database/scientistTable.pm \
	lib/stefans_libs/designImporter.pm \
	lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm \
	lib/stefans_libs/nimbleGeneFiles/gffFile.pm \
	lib/stefans_libs/database/array_Hyb.pm \
	lib/stefans_libs/flexible_data_structures/data_table.pm \
	lib/stefans_libs/database/WGAS/rsID_2_SNP.pm \
	lib/stefans_libs/XY_Evaluation.pm \
	lib/stefans_libs/statistics/HMM/probabilityFunction.pm \
	lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm \
	lib/stefans_libs/plot/plottable_gbFile.pm \
	lib/stefans_libs/file_readers/affymerix_snp_data.pm \
	lib/stefans_libs/file_readers/phenotypes.pm \
	lib/stefans_libs/database/hypothesis_table.pm \
	lib/stefans_libs/array_analysis/tableHandling.pm \
	lib/stefans_libs/file_readers/affymetrix_expression_result.pm \
	lib/stefans_libs/database/antibodyDB.pm \
	lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm \
	lib/stefans_libs/MyProject/PHASE_outfile.pm \
	lib/stefans_libs/Latex_Document/Text.pm \
	lib/stefans_libs/database/materials/materialsTable.pm \
	lib/Statistics/R/Bridge/Linux.pm \
	lib/stefans_libs/normalize/normalizeGFFvalues.pm \
	lib/stefans_libs/database/genomeDB/ROI_table.pm \
	lib/stefans_libs/database/system_tables/errorTable.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm \
	lib/stefans_libs/database/genomeDB/chromosomesTable.pm \
	lib/stefans_libs/multiLinePlot.pm \
	lib/stefans_libs/database/experiment.pm \
	lib/stefans_libs/histogram.pm \
	lib/stefans_libs/database/pathways/kegg/kegg_genes.pm \
	lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm \
	lib/stefans_libs/database/LabBook/LabBook_instance.pm \
	lib/stefans_libs/exec_helper/XML_handler.pm \
	lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm \
	lib/stefans_libs/database/project_table.pm \
	lib/stefans_libs/database/sampleTable.pm \
	lib/stefans_libs/file_readers/plink.pm \
	lib/stefans_libs/Latex_Document.pm \
	lib/stefans_libs/database/experiment/hypothesis.pm \
	lib/stefans_libs/database/publications/PubMed_list.pm \
	lib/stefans_libs/database/system_tables/LinkList.pm \
	lib/stefans_libs/database/expression_estimate/probesets_table.pm \
	lib/stefans_libs/file_readers/stat_results/base_class.pm \
	lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm \
	lib/stefans_libs/database/array_dataset.pm \
	lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm \
	lib/stefans_libs/file_readers/UCSC_ens_Gene.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm \
	plot_differences_4_gene_SNP_comparisons.pl \
	lib/stefans_libs/file_readers/svg_pathway_description.pm \
	lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm \
	lib/stefans_libs/file_readers/expression_net_reader.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm \
	lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm \
	lib/stefans_libs/file_readers/sequenome/resultsFile.pm \
	lib/stefans_libs/database/nucleotide_array.pm \
	lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm \
	lib/stefans_libs/database/organismDB.pm \
	lib/stefans_libs/database/experimentTypes.pm \
	lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm \
	lib/stefans_libs/chromosome_ripper/seq_contig.pm \
	lib/stefans_libs/file_readers/MeDIP_results.pm \
	lib/stefans_libs/database/fulfilledTask.pm \
	lib/stefans_libs/database/tissueTable.pm \
	lib/stefans_libs/database/lists/list_using_table.pm \
	lib/stefans_libs/V_segment_summaryBlot.pm \
	lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm \
	lib/stefans_libs/database/variable_table/linkage_info.pm \
	lib/stefans_libs/database/oligo2dnaDB.pm \
	lib/stefans_libs/WebSearch/Googel_Search.pm \
	lib/stefans_libs/array_analysis/correlatingData/chi_square.pm \
	lib/stefans_libs/database/array_calculation_results.pm \
	lib/stefans_libs/evaluation/tableLine.pm \
	lib/stefans_libs/database/grant_table.pm \
	lib/stefans_libs/array_analysis/regression_models/linear_regression.pm \
	lib/stefans_libs/file_readers/stat_results/Spearman_result.pm \
	lib/stefans_libs/database/system_tables/loggingTable.pm \
	lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm \
	lib/stefans_libs/database/sampleTable/sample_list.pm \
	lib/stefans_libs/database/genomeDB/SNP_table.pm \
	lib/stefans_libs/plot/figure.pm \
	lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm \
	lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm \
	lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm \
	lib/stefans_libs/nimbleGeneFiles/ndfFile.pm \
	lib/stefans_libs/SNP_2_Gene_Expression.pm \
	lib/stefans_libs/database/system_tables/configuration.pm \
	lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm \
	lib/stefans_libs/WWW_Reader/pubmed_search.pm \
	lib/stefans_libs/database/array_dataset/genotype_calls.pm \
	lib/stefans_libs/sequence_modification/deepSequencingRegion.pm
	$(NOECHO) $(POD2MAN) --section=$(MAN1EXT) --perm_rw=$(PERM_RW) \
	  bin/database_scripts/insert_phenotype_table.pl $(INST_MAN1DIR)/insert_phenotype_table.pl.$(MAN1EXT) \
	  bin/database_scripts/insert_into_dbTable_array_dataset.pl $(INST_MAN1DIR)/insert_into_dbTable_array_dataset.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/match_nucleotideArray_to_genome.pl $(INST_MAN1DIR)/match_nucleotideArray_to_genome.pl.$(MAN1EXT) \
	  bin/array_analysis/affy_csv_to_tsv.pl $(INST_MAN1DIR)/affy_csv_to_tsv.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl $(INST_MAN1DIR)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl.$(MAN1EXT) \
	  bin/array_analysis/tab_table_reformater.pl $(INST_MAN1DIR)/tab_table_reformater.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/bib_create.pl $(INST_MAN1DIR)/bib_create.pl.$(MAN1EXT) \
	  bin/database_scripts/batch_insert_phenotypes.pl $(INST_MAN1DIR)/batch_insert_phenotypes.pl.$(MAN1EXT) \
	  bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl $(INST_MAN1DIR)/plot_co_expression_incorporating_phenotype_corrections_results.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/mege_two_tabSeparated_files.pl $(INST_MAN1DIR)/mege_two_tabSeparated_files.pl.$(MAN1EXT) \
	  bin/small_helpers/create_database_importScript.pl $(INST_MAN1DIR)/create_database_importScript.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/old_bibCreate.pl $(INST_MAN1DIR)/old_bibCreate.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/get_NCBI_genome.pl $(INST_MAN1DIR)/get_NCBI_genome.pl.$(MAN1EXT) \
	  bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl $(INST_MAN1DIR)/reanalyse_co_expression_incorporating_phenotype_corrections.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/compare_two_files.pl $(INST_MAN1DIR)/compare_two_files.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/calculateNucleosomePositionings.pl $(INST_MAN1DIR)/calculateNucleosomePositionings.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/binCreate.pl $(INST_MAN1DIR)/binCreate.pl.$(MAN1EXT) \
	  bin/array_analysis/expressionList_toBarGraphs.pl $(INST_MAN1DIR)/expressionList_toBarGraphs.pl.$(MAN1EXT) \
	  bin/array_analysis/add_2_phenotype_table.pl $(INST_MAN1DIR)/add_2_phenotype_table.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/open_query_interface.pl $(INST_MAN1DIR)/open_query_interface.pl.$(MAN1EXT) \
	  bin/array_analysis/describe_SNPs.pl $(INST_MAN1DIR)/describe_SNPs.pl.$(MAN1EXT) \
	  bin/array_analysis/parse_PPI_data.pl $(INST_MAN1DIR)/parse_PPI_data.pl.$(MAN1EXT) \
	  bin/database_scripts/getFeatureNames_in_chromosomal_region.pl $(INST_MAN1DIR)/getFeatureNames_in_chromosomal_region.pl.$(MAN1EXT) \
	  bin/array_analysis/convert_Jasmina_2_phenotype.pl $(INST_MAN1DIR)/convert_Jasmina_2_phenotype.pl.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN1EXT) --perm_rw=$(PERM_RW) \
	  bin/small_helpers/create_hashes_from_mysql_create.pl $(INST_MAN1DIR)/create_hashes_from_mysql_create.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl $(INST_MAN1DIR)/create_a_data_table_based_file_interface_class.pl.$(MAN1EXT) \
	  bin/array_analysis/remove_heterozygot_SNPs.pl $(INST_MAN1DIR)/remove_heterozygot_SNPs.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/makeSenseOfLists.pl $(INST_MAN1DIR)/makeSenseOfLists.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/add_configuartion.pl $(INST_MAN1DIR)/add_configuartion.pl.$(MAN1EXT) \
	  bin/database_scripts/extract_gbFile_fromDB.pl $(INST_MAN1DIR)/extract_gbFile_fromDB.pl.$(MAN1EXT) \
	  bin/small_helpers/create_exec_2_add_2_table.pl $(INST_MAN1DIR)/create_exec_2_add_2_table.pl.$(MAN1EXT) \
	  bin/array_analysis/simpleXYplot.pl $(INST_MAN1DIR)/simpleXYplot.pl.$(MAN1EXT) \
	  bin/database_scripts/create_phenotype_definition.pl $(INST_MAN1DIR)/create_phenotype_definition.pl.$(MAN1EXT) \
	  bin/array_analysis/test_for_T2D_predictive_value.pl $(INST_MAN1DIR)/test_for_T2D_predictive_value.pl.$(MAN1EXT) \
	  bin/array_analysis/convert_database_dump_to_phase_input.pl $(INST_MAN1DIR)/convert_database_dump_to_phase_input.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl $(INST_MAN1DIR)/add_NCBI_SNP_chr_rpts_files.pl.$(MAN1EXT) \
	  bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl $(INST_MAN1DIR)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl $(INST_MAN1DIR)/get_closest_genes_for_rsIDs.pl.$(MAN1EXT) \
	  bin/small_helpers/create_generic_db_script.pl $(INST_MAN1DIR)/create_generic_db_script.pl.$(MAN1EXT) \
	  bin/array_analysis/meanExpressionList_toBarGraphs.pl $(INST_MAN1DIR)/meanExpressionList_toBarGraphs.pl.$(MAN1EXT) \
	  bin/array_analysis/sum_up_Batch_results.pl $(INST_MAN1DIR)/sum_up_Batch_results.pl.$(MAN1EXT) \
	  bin/maintainance_scripts/add_nimbleGene_NDF_file.pl $(INST_MAN1DIR)/add_nimbleGene_NDF_file.pl.$(MAN1EXT) \
	  bin/small_helpers/get_XML_helper_dataset_definition.pl $(INST_MAN1DIR)/get_XML_helper_dataset_definition.pl.$(MAN1EXT) \
	  bin/array_analysis/calculateMean_std_over_genes.pl $(INST_MAN1DIR)/calculateMean_std_over_genes.pl.$(MAN1EXT) \
	  bin/array_analysis/identify_groups_in_PPI_results.pl $(INST_MAN1DIR)/identify_groups_in_PPI_results.pl.$(MAN1EXT) \
	  bin/small_helpers/check_database_classes.pl $(INST_MAN1DIR)/check_database_classes.pl.$(MAN1EXT) \
	  bin/array_analysis/merge2tab_separated_files.pl $(INST_MAN1DIR)/merge2tab_separated_files.pl.$(MAN1EXT) \
	  bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl $(INST_MAN1DIR)/get_DAVID_Pathways_4_Gene_groups.pl.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN1EXT) --perm_rw=$(PERM_RW) \
	  bin/array_analysis/Check_4_Coexpression.pl $(INST_MAN1DIR)/Check_4_Coexpression.pl.$(MAN1EXT) \
	  bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl $(INST_MAN1DIR)/estimate_SNP_influence_on_expression_dataset.pl.$(MAN1EXT) \
	  bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl $(INST_MAN1DIR)/plot_Phenotype_to_phenotype_correlations.pl.$(MAN1EXT) \
	  bin/array_analysis/remove_variable_influence_from_expression_array.pl $(INST_MAN1DIR)/remove_variable_influence_from_expression_array.pl.$(MAN1EXT) \
	  bin/database_scripts/create_Genexpress_Plugin.pl $(INST_MAN1DIR)/create_Genexpress_Plugin.pl.$(MAN1EXT) \
	  bin/array_analysis/download_affymetrix_files.pl $(INST_MAN1DIR)/download_affymetrix_files.pl.$(MAN1EXT) \
	  bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl $(INST_MAN1DIR)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl.$(MAN1EXT) \
	  bin/array_analysis/make_histogram.pl $(INST_MAN1DIR)/make_histogram.pl.$(MAN1EXT) \
	  bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl $(INST_MAN1DIR)/compare_cis_SNPs_to_gene_expression.pl.$(MAN1EXT) \
	  bin/array_analysis/get_location_for_gene_list.pl $(INST_MAN1DIR)/get_location_for_gene_list.pl.$(MAN1EXT) \
	  bin/array_analysis/get_GeneDescription_from_GeneCards.pl $(INST_MAN1DIR)/get_GeneDescription_from_GeneCards.pl.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/database/genomeDB/gene_description.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::gene_description.$(MAN3EXT) \
	  lib/stefans_libs/database/creaturesTable/familyTree.pm $(INST_MAN3DIR)/stefans_libs::database::creaturesTable::familyTree.$(MAN3EXT) \
	  lib/Statistics/R/Bridge/pipe.pm $(INST_MAN3DIR)/Statistics::R::Bridge::pipe.$(MAN3EXT) \
	  lib/stefans_libs/gbFile/gbFeature.pm $(INST_MAN3DIR)/stefans_libs::gbFile::gbFeature.$(MAN3EXT) \
	  lib/stefans_libs/database/LabBook/figure_table.pm $(INST_MAN3DIR)/stefans_libs::database::LabBook::figure_table.$(MAN3EXT) \
	  lib/stefans_libs/fastaFile.pm $(INST_MAN3DIR)/stefans_libs::fastaFile.$(MAN3EXT) \
	  lib/stefans_libs/statistics/HMM.pm $(INST_MAN3DIR)/stefans_libs::statistics::HMM.$(MAN3EXT) \
	  lib/stefans_libs/database/LabBook/ChapterStructure.pm $(INST_MAN3DIR)/stefans_libs::database::LabBook::ChapterStructure.$(MAN3EXT) \
	  lib/stefans_libs/database/dataset_registaration/dataset_list.pm $(INST_MAN3DIR)/stefans_libs::database::dataset_registaration::dataset_list.$(MAN3EXT) \
	  lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm $(INST_MAN3DIR)/stefans_libs::database::nucleotide_array::oligo2dnaDB.$(MAN3EXT) \
	  lib/stefans_libs/database/cellTypeDB.pm $(INST_MAN3DIR)/stefans_libs::database::cellTypeDB.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/PPI_text_file.pm $(INST_MAN3DIR)/stefans_libs::file_readers::PPI_text_file.$(MAN3EXT) \
	  lib/stefans_libs/database/WGAS.pm $(INST_MAN3DIR)/stefans_libs::database::WGAS.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/correlatingData/qValues.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::correlatingData::qValues.$(MAN3EXT) \
	  lib/stefans_libs/Latex_Document/Section.pm $(INST_MAN3DIR)/stefans_libs::Latex_Document::Section.$(MAN3EXT) \
	  lib/stefans_libs/plot/Chromosomes_plot.pm $(INST_MAN3DIR)/stefans_libs::plot::Chromosomes_plot.$(MAN3EXT) \
	  lib/stefans_libs/database/fileDB.pm $(INST_MAN3DIR)/stefans_libs::database::fileDB.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::PluginRegister::exp_functions_list.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset::Affy_SNP_array::affy_cell_flatfile.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/dataRow.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::dataRow.$(MAN3EXT) \
	  lib/stefans_libs/database/subjectTable.pm $(INST_MAN3DIR)/stefans_libs::database::subjectTable.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/MDsum_output.pm $(INST_MAN3DIR)/stefans_libs::file_readers::MDsum_output.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/nimbleGeneFiles/pairFile.pm $(INST_MAN3DIR)/stefans_libs::nimbleGeneFiles::pairFile.$(MAN3EXT) \
	  lib/stefans_libs/database/materials/materialList.pm $(INST_MAN3DIR)/stefans_libs::database::materials::materialList.$(MAN3EXT) \
	  lib/stefans_libs/database/oligo2dna_register.pm $(INST_MAN3DIR)/stefans_libs::database::oligo2dna_register.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/jobTable.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::jobTable.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/executable_table.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::executable_table.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm $(INST_MAN3DIR)/stefans_libs::file_readers::CoExpressionDescription::KEGG_results.$(MAN3EXT) \
	  lib/stefans_libs/gbFile.pm $(INST_MAN3DIR)/stefans_libs::gbFile.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm $(INST_MAN3DIR)/stefans_libs::file_readers::SNP_2_gene_expression_reader.$(MAN3EXT) \
	  lib/stefans_libs/database/array_GFF.pm $(INST_MAN3DIR)/stefans_libs::database::array_GFF.$(MAN3EXT) \
	  lib/stefans_libs/database/creaturesTable.pm $(INST_MAN3DIR)/stefans_libs::database::creaturesTable.$(MAN3EXT) \
	  lib/stefans_libs/statistics/new_histogram.pm $(INST_MAN3DIR)/stefans_libs::statistics::new_histogram.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset/oligo_array_values.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset::oligo_array_values.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/CoExpressionDescription.pm $(INST_MAN3DIR)/stefans_libs::file_readers::CoExpressionDescription.$(MAN3EXT) \
	  lib/stefans_libs/database/Protein_Expression.pm $(INST_MAN3DIR)/stefans_libs::database::Protein_Expression.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/genomeSearchResult.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::genomeSearchResult.$(MAN3EXT) \
	  lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm $(INST_MAN3DIR)/stefans_libs::flexible_data_structures::data_table::arraySorter.$(MAN3EXT) \
	  lib/stefans_libs/root.pm $(INST_MAN3DIR)/stefans_libs::root.$(MAN3EXT) \
	  lib/stefans_libs/database/protocol_table.pm $(INST_MAN3DIR)/stefans_libs::database::protocol_table.$(MAN3EXT) \
	  lib/stefans_libs/plot/axis.pm $(INST_MAN3DIR)/stefans_libs::plot::axis.$(MAN3EXT) \
	  lib/stefans_libs/database/experimentTypes/type_to_plugin.pm $(INST_MAN3DIR)/stefans_libs::database::experimentTypes::type_to_plugin.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::outputFormater::arraySorter.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm $(INST_MAN3DIR)/stefans_libs::database::LabBook::figure_table::subfigure_list.$(MAN3EXT) \
	  lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm $(INST_MAN3DIR)/stefans_libs::database::LabBook::figure_table::subfigure_table.$(MAN3EXT) \
	  lib/stefans_libs/gbFile/gbRegion.pm $(INST_MAN3DIR)/stefans_libs::gbFile::gbRegion.$(MAN3EXT) \
	  lib/stefans_libs/chromosome_ripper/gbFileMerger.pm $(INST_MAN3DIR)/stefans_libs::chromosome_ripper::gbFileMerger.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm $(INST_MAN3DIR)/stefans_libs::MyProject::PHASE_outfile::LIST_SUMMARY.$(MAN3EXT) \
	  lib/stefans_libs/sequence_modification/blastResult.pm $(INST_MAN3DIR)/stefans_libs::sequence_modification::blastResult.$(MAN3EXT) \
	  lib/stefans_libs/multiLinePlot/multiLineLable.pm $(INST_MAN3DIR)/stefans_libs::multiLinePlot::multiLineLable.$(MAN3EXT) \
	  lib/stefans_libs/database/publications/Authors_list.pm $(INST_MAN3DIR)/stefans_libs::database::publications::Authors_list.$(MAN3EXT) \
	  lib/stefans_libs/database/variable_table/queryInterface.pm $(INST_MAN3DIR)/stefans_libs::database::variable_table::queryInterface.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::genomeImporter::seq_contig.$(MAN3EXT) \
	  lib/stefans_libs/statistics/HMM/UMS.pm $(INST_MAN3DIR)/stefans_libs::statistics::HMM::UMS.$(MAN3EXT) \
	  lib/stefans_libs/database/hybInfoDB.pm $(INST_MAN3DIR)/stefans_libs::database::hybInfoDB.$(MAN3EXT) \
	  lib/stefans_libs/database/array_TStat.pm $(INST_MAN3DIR)/stefans_libs::database::array_TStat.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/correlatingData.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::correlatingData.$(MAN3EXT) \
	  lib/stefans_libs/database/variable_table.pm $(INST_MAN3DIR)/stefans_libs::database::variable_table.$(MAN3EXT) \
	  lib/stefans_libs/database/experiment/partizipatingSubjects.pm $(INST_MAN3DIR)/stefans_libs::database::experiment::partizipatingSubjects.$(MAN3EXT) \
	  lib/stefans_libs/statistics/HMM/marcowChain.pm $(INST_MAN3DIR)/stefans_libs::statistics::HMM::marcowChain.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/outputFormater/dataRep.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::outputFormater::dataRep.$(MAN3EXT) \
	  lib/stefans_libs/importHyb.pm $(INST_MAN3DIR)/stefans_libs::importHyb.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm $(INST_MAN3DIR)/stefans_libs::MyProject::compare_SNP_2_Gene_expression_results.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/database/expression_estimate/expr_est_list.pm $(INST_MAN3DIR)/stefans_libs::database::expression_estimate::expr_est_list.$(MAN3EXT) \
	  lib/stefans_libs/Latex_Document/Chapter.pm $(INST_MAN3DIR)/stefans_libs::Latex_Document::Chapter.$(MAN3EXT) \
	  lib/stefans_libs/database/dataset_registration.pm $(INST_MAN3DIR)/stefans_libs::database::dataset_registration.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/plink/bim_file.pm $(INST_MAN3DIR)/stefans_libs::file_readers::plink::bim_file.$(MAN3EXT) \
	  lib/stefans_libs/plot/simpleWhiskerPlot.pm $(INST_MAN3DIR)/stefans_libs::plot::simpleWhiskerPlot.$(MAN3EXT) \
	  lib/Statistics/R/Bridge.pm $(INST_MAN3DIR)/Statistics::R::Bridge.$(MAN3EXT) \
	  lib/stefans_libs/normlize/normalizeGFFvalues.pm $(INST_MAN3DIR)/stefans_libs::normlize::normalizeGFFvalues.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/gbFilesTable.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::gbFilesTable.$(MAN3EXT) \
	  lib/stefans_libs/database/storage_table.pm $(INST_MAN3DIR)/stefans_libs::database::storage_table.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/plink/ped_file.pm $(INST_MAN3DIR)/stefans_libs::file_readers::plink::ped_file.$(MAN3EXT) \
	  lib/stefans_libs/statistics/HMM/state_values.pm $(INST_MAN3DIR)/stefans_libs::statistics::HMM::state_values.$(MAN3EXT) \
	  lib/stefans_libs/fastaDB.pm $(INST_MAN3DIR)/stefans_libs::fastaDB.$(MAN3EXT) \
	  lib/stefans_libs/database/scientistTable/scientificComunity.pm $(INST_MAN3DIR)/stefans_libs::database::scientistTable::scientificComunity.$(MAN3EXT) \
	  lib/stefans_libs/database/nucleotide_array/oligoDB.pm $(INST_MAN3DIR)/stefans_libs::database::nucleotide_array::oligoDB.$(MAN3EXT) \
	  lib/stefans_libs/database/external_files.pm $(INST_MAN3DIR)/stefans_libs::database::external_files.$(MAN3EXT) \
	  lib/stefans_libs/database/WGAS/SNP_calls.pm $(INST_MAN3DIR)/stefans_libs::database::WGAS::SNP_calls.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm $(INST_MAN3DIR)/stefans_libs::file_readers::stat_results::KruskalWallisTest_result.$(MAN3EXT) \
	  lib/stefans_libs/tableHandling.pm $(INST_MAN3DIR)/stefans_libs::tableHandling.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/thread_helper.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::thread_helper.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm $(INST_MAN3DIR)/stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/genomeImporter.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::genomeImporter.$(MAN3EXT) \
	  lib/stefans_libs/Latex_Document/gene_description.pm $(INST_MAN3DIR)/stefans_libs::Latex_Document::gene_description.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm $(INST_MAN3DIR)/stefans_libs::database::fulfilledTask::fulfilledTask_handler.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::oligoBin.$(MAN3EXT) \
	  lib/stefans_libs/database/DeepSeq/genes.pm $(INST_MAN3DIR)/stefans_libs::database::DeepSeq::genes.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::gbFeature_X_axis.$(MAN3EXT) \
	  lib/stefans_libs/database/external_files/file_list.pm $(INST_MAN3DIR)/stefans_libs::database::external_files::file_list.$(MAN3EXT) \
	  lib/stefans_libs/database/designDB.pm $(INST_MAN3DIR)/stefans_libs::database::designDB.$(MAN3EXT) \
	  lib/stefans_libs/evaluation/evaluateHMM_data.pm $(INST_MAN3DIR)/stefans_libs::evaluation::evaluateHMM_data.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::selected_regions_dataRow.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB.$(MAN3EXT) \
	  lib/Statistics/R/Bridge/Win32.pm $(INST_MAN3DIR)/Statistics::R::Bridge::Win32.$(MAN3EXT) \
	  lib/Statistics/R.pm $(INST_MAN3DIR)/Statistics::R.$(MAN3EXT) \
	  lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm $(INST_MAN3DIR)/stefans_libs::database::DeepSeq::genes::gene_names_list.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/stat_results.pm $(INST_MAN3DIR)/stefans_libs::file_readers::stat_results.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::genomeImporter::NCBI_genome_Readme.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/affymerix_snp_description.pm $(INST_MAN3DIR)/stefans_libs::file_readers::affymerix_snp_description.$(MAN3EXT) \
	  lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm $(INST_MAN3DIR)/stefans_libs::statistics::HMM::HMM_hypothesis.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/LinkList/object_list.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::LinkList::object_list.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/workingTable.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::workingTable.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::GFF_data_Y_axis.$(MAN3EXT) \
	  lib/stefans_libs/database.pm $(INST_MAN3DIR)/stefans_libs::database.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::gbFeature_X_axis::X_feature.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/database/LabBook.pm $(INST_MAN3DIR)/stefans_libs::database::LabBook.$(MAN3EXT) \
	  lib/stefans_libs/Latex_Document/Figure.pm $(INST_MAN3DIR)/stefans_libs::Latex_Document::Figure.$(MAN3EXT) \
	  lib/stefans_libs/database/scientistTable.pm $(INST_MAN3DIR)/stefans_libs::database::scientistTable.$(MAN3EXT) \
	  lib/stefans_libs/designImporter.pm $(INST_MAN3DIR)/stefans_libs::designImporter.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm $(INST_MAN3DIR)/stefans_libs::MyProject::ModelBasedGeneticAnalysis.$(MAN3EXT) \
	  lib/stefans_libs/nimbleGeneFiles/gffFile.pm $(INST_MAN3DIR)/stefans_libs::nimbleGeneFiles::gffFile.$(MAN3EXT) \
	  lib/stefans_libs/database/array_Hyb.pm $(INST_MAN3DIR)/stefans_libs::database::array_Hyb.$(MAN3EXT) \
	  lib/stefans_libs/flexible_data_structures/data_table.pm $(INST_MAN3DIR)/stefans_libs::flexible_data_structures::data_table.$(MAN3EXT) \
	  lib/stefans_libs/database/WGAS/rsID_2_SNP.pm $(INST_MAN3DIR)/stefans_libs::database::WGAS::rsID_2_SNP.$(MAN3EXT) \
	  lib/stefans_libs/XY_Evaluation.pm $(INST_MAN3DIR)/stefans_libs::XY_Evaluation.$(MAN3EXT) \
	  lib/stefans_libs/statistics/HMM/probabilityFunction.pm $(INST_MAN3DIR)/stefans_libs::statistics::HMM::probabilityFunction.$(MAN3EXT) \
	  lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm $(INST_MAN3DIR)/stefans_libs::database::variable_table::linkage_info::table_script_generator.$(MAN3EXT) \
	  lib/stefans_libs/plot/plottable_gbFile.pm $(INST_MAN3DIR)/stefans_libs::plot::plottable_gbFile.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/affymerix_snp_data.pm $(INST_MAN3DIR)/stefans_libs::file_readers::affymerix_snp_data.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/phenotypes.pm $(INST_MAN3DIR)/stefans_libs::file_readers::phenotypes.$(MAN3EXT) \
	  lib/stefans_libs/database/hypothesis_table.pm $(INST_MAN3DIR)/stefans_libs::database::hypothesis_table.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/tableHandling.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::tableHandling.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/affymetrix_expression_result.pm $(INST_MAN3DIR)/stefans_libs::file_readers::affymetrix_expression_result.$(MAN3EXT) \
	  lib/stefans_libs/database/antibodyDB.pm $(INST_MAN3DIR)/stefans_libs::database::antibodyDB.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/PHASE_outfile.pm $(INST_MAN3DIR)/stefans_libs::MyProject::PHASE_outfile.$(MAN3EXT) \
	  lib/stefans_libs/Latex_Document/Text.pm $(INST_MAN3DIR)/stefans_libs::Latex_Document::Text.$(MAN3EXT) \
	  lib/stefans_libs/database/materials/materialsTable.pm $(INST_MAN3DIR)/stefans_libs::database::materials::materialsTable.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/Statistics/R/Bridge/Linux.pm $(INST_MAN3DIR)/Statistics::R::Bridge::Linux.$(MAN3EXT) \
	  lib/stefans_libs/normalize/normalizeGFFvalues.pm $(INST_MAN3DIR)/stefans_libs::normalize::normalizeGFFvalues.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/ROI_table.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::ROI_table.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/errorTable.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::errorTable.$(MAN3EXT) \
	  lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm $(INST_MAN3DIR)/stefans_libs::database::DeepSeq::lib_organizer::splice_isoforms.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/chromosomesTable.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::chromosomesTable.$(MAN3EXT) \
	  lib/stefans_libs/multiLinePlot.pm $(INST_MAN3DIR)/stefans_libs::multiLinePlot.$(MAN3EXT) \
	  lib/stefans_libs/database/experiment.pm $(INST_MAN3DIR)/stefans_libs::database::experiment.$(MAN3EXT) \
	  lib/stefans_libs/histogram.pm $(INST_MAN3DIR)/stefans_libs::histogram.$(MAN3EXT) \
	  lib/stefans_libs/database/pathways/kegg/kegg_genes.pm $(INST_MAN3DIR)/stefans_libs::database::pathways::kegg::kegg_genes.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::nucleosomePositioning.$(MAN3EXT) \
	  lib/stefans_libs/database/LabBook/LabBook_instance.pm $(INST_MAN3DIR)/stefans_libs::database::LabBook::LabBook_instance.$(MAN3EXT) \
	  lib/stefans_libs/exec_helper/XML_handler.pm $(INST_MAN3DIR)/stefans_libs::exec_helper::XML_handler.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::dataRep::affy_geneotypeCalls.$(MAN3EXT) \
	  lib/stefans_libs/database/project_table.pm $(INST_MAN3DIR)/stefans_libs::database::project_table.$(MAN3EXT) \
	  lib/stefans_libs/database/sampleTable.pm $(INST_MAN3DIR)/stefans_libs::database::sampleTable.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/plink.pm $(INST_MAN3DIR)/stefans_libs::file_readers::plink.$(MAN3EXT) \
	  lib/stefans_libs/Latex_Document.pm $(INST_MAN3DIR)/stefans_libs::Latex_Document.$(MAN3EXT) \
	  lib/stefans_libs/database/experiment/hypothesis.pm $(INST_MAN3DIR)/stefans_libs::database::experiment::hypothesis.$(MAN3EXT) \
	  lib/stefans_libs/database/publications/PubMed_list.pm $(INST_MAN3DIR)/stefans_libs::database::publications::PubMed_list.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/LinkList.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::LinkList.$(MAN3EXT) \
	  lib/stefans_libs/database/expression_estimate/probesets_table.pm $(INST_MAN3DIR)/stefans_libs::database::expression_estimate::probesets_table.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/file_readers/stat_results/base_class.pm $(INST_MAN3DIR)/stefans_libs::file_readers::stat_results::base_class.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot::pictureLayout.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset.$(MAN3EXT) \
	  lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm $(INST_MAN3DIR)/stefans_libs::database::expression_estimate::CEL_file_storage.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/UCSC_ens_Gene.pm $(INST_MAN3DIR)/stefans_libs::file_readers::UCSC_ens_Gene.$(MAN3EXT) \
	  lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm $(INST_MAN3DIR)/stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile.$(MAN3EXT) \
	  plot_differences_4_gene_SNP_comparisons.pl $(INST_MAN3DIR)/plot_differences_4_gene_SNP_comparisons.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/svg_pathway_description.pm $(INST_MAN3DIR)/stefans_libs::file_readers::svg_pathway_description.$(MAN3EXT) \
	  lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm $(INST_MAN3DIR)/stefans_libs::database::nucleotide_array::Affymetrix_SNP_arrays::affy_SNP_info.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/expression_net_reader.pm $(INST_MAN3DIR)/stefans_libs::file_readers::expression_net_reader.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::pairFile.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/sequenome/resultsFile.pm $(INST_MAN3DIR)/stefans_libs::file_readers::sequenome::resultsFile.$(MAN3EXT) \
	  lib/stefans_libs/database/nucleotide_array.pm $(INST_MAN3DIR)/stefans_libs::database::nucleotide_array.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm $(INST_MAN3DIR)/stefans_libs::MyProject::PHASE_outfile::BESTPAIRS_SUMMARY.$(MAN3EXT) \
	  lib/stefans_libs/database/organismDB.pm $(INST_MAN3DIR)/stefans_libs::database::organismDB.$(MAN3EXT) \
	  lib/stefans_libs/database/experimentTypes.pm $(INST_MAN3DIR)/stefans_libs::database::experimentTypes.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm $(INST_MAN3DIR)/stefans_libs::MyProject::Allele_2_Phenotype_correlator.$(MAN3EXT) \
	  lib/stefans_libs/chromosome_ripper/seq_contig.pm $(INST_MAN3DIR)/stefans_libs::chromosome_ripper::seq_contig.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/file_readers/MeDIP_results.pm $(INST_MAN3DIR)/stefans_libs::file_readers::MeDIP_results.$(MAN3EXT) \
	  lib/stefans_libs/database/fulfilledTask.pm $(INST_MAN3DIR)/stefans_libs::database::fulfilledTask.$(MAN3EXT) \
	  lib/stefans_libs/database/tissueTable.pm $(INST_MAN3DIR)/stefans_libs::database::tissueTable.$(MAN3EXT) \
	  lib/stefans_libs/database/lists/list_using_table.pm $(INST_MAN3DIR)/stefans_libs::database::lists::list_using_table.$(MAN3EXT) \
	  lib/stefans_libs/V_segment_summaryBlot.pm $(INST_MAN3DIR)/stefans_libs::V_segment_summaryBlot.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::gbFeaturesTable.$(MAN3EXT) \
	  lib/stefans_libs/database/variable_table/linkage_info.pm $(INST_MAN3DIR)/stefans_libs::database::variable_table::linkage_info.$(MAN3EXT) \
	  lib/stefans_libs/database/oligo2dnaDB.pm $(INST_MAN3DIR)/stefans_libs::database::oligo2dnaDB.$(MAN3EXT) \
	  lib/stefans_libs/WebSearch/Googel_Search.pm $(INST_MAN3DIR)/stefans_libs::WebSearch::Googel_Search.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/correlatingData/chi_square.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::correlatingData::chi_square.$(MAN3EXT) \
	  lib/stefans_libs/database/array_calculation_results.pm $(INST_MAN3DIR)/stefans_libs::database::array_calculation_results.$(MAN3EXT) \
	  lib/stefans_libs/evaluation/tableLine.pm $(INST_MAN3DIR)/stefans_libs::evaluation::tableLine.$(MAN3EXT) \
	  lib/stefans_libs/database/grant_table.pm $(INST_MAN3DIR)/stefans_libs::database::grant_table.$(MAN3EXT) \
	  lib/stefans_libs/array_analysis/regression_models/linear_regression.pm $(INST_MAN3DIR)/stefans_libs::array_analysis::regression_models::linear_regression.$(MAN3EXT) \
	  lib/stefans_libs/file_readers/stat_results/Spearman_result.pm $(INST_MAN3DIR)/stefans_libs::file_readers::stat_results::Spearman_result.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/loggingTable.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::loggingTable.$(MAN3EXT) \
	  lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm $(INST_MAN3DIR)/stefans_libs::database::nucleotide_array::nimbleGeneArrays.$(MAN3EXT) \
	  lib/stefans_libs/database/sampleTable/sample_list.pm $(INST_MAN3DIR)/stefans_libs::database::sampleTable::sample_list.$(MAN3EXT) \
	  lib/stefans_libs/database/genomeDB/SNP_table.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::SNP_table.$(MAN3EXT) \
	  lib/stefans_libs/plot/figure.pm $(INST_MAN3DIR)/stefans_libs::plot::figure.$(MAN3EXT) \
	  lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm $(INST_MAN3DIR)/stefans_libs::MyProject::GeneticAnalysis::Model.$(MAN3EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm $(INST_MAN3DIR)/stefans_libs::database::genomeDB::genbank_flatfile_db.$(MAN3EXT) \
	  lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm $(INST_MAN3DIR)/stefans_libs::database::DeepSeq::lib_organizer::exon_list.$(MAN3EXT) \
	  lib/stefans_libs/nimbleGeneFiles/ndfFile.pm $(INST_MAN3DIR)/stefans_libs::nimbleGeneFiles::ndfFile.$(MAN3EXT) \
	  lib/stefans_libs/SNP_2_Gene_Expression.pm $(INST_MAN3DIR)/stefans_libs::SNP_2_Gene_Expression.$(MAN3EXT) \
	  lib/stefans_libs/database/system_tables/configuration.pm $(INST_MAN3DIR)/stefans_libs::database::system_tables::configuration.$(MAN3EXT) \
	  lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm $(INST_MAN3DIR)/stefans_libs::plot::Chromosomes_plot::chromosomal_histogram.$(MAN3EXT) \
	  lib/stefans_libs/WWW_Reader/pubmed_search.pm $(INST_MAN3DIR)/stefans_libs::WWW_Reader::pubmed_search.$(MAN3EXT) \
	  lib/stefans_libs/database/array_dataset/genotype_calls.pm $(INST_MAN3DIR)/stefans_libs::database::array_dataset::genotype_calls.$(MAN3EXT) \
	  lib/stefans_libs/sequence_modification/deepSequencingRegion.pm $(INST_MAN3DIR)/stefans_libs::sequence_modification::deepSequencingRegion.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = bin/text/add_cbust2gbFile.pl bin/text/addOligoInfos.pl bin/text/bibCreate.pl bin/text/ChromosomalRegions2SeqFiles.pl bin/text/compareIdentifiedEnrichedRegions.pl bin/text/convert2png.pl bin/text/convert4.pl bin/text/createNewDatabase.pl bin/text/createRegionList.pl bin/text/DensityPlots.pl bin/text/EraseFeature.pl bin/text/findBindingSiteInPromoterElements.pl bin/text/gbFile_Pictures.pl bin/text/GetNimbelGeneIDs.pl bin/text/getOligoValues4regions.pl bin/text/GFF_Calculator_median.pl bin/text/GFFfile2histogram.pl bin/text/HMM.pl bin/text/hmm_execute.pl bin/text/IdentifyMultiHitOligos.pl bin/text/identifyPossibleAmplificates.pl bin/text/importHyb.pl bin/text/KlammernTest.pl bin/text/MakeNormlizedGFF.pl bin/text/MAplot.pl bin/text/match_sorter.pl bin/text/mRNA_Plot.pl bin/text/ncbiBLAST_Wrap.pl bin/text/newTrim.pl bin/text/NimbleGeneNormalization_NoHypothesis.pl bin/text/old_V_segment_blot.pl bin/text/oligoEnrichmentFactorsForRegion.pl bin/text/QuantilNormalization.pl bin/text/Region_XY_Value_Table.pl bin/text/regionXY_plot.pl bin/text/tabellaricreport.pl bin/text/trimPictures.pl bin/text/UMS.pl bin/text/V_SegmentBlot.pl bin/text/V_segmentHMM_report.pl bin/text/XY_plot.pl bin/array_analysis/add_2_phenotype_table.pl bin/array_analysis/affy_csv_to_tsv.pl bin/array_analysis/arrayDataRestrictor.pl bin/array_analysis/batchStatistics.pl bin/array_analysis/calculateMean_std_over_genes.pl bin/array_analysis/change_endung.pl bin/array_analysis/Check_4_Coexpression.pl bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl bin/array_analysis/compareStatisticalResults.pl bin/array_analysis/convert_affy_cdf_to_DBtext.pl bin/array_analysis/convert_affy_cel_to_DBtext.pl bin/array_analysis/convert_database_dump_to_phase_input.pl bin/array_analysis/convert_Jasmina_2_phenotype.pl bin/array_analysis/createConnectionNet_4_expressionArrays.pl bin/array_analysis/createPhaseInputFile.pl bin/array_analysis/describe_SNPs.pl bin/array_analysis/download_affymetrix_files.pl bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl bin/array_analysis/expressionList_toBarGraphs.pl bin/array_analysis/extractSampleInfo_from_HTML.pl bin/array_analysis/findPutativeRegulativeElements.pl bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl bin/array_analysis/get_GeneDescription_from_GeneCards.pl bin/array_analysis/get_location_for_gene_list.pl bin/array_analysis/identify_groups_in_PPI_results.pl bin/array_analysis/identifyHaplotypes.pl bin/array_analysis/make_histogram.pl bin/array_analysis/meanExpressionList_toBarGraphs.pl bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl bin/array_analysis/merge2tab_separated_files.pl bin/array_analysis/parse_PPI_data.pl bin/array_analysis/pca_calculation.pl bin/array_analysis/plot_HistoneProbabilities_on_gbFile.pl bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl bin/array_analysis/printGenotypeList.pl bin/array_analysis/r_controler.pl bin/array_analysis/remove_heterozygot_SNPs.pl bin/array_analysis/remove_variable_influence_from_expression_array.pl bin/array_analysis/simpleXYplot.pl bin/array_analysis/sum_up_Batch_results.pl bin/array_analysis/tab_table_reformater.pl bin/array_analysis/test_for_T2D_predictive_value.pl bin/array_analysis/transpose.pl bin/maintainance_scripts/add_configuartion.pl bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl bin/maintainance_scripts/add_nimbleGene_NDF_file.pl bin/maintainance_scripts/bib_create.pl bin/maintainance_scripts/binCreate.pl bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl bin/maintainance_scripts/calculateNucleosomePositionings.pl bin/maintainance_scripts/changeLib_position.pl bin/maintainance_scripts/compare_two_files.pl bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl bin/maintainance_scripts/get_NCBI_genome.pl bin/maintainance_scripts/makeSenseOfLists.pl bin/maintainance_scripts/makeTest_4_lib.pl bin/maintainance_scripts/match_nucleotideArray_to_genome.pl bin/maintainance_scripts/mege_two_tabSeparated_files.pl bin/maintainance_scripts/old_bibCreate.pl bin/maintainance_scripts/open_query_interface.pl bin/small_helpers/check_database_classes.pl bin/small_helpers/create_database_importScript.pl bin/small_helpers/create_exec_2_add_2_table.pl bin/small_helpers/create_generic_db_script.pl bin/small_helpers/create_hashes_from_mysql_create.pl bin/small_helpers/get_XML_helper_dataset_definition.pl bin/small_helpers/make_in_paths.pl bin/small_helpers/txt_table_to_latex.pl bin/database_scripts/batch_insert_phenotypes.pl bin/database_scripts/create_Genexpress_Plugin.pl bin/database_scripts/create_phenotype_definition.pl bin/database_scripts/extract_gbFile_fromDB.pl bin/database_scripts/findBindingSite_in_genome.pl bin/database_scripts/getFeatureNames_in_chromosomal_region.pl bin/database_scripts/insert_into_dbTable_array_dataset.pl bin/database_scripts/insert_phenotype_table.pl bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl bin/database_scripts/trimPictures.pl

pure_all :: $(INST_SCRIPT)/match_nucleotideArray_to_genome.pl $(INST_SCRIPT)/affy_csv_to_tsv.pl $(INST_SCRIPT)/extractSampleInfo_from_HTML.pl $(INST_SCRIPT)/importHyb.pl $(INST_SCRIPT)/V_SegmentBlot.pl $(INST_SCRIPT)/mege_two_tabSeparated_files.pl $(INST_SCRIPT)/get_NCBI_genome.pl $(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl $(INST_SCRIPT)/compare_two_files.pl $(INST_SCRIPT)/expressionList_toBarGraphs.pl $(INST_SCRIPT)/trimPictures.pl $(INST_SCRIPT)/DensityPlots.pl $(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl $(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl $(INST_SCRIPT)/change_endung.pl $(INST_SCRIPT)/convert2png.pl $(INST_SCRIPT)/txt_table_to_latex.pl $(INST_SCRIPT)/makeSenseOfLists.pl $(INST_SCRIPT)/add_configuartion.pl $(INST_SCRIPT)/createNewDatabase.pl $(INST_SCRIPT)/extract_gbFile_fromDB.pl $(INST_SCRIPT)/test_for_T2D_predictive_value.pl $(INST_SCRIPT)/convert_database_dump_to_phase_input.pl $(INST_SCRIPT)/GFFfile2histogram.pl $(INST_SCRIPT)/pca_calculation.pl $(INST_SCRIPT)/trimPictures.pl $(INST_SCRIPT)/regionXY_plot.pl $(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl $(INST_SCRIPT)/printGenotypeList.pl $(INST_SCRIPT)/identifyHaplotypes.pl $(INST_SCRIPT)/IdentifyMultiHitOligos.pl $(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl $(INST_SCRIPT)/create_generic_db_script.pl $(INST_SCRIPT)/V_segmentHMM_report.pl $(INST_SCRIPT)/GetNimbelGeneIDs.pl $(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl $(INST_SCRIPT)/sum_up_Batch_results.pl $(INST_SCRIPT)/addOligoInfos.pl $(INST_SCRIPT)/calculateMean_std_over_genes.pl $(INST_SCRIPT)/arrayDataRestrictor.pl $(INST_SCRIPT)/check_database_classes.pl $(INST_SCRIPT)/merge2tab_separated_files.pl $(INST_SCRIPT)/tabellaricreport.pl $(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl $(INST_SCRIPT)/Check_4_Coexpression.pl $(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl $(INST_SCRIPT)/KlammernTest.pl $(INST_SCRIPT)/newTrim.pl $(INST_SCRIPT)/create_Genexpress_Plugin.pl $(INST_SCRIPT)/download_affymetrix_files.pl $(INST_SCRIPT)/gbFile_Pictures.pl $(INST_SCRIPT)/convert4.pl $(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl $(INST_SCRIPT)/changeLib_position.pl $(INST_SCRIPT)/insert_phenotype_table.pl $(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl $(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl $(INST_SCRIPT)/tab_table_reformater.pl $(INST_SCRIPT)/UMS.pl $(INST_SCRIPT)/EraseFeature.pl $(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl $(INST_SCRIPT)/bib_create.pl $(INST_SCRIPT)/batch_insert_phenotypes.pl $(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl $(INST_SCRIPT)/create_database_importScript.pl $(INST_SCRIPT)/old_bibCreate.pl $(INST_SCRIPT)/transpose.pl $(INST_SCRIPT)/hmm_execute.pl $(INST_SCRIPT)/calculateNucleosomePositionings.pl $(INST_SCRIPT)/binCreate.pl $(INST_SCRIPT)/add_2_phenotype_table.pl $(INST_SCRIPT)/open_query_interface.pl $(INST_SCRIPT)/describe_SNPs.pl $(INST_SCRIPT)/parse_PPI_data.pl $(INST_SCRIPT)/HMM.pl $(INST_SCRIPT)/add_cbust2gbFile.pl $(INST_SCRIPT)/identifyPossibleAmplificates.pl $(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl $(INST_SCRIPT)/create_hashes_from_mysql_create.pl $(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl $(INST_SCRIPT)/remove_heterozygot_SNPs.pl $(INST_SCRIPT)/MakeNormlizedGFF.pl $(INST_SCRIPT)/mRNA_Plot.pl $(INST_SCRIPT)/findBindingSiteInPromoterElements.pl $(INST_SCRIPT)/create_exec_2_add_2_table.pl $(INST_SCRIPT)/simpleXYplot.pl $(INST_SCRIPT)/create_phenotype_definition.pl $(INST_SCRIPT)/GFF_Calculator_median.pl $(INST_SCRIPT)/batchStatistics.pl $(INST_SCRIPT)/r_controler.pl $(INST_SCRIPT)/match_sorter.pl $(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl $(INST_SCRIPT)/ncbiBLAST_Wrap.pl $(INST_SCRIPT)/createPhaseInputFile.pl $(INST_SCRIPT)/Region_XY_Value_Table.pl $(INST_SCRIPT)/findBindingSite_in_genome.pl $(INST_SCRIPT)/findPutativeRegulativeElements.pl $(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl $(INST_SCRIPT)/add_nimbleGene_NDF_file.pl $(INST_SCRIPT)/XY_plot.pl $(INST_SCRIPT)/old_V_segment_blot.pl $(INST_SCRIPT)/get_XML_helper_dataset_definition.pl $(INST_SCRIPT)/createRegionList.pl $(INST_SCRIPT)/QuantilNormalization.pl $(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl $(INST_SCRIPT)/identify_groups_in_PPI_results.pl $(INST_SCRIPT)/MAplot.pl $(INST_SCRIPT)/bibCreate.pl $(INST_SCRIPT)/make_in_paths.pl $(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl $(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl $(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl $(INST_SCRIPT)/getOligoValues4regions.pl $(INST_SCRIPT)/make_histogram.pl $(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl $(INST_SCRIPT)/compareStatisticalResults.pl $(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl $(INST_SCRIPT)/makeTest_4_lib.pl $(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl $(INST_SCRIPT)/get_location_for_gene_list.pl $(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl $(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/match_nucleotideArray_to_genome.pl $(INST_SCRIPT)/affy_csv_to_tsv.pl \
	  $(INST_SCRIPT)/extractSampleInfo_from_HTML.pl $(INST_SCRIPT)/importHyb.pl \
	  $(INST_SCRIPT)/V_SegmentBlot.pl $(INST_SCRIPT)/mege_two_tabSeparated_files.pl \
	  $(INST_SCRIPT)/get_NCBI_genome.pl $(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl \
	  $(INST_SCRIPT)/compare_two_files.pl $(INST_SCRIPT)/expressionList_toBarGraphs.pl \
	  $(INST_SCRIPT)/trimPictures.pl $(INST_SCRIPT)/DensityPlots.pl \
	  $(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl $(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl \
	  $(INST_SCRIPT)/change_endung.pl $(INST_SCRIPT)/convert2png.pl \
	  $(INST_SCRIPT)/txt_table_to_latex.pl $(INST_SCRIPT)/makeSenseOfLists.pl \
	  $(INST_SCRIPT)/add_configuartion.pl $(INST_SCRIPT)/createNewDatabase.pl \
	  $(INST_SCRIPT)/extract_gbFile_fromDB.pl $(INST_SCRIPT)/test_for_T2D_predictive_value.pl \
	  $(INST_SCRIPT)/convert_database_dump_to_phase_input.pl $(INST_SCRIPT)/GFFfile2histogram.pl \
	  $(INST_SCRIPT)/pca_calculation.pl $(INST_SCRIPT)/trimPictures.pl \
	  $(INST_SCRIPT)/regionXY_plot.pl $(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl \
	  $(INST_SCRIPT)/printGenotypeList.pl $(INST_SCRIPT)/identifyHaplotypes.pl \
	  $(INST_SCRIPT)/IdentifyMultiHitOligos.pl $(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl \
	  $(INST_SCRIPT)/create_generic_db_script.pl $(INST_SCRIPT)/V_segmentHMM_report.pl \
	  $(INST_SCRIPT)/GetNimbelGeneIDs.pl $(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl \
	  $(INST_SCRIPT)/sum_up_Batch_results.pl $(INST_SCRIPT)/addOligoInfos.pl \
	  $(INST_SCRIPT)/calculateMean_std_over_genes.pl $(INST_SCRIPT)/arrayDataRestrictor.pl \
	  $(INST_SCRIPT)/check_database_classes.pl $(INST_SCRIPT)/merge2tab_separated_files.pl \
	  $(INST_SCRIPT)/tabellaricreport.pl $(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl \
	  $(INST_SCRIPT)/Check_4_Coexpression.pl $(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl \
	  $(INST_SCRIPT)/KlammernTest.pl $(INST_SCRIPT)/newTrim.pl \
	  $(INST_SCRIPT)/create_Genexpress_Plugin.pl $(INST_SCRIPT)/download_affymetrix_files.pl \
	  $(INST_SCRIPT)/gbFile_Pictures.pl $(INST_SCRIPT)/convert4.pl \
	  $(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl $(INST_SCRIPT)/changeLib_position.pl \
	  $(INST_SCRIPT)/insert_phenotype_table.pl $(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl \
	  $(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl $(INST_SCRIPT)/tab_table_reformater.pl \
	  $(INST_SCRIPT)/UMS.pl $(INST_SCRIPT)/EraseFeature.pl \
	  $(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl $(INST_SCRIPT)/bib_create.pl \
	  $(INST_SCRIPT)/batch_insert_phenotypes.pl $(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl \
	  $(INST_SCRIPT)/create_database_importScript.pl $(INST_SCRIPT)/old_bibCreate.pl 
	$(RM_F) \
	  $(INST_SCRIPT)/transpose.pl $(INST_SCRIPT)/hmm_execute.pl \
	  $(INST_SCRIPT)/calculateNucleosomePositionings.pl $(INST_SCRIPT)/binCreate.pl \
	  $(INST_SCRIPT)/add_2_phenotype_table.pl $(INST_SCRIPT)/open_query_interface.pl \
	  $(INST_SCRIPT)/describe_SNPs.pl $(INST_SCRIPT)/parse_PPI_data.pl \
	  $(INST_SCRIPT)/HMM.pl $(INST_SCRIPT)/add_cbust2gbFile.pl \
	  $(INST_SCRIPT)/identifyPossibleAmplificates.pl $(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl \
	  $(INST_SCRIPT)/create_hashes_from_mysql_create.pl $(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl \
	  $(INST_SCRIPT)/remove_heterozygot_SNPs.pl $(INST_SCRIPT)/MakeNormlizedGFF.pl \
	  $(INST_SCRIPT)/mRNA_Plot.pl $(INST_SCRIPT)/findBindingSiteInPromoterElements.pl \
	  $(INST_SCRIPT)/create_exec_2_add_2_table.pl $(INST_SCRIPT)/simpleXYplot.pl \
	  $(INST_SCRIPT)/create_phenotype_definition.pl $(INST_SCRIPT)/GFF_Calculator_median.pl \
	  $(INST_SCRIPT)/batchStatistics.pl $(INST_SCRIPT)/r_controler.pl \
	  $(INST_SCRIPT)/match_sorter.pl $(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl \
	  $(INST_SCRIPT)/ncbiBLAST_Wrap.pl $(INST_SCRIPT)/createPhaseInputFile.pl \
	  $(INST_SCRIPT)/Region_XY_Value_Table.pl $(INST_SCRIPT)/findBindingSite_in_genome.pl \
	  $(INST_SCRIPT)/findPutativeRegulativeElements.pl $(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl \
	  $(INST_SCRIPT)/add_nimbleGene_NDF_file.pl $(INST_SCRIPT)/XY_plot.pl \
	  $(INST_SCRIPT)/old_V_segment_blot.pl $(INST_SCRIPT)/get_XML_helper_dataset_definition.pl \
	  $(INST_SCRIPT)/createRegionList.pl $(INST_SCRIPT)/QuantilNormalization.pl \
	  $(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl $(INST_SCRIPT)/identify_groups_in_PPI_results.pl \
	  $(INST_SCRIPT)/MAplot.pl $(INST_SCRIPT)/bibCreate.pl \
	  $(INST_SCRIPT)/make_in_paths.pl $(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl \
	  $(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl $(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl \
	  $(INST_SCRIPT)/getOligoValues4regions.pl $(INST_SCRIPT)/make_histogram.pl \
	  $(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl $(INST_SCRIPT)/compareStatisticalResults.pl \
	  $(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl $(INST_SCRIPT)/makeTest_4_lib.pl \
	  $(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl $(INST_SCRIPT)/get_location_for_gene_list.pl \
	  $(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl $(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl 

$(INST_SCRIPT)/match_nucleotideArray_to_genome.pl : bin/maintainance_scripts/match_nucleotideArray_to_genome.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/match_nucleotideArray_to_genome.pl
	$(CP) bin/maintainance_scripts/match_nucleotideArray_to_genome.pl $(INST_SCRIPT)/match_nucleotideArray_to_genome.pl
	$(FIXIN) $(INST_SCRIPT)/match_nucleotideArray_to_genome.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/match_nucleotideArray_to_genome.pl

$(INST_SCRIPT)/affy_csv_to_tsv.pl : bin/array_analysis/affy_csv_to_tsv.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/affy_csv_to_tsv.pl
	$(CP) bin/array_analysis/affy_csv_to_tsv.pl $(INST_SCRIPT)/affy_csv_to_tsv.pl
	$(FIXIN) $(INST_SCRIPT)/affy_csv_to_tsv.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/affy_csv_to_tsv.pl

$(INST_SCRIPT)/extractSampleInfo_from_HTML.pl : bin/array_analysis/extractSampleInfo_from_HTML.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/extractSampleInfo_from_HTML.pl
	$(CP) bin/array_analysis/extractSampleInfo_from_HTML.pl $(INST_SCRIPT)/extractSampleInfo_from_HTML.pl
	$(FIXIN) $(INST_SCRIPT)/extractSampleInfo_from_HTML.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/extractSampleInfo_from_HTML.pl

$(INST_SCRIPT)/importHyb.pl : bin/text/importHyb.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/importHyb.pl
	$(CP) bin/text/importHyb.pl $(INST_SCRIPT)/importHyb.pl
	$(FIXIN) $(INST_SCRIPT)/importHyb.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/importHyb.pl

$(INST_SCRIPT)/V_SegmentBlot.pl : bin/text/V_SegmentBlot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/V_SegmentBlot.pl
	$(CP) bin/text/V_SegmentBlot.pl $(INST_SCRIPT)/V_SegmentBlot.pl
	$(FIXIN) $(INST_SCRIPT)/V_SegmentBlot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/V_SegmentBlot.pl

$(INST_SCRIPT)/mege_two_tabSeparated_files.pl : bin/maintainance_scripts/mege_two_tabSeparated_files.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/mege_two_tabSeparated_files.pl
	$(CP) bin/maintainance_scripts/mege_two_tabSeparated_files.pl $(INST_SCRIPT)/mege_two_tabSeparated_files.pl
	$(FIXIN) $(INST_SCRIPT)/mege_two_tabSeparated_files.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/mege_two_tabSeparated_files.pl

$(INST_SCRIPT)/get_NCBI_genome.pl : bin/maintainance_scripts/get_NCBI_genome.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/get_NCBI_genome.pl
	$(CP) bin/maintainance_scripts/get_NCBI_genome.pl $(INST_SCRIPT)/get_NCBI_genome.pl
	$(FIXIN) $(INST_SCRIPT)/get_NCBI_genome.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/get_NCBI_genome.pl

$(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl : bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl
	$(CP) bin/database_scripts/reanalyse_co_expression_incorporating_phenotype_corrections.pl $(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl
	$(FIXIN) $(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/reanalyse_co_expression_incorporating_phenotype_corrections.pl

$(INST_SCRIPT)/compare_two_files.pl : bin/maintainance_scripts/compare_two_files.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/compare_two_files.pl
	$(CP) bin/maintainance_scripts/compare_two_files.pl $(INST_SCRIPT)/compare_two_files.pl
	$(FIXIN) $(INST_SCRIPT)/compare_two_files.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/compare_two_files.pl

$(INST_SCRIPT)/expressionList_toBarGraphs.pl : bin/array_analysis/expressionList_toBarGraphs.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/expressionList_toBarGraphs.pl
	$(CP) bin/array_analysis/expressionList_toBarGraphs.pl $(INST_SCRIPT)/expressionList_toBarGraphs.pl
	$(FIXIN) $(INST_SCRIPT)/expressionList_toBarGraphs.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/expressionList_toBarGraphs.pl

$(INST_SCRIPT)/trimPictures.pl : bin/text/trimPictures.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/trimPictures.pl
	$(CP) bin/text/trimPictures.pl $(INST_SCRIPT)/trimPictures.pl
	$(FIXIN) $(INST_SCRIPT)/trimPictures.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/trimPictures.pl

$(INST_SCRIPT)/DensityPlots.pl : bin/text/DensityPlots.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/DensityPlots.pl
	$(CP) bin/text/DensityPlots.pl $(INST_SCRIPT)/DensityPlots.pl
	$(FIXIN) $(INST_SCRIPT)/DensityPlots.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/DensityPlots.pl

$(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl : bin/database_scripts/getFeatureNames_in_chromosomal_region.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl
	$(CP) bin/database_scripts/getFeatureNames_in_chromosomal_region.pl $(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl
	$(FIXIN) $(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/getFeatureNames_in_chromosomal_region.pl

$(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl : bin/array_analysis/convert_affy_cdf_to_DBtext.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl
	$(CP) bin/array_analysis/convert_affy_cdf_to_DBtext.pl $(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl
	$(FIXIN) $(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/convert_affy_cdf_to_DBtext.pl

$(INST_SCRIPT)/change_endung.pl : bin/array_analysis/change_endung.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/change_endung.pl
	$(CP) bin/array_analysis/change_endung.pl $(INST_SCRIPT)/change_endung.pl
	$(FIXIN) $(INST_SCRIPT)/change_endung.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/change_endung.pl

$(INST_SCRIPT)/convert2png.pl : bin/text/convert2png.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/convert2png.pl
	$(CP) bin/text/convert2png.pl $(INST_SCRIPT)/convert2png.pl
	$(FIXIN) $(INST_SCRIPT)/convert2png.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/convert2png.pl

$(INST_SCRIPT)/txt_table_to_latex.pl : bin/small_helpers/txt_table_to_latex.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/txt_table_to_latex.pl
	$(CP) bin/small_helpers/txt_table_to_latex.pl $(INST_SCRIPT)/txt_table_to_latex.pl
	$(FIXIN) $(INST_SCRIPT)/txt_table_to_latex.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/txt_table_to_latex.pl

$(INST_SCRIPT)/makeSenseOfLists.pl : bin/maintainance_scripts/makeSenseOfLists.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/makeSenseOfLists.pl
	$(CP) bin/maintainance_scripts/makeSenseOfLists.pl $(INST_SCRIPT)/makeSenseOfLists.pl
	$(FIXIN) $(INST_SCRIPT)/makeSenseOfLists.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/makeSenseOfLists.pl

$(INST_SCRIPT)/add_configuartion.pl : bin/maintainance_scripts/add_configuartion.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/add_configuartion.pl
	$(CP) bin/maintainance_scripts/add_configuartion.pl $(INST_SCRIPT)/add_configuartion.pl
	$(FIXIN) $(INST_SCRIPT)/add_configuartion.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/add_configuartion.pl

$(INST_SCRIPT)/createNewDatabase.pl : bin/text/createNewDatabase.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/createNewDatabase.pl
	$(CP) bin/text/createNewDatabase.pl $(INST_SCRIPT)/createNewDatabase.pl
	$(FIXIN) $(INST_SCRIPT)/createNewDatabase.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/createNewDatabase.pl

$(INST_SCRIPT)/extract_gbFile_fromDB.pl : bin/database_scripts/extract_gbFile_fromDB.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/extract_gbFile_fromDB.pl
	$(CP) bin/database_scripts/extract_gbFile_fromDB.pl $(INST_SCRIPT)/extract_gbFile_fromDB.pl
	$(FIXIN) $(INST_SCRIPT)/extract_gbFile_fromDB.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/extract_gbFile_fromDB.pl

$(INST_SCRIPT)/test_for_T2D_predictive_value.pl : bin/array_analysis/test_for_T2D_predictive_value.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/test_for_T2D_predictive_value.pl
	$(CP) bin/array_analysis/test_for_T2D_predictive_value.pl $(INST_SCRIPT)/test_for_T2D_predictive_value.pl
	$(FIXIN) $(INST_SCRIPT)/test_for_T2D_predictive_value.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/test_for_T2D_predictive_value.pl

$(INST_SCRIPT)/convert_database_dump_to_phase_input.pl : bin/array_analysis/convert_database_dump_to_phase_input.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/convert_database_dump_to_phase_input.pl
	$(CP) bin/array_analysis/convert_database_dump_to_phase_input.pl $(INST_SCRIPT)/convert_database_dump_to_phase_input.pl
	$(FIXIN) $(INST_SCRIPT)/convert_database_dump_to_phase_input.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/convert_database_dump_to_phase_input.pl

$(INST_SCRIPT)/GFFfile2histogram.pl : bin/text/GFFfile2histogram.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/GFFfile2histogram.pl
	$(CP) bin/text/GFFfile2histogram.pl $(INST_SCRIPT)/GFFfile2histogram.pl
	$(FIXIN) $(INST_SCRIPT)/GFFfile2histogram.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/GFFfile2histogram.pl

$(INST_SCRIPT)/pca_calculation.pl : bin/array_analysis/pca_calculation.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/pca_calculation.pl
	$(CP) bin/array_analysis/pca_calculation.pl $(INST_SCRIPT)/pca_calculation.pl
	$(FIXIN) $(INST_SCRIPT)/pca_calculation.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/pca_calculation.pl

$(INST_SCRIPT)/trimPictures.pl : bin/database_scripts/trimPictures.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/trimPictures.pl
	$(CP) bin/database_scripts/trimPictures.pl $(INST_SCRIPT)/trimPictures.pl
	$(FIXIN) $(INST_SCRIPT)/trimPictures.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/trimPictures.pl

$(INST_SCRIPT)/regionXY_plot.pl : bin/text/regionXY_plot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/regionXY_plot.pl
	$(CP) bin/text/regionXY_plot.pl $(INST_SCRIPT)/regionXY_plot.pl
	$(FIXIN) $(INST_SCRIPT)/regionXY_plot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/regionXY_plot.pl

$(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl : bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl
	$(CP) bin/maintainance_scripts/add_NCBI_SNP_chr_rpts_files.pl $(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl
	$(FIXIN) $(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/add_NCBI_SNP_chr_rpts_files.pl

$(INST_SCRIPT)/printGenotypeList.pl : bin/array_analysis/printGenotypeList.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/printGenotypeList.pl
	$(CP) bin/array_analysis/printGenotypeList.pl $(INST_SCRIPT)/printGenotypeList.pl
	$(FIXIN) $(INST_SCRIPT)/printGenotypeList.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/printGenotypeList.pl

$(INST_SCRIPT)/identifyHaplotypes.pl : bin/array_analysis/identifyHaplotypes.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/identifyHaplotypes.pl
	$(CP) bin/array_analysis/identifyHaplotypes.pl $(INST_SCRIPT)/identifyHaplotypes.pl
	$(FIXIN) $(INST_SCRIPT)/identifyHaplotypes.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/identifyHaplotypes.pl

$(INST_SCRIPT)/IdentifyMultiHitOligos.pl : bin/text/IdentifyMultiHitOligos.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/IdentifyMultiHitOligos.pl
	$(CP) bin/text/IdentifyMultiHitOligos.pl $(INST_SCRIPT)/IdentifyMultiHitOligos.pl
	$(FIXIN) $(INST_SCRIPT)/IdentifyMultiHitOligos.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/IdentifyMultiHitOligos.pl

$(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl : bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl
	$(CP) bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl $(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl
	$(FIXIN) $(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/get_closest_genes_for_rsIDs.pl

$(INST_SCRIPT)/create_generic_db_script.pl : bin/small_helpers/create_generic_db_script.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_generic_db_script.pl
	$(CP) bin/small_helpers/create_generic_db_script.pl $(INST_SCRIPT)/create_generic_db_script.pl
	$(FIXIN) $(INST_SCRIPT)/create_generic_db_script.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_generic_db_script.pl

$(INST_SCRIPT)/V_segmentHMM_report.pl : bin/text/V_segmentHMM_report.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/V_segmentHMM_report.pl
	$(CP) bin/text/V_segmentHMM_report.pl $(INST_SCRIPT)/V_segmentHMM_report.pl
	$(FIXIN) $(INST_SCRIPT)/V_segmentHMM_report.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/V_segmentHMM_report.pl

$(INST_SCRIPT)/GetNimbelGeneIDs.pl : bin/text/GetNimbelGeneIDs.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/GetNimbelGeneIDs.pl
	$(CP) bin/text/GetNimbelGeneIDs.pl $(INST_SCRIPT)/GetNimbelGeneIDs.pl
	$(FIXIN) $(INST_SCRIPT)/GetNimbelGeneIDs.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/GetNimbelGeneIDs.pl

$(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl : bin/text/compareIdentifiedEnrichedRegions.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl
	$(CP) bin/text/compareIdentifiedEnrichedRegions.pl $(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl
	$(FIXIN) $(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/compareIdentifiedEnrichedRegions.pl

$(INST_SCRIPT)/sum_up_Batch_results.pl : bin/array_analysis/sum_up_Batch_results.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/sum_up_Batch_results.pl
	$(CP) bin/array_analysis/sum_up_Batch_results.pl $(INST_SCRIPT)/sum_up_Batch_results.pl
	$(FIXIN) $(INST_SCRIPT)/sum_up_Batch_results.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/sum_up_Batch_results.pl

$(INST_SCRIPT)/addOligoInfos.pl : bin/text/addOligoInfos.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/addOligoInfos.pl
	$(CP) bin/text/addOligoInfos.pl $(INST_SCRIPT)/addOligoInfos.pl
	$(FIXIN) $(INST_SCRIPT)/addOligoInfos.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/addOligoInfos.pl

$(INST_SCRIPT)/calculateMean_std_over_genes.pl : bin/array_analysis/calculateMean_std_over_genes.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/calculateMean_std_over_genes.pl
	$(CP) bin/array_analysis/calculateMean_std_over_genes.pl $(INST_SCRIPT)/calculateMean_std_over_genes.pl
	$(FIXIN) $(INST_SCRIPT)/calculateMean_std_over_genes.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/calculateMean_std_over_genes.pl

$(INST_SCRIPT)/arrayDataRestrictor.pl : bin/array_analysis/arrayDataRestrictor.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/arrayDataRestrictor.pl
	$(CP) bin/array_analysis/arrayDataRestrictor.pl $(INST_SCRIPT)/arrayDataRestrictor.pl
	$(FIXIN) $(INST_SCRIPT)/arrayDataRestrictor.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/arrayDataRestrictor.pl

$(INST_SCRIPT)/check_database_classes.pl : bin/small_helpers/check_database_classes.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/check_database_classes.pl
	$(CP) bin/small_helpers/check_database_classes.pl $(INST_SCRIPT)/check_database_classes.pl
	$(FIXIN) $(INST_SCRIPT)/check_database_classes.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/check_database_classes.pl

$(INST_SCRIPT)/merge2tab_separated_files.pl : bin/array_analysis/merge2tab_separated_files.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/merge2tab_separated_files.pl
	$(CP) bin/array_analysis/merge2tab_separated_files.pl $(INST_SCRIPT)/merge2tab_separated_files.pl
	$(FIXIN) $(INST_SCRIPT)/merge2tab_separated_files.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/merge2tab_separated_files.pl

$(INST_SCRIPT)/tabellaricreport.pl : bin/text/tabellaricreport.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/tabellaricreport.pl
	$(CP) bin/text/tabellaricreport.pl $(INST_SCRIPT)/tabellaricreport.pl
	$(FIXIN) $(INST_SCRIPT)/tabellaricreport.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/tabellaricreport.pl

$(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl : bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl
	$(CP) bin/array_analysis/get_DAVID_Pathways_4_Gene_groups.pl $(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl
	$(FIXIN) $(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/get_DAVID_Pathways_4_Gene_groups.pl

$(INST_SCRIPT)/Check_4_Coexpression.pl : bin/array_analysis/Check_4_Coexpression.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/Check_4_Coexpression.pl
	$(CP) bin/array_analysis/Check_4_Coexpression.pl $(INST_SCRIPT)/Check_4_Coexpression.pl
	$(FIXIN) $(INST_SCRIPT)/Check_4_Coexpression.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/Check_4_Coexpression.pl

$(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl : bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl
	$(CP) bin/array_analysis/plot_Phenotype_to_phenotype_correlations.pl $(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl
	$(FIXIN) $(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/plot_Phenotype_to_phenotype_correlations.pl

$(INST_SCRIPT)/KlammernTest.pl : bin/text/KlammernTest.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/KlammernTest.pl
	$(CP) bin/text/KlammernTest.pl $(INST_SCRIPT)/KlammernTest.pl
	$(FIXIN) $(INST_SCRIPT)/KlammernTest.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/KlammernTest.pl

$(INST_SCRIPT)/newTrim.pl : bin/text/newTrim.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/newTrim.pl
	$(CP) bin/text/newTrim.pl $(INST_SCRIPT)/newTrim.pl
	$(FIXIN) $(INST_SCRIPT)/newTrim.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/newTrim.pl

$(INST_SCRIPT)/create_Genexpress_Plugin.pl : bin/database_scripts/create_Genexpress_Plugin.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_Genexpress_Plugin.pl
	$(CP) bin/database_scripts/create_Genexpress_Plugin.pl $(INST_SCRIPT)/create_Genexpress_Plugin.pl
	$(FIXIN) $(INST_SCRIPT)/create_Genexpress_Plugin.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_Genexpress_Plugin.pl

$(INST_SCRIPT)/download_affymetrix_files.pl : bin/array_analysis/download_affymetrix_files.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/download_affymetrix_files.pl
	$(CP) bin/array_analysis/download_affymetrix_files.pl $(INST_SCRIPT)/download_affymetrix_files.pl
	$(FIXIN) $(INST_SCRIPT)/download_affymetrix_files.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/download_affymetrix_files.pl

$(INST_SCRIPT)/gbFile_Pictures.pl : bin/text/gbFile_Pictures.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/gbFile_Pictures.pl
	$(CP) bin/text/gbFile_Pictures.pl $(INST_SCRIPT)/gbFile_Pictures.pl
	$(FIXIN) $(INST_SCRIPT)/gbFile_Pictures.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/gbFile_Pictures.pl

$(INST_SCRIPT)/convert4.pl : bin/text/convert4.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/convert4.pl
	$(CP) bin/text/convert4.pl $(INST_SCRIPT)/convert4.pl
	$(FIXIN) $(INST_SCRIPT)/convert4.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/convert4.pl

$(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl : bin/array_analysis/plot_HistoneProbabilities_on_gbFile.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl
	$(CP) bin/array_analysis/plot_HistoneProbabilities_on_gbFile.pl $(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl
	$(FIXIN) $(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/plot_HistoneProbabilities_on_gbFile.pl

$(INST_SCRIPT)/changeLib_position.pl : bin/maintainance_scripts/changeLib_position.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/changeLib_position.pl
	$(CP) bin/maintainance_scripts/changeLib_position.pl $(INST_SCRIPT)/changeLib_position.pl
	$(FIXIN) $(INST_SCRIPT)/changeLib_position.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/changeLib_position.pl

$(INST_SCRIPT)/insert_phenotype_table.pl : bin/database_scripts/insert_phenotype_table.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/insert_phenotype_table.pl
	$(CP) bin/database_scripts/insert_phenotype_table.pl $(INST_SCRIPT)/insert_phenotype_table.pl
	$(FIXIN) $(INST_SCRIPT)/insert_phenotype_table.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/insert_phenotype_table.pl

$(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl : bin/database_scripts/insert_into_dbTable_array_dataset.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl
	$(CP) bin/database_scripts/insert_into_dbTable_array_dataset.pl $(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl
	$(FIXIN) $(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/insert_into_dbTable_array_dataset.pl

$(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl : bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl
	$(CP) bin/maintainance_scripts/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl $(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl
	$(FIXIN) $(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/calculate_hypergeometrix_max_on_KEGG_pathways_for_gene_list.pl

$(INST_SCRIPT)/tab_table_reformater.pl : bin/array_analysis/tab_table_reformater.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/tab_table_reformater.pl
	$(CP) bin/array_analysis/tab_table_reformater.pl $(INST_SCRIPT)/tab_table_reformater.pl
	$(FIXIN) $(INST_SCRIPT)/tab_table_reformater.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/tab_table_reformater.pl

$(INST_SCRIPT)/UMS.pl : bin/text/UMS.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/UMS.pl
	$(CP) bin/text/UMS.pl $(INST_SCRIPT)/UMS.pl
	$(FIXIN) $(INST_SCRIPT)/UMS.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/UMS.pl

$(INST_SCRIPT)/EraseFeature.pl : bin/text/EraseFeature.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/EraseFeature.pl
	$(CP) bin/text/EraseFeature.pl $(INST_SCRIPT)/EraseFeature.pl
	$(FIXIN) $(INST_SCRIPT)/EraseFeature.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/EraseFeature.pl

$(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl : bin/array_analysis/createConnectionNet_4_expressionArrays.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl
	$(CP) bin/array_analysis/createConnectionNet_4_expressionArrays.pl $(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl
	$(FIXIN) $(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/createConnectionNet_4_expressionArrays.pl

$(INST_SCRIPT)/bib_create.pl : bin/maintainance_scripts/bib_create.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/bib_create.pl
	$(CP) bin/maintainance_scripts/bib_create.pl $(INST_SCRIPT)/bib_create.pl
	$(FIXIN) $(INST_SCRIPT)/bib_create.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/bib_create.pl

$(INST_SCRIPT)/batch_insert_phenotypes.pl : bin/database_scripts/batch_insert_phenotypes.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/batch_insert_phenotypes.pl
	$(CP) bin/database_scripts/batch_insert_phenotypes.pl $(INST_SCRIPT)/batch_insert_phenotypes.pl
	$(FIXIN) $(INST_SCRIPT)/batch_insert_phenotypes.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/batch_insert_phenotypes.pl

$(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl : bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl
	$(CP) bin/database_scripts/plot_co_expression_incorporating_phenotype_corrections_results.pl $(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl
	$(FIXIN) $(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/plot_co_expression_incorporating_phenotype_corrections_results.pl

$(INST_SCRIPT)/create_database_importScript.pl : bin/small_helpers/create_database_importScript.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_database_importScript.pl
	$(CP) bin/small_helpers/create_database_importScript.pl $(INST_SCRIPT)/create_database_importScript.pl
	$(FIXIN) $(INST_SCRIPT)/create_database_importScript.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_database_importScript.pl

$(INST_SCRIPT)/old_bibCreate.pl : bin/maintainance_scripts/old_bibCreate.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/old_bibCreate.pl
	$(CP) bin/maintainance_scripts/old_bibCreate.pl $(INST_SCRIPT)/old_bibCreate.pl
	$(FIXIN) $(INST_SCRIPT)/old_bibCreate.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/old_bibCreate.pl

$(INST_SCRIPT)/transpose.pl : bin/array_analysis/transpose.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/transpose.pl
	$(CP) bin/array_analysis/transpose.pl $(INST_SCRIPT)/transpose.pl
	$(FIXIN) $(INST_SCRIPT)/transpose.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/transpose.pl

$(INST_SCRIPT)/hmm_execute.pl : bin/text/hmm_execute.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/hmm_execute.pl
	$(CP) bin/text/hmm_execute.pl $(INST_SCRIPT)/hmm_execute.pl
	$(FIXIN) $(INST_SCRIPT)/hmm_execute.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/hmm_execute.pl

$(INST_SCRIPT)/calculateNucleosomePositionings.pl : bin/maintainance_scripts/calculateNucleosomePositionings.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/calculateNucleosomePositionings.pl
	$(CP) bin/maintainance_scripts/calculateNucleosomePositionings.pl $(INST_SCRIPT)/calculateNucleosomePositionings.pl
	$(FIXIN) $(INST_SCRIPT)/calculateNucleosomePositionings.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/calculateNucleosomePositionings.pl

$(INST_SCRIPT)/binCreate.pl : bin/maintainance_scripts/binCreate.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/binCreate.pl
	$(CP) bin/maintainance_scripts/binCreate.pl $(INST_SCRIPT)/binCreate.pl
	$(FIXIN) $(INST_SCRIPT)/binCreate.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/binCreate.pl

$(INST_SCRIPT)/add_2_phenotype_table.pl : bin/array_analysis/add_2_phenotype_table.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/add_2_phenotype_table.pl
	$(CP) bin/array_analysis/add_2_phenotype_table.pl $(INST_SCRIPT)/add_2_phenotype_table.pl
	$(FIXIN) $(INST_SCRIPT)/add_2_phenotype_table.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/add_2_phenotype_table.pl

$(INST_SCRIPT)/open_query_interface.pl : bin/maintainance_scripts/open_query_interface.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/open_query_interface.pl
	$(CP) bin/maintainance_scripts/open_query_interface.pl $(INST_SCRIPT)/open_query_interface.pl
	$(FIXIN) $(INST_SCRIPT)/open_query_interface.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/open_query_interface.pl

$(INST_SCRIPT)/describe_SNPs.pl : bin/array_analysis/describe_SNPs.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/describe_SNPs.pl
	$(CP) bin/array_analysis/describe_SNPs.pl $(INST_SCRIPT)/describe_SNPs.pl
	$(FIXIN) $(INST_SCRIPT)/describe_SNPs.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/describe_SNPs.pl

$(INST_SCRIPT)/parse_PPI_data.pl : bin/array_analysis/parse_PPI_data.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/parse_PPI_data.pl
	$(CP) bin/array_analysis/parse_PPI_data.pl $(INST_SCRIPT)/parse_PPI_data.pl
	$(FIXIN) $(INST_SCRIPT)/parse_PPI_data.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/parse_PPI_data.pl

$(INST_SCRIPT)/HMM.pl : bin/text/HMM.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/HMM.pl
	$(CP) bin/text/HMM.pl $(INST_SCRIPT)/HMM.pl
	$(FIXIN) $(INST_SCRIPT)/HMM.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/HMM.pl

$(INST_SCRIPT)/add_cbust2gbFile.pl : bin/text/add_cbust2gbFile.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/add_cbust2gbFile.pl
	$(CP) bin/text/add_cbust2gbFile.pl $(INST_SCRIPT)/add_cbust2gbFile.pl
	$(FIXIN) $(INST_SCRIPT)/add_cbust2gbFile.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/add_cbust2gbFile.pl

$(INST_SCRIPT)/identifyPossibleAmplificates.pl : bin/text/identifyPossibleAmplificates.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/identifyPossibleAmplificates.pl
	$(CP) bin/text/identifyPossibleAmplificates.pl $(INST_SCRIPT)/identifyPossibleAmplificates.pl
	$(FIXIN) $(INST_SCRIPT)/identifyPossibleAmplificates.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/identifyPossibleAmplificates.pl

$(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl : bin/array_analysis/convert_Jasmina_2_phenotype.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl
	$(CP) bin/array_analysis/convert_Jasmina_2_phenotype.pl $(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl
	$(FIXIN) $(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/convert_Jasmina_2_phenotype.pl

$(INST_SCRIPT)/create_hashes_from_mysql_create.pl : bin/small_helpers/create_hashes_from_mysql_create.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_hashes_from_mysql_create.pl
	$(CP) bin/small_helpers/create_hashes_from_mysql_create.pl $(INST_SCRIPT)/create_hashes_from_mysql_create.pl
	$(FIXIN) $(INST_SCRIPT)/create_hashes_from_mysql_create.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_hashes_from_mysql_create.pl

$(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl : bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl
	$(CP) bin/maintainance_scripts/create_a_data_table_based_file_interface_class.pl $(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl
	$(FIXIN) $(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_a_data_table_based_file_interface_class.pl

$(INST_SCRIPT)/remove_heterozygot_SNPs.pl : bin/array_analysis/remove_heterozygot_SNPs.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/remove_heterozygot_SNPs.pl
	$(CP) bin/array_analysis/remove_heterozygot_SNPs.pl $(INST_SCRIPT)/remove_heterozygot_SNPs.pl
	$(FIXIN) $(INST_SCRIPT)/remove_heterozygot_SNPs.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/remove_heterozygot_SNPs.pl

$(INST_SCRIPT)/MakeNormlizedGFF.pl : bin/text/MakeNormlizedGFF.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/MakeNormlizedGFF.pl
	$(CP) bin/text/MakeNormlizedGFF.pl $(INST_SCRIPT)/MakeNormlizedGFF.pl
	$(FIXIN) $(INST_SCRIPT)/MakeNormlizedGFF.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/MakeNormlizedGFF.pl

$(INST_SCRIPT)/mRNA_Plot.pl : bin/text/mRNA_Plot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/mRNA_Plot.pl
	$(CP) bin/text/mRNA_Plot.pl $(INST_SCRIPT)/mRNA_Plot.pl
	$(FIXIN) $(INST_SCRIPT)/mRNA_Plot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/mRNA_Plot.pl

$(INST_SCRIPT)/findBindingSiteInPromoterElements.pl : bin/text/findBindingSiteInPromoterElements.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/findBindingSiteInPromoterElements.pl
	$(CP) bin/text/findBindingSiteInPromoterElements.pl $(INST_SCRIPT)/findBindingSiteInPromoterElements.pl
	$(FIXIN) $(INST_SCRIPT)/findBindingSiteInPromoterElements.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/findBindingSiteInPromoterElements.pl

$(INST_SCRIPT)/create_exec_2_add_2_table.pl : bin/small_helpers/create_exec_2_add_2_table.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_exec_2_add_2_table.pl
	$(CP) bin/small_helpers/create_exec_2_add_2_table.pl $(INST_SCRIPT)/create_exec_2_add_2_table.pl
	$(FIXIN) $(INST_SCRIPT)/create_exec_2_add_2_table.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_exec_2_add_2_table.pl

$(INST_SCRIPT)/simpleXYplot.pl : bin/array_analysis/simpleXYplot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/simpleXYplot.pl
	$(CP) bin/array_analysis/simpleXYplot.pl $(INST_SCRIPT)/simpleXYplot.pl
	$(FIXIN) $(INST_SCRIPT)/simpleXYplot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/simpleXYplot.pl

$(INST_SCRIPT)/create_phenotype_definition.pl : bin/database_scripts/create_phenotype_definition.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/create_phenotype_definition.pl
	$(CP) bin/database_scripts/create_phenotype_definition.pl $(INST_SCRIPT)/create_phenotype_definition.pl
	$(FIXIN) $(INST_SCRIPT)/create_phenotype_definition.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/create_phenotype_definition.pl

$(INST_SCRIPT)/GFF_Calculator_median.pl : bin/text/GFF_Calculator_median.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/GFF_Calculator_median.pl
	$(CP) bin/text/GFF_Calculator_median.pl $(INST_SCRIPT)/GFF_Calculator_median.pl
	$(FIXIN) $(INST_SCRIPT)/GFF_Calculator_median.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/GFF_Calculator_median.pl

$(INST_SCRIPT)/batchStatistics.pl : bin/array_analysis/batchStatistics.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/batchStatistics.pl
	$(CP) bin/array_analysis/batchStatistics.pl $(INST_SCRIPT)/batchStatistics.pl
	$(FIXIN) $(INST_SCRIPT)/batchStatistics.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/batchStatistics.pl

$(INST_SCRIPT)/r_controler.pl : bin/array_analysis/r_controler.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/r_controler.pl
	$(CP) bin/array_analysis/r_controler.pl $(INST_SCRIPT)/r_controler.pl
	$(FIXIN) $(INST_SCRIPT)/r_controler.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/r_controler.pl

$(INST_SCRIPT)/match_sorter.pl : bin/text/match_sorter.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/match_sorter.pl
	$(CP) bin/text/match_sorter.pl $(INST_SCRIPT)/match_sorter.pl
	$(FIXIN) $(INST_SCRIPT)/match_sorter.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/match_sorter.pl

$(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl : bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl
	$(CP) bin/database_scripts/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl $(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl
	$(FIXIN) $(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/reanalyse_co_expression_incorporating_SINGLE_phenotype_corrections.pl

$(INST_SCRIPT)/ncbiBLAST_Wrap.pl : bin/text/ncbiBLAST_Wrap.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/ncbiBLAST_Wrap.pl
	$(CP) bin/text/ncbiBLAST_Wrap.pl $(INST_SCRIPT)/ncbiBLAST_Wrap.pl
	$(FIXIN) $(INST_SCRIPT)/ncbiBLAST_Wrap.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/ncbiBLAST_Wrap.pl

$(INST_SCRIPT)/createPhaseInputFile.pl : bin/array_analysis/createPhaseInputFile.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/createPhaseInputFile.pl
	$(CP) bin/array_analysis/createPhaseInputFile.pl $(INST_SCRIPT)/createPhaseInputFile.pl
	$(FIXIN) $(INST_SCRIPT)/createPhaseInputFile.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/createPhaseInputFile.pl

$(INST_SCRIPT)/Region_XY_Value_Table.pl : bin/text/Region_XY_Value_Table.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/Region_XY_Value_Table.pl
	$(CP) bin/text/Region_XY_Value_Table.pl $(INST_SCRIPT)/Region_XY_Value_Table.pl
	$(FIXIN) $(INST_SCRIPT)/Region_XY_Value_Table.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/Region_XY_Value_Table.pl

$(INST_SCRIPT)/findBindingSite_in_genome.pl : bin/database_scripts/findBindingSite_in_genome.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/findBindingSite_in_genome.pl
	$(CP) bin/database_scripts/findBindingSite_in_genome.pl $(INST_SCRIPT)/findBindingSite_in_genome.pl
	$(FIXIN) $(INST_SCRIPT)/findBindingSite_in_genome.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/findBindingSite_in_genome.pl

$(INST_SCRIPT)/findPutativeRegulativeElements.pl : bin/array_analysis/findPutativeRegulativeElements.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/findPutativeRegulativeElements.pl
	$(CP) bin/array_analysis/findPutativeRegulativeElements.pl $(INST_SCRIPT)/findPutativeRegulativeElements.pl
	$(FIXIN) $(INST_SCRIPT)/findPutativeRegulativeElements.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/findPutativeRegulativeElements.pl

$(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl : bin/array_analysis/meanExpressionList_toBarGraphs.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl
	$(CP) bin/array_analysis/meanExpressionList_toBarGraphs.pl $(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl
	$(FIXIN) $(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/meanExpressionList_toBarGraphs.pl

$(INST_SCRIPT)/add_nimbleGene_NDF_file.pl : bin/maintainance_scripts/add_nimbleGene_NDF_file.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/add_nimbleGene_NDF_file.pl
	$(CP) bin/maintainance_scripts/add_nimbleGene_NDF_file.pl $(INST_SCRIPT)/add_nimbleGene_NDF_file.pl
	$(FIXIN) $(INST_SCRIPT)/add_nimbleGene_NDF_file.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/add_nimbleGene_NDF_file.pl

$(INST_SCRIPT)/XY_plot.pl : bin/text/XY_plot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/XY_plot.pl
	$(CP) bin/text/XY_plot.pl $(INST_SCRIPT)/XY_plot.pl
	$(FIXIN) $(INST_SCRIPT)/XY_plot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/XY_plot.pl

$(INST_SCRIPT)/old_V_segment_blot.pl : bin/text/old_V_segment_blot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/old_V_segment_blot.pl
	$(CP) bin/text/old_V_segment_blot.pl $(INST_SCRIPT)/old_V_segment_blot.pl
	$(FIXIN) $(INST_SCRIPT)/old_V_segment_blot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/old_V_segment_blot.pl

$(INST_SCRIPT)/get_XML_helper_dataset_definition.pl : bin/small_helpers/get_XML_helper_dataset_definition.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/get_XML_helper_dataset_definition.pl
	$(CP) bin/small_helpers/get_XML_helper_dataset_definition.pl $(INST_SCRIPT)/get_XML_helper_dataset_definition.pl
	$(FIXIN) $(INST_SCRIPT)/get_XML_helper_dataset_definition.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/get_XML_helper_dataset_definition.pl

$(INST_SCRIPT)/createRegionList.pl : bin/text/createRegionList.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/createRegionList.pl
	$(CP) bin/text/createRegionList.pl $(INST_SCRIPT)/createRegionList.pl
	$(FIXIN) $(INST_SCRIPT)/createRegionList.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/createRegionList.pl

$(INST_SCRIPT)/QuantilNormalization.pl : bin/text/QuantilNormalization.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/QuantilNormalization.pl
	$(CP) bin/text/QuantilNormalization.pl $(INST_SCRIPT)/QuantilNormalization.pl
	$(FIXIN) $(INST_SCRIPT)/QuantilNormalization.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/QuantilNormalization.pl

$(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl : bin/array_analysis/convert_affy_cel_to_DBtext.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl
	$(CP) bin/array_analysis/convert_affy_cel_to_DBtext.pl $(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl
	$(FIXIN) $(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/convert_affy_cel_to_DBtext.pl

$(INST_SCRIPT)/identify_groups_in_PPI_results.pl : bin/array_analysis/identify_groups_in_PPI_results.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/identify_groups_in_PPI_results.pl
	$(CP) bin/array_analysis/identify_groups_in_PPI_results.pl $(INST_SCRIPT)/identify_groups_in_PPI_results.pl
	$(FIXIN) $(INST_SCRIPT)/identify_groups_in_PPI_results.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/identify_groups_in_PPI_results.pl

$(INST_SCRIPT)/MAplot.pl : bin/text/MAplot.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/MAplot.pl
	$(CP) bin/text/MAplot.pl $(INST_SCRIPT)/MAplot.pl
	$(FIXIN) $(INST_SCRIPT)/MAplot.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/MAplot.pl

$(INST_SCRIPT)/bibCreate.pl : bin/text/bibCreate.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/bibCreate.pl
	$(CP) bin/text/bibCreate.pl $(INST_SCRIPT)/bibCreate.pl
	$(FIXIN) $(INST_SCRIPT)/bibCreate.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/bibCreate.pl

$(INST_SCRIPT)/make_in_paths.pl : bin/small_helpers/make_in_paths.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/make_in_paths.pl
	$(CP) bin/small_helpers/make_in_paths.pl $(INST_SCRIPT)/make_in_paths.pl
	$(FIXIN) $(INST_SCRIPT)/make_in_paths.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/make_in_paths.pl

$(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl : bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl
	$(CP) bin/array_analysis/estimate_SNP_influence_on_expression_dataset.pl $(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl
	$(FIXIN) $(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/estimate_SNP_influence_on_expression_dataset.pl

$(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl : bin/array_analysis/remove_variable_influence_from_expression_array.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl
	$(CP) bin/array_analysis/remove_variable_influence_from_expression_array.pl $(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl
	$(FIXIN) $(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/remove_variable_influence_from_expression_array.pl

$(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl : bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl
	$(CP) bin/array_analysis/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl $(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl
	$(FIXIN) $(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/MeDIP_extract_oligos_from_NimbleGene_GFF_file.pl

$(INST_SCRIPT)/getOligoValues4regions.pl : bin/text/getOligoValues4regions.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/getOligoValues4regions.pl
	$(CP) bin/text/getOligoValues4regions.pl $(INST_SCRIPT)/getOligoValues4regions.pl
	$(FIXIN) $(INST_SCRIPT)/getOligoValues4regions.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/getOligoValues4regions.pl

$(INST_SCRIPT)/make_histogram.pl : bin/array_analysis/make_histogram.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/make_histogram.pl
	$(CP) bin/array_analysis/make_histogram.pl $(INST_SCRIPT)/make_histogram.pl
	$(FIXIN) $(INST_SCRIPT)/make_histogram.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/make_histogram.pl

$(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl : bin/text/ChromosomalRegions2SeqFiles.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl
	$(CP) bin/text/ChromosomalRegions2SeqFiles.pl $(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl
	$(FIXIN) $(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/ChromosomalRegions2SeqFiles.pl

$(INST_SCRIPT)/compareStatisticalResults.pl : bin/array_analysis/compareStatisticalResults.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/compareStatisticalResults.pl
	$(CP) bin/array_analysis/compareStatisticalResults.pl $(INST_SCRIPT)/compareStatisticalResults.pl
	$(FIXIN) $(INST_SCRIPT)/compareStatisticalResults.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/compareStatisticalResults.pl

$(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl : bin/text/NimbleGeneNormalization_NoHypothesis.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl
	$(CP) bin/text/NimbleGeneNormalization_NoHypothesis.pl $(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl
	$(FIXIN) $(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/NimbleGeneNormalization_NoHypothesis.pl

$(INST_SCRIPT)/makeTest_4_lib.pl : bin/maintainance_scripts/makeTest_4_lib.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/makeTest_4_lib.pl
	$(CP) bin/maintainance_scripts/makeTest_4_lib.pl $(INST_SCRIPT)/makeTest_4_lib.pl
	$(FIXIN) $(INST_SCRIPT)/makeTest_4_lib.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/makeTest_4_lib.pl

$(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl : bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl
	$(CP) bin/array_analysis/compare_cis_SNPs_to_gene_expression.pl $(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl
	$(FIXIN) $(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/compare_cis_SNPs_to_gene_expression.pl

$(INST_SCRIPT)/get_location_for_gene_list.pl : bin/array_analysis/get_location_for_gene_list.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/get_location_for_gene_list.pl
	$(CP) bin/array_analysis/get_location_for_gene_list.pl $(INST_SCRIPT)/get_location_for_gene_list.pl
	$(FIXIN) $(INST_SCRIPT)/get_location_for_gene_list.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/get_location_for_gene_list.pl

$(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl : bin/text/oligoEnrichmentFactorsForRegion.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl
	$(CP) bin/text/oligoEnrichmentFactorsForRegion.pl $(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl
	$(FIXIN) $(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/oligoEnrichmentFactorsForRegion.pl

$(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl : bin/array_analysis/get_GeneDescription_from_GeneCards.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl
	$(CP) bin/array_analysis/get_GeneDescription_from_GeneCards.pl $(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl
	$(FIXIN) $(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/get_GeneDescription_from_GeneCards.pl



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  *$(LIB_EXT) core \
	  core.[0-9] $(INST_ARCHAUTODIR)/extralibs.all \
	  core.[0-9][0-9] $(BASEEXT).bso \
	  pm_to_blib.ts core.[0-9][0-9][0-9][0-9] \
	  $(BASEEXT).x $(BOOTSTRAP) \
	  perl$(EXE_EXT) tmon.out \
	  *$(OBJ_EXT) pm_to_blib \
	  $(INST_ARCHAUTODIR)/extralibs.ld blibdirs.ts \
	  core.[0-9][0-9][0-9][0-9][0-9] *perl.core \
	  core.*perl.*.? $(MAKE_APERL_FILE) \
	  perl $(BASEEXT).def \
	  core.[0-9][0-9][0-9] mon.out \
	  lib$(BASEEXT).def perlmain.c \
	  perl.exe so_locations \
	  $(BASEEXT).exp 
	- $(RM_RF) \
	  blib 
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge ::  clean realclean_subdirs
	- $(RM_F) \
	  $(MAKEFILE_OLD) $(FIRST_MAKEFILE) 
	- $(RM_RF) \
	  MYMETA.yml $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile :
	$(NOECHO) $(NOOP)


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old 



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir  
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{META.yml} => q{Module meta-data (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add META.yml to MANIFEST: $${'\''@'\''}\n"' --



# --- MakeMaker distsignature section:
distsignature : create_distdir
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install :: all
	$(NOECHO) umask 02; $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install :: all

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLSITEARCH)/perllocal.pod
	-$(NOECHO) umask 02; $(MKPATH) $(DESTINSTALLSITEARCH)
	-$(NOECHO) umask 02; $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLSITEARCH)/perllocal.pod

doc_vendor_install :: all


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::



# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /usr/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/_3Ddata2_Jmol_htmlPage.t t/affy_cell_flat_file.t t/affy_geneotypeCalls.t t/affy_SNP_annot.t t/affymerix_snp_data.t t/affymerix_snp_description.t t/Allele_2_Phenotype_correlator.t t/alleleFreq.t t/antibodyDB.t t/array_GFF.t t/array_Hyb.t t/array_TStat.t t/array_values.t t/arraySorter.t t/axis.t t/BESTPAIRS_SUMMARY.t t/blastLine.t t/blastResult.t t/CEL_file_storage.t t/cellTypeDB.t t/ChapterStructure.t t/chi_square.t t/chromosomal_histogram.t t/Chromosomes_plot.t t/ClusterBuster.t t/color.t t/compare_SNP_2_Gene_expression_results.t t/correlatingData.t t/creaturesTable.t t/data_table.t t/dataRow.t t/dataset_registaration.t t/db_0.0_configuration.t t/db_0.0_errorTable.pm.t t/db_0.0_fulfilledTask.t t/db_0.0_job_description.t t/db_0.0_loggingTable.t t/db_0.0_workingTable.t t/db_1.1_gbFilesTable.t t/db_1.2_gbFeaturesTable.t t/db_1_genomeImporter.t t/db_2.1.0.1_experiment.t t/db_2.1.0_scientistTable.t t/db_2.1.1.1_materialList.t t/db_2.1.1_nucleosomePositioning.t t/db_2.1.2_phenotype_registration.t t/db_2.1.2_protocol_table.t t/db_2.1.3_tissueTable.t t/db_2.1.4_external_files.t t/db_2.2.1_nucleotide_array_0.t t/db_2.3.1_oligo2dna_register.t t/db_2.3_match_oligoArray_to_genome.t t/db_2.4.0_array_dataset.t t/db_2.5.1_calculation_summary_statistics.t t/db_2.5.2_calculation_HMM.t t/db_3.1.Affy_description.t t/db_3.2_expression_estimates.t t/db_4.0_LabBook.t t/db_4_0_WGAS.t t/db_system_linkage_info.t t/deepSeq_blastLine.t t/deepSeq_region.t t/deepSequencingRegion.t t/densityMap.t t/designDB.t t/designImporter.t t/enrichedRegions.t t/evaluateHMM_data.t t/expression_net_reader.t t/familyTree.t t/fastaDB.t t/fastaFile.t t/Figure.t t/fileDB.t t/fixed_values_axis.t t/Font.t t/fulfilledTask_handler.t t/gbAxis.t t/gbFeature.t t/gbFeature_X_axis.t t/gbFile.t t/gbFile_X_axis.t t/gbFile_X_axis_with_NuclPos.t t/gbFileMerger.t t/gbHeader.t t/gbRegion.t t/genbank_flatfile_db.t t/geneDescription.t t/geneInfo.t t/genomeDB.t t/genomeSearchResult.t t/GFF_data_Y_axis.t t/gffFile.t t/gin_file.t t/gnuplotParser.t t/grant_table.t t/group3D_MatrixEntries.t t/haplotype.t t/haplotypeList.t t/hapMap_phase.t t/histogram.t t/histogram_container.t t/HMM.t t/HMM_EnrichmentFactors.t t/HMM_hypothesis.t t/HMM_state_values.t t/hmmReportEntry.t t/HTML_helper.t t/hybInfoDB.t t/hypothesis.t t/hypothesis_table.t t/imgt2gb.t t/imgtFeature.t t/imgtFeatureDB.t t/imgtFile.t t/import_KEGG_pathway.t t/importHyb.t t/inverseBlastHit.t t/KruskalWallisTest.t t/Latex_Document.t t/legendPlot.t t/linear_regression.t t/List4enrichedRegions.t t/LIST_SUMMARY.t t/list_using_table.t t/logHistogram.t t/map_file.t t/MAplot.t t/marcowChain.t t/marcowModel.t t/MDsum_output.t t/multi_axis.t t/multiline_gb_Axis.t t/multiline_HMM_Axis.t t/multilineAxis.t t/multiLineLable.t t/multiLinePlot.t t/multilineXY_axis.t t/NCBI_genome_Readme.t t/ndfFile.t t/NEW_GFF_data_Y_axis.t t/new_histogram.t t/NEW_Summary_GFF_Y_axis.t t/newGFFtoSignalMap.t t/NimbleGene_Chip_on_chip.t t/NimbleGene_config.t t/Nimblegene_GeneInfo.t t/nimbleGeneArrays.t t/normalizeGFFvalues.t t/nuclDataRow.t t/nucleotidePositioningData.t t/oligo2dnaDB.t t/oligoBin.t t/oligoBinReport.t t/oligoDB.t t/organismDB.t t/pairFile.t t/partizipatingSubjects.t t/ped_file.t t/peopleDB.t t/PHASE_outfile.t t/pictureLayout.t t/plink.t t/plot.t t/plottable.t t/plottable_gbFile.t t/primer.t t/primerList.t t/probabilityFunction.t t/project_table.t t/pubmed_search.t t/PW_table.t t/quantilNormalization.t t/queryInterface.t t/qValues.t t/R_glm.t t/Rbridge.t t/root.t t/rs_dataset.t t/ruler_x_axis.t t/sampleTable.t t/scientificComunity.t t/Section.t t/selected_regions_dataRow.t t/seq_contig.t t/simple_multiline_gb_Axis.t t/simpleBarGraph.t t/simpleWhiskerPlot.t t/simpleXYgraph.t t/singleLinePlot.t t/singleLinePlotHMM.t t/SNP_2_Gene_Expression.t t/SNP_2_gene_expression_reader.t t/SNP_cluster.t t/SpearmanTest.t t/ssake_info.t t/stat_results.t t/stat_test.t t/statisticItem.t t/stefans_libs_database_DeepSeq_genes.t t/stefans_libs_database_Protein_Expression.t t/stefans_libs_file_readers_affymetrix_expression_result.t t/stefans_libs_file_readers_CoExpressionDescription.t t/stefans_libs_file_readers_CoExpressionDescription_KEGG_results.t t/stefans_libs_file_readers_MeDIP_results.t t/stefans_libs_file_readers_phenotypes.t t/stefans_libs_file_readers_PPI_text_file.t t/stefans_libs_file_readers_stat_results_KruskalWallisTest_result.t t/stefans_libs_file_readers_svg_pathway_description.t t/stefans_libs_file_readers_UCSC_ens_Gene.t t/stefans_libs_flexible_data_structures_sequenome_resultsFile.t t/stefans_libs_Latex_Document_Chapter.t t/stefans_libs_Latex_Document_Figure.t t/stefans_libs_Latex_Document_gene_description.t t/stefans_libs_WebSearch_Googel_Search.t t/storage_table.t t/subjectTable.t t/SubPlot_element.t t/summaryLine.t t/table_script_generator.t t/tableHandling.t t/tableLine.t t/template4deepEvaluation.t t/Text.t t/thread_helper.t t/UMS.t t/UMS_EnrichmentFactors.t t/UMS_old.t t/unifiedDataHandler.t t/V_segment_summaryBlot.t t/VbinaryEvauation.t t/VbinElement.t t/Wilcox_Test.t t/X_feature.t t/XML_handler.t t/XY_Evaluation.t t/xy_graph_withHistograms.t t/XY_withHistograms.t t/XYvalues.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE) subdirs-test

subdirs-test ::
	$(NOECHO) $(NOOP)


test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), 'inc', '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-Iinc" "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="1.00">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT></ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Stefan Lang StefanLang@med.lu.se</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Archive::Zip" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="DBI::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Date::Calc" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Date::Simple" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="DateTime::Format::MySQL" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Digest::MD5" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="ExtUtils::MakeMaker" VERSION="6.55" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Copy" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::HomeDir" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="FindBin::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="GD::SVG" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Number::Format" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="PerlIO::gzip" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Statistics::R" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Test::More" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="WWW::Search::NCBI::PubMed" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="XML::LibXML" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="formatdb::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="inc::Module::Install" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="megablast::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="i486-linux-gnu-thread-multi-5.10" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/doc/list.files blib/lib/stefans_libs/doc/list.files \
	  lib/stefans_libs/database/genomeDB/gene_description.pm blib/lib/stefans_libs/database/genomeDB/gene_description.pm \
	  lib/Statistics/R/Bridge/pipe.pm blib/lib/Statistics/R/Bridge/pipe.pm \
	  lib/stefans_libs/gbFile/gbFeature.pm blib/lib/stefans_libs/gbFile/gbFeature.pm \
	  lib/stefans_libs/database/subjectTable/phenotype/phenotype_base_class.pm blib/lib/stefans_libs/database/subjectTable/phenotype/phenotype_base_class.pm \
	  lib/stefans_libs/database/LabBook/figure_table.pm blib/lib/stefans_libs/database/LabBook/figure_table.pm \
	  lib/stefans_libs/database/scientistTable/role_list.pm blib/lib/stefans_libs/database/scientistTable/role_list.pm \
	  lib/stefans_libs/V_segment_summaryBlot/testgbFeature_X_axis.pl blib/lib/stefans_libs/V_segment_summaryBlot/testgbFeature_X_axis.pl \
	  lib/stefans_libs/nimbleGeneFiles/enrichedRegions.pm blib/lib/stefans_libs/nimbleGeneFiles/enrichedRegions.pm \
	  lib/stefans_libs/database/LabBook/ChapterStructure.pm blib/lib/stefans_libs/database/LabBook/ChapterStructure.pm \
	  lib/stefans_libs/database/dataset_registaration/dataset_list.pm blib/lib/stefans_libs/database/dataset_registaration/dataset_list.pm \
	  lib/stefans_libs/sequence_modification/imgtFileTester.pl blib/lib/stefans_libs/sequence_modification/imgtFileTester.pl \
	  lib/stefans_libs/database/array_dataset/Affymetrix_SNP_array.pm blib/lib/stefans_libs/database/array_dataset/Affymetrix_SNP_array.pm \
	  lib/stefans_libs/array_analysis/outputFormater/HTML_helper.pm blib/lib/stefans_libs/array_analysis/outputFormater/HTML_helper.pm \
	  lib/stefans_libs/V_segment_summaryBlot/List4enrichedRegions.pm blib/lib/stefans_libs/V_segment_summaryBlot/List4enrichedRegions.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Mac/LinuxLibertine-BdIt-2.1.6.dfont blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinuxLibertine-BdIt-2.1.6.dfont \
	  lib/stefans_libs/doc/database/fileDB.html blib/lib/stefans_libs/doc/database/fileDB.html \
	  lib/stefans_libs/array_analysis/correlatingData/qValues.pm blib/lib/stefans_libs/array_analysis/correlatingData/qValues.pm \
	  lib/stefans_libs/array_analysis/dataRep/geneInfo.pm blib/lib/stefans_libs/array_analysis/dataRep/geneInfo.pm \
	  lib/stefans_libs/Latex_Document/Section.pm blib/lib/stefans_libs/Latex_Document/Section.pm \
	  lib/stefans_libs/plot/Chromosomes_plot.pm blib/lib/stefans_libs/plot/Chromosomes_plot.pm \
	  lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm blib/lib/stefans_libs/database/system_tables/PluginRegister/exp_functions_list.pm \
	  lib/stefans_libs/database/fileDB.pm blib/lib/stefans_libs/database/fileDB.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/V_segment_summaryBlot/dataRow.pm blib/lib/stefans_libs/V_segment_summaryBlot/dataRow.pm \
	  lib/stefans_libs/file_readers/MDsum_output.pm blib/lib/stefans_libs/file_readers/MDsum_output.pm \
	  lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_array.pm blib/lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_array.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.otf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.otf \
	  lib/stefans_libs/normlize/quantilNormalization.pm blib/lib/stefans_libs/normlize/quantilNormalization.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_It-2.1.6.dfont blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_It-2.1.6.dfont \
	  lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm blib/lib/stefans_libs/file_readers/SNP_2_gene_expression_reader.pm \
	  lib/stefans_libs/database/array_GFF.pm blib/lib/stefans_libs/database/array_GFF.pm \
	  lib/stefans_libs/array_analysis/affy_files/gin_file.pm blib/lib/stefans_libs/array_analysis/affy_files/gin_file.pm \
	  lib/stefans_libs/database/Protein_Expression.pm blib/lib/stefans_libs/database/Protein_Expression.pm \
	  makeTest_4_lib.pl $(INST_LIB)/makeTest_4_lib.pl \
	  lib/stefans_libs/doc/Script.sh blib/lib/stefans_libs/doc/Script.sh \
	  lib/stefans_libs/array_analysis/outputFormater/_3Ddata2_Jmol_htmlPage.pm blib/lib/stefans_libs/array_analysis/outputFormater/_3Ddata2_Jmol_htmlPage.pm \
	  lib/stefans_libs/multiLinePlot/multilineAxis.pm blib/lib/stefans_libs/multiLinePlot/multilineAxis.pm \
	  lib/stefans_libs/doc/statistics/newGFFtoSignalMap.html blib/lib/stefans_libs/doc/statistics/newGFFtoSignalMap.html \
	  lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm blib/lib/stefans_libs/flexible_data_structures/data_table/arraySorter.pm \
	  lib/stefans_libs/root.pm blib/lib/stefans_libs/root.pm \
	  lib/stefans_libs/database/protocol_table.pm blib/lib/stefans_libs/database/protocol_table.pm \
	  lib/stefans_libs/database/experimentTypes/type_to_plugin.pm blib/lib/stefans_libs/database/experimentTypes/type_to_plugin.pm \
	  lib/stefans_libs/gbFile/gbRegion.pm blib/lib/stefans_libs/gbFile/gbRegion.pm \
	  lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm blib/lib/stefans_libs/database/LabBook/figure_table/subfigure_table.pm \
	  lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm blib/lib/stefans_libs/MyProject/PHASE_outfile/LIST_SUMMARY.pm \
	  lib/stefans_libs/chromosome_ripper/gbFileMerger.pm blib/lib/stefans_libs/chromosome_ripper/gbFileMerger.pm \
	  lib/stefans_libs/doc/evaluation/plotGFF_Files_HMM.html blib/lib/stefans_libs/doc/evaluation/plotGFF_Files_HMM.html 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/database/publications/Authors_list.pm blib/lib/stefans_libs/database/publications/Authors_list.pm \
	  lib/stefans_libs/plot/fixed_values_axis.pm blib/lib/stefans_libs/plot/fixed_values_axis.pm \
	  lib/stefans_libs/sequence_modification/ClusterBuster.pm blib/lib/stefans_libs/sequence_modification/ClusterBuster.pm \
	  lib/stefans_libs/database/hybInfoDB.pm blib/lib/stefans_libs/database/hybInfoDB.pm \
	  lib/stefans_libs/database/array_TStat.pm blib/lib/stefans_libs/database/array_TStat.pm \
	  lib/stefans_libs/array_analysis/correlatingData.pm blib/lib/stefans_libs/array_analysis/correlatingData.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_BdIt-2.1.6.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_BdIt-2.1.6.ttf \
	  lib/stefans_libs/database/experiment/partizipatingSubjects.pm blib/lib/stefans_libs/database/experiment/partizipatingSubjects.pm \
	  lib/stefans_libs/array_analysis/Rbridge.pm blib/lib/stefans_libs/array_analysis/Rbridge.pm \
	  lib/stefans_libs/statistics/HMM/marcowChain.pm blib/lib/stefans_libs/statistics/HMM/marcowChain.pm \
	  lib/stefans_libs/array_analysis/outputFormater/dataRep.pm blib/lib/stefans_libs/array_analysis/outputFormater/dataRep.pm \
	  lib/stefans_libs/array_analysis/correlatingData/KruskalWallisTest.pm blib/lib/stefans_libs/array_analysis/correlatingData/KruskalWallisTest.pm \
	  lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm blib/lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/gffFile.pm \
	  lib/stefans_libs/database/expression_estimate/expr_est_list.pm blib/lib/stefans_libs/database/expression_estimate/expr_est_list.pm \
	  lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotype.pm blib/lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotype.pm \
	  lib/stefans_libs/database/genomeDB/gene_description/gene_aliases.pm blib/lib/stefans_libs/database/genomeDB/gene_description/gene_aliases.pm \
	  lib/stefans_libs/Latex_Document/Chapter.pm blib/lib/stefans_libs/Latex_Document/Chapter.pm \
	  lib/stefans_libs/sequence_modification/blastLine.pm blib/lib/stefans_libs/sequence_modification/blastLine.pm \
	  lib/stefans_libs/database/subjectTable/phenotype/binary_multi.pm blib/lib/stefans_libs/database/subjectTable/phenotype/binary_multi.pm \
	  lib/stefans_libs/database/expression_net/expression_net_data.pm blib/lib/stefans_libs/database/expression_net/expression_net_data.pm \
	  lib/stefans_libs/database/dataset_registration.pm blib/lib/stefans_libs/database/dataset_registration.pm \
	  lib/stefans_libs/database/Affymetrix_expression_lib.pm blib/lib/stefans_libs/database/Affymetrix_expression_lib.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/array_analysis/dataRep/hapMap_phase.pm blib/lib/stefans_libs/array_analysis/dataRep/hapMap_phase.pm \
	  lib/stefans_libs/V_segment_summaryBlot/oligoBinReport.pm blib/lib/stefans_libs/V_segment_summaryBlot/oligoBinReport.pm \
	  lib/Statistics/R/Bridge.pm blib/lib/Statistics/R/Bridge.pm \
	  lib/stefans_libs/array_analysis/correlatingData/SpearmanTest.pm blib/lib/stefans_libs/array_analysis/correlatingData/SpearmanTest.pm \
	  lib/stefans_libs/doc/fastaFile.html blib/lib/stefans_libs/doc/fastaFile.html \
	  lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotypeList.pm blib/lib/stefans_libs/array_analysis/dataRep/hapMap_phase/haplotypeList.pm \
	  lib/stefans_libs/doc/NimbleGene_config.html blib/lib/stefans_libs/doc/NimbleGene_config.html \
	  lib/stefans_libs/file_readers/plink/ped_file.pm blib/lib/stefans_libs/file_readers/plink/ped_file.pm \
	  lib/stefans_libs/database/storage_table.pm blib/lib/stefans_libs/database/storage_table.pm \
	  lib/stefans_libs/database/nucleotide_array/oligoDB.pm blib/lib/stefans_libs/database/nucleotide_array/oligoDB.pm \
	  lib/stefans_libs/database/WGAS/SNP_calls.pm blib/lib/stefans_libs/database/WGAS/SNP_calls.pm \
	  lib/stefans_libs/database/external_files.pm blib/lib/stefans_libs/database/external_files.pm \
	  lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm blib/lib/stefans_libs/file_readers/stat_results/KruskalWallisTest_result.pm \
	  lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm blib/lib/stefans_libs/file_readers/stat_results/Wilcoxon_signed_rank_Test_result.pm \
	  lib/stefans_libs/database/system_tables/thread_helper.pm blib/lib/stefans_libs/database/system_tables/thread_helper.pm \
	  lib/stefans_libs/tableHandling.pm blib/lib/stefans_libs/tableHandling.pm \
	  lib/stefans_libs/doc/sequence_modification/blastResult.html blib/lib/stefans_libs/doc/sequence_modification/blastResult.html \
	  lib/stefans_libs/database/scientistTable/action_groups.pm blib/lib/stefans_libs/database/scientistTable/action_groups.pm \
	  lib/stefans_libs/database/genomeDB/genomeImporter.pm blib/lib/stefans_libs/database/genomeDB/genomeImporter.pm \
	  lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm blib/lib/stefans_libs/V_segment_summaryBlot/oligoBin.pm \
	  lib/stefans_libs/database/DeepSeq/genes.pm blib/lib/stefans_libs/database/DeepSeq/genes.pm \
	  lib/stefans_libs/doc/nimbleGeneFiles/pairFile.html blib/lib/stefans_libs/doc/nimbleGeneFiles/pairFile.html \
	  lib/stefans_libs/singleLinePlotHMM.pm blib/lib/stefans_libs/singleLinePlotHMM.pm \
	  lib/stefans_libs/database/external_files/file_list.pm blib/lib/stefans_libs/database/external_files/file_list.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm blib/lib/stefans_libs/V_segment_summaryBlot/selected_regions_dataRow.pm \
	  lib/stefans_libs/database/sequenome_data/sequenome_assays.pm blib/lib/stefans_libs/database/sequenome_data/sequenome_assays.pm \
	  lib/stefans_libs/histogram_container.pm blib/lib/stefans_libs/histogram_container.pm \
	  lib/Statistics/R/Bridge/Win32.pm blib/lib/Statistics/R/Bridge/Win32.pm \
	  lib/Statistics/R.pm blib/lib/Statistics/R.pm \
	  lib/stefans_libs/database/sampleTable/sample_types.pm blib/lib/stefans_libs/database/sampleTable/sample_types.pm \
	  delete.pl $(INST_LIB)/delete.pl \
	  lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm blib/lib/stefans_libs/database/DeepSeq/genes/gene_names_list.pm \
	  lib/stefans_libs/statistics/HMM/logHistogram.pm blib/lib/stefans_libs/statistics/HMM/logHistogram.pm \
	  lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm blib/lib/stefans_libs/database/genomeDB/genomeImporter/NCBI_genome_Readme.pm \
	  lib/stefans_libs/file_readers/affymerix_snp_description.pm blib/lib/stefans_libs/file_readers/affymerix_snp_description.pm \
	  lib/stefans_libs/database/system_tables/LinkList/object_list.pm blib/lib/stefans_libs/database/system_tables/LinkList/object_list.pm \
	  lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm blib/lib/stefans_libs/V_segment_summaryBlot/GFF_data_Y_axis.pm \
	  lib/stefans_libs/doc/chromosome_ripper/seq_contig.html blib/lib/stefans_libs/doc/chromosome_ripper/seq_contig.html \
	  lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm blib/lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/X_feature.pm \
	  lib/stefans_libs/sequence_modification/ssake_info.pm blib/lib/stefans_libs/sequence_modification/ssake_info.pm \
	  lib/stefans_libs/database/LabBook.pm blib/lib/stefans_libs/database/LabBook.pm \
	  lib/stefans_libs/database/scientistTable.pm blib/lib/stefans_libs/database/scientistTable.pm \
	  lib/stefans_libs/database/PubMed_queries.pm blib/lib/stefans_libs/database/PubMed_queries.pm \
	  lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis.pm blib/lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis.pm \
	  lib/stefans_libs/doc/sequence_modification/imgtFile.html blib/lib/stefans_libs/doc/sequence_modification/imgtFile.html \
	  lib/stefans_libs/nimbleGeneFiles/gffFile.pm blib/lib/stefans_libs/nimbleGeneFiles/gffFile.pm \
	  lib/stefans_libs/XY_Evaluation.pm blib/lib/stefans_libs/XY_Evaluation.pm \
	  lib/stefans_libs/statistics/HMM/probabilityFunction.pm blib/lib/stefans_libs/statistics/HMM/probabilityFunction.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm blib/lib/stefans_libs/database/variable_table/linkage_info/table_script_generator.pm \
	  lib/stefans_libs/database/pathways/kegg/kegg_pathway.pm blib/lib/stefans_libs/database/pathways/kegg/kegg_pathway.pm \
	  lib/stefans_libs/file_readers/affymerix_snp_data.pm blib/lib/stefans_libs/file_readers/affymerix_snp_data.pm \
	  lib/stefans_libs/doc/database/hybInfoDB.html blib/lib/stefans_libs/doc/database/hybInfoDB.html \
	  lib/stefans_libs/database/publications/Authors.pm blib/lib/stefans_libs/database/publications/Authors.pm \
	  lib/stefans_libs/database/wish_list.pm blib/lib/stefans_libs/database/wish_list.pm \
	  lib/stefans_libs/plot/dimensionTest.pl blib/lib/stefans_libs/plot/dimensionTest.pl \
	  lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/enrichedRegions.pm blib/lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/enrichedRegions.pm \
	  lib/stefans_libs/doc/database/cellTypeDB.html blib/lib/stefans_libs/doc/database/cellTypeDB.html \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_BdIt-2.2.7.ttf \
	  lib/stefans_libs/multiLinePlot/multilineXY_axis.pm blib/lib/stefans_libs/multiLinePlot/multilineXY_axis.pm \
	  lib/stefans_libs/database/antibodyDB.pm blib/lib/stefans_libs/database/antibodyDB.pm \
	  lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis_with_NuclPos.pm blib/lib/stefans_libs/V_segment_summaryBlot/gbFile_X_axis_with_NuclPos.pm \
	  lib/stefans_libs/sequence_modification/deepSeq_region.pm blib/lib/stefans_libs/sequence_modification/deepSeq_region.pm \
	  lib/stefans_libs/database/sequenome_data.pm blib/lib/stefans_libs/database/sequenome_data.pm \
	  lib/stefans_libs/array_analysis/correlatingData/stat_test.pm blib/lib/stefans_libs/array_analysis/correlatingData/stat_test.pm \
	  lib/stefans_libs/database/system_tables/errorTable.pm blib/lib/stefans_libs/database/system_tables/errorTable.pm \
	  lib/stefans_libs/database/genomeDB/chromosomesTable.pm blib/lib/stefans_libs/database/genomeDB/chromosomesTable.pm \
	  lib/stefans_libs/doc/pod2htmd.tmp blib/lib/stefans_libs/doc/pod2htmd.tmp \
	  lib/stefans_libs/database/experiment.pm blib/lib/stefans_libs/database/experiment.pm \
	  lib/stefans_libs/multiLinePlot/multiline_gb_Axis.pm blib/lib/stefans_libs/multiLinePlot/multiline_gb_Axis.pm \
	  lib/stefans_libs/database/pathways/kegg/kegg_genes.pm blib/lib/stefans_libs/database/pathways/kegg/kegg_genes.pm \
	  lib/stefans_libs/histogram.pm blib/lib/stefans_libs/histogram.pm \
	  lib/stefans_libs/doc/gbFile/gbRegion.html blib/lib/stefans_libs/doc/gbFile/gbRegion.html 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/exec_helper/XML_handler.pm blib/lib/stefans_libs/exec_helper/XML_handler.pm \
	  lib/stefans_libs/database/LabBook/LabBook_instance.pm blib/lib/stefans_libs/database/LabBook/LabBook_instance.pm \
	  lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm blib/lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls.pm \
	  lib/stefans_libs/file_readers/plink.pm blib/lib/stefans_libs/file_readers/plink.pm \
	  lib/stefans_libs/database/sampleTable.pm blib/lib/stefans_libs/database/sampleTable.pm \
	  lib/stefans_libs/database/project_table.pm blib/lib/stefans_libs/database/project_table.pm \
	  lib/stefans_libs/Latex_Document.pm blib/lib/stefans_libs/Latex_Document.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf \
	  lib/stefans_libs/normalize/quantilNormalization.pm blib/lib/stefans_libs/normalize/quantilNormalization.pm \
	  lib/stefans_libs/database/publications/PubMed_list.pm blib/lib/stefans_libs/database/publications/PubMed_list.pm \
	  lib/stefans_libs/database/system_tables/LinkList.pm blib/lib/stefans_libs/database/system_tables/LinkList.pm \
	  lib/stefans_libs/database/array_dataset.pm blib/lib/stefans_libs/database/array_dataset.pm \
	  lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/test.pl blib/lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis/test.pl \
	  lib/stefans_libs/doc/sequence_modification/primer.html blib/lib/stefans_libs/doc/sequence_modification/primer.html \
	  lib/stefans_libs/database/system_tables/passwords.pm blib/lib/stefans_libs/database/system_tables/passwords.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.ttf \
	  lib/stefans_libs/doc/sequence_modification/primerList.html blib/lib/stefans_libs/doc/sequence_modification/primerList.html \
	  lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine-2.1.9.dfont blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine-2.1.9.dfont \
	  lib/stefans_libs/plot/multi_axis.pm blib/lib/stefans_libs/plot/multi_axis.pm \
	  lib/stefans_libs/binaryEvaluation/VbinaryEvauation.pm blib/lib/stefans_libs/binaryEvaluation/VbinaryEvauation.pm \
	  lib/stefans_libs/array_analysis/group3D_MatrixEntries.pm blib/lib/stefans_libs/array_analysis/group3D_MatrixEntries.pm \
	  lib/stefans_libs/file_readers/sequenome/resultsFile.pm blib/lib/stefans_libs/file_readers/sequenome/resultsFile.pm \
	  lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm blib/lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm blib/lib/stefans_libs/MyProject/PHASE_outfile/BESTPAIRS_SUMMARY.pm \
	  lib/stefans_libs/statistics/GetCategoryOfTI.pl blib/lib/stefans_libs/statistics/GetCategoryOfTI.pl \
	  lib/stefans_libs/database/experimentTypes.pm blib/lib/stefans_libs/database/experimentTypes.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/ChangeLog.txt blib/lib/stefans_libs/fonts/LinLibertineFont/ChangeLog.txt \
	  lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm blib/lib/stefans_libs/MyProject/Allele_2_Phenotype_correlator.pm \
	  lib/stefans_libs/doc/chromosome_ripper/gbFileMerger.html blib/lib/stefans_libs/doc/chromosome_ripper/gbFileMerger.html \
	  lib/stefans_libs/doc/database/oligo2dnaDB.html blib/lib/stefans_libs/doc/database/oligo2dnaDB.html \
	  lib/stefans_libs/doc/database/designDB.html blib/lib/stefans_libs/doc/database/designDB.html \
	  lib/stefans_libs/chromosome_ripper/seq_contig.pm blib/lib/stefans_libs/chromosome_ripper/seq_contig.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LaTex/LibertineInConTeXt.txt blib/lib/stefans_libs/fonts/LinLibertineFont/LaTex/LibertineInConTeXt.txt \
	  lib/stefans_libs/file_readers/MeDIP_results.pm blib/lib/stefans_libs/file_readers/MeDIP_results.pm \
	  lib/stefans_libs/database/tissueTable.pm blib/lib/stefans_libs/database/tissueTable.pm \
	  lib/stefans_libs/database/dataset.sql blib/lib/stefans_libs/database/dataset.sql \
	  lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_Bd-2.1.6.dfont blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/LinLibertine_Bd-2.1.6.dfont \
	  lib/stefans_libs/database/lists/list_using_table.pm blib/lib/stefans_libs/database/lists/list_using_table.pm \
	  lib/stefans_libs/plot/xy_graph_withHistograms.pm blib/lib/stefans_libs/plot/xy_graph_withHistograms.pm \
	  lib/stefans_libs/doc/gbFile/gbFeature.html blib/lib/stefans_libs/doc/gbFile/gbFeature.html \
	  lib/stefans_libs/database/variable_table/linkage_info.pm blib/lib/stefans_libs/database/variable_table/linkage_info.pm \
	  lib/stefans_libs/array_analysis/correlatingData/chi_square.pm blib/lib/stefans_libs/array_analysis/correlatingData/chi_square.pm \
	  lib/stefans_libs/evaluation/tableLine.pm blib/lib/stefans_libs/evaluation/tableLine.pm \
	  lib/stefans_libs/doc/sequence_modification/imgtFeature.html blib/lib/stefans_libs/doc/sequence_modification/imgtFeature.html \
	  lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot/alleleFreq.pm blib/lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot/alleleFreq.pm \
	  lib/stefans_libs/file_readers/stat_results/Spearman_result.pm blib/lib/stefans_libs/file_readers/stat_results/Spearman_result.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/database/sampleTable/sample_list.pm blib/lib/stefans_libs/database/sampleTable/sample_list.pm \
	  lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm blib/lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays.pm \
	  lib/stefans_libs/database/system_tables/loggingTable.pm blib/lib/stefans_libs/database/system_tables/loggingTable.pm \
	  lib/stefans_libs/database/genomeDB/SNP_table.pm blib/lib/stefans_libs/database/genomeDB/SNP_table.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.otf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.otf \
	  lib/stefans_libs/plot/figure.pm blib/lib/stefans_libs/plot/figure.pm \
	  lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm blib/lib/stefans_libs/database/DeepSeq/lib_organizer/exon_list.pm \
	  lib/stefans_libs/database/system_tables/roles.pm blib/lib/stefans_libs/database/system_tables/roles.pm \
	  lib/stefans_libs/SNP_2_Gene_Expression.pm blib/lib/stefans_libs/SNP_2_Gene_Expression.pm \
	  lib/stefans_libs/database/subjectTable/phenotype/continuose_mono.pm blib/lib/stefans_libs/database/subjectTable/phenotype/continuose_mono.pm \
	  lib/stefans_libs/array_analysis/correlatingData/R_glm.pm blib/lib/stefans_libs/array_analysis/correlatingData/R_glm.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_Bd-2.1.8.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_Bd-2.1.8.ttf \
	  lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm blib/lib/stefans_libs/plot/Chromosomes_plot/chromosomal_histogram.pm \
	  lib/stefans_libs/doc/statistics/UMS.html blib/lib/stefans_libs/doc/statistics/UMS.html \
	  lib/stefans_libs/plot/color.pm blib/lib/stefans_libs/plot/color.pm \
	  lib/stefans_libs/statistics/statisticItem.pm blib/lib/stefans_libs/statistics/statisticItem.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Readme blib/lib/stefans_libs/fonts/LinLibertineFont/Readme \
	  lib/stefans_libs/array_analysis/dataRep/oligo2DNA_table.pm blib/lib/stefans_libs/array_analysis/dataRep/oligo2DNA_table.pm \
	  lib/stefans_libs/WWW_Reader/pubmed_search.pm blib/lib/stefans_libs/WWW_Reader/pubmed_search.pm \
	  lib/stefans_libs/database/subjectTable/phenotype/binary_mono.pm blib/lib/stefans_libs/database/subjectTable/phenotype/binary_mono.pm \
	  lib/stefans_libs/doc/gbFile.html blib/lib/stefans_libs/doc/gbFile.html \
	  lib/stefans_libs/database/genomeDB/gene_description/genes_of_importance.pm blib/lib/stefans_libs/database/genomeDB/gene_description/genes_of_importance.pm \
	  lib/stefans_libs/database/creaturesTable/familyTree.pm blib/lib/stefans_libs/database/creaturesTable/familyTree.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/sequence_modification/primerList.pm blib/lib/stefans_libs/sequence_modification/primerList.pm \
	  lib/stefans_libs/statistics/statisticItemList.pm blib/lib/stefans_libs/statistics/statisticItemList.pm \
	  lib/stefans_libs/fastaFile.pm blib/lib/stefans_libs/fastaFile.pm \
	  lib/stefans_libs/sequence_modification/primer.pm blib/lib/stefans_libs/sequence_modification/primer.pm \
	  lib/stefans_libs/statistics/HMM.pm blib/lib/stefans_libs/statistics/HMM.pm \
	  lib/stefans_libs/qantilTest.pl blib/lib/stefans_libs/qantilTest.pl \
	  lib/stefans_libs/file_readers/sequenome/resultFile/report.pm blib/lib/stefans_libs/file_readers/sequenome/resultFile/report.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_R-2.1.0.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_R-2.1.0.ttf \
	  lib/stefans_libs/database/DeepSeq/lib_organizer/exons.pm blib/lib/stefans_libs/database/DeepSeq/lib_organizer/exons.pm \
	  lib/stefans_libs/doc/sequence_modification/imgtFeatureDB.html blib/lib/stefans_libs/doc/sequence_modification/imgtFeatureDB.html \
	  lib/stefans_libs/database/cellTypeDB.pm blib/lib/stefans_libs/database/cellTypeDB.pm \
	  lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm blib/lib/stefans_libs/database/nucleotide_array/oligo2dnaDB.pm \
	  lib/stefans_libs/file_readers/PPI_text_file.pm blib/lib/stefans_libs/file_readers/PPI_text_file.pm \
	  lib/stefans_libs/binaryEvaluation/VbinElement.pm blib/lib/stefans_libs/binaryEvaluation/VbinElement.pm \
	  lib/stefans_libs/r_Birdge/testR.pl blib/lib/stefans_libs/r_Birdge/testR.pl \
	  lib/stefans_libs/database/publications/Journals.pm blib/lib/stefans_libs/database/publications/Journals.pm \
	  lib/stefans_libs/plot/gbAxis.pm blib/lib/stefans_libs/plot/gbAxis.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH-2.1.8.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH-2.1.8.ttf \
	  lib/stefans_libs/V_segment_summaryBlot/SubPlot_element.pm blib/lib/stefans_libs/V_segment_summaryBlot/SubPlot_element.pm \
	  lib/stefans_libs/doc/designImporter.html blib/lib/stefans_libs/doc/designImporter.html \
	  lib/stefans_libs/database/WGAS.pm blib/lib/stefans_libs/database/WGAS.pm \
	  lib/stefans_libs/database/sequenome_data/sequenome_chips.pm blib/lib/stefans_libs/database/sequenome_data/sequenome_chips.pm \
	  lib/stefans_libs/doc/statistics/MAplot.html blib/lib/stefans_libs/doc/statistics/MAplot.html \
	  lib/stefans_libs/database/sequenome_data/sequenome_quality.pm blib/lib/stefans_libs/database/sequenome_data/sequenome_quality.pm \
	  lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm blib/lib/stefans_libs/database/array_dataset/Affy_SNP_array/affy_cell_flatfile.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/database/subjectTable.pm blib/lib/stefans_libs/database/subjectTable.pm \
	  lib/stefans_libs/nimbleGeneFiles/pairFile.pm blib/lib/stefans_libs/nimbleGeneFiles/pairFile.pm \
	  lib/stefans_libs/database/oligo2dna_register.pm blib/lib/stefans_libs/database/oligo2dna_register.pm \
	  lib/stefans_libs/database/materials/materialList.pm blib/lib/stefans_libs/database/materials/materialList.pm \
	  lib/stefans_libs/database/expression_net.pm blib/lib/stefans_libs/database/expression_net.pm \
	  lib/stefans_libs/doc/evaluation/summaryLine.html blib/lib/stefans_libs/doc/evaluation/summaryLine.html \
	  lib/stefans_libs/database/system_tables/jobTable.pm blib/lib/stefans_libs/database/system_tables/jobTable.pm \
	  lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm blib/lib/stefans_libs/file_readers/CoExpressionDescription/KEGG_results.pm \
	  lib/stefans_libs/database/system_tables/executable_table.pm blib/lib/stefans_libs/database/system_tables/executable_table.pm \
	  lib/stefans_libs/doc/evaluation/GBpict.html blib/lib/stefans_libs/doc/evaluation/GBpict.html \
	  lib/stefans_libs/gbFile.pm blib/lib/stefans_libs/gbFile.pm \
	  lib/stefans_libs/plot/simpleXYgraph.pm blib/lib/stefans_libs/plot/simpleXYgraph.pm \
	  lib/stefans_libs/V_segment_summaryBlot/NEW_GFF_data_Y_axis.pm blib/lib/stefans_libs/V_segment_summaryBlot/NEW_GFF_data_Y_axis.pm \
	  lib/stefans_libs/database/creaturesTable.pm blib/lib/stefans_libs/database/creaturesTable.pm \
	  lib/stefans_libs/statistics/new_histogram.pm blib/lib/stefans_libs/statistics/new_histogram.pm \
	  lib/stefans_libs/database/array_dataset/oligo_array_values.pm blib/lib/stefans_libs/database/array_dataset/oligo_array_values.pm \
	  lib/stefans_libs/file_readers/CoExpressionDescription.pm blib/lib/stefans_libs/file_readers/CoExpressionDescription.pm \
	  lib/stefans_libs/database/genomeDB/genomeSearchResult.pm blib/lib/stefans_libs/database/genomeDB/genomeSearchResult.pm \
	  lib/stefans_libs/plot/legendPlot.pm blib/lib/stefans_libs/plot/legendPlot.pm \
	  lib/stefans_libs/plot/axis.pm blib/lib/stefans_libs/plot/axis.pm \
	  lib/stefans_libs/singleLinePlot.pm blib/lib/stefans_libs/singleLinePlot.pm \
	  lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm blib/lib/stefans_libs/array_analysis/outputFormater/arraySorter.pm \
	  lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm blib/lib/stefans_libs/database/LabBook/figure_table/subfigure_list.pm \
	  lib/stefans_libs/graphical_Nucleosom_density/nuclDataRow.pm blib/lib/stefans_libs/graphical_Nucleosom_density/nuclDataRow.pm \
	  lib/stefans_libs/database/system_tables/PluginRegister.pm blib/lib/stefans_libs/database/system_tables/PluginRegister.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/sequence_modification/blastResult.pm blib/lib/stefans_libs/sequence_modification/blastResult.pm \
	  lib/stefans_libs/multiLinePlot/multiLineLable.pm blib/lib/stefans_libs/multiLinePlot/multiLineLable.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_It-2.1.6.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/LinLibertineH_It-2.1.6.ttf \
	  lib/stefans_libs/statistics/HMM/UMS.pm blib/lib/stefans_libs/statistics/HMM/UMS.pm \
	  lib/stefans_libs/plot.pm blib/lib/stefans_libs/plot.pm \
	  lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm blib/lib/stefans_libs/database/genomeDB/genomeImporter/seq_contig.pm \
	  lib/stefans_libs/database/variable_table/queryInterface.pm blib/lib/stefans_libs/database/variable_table/queryInterface.pm \
	  lib/stefans_libs/database/variable_table.pm blib/lib/stefans_libs/database/variable_table.pm \
	  lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm blib/lib/stefans_libs/MyProject/compare_SNP_2_Gene_expression_results.pm \
	  lib/stefans_libs/importHyb.pm blib/lib/stefans_libs/importHyb.pm \
	  lib/stefans_libs/doc/statistics/statisticItemList.html blib/lib/stefans_libs/doc/statistics/statisticItemList.html \
	  lib/stefans_libs/file_readers/plink/bim_file.pm blib/lib/stefans_libs/file_readers/plink/bim_file.pm \
	  lib/stefans_libs/database/scientistTable/action_group_list.pm blib/lib/stefans_libs/database/scientistTable/action_group_list.pm \
	  lib/stefans_libs/plot/simpleWhiskerPlot.pm blib/lib/stefans_libs/plot/simpleWhiskerPlot.pm \
	  lib/stefans_libs/database/lists/basic_list.pm blib/lib/stefans_libs/database/lists/basic_list.pm \
	  lib/stefans_libs/sequence_modification/imgtFile.pm blib/lib/stefans_libs/sequence_modification/imgtFile.pm \
	  lib/stefans_libs/normlize/normalizeGFFvalues.pm blib/lib/stefans_libs/normlize/normalizeGFFvalues.pm \
	  lib/stefans_libs/statistics/HMM/UMS_EnrichmentFactors.pm blib/lib/stefans_libs/statistics/HMM/UMS_EnrichmentFactors.pm \
	  lib/stefans_libs/database/genomeDB/gbFilesTable.pm blib/lib/stefans_libs/database/genomeDB/gbFilesTable.pm \
	  lib/stefans_libs/database/scientistTable/roles.pm blib/lib/stefans_libs/database/scientistTable/roles.pm \
	  lib/stefans_libs/statistics/HMM/state_values.pm blib/lib/stefans_libs/statistics/HMM/state_values.pm \
	  lib/stefans_libs/fastaDB.pm blib/lib/stefans_libs/fastaDB.pm \
	  lib/stefans_libs/database/scientistTable/scientificComunity.pm blib/lib/stefans_libs/database/scientistTable/scientificComunity.pm \
	  lib/stefans_libs/statistics/HMM/UMS_old.pm blib/lib/stefans_libs/statistics/HMM/UMS_old.pm \
	  lib/stefans_libs/V_segment_summaryBlot/hmmReportEntry.pm blib/lib/stefans_libs/V_segment_summaryBlot/hmmReportEntry.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/doc/nimbleGeneFiles/gffFile.html blib/lib/stefans_libs/doc/nimbleGeneFiles/gffFile.html \
	  lib/stefans_libs/sequence_modification/imgtFeatureDB.pm blib/lib/stefans_libs/sequence_modification/imgtFeatureDB.pm \
	  lib/stefans_libs/statistics/newGFFtoSignalMap.pm blib/lib/stefans_libs/statistics/newGFFtoSignalMap.pm \
	  lib/stefans_libs/doc/evaluation/evaluateHMM_data.html blib/lib/stefans_libs/doc/evaluation/evaluateHMM_data.html \
	  lib/stefans_libs/NimbleGene_config.pm blib/lib/stefans_libs/NimbleGene_config.pm \
	  lib/stefans_libs/Latex_Document/gene_description.pm blib/lib/stefans_libs/Latex_Document/gene_description.pm \
	  lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm blib/lib/stefans_libs/database/fulfilledTask/fulfilledTask_handler.pm \
	  lib/stefans_libs/statistics/gnuplotParser.pm blib/lib/stefans_libs/statistics/gnuplotParser.pm \
	  lib/stefans_libs/doc/database/antibodyDB.html blib/lib/stefans_libs/doc/database/antibodyDB.html \
	  lib/stefans_libs/doc/sequence_modification/inverseBlastHit.html blib/lib/stefans_libs/doc/sequence_modification/inverseBlastHit.html \
	  lib/stefans_libs/array_analysis/correlatingData/Wilcox_Test.pm blib/lib/stefans_libs/array_analysis/correlatingData/Wilcox_Test.pm \
	  lib/stefans_libs/db_report/plottable_gbFile.pm blib/lib/stefans_libs/db_report/plottable_gbFile.pm \
	  lib/stefans_libs/database/publications/PubMed.pm blib/lib/stefans_libs/database/publications/PubMed.pm \
	  lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm blib/lib/stefans_libs/V_segment_summaryBlot/gbFeature_X_axis.pm \
	  lib/stefans_libs/database/designDB.pm blib/lib/stefans_libs/database/designDB.pm \
	  lib/stefans_libs/evaluation/evaluateHMM_data.pm blib/lib/stefans_libs/evaluation/evaluateHMM_data.pm \
	  lib/stefans_libs/plot/simpleBarGraph.pm blib/lib/stefans_libs/plot/simpleBarGraph.pm \
	  lib/stefans_libs/database/expression_estimate/expr_est.pm blib/lib/stefans_libs/database/expression_estimate/expr_est.pm \
	  lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/rs_dataset.pm blib/lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/rs_dataset.pm \
	  lib/stefans_libs/doc/database/array_TStat.html blib/lib/stefans_libs/doc/database/array_TStat.html \
	  lib/stefans_libs/database/system_tables/PluginRegister/exportables.pm blib/lib/stefans_libs/database/system_tables/PluginRegister/exportables.pm \
	  lib/stefans_libs/doc/importHyb.html blib/lib/stefans_libs/doc/importHyb.html \
	  lib/stefans_libs/database/pathways/kegg/hypergeometric_max_hits.pm blib/lib/stefans_libs/database/pathways/kegg/hypergeometric_max_hits.pm \
	  lib/stefans_libs/gbFile/gbHeader.pm blib/lib/stefans_libs/gbFile/gbHeader.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/database/genomeDB.pm blib/lib/stefans_libs/database/genomeDB.pm \
	  lib/stefans_libs/doc/evaluation/tableLine.html blib/lib/stefans_libs/doc/evaluation/tableLine.html \
	  lib/stefans_libs/file_readers/stat_results.pm blib/lib/stefans_libs/file_readers/stat_results.pm \
	  lib/stefans_libs/doc/gbFile/gbHeader.html blib/lib/stefans_libs/doc/gbFile/gbHeader.html \
	  lib/stefans_libs/database/scientistTable/PW_table.pm blib/lib/stefans_libs/database/scientistTable/PW_table.pm \
	  lib/stefans_libs/sequence_modification/deepSeq_blastLine.pm blib/lib/stefans_libs/sequence_modification/deepSeq_blastLine.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Mac/README-MAC.txt blib/lib/stefans_libs/fonts/LinLibertineFont/Mac/README-MAC.txt \
	  lib/stefans_libs/fonts/LinLibertineFont/Gehintet/README-hinted blib/lib/stefans_libs/fonts/LinLibertineFont/Gehintet/README-hinted \
	  lib/stefans_libs/array_analysis/outputFormater/sortOrderTest.pl blib/lib/stefans_libs/array_analysis/outputFormater/sortOrderTest.pl \
	  lib/stefans_libs/database/subjectTable/phenotype/continuose_multi.pm blib/lib/stefans_libs/database/subjectTable/phenotype/continuose_multi.pm \
	  lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm blib/lib/stefans_libs/statistics/HMM/HMM_hypothesis.pm \
	  lib/stefans_libs/axis_template.txt blib/lib/stefans_libs/axis_template.txt \
	  lib/stefans_libs/database/system_tables/workingTable.pm blib/lib/stefans_libs/database/system_tables/workingTable.pm \
	  lib/stefans_libs/database/DeepSeq/genes/gene_names.pm blib/lib/stefans_libs/database/DeepSeq/genes/gene_names.pm \
	  lib/stefans_libs/multiLinePlot/simple_multiline_gb_Axis.pm blib/lib/stefans_libs/multiLinePlot/simple_multiline_gb_Axis.pm \
	  lib/stefans_libs/database.pm blib/lib/stefans_libs/database.pm \
	  lib/stefans_libs/database/DeepSeq/lib_organizer.pm blib/lib/stefans_libs/database/DeepSeq/lib_organizer.pm \
	  lib/stefans_libs/sequence_modification/imgtFeature.pm blib/lib/stefans_libs/sequence_modification/imgtFeature.pm \
	  lib/stefans_libs/Latex_Document/Figure.pm blib/lib/stefans_libs/Latex_Document/Figure.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LICENCE.txt blib/lib/stefans_libs/fonts/LinLibertineFont/LICENCE.txt \
	  lib/stefans_libs/designImporter.pm blib/lib/stefans_libs/designImporter.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.otf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.otf \
	  lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm blib/lib/stefans_libs/MyProject/ModelBasedGeneticAnalysis.pm \
	  lib/stefans_libs/doc/histogram.html blib/lib/stefans_libs/doc/histogram.html 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/SNP_cluster.pm blib/lib/stefans_libs/array_analysis/dataRep/affy_geneotypeCalls/SNP_cluster.pm \
	  lib/stefans_libs/doc/statistics/statisticItem.html blib/lib/stefans_libs/doc/statistics/statisticItem.html \
	  lib/stefans_libs/database/array_Hyb.pm blib/lib/stefans_libs/database/array_Hyb.pm \
	  lib/stefans_libs/flexible_data_structures/data_table.pm blib/lib/stefans_libs/flexible_data_structures/data_table.pm \
	  lib/stefans_libs/database/WGAS/rsID_2_SNP.pm blib/lib/stefans_libs/database/WGAS/rsID_2_SNP.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LaTex/README-TEX.txt blib/lib/stefans_libs/fonts/LinLibertineFont/LaTex/README-TEX.txt \
	  lib/stefans_libs/database/genomeDB/db_xref_table.pm blib/lib/stefans_libs/database/genomeDB/db_xref_table.pm \
	  lib/stefans_libs/plot/plottable_gbFile.pm blib/lib/stefans_libs/plot/plottable_gbFile.pm \
	  lib/stefans_libs/array_analysis/outputFormater/XY_withHistograms.pm blib/lib/stefans_libs/array_analysis/outputFormater/XY_withHistograms.pm \
	  lib/stefans_libs/file_readers/phenotypes.pm blib/lib/stefans_libs/file_readers/phenotypes.pm \
	  lib/stefans_libs/statistics/HMM_EnrichmentFactors.pm blib/lib/stefans_libs/statistics/HMM_EnrichmentFactors.pm \
	  lib/stefans_libs/database/hypothesis_table.pm blib/lib/stefans_libs/database/hypothesis_table.pm \
	  lib/stefans_libs/array_analysis/tableHandling.pm blib/lib/stefans_libs/array_analysis/tableHandling.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_Bd-2.1.0.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertineU_Bd-2.1.0.ttf \
	  lib/stefans_libs/file_readers/affymetrix_expression_result.pm blib/lib/stefans_libs/file_readers/affymetrix_expression_result.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.otf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_It-2.3.0.otf \
	  lib/stefans_libs/MyProject/PHASE_outfile.pm blib/lib/stefans_libs/MyProject/PHASE_outfile.pm \
	  lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm blib/lib/stefans_libs/array_analysis/dataRep/Nimblegene_GeneInfo.pm \
	  lib/stefans_libs/Latex_Document/Text.pm blib/lib/stefans_libs/Latex_Document/Text.pm \
	  lib/stefans_libs/database/materials/materialsTable.pm blib/lib/stefans_libs/database/materials/materialsTable.pm \
	  lib/stefans_libs/sequence_modification/inverseBlastHit.pm blib/lib/stefans_libs/sequence_modification/inverseBlastHit.pm \
	  lib/Statistics/R/Bridge/Linux.pm blib/lib/Statistics/R/Bridge/Linux.pm \
	  lib/stefans_libs/normalize/normalizeGFFvalues.pm blib/lib/stefans_libs/normalize/normalizeGFFvalues.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/database/genomeDB/ROI_table.pm blib/lib/stefans_libs/database/genomeDB/ROI_table.pm \
	  lib/stefans_libs/multiLinePlot/multiline_HMM_Axis.pm blib/lib/stefans_libs/multiLinePlot/multiline_HMM_Axis.pm \
	  lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm blib/lib/stefans_libs/database/DeepSeq/lib_organizer/splice_isoforms.pm \
	  lib/stefans_libs/database/Protein_Expression/gene_ids.pm blib/lib/stefans_libs/database/Protein_Expression/gene_ids.pm \
	  lib/stefans_libs/multiLinePlot.pm blib/lib/stefans_libs/multiLinePlot.pm \
	  lib/stefans_libs/sequence_modification/imgt2gb.pm blib/lib/stefans_libs/sequence_modification/imgt2gb.pm \
	  lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot.pm blib/lib/stefans_libs/array_analysis/dataRep/affy_SNP_annot.pm \
	  lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm blib/lib/stefans_libs/database/genomeDB/nucleosomePositioning.pm \
	  lib/stefans_libs/multiLinePlot/XYvalues.pm blib/lib/stefans_libs/multiLinePlot/XYvalues.pm \
	  lib/stefans_libs/database/subjectTable/phenotype/familyHistory.pm blib/lib/stefans_libs/database/subjectTable/phenotype/familyHistory.pm \
	  lib/stefans_libs/doc/database/array_Hyb.html blib/lib/stefans_libs/doc/database/array_Hyb.html \
	  lib/stefans_libs/database/experiment/hypothesis.pm blib/lib/stefans_libs/database/experiment/hypothesis.pm \
	  lib/stefans_libs/database/expression_estimate/probesets_table.pm blib/lib/stefans_libs/database/expression_estimate/probesets_table.pm \
	  lib/stefans_libs/evaluation/probTest.pl blib/lib/stefans_libs/evaluation/probTest.pl \
	  lib/stefans_libs/V_segment_summaryBlot/NEW_Summary_GFF_Y_axis.pm blib/lib/stefans_libs/V_segment_summaryBlot/NEW_Summary_GFF_Y_axis.pm \
	  lib/stefans_libs/file_readers/stat_results/base_class.pm blib/lib/stefans_libs/file_readers/stat_results/base_class.pm \
	  lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm blib/lib/stefans_libs/V_segment_summaryBlot/pictureLayout.pm \
	  lib/stefans_libs/database/to_do_list.pm blib/lib/stefans_libs/database/to_do_list.pm \
	  lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm blib/lib/stefans_libs/database/expression_estimate/CEL_file_storage.pm \
	  lib/stefans_libs/file_readers/UCSC_ens_Gene.pm blib/lib/stefans_libs/file_readers/UCSC_ens_Gene.pm \
	  lib/stefans_libs/statistics/HMM/marcowModel.pm blib/lib/stefans_libs/statistics/HMM/marcowModel.pm \
	  lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm blib/lib/stefans_libs/database/nucleotide_array/nimbleGeneArrays/nimbleGeneFiles/ndfFile.pm \
	  lib/stefans_libs/.dat.oligoIDs.dat blib/lib/stefans_libs/.dat.oligoIDs.dat 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  plot_differences_4_gene_SNP_comparisons.pl $(INST_LIB)/plot_differences_4_gene_SNP_comparisons.pl \
	  lib/stefans_libs/testBins/xy_test.pl blib/lib/stefans_libs/testBins/xy_test.pl \
	  lib/stefans_libs/file_readers/svg_pathway_description.pm blib/lib/stefans_libs/file_readers/svg_pathway_description.pm \
	  lib/stefans_libs/doc/statistics/HMM.html blib/lib/stefans_libs/doc/statistics/HMM.html \
	  lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm blib/lib/stefans_libs/database/nucleotide_array/Affymetrix_SNP_arrays/affy_SNP_info.pm \
	  lib/stefans_libs/file_readers/expression_net_reader.pm blib/lib/stefans_libs/file_readers/expression_net_reader.pm \
	  lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm blib/lib/stefans_libs/database/array_dataset/NimbleGene_Chip_on_chip/pairFile.pm \
	  lib/stefans_libs/database/nucleotide_array.pm blib/lib/stefans_libs/database/nucleotide_array.pm \
	  lib/stefans_libs/doc/sequence_modification/blastLine.html blib/lib/stefans_libs/doc/sequence_modification/blastLine.html \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Re-2.3.2.ttf \
	  lib/stefans_libs/database/organismDB.pm blib/lib/stefans_libs/database/organismDB.pm \
	  lib/stefans_libs/plot/Font.pm blib/lib/stefans_libs/plot/Font.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/Bugs blib/lib/stefans_libs/fonts/LinLibertineFont/Bugs \
	  lib/stefans_libs/doc/pod2htmi.tmp blib/lib/stefans_libs/doc/pod2htmi.tmp \
	  lib/stefans_libs/database/fulfilledTask.pm blib/lib/stefans_libs/database/fulfilledTask.pm \
	  lib/stefans_libs/database/script.sql blib/lib/stefans_libs/database/script.sql \
	  lib/stefans_libs/database/ROI_registration.pm blib/lib/stefans_libs/database/ROI_registration.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.ttf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.ttf \
	  lib/stefans_libs/multiLinePlot/ruler_x_axis.pm blib/lib/stefans_libs/multiLinePlot/ruler_x_axis.pm \
	  lib/stefans_libs/V_segment_summaryBlot.pm blib/lib/stefans_libs/V_segment_summaryBlot.pm \
	  lib/stefans_libs/database/subjectTable/phenotype/ph_age.pm blib/lib/stefans_libs/database/subjectTable/phenotype/ph_age.pm \
	  lib/stefans_libs/statistics/MAplot.pm blib/lib/stefans_libs/statistics/MAplot.pm \
	  lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm blib/lib/stefans_libs/database/genomeDB/gbFeaturesTable.pm \
	  lib/stefans_libs/testBins/Testplot.pl blib/lib/stefans_libs/testBins/Testplot.pl \
	  lib/stefans_libs/doc/createHTMP_help.pl blib/lib/stefans_libs/doc/createHTMP_help.pl 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/fonts/LinLibertineFont-2.3.2.tgz blib/lib/stefans_libs/fonts/LinLibertineFont-2.3.2.tgz \
	  lib/stefans_libs/plot/densityMap.pm blib/lib/stefans_libs/plot/densityMap.pm \
	  lib/stefans_libs/database/oligo2dnaDB.pm blib/lib/stefans_libs/database/oligo2dnaDB.pm \
	  lib/stefans_libs/WebSearch/Googel_Search.pm blib/lib/stefans_libs/WebSearch/Googel_Search.pm \
	  lib/stefans_libs/database/array_calculation_results.pm blib/lib/stefans_libs/database/array_calculation_results.pm \
	  lib/stefans_libs/.dat blib/lib/stefans_libs/.dat \
	  lib/stefans_libs/database/grant_table.pm blib/lib/stefans_libs/database/grant_table.pm \
	  lib/stefans_libs/array_analysis/regression_models/linear_regression.pm blib/lib/stefans_libs/array_analysis/regression_models/linear_regression.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.otf blib/lib/stefans_libs/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.otf \
	  lib/stefans_libs/array_analysis/template4deepEvaluation.pm blib/lib/stefans_libs/array_analysis/template4deepEvaluation.pm \
	  lib/stefans_libs/sequence_modification/testInversBlastHit.pl blib/lib/stefans_libs/sequence_modification/testInversBlastHit.pl \
	  lib/stefans_libs/fonts/LinLibertineFont/GPL.txt blib/lib/stefans_libs/fonts/LinLibertineFont/GPL.txt \
	  lib/stefans_libs/doc/database/array_GFF.html blib/lib/stefans_libs/doc/database/array_GFF.html \
	  lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm blib/lib/stefans_libs/MyProject/GeneticAnalysis/Model.pm \
	  lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm blib/lib/stefans_libs/database/genomeDB/genbank_flatfile_db.pm \
	  lib/stefans_libs/fonts/LinLibertineFont/OFL.txt blib/lib/stefans_libs/fonts/LinLibertineFont/OFL.txt \
	  lib/stefans_libs/nimbleGeneFiles/ndfFile.pm blib/lib/stefans_libs/nimbleGeneFiles/ndfFile.pm \
	  lib/stefans_libs/database/system_tables/LinkList/www_object_table.pm blib/lib/stefans_libs/database/system_tables/LinkList/www_object_table.pm \
	  lib/stefans_libs/evaluation/summaryLine.pm blib/lib/stefans_libs/evaluation/summaryLine.pm \
	  lib/stefans_libs/database/system_tables/configuration.pm blib/lib/stefans_libs/database/system_tables/configuration.pm \
	  lib/stefans_libs/database/expression_estimate/Affy_description.pm blib/lib/stefans_libs/database/expression_estimate/Affy_description.pm \
	  lib/stefans_libs/database/subjectTable/phenotype_registration.pm blib/lib/stefans_libs/database/subjectTable/phenotype_registration.pm \
	  lib/stefans_libs/graphical_Nucleosom_density/nucleotidePositioningData.pm blib/lib/stefans_libs/graphical_Nucleosom_density/nucleotidePositioningData.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/stefans_libs/doc/sequence_modification/imgt2gb.html blib/lib/stefans_libs/doc/sequence_modification/imgt2gb.html \
	  lib/stefans_libs/doc/nimbleGeneFiles/ndfFile.html blib/lib/stefans_libs/doc/nimbleGeneFiles/ndfFile.html \
	  lib/stefans_libs/doc/root.html blib/lib/stefans_libs/doc/root.html \
	  lib/stefans_libs/database/array_dataset/genotype_calls.pm blib/lib/stefans_libs/database/array_dataset/genotype_calls.pm \
	  lib/stefans_libs/database/expression_estimate.pm blib/lib/stefans_libs/database/expression_estimate.pm \
	  lib/stefans_libs/sequence_modification/deepSequencingRegion.pm blib/lib/stefans_libs/sequence_modification/deepSequencingRegion.pm 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
# Postamble by Module::Install 0.81
# --- Module::Install::AutoInstall section:

config :: installdeps
	$(NOECHO) $(NOOP)

checkdeps ::
	$(PERL) Makefile.PL --checkdeps

installdeps ::
	$(PERL) Makefile.PL --config= --installdeps=WWW::Search::NCBI::PubMed,0,Archive::Zip,0,megablast,0,formatdb,0

