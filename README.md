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

We used a data management framework called [DataJoint](https://github.com/datajoint) to organize data and code. Under DataJoint the results of any analysis are stored in a relational database. Each result is stored along with the parameters that were used to obtain it. In addition, dependencies between subsequent analysis steps are kept track of and are enforced automatically. This process tremendously simplifies staying on top of complex analysis toolchains, such as the one for the current project.

In DataJoint, every analysis consists of one or multiple database tables, each of which is associated with its own Matlab class. Such a group of tables is populated automatically via a specific class method called makeTuples(). This method is where the actual work is done. 

Below we provide an overview of the analysis tables used for the current project. In addition, the functions that create the figures are a good entry point to find out which classes/tables are relevant for a certain figure. These functions are located in the folder 'figures'. You will notice that those functions don't do much other than getting data/results from the database [fetch(...)], plot it and sometimes do some statistics on it.



Documentation of individual analysis steps
------------------------------------------


### Spike detection



### Spike sorting



### Basic unit statistics (rate, variance, instability)

classes nc.UnitStats*



### Orientation tuning

classes nc.OriTuning*



### Noise correlations

classes nc.NoiseCorrelation*



### Fitting GPFA model

repo aecker/gpfa
classes nc.Gpfa*



### GPFA model for spontaneous activity

classes nc.GpfaSpont*



### GLM with LFP as input

classes nc.LfpGlm*



### Spectral analysis of LFP

classes nc.LfpSpectrogram*
classes nc.LfpPowerRatio*



General outline of database structure
-------------------------------------

* Describe schemas act, detect, sort, ephys, ae, nc
* Give some pointers where to find certain (meta)data




Installation
============

1. Download and install the [MySQL Community Server](http://dev.mysql.com/downloads/mysql/)

2. Insert database dump.
	* URL
	* Code to do it

3. Download the following repositories, depending on what you intend to do
	* https://github.com/aecker/ecker2014 -- [required] main analysis code (this repo)
	* https://github.com/datajoint/datajoint-matlab -- [required] DataJoint
	* https://github.com/datajoint/mym -- [required] Matlab/MySQL interface
	* https://github.com/atlab/sessions -- [required] meta data stored by acquisition system and processing (spike detection and sorting) toolchain
	* https://github.com/atlab/spikedetection -- spike detection
	* https://github.com/aecker/moksm -- spike sorting

4. Set Matlab path
	* run ecker2014/startup
	* Describe assumptions about where things have to be relative to main repo



