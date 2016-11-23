#!perl

## script  : wsdl_hmdb.pl
#=============================================================================
#                              Included modules and versions
#=============================================================================
## Perl modules
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;

use Data::Dumper ;
use Getopt::Long ;
use Text::CSV ;
use POSIX ;
use FindBin ; ## Permet de localisez le repertoire du script perl d'origine

## PFEM Perl Modules
use conf::conf  qw( :ALL ) ;
use formats::csv  qw( :ALL ) ;

## Specific Modules
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::hmdb qw( :ALL ) ;

## Initialized values
my ( $help ) = undef ;
my ( $mass ) = undef ;
my ( $masses_file, $col_id, $col_mass, $line_header ) = ( undef, undef, undef, undef ) ;
my ( $delta, $molecular_species, $out_tab, $out_html ) = ( undef, undef, undef, undef ) ;

## FOR TEST : with masses_file
#( $masses_file, $delta, $molecular_species, $col_id, $col_mass, $line_header ) = ( 'E:\\TESTs\\galaxy\\hmdb\\ex_HR_set10entries_with_formula_and_header.txt', 0.05, 'neutral', 1, 2, 0 ) ;

## with a only one mass
#( $mass, $delta, $molecular_species ) = ( 160.081 , 0.5, 'neutral' ) ; 

#( $out_tab, $out_html ) = ('E:\\TESTs\\galaxy\\hmdb\\results_hmdb.txt', 'E:\\TESTs\\galaxy\\hmdb\\results_hmdb.html') ; ## 2d case

#=============================================================================
#                                Manage EXCEPTIONS
#=============================================================================

&GetOptions ( 	"h"     		=> \$help,       # HELP
				"masses:s"		=> \$masses_file, ## option : path to the input
				"colid:i"		=> \$col_id, ## Column id for retrieve formula/masses list in tabular file
				"colfactor:i"	=> \$col_mass, ## Column id for retrieve formula list in tabular file
				"lineheader:i"	=> \$line_header, ## header presence in tabular file
				"mass:s"		=> \$mass, ## option : one masse
				"delta:f"		=> \$delta,
				"mode:s"		=> \$molecular_species, ## Molecular species (positive/negative/neutral) 
				"output|o:s"	=> \$out_tab, ## option : path to the ouput (tabular : input+results )
				"view|v:s"		=> \$out_html, ## option : path to the results view (output2)
            ) ;

#=============================================================================
#                                EXCEPTIONS
#=============================================================================
$help and &help ;

#=============================================================================
#                                MAIN SCRIPT
#=============================================================================


