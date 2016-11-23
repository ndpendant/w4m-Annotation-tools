#!/usr/bin/perl
use strict;
use warnings;

## appele a des pakage perl
use Data::Dumper;
use Getopt::Long;
use Carp ;

## Permet de localisez le repertoire du script perl d'origine
use FindBin;
## permet de definir la localisation des .pm et .conf
use lib $FindBin::Bin."/lib";
my $chemin = $FindBin::Bin."/lib";

use HR2;

###########################################################################################################
### hr2_file_mass.pl
### Input : $ hr2_file_mass.pl -input massesReunionPFEM.txt -colId 1 -nbHeader 0 -colmass 2 -tolerance 0.5 -mode neutre -charge 0 -regleOr NO -atome S,P -output1 sortieGalaxy.txt -output2 NoResult.txt -output3 conf.txt
### Author : Franck GIACOMONI and Marion LANDI
### Co-Author : Amandine LIEURADE, Clement LIONNET, Pierre MARIJON, Bruno RADISSON and Laurane VARRAILHON	
### Email : fgiacomoni\@clermont.inra.fr
### Version : 1.0
### Created : 18/07/2012
###########################################################################################################


## variable du script
my $help = undef;
my $conf = undef;

## variable valable dans tout le script (ainsi que les .pm)
use vars qw(%parametre);

use Getopt::Long;
## commande d'execution :
# $ hr2_file_mass.pl -input massesReunionPFEM.txt -colId 1 -nbHeader 0 -colmass 2 -tolerance 0.5 -mode neutre -charge 0 -regleOr NO -atome S,P -output1 sortieGalaxy.txt -output2 NoResult.txt -output3 conf.txt  -outputView view.html
#commande des options gere en ligne de commande
GetOptions(
	"help|h"=>\$help,
	"input:s"=>\$parametre{'input'},
	"colId:i"=>\$parametre{'colId'},
	"nbHeader:i"=>\$parametre{'nbHeader'},
	"colmass:i"=>\$parametre{'colmass'},
	"tolerance:f"=>\$parametre{'tolerance'},
	"mode:s"=>\$parametre{'mode'},
	"charge:i"=>\$parametre{'charge'},
	"regleOr:s"=>\$parametre{'regleOr'},
	"atome:s"=>\$parametre{'atome'},
	"output1:s"=>\$parametre{'output1'},
	"output2:s"=>\$parametre{'output2'},
	"output3:s"=>\$parametre{'output3'},
	"outputView:s"=>\$parametre{'outputView'},
);
## %parametre contient tous les parametres

#print Dumper %parametre;
#print "\n---------------------------\n";

## si on met l'option -help ou -h on lance la fonction d'aide
if (defined($help)){
	help();
	exit;
}

## Recuperation des parametres globaux locaux issu du fichier *.conf
foreach my $ConfFile ( <$chemin/*.conf> ) {
	$conf = HR2::RetrieveConfParam($ConfFile) ;
}

## verification de la bonne concordance des parametres de lancement et ceux du fichier de conf
HR2::ajoutconf(\%parametre, $conf);

## verification l'existance de l'executable HR2
HR2::verrifSystem(\%parametre);

## verification du bon remplissage des parametres
HR2::verrifParam(\%parametre);
#print Dumper %parametre;


## Parsage du fichier tabuler input
my $Id = HR2::parserCSV($parametre{'input'}, $parametre{'nbHeader'}, $parametre{'colId'});	# reccupere les Id dans la premiere colonne
my $listMasses = HR2::parserCSV($parametre{'input'}, $parametre{'nbHeader'}, $parametre{'colmass'});	# reccupere les masses dans la colonne choisit dans les parametres


## permet de d'ecrire une premiere ligne de description dans le fichier de sortie
open (OUTPUT, '>'.$parametre{'output1'}) or die "can't create file output ".$parametre{'output1'}."\n" ;
	print OUTPUT "Id\t MassQuery\t Formula\t mmu\t MassTheoretical\t Rank\n";
close(OUTPUT) ;
## permet de d'ecrire une premiere ligne de description dans le fichier de sortie
open (OUTPUT, '>'.$parametre{'output2'}) or die "can't create file output ".$parametre{'output2'}."\n" ;
	print OUTPUT "Id\t MassQuery\t Formula\t mmu\t MassTheoretical\t Rank\n";
close(OUTPUT) ;

## permet de d'ecrire la version de HR2 dans le fichier de sortie
open (OUTPUT3, '>'.$parametre{'output3'}) or die "can't create file output ".$parametre{'output3'}."\n" ;
	my $resultat = `$parametre{'lancerHR2'} -version`;
	print OUTPUT3 $resultat; 
close(OUTPUT3) ;

## create outputfile and start of HTML format
open (OUTVIEW, '>'.$parametre{'outputView'}) or die "Can't create the output view ".$parametre{'outputView'}."\n" ;
	my $HTML = qq{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<meta charset="utf-8" />
        <style type="text/css">
			table{
			    border-collapse: collapse;
			}
			td, th {/* Mettre une bordure sur les td ET les th */
			    border: 1px solid black;
			}
		 </style>
		<title>GALAXY::HR2 Results</title>
	</head>
	<body>
		<br><br>
    	} ;
    print OUTVIEW $HTML; 
