use VMS::Process qw(process_list);
use VMS::ProcInfo qw(get_all_proc_info_items);

@foo = process_list( ({NAME => "STATE", VALUE => "CUR"}));
foreach $pid (sort @foo) {
  $procinfo = get_all_proc_info_items($pid);
  print sprintf("%8.8x", $pid), " ";
  print sprintf("%-15.15s ", $procinfo->{PRCNAM});
  print $procinfo->{"STATE"}, "\t";
  print $procinfo->{PRI}, "\t";
  print ($procinfo->{DIRIO} + $procinfo->{BUFIO}), "\t\t";
  $cputime = $procinfo->{CPUTIM};
  $days = int($cputime / 8640000);
  $remainder = $cputime % 8640000;
  $hours = int($remainder / 360000);
  $remainder = $remainder % 360000;
  $minutes = int($remainder / 6000);
  $remainder = $remainder % 6000;
  $seconds = int($remainder / 100);
  $hundredths = $remainder % 100;
  $timestr = sprintf("%0.1u %0.2u:%0.2u:%0.2u.%0.2u", $days, $hours,
                     $minutes, $seconds, $hundredths);
  print "\t", $timestr, " ", sprintf("%9.9s ", $procinfo->{PAGEFLTS});
  if ($procinfo->{MODE} eq 'NETWORK') {
    print "N";
  } elsif ($procinfo->{MODE} eq 'BATCH') {
    print "B";
  } elsif (($procinfo->{MASTER_PID} != $$) and ($procinfo->{MODE} eq 'DETACHED')) {
    print "S";
  } 
  print " ", $procinfo->{MASTER_PID};
  print "\n";
}
