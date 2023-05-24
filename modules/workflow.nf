// Include modules


include { PORECHOP; FILTLONG; NANOPLOT; NANOSTATS_TRANSPOSE; COMBINE_NANOSTATS; FLYE; MEDAKA_FIRST_ITERATION; MEDAKA_SECOND_ITERATION; QUAST; QUAST_SUMMARY; QUAST_MULTIQC } from '../modules/processes.nf'

		 
// def workflow

workflow NANOPORE {
    
    take:
    	reads_ch
	     
    main:
    
        versions_overall_ch = channel.empty()
	
       	PORECHOP(reads_ch)
	versions_overall_ch = versions_overall_ch.mix(PORECHOP.out.versions_ch)
    
       	FILTLONG(PORECHOP.out.fastqs_ch)
	versions_overall_ch = versions_overall_ch.mix(FILTLONG.out.versionsfilt_ch)
	
	NANOPLOT(FILTLONG.out.fastqsfilt_ch)
	versions_overall_ch = versions_overall_ch.mix(NANOPLOT.out.versions_ch)

        NANOSTATS_TRANSPOSE(NANOPLOT.out.txt_ch)

        collected_nanostatistics_ch = NANOSTATS_TRANSPOSE.out.nanostats_ch.collect( sort: {a, b -> a[0].getBaseName() <=> b[0].getBaseName()} )

        COMBINE_NANOSTATS(collected_nanostatistics_ch, params.sequencing_date)
    
       	FLYE(FILTLONG.out.fastqsfilt_ch, params.valid_mode) 
	versions_overall_ch = versions_overall_ch.mix(FLYE.out.versions_ch)
    
       	joined_ch = FILTLONG.out.fastqsfilt_ch.join(FLYE.out.fasta_ch)
    
    	MEDAKA_FIRST_ITERATION(joined_ch)
    
    	joined_final_ch = FILTLONG.out.fastqsfilt_ch.join(MEDAKA_FIRST_ITERATION.out.first_iteration_ch)
    
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



