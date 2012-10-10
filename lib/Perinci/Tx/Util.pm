package Perinci::Tx::Util;

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Util qw(wrapres);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       use_other_actions
               );

# VERSION

sub use_other_actions {
    my %args = @_;
    my $actions = $args{actions};

    no strict 'refs';

    my ($has_unfixable, $has_fixable, $has_error);
    my (@do, @undo);
    my ($res, $a);
    my $i = 0;
    for (@$actions) {
        $a = $_;
        my $f = $a->[0];
        $res = $f->(%{$a->[1]}, -tx_action=>'check_state', -tx_v=>2);
        # XXX some function needs -tx_action_id
        if ($res->[0] == 200) {
            $has_fixable++;
            push @do, $a;
            unshift @undo, @{ $res->[3]{undo_actions} };
        } elsif ($res->[0] == 304) {
            # fixed
        } elsif ($res->[0] == 412) {
            $has_unfixable++;
            last;
        } else {
            $has_error++;
            last;
        }
        $i++;
    }

    if ($has_error) {
        wrapres([500, "There is an error: action #$i: "], $res);
    } elsif ($has_unfixable) {
        wrapres([412, "There is an unfixable state: action #$i: "], $res);
    } elsif ($has_fixable) {
        [200, "Some action needs to be done", undef, {
            do_actions => \@do,
            undo_actions => \@undo,
        }];
    } else {
        [304, "No action needed"];
    }
}

1;
# ABSTRACT: Helper when writing transactional functions

=head1 SYNOPSIS

 use Perinci::Tx::Util qw(use_other_actions);

 sub foo {
     my %args = @_;
     use_other_actions(actions => [
         ["My::action1", {arg=>1}],
         ["My::action2", {arg=>2}],
         # ...
     ]);
 }


=head1 FUNCTIONS

=head2 use_other_actions(actions=>$actions) => RES

Generate envelope response for transactional function. Can be used to say that
function entirely depends on other actions.

Each action in C<$actions> will be called with C<< -tx_action => 'check_state'
>>. If all actions return 304, response status will be 304. If some or all
actions return 200 and the rest 304, response status will be 200 with
C<undo_actions> result metadata taken from the actions' metadata and
C<do_actions> from C<$actions>. If any action returns 412, response will be 412.
If any action return other status, response will be 500 (error).

It is your responsibility to load required modules.

Does not perform checking on actions like L<Perinci::Tx::Manager>, but
eventually actions will be checked by Perinci::Tx::Manager anyway.


=head1 SEE ALSO

L<Perinci::Util>

L<Perinci>

=cut
