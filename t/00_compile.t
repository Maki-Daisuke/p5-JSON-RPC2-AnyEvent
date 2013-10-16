use strict;
use Test::More;

use_ok $_ for qw(
    JSON::RPC::AnyEvent
    JSON::RPC::AnyEvent::Server
    JSON::RPC::AnyEvent::Server::Handle
);

done_testing;

