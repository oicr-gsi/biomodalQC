version 1.0


workflow biomodalQC {
    input {
        String tag
        String run_name
        String library_name
        String lane
        String mode
        String subsample
        Boolean random_downsample
        String group_desc
        Array[File] fastqR1
        Array[File] fastqR2
    }
    parameter_meta {
        tag: "Tag for the biomodal pipeline run"
        run_name: "Sequencer run name"
        library_name: "Sample library name"
        lane: "Sequencer lane number"
        mode: "Biomodal pipeline running mode"
        subsample: "The target number of reads to subsample for the input fastq file"
        random_downsample: "Specify whether use seqtk to choose random reads, if set to false then choose the top reads in fastq"
        group_desc: "A text description of what the group ID means"
        fastqR1: "Fastq file for read 1"
        fastqR2: "Fastq file for read 2"
    }

    if (length(fastqR1) > 1) {
        call mergeFastqs {
        input:
            fastqR1 = fastqR1,
            fastqR2 = fastqR2,
            out_prefix = library_name + "_" + lane +"_" + run_name
        }
    }
    File R1_merged = select_first([mergeFastqs.merged_R1, fastqR1[0]])
    File R2_merged = select_first([mergeFastqs.merged_R2, fastqR2[0]])

    call runBiomodalQC {
        input:
        tag = tag,
        run_name = run_name,
        sample_id = sub(library_name, "_", "-"),
        lane = lane,
        mode = mode,
        subsample = subsample,
        random_downsample = random_downsample,
        group_desc = group_desc,
        fastqR1 = R1_merged,
        fastqR2 = R2_merged
    }

    meta {
            author: "Gavin Peng"
            email: "gpeng@oicr.on.ca"
            description: "Workflow for biomodalQC, QC workflow for biomodal pipeline"
                dependencies: [
                    {
                    name: "biomodalqc/1.0.0",
                    url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/71_biomodalqc.yaml?ref_type=heads"
                    }
                ]
            output_meta: {
                dqsreport: {
                    description: "Html file of QC metric tables and plots",
                    vidarr_label: "dqsreport"
                },
                pipelineSummary: {
                    description: "csv file of biomodal pipeline summary",
                    vidarr_label: "pipelineSummary"
                }
            }
    }

    output {
        File dqsreport = runBiomodalQC.dqsreport
        File pipelineSummary = runBiomodalQC.pipelineSummary
    }
}

task mergeFastqs {
  input {
    Array[File] fastqR1
    Array[File] fastqR2
    String out_prefix
    Int jobMemory = 32
    Int threads = 1
    Int timeout = 8
  }
  parameter_meta {
    jobMemory: "Memory allocated for this job (GB)"
    threads: "Requested CPU threads"
    timeout: "Hours before task timeout"
  }

  command <<<
    sorted_R1=($(for fastq in ~{sep=' ' fastqR1}; do echo "$fastq"; done | sort))
    sorted_R2=($(for fastq in ~{sep=' ' fastqR2}; do echo "$fastq"; done | sort))
    cat "${sorted_R1[@]}" > ~{out_prefix}_R1.fastq.gz
    cat "${sorted_R2[@]}" > ~{out_prefix}_R2.fastq.gz
  >>>

  output {
    File merged_R1 = "~{out_prefix}_R1.fastq.gz"
    File merged_R2 = "~{out_prefix}_R2.fastq.gz"
  }

  runtime {
    memory:  "~{jobMemory} GB"
    cpu:     "~{threads}"
    timeout: "~{timeout}"
  }
}

task runBiomodalQC{
        input {
            String tag
            String run_name
            String sample_id
            String lane
            String mode = "6bp"
            String subsample = 2000000
            Boolean random_downsample = true
            String group_desc
            File fastqR1
            File fastqR2
            String modules = "biomodalqc/1.0.0"
            Int jobMemory = 16
            Int threads = 2
            Int timeout = 48
            }
        parameter_meta {
            tag: "Tag for the biomodal pipeline run"
            run_name: "Sequencer run name"
            sample_id: "Sample library name"
            lane: "Sequencer lane number"
            mode: "Biomodal pipeline running mode"
            subsample: "The target number of reads to subsample for the input fastq file"
            random_downsample: "Specify whether use seqtk to choose random reads, if set to false then choose the top reads in fastq"
            group_desc: "A text description of what the group ID means"
            fastqR1: "Fastq file for read 1"
            fastqR2: "Fastq file for read 2"
            modules: "Required environment modules"
            jobMemory: "Memory allocated for this job (GB)"
            threads: "Requested CPU threads"
            timeout: "Hours before task timeout"
        }
        
        command <<<
            set -euo pipefail
            
            mkdir init_folder
            ln -s $INIT_FOLDER/* ./init_folder
            cd init_folder

            mkdir -p dataset/~{run_name}/gsi-input
            mkdir -p dataset/~{run_name}/nf-input
            meta_file_path="dataset/~{run_name}/meta_file.csv"
            input_path="dataset/~{run_name}/gsi-input/"
            nf_input_path="dataset/~{run_name}/nf-input/"

            ln -s ~{fastqR1} ${input_path}
            ln -s ~{fastqR2} ${input_path}
            read1_link="${nf_input_path}~{sample_id}_S1_~{lane}_R1_001.fastq.gz"
            read2_link="${nf_input_path}~{sample_id}_S1_~{lane}_R2_001.fastq.gz"
            ln -s ~{fastqR1} ${read1_link}
            ln -s ~{fastqR2} ${read2_link}
            
            cat << EOF > ${meta_file_path}
                sample_id, ~{sample_id}
                description, ~{group_desc}
            EOF

            
            cat << EOF > ./input_config.txt
            tag=~{tag}
            run_name=~{run_name}
            sample_id=~{sample_id}
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
            cp dataset/~{run_name}/nf-result/duet-1.1.2_~{tag}_~{mode}/dqsreport/~{sample_id}_dqsummary.html ../
            cp dataset/~{run_name}/nf-result/duet-1.1.2_~{tag}_~{mode}/pipeline_report/~{run_name}_~{mode}_Summary.csv ../
            mv ../~{run_name}_~{mode}_Summary.csv ../~{sample_id}_~{mode}_Summary.csv
            chmod -R 770 ./
        >>>

    runtime {
		modules: "~{modules}"
		memory:  "~{jobMemory} GB"
		cpu:     "~{threads}"
		timeout: "~{timeout}"
	}

	output {
		File dqsreport = "~{sample_id}_dqsummary.html"
		File pipelineSummary = "~{sample_id}_~{mode}_Summary.csv"
	}

	meta {
		output_meta: {
			dqsreport: "Html file of QC metric tables and plots",
			pipelineSummary: "csv file of biomodal pipeline summary"
		}
	}
}