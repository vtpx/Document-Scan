function dest = AdaptiveBinarize(src, nKernelSize)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
  % 光照补偿
  ord1 = double(ordfilt2(src, nKernelSize ^ 2 - 2, ones(nKernelSize, nKernelSize), "symmetric"));
  ord2 = double(ordfilt2(src, nKernelSize ^ 2 - 3, ones(nKernelSize, nKernelSize), "symmetric"));
  ord3 = double(ordfilt2(src, nKernelSize ^ 2 - 4, ones(nKernelSize, nKernelSize), "symmetric"));
  ord4 = double(ordfilt2(src, nKernelSize ^ 2 - 5, ones(nKernelSize, nKernelSize), "symmetric"));
  ord5 = double(ordfilt2(src, nKernelSize ^ 2 - 6, ones(nKernelSize, nKernelSize), "symmetric"));
  bg = (ord1 + ord2 + ord3 + ord4 + ord5) / 5;
  % imshow(uint8(bg));
  k = BinWeight(bg);
  y1 = 255 * uint8(bg <= src);
  y = uint8(max(255 - (k .* (bg - double(src))), 192));

  % A = 1.7;
  % fHighBoost = [
  %   -1, -1, -1;
  %   -1, 9 * A - 1, -1;
  %   -1, -1, -1
  % ] / 9;
  dest = bitor(y, y1);
  % dest = imfilter(dest, fHighBoost, "replicate");
  dest = Sauvola(dest, 31, 0.05, 128);
  % dest = imbinarize(dest, "global");
end

function k = BinWeight(bg)
  mask1 = double(bg < 20);
  mask2 = double(bg >= 20 & bg <= 100);
  mask3 = double(bg > 100 & bg < 200);
  mask4 = double(bg >= 200);
  k1 = 2.5 * mask1;
  k2 = mask2 + (3 * (100 - bg) / 160) .* mask2;
  k3 = mask3;
  k4 = mask4 + ((bg - 200) / 35) .* mask4;
  k = k1 + k2 + k3 + k4;
end

