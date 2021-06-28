function [] = compare_columns(filename, window, overlap_of_samples, number_of_frequencies, range_delta, range_number_of_overlaps, r)
    [x, sample_rate] = audioread(sprintf('%s.wav', filename));
    
    x = x(:, 1); % Get the first channel of the signal.
    
    X = make_spectrogram(x, sample_rate, window, overlap_of_samples, number_of_frequencies);
    
    Y = real(X); % Omit phase information
   
    len = size(Y, 2); % Number of columns in the spectrogram
    
    for delta = range_delta
        delta
        for number_of_overlaps = range_number_of_overlaps
            number_of_overlaps
            
            
            % Calculate the average amplitude over time for each frequency
            avg_freq_amp = averageFrequencyAmplitude(Y, number_of_frequencies);


            O = zeros(len, len); % Matrix containing overlaps between vectors
            O_k = zeros(1,len);  % Vector containing the number of overlaps of column k, capped at number_of_overlaps


            for k = 1:len
                avg_amp = mean(vecnorm(Y)); % Calculate the average norm of the columns in the spectrogram
                
                % Compare columns with other columns
                for l = 1:len
                    if(k == l)
                        continue
                    end
                    O(k,l) = doColumnsOverlap(Y, k, l, delta, avg_amp);
                    if(O(k,l))
                        O_k(k) = O_k(k) + 1;
                        if(O_k(k) >= number_of_overlaps)
                            break
                        end
                    end
                end

                % Check if the number of overlaps exceeds the threshold
                if(O_k(k) >= number_of_overlaps)
%                     k % Debugging

            %             if(dst(k, l))

                    % Loop over all rows (frequencies)
                    for m = 1:number_of_frequencies
                        % Check whether the amplitude of the current frequency is
                        % "sufficiently" large
                        if(norm(Y(m,k)) > r*avg_freq_amp(m))

                            % Loop over all columns
                            for l = 1:len
                                if(l == k)
                                    continue
                                end

                                % Determine the sign of the amplitude
                                signk =  Y(m,k) > 0;
                                signl = Y(m,l) > 0;

                               % If amplitudes are both positive or negative
                               if(signk == signl)
                                    % If amplitude of L is larger than amplitude of K
                                    if(abs(Y(m,l)) >= abs(Y(m,k)))
                                        Y(m,l) = Y(m,l) - Y(m,k);
                                    else
                                        Y(m,l) = 0;
                                    end
                                end
                            end
                        end 

                        % Set overlapping column to zero
                        Y(m,k) = 0;
                    end
                end
            end
            
               % YI = Y;
            % Y = 1i*Y + YR;

            y = invert_spectrogram(Y, sample_rate, window, overlap_of_samples, number_of_frequencies);

            audio_filename = sprintf("%s/%d_%d_%1.2f_%d_%1.2f.wav", filename, number_of_frequencies, overlap_of_samples, r, number_of_overlaps, delta);
            image_filename = sprintf("%s/%d_%d_%1.2f_%d_%1.2f.png", filename, number_of_frequencies, overlap_of_samples, r, number_of_overlaps, delta);
            audiowrite(audio_filename, real(y), sample_rate)

            plotAndSave(Y, number_of_frequencies, delta, number_of_overlaps, sample_rate, image_filename)
        end
    end
end


function [X] = make_spectrogram(x, sample_rate, window, overlap_of_samples, number_of_frequencies)
    X = stft(x,sample_rate, 'Window', window, 'OverlapLength', overlap_of_samples, 'FFTLength', number_of_frequencies);
    size(X)
    size(x)
end

function [x] = invert_spectrogram(X, sample_rate, window, overlap_of_samples, number_of_frequencies)
    x = istft(X,sample_rate, 'Window', window, 'OverlapLength', overlap_of_samples, 'FFTLength', number_of_frequencies);
end

function [overlaps] = doColumnsOverlap(X, i, j, delta, avg_amp)    
    % Check if distance between the vectors is less than delta to determine
    % overlap
    overlaps = norm(X(:,i) - X(:,j)) < delta*avg_amp;
end

function [avg_freq_amp] = averageFrequencyAmplitude(Y, N)
    zeros(1,N);
    for m = 1:N
        avg_freq_amp(m) = norm(mean(Y(m,:)));
    end
end

function [] = plotAndSave(Y, number_of_frequencies, delta, number_of_overlaps, Fs, filename)
    f_axis = (-number_of_frequencies+1:number_of_frequencies-1)*Fs/number_of_frequencies;
    t_axis = (0:length(Y)-1)/Fs*number_of_frequencies;

    imagesc(t_axis, f_axis, abs(real(Y)))
    set(gca,'ColorScale','log', 'YDir', 'normal')
    title('Filtered spectrogram');
    subtitle(sprintf('bins = %d, delta = %1.2f, N = %d', number_of_frequencies, delta, number_of_overlaps))
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');

    c = colorbar;
    c.Label.String = 'Amplitude (dB)';
    saveas(gca, filename)
end
