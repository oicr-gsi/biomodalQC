# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-09-01
### Added
- `scheduler`, `slurmPartition`, `slurmAccount`, `singularityBinds`,
  `processBeforeScript` and `processTime`, so the workflow runs on slurm as well as sge.
  `scheduler` is resolved from the submit command the cluster provides when left empty,
  and decided before any work is done.
- With slurm the task translates each `withName` selector's SGE submit string into `cpus`
  and `memory`, appending the result to a writable copy of the config the run script
  passes. Clearing those strings is not an option: the pipeline's own config sets
  `container` and nothing else, so they are the only place a per-process resource request
  exists and a run without them would ask for nothing at all. They are read at run time
  rather than copied here, so a module upgrade that changes one is picked up.
- `processTime` replaces the wall-clock limits, on the generic scope and on each selector
  that sets one, and a slurm run must supply it. The config asks for `10d`; both partitions
  here cap lower, so sbatch refuses every job. That refusal is not fatal to the pipeline,
  whose error strategy ignores a job with no exit status, so the run hung rather than
  failing.
- A slurm run also amends the error strategy so a job that never reached the scheduler
  terminates the run. Only that case changes; a job that ran and failed is still handled
  the way the pipeline asks.
- The pipeline pins one modulator tree's paths into six of its process scripts, so on a
  cluster built from another tree its interpreter resolves but the libraries behind it do
  not. The task repoints them at the tree the loaded module came from. The tree name is
  read off the module's own path and the root off the scripts, so neither is written into
  the workflow; where the two already agree nothing changes. A package with no
  counterpart in the target tree is an error rather than a silent substitution.

### Fixed
- The regression case is named `test_01`. The harness reads the test outcome out of the
  vidarr log keyed by this id and never matched the hyphenated one, so every run of this
  workflow was reported as having no outcome, whatever it actually did.
- Two processes copy their helper scripts from `$INIT_FOLDER`, which is the read-only
  module, so they took the shipped scripts rather than the repointed ones beside them.
  The variable is now pointed at the copy in the task directory before the run starts.
- A slurm run overrides the java temp directory. The head job exports one under its own
  node's `/tmp` and every job it submits inherits it, so a job landing on another node
  could not create a temp file; it showed up as `fastqc` producing a truncated zip.

### Changed
- The instance is copied rather than symlinked. An include is resolved by following the
  symlink before applying the `..` in it, so a symlinked `workflows/` reached back into
  the module tree and read the shipped `modules/` in place of the one beside it. Dotfiles
  are left behind, since the module ships a `.nextflow` cache from its own build.

### Fixed
- `run_directory` dropped from the regression arguments. The workflow has no such input,
  and an argument it does not accept fails the case on submission.

## [1.1.1]
### Changed
- fixed issue of random order of input fastq array

## [1.1.0] - 2025-06-11
### Added
- Added mergeFastqs runtime parameters 

## [1.0.4] - 2025-06-04
### Changed
- input fastq files changed to accept mutiple lanes data

## [1.0.3] - 2025-04-17
### Added
- Added vidarr name biomodalQC_miseq
- 
## [1.0.2] - 2024-11-06
### Changed
- Fix the sample_id convention issue

## [1.0.1] - 2024-11-05
### Changed
- Solve the init_folder permission issue
  
## [1.0.0] - 2024-10-07
### Added
- A brand-new workflow.
