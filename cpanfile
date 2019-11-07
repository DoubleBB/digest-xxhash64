requires 'perl', '5.8.9';

on 'build' => sub {
	requires 'ExtUtils::CBuilder';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {

};

requires 'Math::Int64', '0.54';
requires 'XSLoader';
requires 'Module::Build' => '0.19';
requires 'Exporter';
