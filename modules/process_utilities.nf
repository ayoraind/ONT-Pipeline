def find_genome_size(sample_id, mash_output) {
  m = mash_output =~ /Estimated genome size: (.+)/
  genome_size = Float.parseFloat(m[0][1]).toInteger()
  return [sample_id, genome_size]
}
