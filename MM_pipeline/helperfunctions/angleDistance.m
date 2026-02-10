function distance = angleDistance(angle)
    % Get the remainder when dividing by 90
    remainder = mod(angle, 90);
    
    % Find the minimum distance to the nearest multiple of 90
    distance = abs(min(remainder, 90 - remainder));
end