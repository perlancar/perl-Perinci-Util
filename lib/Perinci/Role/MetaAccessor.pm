package Perinci::Role::MetaAccessor;

use 5.010;
use Moo::Role;

# VERSION

requires 'get_meta';
requires 'get_all_metas';
requires 'set_meta';

1;
# ABSTRACT: Role for metadata accessor class
