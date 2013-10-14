use strict;
use Test::More;

use JSON::RPC::AnyEvent;
use JSON::RPC::AnyEvent::Constants qw(:all);

my $jra = JSON::RPC::AnyEvent->new(
    echo => sub{
        my ($cv, $args) = @_;
        $cv->($args);
    },
);
isa_ok $jra, 'JSON::RPC::AnyEvent', 'new object';

my $res = $jra->dispatch({
    jsonrpc => '2.0',
    id      => 0,
    params  => [qw(hoge fuga)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 0;
is $res->{result}, undef;
isa_ok $res->{error}, 'HASH';
is $res->{error}{code}, ERR_INVALID_REQUEST;

$res = $jra->dispatch({
    jsonrpc => '2.0',
    method  => 'echo',
    id      => 1,
    params  => [qw(hoge fuga)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 1;
isa_ok $res->{result}, 'ARRAY';
is $res->{result}[0], 'hoge';
is $res->{result}[1], 'fuga';

done_testing;

