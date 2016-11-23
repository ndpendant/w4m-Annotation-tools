#! perl
use diagnostics;
use warnings;
no warnings qw/void/;
use strict;
no strict "refs" ;
#use Test::More qw( no_plan );
use Test::More tests => 29 ;
use FindBin ;

use lib '//nas-theix/fgiacomoni/BioInfoTools/galaxy_tools/identification/formula_elucidation/hr2/' ;
use lib $FindBin::Bin ;
use lib::hrTest qw( :ALL ) ;

## testing manage_atoms
print "\n-- Test manage_atoms lib\n\n" ;
is( manage_atomsTest('', 'C,H,O,N'),'C,H,O,N', 'Works with void argvt' ) ;
is( manage_atomsTest(undef, 'C,H,O,N'), 'C,H,O,N', 'Works with undef argvt in input');
isnt( manage_atomsTest('C,H,O,N', undef), 'C,H,O,N', 'Doesn\'t work with undef argvt in conf');
is( manage_atomsTest(' ', 'C,H,O,N'), 'C,H,O,N', 'Works with \'space\' argvt in input' ) ;
is( manage_atomsTest('None', 'C,H,O,N'), 'C,H,O,N', 'Works with \'None\' argvt in input' ) ;
isnt( manage_atomsTest('C,H,O,N', 'C,H,O,N'), 'C,H,O,N', 'Doesn\'t work with same argvt in conf and input' );
is( manage_atomsTest('P', 'C,H,O,N'), 'C,H,O,N,P', 'Works with P argvt in input');
is( manage_atomsTest('1', 'C,H,O,N'), 'C,H,O,N,1', 'Works with 13C argvt in input');
is( manage_atomsTest('P,S', 'C,H,O,N'), 'C,H,O,N,P,S', 'Works with P and S argvt in input');
is( manage_atomsTest('X', 'C,H,O,N'), 'C,H,O,N', 'Doesn\'t work with other character diff than [P|S|F|L|K|B|A|1|] in input');
print "\n--\n" ;

print "\n-- Test check_hr_exe lib\n\n" ;
is ( check_hr_exeTest('J:\\BioInfoTools\\_BINARIES\\HR2-all-res.exe', 'hr version 20050617'), 1, 'Works with WIN path and good version') ;
is ( check_hr_exeTest('J:\\BioInfoTools\\_BINARIES\\HR2-all-res.exe', undef), undef, 'Doesn\'t work with WIN path and bad version') ;
is ( check_hr_exeTest('Z:\\BioInfoTools\\TOTO\\HR2-all-res.exe', 'hr version 20050617'), undef, 'Doesn\'t work with bullshit path and good version') ;
is ( check_hr_exeTest(undef, 'hr version 20050617'), undef, 'Doesn\'t work with undef path and good version') ;
# need to test unix path
print "\n--\n" ;

print "\n-- Test manage_tolerance lib --\n\n" ;
is ( manage_toleranceTest( '5.0', '1.0' ), '5.0', 'Works with tolerance of 5.0' ) ;
is ( manage_toleranceTest( '5,0', '1.0' ), '5.0', 'Works with tolerance of 5,0 (french number)' ) ;
is ( manage_toleranceTest( undef, '1.0' ), undef, 'Doesn\'t work with undef tolerance' ) ;
is ( manage_toleranceTest( '5.0', undef ), undef, 'Doesn\'t work with undef default tolerance' ) ;
is ( manage_toleranceTest( '20.0', '1.0' ), '1.0', 'Works with hight tolerance (20.0), use default tolerance' ) ;
is ( manage_toleranceTest( '-10.0', '1.0' ), '1.0', 'Works with negative tolerance (-10.0), use default tolerance' ) ;
print "\n--\n" ;

print "\n-- Test manage_mode lib\n\n" ;
is ( manage_modeTest('positive', '1', '0.0005486', '1.007825', '100.00'), '98.9927236', 'Works and computes right mass (98.9927236) with positive mode and complete conf') ;
is ( manage_modeTest('negative', '1', '0.0005486', '1.007825', '100.00') , '101.0072764', 'Works and computes right mass (101.0072764) with negative mode and complete conf') ;
is ( manage_modeTest('neutral', '1', '0.0005486', '1.007825', '100.00' ), '100.00', 'Works and computes right mass (100.00) with neutral mode and complete conf') ;
is ( manage_modeTest('banane', '1', '0.0005486', '1.007825', '100.00' ), undef, 'Works and warns with unbelievable argt mode') ;
is ( manage_modeTest('positive', '1', '0.0005486', '1.007825', '100,00' ), '98.9927236', 'Works with french mass format in positive mode') ;
is ( manage_modeTest('neutral', '1', undef, undef, '100.00' ), undef, 'Works and warns when missing some conf paramaters (electron, proton, mass)') ;
is ( manage_modeTest('negative', '0', '0.0005486', '1.007825', '100.00') , '101.0072764', 'Works and computes right mass (101.0072764) with negative mode and charge = 0 become 1 ') ;
is ( manage_modeTest('positive', '3', '0.0005486', '1.007825', '100.00'), '298.9938208', 'Works and computes right mass (298.9938208) with positive mode, charge = 3 and complete conf') ;
is ( manage_modeTest('neutral', undef, '0.0005486', '1.007825', '100.00' ), '100.00', 'Works and warns when missing charge') ;
print "\n--\n" ;







