#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run cutadapt v2.6"

baseCommand: ["cutadapt"]
requirements:
    - class: InlineJavascriptRequirement
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/cutadapt:2.6--py36h516909a_0
    - class: ResourceRequirement
      ramMin: 4000
      coresMin: 4

arguments:
    ["--cores", {valueFrom: "$(runtime.cores)"}, "--no-trim"]

inputs:
    fastq1:
        type: File
        inputBinding:
            position: 7
    fastq2:
        type: File?
        inputBinding:
            position: 8
    adapter:
        type: string
        default: "AGATCGGAAGAGCACACGTCTGAAC"
        inputBinding:
            prefix: "-a"
            position: 1
    adapter2:
        type: string
        default: "AGATCGGAAGAGCGTCGTGTAGGGA"
        inputBinding:
            prefix: "-A"
            position: 2
            valueFrom: |
                ${ if (inputs.fastq2) {
                        return self;
                    } else {
                        return null;
                    }
                }
    quality_cutoff:
        type: string
        default: "15,10"
        inputBinding:
            prefix: "--quality-cutoff"
            position: 3
    minimum_length:
        type: int
        default: 36
        inputBinding:
            prefix: "--minimum-length"
            position: 4
    trim1:
        type: string
        default: "cutadapt_R1.fastq.gz"
        #default: "$(inputs.fastq1).cutadapt.fastq"
        inputBinding:
            prefix: "-o"
            position: 5
    trim2:
        type: string?
        default: "cutadapt_R2.fastq.gz"
        #default: "$(inputs.fastq2.nameroot).cutadapt.fastq"
        inputBinding:
            prefix: "-p"
            position: 6
            valueFrom: |
                ${ if (inputs.fastq2) {
                        return self;
                    } else {
                        return null;
                    }
                }


stdout: "cutadapt.log"
#stdout: "$(inputs.fastq1.nameroot).cutadapt.log"

outputs:
    cutadapt_log:
        type: stdout
    trimmed_fastq1:
        type: File
        outputBinding:
            glob: $(inputs.trim1)
    trimmed_fastq2:
        type: File?
        outputBinding:
            glob: $(inputs.trim2)