close(OUTVIEW) ;


## on parcourt les masses (ici parcourt en parallele la masse et l'Id)
for (my $i=0 ; $i <= $#{$listMasses} ; $i++ ){
	## verrification de la justesse de la masse et de la tolerance
	HR2::verrifMasse_Tolerance($$Id[$i], $$listMasses[$i], $parametre{'tolerance'}, \%parametre);
	
	## preparation de la commande ($parametre{'commande'}) d'execution de HR2 avec les paramettres definit dans %parametre
	HR2::commande(\%parametre);
		
	## lancement de la commande d'execution de HR2 et stockage du resultats dans $resultat
    my $resultat = `$parametre{'commande'}`;
	
	## affiche la commande qui a lancer HR2
	open (OUTPUT3, '>>'.$parametre{'output3'}) or die "can't create file output ".$parametre{'output3'}."\n" ;
		print OUTPUT3 "\n---------------------------\n";
		print OUTPUT3 $parametre{'commande'}."\n";
	close(OUTPUT3);
	
    ## parsage du resultat de HR2 pour ne retenir que les donnees dont on a besoin
    HR2::parseResHR2($resultat, \%parametre);
	
	## ecrit les resultats dans le fichier d'output passable facilement pour d'autres analyses
	if ($parametre{'formuleBrute'}[0] eq 'NA'){
		HR2::printOutput($parametre{'output2'}, \%parametre);
	}
	else {
		HR2::printOutput($parametre{'output1'}, \%parametre);
	}
	
	## ecrit les resultats dans le fichier d'output graphique
	HR2::writeViewOutput($parametre{'outputView'} , \%parametre) ;
}

## create outputfile and start of HTML format
open (OUTVIEW, '>>'.$parametre{'outputView'}) or die "Can't create the output view ".$parametre{'outputView'}."\n" ;
	my $HTML2 = qq{
    <br><br><div><i>Results generate by PFEM-Galaxy -- Dvt 2012 - FGiacomoni & MLandi</i></div><br>
	</body>
</html>
    	} ;
    print OUTVIEW $HTML2; 
close(OUTVIEW) ;


#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
    print STDERR "
	$0
	
	# hr2_file_mass
	# Input : -input massesReunionPFEM.txt -colId 1 -nbHeader 0 -colmass 2 -tolerance 0.5 -mode neutre -charge 0 -regleOr NO -atome S,P -output1 sortieGalaxy.txt -output2 NoResult.txt -output3 conf.txt
	# Author : Franck GIACOMONI and Marion LANDI
	# Co-Author : Amandine LIEURADE, Clement LIONNET, Pierre MARIJON, Bruno RADISSON and Laurane VARRAILHON	
	# Email : fgiacomoni\@clermont.inra.fr
	# Version : 1.0
	# Created : 16/07/2012
	USAGE :
	        hr2_file_mass.pl -help
	        hr2_file_mass.pl -input massesReunionPFEM.txt -colId 1 -nbHeader 0 -colmass 2 -tolerance 0.5 -mode neutre -charge 0 -regleOr NO -atome S,P -output1 sortieGalaxy.txt -output2 NoResult.txt -output3 conf.txt
	!!! ATTENTION !!! ce logiciel necessite :
		- l'installation de differents packages tel que XML::Twig, SOAP::Lite, Text::CSV.
		- la presence dans le meme repertoire que masse_simple.pl de :
				- (HR2-all-res.exe ==> deplacer dans /opt/tool) (executable de HR2 pour le systeme d'exploitation utiliser)
				- README.txt (ce fichier d'aide)
				- le repertoire /module\n";
	
	open(FILE,"README.txt") || die "impossible d'ouvrir README.txt\n";
	while(<FILE>){
		print $_;
	}
	close(FILE);
    exit(1);
} 
