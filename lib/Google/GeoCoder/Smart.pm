

package Google::GeoCoder::Smart;

require Exporter;

use LWP::Simple qw(!head);

use JSON;

our @ISA = qw(Exporter);

our @EXPORT = qw(new geocode parse);

our $VERSION = 1.13;

=head1 NAME

Smart - Google Maps Api HTTP geocoder

=head1 SYNOPSIS

 use Google::GeoCoder::Smart;
  
 $geo = Google::GeoCoder::Smart->new();

 my ($resultnum, $error, @results, $returncontent) = $geo->geocode("address" => *your address here*);

 $resultnum--;

 for $num(0 .. $resultnum) {

 $lat = $results[$num]{geometry}{location}{lat};

 $lng = $results[$num]{geometry}{location}{lng};

 };

=head1 DESCRIPTION

This module provides a simple and "Smart" interface to the Google Maps geocoding API. 

It is compatible with the google maps http geocoder v3.

the XML parsing is based on the current format of the xml returned by the API. 

If Google changes their format, it might stop working. 

This module only depends on LWP::Simple and JSON. 

#################################################

MAKE SURE TO READ GOOGLE's TERMS OF USE

they can be found at http://code.google.com/apis/maps/terms.html#section_10_12

#################################################

If you find any bugs, please let me know. 

=head1 METHODS

=head2 new

	$geo = Google::GeoCoder::Smart->new("method" => "json", "key" => "your api key here", "host" => "host here");

the new function normally is called with no parameters.

however, If you would like to, you can pass it your result format, Google Maps api key and a host name.

the default result format is json. However, if you wish to use my own homemade XML parsing,

or if you want the whole xml file for other purposes, you can specify xml in the "method" argument. 

the api key parameter is useful for the api premium service.

the host paramater is only necessary if you use a different google host than google.com, 

such as google.com.eu or something like that.http://code.google.com/apis/maps/terms.html#section_10_12

=head2 geocode

	my ($num, $error, @results, $returntext) = $geo->geocode(

	"address" => "address *or street number and name* here", 

	"city" => "city here", 

	"state" => "state here", 

	"zip" => "zipcode here"

	);

This function brings back the number of results found for the address and 

the results in an array. This is the case because Google will sometimes return

many different results for one address.

It also returns the result text for debugging purposes.

The geocode method will work if you pass the whole address as the "address" tag.
 
However, it also supports breaking it down into parts.

It will return one of the following error messages if an error is encountered

	connection         #something went wrong with the download

	OVER_QUERY_LIMIT   #the google query limit has been exceeded. Try again 24 hours from when you started geocoding

	ZERO_RESULTS       #no results were found for the address entered

If no errors were encountered it returns the value "OK"

If you are using xml, you will have to run the parse method on each result in the array to bring back values from it. 

If you use the json format, you can get the returned parameters easily through refferences. 

	$lat = $results[0]{geometry}{location}{lat};

	$lng = $results[0]{geometry}{location}{lng};

When using the JSON method, it is helpful to know the format of the json returns of the api. 

A good example can be found at http://www.google.com/maps/apis/geocode/json?address=1600+Amphitheatre+Parkway+Mountain+View,+CA+94043&sensor=false

=head2 parse

	%params = $geo->parse($result);

Parse is only useful for the xml parameter. It takes any result text passed to it and parses it out into the corresponding values.

It is how you get the lat and lon values for the result. 

It will also bring back several other parameters that might be of interest to some. 


it returns: 

	lat             #the lattitude of the result

	lon             #the longitude of the result

	formattedaddr   #the formatted address of the result

	streetnum       #the street number of the result

	streets         #the streets returned. 

              		#it returns an array because sometimes 

               		#google brings back more than one street name.

	cities          #the cities returned. 

			#its an array because sometimes google

			#sometimes brings back more than one city


	state		#the state returned by google for the result *administrative_area_level_1 for those outside the US

	zip		#zip code of the result

	county		#if applicable, returns the administrative_area_level_2 *which is the county in the US*

	type		#brings back the match type *see the google maps api documentation* 

			#common results are street_address or postal_code

	match		#brings back the match type. it is set to yes if the result is a partial match, 

			#and null if it is a full match


=head1 AUTHOR

TTG, ttg@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by TTG

This library is free software; you can redistribute it and/or modify

it under the same terms as Perl itself, either Perl version 5.10.0 or,

at your option, any later version of Perl 5 you may have available.


=cut

sub new {

my ($junk, %params) = @_;

my $host = delete $params{host} || "maps.google.com";

my $key = delete $params{key};

$json = delete $params{method} || "json";

bless {"key" => $key, "host" => $host, "method" => $json};

}

