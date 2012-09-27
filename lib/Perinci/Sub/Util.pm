package Perinci::Sub::Util;

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       wrapres
               );

# VERSION

sub wrapres {
    my ($ores, $ires) = @_;

    $ores //= [];
    $ores->[0] //= $ires->[0];
    if ($ores->[1] && $ores->[1] =~ /: \z/) {
        $ores->[1] .= $ires->[1];
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
        my @c = caller(0);
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

=head1 SYNOPSIS

 use Perinci::Sub::Util qw(wrapres);

 sub foo {
     my %args = @_;
     my $res;

     $res = bar(); # call another function
     return wrapres([500, "Can't bar: "], $res) unless $res->[0] == 200;
     $res = baz();
     return wrapres([500, "Can't baz: "], $res) unless $res->[0] == 200;

     [200, "OK"];
 }


=head1 FUNCTIONS

=head2 wrapres([$status, $msg, $result, $meta], $res) => ARRAY

Generate an envelope response based on an existing $res, with an option to build
an error stack. Usually used to create an error response which preserves inner
error.

If C<$status> is undefined, will use C<$res>'s status.

If C<$message> is undefined, will use C<$res>'s message. If C<$message> ends
with C</:\s?\z/>, will append C<$res>'s message.

If C<$result> is undefined, will use C<$res>'s result.

If C<$meta> is undefined, empty default is used. If instructed to build an error
stack, will append C<$res> to result metadata's C<error_stack>.

Error stack by default is off. Can be turned on via setting global variable
C<$Perinci::ERROR_STACK> to true value, or environment variable
L<PERINCI_ERROR_STACK>, or package variables $PACKAGE::PERINCI_ERROR_STACK (to
turn on on a package basis).

Some examples (C<$res> is assumed to be C<< [404, "not found"] >>:

 wrapres(undef, $res);
 # when error stack is off: [404, "not found"]
 # when error stack is on : [404, "not found", undef,
 #                          {error_stack=>[404, "not found"]}]

 wrapres([undef, "can't select user: "], $res);
 # when error stack is off: [404, "can't select user: not found"]
 # when error stack is on : [405, "can't select user: not found", undef,
                             {error_stack=>[404, "not found"]}]

 wrapres([500, "can't select user", -1, {foo=>1}], $res);
 # when error stack is off: [500, "can't select user"]
 # when error stack is on : [500, "can't select user", -1,
                             {foo=>1, error_stack=>[404, "not found"]}]


=head1 SEE ALSO

L<Perinci::Util>

L<Perinci>

=cut
