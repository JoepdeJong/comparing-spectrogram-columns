% Input parameters
filename = 'Blondie - Denis'; % OR 'Blondie - Call Me'

% Spectrogram parameters
window = hamming(512, 'periodic');
number_of_frequencies = 1024;
range_overlap_of_samples = [0]; %[0, 16, 32];


% Method parameters
range_delta = linspace(0.05, 0.25, 21);
range_number_of_overlaps = linspace(10, 90, 5);
r = 0.5;

% Ouput parameters
if ~exist(filename, 'dir')
    mkdir(filename)
end


% function [] = generateDemoData(Y, N)
for overlap_of_samples = range_overlap_of_samples
    compare_columns(filename, window, overlap_of_samples, number_of_frequencies, range_delta, range_number_of_overlaps, r);
end
% end
