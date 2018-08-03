require 'io/console'
require 'find'
require 'thwait'

class FileOrigin
  def initialize matchstr, recursive: false, nowrap: false
    @recursive = recursive
    @nowrap = nowrap
    @disable = false
    @match = (matchstr || '')
    @match = File.basename @match if File.file? @match
    @counter = 0
    @pad = 20   # of urls / ZoneId
    @conx = IO.console.winsize[1] - 2
    @wrapw = (@conx - @pad)
    @spinner = '▉▊▋▌▍▎▏▎▍▌▋▊▉'.chars
    @t = Thread.new do
      until @disable do
        sleep 0.05
        @spinner.rotate!
      end
    end
  end

  def disable
    @disable = true
  end

  def abortmsg
    "Aborted"
  end

  def search
    Find.find('./').lazy.each do |entry|
      return if @disable
      if File.file?(entry)
        print_info entry
      elsif File.directory?(entry) && entry != './'
        Find.prune unless @recursive
      end
    end
  rescue Errno::EINVAL => e
  end

  def finish
    puts "#{washline}#{@disable ? abortmsg : summary}"
    @disable = true
    ThreadsWait.all_waits(@t)
  end

  def grepfile data
    data.split("\n").map {|l| l.split('=', 2)}.select {|a| a.size == 2}
  end

  def fmt label, content
    colon = ': '
    content = linewrap(content) unless @nowrap
    label = label.size.odd? ? label : "#{label} "
    "%s%s" % ["   #{label}".ljust(@pad - colon.size, '. ') + colon, content]
  end

  def linewrap str
    str.scan(/.{1,#{@wrapw}}/).map {|l| ' ' * @pad + l}.join("\n").strip
  end

  def washline
    "\r"+(' ' * (@conx+1))+"\r"
  end

  def print_info fname
    print "\r#{@spinner.first}"
    zname = "#{fname}:Zone.Identifier"
    if File.file?(zname) && fname.include?(@match)
      data = File.open(zname).read
      if data.include?('Url') && !data.include?(":\\")
        print "#{washline}"
        puts [fname, grepfile(data).map {|pair| fmt(*pair) }, nil]
        @counter += 1
      end
    end
  end

  def summary
    (@counter < 1) ? 'No Records Found' : ''
  end
end

# typedef enum tagURLZONE { 
#   URLZONE_INVALID         = -1,
#   URLZONE_PREDEFINED_MIN  = 0,
#   URLZONE_LOCAL_MACHINE   = 0,
#   URLZONE_INTRANET,
#   URLZONE_TRUSTED,
#   URLZONE_INTERNET,
#   URLZONE_UNTRUSTED,
#   URLZONE_PREDEFINED_MAX  = 999,
#   URLZONE_USER_MIN        = 1000,
#   URLZONE_USER_MAX        = 10000
# } URLZONE;