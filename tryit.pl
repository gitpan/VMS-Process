use VMS::Process qw(process_list);
use VMS::ProcInfo qw(get_all_proc_info_items);

@foo = process_list();
foreach $pid (@foo) {
  $procinfo = get_all_proc_info_items($pid);
  print $pid, "\t", $procinfo->{USERNAME}, "\t",  $procinfo->{PRCNAM}, "\n";
  
}
