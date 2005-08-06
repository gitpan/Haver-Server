# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Store;
use strict;
use warnings;
use Haver::Base -base;
use File::Spec;
use File::Basename ();
use YAML ();

our $VERSION = 0.01;

sub initialize {
	my $self = shift;
	$self->{storedir} ||= File::Spec->curdir;
}

sub storedir {
	my ($self, $dir) = @_;
	if (@_ == 1) {
		$self->{storedir};
	} elsif (@_ > 1) {
		if (-d $dir) {
			$self->{storedir} = $dir;
		} elsif (not -e _) {
			croak "Storage directory $dir does not exist!";
		} elsif (not -d _) {
			croak "Storage directory $dir is not a directory!";
		}
	}
}

sub insert {
	my ($self, $entity) = @_;
	my $data = $entity->dump($self);
	my $file = $self->filename($entity->namespace, $entity->name);
	
	$self->_save_file($file, ref($entity), $data);
}

sub fetch {
	my ($self, $ns, $name) = @_;
	my $file = $self->filename($ns, $name);
	my ($class, $data)  = @{ $self->_load_file($file) };
	return $class->load($data, $self);
}

sub delete {
	my ($self, $ns, $name) = @_;
	my $file = $self->filename($ns, $name);
	unlink($file) or croak "Can't delete $ns/$name!";
}

sub exists {
	my ($self, $ns, $name) = @_;
	my $file = $self->filename($ns, $name);
	-e $file;
}

sub filename {
	my ($self, $ns, $name) = @_;
	File::Spec->catfile($self->storedir, $ns, lc $name)
}

sub dirname {
	my ($self, $ns) = @_;
	File::Spec->catfile($self->storedir, $ns)
}

sub _save_file {
	my ($self, $file, $class, $data) = @_;
	
	my $dir = File::Basename::dirname($file);
	if (not -e $dir) {
		mkdir($dir) or croak "Can't mkdir($dir): $!";
	}
	
	YAML::DumpFile($file, [
			$class,
			$data,
		]
	);
}

sub _load_file {
	my ($self, $file) = @_;
	YAML::LoadFile($file);
}



1;
__END__
=head1 NAME

Haver::Server::Store - description

=head1 SYNOPSIS

  use Haver::Server::Store;
  # Small code example.

=head1 DESCRIPTION

FIXME

=head1 INHERITENCE

Haver::Server::Store extends L<Haver::Base>

=head1 METHODS

This class implements the following methods:

=head2 method1(Z<>)

...

=head1 BUGS

None known. Bug reports are welcome. Please use our bug tracker at
L<http://gna.org/bugs/?func=additem&group=haver>.

=head1 AUTHOR

Dylan William Hardison, E<lt>dhardison@cpan.orgE<gt>

=head1 SEE ALSO

L<http://www.haverdev.org/>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Dylan William Hardison. All Rights Reserved.

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

