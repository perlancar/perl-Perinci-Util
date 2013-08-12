#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Perinci::Examples;
use Perinci::Util qw(get_package_meta_accessor);
use Scalar::Util qw(reftype);

package Bar;

sub new { bless {}, shift }

package Foo;
our $PERINCI_META_ACCESSOR = 'Bar';

package Foo2;
our $PERINCI_META_ACCESSOR = Bar->new;

package Foo3;
require Perinci::MetaAccessor::Default;
our $PERINCI_META_ACCESSOR = Perinci::MetaAccessor::Default->new(var => 'META');
our %META;
$META{':package'} = { v=>1.1, summary=>'foo three' };

package main;

subtest 'default class (class)' => sub {
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

subtest 'default class (object)' => sub {
    my $res = get_package_meta_accessor(package=>"Foo3");
    is($res->[0], 200, "status");
    my $ma = $res->[2];
    is(ref($ma), "Perinci::MetaAccessor::Default", "result");

    $res = $ma->get_meta("Foo3", "");
    is($res->{summary}, "foo three",
       "get_meta :package (result)");
};

subtest 'PERINCI_META_ACCESSOR (class)' => sub {
    my $res = get_package_meta_accessor(package=>"Foo");
    is($res->[0], 200, "status");
    my $ma = $res->[2];
    is($ma, "Bar", "result");
};

subtest 'PERINCI_META_ACCESSOR (object)' => sub {
    my $res = get_package_meta_accessor(package=>"Foo2");
    is($res->[0], 200, "status");
    my $ma = $res->[2];
    is(ref($ma), "Bar", "result");
};

DONE_TESTING:
done_testing();
