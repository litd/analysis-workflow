#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "run summary"

baseCommand: ["/bin/bash", "summary.sh"]
requirements:
    - class: DockerRequirement
      dockerPull: litd/dana@sha256:e0228fbe059abee53ae41ed96e4d1a3b592e71249f14d407820a9051982b1cab
    - class: ResourceRequirement
      ramMin: 16000
      coresMin: 1
    - class: StepInputExpressionRequirement
    - class: InitialWorkDirRequirement
      listing:
      - entryname: 'summary.sh'
        entry: |
            set -eou pipefail
            set -o errexit

            infile="$1"
            str1="$2"
            str2="$3"
            final="$4"
            dup_metrics="$5"
            genebody_r="$6"

            gene_name_fc="$7"
            gene_name_fc_summary="$8"
            gene_type_fc="$9"
            gene_type_fc_summary="$10"

            # cutadapt
            raw_reads=`grep "Total read" "$infile" | awk '{print $NF}' | sed 's/,//g'`
            written_reads=`grep "Pairs written\|Reads written" "$infile" | awk '{print $5}' | sed 's/,//g'`
            echo -e "raw_reads\twritten_reads\n$raw_reads\t$written_reads" > cutadapt_summary.txt

            # star
            awk '{print $1"\t"$2"\t"$3"\t-"$4}' "$str1" | cat - "$str2" > Star_Unique.stranded.bg
            /opt/conda/bin/bedSort Star_Unique.stranded.bg Star_Unique.stranded.bg
            /opt/conda/bin/bgzip Star_Unique.stranded.bg
            /opt/conda/bin/tabix -p bed Star_Unique.stranded.bg.gz

            input_reads=`grep "Number of input reads" "$final" | awk '{print $NF}'`
            exact_1_time_num=`grep "Uniquely mapped reads number" "$final" | awk '{print $NF}'`
            gt_1_time_num=`grep "Number of reads mapped to" "$final" | awk '{print $NF}' | awk '{s+=$1}END{print s}'`
            chimeric_num=`grep "Number of chimeric reads" "$final" | awk '{print $NF}'`
            align_0_time_num=`awk "BEGIN {print $input_reads-$chimeric_num-$exact_1_time_num-$gt_1_time_num}"`
            uniq_ratio=`awk "BEGIN {print $exact_1_time_num/$written_reads}"`
            average_length=`grep "Average input read length" "$final" | awk '{print $NF}'`
            grep "Number of splices" "$final" | sed 's/[[:space:]]//g;s/|/\t/' > Star_Splice.txt

            # mark duplicate
            after_dup=`grep PERCENT_DUPLICATION "$dup_metrics" -A 2 | cut -f9 | sed -n '2p'`

            # gene body coverage
            auc=`head -1 "$genebody_r" | awk -F "[(]" '{print $2}' | sed 's/)//' | awk -F "[,]" '{for(i=1;i<=NF;i++) t+=$i; print t}'`

            # featurecounts
            echo -e "gene_name\tlength\tfragment_count" > gene_name_count.txt
            tail -n +3 "$gene_name_fc" | awk -F "\t" '{print $1"\t"$6"\t"$7}' | sort -k3,3rn >> gene_name_count.txt
            echo -e "gene_type\tlength\tfragment_count" > gene_type_count.txt
            tail -n +3 "$gene_type_fc" | awk -F "\t" '{print $1"\t"$6"\t"$7}' | sort -k3,3rn >> gene_type_count.txt

            # ratio of reads with feature
            total_cc=`awk '{s+=$2}END{print s}' "$gene_name_fc_summary"`
            reads_with_feature=`grep Assigned "$gene_name_fc_summary" | awk '{print $2}'`
            rates_with_feature=`awk "BEGIN {print $reads_with_feature/$exact_1_time_num}"`

            # captured genes
            total_count=`awk '{s+=$3}END{print s}' gene_name_count.txt`
            thres=`awk "BEGIN {print $total_count/1000000}"`
            exp_gene_num=`sed 1d gene_name_count.txt | awk -v thres=$thres '$3>thres' | wc -l`
            all_gene_num=`sed 1d gene_name_count.txt | awk '$3>0' | wc -l`
            sed 1d gene_name_count.txt | awk -v total_count=$total_count '{print $0"\t"$3*1000000/total_count}' | cat <(echo -e "gene_name\tlength\tfragment_count\tCPM") - > temp.txt && mv temp.txt gene_name_count.txt
            grep -f <(echo -e "^rRNA\n^Mt\n^ribo") gene_type_count.txt | cut -f 1,3 > rna_type.txt
            # summarize together
            echo -e "raw_reads\twritten_reads\taverage_input_read_length\tafter_alignment_dup\talign_0_time\texactly_1_time\tuniq_ratio\tgt_1_time\tauc_genebody\tassigned_reads_number\treads_ratio_with_gene_feature\tall_gene_num\tgenes_CPM_gt_1" > QC_summary.txt
            echo -e "$raw_reads\t$written_reads\t$average_length\t$after_dup\t$align_0_time_num\t$exact_1_time_num\t$uniq_ratio\t$gt_1_time_num\t$auc\t$reads_with_feature\t$rates_with_feature\t$all_gene_num\t$exp_gene_num" >> QC_summary.txt

            # saturation analysis
            cut -f1,3 gene_name_count.txt | sed 1d | awk '$2>0' | while read i j; do for ((index=0;index<$j;index++)); do echo $i; done; done > fc_subsample.txt
            all_fc=`wc -l fc_subsample.txt | awk '{print $1}'`
            cut -f1,3 gene_name_count.txt | sed 1d | awk '$2>0' | awk -v sum_count=$all_fc '{print $1,$2*1000000/sum_count}' OFS="\t" | sort > raw_CPM.txt

            cat fc_subsample.txt | sort | uniq -c | awk -v sample_ratio=$all_fc '{print $2,$1*1000000/sample_ratio}' OFS="\t" | awk '$2>=1' > raw_CPM.txt2
            lt10=`awk '$2<10' raw_CPM.txt2 | wc -l`
            bt50=`awk '$2>=10 && $2<50' raw_CPM.txt2 | wc -l`
            gt50=`awk '$2>=50' raw_CPM.txt2 | wc -l`
            all_gene=`cat raw_CPM.txt2 | wc -l`

            # subsampling
            for number in 10 20 30 40 50 60 70 80 90
            do
                sample_ratio=`wc -l fc_subsample.txt | awk -v number=$number '{print $1*number/100}'`
                echo "$sample_ratio out of total $all_fc"
            done
