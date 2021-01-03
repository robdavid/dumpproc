require "option_parser"

#output : String? = nil
output_file : IO? = nil
output : String? = nil
quiet = false

OptionParser.parse do |parser|
  parser.banner = "Usage dumpproc [-o OUTPUT] [pids...]"
  parser.on("-o OUTPUT", "--output OUTPUT", "Send all output to specified file, - for stdout") do |o|
    if o == "-"
      output_file = STDOUT
      output = "stdout"
    else
      output = o
    end
  end
  parser.on("-q","--quiet","Reduce output noise") { quiet = true }
  parser.on("-h","--help","Display this help") do
    STDERR.puts(parser)
    exit(0)
  end
end

if ARGV.empty? 
  STDERR.puts("#{PROGRAM_NAME}: No pids specified")
  exit(1)
end

with_output(output,output_file) do |output_file|
  ARGV.each do |pid|
    unless File.directory?("/proc/#{pid}")
      puts("#{PROGRAM_NAME}: pid #{pid}: Does not exist")
      next
    end
    begin
      File.open("/proc/#{pid}/maps") do |maps_file|
        File.open("/proc/#{pid}/mem") do |mem_file|
          output = "#{pid}.dump" unless output_file
          max_chunks = chunks = 0
          bytes = 0_i64
          STDERR.puts("#{PROGRAM_NAME}: pid #{pid}: Dumping memory")
          with_output(output,output_file) do |output_file|
            next unless output_file
            maps_file.each_line do |line|
              /([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])/.match(line).try do |m|
                if m[3] == "r"
                  from = m[1].to_i64(base: 16)
                  to = m[2].to_i64(base: 16)
                  max_chunks += 1
                  begin
                    mem_file.seek(from)
                    IO.copy(mem_file,output_file,to-from)
                    chunks += 1
                    bytes += to-from
                  rescue e : IO::Error
                    STDERR.puts("#{PROGRAM_NAME}: pid #{pid}: Error reading range #{m[1]}-#{m[2]}: #{e}") unless quiet
                  end
                end
              end
            end
          end
          STDERR.puts("#{PROGRAM_NAME}: pid #{pid}: Wrote #{chunks}/#{max_chunks} memory chunks (#{bytes} bytes) to #{output}") unless quiet
        end
      end
    rescue e : IO::Error
      STDERR.puts("#{PROGRAM_NAME}: #{pid}: #{e}")
    end
  end
end

# Open an output file and run code before closing it, or else just
# pass through the file IO if we already have one open
def with_output(name : String?, io : IO? = nil)
  if io
    yield io
  elsif name
    File.open(name,"w") do |f| 
      protect_file(name)
      yield f 
    end
  else
    yield nil
  end
end

def protect_file(name : String)
  File.chmod(name,0o600)
  if user = ENV["SUDO_USER"]?
    uid = `id #{user} -u`.to_i
    gid = `id #{user} -g`.to_i
    File.chown(name,uid: uid, gid: gid)
  end
end