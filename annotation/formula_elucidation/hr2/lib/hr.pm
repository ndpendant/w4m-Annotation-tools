package lib::hr ;

use strict;
no strict "refs" ;
use warnings ;
use Exporter ;
use threads ;
use HTML::Template ;
use Carp ;

use Data::Dumper ;

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( manage_atoms check_hr_exe manage_atom_and_range manage_tolerance manage_mode config_hr_exe );
our %EXPORT_TAGS = ( ALL => [qw(manage_atoms check_hr_exe manage_atom_and_range manage_tolerance manage_mode config_hr_exe )] );

=head1 NAME

lib::hr - A module for managing / launching hr binary (structure elucidation c++ progr)

=head1 SYNOPSIS

    use lib::hr;
    my $object = lib::hr->new();
    print $object->as_string;

=head1 DESCRIPTION

This module does not really exist, it
was made for the sole purpose of
demonstrating how POD works.

=head1 METHODS

Methods are :

=head2 METHOD new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my $self={};
    bless($self) ;
    return $self ;
}
### END of SUB
     
=head2 METHOD manage_atoms

	## Description : controles atoms input list and prepare it like hr binary parameter 
	## Input : $input_atoms, $conf_atoms
	## Output : $hr_atoms_param
	## Usage : my ( $hr_atoms_param ) = manage_atoms( $input_atoms, $conf_atoms ) ;
	
=cut
## START of SUB
sub manage_atoms {
	## Retrieve Values
    my $self = shift ;
    my ( $input_atoms, $conf_atoms ) = @_ ;
    my $hr_atoms_param = undef ;
    
    if ( ( defined $$input_atoms ) and ( defined $$conf_atoms )  ) {
    	if ( ( $$input_atoms eq 'None' ) or ( $$input_atoms eq '' ) or ( $$input_atoms eq ' ' ) )	{  $hr_atoms_param =  $$conf_atoms ; 	}
    	elsif ( $$input_atoms =~ /[P|S|F|L|K|B|A|1|,]+/ ) { $hr_atoms_param =  $$conf_atoms.','.$$input_atoms ;  }
    	else 							{  $hr_atoms_param =  $$conf_atoms ;  	}
    } ## END IF
    elsif ( !defined $$input_atoms ) { 	$hr_atoms_param =  $$conf_atoms ; }
    elsif ( !defined $$conf_atoms )  { 	warn "hr module can't manage any atom list (undef values in conf)\n" ; }
    else {						    	warn "hr module musn't manage any atom list\n" ; }
    
    return(\$hr_atoms_param) ;
}
## END of SUB

=head2 METHOD manage_atom_and_range

	## Description : build atom range with defined value in conf file
	## Input : $atom, $min, $max
	## Output : $hr_range
	## Usage : my (  ) = manage_atom_and_range( $atom, $min, $max ) ;
	
=cut
## START of SUB
sub manage_atom_and_range {
	## Retrieve Values
    my $self = shift ;
    my ( $atom, $min, $max ) = @_ ;
    my $hr_range = undef ;
    
    if ( ( defined $$atom ) and ( defined $$min ) and ( defined $$max )  ) {
    	## manage ragne like "-C 0-200"
    	$hr_range = ' -'.$$atom.' '.$$min.'-'.$$max ;
    } ## END IF
    else {
    	warn "Some argvts are missing to build the current atom range line\n" ;
    }    
    return(\$hr_range) ;
}
## END of SUB

=head2 METHOD manage_tolerance

	## Description : check range and format of tolerance
	## Input : $tolerance, $default_value
	## Output : $set_tol
	## Usage : my ( $set_tol ) = manage_tolerance( $tolerance, $default_value ) ;
	
