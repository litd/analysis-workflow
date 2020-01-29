#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run STAR v2.5.4"

baseCommand: ["STAR"]
requirements:
    - class: InlineJavascriptRequirement
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/star:2.5.4a--0
    - class: ResourceRequirement
      ramMin: 64000
      coresMin: 6

arguments:
    ["--runThreadN", {valueFrom: "$(runtime.cores)"}, "--outFileNamePrefix", {valueFrom: "$(inputs.fastq1.nameroot)"}, "--readFilesCommand", "zcat" ]

inputs:
    genomeDir:
        type: Directory
        inputBinding:
            prefix: "--genomeDir"
            position: 1
    fastq1:
        type: File
        inputBinding:
            prefix: "--readFilesIn"
            position: 2
    fastq2:
        type: File?
        inputBinding:
            prefix: ""
            position: 3
    quantMode:
        type: string
        default: "TranscriptomeSAM"
        inputBinding:
            prefix: "--quantMode"
            position: 4
    outWigType:
        type: string
        default: "bedGraph"
        inputBinding:
            prefix: "--outWigType"
            position: 5
    outWigNorm:
        type: string
        default: "RPM"
        inputBinding:
            prefix: "--outWigNorm"
            position: 6
    outSAMtype:
        type: string
        default: "BAM"
        inputBinding:
            prefix: "--outSAMtype"
            position: 7
    outSAMtype2:
        type: string
        default: "SortedByCoordinate"
        inputBinding:
            prefix: ""
            position: 8
    outWigStrand:
        type: string
        default: "Stranded"
        inputBinding:
            prefix: "--outWigStrand"
            position: 9

stdout: "star.log"
#stdout: "$(inputs.fastq1.nameroot).cutadapt.log"

outputs:
    aligned_bam:
        type: File
        outputBinding:
            glob: "*Aligned.sortedByCoord.out.bam"
    transcriptome_bam:
        type: File
        outputBinding:
            glob: "*Aligned.toTranscriptome.out.bam"
    str1:
        type: File
        outputBinding:
            glob: "*Signal.Unique.str1.out.bg"
    str2:
        type: File
        outputBinding:
            glob: "*Signal.Unique.str2.out.bg"
    final:
        type: File
        outputBinding:
            glob: "*Log.final.out"
    log:
        type: stdout

