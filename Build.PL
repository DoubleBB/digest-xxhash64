use strict;
use Module::Build;


my $build = Module::Build->new(
    module_name         => 'Digest::xxHash64',
    license             => 'perl',
    dist_author         => 'Bela Bodecs <bodecsb@vivanet.hu>',
    dist_description    => 'Perl interface implementation to xxHash 64 bit algorithm',

    create_readme       => 1,
    configure_requires  => {
                            'Module::Build' => '0.19', # xs
    },
    build_requires      => {
                            'ExtUtils::CBuilder' => 0,
                            'Test::More' => 0
    },
    requires            => {
                             'perl' => '5.8.9',
                             'XSLoader' => 0,
                             'Exporter' => 0,
                             'Math::Int64' => '0.54' # for 32bit perl without native int64 support
    },
    test_requires       => {
                             # nothing special
    },
    needs_compiler => 1,
    include_dirs   => ['.'],
    c_source       => [
                       'ext/xxHash_072', # https://github.com/Cyan4973/xxHash
                       'ext/math_int64_c_api_client_054'  # https://metacpan.org/pod/Math::Int64#C-API
                      ],
    xs_files       => {
                        './xxHash64.xs' => 'lib/Digest/xxHash64.xs'
    },
    meta_merge     => {
        resources => {
            bugtracker  => 'https://github.com/DoubleBB/digest-xxhash64/issues',
            repository  => 'https://github.com/DoubleBB/digest-xxhash64'
        }
    }
);

$build->create_build_script;
