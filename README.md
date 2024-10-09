# biomodalQC

Workflow for biomodalQC, QC workflow for biomodal pipeline

## Overview

## Dependencies

* [biomodalqc 1.0.0](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/71_biomodalqc.yaml?ref_type=heads)


## Usage

### Cromwell
```
java -jar cromwell.jar run biomodalQC.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`tag`|String|Tag for the biomodal pipeline run
`run_name`|String|Sequencer run name
`library_name`|String|Sample library name
`lane`|String|Sequencer lane number
`mode`|String|Biomodal pipeline running mode
`subsample`|String|The target number of reads to subsample for the input fastq file
`random_downsample`|Boolean|Specify whether use seqtk to choose random reads, if set to false then choose the top reads in fastq
`group_desc`|String|A text description of what the group ID means
`fastqR1`|File|Fastq file for read 1
`fastqR2`|File|Fastq file for read 2


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`runBiomodalQC.modules`|String|"biomodalqc/1.0.0"|Required environment modules
`runBiomodalQC.jobMemory`|Int|16|Memory allocated for this job (GB)
`runBiomodalQC.threads`|Int|2|Requested CPU threads
`runBiomodalQC.timeout`|Int|48|Hours before task timeout


### Outputs

Output | Type | Description
---|---|---
`dqsreport`|File|{'description': 'Html file of QC metric tables and plots', 'vidarr_label': 'dqsreport'}
`pipelineSummary`|File|{'description': 'csv file of biomodal pipeline summary', 'vidarr_label': 'pipelineSummary'}


## Commands
 This section lists command(s) run by biomodalQC workflow
 
 * Running biomodalQC
 
 ```
             set -euo pipefail
             
             mkdir init_folder
             cp -r $INIT_FOLDER/* ./init_folder/
             cd init_folder
 
             mkdir -p dataset/~{run_name}/gsi-input
             mkdir -p dataset/~{run_name}/nf-input
             meta_file_path="dataset/~{run_name}/meta_file.csv"
             input_path="dataset/~{run_name}/gsi-input/"
             nf_input_path="dataset/~{run_name}/nf-input/"
 
             ln -s ~{fastqR1} ${input_path}
             ln -s ~{fastqR2} ${input_path}
             read1_link="${nf_input_path}~{library_name}_S1_~{lane}_R1_001.fastq.gz"
             read2_link="${nf_input_path}~{library_name}_S1_~{lane}_R2_001.fastq.gz"
             ln -s ~{fastqR1} ${read1_link}
             ln -s ~{fastqR2} ${read2_link}
             
             cat << EOF > ${meta_file_path}
                 sample_id, ~{library_name}
                 description, ~{group_desc}
             EOF
 
             cat << EOF > ./input_config.txt
             tag=~{tag}
             run_name=~{run_name}
             sample_id=~{library_name}
             lane=~{lane}
             mode=~{mode}
             subsample=~{subsample}
             random_downsample=~{random_downsample}
             meta_file=${meta_file_path}
             data_path=${input_path}
             run_directory=~{run_name}
             work_dir="dataset"
             EOF
             
             ./run_biomodal_qc.sh ./input_config.txt
            cp dataset/~{run_name}/nf-result/duet-1.1.2_~{tag}_~{mode}/dqsreport/~{library_name}_dqsummary.html ../
            cp dataset/~{run_name}/nf-result/duet-1.1.2_~{tag}_~{mode}/pipeline_report/~{run_name}_~{mode}_Summary.csv ../
            mv ../~{run_name}_~{mode}_Summary.csv ../~{library_name}_~{mode}_Summary.csv
 ```
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
