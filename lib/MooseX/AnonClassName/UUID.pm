package MooseX::AnonClassName::UUID;

# ABSTRACT: Change anonymous class names to use UUIDs

use aliased 'MooseX::AnonClassName::UUID::Meta::Class::Trait::AnonClassName::UUID', 'AnonClassNameUUID';
use namespace::autoclean;

=head1 SYNOPSIS

    package My::Package;
    use MooseX::AnonClassName::UUID;
    use Moose -traits => qw/ AnonClassName::UUID  /;

    sub get_new_anon_class
    {
        return shift->meta->create_anon_class();
    }

    1;

=cut

=method init_meta

This is our entry point into modifying Moose.

It uses Moose::Util::MetaRole::apply_metaclass_roles to apply the
implementation Role to Moose::Meta::Class instance in your package.

=cut

sub init_meta 
{
    my ($class, %options) = @_;
    return Moose::Util::MetaRole::apply_metaclass_roles
    (
        for_class       => $options{for_class},
        metaclass_roles => [AnonClassNameUUID],
    );
}

1;

__END__

=head1 DESCRIPTION

MooseX::AnonClass::UUID alters the way Moose/Class::MOP generate anonymous 
class names so that they are no longer SERIAL. Instead, Data::UUID is used, 
plus a new prefix to come up with truly unique names. 

=head1 WHY?

Consider you want to serialize anonymous class instances in one process and 
reconstitute them in another process. Both processes create anonymous classes
in their normal runtime. Without this module, if I serialize SERIAL::2 and send
it over to the other process and it attempts to reconstitute it, there is a
very high probability that it has already created its own SERIAL::2 and 
therefore things go wrong.

This avoids that problem by using UUIDs in the class names, guaranteeing that
all of your anonymous class names will be unique.

