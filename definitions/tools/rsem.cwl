#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run rsem v1.3.0"

baseCommand: ["/usr/local/bin/rsem-calculate-expression"]
requirements:
    - class: InlineJavascriptRequirement
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/rsem:1.3.0--pl526r341h4f16992_4
    - class: ResourceRequirement
      ramMin: 16000
      coresMin: 4

arguments:
    ["--num-threads", {valueFrom: "$(runtime.cores)"}]

inputs:
    paired_end:
        type: boolean
        default: true
        inputBinding:
            prefix: "--paired-end"
            position: 1
    bam:
        type: File
        inputBinding:
            prefix: "--bam"
            position: 2
    reference:
        type: string
        inputBinding:
            position: 3
    output:
        type: string
        default: "rsem"
        inputBinding:
            position: 4

stdout: "rsem.log"
#stdout: "$(inputs.fastq1.nameroot).cutadapt.log"

outputs:
    genes_file:
        type: File
        outputBinding:
            glob: "rsem.genes.results"
    isoforms_file:
        type: File
        outputBinding:
            glob: "rsem.isoforms.results"
    transcript_file:
        type: File
        outputBinding:
            glob: "rsem.transcript.bam"
    stat:
        type: Directory
        outputBinding:
            glob: "rsem.stat"
    log:
        type: stdout

