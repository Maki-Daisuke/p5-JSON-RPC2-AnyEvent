package JSON::RPC::AnyEvent;
use 5.010000;
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent;
use Carp 'croak';
use JSON;
use Scalar::Util 'reftype';
use Try::Tiny;

use JSON::RPC::AnyEvent::Constants qw(:all);


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    while ( @_ ) {
        my $method = shift;
        my $spec   = shift;
        if ( reftype $spec eq 'CODE' ) {
            $self->register($method, $spec);
        } else {
            $self->register($method, $spec, shift);
        }
    }
    $self;
}

sub dispatch {
    my $self = shift;
    my $json = shift;
    my $ret_cv = AE::cv;
    try{
        my $type = _check_format($json);  # die when $json's format is invalid
        my $method = $self->{$json->{method}};
        unless ( $method ) {  # Method not found
            $ret_cv->send(_make_error_response($json->{id}, ERR_METHOD_NOT_FOUND, 'Method not found'));
            return $ret_cv;
        }
        if ( $type eq 'c' ) {  # RPC call
            $method->(AE::cv{
                my $cv = shift;
                try{
                    $ret_cv->send(_make_response($json->{id}, $cv->recv));
                } catch {
                    $ret_cv->send(_make_error_response($json->{id}, ERR_SERVER_ERROR, 'Server error', shift));
                };
            }, $json->{params});
            return $ret_cv;
        } else {  # Notification request (no response)
            $method->(AE::cv, $json->{params});  # pass dummy cv
            return $ret_cv;
        }
    } catch {  # Invalid request
        my $err = _make_error_response((reftype $json eq 'HASH' ? $json->{id} : undef), ERR_INVALID_REQUEST, 'Invalid Request', shift);
        $ret_cv->send($err);
        return $ret_cv;
    };
}

sub _check_format {
    # Returns
    #    "c"  : when the value represents rpc call
    #    "n"  : when the value represents notification
    #    croak: when the value is in invalid format
    my $json = shift;
    reftype $json eq 'HASH'                                                      or croak "JSON-RPC request MUST be an Object (hash)";
    #$json->{jsonrpc} eq "2.0"                                                   or croak "Unsupported JSON-RPC version";  # This module supports only JSON-RPC 2.0 spec, but here just ignores this member.
    exists $json->{method} && not ref $json->{method}                            or croak "`method' MUST be a String value";
    if ( exists $json->{params} ) {
        reftype $json->{params} eq 'ARRAY' || reftype $json->{params} eq 'HASH'  or croak "`params' MUST be an array or an object";
    } else {
        $json->{params} = [];
    }
    return 'n' unless exists $json->{id};
    not ref $json->{id}                                                          or croak "`id' MUST be neighter an array nor an object";
    return 'c';
}

sub _make_response {
    my ($id, $result) = @_;
    {
        jsonrpc => '2.0',
        id      => $id,
        result  => $result,
    };
}

sub _make_error_response {
    my ($id, $code, $msg, $data) = @_;
    {
        jsonrpc => '2.0',
        id      => $id,
        error   => {
            code    => $code,
            message => "$msg",
            (defined $data ? (data => $data) : ()),
        },
    };
}


sub register {
    my $self   = shift;
    my ($method, $spec, $code) = @_;
    if ( UNIVERSAL::isa($spec, "CODE") ) {  # spec is omitted.
        $code = $spec;
        $spec = sub{ $_[0] };
    } else {
        $spec = _compile_argspec($spec);
        croak "`$code' is not CODE ref"  unless UNIVERSAL::isa($code, 'CODE');
    }
    $self->{$method} = sub{
        my ($cv, $params) = @_;        
        $code->($cv, $spec->($params), $params);
    };
}

sub _parse_argspec {
    my $orig = my $spec = shift;
    if ( $spec =~ s/^\s*\[// ) {  # Wants array
        croak "Invalid argspec. Unmatched '[' in argspec: $orig"  unless $spec =~ s/\]\s*$//;
        my @parts = split /\s*,\s*/, $spec;
        return sub{
            my $params = shift;
            return $params  if UNIVERSAL::isa($params, 'ARRAY');
            # Got a hash! Then, convert it to an array!
            my $args = [];
            push @$args, $params->{$_}  foreach @parts;
            return $args;
        };
    } elsif ( $spec =~ s/\s*\{// ) {  # Wants hash
        croak "Invalid argspec. Unmatched '{' in argspec: $orig"  unless $spec =~ s/\}\s*$//;
        my @parts = split /\s*,\s*/, $spec;
        return sub{
            my $params = shift;
            return $params  if UNIVERSAL::isa($params, 'HASH');
            # Got an array! Then, convert it to a hash!
            my $args = {};
            for ( my $i=0;  $i < @parts;  $i++ ) {
                $args->{$parts[$i]} = $params->[$i];
            }
            return $args;
        };
    } else {
        croak "Invalid argspec. Argspec must be enclosed in [] or {}: $orig";
    }
}



1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::AnyEvent - It's new $module

=head1 SYNOPSIS

    use JSON::RPC::AnyEvent;

    my $jra = JSON::RPC::AnyEvent->new;
    $jra->register(a_method => "[param1, param2]" => sub{
        my ($cv $args_arr, $original_args) = @_;
        do_some_async_task(sub{
            # Done!
            $cv->send($result);
        });
    });
    
    my $cv = $j->dispatch($req);
    my $res = $cv->recv;
    
    # For Notification Request, just returns undef.
    my $res = $jra->dispatch({jsonrpc => "2.0", method => "a_method", ["some", "values"]})->recv;  # Non-bloking when "id" is omitted.
    not defined $res;  # true


=head1 DESCRIPTION

JSON::RPC::AnyEvent is ...

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