=cut
## START of SUB
sub manage_tolerance {
	## Retrieve Values
    my $self = shift ;
    my ( $tolerance, $default_value ) = @_ ;
    my ($set_tol, $tmp_tol ) = (undef, undef) ;
        
    if ( ( defined $$tolerance ) and ( defined $$default_value )) {
    	$tmp_tol = $$tolerance ;
    	$tmp_tol =~ tr/,/./;
		## tolerance doit etre >0 et <10
		if ( $tmp_tol <= 0 || $tmp_tol >= 10 ){
			$set_tol = $$default_value ;
			warn "The used tolerance is set to $$default_value (out of authorized range)\n" ;
		}
		else{ $set_tol = $tmp_tol ; }
    }
    else { 	warn "Your tolerance or the default tol are not defined\n" ;   }
    
    return(\$set_tol) ;
}
## END of SUB

=head2 METHOD manage_mode

	## Description : manage mode and apply mass correction (positive/negative/neutral)
	## Input : $mode, $charge, $electron, $proton, $mass
	## Output : $exact_mass
	## Usage : my ( $exact_mass ) = manage_mode( $mode, $charge, $electron, $proton, $mass ) ;
	
=cut
## START of SUB
sub manage_mode {
	## Retrieve Values
    my $self = shift ;
    my ( $mode, $charge, $electron, $proton, $mass ) = @_ ;
    my ($exact_mass, $tmp_mass) = ( undef, undef ) ;
    
    ## some explanations :
    	# MS in + mode = adds H+ (proton) and molecule is positive : el+ => $charge = "positive"
		# For HR, need to subtrack proton mz and to add electron mz (1 electron per charge) to the input mass which comes neutral!
    
    if ( ( defined $$electron ) and ( defined $$proton ) ) {
    	# check mass
    	if ( defined $$mass ) {  $tmp_mass = $$mass ;   $tmp_mass =~ tr/,/./ ; } # manage . and , in case of...
    	else {	warn "No mass is defined\n"  	}
    	
    	# manage charge 
    	if ( ( defined $$charge ) and ($$charge == 0) ){ $$charge = 1 ; }
    	elsif ( ( defined $$charge ) and ($$charge > 0) ){  }
    	else {	warn "Charge is not defined or value is ununderstanding\n" ; }
    	
    	# set neutral mass in function of ms mode
    	if($$mode eq 'positive')	{	$exact_mass = (	$tmp_mass*$$charge) - $$proton + ($$charge*$$electron); }
    	elsif($$mode eq 'negative')	{ 	$exact_mass = (	$tmp_mass*$$charge) + $$proton - ($$charge*$$electron); }
    	elsif($$mode eq "neutral")	{	$exact_mass = 	$tmp_mass ;  }
	    else { 	warn "This mode doesn't exist : please select positive/negative or neutral mode\n" ; 	    }
    }
    else {
    	warn "Missing some parameter values (electron, neutron masses), please check your conf file\n" ;
    } 
    return(\$exact_mass) ;
}
## END of SUB

=head2 METHOD check_hr_exe

	## Description : permit to check the path of hr.exe and its full availability
	## Input : $hr_path, $hr_version
	## Output : true/false
	## Usage : my ( $res ) = check_hr_exe( $hr_path, $hr_version ) ;
	
=cut
## START of SUB
sub check_hr_exe {
	## Retrieve Values
    my $self = shift ;
    my ( $hr_path, $hr_version ) = @_ ;
    my $success = undef ;
    my $check_res = undef ;
    
    ## test path :
    if ( ( defined $$hr_path ) and ( defined $$hr_version ) ) {
   		if ( -e $$hr_path ) {
   			$success = `$$hr_path -version`;
   			if ($success !~/^$$hr_version/) { 	warn "You do not use the expected version of hr2 ($$hr_version)\n" ;  }
   			else { 								$check_res = 1 ; }
   		}
    	else { warn "Can't use HR because the binary file doesn't exist at the specified path ($$hr_path)\n" ; }
    	
    } ## END IF
    else { 	warn "No HR path or Hr version defined\n" ;   }
    
    return($check_res) ;
}
## END of SUB

