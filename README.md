Overview
========

This repository contains the Matlab code used to analyze the data and generate the figures in Ecker et al., _State dependence of noise correlations in macaque primary visual cortex_, Neuron (2014).

We analyzed the data using a data management framework called [DataJoint](https://github.com/datajoint), which uses a relational database (MySQL) to store data and analysis results. 

Our primary intention was to publish the actual code that we used to analyze the data and create the figures, to provide full transparency and to enable readers to read it and find out the exact details of what was done. The section "understanding the code" below gives some pointers to navigate it.

Running the code yourself to reproduce the figures or build upon it is a bit more involved. In addition to a couple of external libraries, you will need a MySQL server and download the database dump (8.5 GB). The installation is described at the end of this document. If you go this route, please make sure to read the remarks on the license (next section).





License
=======

The code in this repository by A. Ecker is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/)

Note that the dataset associated with the paper is licensed under a [Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License](http://creativecommons.org/licenses/by-nc-nd/3.0/). This means you are free to use the data to reproduce and validate our results. However, if you want to use our data in your own research and publish a new analysis, we kindly ask you to get in touch with us before doing so. We imposed the no derivatives clause for two (hopefully understandable) reasons:

1. To avoid misunderstandings and/or misinterpretations of the data we would like to know about results by other people _before_ they are published.

2. In case we are working on a similar project, we would like to avoid getting scooped with our own data.





Understanding the code
======================


General organization of the code
--------------------------------

We used a data management framework called [DataJoint](https://github.com/datajoint) to organize data and code. Under DataJoint the results of any analysis are stored in a relational database. Each result is stored along with the parameters that were used to obtain it. In addition, dependencies between subsequent analysis steps are kept track of and are enforced automatically. This process tremendously simplifies staying on top of complex analysis toolchains, such as the one for the current project. Details can be found in the [DataJoint documentation](https://github.com/datajoint/datajoint-matlab/wiki).

In DataJoint, every analysis consists of one or multiple database tables, each of which is associated with its own Matlab class. Such a group of tables is populated automatically via a specific class method called makeTuples(). This method is where the actual work is done. 

Below we provide an overview of the analysis tables used for the current project. In addition, the functions that create the figures are a good entry point to find out which classes/tables are relevant for a certain figure. These functions are located in the folder 'figures'. You will notice that those functions don't do much other than getting data/results from the database [fetch(...)], plot it and sometimes do some statistics on it.

In addition to the classes defined in this repository, we use a number of general purpose libraries for the basic organization of our experimental data and tasks such as spike detection and sorting. These libraries can be found on Github as well:

* https://github.com/atlab/sessions -- meta data stored by acquisition system and processing toolchain (database schemas acq, detect, sort)
* https://github.com/atlab/spikedetection -- spike detection
* https://github.com/aecker/moksm -- spike sorting
* https://github.com/aecker/gpfa -- Gaussian Process Factor Analysis (GPFA)




Documentation of individual analysis steps
------------------------------------------


### Spike detection

Spike detection is done by a separate library. See https://github.com/atlab/spikedetection
The function `detectSpikesTetrodesV2.m` is used.



### Spike sorting

Parameter settings etc. are defined in `sessions/sort.KalmanAutomatic`. The actual spike sorting is done by a separate library. See https://github.com/aecker/moksm for more information.



### Basic single unit properties

Basic single unit statistics such as firing rates, variances, rate stability etc. are computed in the class `nc.UnitStats`. Quantities related to tuning properties such as orientation and direction tuning, their significance and visual responsiveness are computed in the class `nc.OriTuning`. For statistics of pairs of neurons, see next section (Noise Correlations).



### Noise correlations (Fig. 2)

Pairwise analyses such as computing signal and noise correlations, but also more basic properties such as geometric mean firing rate, distance between electrodes, maximum contamination or rate instability, are computed in the class `nc.NoiseCorrelationSet`.



### Fitting and evaluation of GPFA model (Fig. 3–5, 7)

Fitting the GPFA model is performed in the classses `nc.GpfaModelSet` (for evoked responses) and `nc.GpfaSpontSet` (for spontaneous responses). More precisely, these classes deal with preparing the data, i.e. partitioning for cross-validation, pre-transforming etc. The actual work (model fitting and evaluation) is done by a separate library. See https://github.com/aecker/gpfa for details.

Computing variance explained and residual correlations is performed by the class `nc.GpfaResidCorrSet`. Again here, the actual work is done by the GPFA library.



### GLM with LFP as input (Fig. 8)

The Generalized Linear Model using the local field potention (LFP) as input to predict correlated variability is fit by the class `nc.LfpGlmSet`.



### Spectral analysis of LFP (Fig. 9)

Power spectrograms of the LFP are computed in the class `nc.LfpSpectrogram`. The correlation between LFP power ratio and overall correlation is performed by the classes `nc.LfpPowerRatioGpfaSet` and `nc.NetworkStateVar`.



### Inclusion criteria

All sessions and cells that were included in the analysis are listed in the tables `nc.AnalysisStims` and `nc.AnalysisUnits`. The populate relation (property `popRel`) of those classes defines the restrictions that are applied.




General outline of database structure
-------------------------------------

Each Matlab package (+xyz) maps to a database schema and each Matlab class to a database table. 


### Schema `acq`

This schema contains the metadata entered into the database by the recording software during data collection. The following tables are most relevant:

* `Subjects`: list of monkeys
* `Sessions`: experimental sessions (can contain multiple recordings and stimuli)
* `Ephys`: electrophysiological recording
* `Stimulation`: visual stimulus presentation
* `EphysStimuliationLink`: links simultaneous ephys recordings and stimulus presentations



### Schema `detect`

Implements the spike detection part of the processing toolchain. This is highly customized code to be run on specific, optimized computers. The actual spike detection is done by an [external library](https://github.com/atlab/spikedetection).



### Schema `sort`

Implements the spike sorting toolchain. The `sort.Kalman*` classes are the ones used for the Mixture of Kalman filter model we use (Calabrese & Paninski 2011). The actual model fitting is done by an [external library](https://github.com/aecker/moksm).



### Schema `ephys`

The schema contains general purpose electrophysiology tables. Only `ephys.Spikes` is relevant here; it contains the spike times for each single unit.



### Schema `ae`

This schema contains my (AE) general purpose electrophysiology tables. The following tables are most relevant:

* `SpikesByTrial`: spike times relative to stimulus onset for each trial
* `SpikeCounts`: spike count in a certain window (see `SpikeCountParams`) for each cell and each trial
* `Lfp`: bandpass-filtered LFP trace (see `LfpParams` for parameters)
* `LfpByTrial`: LFP snippet for each trial aligned to stimulus onset



### Schema `nc`

This schema contains the concrete analyses done in the paper. The specific tables are listed in the previous sections for each analysis. In addition, the following tables may be of interest:

* `Gratings`, `GratingConditions`: contain the grating parameters for the different stimulus conditions
* `Anesthesia`: lists monkeys used for awake vs. anesthetized recordings
* `CrossCorrSet`: computes the cross-correlograms (Supplemental Information, Fig. S3)
* `UnitPairs`, `UnitPairMembership`: contains all pairs of units



Installation
============

1. Download and install the [MySQL Community Server](http://dev.mysql.com/downloads/mysql/)

2. Insert database dump.
	* Download the [database dump](http://bethgelab.org/files/ecker2014.zip)
	* Insert the dump file into the database (replace `<HOST>` and `<USER>` by the database host and username, respectively): ```mysql -h <HOST> -u <USER> -p < ecker2014.sql```

3. Download the following repositories, depending on what you intend to do. All repositories should reside in the same base folder as this repository.
	* https://github.com/aecker/ecker2014 -- [required] main analysis code (this repo)
	* https://github.com/datajoint/datajoint-matlab -- [required] DataJoint
	* https://github.com/datajoint/mym -- [required] Matlab/MySQL interface
	* https://github.com/atlab/sessions -- [required] meta data stored by acquisition system and processing (spike detection and sorting) toolchain
	* https://github.com/aecker/gpfa -- [required] Gaussian Process Factor Analysis (GPFA) implementation
	* https://github.com/atlab/spikedetection -- spike detection
	* https://github.com/aecker/moksm -- spike sorting

4. Set Matlab path
	* In Matlab, run `ecker2014/startup` to set the path etc.
	* You may have to compile mym, the Matlab-MySQL database connector utility. Refer to the readme of the mym repository for details.


