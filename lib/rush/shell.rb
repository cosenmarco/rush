require 'readline'
require 'rush'

# Rush::Shell is used to create an interactive shell.  It is invoked by the rush binary.
# There are 2 types of invocation: #execute(cmd) and #run(). The first executes a command and exits.
# The latter prompts for command and execute them in a loop or loads and executes a script (depending on options).
module Rush
  class Shell
    DEFAULT_PROMPT = 'rush > '
    MULTILINE_PROMPT = '-> '
    attr_accessor :suppress_output

    # Set up the user's environment, including a pure binding into which
    # env.rb and commands.rb are mixed.
    def initialize(options)
      root = Rush::Dir.new('/')
      home = Rush::Dir.new(ENV['HOME']) if ENV['HOME']
      pwd = Rush::Dir.new(ENV['PWD']) if ENV['PWD']

      @pwd = pwd

      @config = Rush::Config.new
      @options = options

      @config.load_history.each do |item|
        Readline::HISTORY.push(item)
      end

      Readline.basic_word_break_characters = ""
      Readline.completion_append_character = nil
      Readline.completion_proc = completion_proc

      @box = Rush::Box.new
      @pure_binding = @box.instance_eval "binding"
      $last_res = nil

      eval @config.load_env, @pure_binding

      commands = @config.load_commands
      Rush::Dir.class_eval commands
      Array.class_eval commands
    end

    # Run the interactive shell using readline.
    # Or if specified in @options runs a rush script and exits
    # Or if specified in options
    def run
      if @options['file']
        execute_script @options['file']
      elsif @options['command']
        execute @options['command']
      else
        interactive_shell
        puts 
      end
    end

    # A stub for the readline handler. At the moment it is implemented with the
    # Readline stdlib class.
    def readline(p); Readline.readline(p); end

    # Clears the command history
    def clear_history
      Readline::HISTORY.drop Readline::HISTORY.size
    end

    # The main commands loop for the interactive shell
    def interactive_shell
      final_cmd = ""
      prompt = DEFAULT_PROMPT
      loop do
        cmd = readline(prompt)

        case cmd
        when "", "\\"
          next
        when "exit", nil
          finish
          break
        when /.?\\$/
          final_cmd += cmd.sub(/\\$/,"\n")
          prompt = MULTILINE_PROMPT
          Readline::HISTORY.push(cmd)
          next
        else
          final_cmd += cmd
          Readline::HISTORY.push(cmd)
        end

        execute(final_cmd)
        final_cmd = ""
        prompt = DEFAULT_PROMPT
      end
    end

    # Executes the content of a scripting file
    def execute_script(file)
      abspath = ::File.expand_path(file,@pwd.full_path)
      execute(Rush::File.new(abspath).contents)
    end

    # Run a single command.
    def execute(cmd)
      res = eval(cmd, @pure_binding)
      $last_res = res
      eval("_ = $last_res", @pure_binding)
      print_result res
    rescue Rush::Exception => e
      puts "Exception #{e.class} -> #{e.message}"
    rescue ::Exception => e
      puts "Exception #{e.class} -> #{e.message}"
      e.backtrace.each do |t|
        puts "   #{::File.expand_path(t)}"
      end
    end


    # Save history to ~/.rush/history when the shell exists.
    def finish
      @config.save_history(Readline::HISTORY.to_a)
    end

    # Nice printing of different return types, particularly Rush::SearchResults.
    def print_result(res)
      return if self.suppress_output
      if res.kind_of? String
        puts res
      elsif res.kind_of? Rush::SearchResults
        widest = res.entries.map { |k| k.full_path.length }.max
        res.entries_with_lines.each do |entry, lines|
          print entry.full_path
          print ' ' * (widest - entry.full_path.length + 2)
          print "=> "
          print res.colorize(lines.first.strip.head(30))
          print "..." if lines.first.strip.length > 30
          if lines.size > 1
            print " (plus #{lines.size - 1} more matches)"
          end
          print "\n"
        end
        puts "#{res.entries.size} matching files with #{res.lines.size} matching lines"
      elsif res.respond_to? :each
        counts = {}
        res.each do |item|
          puts item
          counts[item.class] ||= 0
          counts[item.class] += 1
        end
        if counts == {}
          puts "=> (empty set)"
        else
          count_s = counts.map do |klass, count|
            "#{count} x #{klass}"
          end.join(', ')
          puts "=> #{count_s}"
        end
      else
        puts "=> #{res.inspect}"
      end
    end

    def path_parts(input)		# :nodoc:
      case input
      when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)([\[\/])(['"])([^\3]*)$/
        $~.to_a.slice(1, 4).push($~.pre_match)
      when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)(\.)(\w*)$/
        $~.to_a.slice(1, 3).push($~.pre_match)
      when /((?:@{1,2}|\$|)\w+)$/
        $~.to_a.slice(1, 1).push(nil).push($~.pre_match)
      else
        [ nil, nil, nil ]
      end
    end

    def complete_method(receiver, dot, partial_name, pre)
      path = eval("#{receiver}.full_path", @pure_binding) rescue nil
      box = eval("#{receiver}.box", @pure_binding) rescue nil
      if path and box
        (box[path].methods - Object.methods).select do |e|
          e.match(/^#{Regexp.escape(partial_name)}/)
        end.map do |e|
          (pre || '') + receiver + dot + e
        end
      end
    end

    def complete_path(possible_var, accessor, quote, partial_path, pre)		# :nodoc:
      original_var, fixed_path = possible_var, ''
      if /^(.+\/)([^\/]*)$/ === partial_path
        fixed_path, partial_path = $~.captures
        possible_var += "['#{fixed_path}']"
      end
      full_path = eval("#{possible_var}.full_path", @pure_binding) rescue nil
      box = eval("#{possible_var}.box", @pure_binding) rescue nil
      if full_path and box
        Rush::Dir.new(full_path, box).entries.select do |e|
          e.name.match(/^#{Regexp.escape(partial_path)}/)
        end.map do |e|
          (pre || '') + original_var + accessor + quote + fixed_path + e.name + (e.dir? ? "/" : "")
        end
      end
    end

    def complete_variable(partial_name, pre)
      lvars = eval('local_variables', @pure_binding)
      gvars = eval('global_variables', @pure_binding)
      ivars = eval('instance_variables', @pure_binding)
      (lvars + gvars + ivars).select do |e|
        e.match(/^#{Regexp.escape(partial_name)}/)
      end.map do |e|
        (pre || '') + e
      end
    end

    # Try to do tab completion on dir square brackets and slash accessors.
    #
    # Example:
    #
    # dir['subd    # presing tab here will produce dir['subdir/ if subdir exists
    # dir/'subd    # presing tab here will produce dir/'subdir/ if subdir exists
    #
    # This isn't that cool yet, because it can't do multiple levels of subdirs.
    # It does work remotely, though, which is pretty sweet.
    def completion_proc
      proc do |input|
        receiver, accessor, *rest = path_parts(input)
        if receiver
          case accessor
          when /^[\[\/]$/
            complete_path(receiver, accessor, *rest)
          when /^\.$/
            complete_method(receiver, accessor, *rest)
          when nil
            complete_variable(receiver, *rest)
          end
        end
      end
    end
  end
end
