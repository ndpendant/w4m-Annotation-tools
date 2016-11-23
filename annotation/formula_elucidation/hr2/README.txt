## ****** HR2 environnemnt : ****** ##
# version dec 2013 M Landi / A LIEURADE, Cl LIONNET, P MARIJON, B RADISSON and L VARRAILHON / F Giacomoni

## --- PERL compilator / libraries : --- ##
$ perl -v
This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi

# libs CORE PERL : 
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;
use Data::Dumper ;
use Getopt::Long ;
use FindBin ;

# libs CPAN PERL : 
$ perl -e 'use Text::CSV'
$ sudo perl -MCPAN -e shell
cpan> install Text::CSV

# libs pfem PERL : 
No dependency with pfem lib -- but soon!
--

## --- Binary dependencies --- ##
Install folowing binaries :
* HR2 :
source : HR2_v1.03.cpp available in the tar ball
lab : http://jhau.maliwi.de/sci/ms.html for initial project and http://fiehnlab.ucdavis.edu/projects/Seven_Golden_Rules/Software/ for fork
install : in /opt/prog/metabolomics/hr2
compilation : g++ HR2_v1.03.cpp -o HR2-all-res_v1.03.exe

The project is available on :
http://fiehnlab.ucdavis.edu/projects/Seven_Golden_Rules/Software/seven-golden-rules-supplement-v46.zip (the launch of the download may take some time)
~/seven-golden-rules-supplement-v46.zip/supplement/HR2-formula-generator/HR2.zip/HR2.cpp
OR
http://sourceforge.net/projects/hires/ : This proposed binary is an fork of the HiRes initial project.
--

## --- Config : --- ##
Edit the config file : /HR2/lib/HR2.conf
lancerHR2=/your/hr2/binary/path/HR2-all-res_v1.03.exe
--

## --- XML HELP PART --- ##
Copy the following images in ~/static/images/metabolomics : 
HR2_View.png
--

## --- DATASETS --- ##
No data set!
--

## --- ??? COMMENTS ??? --- ##
In the PFEM version, the HR2 source (HR2_v*.cpp) is modified to correct atom exact masses.
For more information, please contact us.