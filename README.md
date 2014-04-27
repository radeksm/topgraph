Why topgrapg?
=============

  Topgrapg is a small utility written in ruby to parse output from Linux top
command and visualize few important aspects of this putput from performance
point of view. So far there is only few graphs generated but I am going
to add more.
  It can be use by sysadmins or support engineers to analyze system behavior
in some period of time, helps understand how load, number processes or other
system parameters change as time goes.
  I am NOT a ruby programmer and topgraph is the first project I wroteain this
language, so please forgive quality ;)

Requirements
============
1. ruby
2. gnuplot

HOWTO
=====
1. Collect the top data:
   top -b -n 5  > /tmp/top.data
2. Process top data na generate graphs:
   ./topgraph.rb [-o|--out] OUTPUT_DIRECTORY top_input_file
   ./topgraph.rb -o /tmp/out /tmp/top.data

Homepage
========
http://vmcrowd.com/topgraph