sub geocode {

my ($self, %params) = @_;

$addr = delete $params{'address'};

$CITY = delete $params{'city'};

$STATE = delete $params{'state'};

$ZIP = delete $params{'zip'};



my $content = get("http://$self->{host}/maps/api/geocode/$self->{method}?address=$addr $CITY $STATE $ZIP&sensor=false");

undef $err;

undef $error;

if($content =~ m/ZERO_RESULTS/) {

$error = "ZERO_RESULTS";

};

if($content =~ m/OVER_QUERY_LIMIT/) {

$error = "OVER_QUERY_LIMIT";

};

unless(defined $content) {

$error = "connection";

};

unless(defined $error) {

$error = "OK";

};

undef @results;


if($self->{method} eq "xml") {

@results = split /<\/result>/, $content;

pop @results;

};

if($self->{method} eq "json") {

$results_json  = decode_json $content;

#$error = $results_json->{results}[0];

#@results = \$results_json->{results};

$error = $results_json->{status};

foreach $res($results_json->{results}[0]) {

@push = ($res);



push @results, @push;


};


};



my $length = @results;

return $length, $error, @results, $content;

}

sub parse {

my ($self, $result) = @_;

$content = $result;



@lines = split /
/, $content;

$linelength = @lines;

$linelength--;

for $num(0 .. $linelength) {

if($lines[$num] =~ m/address_component/) {

$num++;

$var = $lines[$num];

$num++;

$num++;

if($lines[$num] =~ m/street_number/) {


$streetnum = $var;

for($streetnum) {

s/<long_name>//g;

s/<\/long_name>//g;

s/^\s+//;

s/\s+$//;

s/\s+/ /g;


};


};

if($lines[$num] =~ m/locality/) {

$cityreturn = $var;

for($cityreturn) {


s/<long_name>//g;

s/<\/long_name>//g;

s/^\s+//;

s/\s+$//;

s/\s+/ /g;

};



@push = ($cityreturn);

push @cities, @push;

};

if($lines[$num] =~ m/administrative_area_level_1/) {

$number = $num - 1;

$var = $lines[$number];

$statereturn = $var;

for($statereturn) {

s/<short_name>//g;

s/<\/short_name>//g;

s/^\s+//;

s/\s+$//;

s/\s+/ /g;

};



};

if($lines[$num] =~ m/administrative_area_level_2/) {

$countyreturn = $var;

for($countyreturn) {

s/<long_name>//g;

s/<\/long_name>//g;

s/^\s+//;

s/\s+$//;

s/\s+/ /g;


};



};

if($lines[$num] =~ m/route/) {

$stname = $var;

for($stname) {

s/<long_name>//g;

s/<\/long_name>//g;

s/^\s+//;

s/\s+$//;

s/\s+/ /g;

};



@push = ($stname);

push @stnames, @push;

};

if($lines[$num] =~ m/postal_code/) {

$zipcode = $var;

for($zipcode) {

s/<long_name>//g;

s/<\/long_name>//g;

s/ //g;

};


};

};

if ($lines[$num] =~ m/formatted_address/) {

$address = $lines[$num];

$address =~ s/<formatted_address>//g;

$address =~ s/<\/formatted_address>//g;

$address =~ s/^\s+//;

$address =~ s/\s+$//;

$address =~ s/\s+/ /g;

};

if ($lines[$num] =~ m/partial_match/) {

$matchtype = $lines[$num];

for($matchtype) {

s/<partial_match>//g;

s/<\/partial_match>//g;

s/^\s+//;

s/\s+$//;

s/\s+/ /g;

};

};


if ($lines[$num] =~ m/<type>/) {

$type = $lines[$num];

$type =~ s/<type>//g;

$type =~ s/<\/type>//g;

$type =~ s/ //g;

};

if ($lines[$num] =~ m/location/) {

$num++;

$lat = $lines[$num];

$num++;

$lon = $lines[$num];

last;

};

$num++;

};


$address2 = $address;

@params = split / /, $address2;

$addr2 = $addr;

@addrparts = split / /, $addr2;

$street = @addrparts[0];

for($street) {

s/^\s+//;

s/\s+$//;

s/\s+/ /g;

};



$lat =~ s/<lat>//g;

$lat =~ s/<\/lat>//g;

$lat =~ s/ //g;

$lon =~ s/<lng>//g;

$lon =~ s/<\/lng>//g;

$lon =~ s/ //g;

$citylngth--;

return ( "lon" => $lon, "lat" => $lat, "formattedaddr" => $address, "zip" => $zipcode, "state" => $statereturn, "streetnum" => $streetnum, "county" => $countyreturn, "match" => $matchtype, "type" => $type, "streets" => @stnames, "cities" => @cities );

}


1;


