process PORECHOP {
    tag "Porechop on $sample_id"
    memory { 4.GB * task.attempt }
    errorStrategy { task.attempt <= 5 ? "retry" : "finish" }
    maxRetries 5
    
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.fastq.gz"), emit: fastqs_ch
    tuple val(sample_id), path("*.log"),      emit: log_ch
    path "versions.yml",                      emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${sample_id}"

    """
    porechop \\
        -i ${reads} \\
        -t ${task.cpus} \\
        --format fastq \\
        -o ${sample_id}.PORECHOP.fastq \\
        > ${sample_id}.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop: \$( porechop --version )
    END_VERSIONS

    # gzip output
    gzip ${sample_id}.PORECHOP.fastq

    """
}


process FILTLONG {
    tag "Filtlong on $sample_id"
    memory { 4.GB * task.attempt }
    errorStrategy { task.attempt <= 5 ? "retry" : "finish" }
    maxRetries 5
    
    publishDir "${params.output_dir}", mode:'copy'
    
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.fastq.gz"), emit: fastqsfilt_ch
    tuple val(sample_id), path("*.log"), emit: logfilt_ch
    path "versions.yml"                 , emit: versionsfilt_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${sample_id}"
    if ("$reads" == "${prefix}.fastq.gz") error "Read FASTQ input and output names are the same, set prefix in module configuration to disambiguate!"
    
    """
    filtlong \\
        $args \\
        --min_length 1000 \\
        --keep_percent 90 \\
        --target_bases 1000000000 \\
        $reads \\
        2> ${prefix}.log \\
        | gzip -n > ${prefix}.FILTLONG.fastq.gz
	
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: \$( filtlong --version | sed -e "s/Filtlong v//g" )
    END_VERSIONS
    """
}

