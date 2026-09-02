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
        String scheduler = ""
        String slurmPartition = ""
        String slurmAccount = ""
        Array[String] singularityBinds = []
        String processBeforeScript = ""
        String processTime = ""
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
        scheduler: "Which scheduler Nextflow submits its own jobs to, sge or slurm. Leave empty and the task decides from the submit command the cluster provides, so one set of inputs is portable between sites"
        slurmPartition: "Partition Nextflow submits its own jobs to, required when scheduler resolves to slurm. The pipeline config names no queue that exists outside the site it was written for"
        slurmAccount: "Accounting group for the jobs Nextflow submits, when the site requires one"
        singularityBinds: "Paths bound into every container, for a site whose filesystems the pipeline config does not already reach"
        processBeforeScript: "Script run before every Nextflow process. Empty keeps the pipeline's own"
        processTime: "Wall-clock limit for every Nextflow process, as a Nextflow duration such as 24h, replacing the limits the pipeline config sets. Empty keeps those, which is only safe where they fit the partition or queue the jobs go to"
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
        fastqR2 = R2_merged,
        scheduler = scheduler,
        slurmPartition = slurmPartition,
        slurmAccount = slurmAccount,
        singularityBinds = singularityBinds,
        processBeforeScript = processBeforeScript,
        processTime = processTime
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
            String scheduler = ""
            String slurmPartition = ""
            String slurmAccount = ""
            Array[String] singularityBinds = []
            String processBeforeScript = ""
            String processTime = ""
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
            scheduler: "Which scheduler Nextflow submits its own jobs to, sge or slurm. Empty resolves from the submit command on PATH"
            slurmPartition: "Partition Nextflow submits its own jobs to, required when scheduler resolves to slurm"
            slurmAccount: "Accounting group for the jobs Nextflow submits, when the site requires one"
            singularityBinds: "Paths bound into every container"
            processBeforeScript: "Script run before every Nextflow process. Empty keeps the pipeline's own"
            processTime: "Wall-clock limit for every Nextflow process, as a Nextflow duration such as 24h. Empty keeps the pipeline config's own"
            modules: "Required environment modules"
            jobMemory: "Memory allocated for this job (GB)"
            threads: "Requested CPU threads"
            timeout: "Hours before task timeout"
        }
        
        command <<<
            set -euo pipefail

            # ---------------------------------------------------------------------------
            # Which scheduler Nextflow submits its own jobs to. Resolved from the submit
            # command the cluster provides so one set of inputs is portable between sites;
            # the scheduler input overrides that. Decided before any work is done, so a
            # setting that cannot be satisfied fails at once rather than after the run.
            # ---------------------------------------------------------------------------
            SCHEDULER="~{scheduler}"
            if [ -z "${SCHEDULER}" ]; then
                if   command -v sbatch >/dev/null 2>&1; then SCHEDULER=slurm
                elif command -v qsub   >/dev/null 2>&1; then SCHEDULER=sge
                else
                    echo "ERROR: cannot tell which scheduler Nextflow should submit to: neither sbatch nor qsub is on PATH. Set the scheduler input" >&2
                    exit 1
                fi
                echo "Detected scheduler: ${SCHEDULER}"
            fi

            SLURM_ONLY=()
            [ -z "~{slurmPartition}" ]      || SLURM_ONLY+=("slurmPartition")
            [ -z "~{slurmAccount}" ]        || SLURM_ONLY+=("slurmAccount")
            [ -z "~{processBeforeScript}" ] || SLURM_ONLY+=("processBeforeScript")

            case "${SCHEDULER}" in
                sge)
                    if [ "${#SLURM_ONLY[@]}" -gt 0 ]; then
                        echo "Note: $(IFS=,; echo "${SLURM_ONLY[*]}") ignored; those apply only to slurm"
                    fi
                    ;;
                slurm)
                    if [ -z "~{slurmPartition}" ]; then
                        echo "ERROR: scheduler slurm requires slurmPartition: the pipeline config names no queue that exists here" >&2
                        exit 1
                    fi
                    ;;
                *)
                    echo "ERROR: scheduler must be sge or slurm, got '${SCHEDULER}'" >&2
                    exit 1
                    ;;
            esac

            
            mkdir init_folder
            ln -s $INIT_FOLDER/* ./init_folder
            cd init_folder

            # The run script hands conf/nextflow.config.sge.deep to nextflow with -c. The
            # module tree is read-only, so take a writable copy to append the scheduler
            # settings to; the script resolves conf/ next to itself and picks this one up.
            rm -f ./conf
            cp -rL "$INIT_FOLDER/conf" ./conf
            chmod -R u+w ./conf


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
            
            # ---------------------------------------------------------------------------
            # Scheduler and wall-time settings, appended to the config the run script passes
            # first, so they win over what it sets. Nothing is written for an sge run that
            # leaves processTime empty, so that path keeps exactly the config in place.
            # ---------------------------------------------------------------------------
            SCHED_SCHEDULER="${SCHEDULER}" \
            SCHED_PARTITION="~{slurmPartition}" \
            SCHED_ACCOUNT="~{slurmAccount}" \
            SCHED_BEFORE="~{processBeforeScript}" \
            SCHED_TIME="~{processTime}" \
            SCHED_MODULE="~{modules}" \
            SCHED_BINDS="~{sep=',' singularityBinds}" \
            SCHED_CONFIG="$(pwd)/conf/nextflow.config.sge.deep" \
            python3 <<'PYEOF'
            import os, pathlib, re

            sched = os.environ["SCHED_SCHEDULER"]
            cfg_path = pathlib.Path(os.environ["SCHED_CONFIG"])
            cfg = cfg_path.read_text()

            SELECTOR = re.compile(r"^\s*withName:\s*'([^']+)'\s*\{([^{}]*)\}", re.M)
            SGE_RESOURCE = re.compile(r"-pe\s+\S+\s+(\d+)\b|h_vmem=(\d+(?:\.\d+)?)([KMGT])")


            def sge_resources(opts):
                cpus = mem = None
                for m in SGE_RESOURCE.finditer(opts):
                    if m.group(1):
                        cpus = int(m.group(1))
                    elif m.group(2):
                        mem = "%s%sB" % (m.group(2), m.group(3))
                return cpus, mem


            # What each selector asks for. Resources here exist only as SGE submit strings -- the
            # pipeline's own config sets container and nothing else -- so another scheduler needs
            # them translated, not cleared. Read at run time so a module upgrade is picked up.
            requests, sets_time = {}, set()
            for m in SELECTOR.finditer(cfg):
                name, body = m.group(1), m.group(2)
                opts = re.search(r'clusterOptions\s*=\s*"([^"]*)"', body)
                if opts:
                    requests[name] = sge_resources(opts.group(1))
                if re.search(r"\btime\s*=", body):
                    sets_time.add(name)

            generic, per_selector, notes = [], {}, []

            if sched == "slurm":
                account = os.environ["SCHED_ACCOUNT"]
                cluster_opts = "--account=%s" % account if account else ""
                generic += [
                    "executor = 'slurm'",
                    "queue = '%s'" % os.environ["SCHED_PARTITION"],
                    "clusterOptions = '%s'" % cluster_opts,
                    "module = '%s'" % os.environ["SCHED_MODULE"],
                ]
                before = os.environ["SCHED_BEFORE"]
                if before:
                    generic.append("beforeScript = '%s'" % before)

                unreadable = [n for n, (c, m) in requests.items() if c is None or m is None]
                if unreadable:
                    raise SystemExit(
                        "ERROR: cannot read cpus/memory out of the SGE clusterOptions for: %s. "
                        "Keeping them would submit in the wrong scheduler's syntax and clearing "
                        "them would submit with no request at all, so neither is safe."
                        % ", ".join(sorted(unreadable)))
                for name, (cpus, mem) in requests.items():
                    per_selector.setdefault(name, []).extend(
                        ["cpus = %d" % cpus, "memory = '%s'" % mem,
                         "clusterOptions = '%s'" % cluster_opts])
                notes.append("translated %d selectors from SGE clusterOptions to cpus/memory"
                             % len(requests))
            else:
                m = re.search(r'^\s*module\s*=\s*"([^"]*)"', cfg, re.M)
                if m and m.group(1) != os.environ["SCHED_MODULE"]:
                    print("WARNING: the pipeline config loads module '%s' on the execution nodes "
                          "but this task loads '%s'" % (m.group(1), os.environ["SCHED_MODULE"]))

            proc_time = os.environ["SCHED_TIME"]
            if proc_time:
                generic.append("time = '%s'" % proc_time)
                for name in sorted(set(requests) | sets_time):
                    per_selector.setdefault(name, []).append("time = '%s'" % proc_time)
                notes.append("time set to %s" % proc_time)

            binds = [b for b in os.environ["SCHED_BINDS"].split(",") if b]

            if generic or per_selector or binds:
                lines = ["", "// ---- SCHEDULER SETTINGS (generated per run) ----"]
                if generic or per_selector:
                    lines.append("process {")
                    lines += ["    %s" % g for g in generic]
                    lines += ["    withName: '%s' { %s }" % (n, "; ".join(a))
                              for n, a in sorted(per_selector.items())]
                    lines.append("}")
                if binds:
                    lines += ["singularity {", "    runOptions = '-B %s'" % ",".join(binds), "}"]
                with cfg_path.open("a") as fh:
                    fh.write("\n".join(lines) + "\n")
                for n in notes:
                    print("Scheduler settings: %s" % n)
            PYEOF

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