require 'erb'
require 'open3'

class GnuPlotExec
    attr_writer :gnuplot_script_file
    def exec(verbose=false)
        cmd = '/usr/bin/gnuplot ' + @gnuplot_script_file
        if verbose
            puts "GnuPlotExec(#{cmd})"
        end
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
        pid = wait_thr[:pid] 
        if verbose; puts "gnuploat PID: #{pid}"; end
        stdin.close
        stdout.close
        stderr.close
        if verbose; puts stdin, stdout, stderr; end
        wait_thr.value
    end
end

class GnuPlotGeneric
    attr_writer :title, :height, :width, :term, :verbose, :out_dir, :out_file
    attr_reader :title, :height, :width, :term, :verbose, :out_dir, :out_file, :template
    def set_defaults
        @title = "Title"
        @height = 600
        @width = 800 
        @term = "png"
        @out_file = 'default.' + @term
    end
end

class PlotLoad < GnuPlotGeneric
    def add_load_point(top_obj)
        @file_data.write("#{top_obj.time}\t#{top_obj.load1}\t" +\
            "#{top_obj.load5}\t#{top_obj.load15}\n")
    end
    def ploat_load
        @file_data.close()
        @file_data_name_gp = @file_data_name + '.gp'
        gnuploat_script = @template_erb.result(binding)
        gnuplot_script_file = File.open(@file_data_name_gp, 'w')
        gnuplot_script_file.write(gnuploat_script)
        gnuplot_script_file.close()
        gpexec = GnuPlotExec.new
        gpexec.gnuplot_script_file = @file_data_name_gp
        gpexec.exec(true)
    end
    def initialize_template(verbose=false)
        set_defaults
        @out_file = 'load.' + @term
        @file_data_name = @out_dir + '/data_load'
        if verbose; puts "out_dir=#{@out_dir} file_data_name=#{@file_data_name}"; end
        @file_data = File.open(@file_data_name, 'w')
        @title = "System load (1min, 5min, 15min)"
        @template = %q{
            cd "<%= @out_dir %>"
            set term png size <%= @width %>, <%= @height %>
            set output '<%= @out_file %>'
            set title '<%= @title %>'
            set timefmt "%H:%M:%S"
            set xdata time
            set xtics format "%H:%M:%S"
            set xtics "01:00:00"
            set xlabel "Time"
            set ylabel "System load"
            plot \
                '<%= @file_data_name %>' using 1:2:xtic(1) with lines title 'load averages for the past 1  min',\
                '<%= @file_data_name %>' using 1:3:xtic(1) with lines title 'load averages for the past 10 min', \
                '<%= @file_data_name %>' using 1:4:xtic(1) with lines title 'load averages for the past 15 min'
            }.gsub(/^\s{1,}/,'')
        @template_erb = ERB.new(@template)
    end
end

class PlotLoad_and_Dstate < GnuPlotGeneric
    def check_d_state(top_obj)
        how_many_D_state = 0
        top_obj.process_list.keys.each do  |k|
            if top_obj.process_list[k].state = "D"
                how_many_D_state += 1
            end
        end
        return how_many_D_state
    end
    def add_load_point(top_obj)
        @file_data.write("#{top_obj.time}\t#{top_obj.load1}\t\
            #{top_obj.load5}\t#{top_obj.load15}\t\
            #{check_d_state(top_obj)}\n")
    end
    def ploat_load
        @file_data.close()
        @file_data_name_gp = @file_data_name + '.gp'
        gnuploat_script = @template_erb.result(binding)
        gnuplot_script_file = File.open(@file_data_name_gp, 'w')
        gnuplot_script_file.write(gnuploat_script)
        gnuplot_script_file.close()
        gpexec = GnuPlotExec.new
        gpexec.gnuplot_script_file = @file_data_name_gp
        gpexec.exec(true)
    end
    def initialize_template(verbose=false)
        set_defaults
        @out_file = 'load_d_state.' + @term
        @file_data_name = @out_dir + '/data_load_d_state'
        if verbose; puts "out_dir=#{@out_dir} file_data_name=#{@file_data_name}"; end
        @file_data = File.open(@file_data_name, 'w')
        @title = "System load (1min, 5min, 15min) and D state process count"
        @template = %q{
            cd "<%= @out_dir %>"
            set term png size <%= @width %>, <%= @height %>
            set output '<%= @out_file %>'
            set title '<%= @title %>'
            set timefmt "%H:%M:%S"
            set xdata time
            set xtics format "%H:%M:%S"
            set xtics "01:00:00"
            set xlabel "Time"
            set ylabel "System load and D state process number"
            set logscale y
            plot \
                '<%= @file_data_name %>' using 1:2:xtic(1) with lines title 'load averages for the past 1  min',\
                '<%= @file_data_name %>' using 1:5:xtic(1) with lines title 'D state'
            }.gsub(/^\s{1,}/,'')
        @template_erb = ERB.new(@template)
    end
