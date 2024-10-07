version 1.0

workflow biomodalQC {
    input {
        String tag
        String run_name
        String library_name
        String lane
        String mode
        String subsample
        Boolean randon_downsample
        String group_desc
        String data_path
        String run_directory
        String work_dir
    }
    parameter_meta {
        tag: "Tag for the biomodal pipeline run"
        run_name: "Sequencer run name"
        library_name: "Sample library name"
        lane: "Sequencer lane number"
        mode: "Biomodal pipeline running mode"
        subsample: "The target number of reads to subsample for the input fastq file"
        randon_downsample: "Specify whether use seqtk to choose random reads, if set to false then choose the top reads in fastq"
        group_desc: "A text description of what the group ID means"
        data_path: " Path to directory that contains the input fastq files"
        run_directory: "subdirectory under data_path with run name "
        work_dir: "Path to biomodal working directory"
    }

    String output_path = "data_sets/" + run_directory + "/nf-result" + "duet/1.1.2_" + tag + mode

    call runBiomodalQC {
        input:
        tag = tag,
        run_name = run_name,
        library_name = library_name,
        lane = lane,
        mode = mode,
        subsample = subsample,
        randon_downsample = randon_downsample,
        group_desc = group_desc,
        data_path = data_path,
        run_directory = run_directory,
        work_dir = work_dir,
        output_path = output_path
    }

    meta {
            author: "Gavin Peng"
            email: "gpeng@oicr.on.ca"
            description: "Workflow for biomodalQC, QC workflow for biomodal pipeline"
                dependencies: 
                {
                name: "biomodalqc/1.0.0",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/71_biomodalqc.yaml?ref_type=heads"
                }
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
        File runBiomodalQC.dqsreport
        File runBiomodalQC.pipelineSummary
    }

    task runBiomodalQC{
        input {
            String tag
            String run_name
            String library_name
            String lane
            String mode = "6bp"
            String subsample = 2000000
            Boolean randon_downsample = true
            String group_desc
            String data_path
            String run_directory
            String work_dir = "/scratch2/groups/gsi/bis/biomodal/"
            String output_path
            String modules = "biomodalqc/1.0.0"
            Int jobMemory = 16
            Int threads = 2
            Int timeout = 48
            }
        parameter_meta {
            tag: "Tag for the biomodal pipeline run"
            run_name: "Sequencer run name"
            library_name: "Sample library name"
            lane: "Sequencer lane number"
            mode: "Biomodal pipeline running mode"
            subsample: "The target number of reads to subsample for the input fastq file"
            randon_downsample: "Specify whether use seqtk to choose random reads, if set to false then choose the top reads in fastq"
            group_desc: "A text description of what the group ID means"
            data_path: " Path to directory that contains the input fastq files"
            run_directory: "subdirectory under data_path with run name "
            work_dir: "Path to biomodal working directory"
            output_path: "Path to biomodalQC outputs"
            modules: "Required environment modules"
            jobMemory: "Memory allocated for this job (GB)"
            threads: "Requested CPU threads"
            timeout: "Hours before task timeout"
        }
        
        String meta_file_path = "data_sets/" + ~${run_directory} + "/meta_file.csv"
        command <<<
            set -euo pipefail
            module load biomodalQC
            mkdir init_folder
            cp -r $INIT_FOLDER/* ./init_folder/
            cd init_folder

            mkdir data_sets
            mkdir data_sets/~${run_directory}
            mkdir data_sets/~${run_directory}/gsi-input
            ln -s ~{data_path} data_sets/~${run_directory}/gsi-input/ 

            
            cat << EOF > ${meta_file}
                sample_id, ~{$library_name}
                description, ~${group_desc}
            EOF

            cat << EOF > input_config.txt
                tag=~${tag}
                run_name=$~{run_name}
                sample_id=~${library_name}
                lane=~${lane}
                mode=~${mode}
                subsample=~${subsample}
                random_downsample=~${random_downsample}
                meta_file=${meta_file}
                data_path=~${data_sets}
                run_directory=~${run_directory}
                work_dir=~${work_dir}
            EOF

            ./run_biomodalqc.sh ./input_config.txt
        >>>
    runtime {
		modules: "~{modules}"
		memory:  "~{jobMemory} GB"
		cpu:     "~{threads}"
		timeout: "~{timeout}"
	}

	output {
		File dqsreport = "~{output_path}/dqsreport/~{library_name}.dqsummary.html"
		File pipelineSummary = "~{output_path}pipeline_report/~{run_name}_~{mode}_Summary.csv"
	}

	meta {
		output_meta: {
			dqsreport: "Html file of QC metric tables and plots",
			pipelineSummary: "csv file of biomodal pipeline summary"
		}
	}
    }
}