#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run RSeQC v3.0.1"

baseCommand: ["/bin/bash", "rseqc.sh"]
requirements:
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/rseqc:3.0.1--py37h516909a_1
    - class: ResourceRequirement
      ramMin: 16000
      coresMin: 4
    - class: StepInputExpressionRequirement
    - class: InitialWorkDirRequirement
      listing:
      - entryname: 'rseqc.sh'
        entry: |
            set -eou pipefail
            set -o errexit

            bam="$1"
            refgene="$2"

            /usr/local/bin/geneBody_coverage.py -i "$bam" -r "$refgene" -o "$bam"
            /usr/local/bin/RNA_fragment_size.py -i "$bam" -r "$refgene" > "$bam".frag_size
            /usr/local/bin/inner_distance.py -i "$bam" -r "$refgene" -o "$bam"
            /usr/local/bin/junction_annotation.py -i "$bam" -r "$refgene" -o "$bam"
            /usr/local/bin/read_GC.py -i "$bam" -o "$bam"
            /usr/local/bin/read_distribution.py -i "$bam" -r "$refgene" > "$bam".read_distribution.txt
            /usr/local/bin/infer_experiment.py -i "$bam" -r "$refgene" > "$bam".strand.txt
            for i in annotated complete_novel partial_novel; do echo $i; /bin/grep -w $i "$bam".junction.xls | wc -l || true; /bin/grep -w $i "$bam".junction.xls | cut -f4 | awk 'BEGIN{sum=0}{sum += $1} END {print sum}' || true; done | xargs -n 3 | sed 's/ /\t/g' > "$bam".junction.txt
      - $(inputs.bam)
      - $(inputs.bam.secondaryFiles)

inputs:
    bam:
        type: File
        inputBinding:
            position: 1
            valueFrom: $(self.basename)
    refgene:
        type: File
        inputBinding:
            position: 2

stdout: "rseqc.log"

outputs:
    genebody_r:
        type: File
        outputBinding:
            glob: "*geneBodyCoverage.r"
    genebody_text:
        type: File
        outputBinding:
            glob: "*geneBodyCoverage.txt"
    genebody_pdf:
        type: File
        outputBinding:
            glob: "*geneBodyCoverage.curves.pdf"
    frag_size:
        type: File
        outputBinding:
            glob: "*frag_size"
    inner_distance_text:
        type: File
        outputBinding:
            glob: "*inner_distance.txt"
    inner_distance_freq:
        type: File
        outputBinding:
            glob: "*inner_distance_freq.txt"
    inner_distance_pdf:
        type: File
        outputBinding:
            glob: "*inner_distance_plot.pdf"
    inner_distance_r:
        type: File
        outputBinding:
            glob: "*inner_distance_plot.r"
    junction_interact:
        type: File
        outputBinding:
            glob: "*junction.Interact.bed"
    junction_bed:
        type: File
        outputBinding:
            glob: "*junction.bed"
    junction_text:
        type: File
        outputBinding:
            glob: "*junction.txt"
    junction_xls:
        type: File
        outputBinding:
            glob: "*junction.xls"
    junction_r:
        type: File
        outputBinding:
            glob: "*junction_plot.r"
    gc_xls:
        type: File
        outputBinding:
            glob: "*GC.xls"
    gc_pdf:
        type: File
        outputBinding:
            glob: "*GC_plot.pdf"
    gc_r:
        type: File
        outputBinding:
            glob: "*GC_plot.r"
    read_distribution:
        type: File
        outputBinding:
            glob: "*read_distribution.txt"
    infer_strand:
        type: File
        outputBinding:
            glob: "*strand.txt"
    splice_events:
        type: File
        outputBinding:
            glob: "*splice_events.pdf"
    splice_junction:
        type: File
        outputBinding:
            glob: "*splice_junction.pdf"
    log:
        type: stdout