process NANOPLOT {
    tag "$meta"
    publishDir "${params.output_dir}/${meta}_NANOPLOT", mode:'copy'
    memory { 4.GB * task.attempt }
    errorStrategy { task.attempt <= 5 ? "retry" : "finish" }
    maxRetries 5

    input:
    tuple val(meta), path(ontfile)

    output:
    tuple val(meta), path("*.html")                , emit: html_ch
    tuple val(meta), path("*.png") , optional: true, emit: png_ch
    tuple val(meta), path("*.txt")                 , emit: txt_ch
    tuple val(meta), path("*.log")                 , emit: log_ch
    path  "versions.yml"                           , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def input_file = ("$ontfile".endsWith(".fastq.gz")) ? "--fastq ${ontfile}" :
        ("$ontfile".endsWith(".txt")) ? "--summary ${ontfile}" : ''
    """
    NanoPlot \\
        $args \\
        -t $task.cpus \\
        $input_file

    # rename
    mv NanoStats.txt ${meta}.NanoStats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(echo \$(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}

process NANOSTATS_TRANSPOSE {
   // publishDir "${params.output_dir}", mode:'copy'
    tag "$sample_id"


    input:
    tuple val(sample_id), path(txt)

    output:
    path("*.transposed.NanoStats.txt"), emit: nanostats_ch


    script:
    """
    transpose_nanoplot.sh ${sample_id}

    """
}

process COMBINE_NANOSTATS {
    publishDir "${params.output_dir}", mode:'copy'
    tag { 'combine nanostats files'}


    input:
    path(nanostats_files)
    val(sequencing_date)

    output:
    path("combined_nanostats_${sequencing_date}.txt"), emit: nanostats_comb_ch


    script:
    """
    NANOSTATS_FILES=(${nanostats_files})

    for index in \${!NANOSTATS_FILES[@]}; do
    NANOSTATS_FILE=\${NANOSTATS_FILES[\$index]}

    # add header line if first file
    if [[ \$index -eq 0 ]]; then
      echo "\$(head -1 \${NANOSTATS_FILE})" >> combined_nanostats_${sequencing_date}.txt
    fi
    echo "\$(awk 'FNR==2 {print}' \${NANOSTATS_FILE})" >> combined_nanostats_${sequencing_date}.txt
    done

    """
}

process GENOME_SIZE_ESTIMATION {
    tag { sample_id }
  //  publishDir "${params.output_dir}/${sample_id}_genome_size", mode:'copy'
    
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path('mash_stats.out')

    script:
    if (params.kmer_min_copy)
      """
        mash sketch -o sketch_${sample_id}  -k 32 -m ${params.kmer_min_copy} -r ${reads}  2> mash_stats.out
      """
    else
      """
      kat hist --mer_len 21  --thread 1 --output_prefix ${sample_id} ${reads} > /dev/null 2>&1 \
      && minima=`cat  ${sample_id}.dist_analysis.json | jq '.global_minima .freq' | tr -d '\\n'`
      mash sketch -o sketch_${sample_id}  -k 32 -m \$minima -r ${reads}  2> mash_stats.out
      """
}

process WRITE_OUT_EXCLUDED_GENOMES {
    tag { sample_id }

    publishDir "${params.output_dir}/estimated_size_of_excluded_genomes"
    input:
    tuple(val(sample_id), val(genome_size))

    output:
    path("${sample_id}.estimated_genome_size.txt") 

    script:
    """
    echo ${genome_size} > ${sample_id}.estimated_genome_size.txt
    """
}

process FLYE {
    publishDir "${params.output_dir}/${meta}_FLYE", mode:'copy'
    tag "flye on $meta"
    
    memory { 4.GB * task.attempt }
    errorStrategy { task.attempt <= 5 ? "retry" : "finish" }
    maxRetries 5
    
    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path("*.fasta")   , emit: fasta_ch
    tuple val(meta), path("*.gfa")     , emit: gfa_ch
    tuple val(meta), path("*.gv")      , emit: gv_ch
    tuple val(meta), path("*.txt")     , emit: txt_ch
    tuple val(meta), path("*.log")     , emit: log_ch
    tuple val(meta), path("*.json")    , emit: json_ch
    path "versions.yml"                , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def valid_mode = ["--pacbio-raw", "--pacbio-corr", "--pacbio-hifi", "--nano-raw", "--nano-corr", "--nano-hq"]
    if ( !valid_mode.contains(mode) )  { error "Unrecognised mode to run Flye. Options: ${valid_mode.join(', ')}" }
    """
    
    flye $mode $reads --keep-haplotypes --meta --out-dir . --threads $task.cpus $args
    
    mv assembly.fasta ${prefix}.fasta
    mv flye.log ${prefix}.flye.log
    mv assembly_graph.gfa ${prefix}.assembly_graph.gfa
    mv assembly_graph.gv ${prefix}.assembly_graph.gv
    mv assembly_info.txt ${prefix}.assembly_info.txt
    mv params.json ${prefix}.params.json
    
    sed -i "s/^>/>${prefix}_/g" ${prefix}.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
    END_VERSIONS
    """

}

process MEDAKA_FIRST_ITERATION {
    tag "error correction of $meta assemblies"
    
    memory { 4.GB * task.attempt }
    errorStrategy { task.attempt <= 5 ? "retry" : "finish" }
    maxRetries 5
    
    // publishDir "${params.output_dir}", mode:'copy'
        
    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta}.fasta"), emit: first_iteration_ch
    path "versions.yml"                   , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    medaka_consensus -t $task.cpus $args -i $reads -d $assembly -m r941_min_hac_g507 -o .
    
    mv consensus.fasta ${prefix}.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}


process MEDAKA_SECOND_ITERATION {
    tag "error correction of $meta assemblies"
    
    publishDir "${params.output_dir}/${meta}_FLYE_MEDAKA", mode:'copy'
    
    memory { 4.GB * task.attempt }
    errorStrategy { task.attempt <= 5 ? "retry" : "finish" }
    maxRetries 5
    
        
    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta}.fasta"), emit: second_iteration_ch
    path "versions.yml"                   , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when
    

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    medaka_consensus -t $task.cpus $args -i $reads -d $assembly -m r941_min_hac_g507 -o .
    
    mv consensus.fasta ${prefix}.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}

// assess assembly with Quast
process QUAST {
  tag { sample_id }

 // publishDir "${params.output_dir}", mode: 'copy'

  input:
  tuple val(sample_id), path(assembly)

  output:
  path("${sample_id}"), emit: quast_dir_ch
  tuple(val(sample_id), path("${sample_id}/transposed_report.tsv"), emit: quast_report_ch)
  path("${sample_id}/${sample_id}.tsv"), emit: quast_transposed_report_ch
  path "versions.yml" , emit: versions_ch

  """
  quast.py ${assembly} --threads $task.cpus -o $sample_id
  # mkdir ${sample_id}
  #ln -s \$PWD/report.tsv ${sample_id}/report.tsv
  cp ${sample_id}/transposed_report.tsv ${sample_id}/${sample_id}.tsv

  cat <<-END_VERSIONS > versions.yml
   "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
  END_VERSIONS
  """
}

// summarize
process QUAST_SUMMARY {
    publishDir "${params.output_dir}", mode:'copy'
    tag { 'combine quast transposed files'}


    input:
    path(quast_files)
    val(sequencing_date)

    output:
    path("combined_quast_${sequencing_date}.tsv"), emit: quast_comb_ch


    script:
    """
    QUAST_FILES=(${quast_files})

    for index in \${!QUAST_FILES[@]}; do
    QUAST_FILE=\${QUAST_FILES[\$index]}

    # add header line if first file
    if [[ \$index -eq 0 ]]; then
      echo "\$(head -1 \${QUAST_FILE})" >> combined_quast_${sequencing_date}.tsv
    fi
    echo "\$(awk 'FNR==2 {print}' \${QUAST_FILE})" >> combined_quast_${sequencing_date}.tsv
    done

    """
}

// QUAST MultiQC
process QUAST_MULTIQC {
  tag { 'multiqc for quast' }
  memory { 4.GB * task.attempt }

  publishDir "${params.output_dir}/quality_reports",
    mode: 'copy',
    pattern: "multiqc_report.html",
    saveAs: { "quast_multiqc_report.html" }

  input:
  path(quast_files) 

  output:
  path("multiqc_report.html")

  script:
  """
  multiqc --interactive .
  """
}
