package Perinci::Access::InProcess::MetaAccessor;

use 5.010;
use Moo;
with 'Perinci::Role::MetaAccessor';

# VERSION

# static method
sub get_meta {
    my ($class, $req) = @_;
    my $leaf = $req->{-leaf};
    my $key  = $req->{-leaf} || ':package';
    no strict 'refs';
    ${ $req->{-module} . "::SPEC" }{$key};
}

sub get_all_meta {
    my ($class, $req) = @_;
    no strict 'refs';
    \%{ $req->{-module} . "::SPEC" };
}

sub set_meta {
    my ($class, $req, $meta) = @_;
    no strict 'refs';
    my $key = $req->{-leaf} || ':package';
    ${ $req->{-module} . "::SPEC" }{$key} = $meta;
}

1;
# ABSTRACT: Default class to access metadata in package
