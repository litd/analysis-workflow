#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run preseq v2.0.3"

baseCommand: ["preseq"]
requirements:
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/preseq:2.0.3--hf53bd2b_3
    - class: ResourceRequirement
      ramMin: 16000
      coresMin: 4

arguments:
    ["lc_extrap", "-v", "-seg_len", "9000000000"]

inputs:
    terms:
        type: int
        default: 100
        inputBinding:
            prefix: "-terms"
            position: 1
    paired_end:
        type: boolean
        default: true
        inputBinding:
            prefix: "-pe"
            position: 2
    bam:
        type: File
        doc: "Coordinate sorted BAM file"
        inputBinding:
            prefix: "-bam"
            position: 3
    output:
        type: string
        default: "preseq_result.txt"
        inputBinding:
            prefix: "-output"
            position: 4
#    vals:
#        type: string?
#        default: "counts.txt"
#        inputBinding:
#            prefix: "-vals"
#            position: 4

stdout: "preseq.log"
#stdout: "$(inputs.fastq1.nameroot).cutadapt.log"

outputs:
    log:
        type: stdout
    preseq_result:
        type: File
        outputBinding:
            glob: $(inputs.output)
