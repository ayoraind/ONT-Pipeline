/*
 * pipeline input parameters
 */
//params.input_dir = "~/test/"
//params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
//params.fastq_pattern = "*.fastq.gz"
//params.reads = params.input_dir + "/" + params.fastq_pattern
//params.output_dir = "results"



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
    

    script:
    
    """
    porechop \\
        -i ${reads} \\
        -t ${task.cpus} \\
        --format fastq \\
        -o ${sample_id}_PORECHOP.fastq \\
       
	
    # gzip output
    gzip ${sample_id}_PORECHOP.fastq
    
    """
}

workflow {
    reads_ch = channel.fromFilePairs( params.reads, checkIfExists: true )
    PORECHOP(reads_ch)
}

