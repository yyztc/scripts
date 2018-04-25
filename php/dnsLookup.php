<?php
set_include_path('/Users/bbrown/pear/share/pear');
require_once 'Net/DNS2.php';

// command-line arguments
function parseArgs($argv){
    array_shift($argv);
    $out = array();
    foreach ($argv as $arg){
        if (substr($arg,0,2) == '--'){
            $eqPos = strpos($arg,'=');
            if ($eqPos === false){
                $key = substr($arg,2);
                $out[$key] = isset($out[$key]) ? $out[$key] : true;
            } else {
                $key = substr($arg,2,$eqPos-2);
                $out[$key] = substr($arg,$eqPos+1);
            }
        } else if (substr($arg,0,1) == '-'){
            if (substr($arg,2,1) == '='){
                $key = substr($arg,1,1);
                $out[$key] = substr($arg,3);
            } else {
                $chars = str_split(substr($arg,1));
                foreach ($chars as $char){
                    $key = $char;
                    $out[$key] = isset($out[$key]) ? $out[$key] : true;
                }
            }
        } else {
            $out[] = $arg;
        }
    }
    return $out;
}

$params = parseArgs($argv);
$domain = $params['D'];
if(!isset($domain)) {
	echo "No argument specified.\n";
	die;
}

$r = new Net_DNS2_Resolver(array('nameservers' => array('8.8.8.8', '8.8.4.4')));

try {
	$result = $r->query($domain, 'ANY');
} catch(Net_DNS2_Exception $e) {
	echo $e . "\n";
	die;
}

var_dump($result);

?>
