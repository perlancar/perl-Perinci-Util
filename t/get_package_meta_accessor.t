#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Perinci::Examples;
use Perinci::Util qw(get_package_meta_accessor);
use Scalar::Util qw(reftype);

package Bar;

package Foo;
our $PERINCI_META_ACCESSOR = 'Bar';

package main;

subtest 'default class' => sub {
    my $res = get_package_meta_accessor(package=>"Perinci::Examples");
    is($res->[0], 200, "status");
    my $ma = $res->[2];
    is($ma, "Perinci::MetaAccessor::Default", "result");

    $res = $ma->get_meta("Perinci::Examples", "");
    is($res->{summary}, "This package contains various examples",
       "get_meta :package (result)");

    $res = $ma->get_meta("Perinci::Examples", "delay");
    is($res->{summary}, "Tidur, defaultnya 10 detik",
       "get_meta delay");

    $res = $ma->get_all_metas("Perinci::Examples");
    ok($res->{":package"} && $res->{delay}, "get_all_metas");

    $ma->set_meta("Perinci::Examples", "foo", {v=>1.1, summary=>"foo"});
    $res = $ma->get_meta("Perinci::Examples", "foo");
    is($res->{summary}, "foo", "set_meta");
};

subtest 'PERINCI_META_ACCESSOR' => sub {
    my $res = get_package_meta_accessor(package=>"Foo");
    is($res->[0], 200, "status");
    my $ma = $res->[2];
    is($ma, "Bar", "result");
};

done_testing();
