ref_scaffold = ARGV[0]
#ref_scaffold = "scaffold_2"
prefix = "Rspe_#{ref_scaffold}_promer"

## hard masking is preferable for rgenome and qgenome 
rgenome = "Rspe02.final.assembly.hardmasked.fasta"
qgenome = "Znev_genome_scaffold.fasta.hardmasked"
## rgenome should be formatted as fai
## qgenome should be formatted as blastdb

lastz_net_result = "150412-Znev_Rspe_lastz.target.syn.net.tab.toponly"
mummer_path = "~/bio/applications/MUMmer3.23"

require 'rake'

rfastaf = "#{prefix}.fasta"
cmd = "samtools faidx #{rgenome} #{ref_scaffold} > #{rfastaf}"
sh cmd

qlistf = "#{prefix}_Znev_scaffolds.r1.list"
cmd = "grep --perl \"#{ref_scaffold}\t\" #{lastz_net_result} |cut -f 4 |sort|uniq > #{qlistf}"

sh cmd

qfastaf = "#{prefix}_Znev_scaffolds.r1.fasta"
cmd = "blastdbcmd -db #{qgenome} -entry_batch #{qlistf} > #{qfastaf}"

sh cmd

## Run MUMmer nucmer
cmd = "#{mummer_path}/promer --prefix=#{prefix}.vs.Znev #{rfastaf} #{qfastaf}"
sh cmd
#=> #{prefix}.vs.Znev.delta 

delta1 = "#{prefix}.vs.Znev.delta"
delta1f = "#{prefix}.vs.Znev.filt.delta"
cmd = "#{mummer_path}/delta-filter -q -r #{delta1} > #{delta1f}"
sh cmd

cmd = "#{mummer_path}/mummerplot #{delta1f} -R #{rfastaf} -Q #{qfastaf} --layout -t png --prefix #{delta1f}"
sh cmd

coordf = "#{delta1f}.coords"
cmd = "show-coords -r #{delta1f} > #{coordf}"
sh cmd

## choose hit scaffolds
hit_contigs = []
File.open(coordf).each do |l|
  a = l.chomp.strip.split(/\s+/)
  a.compact!
  if a.size == 17 && a[2] == "|"
    hit_contigs << a[16]
  end
end

hit_contigs.sort!
hit_contigs.uniq!

qlistf2 = "#{prefix}_Znev_scaffolds.r2.list"
File.open(qlistf2, "w"){|o| o.puts hit_contigs}

qfastaf2 = "#{prefix}_Znev_scaffolds.r2.fasta"
cmd = "blastdbcmd -db #{qgenome} -entry_batch #{qlistf2} > #{qfastaf2}"

sh cmd


## round 2
cmd = "#{mummer_path}/promer --prefix=#{prefix}.vs.Znev.r2 #{rfastaf} #{qfastaf2}"
sh cmd
#=> #{prefix}.vs.Znev.r2.delta 

delta2 = "#{prefix}.vs.Znev.r2.delta"
delta2f = "#{prefix}.vs.Znev.r2.filt.delta"
cmd = "#{mummer_path}/delta-filter -q -r #{delta2} > #{delta2f}"
sh cmd

cmd = "#{mummer_path}/mummerplot #{delta2f} -R #{rfastaf} -Q #{qfastaf2} --layout -t png --prefix #{delta2f}"
sh cmd

dir = "mummer_out.#{prefix}.vs.Znev"
sh "mkdir #{dir}"
sh "mv #{prefix}.* #{dir}/"
sh "mv #{prefix}_* #{dir}/"

STDERR.puts "#{Time.now}: completed"
