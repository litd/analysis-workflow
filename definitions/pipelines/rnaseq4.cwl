#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "RNA-Seq alignment with qc"
requirements:
    - class: SchemaDefRequirement
      types:
          - $import: ../types/labelled_file.yml
          - $import: ../types/sequence_data.yml
inputs:
    fastq1:
        type: File
    fastq2:
        type: File?
    genomeDir:
        type: Directory
    input_sort_order:
        type: string
    paired_end:
        type: boolean
    refgene:
        type: File
    annotation_file:
        type: File
    rsem_reference:
        type: string

outputs:
    zippedfile:
        type:
            type: array
            items: File
        outputSource: fastqc/zippedfile
    htmlfile:
        type:
            type: array
            items: File
        outputSource: fastqc/htmlfile
    summary:
        type:
            type: array
            items: File
        outputSource: fastqc/summary
    fastqc_data:
        type:
            type: array
            items: File
        outputSource: fastqc/fastqc_data
    transcriptome_bam:
        type: File
        outputSource: star/transcriptome_bam
    final_bam:
        type: File
        outputSource: index_bam/indexed_bam
    preseq_result:
        type: File
        outputSource: preseq/preseq_result
    genes_file:
        type: File
        outputSource: rsem/genes_file
    isoforms_file:
        type: File
        outputSource: rsem/isoforms_file
    transcript_file:
        type: File
        outputSource: rsem/transcript_file
    cutadapt_summary:
        type: File
        outputSource: rnaseq_summary/cutadapt_summary
    unique_stranded:
        type: File
        outputSource: rnaseq_summary/unique_stranded

steps:
    cutadapt:
        run: ../tools/cutadapt.cwl
        in: 
            fastq1: fastq1
            fastq2: fastq2
        out: [cutadapt_log,trimmed_fastq1,trimmed_fastq2]
    fastqc:
        run: ../tools/fastqc.cwl
        in: 
            fastq1: cutadapt/trimmed_fastq1
            fastq2: cutadapt/trimmed_fastq2
        out: [zippedfile,htmlfile,summary,fastqc_data,log]
    star:
        run: ../tools/star.cwl
        in: 
            genomeDir: genomeDir
            fastq1: cutadapt/trimmed_fastq1
            fastq2: cutadapt/trimmed_fastq2
        out: [aligned_bam,transcriptome_bam,str1,str2,final,log]
    mark_dup:
        run: ../tools/mark_duplicates_and_sort.cwl
        in: 
            bam: star/aligned_bam
            input_sort_order: input_sort_order
        out: [sorted_bam,metrics_file]
    index_bam:
        run: ../tools/index_bam.cwl
        in:
            bam: mark_dup/sorted_bam
        out:
            [indexed_bam]
    preseq:
        run: ../tools/preseq.cwl
        in: 
            bam: index_bam/indexed_bam
        out: [preseq_result,log]
    rseqc:
        run: ../tools/rseqc.cwl
        in: 
            bam: index_bam/indexed_bam
            refgene: refgene
        out: [genebody_log,log]
    sub_bam:
        run: ../tools/sub_bam.cwl
        in:
            bam: index_bam/indexed_bam
        out: [sub_bam,log]
    fc:
        run: ../tools/subread_featurecounts.cwl
        in: 
            bam: index_bam/indexed_bam
            annotation_file: annotation_file
            paired_end: paired_end
            sub_bam: sub_bam/sub_bam
        out: [gene_name_fc,gene_name_fc_summary,gene_type_fc,gene_type_fc_summary,log]
    rsem:
        run: ../tools/rsem.cwl
        in: 
            bam: star/transcriptome_bam
            reference: rsem_reference
            paired_end: paired_end
        out: [genes_file,isoforms_file,transcript_file,stat,log]
    rnaseq_summary:
        run: ../tools/rnaseqv4_summary.cwl
        in: 
            infile: cutadapt/cutadapt_log
            str1: star/str1
            str2: star/str2
            final: star/final
            dup_metrics: mark_dup/metrics_file
            genebody_log: rseqc/genebody_log
            gene_name_fc: fc/gene_name_fc
            gene_name_fc_summary: fc/gene_name_fc_summary
            gene_type_fc: fc/gene_type_fc
            gene_type_fc_summary: fc/gene_type_fc_summary
        out: [cutadapt_summary,unique_stranded,splice,gene_name_count,gene_type_count,qc_summary,summary_log]


