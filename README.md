# NAME

JSON::RPC2::AnyEvent - It's new $module

# SYNOPSIS

    use JSON::RPC2::AnyEvent::Server;

    my $jra = JSON::RPC2::AnyEvent::Server->new;
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



# DESCRIPTION

JSON::RPC2::AnyEvent is ...

# LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke (yet another) Maki <maki.daisuke@gmail.com>
