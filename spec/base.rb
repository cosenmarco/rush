require 'rubygems'
#require 'spec'
FILE_ENTRY_SIZE = 20      # This is the file descriptor size as reported by du -sb for an empty file that stays in an empty dir.
DIR_ENTRY_SIZE = 40      # This is the dir descriptor size as reported by du -sb for an empty dir.

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'rush'

def mock_config(&block)
	mock_config_start
	block.call(config)
	mock_config_end
end

def mock_config_sandbox_dir
	"/tmp/fake_config.#{Process.pid}"
end

def mock_config_start
	mock_config_cleanup
	Rush::Config.new(mock_config_sandbox_dir)
end

def mock_config_cleanup
	FileUtils.rm_rf(mock_config_sandbox_dir)
end
