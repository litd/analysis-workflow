#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run fastqc v0.11.8"

baseCommand: ["fastqc"]
requirements:
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/fastqc:0.11.8--2
    - class: ResourceRequirement
      ramMin: 4000
      coresMin: 4

arguments:
    ["--threads", {valueFrom: "$(runtime.cores)"}, "--extract", "--outdir", {valueFrom: "$(runtime.outdir)"}]

inputs:
    fastq1:
        type: File
        inputBinding:
            position: 1
    fastq2:
        type: File?
        inputBinding:
            position: 2

stdout: "fastqc.log"
#stdout: "$(inputs.fastq1.nameroot).cutadapt.log"

outputs:
    zippedfile:
        type:
            type: array
            items: File
        outputBinding:
            glob: "*_fastqc.zip"
    htmlfile:
        type:
            type: array
            items: File
        outputBinding:
            glob: "*_fastqc.html"
#    summary:
#        type:
#            type: array
#            items: File
#        outputBinding:
#            glob: |
#               ${ return "*/summary.txt" }
#    fastqc_data:
#        type:
#            type: array
#            items: File
#        outputBinding:
#            glob: |
#               ${ return "*/fastqc_data.txt" }
    log:
        type: stdout

