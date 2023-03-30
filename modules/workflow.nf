// Include modules


include { PORECHOP; FILTLONG; FLYE; MEDAKA_FIRST_ITERATION; MEDAKA_SECOND_ITERATION } from '../modules/processes.nf'

		 
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
    
       	FLYE(FILTLONG.out.fastqsfilt_ch, params.valid_mode) 
	versions_overall_ch = versions_overall_ch.mix(FLYE.out.versions_ch)
    
       	joined_ch = FILTLONG.out.fastqsfilt_ch.join(FLYE.out.fasta_ch)
    
    	MEDAKA_FIRST_ITERATION(joined_ch)
    
    	joined_final_ch = FILTLONG.out.fastqsfilt_ch.join(MEDAKA_FIRST_ITERATION.out.first_iteration_ch)
    
    	MEDAKA_SECOND_ITERATION(joined_final_ch)
	versions_overall_ch = versions_overall_ch.mix(MEDAKA_SECOND_ITERATION.out.versions_ch)
	
    
    emit:
    	flye_out = FLYE.out.fasta_ch
	medaka_out = MEDAKA_SECOND_ITERATION.out.second_iteration_ch
	versions = versions_overall_ch
}



