package lib::chemspider_api ;

use strict;
use warnings ;
use Exporter ;
use Carp ;

use HTML::Template ;

use Data::Dumper ;

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( chemspider_exe set_html_tbody_object add_mz_to_tbody_object add_entries_to_tbody_object write_html_skel set_chemspider_matrix_object add_chemspider_matrix_to_input_matrix write_csv_skel write_csv_one_mass );
our %EXPORT_TAGS = ( ALL => [qw( chemspider_exe set_html_tbody_object add_mz_to_tbody_object add_entries_to_tbody_object write_html_skel set_chemspider_matrix_object add_chemspider_matrix_to_input_matrix write_csv_skel write_csv_one_mass )] );

=head1 NAME

My::Module - An example module

=head1 SYNOPSIS

    use My::Module;
    my $object = My::Module->new();
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

=head2 METHOD chemspider_exe

	## Description : launching metabolomicBankWs jar with complete argt
	## Input : $exec, $delta, $mass, $massesinputfile, $json_outputfile
	## Output : $json
	## Usage : my ( $json ) = chemspider_exe( $exec, $delta, $mass, $massesinputfile, $json_outputfile ) ;
	
=cut
## START of SUB
sub chemspider_exe {
	## Retrieve Values
    my $self = shift ;
    my ( $exec, $delta, $mass, $massesinputfile, $col_mass, $col_id, $line_hearder ) = @_ ;
    
    my $json = undef ;
    
    if ( ( defined $exec ) and ( -e $exec ) and ( defined $delta ) ) {
    	## depends of input type
    	if ( defined $mass ) { 	$json = `java -jar $exec -delta="$delta" -ws="chemspider" -stdout -mass="$mass"` ;   	}
    	elsif ( defined $massesinputfile ) { $json = `java -jar $exec -delta="$delta" -ws="chemspider" -stdout -inFile="$massesinputfile" -colData="$col_mass" -colId="$col_id" -inFileHeader="$line_hearder"` ; 	}
    	
    	## manage final backslash n 
    	chomp $json ;
    	
    }
    else {
    	croak "Can't execute chemspider ws (metabolicBankWS_client-0.1.jar)\n" ;
    }
    
    return(\$json) ;
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
    my ( $tbody_object, $nb_items_per_page, $mz_list, $ids_list ) = @_ ;

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
					
					my %mz = (
						# mass feature
						MASSES_ID_QUERY => $ids_list->[$mz_index],
						MASSES_MZ_QUERY => $mz_list->[$mz_index],
						MZ_COLOR => $colors[$icolor],
						MASSES_NB => $mz_index+1,
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
    my ( $tbody_object, $nb_items_per_page, $mz_list, $ids_list, $json, $url_chemspider ) = @_ ;
    
    my $index_page = 0 ;
    my $index_mz_continous = 0 ;
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;
    	
    	foreach my $mz (@{ $tbody_object->[$index_page]{MASSES} }) {
    		
    		my $index_entry = 0 ;
    		my $entries = undef ;
    		
    		
    		## attach the right list of entries (hash...)
    		foreach my $result ( @{ $$json->{extendedCompoundInfos} } ) {
    			if ( ( $result->{id} ) and ( $result->{mass} ) ) {
    				if ( ( $result->{mass} eq $mz_list->[$index_mz_continous] ) and ( $result->{id} eq $ids_list->[$index_mz_continous] ) ) { $entries = $result->{extendedCompoundInfo} ; last ; }
    			}
    		}
    		if ( defined $entries ) {
    			
    			foreach my $entry ( @{ $entries } ) {
	    			
	    			my $delta = sprintf( "%.4f", ( $mz_list->[$index_mz_continous] - $entry->{monoisotopicMass} ) ) ;

	    			my %entry = (
			    		ENTRY_COLOR => $tbody_object->[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
			    		ENTRY_NAME => $entry->{commonName},
						ENTRY_CHEMSPIDER_ID => $entry->{csid},
						URL_CHEMSPIDER => $url_chemspider,
			   			ENTRY_FORMULA => 'NA',
						ENTRY_CPD_MZ => $entry->{monoisotopicMass},
						ENTRY_DELTA => $delta,					  			
			    	) ; ## No $entry->{formula}
			    	
		    		push ( @{ $tbody_object->[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
	    			$index_entry++ ;	
	    		} ## end foreach
	    		$entries = undef ;
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
    my ( $html_file_name,  $html_object, $pages , $html_template, $js_path, $css_path ) = @_ ;
    
    my $html_file = $$html_file_name ;
    
    if ( defined $html_file ) {
		open ( HTML, ">$html_file" ) or die "Can't create the output file $html_file " ;
		
		if (-e $html_template) {
			my $ohtml = HTML::Template->new(filename => $html_template) ;
			$ohtml->param( JS_GALAXY_PATH => $js_path, CSS_GALAXY_PATH => $css_path ) ;
			$ohtml->param( PAGES_NB => $pages ) ;
			$ohtml->param( PAGES => $html_object ) ;
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

=head2 METHOD set_chemspider_matrix_object

	## Description : build the chemspider_row under its ref form
	## Input : $header, $init_mzs, $entries
	## Output : $chemspider_matrix
	## Usage : my ( $chemspider_matrix ) = set_lm_matrix_object( $header, $init_mzs, $entries ) ;
	
=cut
## START of SUB
sub set_chemspider_matrix_object {
	## Retrieve Values
    my $self = shift ;
    my ( $header, $init_mzs, $init_ids, $json ) = @_ ;
    
    my @chemspider_matrix = () ;
    
    if ( defined $header ) {
    	my @headers = () ;
    	push @headers, $header ;
    	push @chemspider_matrix, \@headers ;
    }
    
    my $index_mz = 0 ;
    
    foreach my $mz ( @{$init_mzs} ) {
    	
    	my $index_entries = 0 ;
    	my @clusters = () ;
    	my $cluster_col = undef ;
    	my $entries = undef ;
    		
    		
    	## attach the right list of entries (hash...)
    	foreach my $result ( @{ $$json->{extendedCompoundInfos} } ) {
    		if ( ( $result->{id} ) and ( $result->{mass} ) ) {
    			if ( ( $result->{mass} eq $init_mzs->[$index_mz] ) and ( $result->{id} eq $init_ids->[$index_mz] ) ) { $entries = $result->{extendedCompoundInfo} ; last ; }
    		}
    	}
    	
    	if ( defined $entries ) {
    		
    		my $nb_entries = scalar (@{ $entries }) ;
    	    	
	    	foreach my $entry ( @{ $entries } ) {
	    		
	    		my ( $delta, $name, $chemspider_id ) = ( 0, 'NA', 'NA') ;
	    		
	    		if ( $entry->{monoisotopicMass} ) { $delta = sprintf("%.4f", ( $init_mzs->[$index_mz] - $entry->{monoisotopicMass} ) ) ; }
	    		if ( $entry->{commonName} ) { $name =  $entry->{commonName} ; }
	    		if ( $entry->{csid} ) { $chemspider_id = $entry->{csid}  ; }
		    	
		    	## METLIN data display model 
		   		## entry1=VAR1::VAR2::VAR3::VAR4|entry2=VAR1::VAR2::VAR3::VAR4|...
		   		# manage final pipe<>
		   		if ($index_entries < $nb_entries-1 ) { 	$cluster_col .= $delta.'::('.$name.')::'.$chemspider_id.'|' ; }
		   		else { 						   			$cluster_col .= $delta.'::('.$name.')::'.$chemspider_id ; 	}
		    		
		    	$index_entries++ ;
		    } ## end foreach
		    if ( !defined $cluster_col ) { $cluster_col = 'No_result_found_on_Chemspider' ; }
	    	push (@clusters, $cluster_col) ;
	    	push (@chemspider_matrix, \@clusters) ;
	    	
    		$entries = undef ;
    	} ## end IF defined
		$index_mz++ ;
    }
    return(\@chemspider_matrix) ;
}
## END of SUB

=head2 METHOD add_chemspider_matrix_to_input_matrix

	## Description : build a full matrix (input + lm column)
	## Input : $input_matrix_object, $chemspider_matrix_object
	## Output : $output_matrix_object
	## Usage : my ( $output_matrix_object ) = add_chemspider_matrix_to_input_matrix( $input_matrix_object, $chemspider_matrix_object ) ;
	
=cut
## START of SUB
sub add_chemspider_matrix_to_input_matrix {
	## Retrieve Values
    my $self = shift ;
    my ( $input_matrix_object, $chemspider_matrix_object ) = @_ ;
    
    my @output_matrix_object = () ;
    my $index_row = 0 ;
    
    foreach my $row ( @{$input_matrix_object} ) {
    	my @init_row = @{$row} ;
    	
    	if ( $chemspider_matrix_object->[$index_row] ) {
    		my $dim = scalar(@{$chemspider_matrix_object->[$index_row]}) ;
    		
    		if ($dim > 1) { warn "the add method can't manage more than one column\n" ;}
    		my $lm_col =  $chemspider_matrix_object->[$index_row][$dim-1] ;

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

=head2 METHOD write_csv_one_mass

	## Description : permet de print un fichier cvs
	## Input : $masses, $ids, $results, $file
	## Output : N/A
	## Usage : write_csv_one_mass( $ids, $results, $file ) ;
	
=cut
## START of SUB
sub write_csv_one_mass {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $ids, $json, $file,  ) = @_ ;
    
    open(CSV, '>:utf8', "$file") or die "Cant' create the file $file\n" ;
    print CSV "ID\tMASS_SUBMIT\tCHEMSPIDER_ID\tCPD_NAME\tFORMULA\tCPD_MW\tDELTA\n" ;
    	
    my $i = 0 ;
    	
    foreach my $id (@{$ids}) {
    	my $mass = $masses->[$i] ;
    	my $entries = undef ;
    	
    	## attach the right list of entries (hash...)
   		foreach my $result ( @{ $$json->{extendedCompoundInfos} } ) {
   			if ( ( $result->{id} ) and ( $result->{mass} ) ) {
   				if ( ( $result->{mass} eq $masses->[$i] ) and ( $result->{id} eq $ids->[$i] ) ) { $entries = $result->{extendedCompoundInfo} ; last ; }
    		}
    	}
    	
    	if ( defined $entries ) {
    		
    		foreach my $entry (@{$entries}) {
    			
    			print CSV "$id\t$mass\t" ;
    			## print cpd chemspider_id
    			if ( $entry->{csid} ) { 		print CSV "$entry->{csid}\t" ; }
    			else { 							print CSV "N/A\t" ; }
    			## print cpd name
    			if ( $entry->{commonName} ) { 	print CSV "$entry->{commonName}\t" ; }
    			else { 							print CSV "N/A\t" ; }
    			## print cpd formula
    			if ( $entry->{formula} ) { 		print CSV "$entry->{formula}\t" ; }
    			else { 							print CSV "N/A\t" ; }
    			## print cpd mw
    			if ( $entry->{monoisotopicMass} ) { 	print CSV "$entry->{monoisotopicMass}\t" ; }
    			else { 									print CSV "N/A\t" ; }
    			## print delta
    			if ( $entry->{monoisotopicMass} ) { 
    											my $delta = sprintf( "%.4f", ( $masses->[$i] - $entry->{monoisotopicMass} ) ) ;
    											print CSV "$delta\n" ; }
    			else { 							print CSV "N/A\n" ; }
    		}
    	}
    	$i++ ;
    }
   	close(CSV) ;
    return() ;
}
## END of SUB

1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc lib::chemspider_api.pm

=head1 Exports

=over 4

=item :ALL is chemspider_exe, set_html_tbody_object, add_mz_to_tbody_object, add_entries_to_tbody_object, write_html_skel, set_chemspider_matrix_object, add_chemspider_matrix_to_input_matrix, write_csv_skel and write_csv_one_mass 

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 01 / 04 / 2014

version 2 : ??

=cut