=head2 METHOD config_hr_exe

	## Description : builds hr execute line with needed params
	## Input : $hr_path, $hr_delta, $mass, $has_goldenrules, $atoms_and_ranks
	## Output : var2
	## Usage : my ( var2 ) = config_hr_exe( $hr_path, $hr_delta, $mass, $has_goldenrules, $atoms_and_ranks ) ;
	
=cut
## START of SUB
sub config_hr_exe {
	## Retrieve Values
    my $self = shift ;
    my ( $hr_path, $hr_delta, $mass, $has_goldenrules, $atoms_and_ranks ) = @_ ;
    my $hr_cmd = undef ;
    
    if ( ( defined $$hr_path ) and ( defined $$hr_delta ) and ( defined $$mass ) and ( defined $$atoms_and_ranks )  ) {
    	$hr_cmd = $$hr_path.' -t '.$$hr_delta.' -m '.$$mass.' '.$$atoms_and_ranks ;
    	if ( defined $$has_goldenrules ) { 	$$hr_cmd .= ' -g ' ;   	}
    } ## END IF
    else { 	warn "Some argvts are missing to build the current hr exec line\n" ; }
    
    return(\$hr_cmd) ;
}
## END of SUB

=head2 METHOD threading_hr_exe

	## Description : prepare 5 threads for hr executing
	## Input : $method, $list
	## Output : $results
	## Usage : my ( $results ) = threading_hr_exe( $method, $list ) ;
	
=cut
## START of SUB
sub threading_hr_exe {
	## Retrieve Values
    my $self = shift ;
    my ( $method, $list ) = @_ ;
    
    my @results = () ;
    
    if ( ( defined $list ) and ( defined $method )) {
    	
    	for (my $i = 0; $i < (scalar @{$list}); $i+=6 ) {
			my $thr1 = threads->create($method, $self, $list->[$i]) if $list->[$i] ;
			my $thr2 = threads->create($method, $self, $list->[$i+1]) if $list->[$i+1] ;
			my $thr3 = threads->create($method, $self, $list->[$i+2]) if $list->[$i+2] ;
			my $thr4 = threads->create($method, $self, $list->[$i+3]) if $list->[$i+3] ;
			my $thr5 = threads->create($method, $self, $list->[$i+4]) if $list->[$i+4] ;
			my $thr6 = threads->create($method, $self, $list->[$i+5]) if $list->[$i+5] ;
			push ( @results, $thr1->join )  if $list->[$i] ;
			push ( @results, $thr2->join ) if $list->[$i+1] ;
			push ( @results, $thr3->join ) if $list->[$i+2] ;
			push ( @results, $thr4->join ) if $list->[$i+3] ;
			push ( @results, $thr5->join ) if $list->[$i+4] ;
			push ( @results, $thr6->join ) if $list->[$i+5] ;
		}
    }
    else {
    	warn "Your input list or your method is undefined\n" ;
    }
    
    return(\@results) ;
}
## END of SUB

=head2 METHOD hr_exe

	## Description : hr_exe launches hr and catches result
	## Input : $cmd
	## Output : $res
	## Usage : my ( $res ) = hr_exe( $cmd ) ;
	
=cut
## START of SUB
sub hr_exe {
	## Retrieve Values
    my $self = shift ;
    my ( $cmd ) = @_ ;
    my $res = undef ;
	
	if (defined $cmd){
		#print "\n--CMD used : $cmd\n" ;
		$res = `$cmd` ;
		sleep(0.5) ;
		#print "Results : $res\n" ;
	}

	return (\$res) ;
}
## END of SUB


=head2 METHOD hr_out_parser

	## Description : parse output of hr and return a hash of features
	## Input : $res
	## Output : $parsed_res
	## Usage : my ( $parsed_res ) = hr_out_parser( $res ) ;
	
