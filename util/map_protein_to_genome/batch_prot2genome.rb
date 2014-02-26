require 'bio'
require 'tempfile'

query = ARGV[0]
genome = ARGV[1]

Bio::FlatFile.open(Bio::FastaFormat, query).each do |fas|
  tf = Tempfile.new("#{fas.entry_id}")
  tf.puts fas
  tf.close
  cmd = "ruby prot2genome.rb #{tf.path} #{genome}"
  IO.popen(cmd){|io| io.read}
end
