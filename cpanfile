requires 'Alien::Base'  => '2.38';
requires 'Alien::Build' => '2.38';

requires 'Path::Tiny'   => '0';

on 'test' => sub {
  requires 'Test2::V0' => '0';
};

on 'develop' => sub {
  requires 'Dist::Zilla'             => '0';
};