# Haver::Server::Object - OO Channel/User/etc base class.
# 
# Copyright (C) 2004 Dylan William Hardison
#
# This module is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This module is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this module; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
package Haver::Server::Object;
use strict;
use warnings;
use Carp;

use POE::Preprocessor;
use Haver::Base;
use base 'Haver::Base';
use YAML ();
use File::Basename ();

# Perms:
#  w = set
#  r = get
#  h = has
#  d = del
# 

# Flags:
#  p = persistent
#  a = ACL permision.
#  b = broadcast
#  l = listed in WHOIS.
our $VERSION = "0.01";
our $ID = 1;

our %Access = (
	config    => {
		OWNER => 'rwhd',
		ANY   => '',
	},
	broadcast => {
		OWNER => 'rwhd',
		ANY   => 'rh',
	},
	perms    => {
		OWNER => 'rh',
		ANY   => 'rh',
	},
	option    => {
		OWNER => 'rwhd',
		ANY   => 'rh',
	},
	tag       => {
		OWNER => '',
		ANY   => '',
	},
	normal    => {
		OWNER => 'rwhd',
		ANY   => 'hd',
	},
);
our %Flags = (
	broadcast => 'b',
	normal    => 'p',
	perms     => 'apb',
	tag       => 'p',
	option    => 'p',
	config    => 'p',
);
our %Types = (
	'.'  => 'config',
	'+'  => 'broadcast',
	'@'  => 'perms',
	'-'  => 'option',
	'_'  => 'tag'
);

### Class methods.
sub field_type {
	my ($this, $f) = @_;
	my ($char) = $f =~ /^([^a-zA-Z0-9])/;

	if (defined $char) {
		return $Types{$char};
	} else {
		return 'normal';
	}
}
sub initialize {
	my ($me) = @_;

	my $config = eval { instance Haver::Config } || {};
	$me->{_fields}   = {};
	$me->{_perms}    = {};
	$me->{_flags}    = {};
	$me->{directory} = $config->{StoreDir} || './store';
	$me->{id}      ||= $ID++;


	return $me;
}


sub save {
	my ($me) = @_;
	my %f = %{ $me->{_fields} };
	my @del = grep { ! $me->has_flag($_, 'p') } keys %f;
	my $file = $me->filename;
	delete @f{@del};

	my %save = (
		fields => \%f,
		perms  => $me->{_perms},
		flags  => $me->{_flags},
		ID     => $me->{id},
		NS     => $me->namespace,
		Class  => ref($me),
	);
	$me->on_save(\%save);
	
	my $path = (File::Basename::fileparse($file))[1];
	mkdir($path) or die "Can't mkdir($path): $!" unless -d $path;
	
	print "DEBUG: Saving $file\n";
	open my $fh, ">$file" or die "Can't open $file for writing: $!";
	print $fh YAML::Dump(\%save);
	close $fh;
}
sub load {
	my ($me) = @_;
	my $file = $me->filename;
	local $/ = undef;
	my $data;

	open my $fh, "<$file" or die "Can't open $file for reading: $!";
	$data = readline($fh);
	close $fh;
	$data = YAML::Load($data);
	
	$me->{_fields} = $data->{fields};
	$me->{_flags}  = $data->{flags};
	$me->{_perms}  = $data->{perms};
	
	
	print "DEBUG: Loading $file\n";
	$me->on_load($data);
}

sub on_save {
	my ($me, $save) = @_;
} 
sub on_load {
	my ($me, $data) = @_;
}

### Accessor methods.
sub id        {
	$_[0]{id}
}
sub namespace {
	'object'
}
sub directory {
	my ($me, $dir) = @_;
	if (@_ == 2) {
		$me->{directory} = $dir;
	} else {
		$me->{directory}
	}
}
sub filename {
	my ($me) = @_;
	return $me->directory . '/' . $me->namespace . '/' . $me->id;
}
sub send      {
	croak "Must define send method!" 
}

### Flag methods
sub get_flags {
	my ($me, $key) = @_;

	if (exists $me->{_flags}{$key}) {
		return $me->{_flags}{$key};
	} else {
		return $Flags{ $me->field_type($key) };
	}
}
sub set_flags {
	my ($me, $key, $value) = @_;
	$me->{_flags}{$key} = $value;
}
sub has_flag {
	my ($me, $key, $flag) = @_;
	my $s = $me->get_flags($key);

	return undef unless defined $s;
	return index($s, $flag) != -1;
}

### Permision methods. 
sub get_perms {
	my ($me, $key) = @_;

	if (exists $me->{_perms}{$key}) {
		return $me->{_perms}{$key};
	} else {
		return $Access{ $me->field_type($key) };
	}
}
sub set_perms {
	my ($me, $key, %set) = @_;

	unless (exists $me->{_perms}{$key}) {
		$me->{_perms}{$key} = $Access{ $me->field_type($key) };
	}
	
	foreach my $k (keys %set) {
		$me->{_perms}{$key}{$k} = $set{$k};
	}
}
sub del_perms {
	my ($me, $key, @keys) = @_;

	foreach my $k (@keys) {
		delete $me->{_perms}{$key}{$k};
	}
}

### Methods for accessing fields.
sub set {
	my ($me, @set) = @_;
	
	while (my ($k,$v) = splice(@set, 0, 2)) {
		$me->{_fields}{$k} = $v;
	}
}
sub get {
	my ($me, @keys) = @_;

	if (@keys <= 1) {
		return $me->{_fields}{$keys[0]};
	}
	my @values;
	
	foreach my $key (@keys) {
		push(@values, $me->{_fields}{$key});
	}

	return wantarray ? @values : \@values ;
}
sub has {
	my ($me, @keys) = @_;

	if (@keys <= 1) {
		return exists $me->{_fields}{$keys[0]};
	}
	
	foreach my $key (@keys) {
		unless (exists $me->{_fields}{$key}) {
			return undef;
		}
	}

	return 1;
}
sub del {
	my ($me, @keys) = @_;
	
	if (@keys <= 1) {
		return delete $me->{_fields}{$keys[0]};
	}
	my @values;
	
	foreach my $key (@keys) {
		push(@values, delete $me->{_fields}{$key});
	}
	
	
	return wantarray ? @values : \@values ;
}
sub list_keys {
	my ($me) = @_;
	return keys %{ $me->{_fields} };
}


1;
=head1 NAME

Haver::Server::Object - Base class for Users and Channels.

=head1 SYNOPSIS

  use Haver::Server::Object;
  # FIXME.

=head1 DESCRIPTION

FIXME


=head1 METHODS
	
FIXME

=head1 SEE ALSO

L<Haver::Server::User>, L<Haver::Server::Channel>.

=head1 AUTHOR

Dylan William Hardison, E<lt>dylanwh@tampabay.rr.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2004 by Dylan William Hardison

This module is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this module; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
