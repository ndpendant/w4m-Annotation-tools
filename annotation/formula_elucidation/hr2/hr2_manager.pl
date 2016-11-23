#!perl

## script  : hr2_manager.pl
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

## Dedicate Perl Modules (Home made...)
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::hr qw( :ALL ) ;

## Initialized values
use vars qw(%parametre);
my $help = undef ; 
my ( $input_file, $line_header, $col_id, $col_mass ) = ( undef, undef, undef, undef ) ; # manage input option file of masses
my ( $mass ) = ( undef ) ; # manage input option masses list
my ( $tolerance, $mode, $charge, $has_golden_rules, $atomes ) = ( undef, undef, undef, undef, undef ) ; # manage params
my ( $output_csv, $output2, $output3, $output_html ) = ( undef, undef, undef, undef ) ; # manage ouputs

## For test ONLY !!
#( $input_file, $line_header, $col_id, $col_mass ) = ( 'E:\\TESTs\\galaxy\\hr2\\hr2_masses_small_list_without_header.csv', 0, 1, 2 ) ; # manage input option file of masses
#( $mass ) = ( 422.0849114 ) ; # manage input option masses list
#( $tolerance, $mode, $charge, $has_golden_rules, $atomes ) = ( 1.0, 'neutral', 1, 'NO', undef ) ; # manage params
#( $output_csv, $output2, $output3, $output_html ) = ( 'E:\\TESTs\\galaxy\\hr2\\output_csv.csv', undef, undef, 'E:\\TESTs\\galaxy\\hr2\\output_html.html' ) ; # manage ouputs

#=============================================================================
#                                Manage EXCEPTIONS
#=============================================================================
&GetOptions ( 	"h"     		=> 	\$help,       # HELP
				"input:s"		=>	\$input_file,
				"colId:i"		=>	\$col_id,
				"nbHeader:i"	=>	\$line_header,
				"colmass:i"		=>	\$col_mass,
				"masse:s"		=>	\$mass,
				"tolerance:f"	=>	\$tolerance,
				"mode:s"		=>	\$mode,
				"charge:i"		=>	\$charge,
				"regleOr:s"		=>	\$has_golden_rules,
				"atome:s"		=>	\$atomes,
				"output1:s"		=>	\$output_csv,
				"outputView:s"	=>	\$output_html
            ) ;
         
#=============================================================================
#                                EXCEPTIONS
#=============================================================================
$help and &help ;

#=============================================================================
#                                MAIN SCRIPT
#=============================================================================


## -------------- Conf file and verbose ------------------------ :
my ( $CONF, $verbose ) = ( undef, 2 ) ; ## verbose level is 3 for debugg
my $time_start = time ;

