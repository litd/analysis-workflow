#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run subread v1.6.4"

baseCommand: ["/bin/bash", "fc.sh"]
requirements:
    - class: DockerRequirement
      dockerPull: quay.io/biocontainers/subread:1.6.4--h84994c4_1
    - class: ResourceRequirement
      ramMin: 16000
      coresMin: 4
    - class: StepInputExpressionRequirement
    - class: InitialWorkDirRequirement
      listing:
      - entryname: 'fc.sh'
        entry: |
            set -eou pipefail
            set -o errexit

            annotation_file="$1"
            feature="$2"
            attribute="$3"
            attribute2="$4"
            mapping_quality="$5"
            paired_end="$6"
            strand="$7"
            bam="$8"
            sub_bam="$9"

            if [[ "$paired_end" == "true" ]]; then
                for i in 0 1 2; do
                    /usr/local/bin/featureCounts -p -T 4 -Q "$mapping_quality" -s "$i" -g "$attribute" -t "$feature" -a "$annotation_file" -o "$sub_bam"_s"$i"_fc "$sub_bam"
                done
            else
                for i in 0 1 2; do
                    /usr/local/bin/featureCounts -T 4 -Q "$mapping_quality" -s "$i" -g "$attribute" -t "$feature" -a "$annotation_file" -o "$sub_bam"_s"$i"_fc "$sub_bam"
                done
            fi

            s0_hit=`grep Assigned "$sub_bam"_s0_fc.summary | awk '{print $2}'`
            s1_hit=`grep Assigned "$sub_bam"_s1_fc.summary | awk '{print $2}'`
            s2_hit=`grep Assigned "$sub_bam"_s2_fc.summary | awk '{print $2}'`
            echo -e "for chr10 subsample, the strand hits of featureCounts are: \ns0: $s0_hit\ns1: $s1_hit\ns2: $s2_hit"

            [[ $s0_hit -gt $s1_hit ]] && [[ $s0_hit -gt $s2_hit ]] && strand=0
            [[ $s1_hit -gt $s0_hit ]] && [[ $s1_hit -gt $s2_hit ]] && strand=1
            [[ $s2_hit -gt $s0_hit ]] && [[ $s2_hit -gt $s1_hit ]] && strand=2
            echo "the strand choice for featureCounts is $strand"

            if [[ "$paired_end" == "true" ]]; then
                    /usr/local/bin/featureCounts -p -T 4 -Q "$mapping_quality" -s "$strand" -g "$attribute" -t "$feature" -a "$annotation_file" -o "$bam"_gene_name_fc "$bam"
                    /usr/local/bin/featureCounts -p -T 4 -Q "$mapping_quality" -s "$strand" -g "$attribute2" -t "$feature" -a "$annotation_file" -o "$bam"_gene_type_fc "$bam"
            else
                    /usr/local/bin/featureCounts -T 4 -Q "$mapping_quality" -s "$strand" -g "$attribute" -t "$feature" -a "$annotation_file" -o "$bam"_gene_name_fc "$bam"
                    /usr/local/bin/featureCounts -T 4 -Q "$mapping_quality" -s "$strand" -g "$attribute2" -t "$feature" -a "$annotation_file" -o "$bam"_gene_type_fc "$bam"
            fi
      - $(inputs.bam)
      - $(inputs.bam.secondaryFiles)

inputs:
    annotation_file:
        type: File
        inputBinding:
            position: 1
    feature:
        type: string
        default: "exon"
        inputBinding:
            position: 2
    attribute:
        type: string
        default: "gene_name"
        inputBinding:
            position: 3
    attribute2:
        type: string
        default: "gene_type"
        inputBinding:
            position: 4
    mapping_quality:
        type: int
        default: 10
        inputBinding:
            position: 5
    paired_end:
        type: boolean
        default: true
        inputBinding:
            position: 6
            valueFrom: |
                ${ if (inputs.paired_end) {
                        return "true";
                    } else {
                        return "false";
                    }
                }
    strand:
        type: int
        default: 0
        inputBinding:
            position: 7
    bam:
        type: File
        inputBinding:
            position: 8
            valueFrom: $(self.basename)
    sub_bam:
        type: File
        inputBinding:
            position: 9

stdout: "feature_counts.log"
#stdout: "$(inputs.fastq1.nameroot).cutadapt.log"

outputs:
    log:
        type: stdout
    gene_name_fc:
        type: File
        outputBinding:
            glob: "*gene_name_fc"
    gene_name_fc_summary:
        type: File
        outputBinding:
            glob: "*gene_name_fc.summary"
    gene_type_fc:
        type: File
        outputBinding:
            glob: "*gene_type_fc"
    gene_type_fc_summary:
        type: File
        outputBinding:
            glob: "*gene_type_fc.summary"
