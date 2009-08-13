package MooseX::AnonClassName::UUID::Meta::Class::Trait::AnonClassName::UUID;

#ABSTRACT: Implementation role for overriding anonymous class name creation

use Moose::Role;
use Data::UUID;
use Devel::GlobalDestruction 'in_global_destruction';
use namespace::autoclean;

my %ANON_CLASSES;
my $ANON_CLASS_PREFIX = 'Moose::Meta::Class::__ANON__::UUID::';
my $MY_UUID = Data::UUID->new();

=method around is_anon_class

is_anon_class is subverted to use the new lexical prefix to determine if the
class is actually anonymous

=cut

around is_anon_class => sub 
{
    my $orig = shift;
    my $self = shift;
    no warnings 'uninitialized';
    return 1 if $self->name =~ /^$ANON_CLASS_PREFIX/o;
    return $self->$orig(@_);
};


=method around create_anon_class

create_anon_class is overriden to call a custom method that does the actual
create. Since Class::MOP::Class also has a create_anon_class and the original
Moose::Meta::Class used ->SUPER, CMOP's method couldn't be overriden.

=cut

around create_anon_class => sub
{
    shift;
    my ($self, %options) = @_;

    my $cache_ok = delete $options{cache};

    # something like Super::Class|Super::Class::2=Role|Role::1
    my $cache_key = join '=' => (
        join('|', @{$options{superclasses} || []}),
        join('|', sort @{$options{roles}   || []}),
    );

    if ($cache_ok && defined $ANON_CLASSES{$cache_key}) {
        return $ANON_CLASSES{$cache_key};
    }
    my $new_class = $self->my_create_anon_class(%options);

    $ANON_CLASSES{$cache_key} = $new_class
        if $cache_ok;

    return $new_class;
};

=method my_create_anon_class

my_create_anon_class provides the actual implementation for providing the 
package name. 

=cut

sub my_create_anon_class
{
    my ($class, %options) = @_;
    my $package_name = $ANON_CLASS_PREFIX . $MY_UUID->create_hex();
    return $class->create($package_name, %options);
};

=method around DESTROY

DESTROY is advised so that we clean up UUID based anonymous classes

=cut

around DESTROY => sub
{
    my $orig = shift;
    my $self = shift;

    return if in_global_destruction(); # it'll happen soon anyway and this just makes things more complicated

    no warnings 'uninitialized';
    my $name = $self->name;
    
    if($name =~ /^$ANON_CLASS_PREFIX/o)
    {
        my $current_meta = Class::MOP::get_metaclass_by_name($name);
        return if $current_meta ne $self;

        my ($uuid) = ($name =~ /^$ANON_CLASS_PREFIX(.+)/o);
        no strict 'refs';
        @{$name . '::ISA'} = ();
        %{$name . '::'}    = ();
        delete ${$ANON_CLASS_PREFIX}{$uuid . '::'};

        Class::MOP::remove_metaclass_by_name($name);
    }
    else
    {
        return $self->$orig(@_);
    }
};

package Moose::Meta::Class::Custom::Trait::AnonClassName::UUID;

sub register_implementation { 'MooseX::AnonClassName::UUID::Meta::Class::Trait::AnonClassName::UUID' }

1;
__END__