#                shuf fc_subsample.txt | head -$sample_ratio | sort | uniq -c | awk -v sample_ratio=$sample_ratio '{print $2,$1*1000000/sample_ratio}' OFS="\t" > b.txt && \
#                join -a 1 -j 1 raw_CPM.txt2 b.txt | awk 'sqrt(($2-$3)^2)/$2>0.1' > c.txt
#                shuf fc_subsample.txt | head -$sample_ratio | sort | uniq -c | awk -v sample_ratio=$sample_ratio '{print $2,$1*1000000/sample_ratio}' OFS="\t" | sort -k1,1 | join -j 1 <(sort -k1,1 raw_CPM.txt2) - | awk 'sqrt(($2-$3)^2)/$2>0.1' > c.txt
#                echo -e "`awk '$2<10' c.txt | wc -l`\t`awk '$2>=10 && $2<50' c.txt | wc -l`\t`awk '$2>=50' c.txt | wc -l`\t`cat c.txt | wc -l`" >> step4.3_CPM_saturation.txt
 
#            awk -v lt10=$lt10 -v bt50=$bt50 -v gt50=$gt50 -v all_gene=$all_gene '{print lt10-$1, bt50-$2, gt50-$3, all_gene-$4 }' OFS="\t" step4.3_CPM_saturation.txt > temp.txt
#            echo -e "$lt10\t$bt50\t$gt50\t$all_gene" >> temp.txt #step4.3_CPM_saturation.txt
#            paste <(seq 10 10 100) temp.txt | cat <(echo -e "percent\tlt10\tbt50\tgt50\ttotal") - > step4.3_CPM_saturation.txt2

#      - $(inputs.bam)
#      - $(inputs.bam.secondaryFiles)

inputs:
    infile:
        type: File
        inputBinding:
            position: 1
    str1:
        type: File
        inputBinding:
            position: 2
    str2:
        type: File
        inputBinding:
            position: 3
    final:
        type: File
        inputBinding:
            position: 4
    dup_metrics:
        type: File
        inputBinding:
            position: 5
    genebody_r:
        type: File
        inputBinding:
            position: 6
    gene_name_fc:
        type: File
        inputBinding:
            position: 7
    gene_name_fc_summary:
        type: File
        inputBinding:
            position: 8
    gene_type_fc:
        type: File
        inputBinding:
            position: 9
    gene_type_fc_summary:
        type: File
        inputBinding:
            position: 10

stdout: "summary.log"

outputs:
    summary_log:
        type: stdout
    cutadapt_summary:
        type: File
        outputBinding:
            glob: "cutadapt_summary.txt"
    unique_stranded:
        type: File
        outputBinding:
            glob: "Star_Unique.stranded.bg.gz"
    splice:
        type: File
        outputBinding:
            glob: "Star_Splice.txt"
    gene_name_count:
        type: File
        outputBinding:
            glob: "gene_name_count.txt"
    gene_type_count:
        type: File
        outputBinding:
            glob: "gene_type_count.txt"
    rna_type:
        type: File
        outputBinding:
            glob: "rna_type.txt"
    qc_summary:
        type: File
        outputBinding:
            glob: "QC_summary.txt"

