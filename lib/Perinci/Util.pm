package Perinci::Util;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use SHARYANTO::Package::Util qw(package_exists);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       get_package_meta_accessor
               );

# VERSION

sub get_package_meta_accessor {
    my %args = @_;

    my $pkg = $args{package};
    my $def = $args{default_class} // 'Perinci::MetaAccessor::Default';

    no strict 'refs';
    no warnings; # next line, the var only used once, thus warning
    my $ma   = ${ "$pkg\::PERINCI_META_ACCESSOR" } // $def;
    my $ma_p = $ma;
    $ma_p  =~ s!::!/!g;
    $ma_p .= ".pm";
    eval { require $ma_p };
    my $req_err = $@;
    if ($req_err) {
        if (!package_exists($ma)) {
            return [500, "Can't load meta accessor module $ma (probably ".
                        "mistyped or missing module): $req_err"];
        } elsif ($req_err !~ m!Can't locate!) {
            return [500, "Can't load meta accessor module $ma (probably ".
                        "compile error): $req_err"];
        }
        # require error of "Can't locate ..." can be ignored. it
        # might mean package is already defined by other code. we'll
        # try and access it anyway.
    } elsif (!package_exists($ma)) {
        # shouldn't happen
        return [500, "Meta accessor module loaded OK, but no $ma package ".
                    "found, something's wrong"];
    }
    [200, "OK", $ma];
}

1;
# ABSTRACT: Perinci utility routines

=head1 DESCRIPTION

This is a temporary module containing utility routines.

It should be split once it's rather big.


=head1 FUNCTIONS

=head2 get_package_meta_accessor(%args)

Arguments: C<package>, C<default_class> (optional, defaults to
C<Perinci::MetaAccessor::Default>).


=head1 SEE ALSO

L<Perinci>

=cut
