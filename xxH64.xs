/*
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 *  Copyright 2019 Bela Bodecs
 *
 *
 * This module is an interface for xxHash library
 *   Copyright (c) 2012-present, Yann Collet
 *   All rights reserved.
 *   https://github.com/Cyan4973/xxHash
 *
 */
#define PERL_NO_GET_CONTEXT   /* no need for thread context, get faster */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#define PERLIO_NOT_STDIO 0    /* For co-existence with stdio only */
#include <perlio.h>           /* Usually via #include <perl.h> */

#define READ_BUFFER_SIZE 65536

#define  bbMIN2(a, b)   ((a) < (b) ? (a) : (b))


/* According to https://metacpan.org/pod/Math::Int64
   perl_math_int64.h requires the types int64_t and uint64_t to be defined beforehand
   earlier incluson of stdint.h may define them  */
#if !defined (__VMS) \
  && (defined (__cplusplus) \
  || (defined (__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L) /* C99 */) )
#   include <stdint.h>
    /* now uint64_t and int64_t are defined (mostly) */
#else
    /* the following type must have a width of 64-bit if they are not defined earlier */
#   if !defined (UINT64_MAX)
      typedef unsigned long long uint64_t;
#   endif
#   if !defined (INT64_MAX)
      typedef long long int64_t;
#   endif
#endif




/* to use native IVs if they are 64bits long */
#define MATH_INT64_NATIVE_IF_AVAILABLE

/* use 64 bit integers even by 32 bit Perl */
#include "perl_math_int64.h"

#include "xxhash.h"


/* for OO interface */
typedef XXH64_state_t * Digest__xxH64;

MODULE = Digest::xxH64  PACKAGE = Digest::xxH64

BOOT:
    PERL_MATH_INT64_LOAD_OR_CROAK;

PROTOTYPES: ENABLE

 #
 # Object oriented style interface
 #
Digest::xxH64
new (char * class, ...)
    PREINIT:
        uint64_t seed64_value = 0;
    CODE:
        if (items > 2) {
          croak("Too many arguments");
        }
        RETVAL = XXH64_createState( );
        if (! RETVAL) {
          croak("No memory for %s", class);
        }

        if (SvOK(ST(1)) && SvIOK(ST(1)))
          seed64_value = SvU64(ST(1));

        if (XXH64_reset(RETVAL, seed64_value) == XXH_ERROR) {
          croak("Could not set seed");
        }

    OUTPUT:
        RETVAL



Digest::xxH64
clone (Digest::xxH64 xx)
    CODE:
        RETVAL = XXH64_createState( );
        if (! RETVAL) {
          croak("Insufficient memory");
        }

        XXH64_copyState(RETVAL, xx);
    OUTPUT:
        RETVAL



void
DESTROY (xx)
        Digest::xxH64 xx;
    CODE:
        XXH64_freeState(xx);



uint64_t
reset ( Digest::xxH64 xx, ... )
    PREINIT:
        uint64_t seed64_value = 0;
    CODE:
        if (items > 2) {
          croak("Too many arguments");
        }
        if (SvOK(ST(1)) && SvIOK(ST(1)))
          seed64_value = SvU64(ST(1));
        if (XXH64_reset(xx, seed64_value) == XXH_ERROR) {
          croak("Could not set seed");
        }
        RETVAL = seed64_value;
    OUTPUT:
        RETVAL



uint64_t
add ( Digest::xxH64 xx, ... )
    PREINIT:
        STRLEN len = 0;
        const char *ptr;
        unsigned int i;
        U32 had_utf8;
    CODE:
        if (items > 1) {
          for (i = 1; i < items; i++) {
            if (!SvOK(ST(i))) {
              croak("One of the arguments (#%u) is not defined", i);
            }
            had_utf8 = SvUTF8(ST(i));
            ptr = SvPVbyte(ST(i), len);
            if (len == 0) {
              croak("One of the arguments (#%u) is zero length", i);
            }
            if (XXH64_update(xx, ptr, len) == XXH_ERROR) {
              croak("Could not update xxHash state with argument #%u", i);
            }
            if (had_utf8)
               sv_utf8_upgrade(ST(i));
          }
        }
        else {
          croak("requires at least one argument");
        }
        RETVAL = len;
    OUTPUT:
        RETVAL



uint64_t
digest (Digest::xxH64 xx)
    CODE:
        RETVAL = XXH64_digest(xx);
    OUTPUT:
        RETVAL



void
hexdigest (Digest::xxH64 xx)
  PREINIT:
    char str_hash[17]; /* 16 hexa characters + terminating zero */
    const char digits[16] = "0123456789ABCDEF";
    int i;
    XXH64_hash_t hash64;
  PPCODE:
    hash64 = XXH64_digest(xx);
    /* sprintf for 64 bit numbers is not available on all platform */
    for(i=0; i<16; i++)
      str_hash[15 - i] = digits[(hash64 >> (i*4)) & 15];

    str_hash[16] = 0;
    XPUSHs(sv_2mortal(newSVpv(str_hash, 0)));


void
bindigest (Digest::xxH64 xx)
  PREINIT:
    char str_hash[9]; /* 8 bytes + terminating zero */
    int i;
    XXH64_hash_t hash64;
  PPCODE:
    hash64 = XXH64_digest(xx);

    for(i=0; i<8; i++)
      str_hash[7 - i] = (hash64 >> (i*8)) & 255;

    str_hash[8] = 0;
    XPUSHs(sv_2mortal(newSVpv(str_hash, 0)));