=cut
## START of SUB
sub hr_out_parser {
	## Retrieve Values
    my $self = shift ;
    my ( $res ) = @_ ;
    
    my %parsed_res = () ;
    my ( @formula, @rings_and_double_bond_equivalents, @formula_mz, @mmus ) = ( (), (), (), () ) ;
    my ( $formula_nb, $formula_total, $time ) = ( undef, undef, undef ) ;
    
    if ( defined $$res ) {
    	# foreach line
    	foreach my $line (split(/\n/,$$res)){
    		## v1.02 - parse result line "C7.H17.N5.		2.0	171.1484	+17.2 mmu"
    		## v1.03 - parse result line "C10.H25.N5.O5.P2.S2.    C10H25N5O5P2S2  8.00    421.0772333     0       0       +0.40"
    		## $1 = "C10.H25.N5.O5.P2.S2. " 	$2 = "C10H25N5O5P2S2" 	$3 = "8.00"		$4="421.0772333"	$5="0"	$6="0"	$7="+0.40"
    		## if ( $line =~ /([\w|\.]+)\s+(\d+.?\d*)\s+(\d+.?\d*)\s+([+|-]\d+.?\d*)\s+(.*)/ ) { ## for hr2 1.02
    		
    		if ( $line =~ /([\w|\.]+)\s+(\w+)\s+(\d+.?\d*)\s+(\d+.?\d*)\s+(\d+.?\d*)\s+(\d+.?\d*)\s+([+|-]\d+.?\d*)/ ) { # for hr2 1.03
    			my ( $formula, $cleanformula, $rings_and_double_bond_equivalent, $formula_mz, $abscharge, $nadd, $mmu_value  ) = ( $1, $2, $3, $4, $5, $6, $7 ) ;
     			
    			if (defined $formula ) 		{ $formula =~ s/\.//g ; 	push (@formula, $formula) ;	} # clean \.
    			if (defined $rings_and_double_bond_equivalent ) {		push (@rings_and_double_bond_equivalents, $rings_and_double_bond_equivalent) ;	} # 
    			if (defined $formula_mz ) 	{ 						 	push (@formula_mz, $formula_mz) ;	}
    			if (defined $mmu_value ) 	{ $mmu_value =~ s/\+// ; 	push (@mmus, $mmu_value) ;	} # clean (+)
    		}
    		elsif (  $line =~ /(\d+)\s+formulas.+\s+(\d+)\s+seconds.+\s+(\d+)\s+formulae/ ) {
    			( $formula_nb, $time, $formula_total  ) = ( $1, $2, $3 ) ;
    		}
    		else {	next;	}
    	}
    	# build parser
    	if ( scalar(@formula) > 0 ){
    		$parsed_res{'ENTRY_FORMULA'} = \@formula ; 
	    	$parsed_res{'rings_and_double_bond_equivalents'} = \@rings_and_double_bond_equivalents ; 
	    	$parsed_res{'ENTRY_CPD_MZ'} = \@formula_mz ; 
	    	$parsed_res{'ENTRY_DELTA'} = \@mmus ; 
	    	$parsed_res{'MASSES_TOTAL'} = \$formula_nb ; 
	    	$parsed_res{'time'} = \$time ;
    	}
    }
    return(\%parsed_res) ;
}
## END of SUB


=head2 METHOD set_html_tbody_object

	## Description : initializes and build the tbody object (perl array) need to html template
	## Input : $nb_pages, $nb_items_per_page
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = set_html_tbody_object($nb_pages, $nb_items_per_page) ;
	
=cut
## START of SUB
sub set_html_tbody_object {
	my $self = shift ;
    my ( $nb_pages, $nb_items_per_page ) = @_ ;

	my ( @tbody_object ) = ( ) ;
	
	for ( my $i = 1 ; $i <= $nb_pages ; $i++ ) {
	    
	    my %pages = ( 
	    	# tbody feature
	    	PAGE_NB => $i,
	    	MASSES => [], ## end MASSES
	    ) ; ## end TBODY N
	    push (@tbody_object, \%pages) ;
	}
    return(\@tbody_object) ;
}
## END of SUB

=head2 METHOD add_mz_to_tbody_object

	## Description : initializes and build the mz object (perl array) need to html template
	## Input : $tbody_object, $nb_items_per_page, $mz_list
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = add_mz_to_tbody_object( $tbody_object, $nb_items_per_page, $mz_list ) ;
	
=cut
## START of SUB
sub add_mz_to_tbody_object {
	my $self = shift ;
    my ( $tbody_object, $nb_items_per_page, $mz_list, $ids_list, $totals ) = @_ ;

	my ( $current_page, $mz_index ) = ( 0, 0 ) ;
	
	foreach my $page ( @{$tbody_object} ) {
		
		my @colors = ('white', 'green') ;
		my ( $current_index, , $icolor ) = ( 0, 0 ) ;
		
		for ( my $i = 1 ; $i <= $nb_items_per_page ; $i++ ) {
			# 
			if ( $current_index > $nb_items_per_page ) { ## manage exact mz per html page
				$current_index = 0 ; 
				last ; ##
			}
			else {
				$current_index++ ;
				if ( $icolor > 1 ) { $icolor = 0 ; }
				
				if ( exists $mz_list->[$mz_index]  ) {
					my $total = \0 ;
					if ( $totals->[$mz_index]{'MASSES_TOTAL'} ) { $total = $totals->[$mz_index]{'MASSES_TOTAL'} }					
					
					my %mz = (
						# mass feature
						MASSES_ID_QUERY => $ids_list->[$mz_index],
						MASSES_MZ_QUERY => $mz_list->[$mz_index],
						MZ_COLOR => $colors[$icolor],
						MASSES_NB => $mz_index+1,
						MASSES_TOTAL => $$total ,
						ENTRIES => [] ,
					) ;
					push ( @{ $tbody_object->[$current_page]{MASSES} }, \%mz ) ;
					# Html attr for mass
					$icolor++ ;
				}
			}
			$mz_index++ ;
		} ## foreach mz

		$current_page++ ;
	}
    return($tbody_object) ;
}
## END of SUB

=head2 METHOD add_entries_to_tbody_object

	## Description : initializes and build the mz object (perl array) need to html template
	## Input : $tbody_object, $nb_items_per_page, $mz_list, $entries
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = add_entries_to_tbody_object( $tbody_object, $nb_items_per_page, $mz_list, $entries ) ;
	
=cut
## START of SUB
sub add_entries_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $tbody_object, $results ) = @_ ;
    
    my $index_page = 0 ;
    my $index_mz_continous = 0 ;
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;
    	
    	foreach my $mz (@{ $tbody_object->[$index_page]{MASSES} }) {
    		
    		my $index_res = 0 ;
    		if ( $results->[$index_mz_continous]{ENTRY_FORMULA} ){
	    			
    			my $entry_nb = scalar( @{ $results->[$index_mz_continous]{ENTRY_FORMULA} } ) ;
    			for( my $i = 0 ; $i<$entry_nb; $i++ ) {
    				my %entry = (
			    		ENTRY_COLOR 	=> $tbody_object->[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
			   			ENTRY_FORMULA 	=> $results->[$index_mz_continous]->{ENTRY_FORMULA}[$i],
						ENTRY_CPD_MZ 	=> $results->[$index_mz_continous]->{ENTRY_CPD_MZ}[$i],
						ENTRY_DELTA 	=> $results->[$index_mz_continous]->{ENTRY_DELTA}[$i]			
			    	) ;
		    		push ( @{ $tbody_object->[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
    			}
    			$index_res++ ;	
    		}
    		$index_mz ++ ;
    		$index_mz_continous ++ ;
    	}
    	$index_page++ ;
    }
    return($tbody_object) ;
}
## END of SUB

=head2 METHOD write_html_skel

	## Description : prepare and write the html output file
	## Input : $html_file_name, $html_object, $html_template
	## Output : $html_file_name
	## Usage : my ( $html_file_name ) = write_html_skel( $html_file_name, $html_object ) ;
	
=cut
## START of SUB
sub write_html_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $html_file_name,  $html_object, $pages , $search_condition, $html_template, $js_path, $css_path ) = @_ ;
    
    my $html_file = $$html_file_name ;
    
    if ( defined $html_file ) {
		open ( HTML, ">$html_file" ) or die "Can't create the output file $html_file " ;
		
		if (-e $html_template) {
			my $ohtml = HTML::Template->new(filename => $html_template);
			$ohtml->param(  JS_GALAXY_PATH => $js_path, CSS_GALAXY_PATH => $css_path  ) ;
			$ohtml->param(  CONDITIONS => $search_condition  ) ;
			$ohtml->param(  PAGES_NB => $pages  ) ;
			$ohtml->param(  PAGES => $html_object  ) ;
			print HTML $ohtml->output ;
		}
		else {
			croak "Can't fill any html output : No template available ($html_template)\n" ;
		}
		
		close (HTML) ;
    }
    else {
    	croak "No output file name available to write HTML file\n" ;
    }
    return(\$html_file) ;
}
## END of SUB

=head2 METHOD write_csv_one_mass

	## Description :  print a csv file
	## Input : $masses, $ids, $results, $file
	## Output : N/A
	## Usage : write_csv_one_mass( $ids, $results, $file ) ;
	
=cut
## START of SUB
sub write_csv_one_mass {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $ids, $results, $file,  ) = @_ ;
    
    open(CSV, '>:utf8', "$file") or die "Cant' create the file $file\n" ;
    print CSV "ID\tMASS_SUBMIT\tCPD_FORMULA\tCPD_MW\tDELTA\n" ;
    	
    my $i = 0 ;
    	
    foreach my $id (@{$ids}) {
    	my $mass = $masses->[$i] ;
    	
    	if ( $results->[$i] ) { ## an requested id has a result in the list of hashes $results.
    		
    		my $entry_nb = 0 ;
    		
    		## in case of no results -- Hr_parsed Results : $VAR1 = [ { 'ENTRY_FORMULA' => [] } ];
    		if ( !$results->[$i]{'ENTRY_FORMULA'} ) { 	print CSV "$id\t$mass\tN/A\t0.0\t0.0\n" ; 	}
    		
    		foreach (@{$results->[$i]{'ENTRY_FORMULA'}}) {

    			print CSV "$id\t$mass\t" ;
    			## print cpd formula
    			if ( $results->[$i]{'ENTRY_FORMULA'}[$entry_nb] ) 	{	print CSV "$results->[$i]{'ENTRY_FORMULA'}[$entry_nb]\t" ; }
    			else { 							print CSV "N/A\t" ; }
    			## print cpd name
    			if ( $results->[$i]{'ENTRY_CPD_MZ'}[$entry_nb] ) 	{ 	print CSV "$results->[$i]{'ENTRY_CPD_MZ'}[$entry_nb]\t" ; }
    			else { 							print CSV "0.0\t" ; }
    			## print delta
    			if ( $results->[$i]{'ENTRY_DELTA'}[$entry_nb] ) 	{ print CSV "$results->[$i]{'ENTRY_DELTA'}[$entry_nb]\n" ; }
    			else { 							print CSV "0.0\n" ; }
    			$entry_nb++ ;
    		}
    	}
    	else {
    		print CSV "$id\t$mass\tN/A\t0.0\t0.0\n" ;
    	}
    	$i++ ;
    }
   	close(CSV) ;
    return() ;
}
## END of SUB