foreach my $conf ( <$binPath/*.cfg> ) {
	my $oConf = conf::conf::new() ;
	$CONF = $oConf->as_conf($conf) ;
}
## --------------- Global parameters ---------------- :
my ( $ids, $masses, $hr_cmds, $results, $parsed_results ) = ( undef, undef, undef, undef, undef ) ;
my $complete_rows = undef ;
my ($hr_atoms_list, $hr_atoms_and_ranges, $set_tol, ) = (undef, undef, undef, ) ;

## Check and manage params
my $ohr = lib::hr->new() ;

## set tolerance
$set_tol = $ohr->manage_tolerance( \$tolerance, \$CONF->{'tolerance'} ) ;

## check HR exe envt :
my $hr_check = $ohr->check_hr_exe(\$CONF->{'HR2_EXE'}, \$CONF->{'HR2_VERSION'}) ;
if (!defined $hr_check ) { croak "No hr exe available (wrong path) or wrong version will be used  -- end of script\n" ; }

## manage atoms and their ranges
$hr_atoms_list = $ohr->manage_atoms(\$atomes, \$CONF->{'DEFAULT_ATOMS'}) ;

if ( defined $hr_atoms_list ) {
	## implements range foreach atom
	foreach my $atom ( (split(",", $$hr_atoms_list )) ) {
		my $range_max = $CONF->{'DEFAULT_MAX'} ; # manage max value in case of
		if ( exists $CONF->{$atom} ) 	{ $range_max = $CONF->{$atom} ; }
		my $ref_range = $ohr->manage_atom_and_range(\$atom, \$CONF->{'DEFAULT_MIN'}, \$range_max ) ;
		$hr_atoms_and_ranges .= $$ref_range ; ## concat ranges
	}
}
else { 	croak "No atom detected with input params\n" ; }

## Parsing input file with masses/ids or unik mass :
## manage only one mass
if ( ( defined $mass ) and ( $mass ne "" ) and ( $mass > 0 ) ) {
	$ids = ['mass_01'] ;
	$masses = [$mass] ;
	
} ## END IF
## manage csv file containing list of masses
elsif ( ( defined $input_file ) and ( $input_file ne "" ) and ( -e $input_file ) ) {
	
	## parse all csv for later : output csv build
	my $ocsv_input  = formats::csv->new() ;
	my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
	$complete_rows = $ocsv_input->parse_csv_object($complete_csv, \$input_file) ;
	
	## parse csv ids and masses
	my $is_header = undef ;
	my $ocsv = formats::csv->new() ;
	my $csv = $ocsv->get_csv_object( "\t" ) ;
	if ( ( defined $line_header ) and ( $line_header > 0 ) ) { $is_header = 'yes' ;	}
	$masses = $ocsv->get_value_from_csv( $csv, $input_file, $col_mass, $is_header ) ; ## retrieve mz values on csv
	$ids = $ocsv->get_value_from_csv( $csv, $input_file, $col_id, $is_header ) ; ## retrieve ids values on csv
	
}
else {
	croak "Can't work with HR2 : missing input file or mass (list of masses, ids)\n" ;
} ## end ELSE

## check using golden rules
if ( $has_golden_rules eq 'NO') { $has_golden_rules = undef ; }

## ---------------- launch queries -------------------- :

## prepare cmd
foreach my $mz (@{ $masses }) {
	## computes mass
	my $ohr_mode = lib::hr->new() ;
	my ( $exact_mass ) = $ohr_mode->manage_mode( \$mode, \$charge, \$CONF->{'electron'}, \$CONF->{'proton'}, \$mz ) ;
	print "Current MZ send to HR\n"  if $verbose == 3 ;
	print Dumper $exact_mass if $verbose == 3 ;
	## build exe line
	my $ohr_exe = lib::hr->new() ;
	my $hr_cmd = $ohr_exe->config_hr_exe( \$CONF->{'HR2_EXE'}, \$tolerance, $exact_mass, \$has_golden_rules, \$hr_atoms_and_ranges ) ;
	push(@{$hr_cmds}, $$hr_cmd) ;
}

## MultiThreading execution of Hr :
my $threads = lib::hr->new() ;
my $hr_object = lib::hr->new() ;
if ( $hr_object->can('hr_exe') ) {
	my $method = $hr_object->can('hr_exe') ;
	$results = $threads->threading_hr_exe( $method, $hr_cmds) ;

}

## MultiThreading parsing of Hr outputs :
my $hrres_object = lib::hr->new() ;
if ( $hrres_object->can('hr_out_parser') ) {
	my $method = $hr_object->can('hr_out_parser') ;
	if ( defined $results ) { 	$parsed_results = $threads->threading_hr_exe( $method, $results ) ; }
}

## -------------- Produce HTML/CSV output ------------------ :
my $search_condition = 'Mode used: '.$mode.' / Charge: +'.$charge.' / Mass tolerance: '.$$set_tol.' / Composition: '.$$hr_atoms_list ;
## Uses N mz and theirs entries per page (see config file).
# how many pages you need with your input mz list?
my $nb_pages_for_html_out = ceil( scalar(@{$masses} ) / $CONF->{HTML_ENTRIES_PER_PAGE} )  ;

if ( ( defined $output_html ) and ( defined $parsed_results ) ) {	
	my $oHtml = lib::hr::new() ;
	my ($tbody_object) = $oHtml->set_html_tbody_object( $nb_pages_for_html_out, $CONF->{HTML_ENTRIES_PER_PAGE} ) ;
	($tbody_object) = $oHtml->add_mz_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $ids, $parsed_results ) ;
	($tbody_object) = $oHtml->add_entries_to_tbody_object($tbody_object, $parsed_results) ;
	my $output = $oHtml->write_html_skel(\$output_html, $tbody_object, $nb_pages_for_html_out, $search_condition, $CONF->{'HTML_TEMPLATE'}, $CONF->{'JS_GALAXY_PATH'}, $CONF->{'CSS_GALAXY_PATH'}) ;
	
} ## END IF
else {
	croak "Can't create a HTML output for HMDB : no result found or your output file is not defined\n" ;
}

if ( ( defined $output_csv ) and ( defined $parsed_results ) ) {
	# produce a csv based on METLIN format
	my $ocsv = lib::hr::new() ;
	if (defined $input_file) {
		my $lm_matrix = undef ;
		if ( ( defined $line_header ) and ( $line_header == 1 ) ) { $lm_matrix = $ocsv->set_hr_matrix_object('hr2', $masses, $parsed_results ) ; }
		elsif ( ( defined $line_header ) and ( $line_header == 0 ) ) { $lm_matrix = $ocsv->set_hr_matrix_object(undef, $masses, $parsed_results ) ; }
		$lm_matrix = $ocsv->add_hr_matrix_to_input_matrix($complete_rows, $lm_matrix) ;
		$ocsv->write_csv_skel(\$output_csv, $lm_matrix) ;
	}
	elsif (defined $mass) {
		$ocsv->write_csv_one_mass($masses, $ids, $parsed_results, $output_csv) ;
	}
} ## END IF
else {
#	croak "Can't create a tabular output for HR2 : no result found or your output file is not defined\n" ;
}



### VERBOSE OUTPUTs
if ( $verbose == 3 ) {
	print "-- Conf file contains :\n" ;
	print Dumper $CONF ;
	print "-- Atoms input list :\n" ;
	print Dumper $hr_atoms_list ;
	print "-- HR envt ready  :\n" ;
	print Dumper $hr_check ;
	print "-- Atoms and ranges :\n" ;
	print Dumper $hr_atoms_and_ranges ;
	print "-- Tolerance :\n" ;
	print Dumper $set_tol ;
	print "-- Complete input file :\n" ;
	print Dumper $complete_rows ;
	print "-- Inputs initiales masses :\n" ;
	print Dumper $masses ;
	print "-- Inputs initiales ids :\n" ;
	print Dumper $ids ;
	print "-- Hr_Cmds :\n" ;
	print Dumper $hr_cmds ;
	print "-- Hr_Results :\n" ;
#	print Dumper $results ;
	print "-- Hr_parsed Results :\n" ;
	print Dumper $parsed_results ;
	
	my $nb_results = scalar (@{$results}) ;
	print "-- Hr_Results return  : $nb_results\n" ;
}

my $time_end = time ;
my $seconds = $time_end-$time_start ;
print "\n------  Time used in threaded mode by 6 : $seconds seconds --------\n\n" ;






#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
	print STDERR "
XXX.pl

# XXX is a script to ...
# Input : 
# Author : Franck Giacomoni and Marion Landi
# Email : fgiacomoni\@clermont.inra.fr or mlandi\@clermont.inra.fr
# Version : 1.0
# Created : xx/xx/201x
USAGE :		 
		XXX.pl -options
		
		";
	exit(1);
}

## END of script - F Giacomoni 

__END__

=head1 NAME

 hr2_manager.pl -- script for launch / manage hr2 binary

=head1 USAGE

 hr2_manager.pl  -arg1 [-arg2] 
 or hr2_manager.pl -help

=head1 SYNOPSIS

This script manages hr2 binary which elucids raw formula with exact masses.

=head1 DESCRIPTION

This main program is a ...

=over 4

=item B<function01>

=item B<function02>

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>
Marion Landi E<lt>marion.landi@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 18/07/2012

version 2 : 02/10/2013

version 3 : 20/02/2014

=cut