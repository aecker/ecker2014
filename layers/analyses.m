% Layer analysis
addpath ~/lab/libraries/matlab/
run ~/lab/projects/acq/alex_setPath.m
run ~/lab/projects/anesthesia/code/setPath.m


%% Current source density
%
% Here we compute the current source density (CSD, second spatial
% derivative of LFP) to identify the location of layer 4.
%
% Simply assuming that within one recording all tetrodes were at the same
% depth and averaging them did not produce convincing results when I tried
% it. This is probably because there were different amounts of tissue
% dimpling when inserting the tetrodes and in addition there was some
% variability in how much we adjusted each tetrode after each recording.
%
% I noticed that in one monkey the magnitude of the off-response of the LFP
% has a characteristic pattern across depths that is fairly consistent
% across tetrodes. I used this pattern to estimate the depth of each
% tetrode relative to the others. In combination with our notes about how
% far each tetrode was adjusted after each recording this should give me a
% fairly reliable estimate of the depths.
%
%   * At least in one monkey we seem to get a decent source/sink pattern
%     where we expect layer 4.
%   * As an interesting aside, the off response seems to be pretty strong
%     in the superficial layers. It's also visible in layer 4, roughly at
%     the same magnitude as the on response.
%
% last update: 2013-02-13

plotCSD

