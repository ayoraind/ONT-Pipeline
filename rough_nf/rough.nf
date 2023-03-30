/*
 * pipeline input parameters
 */
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"

params.output_dir = "$PWD/results"


log.info """\
    ONT PREPROCESSING  - TAPIR   P I P E L I N E
    ============================================
    reads            : ${params.reads}
    output_dir       : ${params.output_dir}
    """
    .stripIndent()

/*
 * define the `index` process that creates a binary index
 * given the transcriptome file
 */
 


process PORECHOP {
    publishDir "${params.output_dir}/porechop", mode:'copy'
    tag "Porechop on $sample_id"
    
    conda "bioconda::porechop=0.2.4"
    
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.fastq.gz"), emit: fastqs_ch
    tuple val(sample_id), path("*.log"), emit: log_ch
    
    
    script:
    
    """
    porechop \\
        -i ${reads} \\
        -t ${task.cpus} \\
        --format fastq \\
        -o ${sample_id}.PORECHOP.fastq \\
	> ${sample_id}.log
    
    
    # gzip output
    gzip ${sample_id}.PORECHOP.fastq
    
    """
}

workflow {
         reads_ch = channel
                          .fromPath( params.reads, checkIfExists: true )
		          .map { file -> tuple(file.simpleName, file) }
		 		     
    PORECHOP(reads_ch)
}