end

class PlotMemSwap < GnuPlotGeneric
    attr_writer :y_logarithmic
    def add_memswap_point(top_obj)
        @file_data.write("#{top_obj.time}\t" +\
            "#{top_obj.mem_used}\t#{top_obj.mem_free}\t\
            #{top_obj.mem_buffers}\t#{top_obj.swap_used}\n")
    end
    def ploat_memswap
        @file_data.close()

        if @y_logarithmic
            @out_file = 'mem.swap.logarithmic.' + @term
            @file_data_name_gp = @file_data_name + '.logarithmic.gp'
        else
            @file_data_name_gp = @file_data_name + '.gp'
        end

        gnuploat_script = @template_erb.result(binding)
        gnuplot_script_file = File.open(@file_data_name_gp, 'w')
        gnuplot_script_file.write(gnuploat_script)
        gnuplot_script_file.close()
        gpexec = GnuPlotExec.new
        gpexec.gnuplot_script_file = @file_data_name_gp
        gpexec.exec(true)
    end
    def initialize_template(verbose=false)
        set_defaults
        if @y_logarithmic
            @out_file = 'mem.swap.logarithmic.' + @term
        else
            @out_file = 'mem.swap.' + @term
        end
        @file_data_name = @out_dir + '/data_mem_swap'
        if verbose; puts "out_dir=#{@out_dir} file_data_name=#{@file_data_name}"; end
        @file_data = File.open(@file_data_name, 'w')
        @title = "System memory and swap"
        @template = %q{
            cd "<%= @out_dir %>"
            set term png size <%= @width %>, <%= @height %>
            set output '<%= @out_file %>'
            set title '<%= @title %>'
            set timefmt "%H:%M:%S"
            set xdata time
            set xtics format "%H:%M:%S"
            set xtics "01:00:00"
            set xlabel "Time"
            set ylabel "Memory and swap"
            <% if @y_logarithmic %>
                set logscale y
            <% end %>
            plot \
                '<%= @file_data_name %>' using 1:2:xtic(1) with lines title 'Memory used',\
                '<%= @file_data_name %>' using 1:3:xtic(1) with lines title 'Memory free', \
                '<%= @file_data_name %>' using 1:4:xtic(1) with lines title 'Memory buffers', \
                '<%= @file_data_name %>' using 1:5:xtic(1) with lines title 'Swap used'
            }.gsub(/^\s{1,}/,'')
        @template_erb = ERB.new(@template)
    end
end

class PlotTasks < GnuPlotGeneric
    def add_tasks_point(top_obj)
        @file_data.write("#{top_obj.time}\t#{top_obj.tasks}\n")
    end
    def ploat_tasks
        @file_data.close()
        @file_data_name_gp = @file_data_name + '.gp'
        gnuploat_script = @template_erb.result(binding)
        gnuplot_script_file = File.open(@file_data_name_gp, 'w')
        gnuplot_script_file.write(gnuploat_script)
        gnuplot_script_file.close()
        gpexec = GnuPlotExec.new
        gpexec.gnuplot_script_file = @file_data_name_gp
        gpexec.exec(true)
    end
    def initialize_template(verbose=false)
        set_defaults
        @out_file = 'tasks.' + @term
        @file_data_name = @out_dir + '/data_tasks'
        if verbose; puts "out_dir=#{@out_dir} file_data_name=#{@file_data_name}"; end
        @file_data = File.open(@file_data_name, 'w')
        @title = "System tasks, number of processes"
        @template = %q{
            cd "<%= @out_dir %>"
            set term png size <%= @width %>, <%= @height %>
            set output '<%= @out_file %>'
            set title '<%= @title %>'
            set timefmt "%H:%M:%S"
            set xdata time
            set xtics format "%H:%M:%S"
            set xtics "01:00:00"
            set xlabel "Time"
            set ylabel "Processes number"
            plot \
                '<%= @file_data_name %>' using 1:2:xtic(1) with lines title 'Number of processes'
            }.gsub(/^\s{1,}/,'')
        @template_erb = ERB.new(@template)
    end
end
