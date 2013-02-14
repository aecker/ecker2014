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


%% CSD debugging in first monkey
%
% We don't get a decent CSD profile for the first monkey, presumably
% because of the way we referenced in this monkey: we used a tetrode in
% white matter as the reference. Presumably that tetrode changed its
% position due to tissue movement when adjusting the other tetrodes,
% resulting quite different evoked LFP responses from one recording to the
% next. Also, it could be picking up different signals related to how deep
% the anesthesia was in different sessions.
%
% The script below illustrates the average evoked LFP responses for each
% recording along with the first two components of a space-time SVD, which
% pretty nicely capture the differences in the on responses from one
% recording to the next. Since it doesn't change smoothly over time but
% seems to oscillate back and forth it seems unplausible that these changes
% are actually related to the depth in cortex.
%
% last update: 2013-02-14

plotLFP(9)
plotLFP(11)


