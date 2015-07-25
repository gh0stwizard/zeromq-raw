#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';
use blib;

use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants
  qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_FD ZMQ_DONTWAIT ZMQ_EVENTS ZMQ_POLLIN);

use EV;
use AnyEvent;

my $c = ZeroMQ::Raw::Context->new( threads => 1 );
my $s = ZeroMQ::Raw::Socket->new( $c, ZMQ_SUB );
$s->connect( 'tcp://127.0.0.1:1234' );
$s->setsockopt( ZMQ_SUBSCRIBE, 'debug:' );
my $fh = $s->getsockopt( ZMQ_FD );

my $w = AE::io $fh, 0, sub {
    ( $s->getsockopt( ZMQ_EVENTS ) & ZMQ_POLLIN ) == ZMQ_POLLIN
      or return;
    my $m = ZeroMQ::Raw::Message->new;
    $s->recvmsg( $m, ZMQ_DONTWAIT );
    say $m->data();
    EV::feed_fd_event $fh, EV::READ; # XXX
};

AE::cv->recv;