uint64_t
addfile(Digest::xxH64 xx, PerlIO * fh, ...)
    PREINIT:
        uint64_t total_read = 0;
        uint64_t max_read = 0;
        uint64_t still_read = 0;
#ifdef USE_HEAP_INSTEAD_OF_STACK
        unsigned char* buffer;
#else
        unsigned char buffer[READ_BUFFER_SIZE];
#endif
        int  n;
    CODE:
        if (items > 3) {
          croak("Too many arguments");
        }
        /* 3rd optional parameter */
        if (SvOK(ST(2)) && SvIOK(ST(2)))
          max_read = SvU64(ST(2));

        if (fh) {
#ifdef USE_HEAP_INSTEAD_OF_STACK
          NewX(buffer, READ_BUFFER_SIZE, unsigned char);
          if (!buffer) {
            croak("Memory allocation error");
          }
#endif

          /* read/process blocks until EOF or any error */
          still_read = max_read;
          while ( (!max_read || still_read) &&
                  (n = PerlIO_read(fh, buffer, max_read ? bbMIN2(still_read,sizeof(buffer)) : sizeof(buffer))) > 0 ) {
            if (XXH64_update(xx, buffer, n) == XXH_ERROR) {
              croak("Could not update xxHash state with with read data");
            }
            total_read += n;
            if (max_read)
              still_read -= bbMIN2(still_read, n); /* just for any case*/
          }
#ifdef USE_HEAP_INSTEAD_OF_STACK
          Safefree(buffer);
#endif
          if (PerlIO_error(fh)) {
            croak("Reading from filehandle failed");
          }

        }
        else {
          croak("No filehandle passed");
        }
        RETVAL = total_read;
    OUTPUT:
        RETVAL



uint64_t
get_xxHash64 ( ... )
    ALIAS:
        xx64 = 1
        xxH64 = 2
        xxHash64 = 3

    PREINIT:
        STRLEN len = 0;
        const char *ptr;
        uint64_t seed64_value = 0;
        U32 had_utf8;

    CODE:
        if (items > 2) {
          croak("Too many arguments");
        }
        if (items == 0) {
          croak("Too few arguments");
        }

        if (!SvOK(ST(0))) {
          croak("Requires a valid argument");
        }

        if (SvOK(ST(1)) && SvIOK(ST(1)))
          seed64_value = SvU64(ST(1));

        had_utf8 = SvUTF8(ST(0));
        ptr = SvPVbyte(ST(0), len);
        if (len == 0) {
          croak("Data argument is zero length");
        }

        RETVAL = XXH64(ptr, len, seed64_value);
        if (had_utf8)
           sv_utf8_upgrade(ST(0));
    OUTPUT:
        RETVAL


void
get_xxHash64hex ( ... )
    ALIAS:
        xx64hex = 1
        xxH64hex = 2
        xxHash64hex = 3

    PREINIT:
        char str_hash[17]; /* 16 hexa characters + terminating zero */
        const char digits[16] = "0123456789ABCDEF";
        int i;
        STRLEN len = 0;
        const char *ptr;
        uint64_t seed64_value = 0;
        XXH64_hash_t hash64;
        U32 had_utf8;

    PPCODE:
        if (items > 2) {
          croak("Too many arguments");
        }
        if (items == 0) {
          croak("Too few arguments");
        }

        if (!SvOK(ST(0))) {
          croak("requires at least one valid argument");
        }

        if (SvOK(ST(1)) && SvIOK(ST(1)))
          seed64_value = SvU64(ST(1));


        had_utf8 = SvUTF8(ST(0));
        ptr = SvPVbyte(ST(0), len);
        if (len == 0) {
          croak("Data argument is zero length");
        }

        hash64 = XXH64(ptr, len, seed64_value);
        if (had_utf8)
           sv_utf8_upgrade(ST(0));

        /* sprintf for 64 bit numbers is not available on all platform */
        for(i=0; i<16; i++)
          str_hash[15 - i] = digits[(hash64 >> (i*4)) & 15];

        str_hash[16] = 0;
        XPUSHs(sv_2mortal(newSVpv(str_hash, 0)));



void
get_xxHash64bin ( ... )
    ALIAS:
        xx64bin = 1
        xxH64bin = 2
        xxHash64bin = 3

    PREINIT:
        char str_hash[9]; /* 8 bytes + terminating zero */
        int i;
        STRLEN len = 0;
        const char *ptr;
        uint64_t seed64_value = 0;
        XXH64_hash_t hash64;
        U32 had_utf8;

    PPCODE:
        if (items > 2) {
          croak("Too many arguments");
        }
        if (items == 0) {
          croak("Too few arguments");
        }

        if (!SvOK(ST(0))) {
          croak("requires at least one valid argument");
        }

        if (SvOK(ST(1)) && SvIOK(ST(1)))
          seed64_value = SvU64(ST(1));


        had_utf8 = SvUTF8(ST(0));
        ptr = SvPVbyte(ST(0), len);

        if (len == 0) {
          croak("Data argument is zero length");
        }

        hash64 = XXH64(ptr, len, seed64_value);
        if (had_utf8)
           sv_utf8_upgrade(ST(0));

        for(i=0; i<8; i++)
          str_hash[7 - i] = (hash64 >> (i*8)) & 255;

        str_hash[8] = 0;
        XPUSHs(sv_2mortal(newSVpv(str_hash, 0)));
