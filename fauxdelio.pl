#!/usr/local/bin/perl -w
use strict;
use v5.22.1;
use warnings;
use Data::Faker qw();
use Data::Dumper;
use Getopt::Long;
use Const::Fast;
use Data::UUID;
use POSIX 'strftime';
use POE qw(Component::Server::TCP Filter::Reference Filter::Line);

BEGIN {
  say "//~~~~~~~~~~~~~~~~~~~~~~~~~~\\\\";
}

$|++;

#############################################################
# hex values for start/end and delimiter
#############################################################
const my $STX => chr(2);
const my $ETX => chr(3);
const my $US => chr(31);

my $counter = 0;
my $lastSent = 0;
my $connected = 0;
my ($delay, $port, @requests, $manifest, $count);

my $faker = Data::Faker->new();
my %fakeData;


my $postingResponse = <DATA>;

my $opts = GetOptions(
  'd|delay=s'   => \$delay,
  'p|port=s'    => \$port,
  'c|count=s'   => \$count
);

$delay = 1 unless defined $delay;
$port = 2019 unless defined $port;
$count = 3 unless defined $count;


my @CorP = ('P');
my @genders = ('M', 'F');
my @loyaltyGroups = ("WAVESBLACK", "WFSO", "WFNA", "WFCO", "WFCO", "PWC1", "PWC2", "PWN1", "PWN2", "PWS1", "PWS2", "FREE100");
my $totalCabins = $count / 2;
my @cabins = (1000..$totalCabins + 1000);
my @nationalities = ('US', 'CA', 'CH');

buildManifest();

POE::Component::Server::TCP->new(
  Port => $port,
  ClientError => sub {
    my ($syscall_name, $error_num, $error_str) = @_[ARG0..ARG2];
    say "Got client error $error_str";
  },
  ClientFilter => POE::Filter::Line->new( OutputLiteral => "", InputLiteral => $ETX),
  ClientConnected => sub {
    my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];
    say "got a connection from client";
    $connected = 1;
    #$kernel->delay('send_it' => $delay);
    #$heap->{client}->put('hello');
  },
  ClientDisconnected => sub {
    my ($kernel, $head, $args) = @_[KERNEL, HEAP, ARG0];
    $connected = 0;
    say "client disconnected, resetting queue";

    $kernel->alarm_remove_all();
    @requests = [];
  },
  ClientInput => sub {
    my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

    say "got input $request";

    $counter++;

    if($request =~ m/BuildManifest/) {
        $kernel->yield('build_manifest');
    }

    if($request =~ m/Posting/) {
      $kernel->yield('trans_response' => $request);
    }else{
      $kernel->yield('manifest_response');
    }
  },

  InlineStates => {
      trans_response      => \&transResponse,
      manifest_response   => \&manifestResponse,
      build_manifest      => \&buildManifest,
      send_it             => \&sendIt
   }
);

#############################################################
#
sub manifestResponse {
    my ($kernel, $heap, $request) =  @_[KERNEL, HEAP, ARG0];
    say "sending $count records of passenger manifest...";
    say "$manifest\n";

    if ($connected){
      $heap->{client}->put($manifest);
    }else{
      say "Client not connected";
    }
}

#############################################################
#
sub transResponse {
    my ($kernel, $heap, $request) =  @_[KERNEL, HEAP, ARG0];

    $request =~ /RQN=(\d+)(?{$US})/;
    my $number = $1 || 000000;
    my $new_response = $postingResponse;
    $new_response =~ s/XXXXXX/$number/g;

    say "Scheduling Response $number to be sent in $delay secs";

    push(@requests, $new_response);
}

sub sendIt {
    my ($kernel, $heap, $response) =  @_[KERNEL, HEAP, ARG0];

    if (@requests > 0 && $connected == 1) {
      my $new_response = pop(@requests);
      say "sending message to client $new_response";
      $heap->{client}->put($new_response);
    }
    $kernel->delay('send_it' => $delay);
}

sub buildManifest {

    #my ($request) = @_;
    #my ($letter) = $request =~ m/ACI=([A-Z])(?{$US})/;
    #
    #say "$letter  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";

    my $today = POSIX::strftime("%s", localtime);
    my $embarkation = POSIX::strftime("%Y-%m-%d %T%z", localtime);
    my @headerFields = ("InquireResponse", "REF=DsiServer", "RQN=$today", "DTE=$today");
    my $record = $STX.join($US, @headerFields);

    my $ug    = Data::UUID->new;

    foreach my $cntr (1..$count){
        say "creating record $cntr";

        my $expiration = POSIX::strftime("%Y-%m-%d %T%z", localtime (time + (86400 * (30 + $cntr))));
        my $minor = 'N';
        my $balance = $cntr + 1000;
        my $creditLimit = $balance + 20;
        my $uuid  = $ug->create();
        my $str   = substr($ug->to_string( $uuid ), 0, 5);
        my $folio = "$str$cntr";

        my $firstname = $faker->first_name;
        my $lastname = $faker->last_name;
        my $cabin = getRandom(@cabins);
        my $dob = "1981-01-01";

        if ($cntr == 1){
            $folio = "FIXEDFOLIO";
            $firstname = "carlitos";
            $lastname = "way";
            $cabin = "44";
            $dob = "2019-11-01";
        }

        my @arr = (
                "ACI$cntr=$folio",
                "ACT$cntr=".getRandom(@CorP),
                "ENB$cntr=1",
                "CAB$cntr=$cabin",
                "NAT$cntr=".getRandom(@nationalities),
                "EMB$cntr=$embarkation",
                "DIS$cntr=$expiration",
                "DOB$cntr=$dob",
                "BAL$cntr=$balance",
                "FST$cntr=$firstname",
                "LST$cntr=$lastname",
                "EML$cntr=".$faker->email,
                "SML$cntr=".getRandom(@loyaltyGroups),
                "FRQ$cntr=".getRandom(@loyaltyGroups),
                "GND$cntr=".getRandom(@genders),
                "MIN$cntr=".$minor,
                "ADD$cntr=".$faker->street_address,
                "CTY$cntr=".$faker->city,
                "STT$cntr=FL",
                "PIN$cntr=$folio",
                "AWD$cntr=".getRandom(@loyaltyGroups),
                "CLM$cntr=$creditLimit",
                "CS1$cntr=".getRandom(@loyaltyGroups),
                "TEL$cntr=$cntr-8675309"
            );

        my $newRec = join($US, @arr);

        $record .= $US . $newRec;
    }

    $record .= $ETX;

    my $finalString = withCheckSum($record);
    $manifest = $finalString;
}

sub getRandom {
    my (@arr) = @_;
    my $item = $arr[ rand @arr ];
    return $item;
}

sub withCheckSum {
    my ($stringValue) = @_;
    my $xor;

    my @myVal = split //, $stringValue;

    foreach my $val(split(//,$stringValue)){
         $xor ^= $val;
    }

    my $finalString = $stringValue . $xor;
    return $finalString;
}

say "Starting server on port $port";


$poe_kernel->run();

__DATA__
PostingResponseREF=DsiServerRQN=XXXXXXDTE=2015-10-22 04:00:12ACI=894854ACT=PNAM=MRS BARBARA BAILEYCAB=7031EMB=2010-03-18 00:00:00DIS=2010-03-31 00:00:00BAL=1071193CRU=1581POI=1445544012OCI=940285PTI=1573223

