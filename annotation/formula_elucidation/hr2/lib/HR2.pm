package HR2;

use strict;
use warnings;

use Data::Dumper;
use Carp ;
use Text::CSV ;

## Permet de localisez le repertoire du script perl d'origine
use FindBin;
use lib $FindBin::Bin."/lib";
my $chemin = $FindBin::Bin."/lib";

###########################################################################################################
### masse_unique.pl
### Input : -masse \"237.5983 536.3254\" -tolerance 1.0 -mode positif -charge 0 -atome S,P
### Author : Franck GIACOMONI and Marion LANDI
### Co-Author : Amandine LIEURADE, Clement LIONNET, Pierre MARIJON, Bruno RADISSON and Laurane VARRAILHON	
### Email : fgiacomoni\@clermont.inra.fr
### Version : 1.0
### Created : 18/07/2012
###########################################################################################################


## Fonction : permet de parcourir les parametres du fichiers de conf et remplir un hash simple.
## Input : nom du fichier de conf (chemin relatif)
## Ouput : ref du hash des parametres
sub RetrieveConfParam {

    my ( $CfgFile ) = @_;

    my %Param = () ; ## Hash devant contenir l'ensemble des parametres locaux

    if (-e $CfgFile) {
        open (CFG, "<$CfgFile") or die "Can't open $CfgFile\n" ;
        while (<CFG>) {
            chomp $_ ;
            if ( $_ =~ /^#(.*)/)  {    next ; }
            elsif ($_ =~/^(.*)=(.*)/) { $Param{$1} = $2 ; }
            else {	next ;	}
        }
        close(CFG) ;
    }
    else { print "[Error] Can't find $CfgFile \n" ; }

    return ( \%Param ) ;
}
### END of SUB


## Fonction : verification de la bonne concordance des parametres de lancement et ceux du fichier de conf
## Input : reference d'un hash des parametres envoyer $parametre, reference d'un hash des parametres dans le fichier de conf
## Ouput : NA
sub ajoutconf{
	my $parametre = shift;	
	my $conf = shift;
	
	## si un parametre du fichier de conf n'existe pas encore ou est vide dans les parametres du programme on le definit
	foreach my $k (keys(%$conf)){
		if (exists $$parametre{$k} && defined $$parametre{$k} && $$parametre{$k} ne "" && $$parametre{$k} ne " "){	
			if ($k eq 'atome'){
				## on ajoute les atomes C,H, O et N au autres rechercher
				## on veux toujours les chercher
				if ($$parametre{$k} eq 'None'){	## si il n'y a pas d'autres atomes on ecrase et on met C,H,O,N
					$$parametre{$k} = $$conf{$k};
				}
				else {	## sinon on concatene devent les autres atomes choisis
					$$parametre{$k} = $$conf{$k}.','.$$parametre{$k};
				}
			}
			else {	next ;	}
		}
		else {
			$$parametre{$k} = $$conf{$k};
		}
	}
}
### END of SUB


## Fonction : verrifie l'existance de l'executable HR2
## Input : reference d'un hash des parametres envoyer $parametre 
## Ouput : NA
sub verrifSystem{
	my $parametre = shift;	
	
	## on verrifie que le chemin de l'executable de HR2
	if (exists $$parametre{'lancerHR2'} && defined $$parametre{'lancerHR2'} && $$parametre{'lancerHR2'} ne "" && $$parametre{'lancerHR2'} ne " "){
		## si l'executable de HR2 est la ou il est definit dans le fichier de conf on ne fait rien
		if (-e $$parametre{'lancerHR2'}){ 	}
		## si l'executable de HR2 N'est  PAS la ou il est definit dans le fichier de conf
		## on regarde la ou se situ le script principal (.pl)
		elsif (-e $FindBin::Bin."/HR2-all-res.exe") {
			## si il y est on change le chemin dans $$parametre{'lancerHR2'}
			$$parametre{'lancerHR2'} = $FindBin::Bin."/HR2-all-res.exe";
		}
		## sinon on regarde la ou se situ les modules (repertoire /module)
		elsif (-e $chemin."/HR2-all-res.exe") {
			## si il est la, on change le chemin dans $$parametre{'lancerHR2'}
			$$parametre{'lancerHR2'} = $chemin."/HR2-all-res.exe";
		}
		## si on ne le trouve pas, on stop tout
		else {	die "!!! Attention pas de HR2-all-res.exe (executable HR2) n'existe ni a la position $$parametre{'lancerHR2'} ni a la position $FindBin::Bin !!!\n" ;	}
	}
	else{
		## si l'executable n'est pas definit on regarde dans le repertoire du script principal (.pl)
		if (-e $FindBin::Bin."/HR2-all-res.exe") {
			$$parametre{'lancerHR2'} = $FindBin::Bin."/HR2-all-res.exe";
		}
		## sinon on regarde la ou se situ les modules (repertoire /module)
		elsif (-e $chemin."/HR2-all-res.exe") {
			## si il est la, on change le chemin dans $$parametre{'lancerHR2'}
			$$parametre{'lancerHR2'} = $chemin."/HR2-all-res.exe";
		}
		## si on ne le trouve pas, on stop tout
		else {	die "!!! Attention pas de HR2-all-res.exe (executable HR2) a la position $FindBin::Bin !!!\n" ;	}
	}
}
### END of SUB

	
## Fonction : verrifie qu'on a tous les parametres dont HR2 a besoin
## Input : reference d'un hash des parametres envoyer $parametre 
## Ouput : NA
sub verrifParam{
	my $parametre = shift;	
	
	## pour tout les parametres non-vide du programme, on fait quelques verrifications
	## sinon le parametre est vide, donc on stop tout pour eviter les erreurs
	foreach my $k (keys(%$parametre)){
		if (defined $$parametre{$k} && $$parametre{$k} ne "" && $$parametre{$k} ne " "){
			## tolerance et les atomes CHON doivent etre >0
			if ($k eq 'C' || $k eq 'H' || $k eq 'O' || $k eq 'N'){
				if ($$parametre{$k} <= 0){
					die "!!! Attention parametre(s) $k <= 0 !!!\n" ;
				}
			}
			elsif ($k eq 'atome'){
				my @atome = split ("," , $$parametre{$k});
				foreach my $at (@atome){
					if (exists $$parametre{$at} && defined $$parametre{$at} && $$parametre{$at} ne "" && $$parametre{$at} ne " "){	next ;	}
					else {
						$$parametre{$at} = 10;
					}
				}
			}
			elsif ($k eq 'mode'){
				if ($$parametre{$k} eq "neutre" && $$parametre{'charge'} != 0){
					die "!!! Attention il s'agit d'une molecule et non d'un ion puisque le mode 'neutre' est utilise, donc la charge doit etre de '0' !!!\n" ;
				}
			}
			else {	next ;	}
		}
		else {
			die "!!! Attention parametre(s) $k vide !!!\n" ;
		}
	}
}
### END of SUB


## Fonction : Parse un fichier tabuler et reccupere la colonne en argument dans un tableau
## Input : fichier tabuler : $input ; numero de colonne : $column (ne sert pas vraiment) 
## Ouput : un tableau avec le contenu de la colonne : @RetrieveList
sub parserCSV{
	my ($input, $nbHeader, $Column) = @_ ;
	
	## Adapte the number of the colunm : (nb of column to position in array)
	$Column = $Column - 1 ;
	
	my @RetrieveList = () ;
	my $csv = Text::CSV->new({'sep_char' => "\t"});
		
	open (CSV, "<", $input) or die $!;
	my $i = -1;
	
	while (<CSV>) {
	    $i++;
		chomp $_ ;
		if ($i < $nbHeader){	next;	}
	    elsif ( $csv->parse($_) ) {
	        my @columns = $csv->fields();
#			print Dumper "$columns[0]\n";
	        push (@RetrieveList, $columns[$Column]) ;
	    }
	    else {
	        my $err = $csv->error_input;
	        die "Failed to parse line: $err";
	    }
	}
	close CSV;
	return (\@RetrieveList);
}
### END of SUB


## Fonction : Parse un fichier tabuler et reccupere les colonnes 1 et 2 dans des tableaux
## Input : fichier tabuler : $input ; numero de colonne : $column (ne sert pas vraiment)
## Ouput : un tableau pour chaque colonne : @Id (colonne 1), @listMasses (colonne 2) 
sub parserTab{	
	my ($input, $column) = @_ ;
	
	my @Id = ();
	my @listMasses = ();
	if (defined $input ) {
		if (-e $input) {
		        if (defined $column) {
		                my $Line = 0 ;
		                open (INPUT , "<$input") or die "can't open file input $input\n" ;
		                while (<INPUT>) {
		                        chomp $_ ;
		                        $Line++ ;
		                        if ( $_ =~ /(.*)\s+(.*)/ ) {
		                        	push (@Id, $1);
		                        	push (@listMasses, $2);
		                        }
		                        else {        next ;     }
		                }
		                close (INPUT) ;
		        }
		        else {
		                die "No column select\n" ;
		        }
		}
		else {
		    die "No file $input\n" ;
		}
	}
	else {
	    die "No file select\n" ;
	}
	return (\@Id, \@listMasses);
}
### END of SUB

			
## Fonction : verrifie la masse et la tolerance
## Input : identifiant de la masse : $Id ; masse : $masse ; tolerance : $tolerance ; reference d'un hash des parametres : $parametre 
## Ouput : NA
sub verrifMasse_Tolerance{
	my $Id = shift;
	my $masse = shift;
	my $tolerance = shift;
	my $parametre = shift;
	
	if (defined $tolerance && $tolerance ne "" && $tolerance ne " "){
		## tolerance doivent contenir des "." et non des ","
		$tolerance =~ tr/,/./;
		## tolerance doit etre >0 et <10
		if ($tolerance <= 0 || $tolerance >= 10){
			die "!!! Attention tolerance de $Id invalide : <= 0 ou >= 10 !!!\n" ;
		}
		else{
			$$parametre{'tolerance'} = $tolerance ;
		}
	}
	else {
		die "!!! Attention tolerance de $Id invalide : vide !!!\n" ;
	}
	
	$masse=~tr/,/./;	# la masse doivent contenir des "." et non des ","
	if (defined $masse && $masse ne "" && $masse ne " " && $masse > 10){	# la masse doit etre >10
		
		# retablissement de la masse non-ionise de la molecule en fonction du mode du spectrometre pour que la formule puisse etre trouver par HR2
		if($$parametre{'mode'} eq "positif"){	
			# si on a fait l'analyse en mode positif => on a ajouter un H+ (proton) => molecule charger positivement : el+ => $charge = "positive"
			# => on doit enlever la masse du proton et ajouter la masse des electrons (1 electron par nb de charge) a la masse en entree pour avoir la masse d'une molecule neutre (non-charger) trouvable pas HR2
			if ($$parametre{'charge'} == 0){
				## si on cherche une molecule non-charger la masse entre sera quand meme 1 fois charger (ionisation systematique des molecules par le spectrometre)
				$masse = $masse - $$parametre{'proton'} + $$parametre{'electron'};
			}
			else {
				$masse = ($masse*$$parametre{'charge'}) - $$parametre{'proton'} + ($$parametre{'charge'}*$$parametre{'electron'});
			}
	    }
	    elsif($$parametre{'mode'} eq "negatif"){
	    	# si on a fait l'analyse en mode negatif => on a enleve un H+ (proton) => molecule charger negativement : el- => $charge = "negative"
			# => on doit ajouter la masse du proton et enlever la masse des electrons (1 electron par nb de charge) a la masse en entree pour avoir la masse d'une molecule neutre (non-charger) trouvable pas HR2
			if ($$parametre{'charge'} == 0){
				## si on cherche une molecule non-charger la masse entre sera quand meme 1 fois charger (ionisation systematique des molecules par le spectrometre)
				$masse = $masse + $$parametre{'proton'} - $$parametre{'electron'};
			}
			else {
				$masse = ($masse*$$parametre{'charge'}) + $$parametre{'proton'} - ($$parametre{'charge'}*$$parametre{'electron'});
			}
	    }
	    ## mode neutre masse non sortie par spectrometre de masse (donc non-ioniser)
	    elsif($$parametre{'mode'} ne "neutre"){
	                die "Format charge non gerer !!!\n";
	    }
	    
		$$parametre{'Id'} = $Id ;	# on affecte l'identifiant
		$$parametre{'masse'} = $masse ;	# on affecte la masse
	}
	else {
		die "!!! Attention masse de $Id invalide : <= 10 ou vide !!!\n" ;
	}
	
}
### END of SUB


## Fonction : Prepare la ligne de commande pour le lancement de HR2
## Input : reference d'un hash des parametres : $parametre 
## Ouput : NA
sub commande{
	my $parametre = shift;
	
	## si on a demander a restreindre le nombre de regle d'or aux 3 premieres
	if ($$parametre{'regleOr'} eq "YES" || $$parametre{'regleOr'} eq "Yes" || $$parametre{'regleOr'} eq "yes" || $$parametre{'regleOr'} eq "OUI" || $$parametre{'regleOr'} eq "Oui" || $$parametre{'regleOr'} eq "oui"){
		$$parametre{'commande'} = $$parametre{'lancerHR2'}.' -g -t '.$$parametre{'tolerance'}.' -m '.$$parametre{'masse'};
	}
	## pour les petites masses (<=100) on n'applique que les 3 premieres regles d'or pour generer plus de formules brutes
	elsif ($$parametre{'masse'} <= 100){
		$$parametre{'commande'} = $$parametre{'lancerHR2'}.' -g -t '.$$parametre{'tolerance'}.' -m '.$$parametre{'masse'};
	}
	## pour les autres masses (>100) on applique toutes les regles d'or pour generer plus de formules brutes
	else{
		$$parametre{'commande'} = $$parametre{'lancerHR2'}.' -t '.$$parametre{'tolerance'}.' -m '.$$parametre{'masse'};
	}
	
	# condition permettant de rajouter les atomes comme on le veut
	my @element=('C', 'H', 'N', 'O', 'P', 'S', 'F', 'L', 'K', 'B', 'A', '1');
	foreach my $at (split ("," , $$parametre{'atome'})){
		$$parametre{'commande'}.=' -'.$at.' 0-'.$$parametre{$at};
	}
}
### END of SUB


## Fonction : Parsage du resultat de HR2 pour ne garder que les donnees qui nous interessent
## Input : resultats de HR2 : $resultat ; reference d'un hash des parametres : $parametre 
## Ouput : NA
sub parseResHR2{
	my $resultat = shift;
	my $parametre = shift;
		
	my %formules;
	my @mu = ();
	my @formuleMasse = ();
	my $formuleBrute;
	
	if (defined $resultat && $resultat ne "" && $resultat ne " "){
		# parcourt de la sortie et recuperation des lignes qui nous interesse
		# On stocke les informations dans des variables
	    foreach my $ligne (split(/\n/,$resultat)){
			# exemple :
			## "C7.H17.N5.		2.0	171.1484	+17.2 mmu "
			## $1 = "C7.H" 	$2 = "17" 	$3 = ".N5."		$4 = "		2.0	171.1484	+"		$5="17.2"	$6 = " mmu"
			if($ligne=~/^(C.*\.H)(\d+)(\..*?)(\s+.+\s[+|-])(\d+.?\d*)(.*)/){
	#			print "$1#$2#$3#$4#$5#$6\n";
				my $form = $1.$2.$3;
				my $mmu = $5;
				$form =~ s/\.//g;
				$form =~ s/(\D)1(\D)/$1$2/ig;
				$form =~ s/(\D)1(\D)/$1$2/ig;
				$form =~ s/(\D)1$/$1/;
				$formules{$form}{'mmu'} = $mmu;
			    
			    my @ligne = split ("	" , $ligne);
				$formules{$form}{'colonne3'} = $ligne[2];
				$formules{$form}{'formuleMasse'} = $ligne[3];
				$formules{$form}{'colonne5'} = $ligne[4];
				$formules{$form}{'colonne6'} = $ligne[5];
			}
			## parse le ligne
			## 1 formulas found in      0 seconds by evaluating 101437 formulae.
			elsif($ligne=~/^(\d+)\s+formulas.+\s(\d+)\s+seconds.+\s(\d+)\s+formulae/){
				$$parametre{'nbFormule'} = $1;
				$$parametre{'temps'} = $2;
				$$parametre{'totFormule'} = $3;
			}
			else {	next;	}
	    }
	    
	    ## si on a des formules brutes
	    if (keys(%formules)>0){
	#		print sort(@mu);
			my @sortformules = sort { $formules{$a}{'mmu'} cmp $formules{$b}{'mmu'} } keys (%formules);
			foreach my $form (@sortformules){
				push(@formuleMasse,$formules{$form}{'formuleMasse'});
				push(@mu,$formules{$form}{'mmu'});
			}
#			$$parametre{'mmu'} = join(";", @mu);
#			$$parametre{'formuleBrute'} = join(";", @sortformules);
#			$$parametre{'formuleMasse'} = join(";", @formuleMasse);
			$$parametre{'mmu'} = \@mu;
			$$parametre{'formuleBrute'} = \@sortformules;
			$$parametre{'formuleMasse'} = \@formuleMasse;
	    }
	    else {	## sinon NA partout
	    	$$parametre{'formuleBrute'} = ['NA'];
	    	$$parametre{'mmu'} = ['NA'];
			$$parametre{'formuleMasse'} = ['NA'];
			$$parametre{'nbFormule'} = ['NA'];
			$$parametre{'temps'} = ['NA'];
			$$parametre{'totFormule'} = ['NA'];
	    }
	}
	else {
		die "!!! Attention pas de resultats HR2 : surmant du a une erreur dans les parametre de construction de la commande !!!\n" ;
	}
}
### END of SUB

## Fonction : ecrite le fichier de sortie de l'analyse HR2
## Input : nom du fichier de output : $output, reference d'un hash des parametres : $parametre 
## Ouput : NA
sub printOutput{
	my $output = shift;
	my $parametre = shift;
	
	open (OUTPUT, '>>'.$output) or die "can't create file output $output\n" ;
#	print Dumper %$parametre;
		for (my $i=0 ; $i<=$#{$$parametre{'formuleBrute'}} ; $i++){
			## on ecrit l'identifiant dans la sortie
			print OUTPUT $$parametre{'Id'}."\t";
			## on ecrit la masse dans la sortie
			print OUTPUT $$parametre{'masse'}."\t";
			## on ecrit la formule brute dans la sortie
			print OUTPUT $$parametre{'formuleBrute'}[$i]."\t";
			## on ecrit le mmu de la formule brute dans la sortie
			print OUTPUT $$parametre{'mmu'}[$i]."\t";
			## on ecrit la masse de la formule brute dans la sortie
			print OUTPUT $$parametre{'formuleMasse'}[$i]."\t";
			## on ecrit le rang / nombre de formules brutes trouver dans la sortie
			if ($$parametre{'formuleBrute'}[0] eq 'NA'){
				print OUTPUT "0/0\n";
			}
			else {
				my $rang = $i+1;
				print OUTPUT $rang."/".scalar(@{$$parametre{'formuleBrute'}})."\n";
			}
		}
	close(OUTPUT) ;
}
### END of SUB


## Fonction : ecrite le fichier de sortie de l'analyse HR2 en HTML bien visuel
## Input : nom du fichier de output : $output, reference d'un hash des parametres : $parametre
## Ouput : NA
sub writeViewOutput {
    ## Retrieve Values
    my ( $file, $parametre ) = @_;
    
    my $HTML = undef ;
    my $TABLE = undef ;
    
    ## create outputfile and start of HTML format
    open (HTML, ">>$file") or die "Can't create the output view $file" ;
    
    ## Init start of page
    ## -------------------------- HTML ---------------------------
    
    	
    $TABLE = qq{
	<table>
		<col style="width:200px;">
		<col style="width:80px;">
		<col style="width:200px;">
		<col style="width:80px;">
	<thead>
		<tr>
			<th style="text-align:center;">Formula</th>
			<th style="text-align:center;">mmu</th>
			<th style="text-align:center;">MassTheoretical</th>
			<th style="text-align:center;">Rank</th>
		</tr>
	</thead>
    	} ;
    	
    ## Ecriture du titre du tableau
    $HTML .= qq{
    		<br><CAPTION><b>Results for query $$parametre{'Id'} on mass $$parametre{'masse'}:</b></CAPTION>
    		<tbody>
    	} ;
    $HTML .= $TABLE ;
    ## -------------------------- HTML ---------------------------
    
    for (my $i=0 ; $i<=$#{$$parametre{'formuleBrute'}} ; $i++){
    	## -------------------------- HTML ---------------------------
    	$HTML .= qq{
    	<tr>
			<td style="text-align:center;">$$parametre{'formuleBrute'}[$i]</td>
			<td style="text-align:center;">$$parametre{'mmu'}[$i]</td>
			<td style="text-align:center;">$$parametre{'formuleMasse'}[$i]</td>
			} ;
		if ($$parametre{'formuleBrute'}[0] eq 'NA'){
			$HTML .= qq{
				<td style="text-align:center;">0/0</td>
			</tr>
    			} ;
		}
    	else {
			my $rang = $i+1;
			my $nbtotal = scalar(@{$$parametre{'formuleBrute'}});
			$HTML .= qq{
				<td style="text-align:center;">$rang/$nbtotal</td>
			</tr>
    			} ;
		}
    				## -------------------------- HTML ---------------------------
    	
    } ## END FOREACH
    
    ## -------------------------- HTML ---------------------------
    $HTML .= qq{
    		</tbody>
    	</table>
    	} ;
    ## -------------------------- HTML ---------------------------
    
    print HTML $HTML ;
    close (HTML) ;
    return ;
}
### END of SUB

1;
