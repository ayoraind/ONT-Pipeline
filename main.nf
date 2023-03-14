#!/usr/bin/env nextflow


nextflow.enable.dsl=2

/*
========================================================================================
                         TAPIR ONT Pipeline
========================================================================================
*/

// include definitions
include  { helpMessage; Version } from './modules/messages.nf'

// include workflows
include { NANOPORE } from './workflows/nanopore.nf'

workflow {

// Setup input Channel from Read path
        reads_ch = channel
                         .fromPath( params.reads, checkIfExists: true )
                         .map { file -> tuple(file.simpleName, file) }
			 
	NANOPORE(reads_ch)
}


workflow.onComplete {
    println ""
    println "Ran the workflow: ${workflow.scriptName} ${Version}"
    println "Command line    : ${workflow.commandLine}"
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    println "Execution duration: $workflow.duration"
    println "Work directory  : ${workflow.workDir}"
    println "Thank you for using the ONT pipeline!"
}

workflow.onError {
    // Display error message
        println ""
        println "Workflow execution stopped with the following message:"
        println "  " + workflow.errorMessage

}
