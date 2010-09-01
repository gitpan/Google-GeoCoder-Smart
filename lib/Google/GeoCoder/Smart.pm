

package Google::GeoCoder::Smart;

require Exporter;

use LWP::Simple qw(!head);

our @ISA = qw(Exporter);

our @EXPORT = qw(new geocode parse);

our $VERSION = 1.12;

=head1 NAME

Smart - Google Maps Api HTTP geocoder

=head1 SYNOPSIS

 use Google::GeoCoder::Smart;
  
 $geo = Google::GeoCoder::Smart->new();

 my ($resultnum, $error, @results) = $geo->geocode("address" => *your address here*);

 foreach $result(@results) {

 my (%params) = $geo->parse($result);

 $lat = $params{'lat'};

 $lon = $params{'lon'};

 };

=head1 DESCRIPTION

This module provides a simple and "Smart" interface to the Google Maps geocoding API. 

It is compatible with the google maps http geocoder v3.

It is based on the current format of the xml returned by the API. If Google changes their format, 

this module might stop working. The only dependency that this module has is the LWP::Simple module, 

and its sub-dependencies. I wanted something that was adaptable and would return results 

automaticaly formatted for perl. 

#################################################

MAKE SURE TO READ GOOGLE's TERMS OF USE

they can be found at http://code.google.com/apis/maps/terms.html#section_10_12

#################################################

If you find any bugs, please let me know. 

=head1 METHODS

=head2 new

	$geo = Google::GeoCoder::Smart->new("key" => "your api key here", "host" => "host here");

the new function normally is called with no parameters.

however, If you would like to, you can pass it your Google Maps api key and a host name.

the api key parameter is useful for the api premium service.

the host paramater is only necessary if you use a different google host than google.com, 

such as google.com.eu or something like that.http://code.google.com/apis/maps/terms.html#section_10_12

=head2 geocode

	my ($num, $error, @results) = $geo->geocode(

	"address" => "address *or street number and name* here", 

	"city" => "city here", 

	"state" => "state here", 

	"zip" => "zipcode here"

	);

This function brings back the number of results found for the address and 

the results in an array. This is the case because Google will sometimes return

many different results for one address.

The geocode method will work if you pass the whole address as the "address" tag.
 
However, it also supports breaking it down into parts.

Once I implement a validation function, breaking it down into parts will be the

best thing to do if you wish to validate the results brought back.

####################################

New Update to the geocode function.

In the older versions of this module, I had it die if google returned an error.

This version sends back the error as a scalar value. 

It will return one of the following error messages if an error is encountered

	connection  #something went wrong with the download

	limit       #the google query limit has been exceeded. Try again 24 hours from when you started geocoding

	no_result   #no results were found for the address entered

=head2 parse

	%params = $geo->parse($result);

parse takes any result text passed to it and parses it out into the corresponding values.

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

bless {"key" => $key, "host" => $host};

}

sub geocode {

my ($self, %params) = @_;

$addr = delete $params{'address'};

$CITY = delete $params{'city'};

$STATE = delete $params{'state'};

$ZIP = delete $params{'zip'};

my $content = get("http://$self->{host}/maps/api/geocode/xml?address=$addr $CITY $STATE $ZIP&sensor=false");

undef $err;

undef $error;

if($content =~ m/ZERO_RESULTS/) {

$error = "no_result";

};

if($content =~ m/OVER_QUERY_LIMIT/) {

$error = "limit";

};

unless(defined $content) {

$error = "connection";

};

@results = split /<\/result>/, $content;

pop @results;

my $length = @results;

return $length, $error, @results;

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


