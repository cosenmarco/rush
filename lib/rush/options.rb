require 'optparse'
require 'rush/version'

# This class is responsible of parsing correctly the command line
module Rush
  class RushOptions

    # Parses the options from the command line. The input parameter must be the ARGV.
    def initialize(argv)
      @options = {}

      ind = argv.index "--"
      @options['command'] = argv.slice!(ind + 1 .. argv.size).join(" ") if ind


      OptionParser.new do |opts|
        opts.banner = <<-BAN

        Usage: rush [options] [--] [command]"

        When called without options a prompt is displayed.
        -- denotes the end of the options.
        BAN

        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-f", "--file FILENAME",
                "Executes the Rush script specified in file") do |f|
          @options['file'] = f
                end


        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        # Another typical switch to print the version.
        opts.on_tail("--version", "Show version and exit") do
          puts "Rush version " + VERSION 
          exit
        end
      end.parse!(argv)

      @options['command'] = argv.join(" ") if argv.size > 0

    end

    def [](key)
      @options[key] if key.is_a?(String)
    end

  end
end
