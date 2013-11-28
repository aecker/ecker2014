
xi = 0:50:1700;
yi = gpreg(depths(:), SD(:), xi', 1e-5, 1e-5, 800);

SDi = gpreg(depths(:), SD(:), depths(:), 1e-5, 1e-5, 800);
resid = SD - reshape(SDi, size(SD));
SD2 = bsxfun(@minus, SD, mean(resid, 2));