=head2 METHOD add_hr_matrix_to_input_matrix

	## Description : build a full matrix (input + lm column)
	## Input : $input_matrix_object, $lm_matrix_object
	## Output : $output_matrix_object
	## Usage : my ( $output_matrix_object ) = add_hr_matrix_to_input_matrix( $input_matrix_object, $hr_matrix_object ) ;
	
=cut
## START of SUB
sub add_hr_matrix_to_input_matrix {
	## Retrieve Values
    my $self = shift ;
    my ( $input_matrix_object, $hr_matrix_object ) = @_ ;
    
    my @output_matrix_object = () ;
    my $index_row = 0 ;
    
    foreach my $row ( @{$input_matrix_object} ) {
    	my @init_row = @{$row} ;
    	
    	if ( $hr_matrix_object->[$index_row] ) {
    		my $dim = scalar(@{$hr_matrix_object->[$index_row]}) ;
    		
    		if ($dim > 1) { warn "the add method can't manage more than one column\n" ;}
    		my $lm_col =  $hr_matrix_object->[$index_row][$dim-1] ;

   		 	push (@init_row, $lm_col) ;
	    	$index_row++ ;
    	}
    	push (@output_matrix_object, \@init_row) ;
    }
    return(\@output_matrix_object) ;
}
## END of SUB

