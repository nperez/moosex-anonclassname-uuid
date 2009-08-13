use warnings;
use strict;

use Test::More;

{
    package My::Class::Creator;
    use MooseX::AnonClassName::UUID;
    use Moose -traits => qw/ AnonClassName::UUID  /;

    sub make_class
    {
        return shift->meta->create_anon_class();
    }
}

{
    package My::Non::Creator;
    use Moose;
    
    sub make_class
    {
        return shift->meta->create_anon_class();
    }
}

my $anon1 = My::Class::Creator->make_class();
my $anon2 = My::Non::Creator->make_class();

diag(sprintf('Anonymous class name with override: %s', $anon1->name));
ok($anon1->name !~ /SERIAL/, 'Does not have SERIAL in the name');

diag(sprintf('Anonymous class name without override: %s', $anon2->name));
ok($anon2->name =~ /SERIAL/, 'Does not have SERIAL in the name');

done_testing();

0;
