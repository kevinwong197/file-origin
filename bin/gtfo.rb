$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'io/console'
require 'optparse'
require 'fileorigin'

class IntCatch
  def initialize
    @exit_act = ->() do
      Process.kill 'INT', Process.pid
    end
  end

  def exec
    Thread.new do
      # steal Control-C processing from cmd
      next while "\u0003" != STDIN.getch
      @exit_act.call
    end    
    yield
  end
end

options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = <<~EOF
    Usage: gtfo [options...] <searchfilter>

      search files with zone identifiers containing url.

    Output Options:
  EOF
  options[:recursive] = false
  opts.on('-r', '--recursive', 'scan recursively') do
    options[:recursive] = true
  end

  options[:nowrap] = false
  opts.on('-n', '--nowrap', 'disable line wrapping for urls') do
    options[:nowrap] = true
  end
end.parse!
filter = ARGV.pop

intcatcher = IntCatch.new
intcatcher.exec do
  z = FileOrigin.new filter, options
  trap 'INT' do
    z.disable
  end
  z.search
  z.finish
end
