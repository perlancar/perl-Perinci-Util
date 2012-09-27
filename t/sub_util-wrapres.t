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
                  [500, "x", undef, {
                      error_stack=>[[404, "not found", undef, {}]]}]);
        is_deeply(wrapres([500, "x", -1, {a=>1, b=>2}], $ires),
                  [500, "x", -1, {
                      a=>1, b=>2,
                      error_stack=>[[404, "not found", undef, {}]]}]);
    }
    {
        no warnings;
        local $Perinci::ERROR_STACK = 1;
        is_deeply(wrapres([500, "x"], $ires),
                  [500, "x", undef, {
                      error_stack=>[[404, "not found", undef, {}]]}]);
        is_deeply(wrapres([500, "x", -1, {a=>1, b=>2}], $ires),
                  [500, "x", -1, {
                      a=>1, b=>2,
                      error_stack=>[[404, "not found", undef, {}]]}]);
    }
    {
        no warnings;
        local $Foo::PERINCI_ERROR_STACK = 1;
        is_deeply(Foo::foo(),
                  [404, "not found", undef, {
                      error_stack=>[[404, "not found", undef, {}]]}]);
    }
};

subtest "building error stack" => sub {
    local $Perinci::ERROR_STACK = 1;

    my $res1 = wrapres([2, 2], [1, 1]);
    my $res2 = wrapres([3, 3], $res1);
    my $res3 = wrapres([3, 3], $res2);

    my $es = $res3->[3]{error_stack};
    is_deeply($res3->[3]{error_stack}, $res2->[3]{error_stack},
              "error stack is not duplicated (3 & 2)");
};

done_testing();
