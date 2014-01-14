requires 'perl', '5.008001';
requires 'Time::Local';
requires 'Carp';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

