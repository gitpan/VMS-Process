package VMS::Process;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&process_list &suspend_process &release_process
                &kill_process &change_priority);
$VERSION = '0.01';

bootstrap VMS::Process $VERSION;

# Preloaded methods go here.
#sub new {
#  my($pkg,$pid) = @_;
#  my $self = { __PID => $pid || $$ };
#  bless $self, $pkg; 
#}
#
#sub one_info { get_one_proc_info_item($_[0]->{__PID}, $_[1]); }
#sub all_info { get_all_proc_info_items($_[0]->{__PID}) }
#
#sub TIEHASH { my $obj = new VMS::Process @_; $obj; }
#sub FETCH   { $_[0]->one_info($_[1]); }
#sub EXISTS  { grep(/$_[1]/, proc_info_names()) }
#
# Can't STORE, DELETE, or CLEAR--this is readonly. We'll Do The Right Thing
# later, when I know what it is...
#sub STORE   {
#  my($self,$priv,$val) = @_;
#  if (defined $val and $val) { $self->add([ $priv ],$self->{__PRMFLG});    }
#  else                       { $self->remove([ $priv ],$self->{__PRMFLG}); }
#}
#sub DELETE  { $_[0]->remove([ $_[1] ],$_[0]->{__PRMFLG}); }
#sub CLEAR   { $_[0]->remove([ keys %{$_[0]->current_privs} ],$_[0]->{__PRMFLG}) }

#sub FIRSTKEY {
#  $_[0]->{__PROC_INFO_ITERLIST} = [ proc_info_names() ];
#  $_[0]->one_info(shift @{$_[0]->{__PROC_INFO_ITERLIST}});
#}
#sub NEXTKEY { $_[0]->one_info(shift @{$_[0]->{__PROC_INFO_ITERLIST}}); }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

VMS::Process - Perl extension to manage processes

=head1 SYNOPSIS

  use VMS::Process;

  @pid_list = process_list([\%process_characteristics]);
  $WorkedOK = suspend_process($pid);
  $WorkedOK = release_process($pid);
  $WorkedOK = kill_process($pid);
  $WorkedOK = change_priority($pid, $priority);

=head1 DESCRIPTION

VMS::Process allows a perl program to get a list of some or all the
processes on one or more nodes in the cluster, change process priority,
suspend, release, or kill them. Normal VMS system security is in effect, so
a program can't see or modify processes that the process doesn't have the
privs to see. Once process pids are available, information about those
processes can be retrieved with the VMS::ProcInfo module.

The process_list function takes an optional reference to a hash with the
characteristics of the processes whose pids will be returned. Each hash
element can be either a scalar or a list. 

=head1 BUGS

May leak memory. May not, though.

While process_list is supposed to take a hash ref, right now it
doesn't. You get all the pids for the processes on the cluster that you
would normally have privs to see.

=head1 LIMITATIONS

The processing of the process characteristics hash is pretty simplistic. 

The tests are really primitive. (Like there aren't any right now)

VMS system security is in force, so process_list() is likely to show fewer
PIDs than SHOW SYSTEM will. Nothing we can do about that, short if INSALLing Perl with lots of privs, which is a really, really bad idea, so don't.

=head1 AUTHOR

Dan Sugalski <sugalsd@lbcc.cc.or.us>

=head1 SEE ALSO

perl(1), VMS::ProcInfo.

=cut
