#!/usr/bin/env ruby

require 'optparse'
load 'plot.rb'

class TopLine_Process
    # this is the porcess line representation, ie:
    # 29 root       0 -20       0      0      0 S   0.0  0.0   0:00.00 writeback
    attr :name, true
    attr :cpu, true
    attr :mem, true
    attr :state, true
    attr :pid, true
    def initialize(verbose=false, line)
        if line
            parse_line(line)
        else
            @pid = nil
            @name = nil
            @cpu = nil
            @mem = nil
            @state = nil
        end
    end
    def to_str
        "Task[PID:#{@pid} #{@name} CPU:#{@cpu} Mem:#{@mem} State:#{@state}]"
    end
    def parse_line(line)
        @line_elems = line.split
        if line and @line_elems.length == 12
            @pid = @line_elems[0]
            @state = @line_elems[7]
            @cpu = @line_elems[8]
            @mem = @line_elems[9]
            @name = @line_elems[11]
        end
    end
end

class TopObject
    attr :time, true
    attr :load1, true
    attr :load5, true
    attr :load15, true
    attr :tasks, true
    attr :process_list, true
    attr_writer :cpu_us, :cpu_sy, :cpu_ni, :cpu_id, :cpu_wa, :cpu_hi, :cpu_si, :cpu_st
    attr_reader :cpu_us, :cpu_sy, :cpu_ni, :cpu_id, :cpu_wa, :cpu_hi, :cpu_si, :cpu_st
    attr_writer :mem_total, :mem_used, :mem_free, :mem_buffers
    attr_reader :mem_total, :mem_used, :mem_free, :mem_buffers
    attr_writer :swap_total, :swap_used, :swap_free, :swap_cached
    attr_reader :swap_total, :swap_used, :swap_free, :swap_cached

    def initialize(line, verbose=false)
        @verbose = verbose
        @line = line
        @process_list = {}
    end

    def to_str
        "Time:#{@time} load:[#{@load1}|#{@load5}|#{@load15}] Tasks:#{@tasks}" +
            " CPU[us:#{@cpu_us},sy:#{@cpu_sy},id:#{@cpu_id}]" +
            " Mem[#{@mem_total},#{@mem_used},#{@mem_free},#{@mem_buffers}]" +
            " Swap[#{@swap_total},#{@swap_used}" +
            " PIDs:#{@process_list.length}]"
    end

    def process_line(line=nil)
        if line == nil
            return line
        end

        @line_elems = line.split

        if /[0-9]{1,}/.match(@line_elems[0])
            @process = TopLine_Process.new(line)
            @process_list[@process.pid] = @process
        elsif line[0,3] == 'top'
            @time = @line_elems[2]
            @load1 = @line_elems[9][0..-2]
            @load5 = @line_elems[10][0..-2]
            @load15 = @line_elems[11]
        elsif line[0,5] == 'Tasks'
            @tasks = @line_elems[1]
        elsif line[0,8] == '%Cpu(s):'
            # %Cpu(s):  1.2 us,  0.5 sy,  0.1 ni, 89.1 id,  9.0 wa,  0.1 hi,  0.1 si,  0.0 st
            @cpu_us = @line_elems[1]
            @cpu_sy = @line_elems[3]
            @cpu_ni = @line_elems[5]
            @cpu_id = @line_elems[7]
            @cpu_wa = @line_elems[9]
            @cpu_hi = @line_elems[11]
            @cpu_si = @line_elems[13]
            @cpu_st = @line_elems[15]
        elsif line[0,7] == 'KiB Mem'
            # KiB Mem:   3925528 total,  1980588 used,  1944940 free,    28600 buffers
            @mem_total = @line_elems[2]
            @mem_used = @line_elems[4]
            @mem_free = @line_elems[6]
            @mem_buffers = @line_elems[8]
        elsif line[0,8] == 'KiB Swap'
            # KiB Swap:   974844 total,        0 used,   974844 free,   952516 cached
            @swap_total = @line_elems[2]
            @swap_used = @line_elems[4]
            @swap_free = @line_elems[6]
            @swap_cached = @line_elems[8]
        end
    end
