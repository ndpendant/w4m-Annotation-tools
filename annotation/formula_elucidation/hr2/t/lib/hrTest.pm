package lib::hrTest ;

use diagnostics; # this gives you more debugging information
use warnings;    # this warns you of bad practices
use strict;      # this prevents silly errors
use Exporter ;
use Carp ;

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( manage_atomsTest check_hr_exeTest manage_toleranceTest manage_modeTest );
our %EXPORT_TAGS = ( ALL => [qw(manage_atomsTest check_hr_exeTest manage_toleranceTest manage_modeTest )] );


use lib::hr qw( :ALL ) ;

sub manage_atomsTest {
	
	my ($input_atoms, $conf_atoms, ) = @_ ;
	
	my $oAtom = lib::hr->new() ;
	my $ref_atoms = $oAtom->manage_atoms(\$input_atoms, \$conf_atoms) ;
	my $atoms = $$ref_atoms ;
	
	return ($atoms) ;
}

sub check_hr_exeTest {
	my ( $hr_path, $hr_version ) = @_ ;
	my $oHr = lib::hr->new() ;
	my $res = $oHr->check_hr_exe(\$hr_path, \$hr_version) ;
	
	return ($res) ;
}

sub manage_toleranceTest {
	my ( $tolerance, $default_value ) = @_ ;
	my $oHr = lib::hr->new() ;
	my $tol = $oHr->manage_tolerance( \$tolerance, \$default_value ) ;
	return ($$tol) ;
}

sub manage_modeTest {
	my ( $mode, $charge, $electron, $proton, $mass ) = @_ ;
	my $oHr = lib::hr->new() ;
	my $exact_mass = $oHr->manage_mode( \$mode, \$charge, \$electron, \$proton, \$mass ) ;
	return ($$exact_mass) ;
}




1 ;