use Google::GeoCoder::Smart;

use XML::Simple;
  
 $geo = Google::GeoCoder::Smart->new("method" => "xml");

 my ($resultnum, $error, @results, $returnref) = $geo->geocode("address" => "1600+Amphitheatre+Parkway+Mountain+View,+CA+94043");


$results = XMLin($returnref, ForceArray => [ "results" ]);

$lat = $results[0]{geometry}{location}{lat};

$lon = $results[0]{geometry}{location}{lng};

if($lat) {

if($lon) {

print "You are good to go!\n";

}

else {

print "oops.. didn't work...\n";

};

}

else {

print "oops.. didn't work...\n";

};

