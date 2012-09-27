#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Perinci::Examples;
use Perinci::Sub::Util qw(wrapres);

package Foo;

sub foo {
    Perinci::Sub::Util::wrapres(undef, [404, "not found"]);
}

package main;

my $ires = [404, "not found"];

subtest "without error stack" => sub {
    local $ENV{PERINCI_ERROR_STACK};

    is_deeply(wrapres(undef, $ires), [404, "not found"]);
    is_deeply(wrapres([500], $ires), [500, "not found"]);
    is_deeply(wrapres([500, "x"], $ires), [500, "x"]);
    is_deeply(wrapres([500, "x: "], $ires), [500, "x: not found"]);
    is_deeply(wrapres([500, "x", -1], $ires), [500, "x", -1]);
    is_deeply(wrapres([500, "x", -1, {a=>1, b=>2}], $ires),
              [500, "x", -1, {a=>1, b=>2}]);
};

subtest "with error stack" => sub {
    {
        local $ENV{PERINCI_ERROR_STACK} = 1;
        is_deeply(wrapres([500, "x"], $ires),
                  [500, "x", undef, {stack=>[[404, "not found"]]}]);
        is_deeply(wrapres([500, "x", -1, {a=>1, b=>2}], $ires),
                  [500, "x", -1, {a=>1, b=>2, stack=>[[404, "not found"]]}]);
    }
    {
        no warnings;
        local $Perinci::ERROR_STACK = 1;
        is_deeply(wrapres([500, "x"], $ires),
                  [500, "x", undef, {stack=>[[404, "not found"]]}]);
        is_deeply(wrapres([500, "x", -1, {a=>1, b=>2}], $ires),
                  [500, "x", -1, {a=>1, b=>2, stack=>[[404, "not found"]]}]);
    }
    {
        no warnings;
        local $Foo::PERINCI_ERROR_STACK = 1;
        is_deeply(Foo::foo(),
                  [404, "not found", undef, {stack=>[[404, "not found"]]}]);
    }
};

done_testing();
