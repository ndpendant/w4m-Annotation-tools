## ****** wsdl_chemspider environnemnt : ****** ##
# version 2014.05.07 N Paulhe / M Landi / F Giacomoni

## --- PERL compilator / libraries : --- ##
$ perl -v
This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi

# libs CORE PERL : 
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;
use Data::Dumper ;
use Getopt::Long ;
use POSIX ;
use FindBin ;

# libs CPAN PERL : 
No specific modules needed

# libs pfem PERL : 
use conf::conf  qw( :ALL ) ;
use formats::csv  qw( :ALL ) ;
use formats::json  qw( :ALL ) ;
use logs::logtools  qw( :ALL ) ;
--

## --- R bin and Packages : --- ##
No interaction with R
-- 

## --- Binary dependencies --- ##
Install following binaries : metabolicBankWS_client-0.1.jar
Make sure about last release by consulting the PFEM Maven repository available at https://www1.clermont.inra.fr/maven/
You need to install it on your server and configure it.
A security token is require for Chemspider WS : please contact https://www.chemspider.com/AboutServices.aspx
Open the jar binary with your favorite file archiver and fill in ~/config.properties, the "chemSpider.token" field with your own token.
--

## --- Config : --- ##
Edit the following lines in the config file : ~/metabolomics/identification/banks_queries/chemspider-ws/conf_chemspider.cfg
EXE=absolute_path_to_/metabolicBankWS_client-0.1.jar
JS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/scripts/libs/outputs
CSS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/style
HTML_TEMPLATE=absolute_path_to_/chemspider_out.tmpl
--

## --- XML HELP PART --- ##
No image is available for ~/static/images/metabolomics : 
--

## --- DATASETS --- ##
--

## --- ??? COMMENTS ??? --- ##
--