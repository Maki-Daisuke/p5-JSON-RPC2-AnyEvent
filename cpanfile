requires 'perl', '5.014000';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

requires 'AnyEvent', '7.0';
requires 'JSON';
requires 'Scalar::Util';
requires 'Try::Tiny';

recommends 'JSON::XS';
