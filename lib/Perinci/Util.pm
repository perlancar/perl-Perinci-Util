package Perinci::Util;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use SHARYANTO::Package::Util qw(package_exists);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       declare_property
                       declare_function_feature
                       declare_function_dep
                       get_package_meta_accessor
                       get_step_spec
               );

# VERSION

sub declare_property {
    my %args   = @_;
    my $name   = $args{name}   or die "Please specify property's name";
    my $schema = $args{schema} or die "Please specify property's schema";
    my $type   = $args{type};

    my $bs; # base schema (Rinci::metadata)
    my $ts; # per-type schema (Rinci::metadata::TYPE)
    my $bpp;
    my $tpp;

    require Rinci::Schema;
    $bs = $Rinci::Schema::base;
    $bpp = $bs->[1]{"keys"}
        or die "BUG: Schema structure changed (1)";
    $bpp->{$name}
        and die "Property '$name' is already declared in base schema";
    if ($type) {
        if ($type eq 'function') {
            $ts = $Rinci::Schema::function;
        } elsif ($type eq 'variable') {
            $ts = $Rinci::Schema::variable;
        } elsif ($type eq 'package') {
            $ts = $Rinci::Schema::package;
        } else {
            die "Unknown/unsupported property type: $type";
        }
        $tpp = $ts->[1]{"[merge+]keys"}
            or die "BUG: Schema structure changed (1)";
        $tpp->{$name}
            and die "Property '$name' is already declared in $type schema";
    }
    ($bpp // $tpp)->{$name} = $schema;

    {
        require Perinci::Sub::Wrapper;
        no strict 'refs';
        if ($args{wrapper}) {
            *{"Perinci::Sub::Wrapper::handlemeta_$name"} =
                sub { $args{wrapper}{meta} };
            *{"Perinci::Sub::Wrapper::handle_$name"} =
                $args{wrapper}{handler};
        } else {
            *{"Perinci::Sub::Wrapper::handlemeta_$name"} =
                sub { {} };
        }
    }
}

sub declare_function_feature {
    my %args   = @_;
    my $name   = $args{name}   or die "Please specify feature's name";
    my $schema = $args{schema} or die "Please specify feature's schema";

    $name =~ /\A\w+\z/
        or die "Invalid syntax on feature's name, please use alphanums only";

    require Rinci::Schema;
    # XXX merge first or use Perinci::Object, less fragile
    my $ff = $Rinci::Schema::function->[1]{"[merge+]keys"}{features}
        or die "BUG: Schema structure changed (1)";
    $ff->[1]{keys}
        or die "BUG: Schema structure changed (2)";
    $ff->[1]{keys}{$name}
        and die "Feature '$name' is already declared";
    $ff->[1]{keys}{$name} = $args{schema};
}

sub declare_function_dep {
    my %args    = @_;
    my $name    = $args{name}   or die "Please specify dep's name";
    my $schema  = $args{schema} or die "Please specify dep's schema";
    my $check   = $args{check};

    $name =~ /\A\w+\z/
        or die "Invalid syntax on dep's name, please use alphanums only";

    require Rinci::Schema;
    # XXX merge first or use Perinci::Object, less fragile
    my $dd = $Rinci::Schema::function->[1]{"[merge+]keys"}{deps}
        or die "BUG: Schema structure changed (1)";
    $dd->[1]{keys}
        or die "BUG: Schema structure changed (2)";
    $dd->[1]{keys}{$name}
        and die "Dependency type '$name' is already declared";
    $dd->[1]{keys}{$name} = $args{schema};

    if ($check) {
        require Perinci::Sub::DepChecker;
        no strict 'refs';
        *{"Perinci::Sub::DepChecker::checkdep_$name"} = $check;
    }
}

sub get_package_meta_accessor {
    my %args = @_;

    my $pkg = $args{package};
    my $def = $args{default_class} // 'Perinci::MetaAccessor::Default';

    no strict 'refs';
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

sub get_step_spec {
    my ($name, $steps) = @_;
    $steps //= {};

    my $spec = $steps->{$name};
    if (defined($spec) && !ref($spec)) {
        $spec = $steps->{$spec};
    } # currently only allows 1 level of aliasing
    unless (defined $spec) {
        # attempt to load step specification from a module first
        my $m = "Perinci::Sub::Step::$name";
        eval {
            unless (package_exists($m)) {
                my $mp = $m;
                $mp =~ s!::!/!g;
                $mp .= ".pm";
                $log->tracef("Trying to load step spec from %s ...",$m);
                my $rres = require $mp;
                $log->tracef("Loaded %s", $m) if $rres;
            }
            no strict 'refs';
            $spec = *{"$m\::spec"}{CODE}->();
        };
        $log->trace("Can't load step spec from $m: $@") if $@;
    }
    $spec;
}

1;
# ABSTRACT: Utility routines

=head1 DESCRIPTION

This is a temporary module containing utility routines.

It should be split once it's rather big.


=head1 FUNCTIONS

=head2 declare_property

=head2 declare_function_dep

=head2 declare_function_feature

=head2 get_package_meta_accessor(%args)

Arguments: C<package>, C<default_class> (optional, defaults to
C<Perinci::MetaAccessor::Default>).

=head2 get_step_spec($name, \%steps) => HASHREF

Step is the unit of subroutine's work in defined by
L<Rinci::function::Transaction>.

C<%steps> is optional. Step C<$name> will first be searched in C<%steps>'s keys.
If found and value is a hashref, that stepspec is returned. If found but value
is a string, it is assumed to be the new step name (an alias) and the new step
name is searched. If not found in C<%steps> (or C<%steps> if not provided), then
an attempt is made to load module Perinci::Sub::Step::<$name>; the module should
contain C<spec()> which if called returns the stepspec.


=head1 SEE ALSO

L<Perinci>

=cut