=head2 METHOD write_csv_skel

	## Description : prepare and write csv output file
	## Input : $csv_file, $rows
	## Output : $csv_file
	## Usage : my ( $csv_file ) = write_csv_skel( $csv_file, $rows ) ;
	
=cut
## START of SUB
sub write_csv_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $csv_file, $rows ) = @_ ;
    
    my $ocsv = formats::csv::new() ;
	my $csv = $ocsv->get_csv_object("\t") ;
	$ocsv->write_csv_from_arrays($csv, $$csv_file, $rows) ;
    
    return($csv_file) ;
}
## END of SUB

=head2 METHOD set_hr_matrix_object

	## Description : build the hr_row under its ref form
	## Input : $header, $init_mzs, $entries
	## Output : $hr_matrix
	## Usage : my ( $hmdb_matrix ) = set_hr_matrix_object( $header, $init_mzs, $entries ) ;
	
=cut
## START of SUB
sub set_hr_matrix_object {
	## Retrieve Values
    my $self = shift ;
    my ( $header, $init_mzs, $entries ) = @_ ;
    
    my @hr_matrix = () ;
    
    if ( defined $header ) {
    	my @headers = () ;
    	push @headers, $header ;
    	push @hr_matrix, \@headers ;
    }
    
    my $index_mz = 0 ;
    
    foreach my $mz ( @{$init_mzs} ) {
    	
    	my $index_entries = 0 ;
    	my @clusters = () ;
    	my $cluster_col = undef ;
    	
    	my $nb_entries = $entries->[$index_mz]{MASSES_TOTAL} ;
    	
    	foreach (@{$entries->[$index_mz]{'ENTRY_FORMULA'}}) {
    				
    		my $delta = $entries->[$index_mz]{'ENTRY_DELTA'}[$index_entries] ;
	    	my $hr_formula = $entries->[$index_mz]{'ENTRY_FORMULA'}[$index_entries] ;
	    	my $hr_mz = $entries->[$index_mz]{'ENTRY_CPD_MZ'}[$index_entries] ;
    		
	    	
	    	## METLIN data display model 
	   		## entry1=VAR1::VAR2::VAR3::VAR4|entry2=VAR1::VAR2::VAR3::VAR4|...
	   		# manage final pipe
	   		if ($index_entries < $$nb_entries-1 ) { 	$cluster_col .= $delta.'::('.$hr_formula.')::'.$hr_mz.'|' ; }
	   		else { 						   			$cluster_col .= $delta.'::('.$hr_formula.')::'.$hr_mz ; 	}
	    		
	    	$index_entries++ ;
	    } ## end foreach
	    if ( !defined $cluster_col ) { $cluster_col = 'No_result_found_with HR' ; }
    	push (@clusters, $cluster_col) ;
    	push (@hr_matrix, \@clusters) ;
    	$index_mz++ ;
    }
    return(\@hr_matrix) ;
}
## END of SUB



1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc hr.pm

=head1 Exports

=over 4

=item :ALL is manage_atoms, check_hr_exe, manage_tolerance

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 02 / 20 / 2014

version 2 : ??

=cut