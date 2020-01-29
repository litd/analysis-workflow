#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run summary"

baseCommand: ["samtools", "view", "-q", "10", "-b"]
requirements:
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/samtools:1.10--h9402c20_2
    - class: ResourceRequirement
      ramMin: 4000

inputs:
    bam:
        type: File
        secondaryFiles: [.bai]
        inputBinding:
            position: 1
    region:
        type: string
        default: "chr10"
        inputBinding:
            position: 2
    test_bam:
        type: string
        default: "sub_bam.bam"
        inputBinding:
            prefix: "-o"
            position: 3

stdout: "sub_bam.log"

outputs:
    log:
        type: stdout
    sub_bam:
        type: File
        outputBinding:
            glob: "sub_bam.bam"