end

def check_if_file_exists(top_data, verbose=false)
    # is file exist?
    if FileTest.exist?(top_data) and FileTest.file?(top_data)
        @top_data_size = FileTest.size(top_data)
        if verbose; puts "File #{top_data} (size: #{@top_data_size}b) exists opening."; end
        return true
    else
        STDERR.puts "File #{top_data} does not exists or is inaccessible."
    end
    return false
end

def check_output_directory(out_dir, verbose=false)
    if not out_dir
        if verbose; STDERR.puts "No output directory specified"; end
        return false
    end
    if File.directory?(out_dir) and File.writable?(out_dir)
        return true
    else
        STDERR.puts "Output directory #{out_dir} does not exists, trying to create it"
        Dir.mkdir(out_dir)
    end
end
    
def parse_top_data_file(top_data, out_dir, verbose=false)
    f = File.open(top_data)
    top = nil
    top_list = []
    f.each do |line|
        line_elems = line.split
        if line[0,3] == 'top'
            if top
                top_list.push(top)
                top = TopObject.new(true)
            else
                top = TopObject.new(true)
            end
        end
        top.process_line(line)
    end
    f.close()

    load_ploat = PlotLoad.new
    memswap_plot = PlotMemSwap.new
    memswap_plot_ylogscale = PlotMemSwap.new
    tasks_ploat = PlotTasks.new
    load_d_state = PlotLoad_and_Dstate.new
    
    memswap_plot_ylogscale.y_logarithmic = true

    load_ploat.out_dir = out_dir
    memswap_plot.out_dir = out_dir
    memswap_plot_ylogscale.out_dir = out_dir
    tasks_ploat.out_dir = out_dir
    load_d_state.out_dir = out_dir
    
    
    load_ploat.out_file = 'load_graph'
    memswap_plot.out_file = 'memswap_graph'
    memswap_plot_ylogscale.out_file = 'memswap_graph'
    tasks_ploat.out_file = 'tasks_graph'
    load_d_state.out_file = 'load_d_state_graph'
    
    load_ploat.initialize_template
    memswap_plot.initialize_template
    memswap_plot_ylogscale.initialize_template
    tasks_ploat.initialize_template
    load_d_state.initialize_template

    top_list.each do |x|
        puts "" + x if verbose
        load_ploat.add_load_point(x)
        memswap_plot.add_memswap_point(x)
        tasks_ploat.add_tasks_point(x)
        load_d_state.add_load_point(x)
    end

    load_ploat.ploat_load
    memswap_plot.ploat_memswap
    memswap_plot_ylogscale.ploat_memswap
    tasks_ploat.ploat_tasks
    load_d_state.ploat_load
end

if __FILE__ == $0
    options = {}
    OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"
        opts.separator " SEPARATOR"
        opts.on("-v", "--verbose", "Run verbosely") do |v|
            options[:verbose] = v
        end
        opts.on("-o", "--out DIR",
            "output directtory (where all data will be saved)") do |outd|
            options[:outd] = outd
        end
        opts.on_tail("-h", "--help", "This help") do
            puts "This help message"
            exit
        end
    end.parse!

    if options[:outd]
        out_dir = options[:outd]
        puts "Output directory: #{out_dir}"
    else
        out_dir = '/tmp'
        puts "Output directory not specified, using #{out_dir}"
    end

    verbose = options[:verbose]

    if not ARGV[0]
        STDERR.puts "No data file specified. Nothing to do, exiting."
        exit(2)
    end
    top_data_file = ARGV[0]


    if check_if_file_exists(top_data_file, verbose) \
        and check_output_directory(out_dir, verbose)
            parse_top_data_file(top_data_file, out_dir, verbose)
    else
        exit(1)
    end
end
