package Perinci::MetaAccessor::Default;

use 5.010;
use Moo;
with 'Perinci::Role::MetaAccessor';

# VERSION

# static method
sub get_meta {
    my ($class, $package, $leaf) = @_;
    my $key = $leaf || ':package';
    no strict 'refs';
    no warnings;
    ${ $package . "::SPEC" }{$key};
}

sub get_all_metas {
    my ($class, $package) = @_;
    no strict 'refs';
    \%{ $package . "::SPEC" };
}

sub set_meta {
    my ($class, $package, $leaf, $meta) = @_;
    no strict 'refs';
    my $key = $leaf || ':package';
    ${ $package . "::SPEC" }{$key} = $meta;
}

1;
# ABSTRACT: Default class to access metadata in local package