## -------------- Conf file ------------------------ :
my ( $CONF ) = ( undef ) ;
foreach my $conf ( <$binPath/*.cfg> ) {
	my $oConf = conf::conf::new() ;
	$CONF = $oConf->as_conf($conf) ;
}

## --------------- Global parameters ---------------- :
my ( $ids, $masses, $results ) = ( undef, undef, undef ) ;
my ( $complete_rows, $nb_pages_for_html_out ) = ( undef, 1 ) ;
my $search_condition = "Search params : Molecular specie = $molecular_species / delta = $delta" ;

## --------------- retrieve input data -------------- :

## manage only one mass
if ( ( defined $mass ) and ( $mass ne "" ) and ( $mass > 0 ) ) {
	$ids = ['mass_01'] ;
	$masses = [$mass] ;
	
} ## END IF
## manage csv file containing list of masses
elsif ( ( defined $masses_file ) and ( $masses_file ne "" ) and ( -e $masses_file ) ) {
	## parse all csv for later : output csv build
	my $ocsv_input  = formats::csv->new() ;
	my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
	$complete_rows = $ocsv_input->parse_csv_object($complete_csv, \$masses_file) ;
	
	## parse csv ids and masses
	my $is_header = undef ;
	my $ocsv = formats::csv->new() ;
	my $csv = $ocsv->get_csv_object( "\t" ) ;
	if ( ( defined $line_header ) and ( $line_header > 0 ) ) { $is_header = 'yes' ;	}
	$masses = $ocsv->get_value_from_csv( $csv, $masses_file, $col_mass, $is_header ) ; ## retrieve mz values on csv
	$ids = $ocsv->get_value_from_csv( $csv, $masses_file, $col_id, $is_header ) ; ## retrieve ids values on csv
}

## ---------------- launch queries -------------------- :

if ( ( defined $delta ) and ( $delta > 0 ) and ( defined $molecular_species ) and ( $molecular_species ne '' ) ) {
	## prepare masses list and execute query
	my $oHmdb = lib::hmdb::new() ;
	my $hmdb_pages = undef ;
	
	## manage two modes
	if (defined $mass) { # manual mode (don't manage more than 150 mz per job)
		$hmdb_pages = $oHmdb->get_matches_from_hmdb_ua($mass, $delta, $molecular_species) ; 
		$results = $oHmdb->parse_hmdb_csv_results($hmdb_pages, $masses) ; ## hash format results
	}
	
	if (defined $masses_file) {
		$results = [] ; # prepare arrays ref
		my $submasses = $oHmdb->extract_sub_mz_lists($masses, $CONF->{HMDB_LIMITS} ) ;
		
		foreach my $mzs ( @{$submasses} ) {
			
			my $result = undef ;
			my ( $hmdb_masses, $nb_masses_to_submit ) = $oHmdb->prepare_multi_masses_query($mzs) ;
			$hmdb_pages = $oHmdb->get_matches_from_hmdb_ua($hmdb_masses, $delta, $molecular_species) ;
			$result = $oHmdb->parse_hmdb_csv_results($hmdb_pages, $mzs) ; ## hash format result
			
			$results = [ @$results, @$result ] ;
		}
	}
	
	## Uses N mz and theirs entries per page (see config file).
	# how many pages you need with your input mz list?
	$nb_pages_for_html_out = ceil( scalar(@{$masses} ) / $CONF->{HTML_ENTRIES_PER_PAGE} )  ;
	
#	print Dumper $results ;
}
else {
	croak "Can't work with HMDB : missing paramaters (list of masses, delta or molecular species)\n" ;
} ## end ELSE

## -------------- Produce HTML/CSV output ------------------ :

if ( ( defined $out_html ) and ( defined $results ) ) {
	my $oHtml = lib::hmdb::new() ;
	my ($tbody_object) = $oHtml->set_html_tbody_object( $nb_pages_for_html_out, $CONF->{HTML_ENTRIES_PER_PAGE} ) ;
	($tbody_object) = $oHtml->add_mz_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $ids) ;
	($tbody_object) = $oHtml->add_entries_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $results) ;
	my $output_html = $oHtml->write_html_skel(\$out_html, $tbody_object, $nb_pages_for_html_out, $search_condition, $CONF->{'HTML_TEMPLATE'}, $CONF->{'JS_GALAXY_PATH'}, $CONF->{'CSS_GALAXY_PATH'}) ;
	
} ## END IF
else {
#	croak "Can't create a HTML output for HMDB : no result found or your output file is not defined\n" ;
}

if ( ( defined $out_tab ) and ( defined $results ) ) {
	# produce a csv based on METLIN format
	my $ocsv = lib::hmdb::new() ;
	if (defined $masses_file) {
		my $lm_matrix = undef ;
		if ( ( defined $line_header ) and ( $line_header == 1 ) ) { $lm_matrix = $ocsv->set_lm_matrix_object('hmdb', $masses, $results ) ; }
		elsif ( ( defined $line_header ) and ( $line_header == 0 ) ) { $lm_matrix = $ocsv->set_lm_matrix_object(undef, $masses, $results ) ; }
		$lm_matrix = $ocsv->add_lm_matrix_to_input_matrix($complete_rows, $lm_matrix) ;
		$ocsv->write_csv_skel(\$out_tab, $lm_matrix) ;
	}
	elsif (defined $mass) {
		$ocsv->write_csv_one_mass($masses, $ids, $results, $out_tab) ;
	}
} ## END IF
else {
#	croak "Can't create a tabular output for HMDB : no result found or your output file is not defined\n" ;
}



#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
	print STDERR "
wsdl_hmdb

# wsdl_hmdb is a script to query HMDB website using chemical formula and return a list of common names.
# Input : formula or list of formula
# Author : Franck Giacomoni
# Email : fgiacomoni\@clermont.inra.fr
# Version : 1.0
# Created : 08/07/2012
USAGE :		 
		wsdl_hmdb.pl -input [path to list of formula file] -f [formula] -output [output file format1] -view [output file format2] -colid [col of id in input file] -colfactor [col of factor] -lineheader [nb of lines containing file header : 0-n]
		
		";
	exit(1);
}

## END of script - F Giacomoni 

__END__

=head1 NAME

 XXX.pl -- script for

=head1 USAGE

 XXX.pl -precursors -arg1 [-arg2] 
 or XXX.pl -help

=head1 SYNOPSIS

This script manage ... 

=head1 DESCRIPTION

This main program is a ...

=over 4

=item B<function01>

=item B<function02>

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : xx / xx / 201x

version 2 : ??

=cut