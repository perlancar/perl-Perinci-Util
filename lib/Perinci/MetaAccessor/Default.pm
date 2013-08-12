sub get_meta {
    my ($soc, $package, $leaf) = @_; # soc = self_or_class
    my $key = $leaf || ':package';
    no strict 'refs';
    no warnings;
    ${ "$package\::" . (ref($soc) ? $soc->{var} : $Default_Var) }{$key};
}

sub get_all_metas {
    my ($soc, $package) = @_;
    no strict 'refs';
    \%{ "$package\::" . (ref($soc) ? $soc->{var} : $Default_Var) };
}

sub set_meta {
    my ($soc, $package, $leaf, $meta) = @_;
    no strict 'refs';
    my $key = $leaf || ':package';
    ${ "$package\::" . (ref($soc) ? $soc->{var}:"SPEC") }{$key} = $meta;
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

Can also be accessed as a static method.

=head2 $ma->get_all_metas($package) => HASH OF HASH

Can also be accessed as a static method.

=head2 $ma->set_meta($package, $leaf, $metadata)

Can also be accessed as a static method.

=cut
