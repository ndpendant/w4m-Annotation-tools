## ****** HMDB environnemnt : ****** ##
# version 2014-05-07 M Landi / F Giacomoni

## --- PERL compilator / libraries : --- ##
$ perl -v
This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi

# libs CORE PERL : 
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;
use Exporter ;
use Data::Dumper ;
use Getopt::Long ;
use FindBin ;
use Encode;

# libs CPAN PERL : 
$ perl -e 'use Text::CSV'
$ perl -e 'use LWP::Simple'
$ perl -e 'use URI::URL'
$ perl -e 'use SOAP::Lite'
$ perl -e 'use HTML::Template'
$ sudo perl -MCPAN -e shell
cpan> install Text::CSV
cpan> install LWP::Simple
cpan> install URI::URL
cpan> install SOAP::Lite
cpan>  install HTML::Template

# libs pfem PERL : include the lib called pfem-perl in your PERL5LIB path. This lib is available in the ABIMS toolshed "Tool Dependency Packages" category.
use conf::conf  qw( :ALL ) ;
use formats::csv  qw( :ALL ) ;
--

## --- R bin and Packages : --- ##
No interaction with R
-- 

## --- Binary dependencies --- ##
No interaction with binary - use only HMDB post method (http://www.hmdb.ca/spectra/ms/search?)
--

## --- Config : --- ##
Edit the following lines in the config file : ~/metabolomics/Identification/Banks_Queries/HMDB/conf_hmdb.cfg
JS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/scripts/libs/outputs
CSS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/style
HTML_TEMPLATE=absolute_path_to_/hmdb.tmpl

--

## --- XML HELP PART --- ##
Copy the following images in ~/static/images/metabolomics
--

## --- DATASETS --- ##
No data set ! waiting for galaxy pages
--

## --- ??? COMMENTS ??? --- ##
To use full funtionalities of html output files : 
  - check that sanitize_all_html option in universe_wsgi.ini file is uncomment and set to FALSE.
  - copy the following JS files in YOUR_GALAXY_PATH/static/scripts/libs/outputs/ : jquery.simplePagination.js
  - copy the following CSS files in YOUR_GALAXY_PATH/static/style/ : simplePagination.css
 Their files (pfem-js and pfem-css) are available in the ABIMS toolshed "Tool Dependency Packages" category.
--