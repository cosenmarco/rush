# The config class accesses files in ~/.rush to load and save user preferences.
class Rush::Config
	DefaultPort = 7770

	attr_reader :dir

	# By default, reads from the dir ~/.rush, but an optional parameter allows
	# using another location.
	def initialize(location=nil)
		@dir = Rush::Dir.new(location || "#{ENV['HOME']}/.rush")
		@dir.create
	end

	# History is a flat file of past commands in the interactive shell,
	# equivalent to .bash_history.
	def history_file
		dir['history']
	end

	def save_history(array)
		history_file.write(array.join("\n") + "\n")
	end

	def load_history
		history_file.contents_or_blank.split("\n")
	end

	# The environment file is executed when the interactive shell starts up.
	# Put aliases and your own functions here; it is the equivalent of .bashrc
	# or .profile.
	#
	# Example ~/.rush/env.rb:
	#
	#   server = Rush::Box.new('www@my.server')
	#   myproj = home['projects/myproj/']
	def env_file
		dir['env.rb']
	end

	def load_env
		env_file.contents_or_blank
	end

	# Commands are mixed in to Array and Rush::Entry, alongside the default
	# commands from Rush::Commands.  Any methods here should reference "entries"
	# to get the list of entries to operate on.
	#
	# Example ~/.rush/commands.rb:
	#
	#   def destroy_svn(*args)
	#     entries.select { |e| e.name == '.svn' }.destroy
	#   end
	def commands_file
		dir['commands.rb']
	end

	def load_commands
		commands_file.contents_or_blank
	end
end
