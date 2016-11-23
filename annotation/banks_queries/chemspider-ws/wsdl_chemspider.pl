#!perl

## script  : wsdl_chemspider.pl
#=============================================================================
#                              Included modules and versions
#=============================================================================
## Perl modules
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;

use Data::Dumper ;
use Getopt::Long ;
use POSIX ;
use FindBin ; ## Allows you to locate the directory of original perl script

## PFEM Perl Modules
use conf::conf  qw( :ALL ) ;
use formats::csv  qw( :ALL ) ;
use formats::json  qw( :ALL ) ;
use logs::logtools  qw( :ALL ) ;

## Specific Modules
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::chemspider_api qw( :ALL ) ;

## Initialized values
my ( $help ) = ( undef ) ;
my ( $mass ) = ( undef ) ;
my ( $masses_file, $col_id, $col_mass, $line_header ) = ( undef, undef, undef, undef ) ;
my ( $delta, $molecular_species, $out_tab, $out_html, $out_xls ) = ( undef, undef, undef, undef, undef ) ;

## SOAP Adress for chemspider :
#http://www.chemspider.com/MassSpecAPI.asmx?WSDL

my ( $verbose ) = ( 1 ) ; ## verbose level is 3 for debugg, default is 1.

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
				"output:s"		=> \$out_tab, ## option : path to the ouput (tabular : input+results )
				"view:s"		=> \$out_html, ## option : path to the results view (output2)
				"verbose:s"		=> \$verbose,
#				"outputXls:s"	=> \$out_xls, ## option : path to the results xls view (output3)
            ) ;
         
## if you put the option -help or -h function help is started
$help and &help ;

#=============================================================================
#                                MAIN SCRIPT
#=============================================================================

my ( $json, $string ) = ( undef, undef ) ;
my ( $masses, $ids ) = ( undef, undef ) ;
my ( $complete_rows, $nb_pages_for_html_out ) = ( undef, undef ) ;

my $ostarttime = logs::logtools->new() ;
my $start_time = $ostarttime->get_duration('START') ;


