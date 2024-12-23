function dest = Sauvola(src, nKernelSize, k, r)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
  src = double(src);
  convKernel = fspecial("average", nKernelSize);
  mMean = imfilter(src, convKernel, "replicate");
  mMeanSqr = imfilter(src .^ 2, convKernel, "replicate");
  sigma = sqrt(mMeanSqr - mMean .^ 2);
  mThreshold = mMean .* (1 + k * (sigma / r - 1));
  dest = src > mThreshold;
end