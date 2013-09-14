package Perinci::Sub::Util;

use 5.010;
use strict;
use warnings;

use Scalar::Util qw (looks_like_number);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       err
                       caller
                       wrapres
               );

# VERSION

sub err {

    # get information about caller
    my @caller = CORE::caller(1);
    if (!@caller) {
        # probably called from command-line (-e)
        @caller = ("main", "-e", 1, "program");
    }

    my ($status, $msg, $meta, $prev);

    for (@_) {
        my $ref = ref($_);
        if ($ref eq 'ARRAY') { $prev = $_ }
        elsif ($ref eq 'HASH') { $meta = $_ }
        elsif (!$ref) {
            if (looks_like_number($_)) {
                $status = $_;
            } else {
                $msg = $_;
            }
        }
    }

    $status //= 500;
    $msg  //= "$caller[3] failed";
    $meta //= {};
    $meta->{prev} //= $prev if $prev;

    # put information on who produced this error and where/when
    if (!$meta->{logs}) {

        # should we produce a stack trace?
        my $stack_trace;
        {
            no warnings;
            # we use Carp::Always as a sign that user wants stack traces
            last unless $INC{"Carp/Always.pm"};
            # stack trace is already there in previous result's log
            last if $prev && ref($prev->[3]) eq 'HASH' &&
                ref($prev->[3]{logs}) eq 'ARRAY' &&
                    ref($prev->[3]{logs}[0]) eq 'HASH' &&
                        $prev->[3]{logs}[0]{stack_trace};
            $stack_trace = [];
            my $i = 1;
            while (my @c = CORE::caller($i)) {
                push @$stack_trace, \@c;
                $i++;
            }
        }
        push @{ $meta->{logs} }, {
            type    => 'create',
            time    => time(),
            package => $caller[0],
            file    => $caller[1],
            line    => $caller[2],
            func    => $caller[3],
            ( stack_trace => $stack_trace ) x !!$stack_trace,
        };
    }

    [$status, $msg, undef, $meta];
}

sub caller {
    my $n0 = shift;
    my $n  = $n0 // 0;

    my $pkg = $Perinci::Sub::Wrapper::default_wrapped_package //
        'Perinci::Sub::Wrapped';

    my @r;
    my $i =  0;
    my $j = -1;
    while ($i <= $n+1) { # +1 for this sub itself
        $j++;
        @r = CORE::caller($j);
        last unless @r;
        if ($r[0] eq $pkg && $r[1] =~ /^\(eval /) {
            next;
        }
        $i++;
    }

    return unless @r;
    return defined($n0) ? @r : $r[0];
}

sub wrapres {
    my ($ores, $ires) = @_;

    $ores //= [];
    my $istatus;
    unless (defined $ores->[0]) {
        $ores->[0] = $ires->[0];
        $istatus++;
    }
    if ($ores->[1] && $ores->[1] =~ /: \z/) {
        $ores->[1] .= $istatus ? $ires->[1] : "$ires->[0] - $ires->[1]";
    } else {
        $ores->[1] //= $ires->[1];
    }
    if (defined($ires->[2]) || @$ires > 2) {
        $ores->[2] //= $ires->[2];
    }

    # should we build error stack?
    my $build_es = $ENV{PERINCI_ERROR_STACK} || $Perinci::ERROR_STACK;
    if (!$build_es) {
        no strict 'refs';
        my @c = CORE::caller(0);
        $build_es ||= ${"$c[0]::PERINCI_ERROR_STACK"};
    }

    if ($build_es) {
        $ores->[3] //= {};
        $ores->[3]{error_stack} //= $ires->[3]{error_stack};
        unshift @{ $ores->[3]{error_stack} }, $ires;
    }

    $ores;
}

1;
# ABSTRACT: Helper when writing functions

=for Pod::Coverage ^(wrapres)$

=head1 SYNOPSIS

 use Perinci::Sub::Util qw(err caller);

 sub foo {
     my %args = @_;
     my $res;

     my $caller = caller();

     $res = bar(...);
     return err($err, 500, "Can't foo") if $res->[0] != 200;

     [200, "OK"];
 }


=head1 FUNCTIONS

=head2 caller([ $n ])

Just like Perl's builtin caller(), except that this one will ignore wrapper code
in the call stack. You should use this if your code is potentially wrapped. See
L<Perinci::Sub::Wrapper> for more details.

=head2 err(...) => ARRAY

Experimental.

Generate an enveloped error response (see L<Rinci::function>). Can accept
arguments in an unordered fashion, by utilizing the fact that status codes are
always integers, messages are strings, result metadata are hashes, and previous
error responses are arrays. Error responses also seldom contain actual result.
Status code defaults to 500, status message will default to "FUNC failed". This
function will also fill the information in the C<logs> result metadata.

Examples:

 err();    # => [500, "FUNC failed", undef, {...}];
 err(404); # => [404, "FUNC failed", undef, {...}];
 err(404, "Not found"); # => [404, "Not found", ...]
 err("Not found", 404); # => [404, "Not found", ...]; # order doesn't matter
 err([404, "Prev error"]); # => [500, "FUNC failed", undef,
                           #     {logs=>[...], prev=>[404, "Prev error"]}]

Will put C<stack_trace> in logs only if C<Carp::Always> module is loaded.


=head1 FAQ

=head2 What if I want to put result ($res->[2]) into my result with err()?

You can do something like this:

 my $err = err(...) if ERROR_CONDITION;
 $err->[2] = SOME_RESULT;
 return $err;


=head1 SEE ALSO

L<Perinci::Util>

L<Perinci>

=cut
