# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use VMS::Process;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Check to see if our PID is on the list we get. It ought to be, since it
# *is* us, after all.
@pidlist = VMS::Process::process_list();
$foundit = "No";
foreach $testpid (@pidlist) {
  if ($$ == $testpid) {
    $foundit = "Yes";
  }
}
print $foundit eq "Yes" ? "ok 2\n" : "not ok 2\n";

@foo = VMS::Process::proc_info_names;
if (scalar(@foo) > 0) {
  print "ok 3\n";
} else {
  print "not ok 3\n";
}

$NodeName = VMS::Process::get_one_proc_info_item($$, "NODENAME");
$DCLNodeName = `\$write sys\$output f\$getjpi("", "NODENAME")`;
chomp $DCLNodeName;
if ($NodeName ne $DCLNodeName) {
  print "#DCL $DCLNodeName Us $NodeName\n";
  print "not ok 4\n";
} else {
  print "ok 4\n";
}

if (!defined($foo = VMS::Process::get_all_proc_info_items($$))) {
  print "not ";
};
print "ok 5\n";

$foo->{NODENAME} eq $DCLNodeName ? print "ok 6\n" : print "not ok 6\n";
