#!/usr/bin/perl

use Data::Dumper;
use DBI;
use DBD::Oracle qw(:ora_types :ora_session_modes);
use JSON;
use strict;

# make connection string
my $dbh = DBI->connect("dbi:Oracle:host=127.0.0.1;sid=cwiering1",
  'coco','coco') || die("error: " . DBI->errstr);
$dbh->{AutoCommit} = 1;

# load the JSON for captions
open(FILE,'/home/chris/annotations/captions_train2017.json');
my $jsonin = <FILE>;
close(FILE);

# parse it
my $jsonhash = decode_json $jsonin;

# loop through all the images; check if there, if NOT, then populate it
foreach my $image (@{$jsonhash->{'images'}}) {
  print Dumper($image);
  # check to see if this one is populated already
  my $sth = $dbh->prepare('SELECT COUNT(*) AS NUMRECORDS FROM IMAGE WHERE ID=?');
  $sth->execute($image->{'id'});

  # fetch it
  my $ref = $sth->fetchrow_hashref();
  if(defined($ref->{'NUMRECORDS'}) && $ref->{'NUMRECORDS'} >= 1) { next; }

  # no records, so insert it
  my $sth = $dbh->prepare("INSERT INTO IMAGE VALUES(?,?,?,?,?,?,?,TO_DATE(?,'YYYY-MM-DD HH24:MI:SS'))");
  $sth->execute($image->{'id'},$image->{'width'},$image->{'height'},
    $image->{'file_name'},$image->{'license'},$image->{'flickr_url'},
    $image->{'coco_url'},$image->{'date_captured'});
  
  # echo out printed
  printf("INSERTED id = %d\n",$image->{'id'});
}

# exit out
exit;
