package Perinci::MetaAccessor::Default;

use 5.010;
use Moo;
with 'Perinci::Role::MetaAccessor';

# VERSION

sub new {
    my ($class, %args) = @_;
    $args{var} //= 'SPEC';
}

sub get_meta {
    my ($self, $package, $leaf) = @_;
    my $key = $leaf || ':package';
    no strict 'refs';
    no warnings;
    ${ "$package\::$self->{var}" }{$key};
}

sub get_all_metas {
    my ($self, $package) = @_;
    no strict 'refs';
    \%{ "$package\::$self->{var}" };
}

sub set_meta {
    my ($self, $package, $leaf, $meta) = @_;
    no strict 'refs';
    my $key = $leaf || ':package';
    ${ "$package\::$self->{var}" }{$key} = $meta;
}

1;
# ABSTRACT: Default class to access metadata in local package

=head1 DESCRIPTION

This class looks for L<Rinci> metadata in package variable C<%SPEC>. The keys
are function names, or variables with the sigil prefix, or C<:package> for the
package metadata itself.

 our %SPEC;
 $SPEC{':package'} = {
     # Rinci metadata for the package
     v => 1.1,
     ...
 };

 $SPEC{'func1'} = {
     # Rinci metadata for function func1()
     v => 1.1,
     ...
 };
 sub func1 { ... }

 $SPEC{'$Var1'} = {
     v => 1.1,
     ...
 }
 our $Var1 = "default val";

 ...
 1;

You can change the name of variable from C<%SPEC> to something else, by setting
the C<var> attribute:

 my $ma = Perinci::MetaAccessor::Default->new(var => 'META');


=head1 ATTRIBUTES

=head2 var => str (default: "SPEC")

Can be used to change the name of the package variable which contains the
metadata.


=head1 METHODS

=head2 new(%attrs) => OBJ

Constructor.

=head2 $ma->get_meta($package, $leaf) => HASH

=head2 $ma->get_all_metas($package) => HASH OF HASH

=head2 $ma->set_meta($package, $leaf, $metadata)

=cut
