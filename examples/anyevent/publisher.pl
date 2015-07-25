#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';
use blib;

use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants
  qw(ZMQ_PUB ZMQ_SUBSCRIBE ZMQ_FD ZMQ_DONTWAIT ZMQ_EVENTS ZMQ_POLLOUT);

use AnyEvent;

my $c = ZeroMQ::Raw::Context->new(threads => 1);
my $s = ZeroMQ::Raw::Socket->new( $c, ZMQ_PUB );
$s->bind('tcp://lo:1234');

my $i = 0;
my $fh = $s->getsockopt( ZMQ_FD );
my $w = AE::io $fh, 1, sub {
    # XXX: duplicate call
    ( $s->getsockopt( ZMQ_EVENTS ) & ZMQ_POLLOUT ) == ZMQ_POLLOUT
      or return;
    my $str = "debug: message $i";
    my $m = ZeroMQ::Raw::Message->new_from_scalar($str);
    $s->sendmsg( $m, ZMQ_DONTWAIT );
    $s->getsockopt( ZMQ_EVENTS );
    say $str;
    $i++;
#    sleep 1;
};

AE::cv->recv;