## -------------- Conf file ------------------------ :
my ( $CONF ) = ( undef ) ;
foreach my $conf ( <$binPath/*.cfg> ) {
	my $oConf = conf::conf::new() ;
	$CONF = $oConf->as_conf($conf) ;
}


## manage only one mass
if ( ( defined $mass ) and ( $mass ne "" ) and ( $mass =~ /[,]+/ ) ) {
	my $i = 0 ;
	my @mz = split(/,/, $mass ) ;
	$masses = \@mz ;
	foreach  ( @{$masses} ) { push (@{$ids}, 'comp'.$i) ; $i++ ; }
	
	my $ochemspider = lib::chemspider_api->new() ;
	$string = $ochemspider->chemspider_exe($CONF->{EXE}, $delta, $mass, undef, $CONF->{JSON_TMP}) ;
	
	
} ## END IF
elsif ( ( defined $mass ) and ( $mass ne "" ) and ( $mass > 0 ) ) {
	# fill ref arrays
	$ids = ['comp0'] ;
	$masses = [$mass] ;
	
	my $ochemspider = lib::chemspider_api->new() ;
	$string = $ochemspider->chemspider_exe($CONF->{EXE}, $delta, $mass, undef, $CONF->{JSON_TMP}) ;
	
} ## END IF
## manage csv file containing list of masses (every thing is manage in jar)
elsif ( ( defined $masses_file ) and ( $masses_file ne "" ) and ( -e $masses_file ) ) {
	
	## parse all csv for later : output csv build
	my $ocsv_input  = formats::csv->new() ;
	my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
	$complete_rows = $ocsv_input->parse_csv_object($complete_csv, \$masses_file) ;
	
	## parse csv ids and masses
	my $is_header = undef ;
	my $ocsv = formats::csv->new() ;
	my $csv = $ocsv->get_csv_object( "\t" ) ;
	if ( ( defined $line_header ) and ( $line_header > 0 ) ) { $is_header = 'yes' ;    }
	$masses = $ocsv->get_value_from_csv( $csv, $masses_file, $col_mass, $is_header ) ; ## retrieve mz values on csv
	$ids = $ocsv->get_value_from_csv( $csv, $masses_file, $col_id, $is_header ) ; ## retrieve ids values on csv
	
	my $ochemspider = lib::chemspider_api->new() ;
	$string = $ochemspider->chemspider_exe($CONF->{EXE}, $delta, undef, $masses_file, $col_mass, $col_id, $line_header ) ;
}
else {
	croak "No argt for masses : file doesn't exist or mass is not defined\n" ;
}

## Mapping JSON to PERL scalar
if ( defined $string ) {
#	print Dumper $string ;
	## open and read it
	my $ojson = formats::json->new() ;	
	$json = $ojson->decode_json_stdout($string) ;
}
else {
	croak "Can't create outputs, no results send by WS\n" ;
}

## -------------- Produce HTML/CSV output ------------------ :
my ( $tbody_object, $chemspider_matrix ) = ( undef, undef ) ;
if ( ( defined $out_html ) and ( defined $json ) ) {
	
	$nb_pages_for_html_out = ceil( scalar( @{$masses} ) / $CONF->{HTML_ENTRIES_PER_PAGE} )  ;
	
	my $oHtml = lib::chemspider_api->new() ;
	($tbody_object) = $oHtml->set_html_tbody_object($nb_pages_for_html_out, $CONF->{HTML_ENTRIES_PER_PAGE} ) ;
	($tbody_object) = $oHtml->add_mz_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $ids) ;
	($tbody_object) = $oHtml->add_entries_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $ids, $json, $CONF->{'URL_CHEMSPIDER'}) ;
	my $output_html = $oHtml->write_html_skel(\$out_html, $tbody_object, $nb_pages_for_html_out, $CONF->{'HTML_TEMPLATE'}, $CONF->{'JS_GALAXY_PATH'}, $CONF->{'CSS_GALAXY_PATH'} ) ;
	
} ## END IF
else {
	croak "Can't create a HTML output for Chemspider : no result found or your output file is not defined\n" ;
}

if ( ( defined $out_tab ) and ( defined $json ) ) {
	# produce a csv based on METLIN format
	my $ocsv = lib::chemspider_api->new() ;
	if (defined $masses_file) {
		if ( ( defined $line_header ) and ( $line_header == 1 ) ) { $chemspider_matrix = $ocsv->set_chemspider_matrix_object('chemspider', $masses, $ids, $json ) ; }
		elsif ( ( defined $line_header ) and ( $line_header == 0 ) ) { $chemspider_matrix = $ocsv->set_chemspider_matrix_object(undef, $masses, $ids, $json ) ; }
		$chemspider_matrix = $ocsv->add_chemspider_matrix_to_input_matrix($complete_rows, $chemspider_matrix) ;
		$ocsv->write_csv_skel(\$out_tab, $chemspider_matrix) ;
	}
	elsif (defined $mass) {
		$ocsv->write_csv_one_mass($masses, $ids, $json, $out_tab) ;
	}
} ## END IF
else {
	croak "Can't create a tabular output for Chemspider : no result found or your output file is not defined\n" ;
}

## Manage end time
my $ostoptime = logs::logtools->new() ;
my $duration_time = $ostoptime->get_duration('STOP', $start_time) ;

## -------------- Manage verbose ------------------ :
print "\n--->Argvts received by wrapper $0 :\n\t" if $verbose == 3 ;
#print Dumper  if $verbose == 3 ;
print "\n--->Masses submitted:\n\t" if $verbose == 3 ;
print Dumper $masses if $verbose == 3 ;
print "\n--->Ids submitted:\n\t" if $verbose == 3 ;
print Dumper $ids if $verbose == 3 ;
print "\n--->JSON containing:\n\t" if $verbose == 3 ;
print Dumper $json if $verbose == 3 ;
print "\n--->Tbody for html output containing:\n\t" if $verbose == 3 ;
print Dumper $tbody_object if $verbose == 3 ;
print "\n--->Matrix for csv output containing:\n\t" if $verbose == 3 ;
print Dumper $chemspider_matrix if $verbose == 3 ;
print "\n-----------------------------------\nDuration of script : $$duration_time seconds... \n" if $verbose == 3 ;

#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
	print STDERR "
wsdl_chemspider.pl

# wsdl_chemspider is a script to identify mass/masses on chemspider database webservices
# Input : an exact mass or a tabular file with a list of masses
# Author : Franck Giacomoni, Nils Paulhe and Marion Landi
# Email : fgiacomoni\@clermont.inra.fr or mlandi\@clermont.inra.fr or nils.paulhe\@clermont.inra.fr
# Version : 1.0
# Created : 01/04/2014
USAGE :		 
		wsdl_chemspider.pl -h or
		
		wsdl_chemspider.pl 
		
		* mandatory:
			-delta [delta : Must be smaller than 1e-03 for ChemSpider]
			-output [tabular ouput file]
			-view [HTML ouput file]
			-ouputXls [ouput file for XLS]
		
		* optionnal:
		
			-mass [MY_EXACT_MASS] or
			-masses [MY_TSV_FILE with ids and masses colunms]
			-colid
			-colfactor
			-lineheader
		
		";
	exit(1);
}

## END of script - F Giacomoni 

__END__

=head1 NAME

wsdl_chemspider.pl -- script for identification of mass/masses on chemspider database webservices.

=head1 USAGE

 		wsdl_chemspider.pl -h or
		
		wsdl_chemspider.pl 
		
		* mandatory:
			-delta [delta : Must be smaller than 1e-03 for ChemSpider ]
			-output [tabular ouput file]
			-view [HTML ouput file]
			-ouputXls [ouput file for XLS]
		
		* optionnal:
		
			-mass [MY_EXACT_MASS] or
			-masses [MY_TSV_FILE with ids and masses colunms]
			-colid
			-colfactor
			-lineheader

=head1 SYNOPSIS

This script manage queries on ws chemspider database.

=head1 DESCRIPTION

This main program is a wrapper for a internal tool called metabolomicBankWs : a java implementation of several banks web services.
You can download all sources on : www.pfem.clermont.inra.fr 

=over 4

=item B<function01>

=item B<function02>

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>
Marion Landi E<lt>marion.landi@clermont.inra.frE<gt>
Nils Paulhe E<lt>nils.paulhe@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 10 / 04 / 2014

=cut