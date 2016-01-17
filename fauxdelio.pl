#!/usr/local/bin/perl -w
use strict;
use v5.22.1;
use warnings;
use Data::Faker;
use Data::Dumper;
use Getopt::Long;
use POE qw(Component::Server::TCP Filter::Reference Filter::Line);

BEGIN {
  say "//~~~~~~~~~~~~~~~~~~~~~~~~~~\\\\";
}

$|++;

#############################################################
# hex values for start/end and delimiter
#############################################################
use constant STX => chr(2);
use constant ETX => chr(3);
use constant US => chr(31);

my $counter = 0;
my $lastSent = 0;
my $connected = 0;
my ($delay, $port, @requests);

open FILE, "fidelioManifest.dat";
my $manifest = <FILE>;
close FILE;

my $postingResponse = <DATA>;

my $opts = GetOptions(
  'd|delay=s'   => \$delay,
  'p|port=s'    => \$port
);

$delay = 1 unless defined $delay;
$port = 2019 unless defined $port;

POE::Component::Server::TCP->new(
  Port => $port,
  ClientError => sub {
    my ($syscall_name, $error_num, $error_str) = @_[ARG0..ARG2];
    say "Got client error $error_str";
  },
  ClientFilter => POE::Filter::Line->new(Literal => ETX),
  ClientConnected => sub {
    my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];
    say "got a connection from client";
    $connected = 1;
    $kernel->delay('send_it' => $delay);
    $heap->{client}->put('hello');
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

    $counter++;
    say "Request #$counter";

    if($request =~ m/Posting/) {
      $kernel->yield('trans_response' => $request);
    }else{
      $kernel->yield('manifest_response');
    }
  },

  InlineStates => {
      trans_response      => \&transResponse,
      manifest_response   => \&manifestResponse,
      send_it             => \&sendIt
   }
);

#############################################################
#
sub manifestResponse {
    my ($kernel, $heap, $request) =  @_[KERNEL, HEAP, ARG0];
    say "sending manifest";

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

    $request =~ /RQN=(\d+)(?{US})/;
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
      say "Sending response...". scalar @requests ." left";
      $heap->{client}->put($new_response);
    }
    $kernel->delay('send_it' => $delay);
}

say "Starting server on port $port";

$poe_kernel->run();

__DATA__
PostingResponseREF=DsiServerRQN=XXXXXXDTE=2015-10-22 04:00:12ACI=894854ACT=PNAM=MRS BARBARA BAILEYCAB=7031EMB=2010-03-18 00:00:00DIS=2010-03-31 00:00:00BAL=1071193CRU=1581POI=1445544012OCI=940285PTI=1573223
