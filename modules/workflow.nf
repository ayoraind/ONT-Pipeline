// Include modules


include { PRE_SCREEN_FASTQ_FILESIZE; WRITE_OUT_FILESIZE_CHECK; PORECHOP; FILTLONG; NANOPLOT; NANOSTATS_TRANSPOSE; COMBINE_NANOSTATS; GENOME_SIZE_ESTIMATION; WRITE_OUT_EXCLUDED_GENOMES; FLYE; MEDAKA_FIRST_ITERATION; MEDAKA_SECOND_ITERATION; QUAST; QUAST_SUMMARY; QUAST_MULTIQC } from '../modules/processes.nf'

include { find_genome_size } from '../modules/process_utilities.nf'

		 
// def workflow

workflow NANOPORE {
    
    take:
    	reads_ch
	     
    main:
    
        versions_overall_ch = channel.empty()
	
	// pre screen check based on file size
  	if (params.prescreen_file_size_check){
        PRE_SCREEN_FASTQ_FILESIZE(reads_ch)
	// included genomes
        included_genomes_based_on_file_size_ch = PRE_SCREEN_FASTQ_FILESIZE.out.filter { it[1].toFloat() >= params.prescreen_file_size_check }
        // excluded genomes
        excluded_genomes_based_on_file_size_ch = PRE_SCREEN_FASTQ_FILESIZE.out.filter { it[1].toFloat() < params.prescreen_file_size_check }

        file_size_checks_ch = WRITE_OUT_FILESIZE_CHECK(PRE_SCREEN_FASTQ_FILESIZE.out)
	
	included_sample_id_and_reads_ch = reads_ch
            					.join(included_genomes_based_on_file_size_ch)
           					.map { items -> [items[0], items[1]] }

    	}

	GENOME_SIZE_ESTIMATION(included_sample_id_and_reads_ch)
        
	genome_sizes_ch = GENOME_SIZE_ESTIMATION.out.map { sample_id, path -> find_genome_size(sample_id, path.text) }
	
	// pre-screen check based on genome size
        if (params.prescreen_genome_size_check) {
        excluded_genomes_based_on_size_ch = genome_sizes_ch.filter { it[1] < params.prescreen_genome_size_check }
	
	WRITE_OUT_EXCLUDED_GENOMES(excluded_genomes_based_on_size_ch)
	
	included_genomes_based_on_size_ch = genome_sizes_ch.filter { it[1] >= params.prescreen_genome_size_check }
	
	included_sample_id_and_reads_ch = reads_ch
                				.join(included_genomes_based_on_size_ch)
                				.map { items -> [items[0], items[1]] }

        }
	
	// adapter removal
       	PORECHOP(included_sample_id_and_reads_ch)
	versions_overall_ch = versions_overall_ch.mix(PORECHOP.out.versions_ch)
    	
	// filtering
       	FILTLONG(PORECHOP.out.fastqs_ch)
	versions_overall_ch = versions_overall_ch.mix(FILTLONG.out.versionsfilt_ch)
	
	NANOPLOT(FILTLONG.out.fastqsfilt_ch)
	versions_overall_ch = versions_overall_ch.mix(NANOPLOT.out.versions_ch)

        NANOSTATS_TRANSPOSE(NANOPLOT.out.txt_ch)

        collected_nanostatistics_ch = NANOSTATS_TRANSPOSE.out.nanostats_ch.collect( sort: {a, b -> a[0].getBaseName() <=> b[0].getBaseName()} )

        COMBINE_NANOSTATS(collected_nanostatistics_ch, params.sequencing_date)

	
       	FLYE(FILTLONG.out.fastqsfilt_ch, params.valid_mode) 
	versions_overall_ch = versions_overall_ch.mix(FLYE.out.versions_ch)
    
       	joined_ch = included_sample_id_and_reads_ch.join(FLYE.out.fasta_ch)
    
    	MEDAKA_FIRST_ITERATION(joined_ch)
    
    	joined_final_ch = included_sample_id_and_reads_ch.join(MEDAKA_FIRST_ITERATION.out.first_iteration_ch)
    
    	MEDAKA_SECOND_ITERATION(joined_final_ch)
	versions_overall_ch = versions_overall_ch.mix(MEDAKA_SECOND_ITERATION.out.versions_ch)
	
	QUAST(MEDAKA_SECOND_ITERATION.out.second_iteration_ch)
	 
        collected_quaststatistics_ch = QUAST.out.quast_transposed_report_ch.collect( sort: {a, b -> a[0].getBaseName() <=> b[0].getBaseName()} )

        QUAST_SUMMARY(collected_quaststatistics_ch, params.sequencing_date)
	 
	QUAST_MULTIQC(QUAST.out.quast_dir_ch.collect())
	
    
    emit:
    	flye_out = FLYE.out.fasta_ch
	medaka_out = MEDAKA_SECOND_ITERATION.out.second_iteration_ch
	versions = versions_overall_ch
}



