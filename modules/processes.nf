process PORECHOP {
    tag "Porechop on $sample_id"

    conda "/MIGE/01_DATA/07_TOOLS_AND_SOFTWARE/nextflow_pipelines/filter_assemble_error-correct_ont/conda_environments/porechop_filtlong_env.yml"

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

    conda "/MIGE/01_DATA/07_TOOLS_AND_SOFTWARE/nextflow_pipelines/filter_assemble_error-correct_ont/conda_environments/porechop_filtlong_env.yml"


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

process FLYE {
    publishDir "${params.output_dir}/${meta}_FLYE", mode:'copy'
    tag "flye on $meta"
    
    errorStrategy 'ignore'
    
    conda "/MIGE/01_DATA/07_TOOLS_AND_SOFTWARE/nextflow_pipelines/filter_assemble_error-correct_ont/conda_environments/flye_env.yml"
    // outside of the TAPIR network, simply edit script and use conda '../flye_env.yml'

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
    
    errorStrategy 'ignore'
    
    // publishDir "${params.output_dir}", mode:'copy'
    
    conda '/MIGE/01_DATA/07_TOOLS_AND_SOFTWARE/nextflow_pipelines/filter_assemble_error-correct_ont/conda_environments/medaka_env.yml'
    // when used outside the TAPIR network, simply edit the code and use conda '../medaka_env.yml)'
    
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
    
    errorStrategy 'ignore'
    
    
    conda '/MIGE/01_DATA/07_TOOLS_AND_SOFTWARE/nextflow_pipelines/filter_assemble_error-correct_ont/conda_environments/medaka_env.yml'
    
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
    
    sed -i "s/^>/>${prefix}_/g" ${prefix}.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
