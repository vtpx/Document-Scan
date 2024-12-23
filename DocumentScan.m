imgOrigin = imread("Example.jpeg");
imgOrigin = imrotate(imgOrigin, -90, "bicubic", "loose");

imgGrayOrigin = im2gray(imgOrigin);
imgGray = im2double(imgGrayOrigin);
scaleRate = 2;
imgResize = imresize(imgOrigin, 1 /scaleRate);
imgGray = imresize(imgGray, 1 / scaleRate);

% Canny边缘提取
kernel = fspecial("gaussian", 5);
imgBlur = filter2(kernel, imgGray);
imgEdge = edge(imgBlur, "canny", [0.1, 0.6]);

% 找到最大的轮廓
imgBound = bwboundaries(imgEdge, 8, "holes");
maxLength = 0;
maxi = 0;
for i = 1 : length(imgBound)
  a = length(imgBound{i});
  if a > maxLength
    maxLength = a;
    maxi = i;
  end
end
boundCord = imgBound{maxi};

% 找到矩形的四个角
% 先从一点出发找到两个对角顶点
vVec = boundCord - boundCord(1);
vDist = vVec(:, 1) .^ 2 + vVec(:, 2) .^ 2;
[~, idx] = max(vDist);
corner1 = boundCord(idx, :);

vVec = boundCord - corner1;
vDist = vVec(:, 1) .^ 2 + vVec(:, 2) .^ 2;
[~, idx] = max(vDist);
corner2 = boundCord(idx, :);

function [x, y] = RelativeEdgePoints(corner, vContour, radius)
  for i = 1 : height(vContour)
    l2Distance = norm(vContour(i, :) - corner);
    if  l2Distance > radius && ...
        l2Distance < radius + 2
      x = vContour(i, :);
      break
    end
  end

  v1 = x - corner;
  for i = 1 : height(vContour)
    v2 = vContour(i, :) - corner;
    l2Distance = norm(v2);
    if  l2Distance > radius && ...
        l2Distance < radius + 2 && ...
        v1 * v2' < radius * radius / 2
      y = vContour(i, :);
      break
    end
  end
end

function [u, v] = swap(x, y)
  u = y;
  v = x;
end

function [e1, e2] = RelativeEdge(corner, vContour, frame)
  maxRadius = min(frame);
  radius = maxRadius / 12;
  [p1, p2] = RelativeEdgePoints(corner, vContour, radius);
  v1 = corner - p1;
  e1p = [p1; zeros(8, 2)];
  e2p = [p2; zeros(8, 2)];
  for i = 2 : 9
    [p3, p4] = RelativeEdgePoints(corner, vContour, i * radius);
    v3 = corner - p3;
    if v1 * v3' < norm(v1) * norm(v3) / 2
      [p3, p4] = swap(p3, p4);
    end
    e1p(i, :) = p3;
    e2p(i, :) = p4;
  end

  e1 = polyfit(e1p(:, 1), e1p(:, 2), 1);
  e2 = polyfit(e2p(:, 1), e2p(:, 2), 1);
  if abs(e1(1)) < 1
    [e1, e2] = swap(e1, e2);
  end
end

% 由这两个顶点找到从顶点出发的四条边，认为这四条边是矩形的四条边

approxFrame = abs(corner1 - corner2);
[e1, e3] = RelativeEdge(corner1, boundCord, approxFrame);
[e2, e4] = RelativeEdge(corner2, boundCord, approxFrame);

function pt = CrossNode(line1, line2)
  k1 = line1(1);
  b1 = line1(2);
  k2 = line2(1);
  b2 = line2(2);
  x = (b2 - b1) / (k1 - k2);
  y = det([line1; line2]) / (k1 - k2);
  pt = [x, y];
end

x1 = -e1(2) / e1(1);
x2 = -e2(2) / e2(1);
if x1 > x2
  [e1, e2] = swap(e1, e2);
end

if e3(2) > e4(2)
  [e3, e4] = swap(e3, e4);
end

% 求四条边的交点，可以认为是矩形的四个角
corner1 = scaleRate * CrossNode(e1, e3);
corner2 = scaleRate * CrossNode(e1, e4);
corner3 = scaleRate * CrossNode(e2, e3);
corner4 = scaleRate * CrossNode(e2, e4);

h = round((norm(corner1 - corner3) + norm(corner2 - corner4)) / 2);
w = round((norm(corner1 - corner2) + norm(corner3 - corner4)) / 2);
vMoving = [corner1; corner2; corner3; corner4];
vMoving = [vMoving(:, 2), vMoving(:, 1)];

% 由四个角的坐标生成透视变换矩阵
TForm = fitgeotform2d(vMoving, ...
    [0, 0; w, 0; 0, h; w, h], "projective");
[dest, RB] = imwarp(imgGrayOrigin, TForm);
x1 = abs(round(RB.XWorldLimits(1)));
y1 = abs(round(RB.YWorldLimits(1)));
dest = dest(y1 : y1 + h, x1 : x1 + w);
% imshow(dest);

% 光照补偿 + Sauvola算法进行二值化
monochrome = AdaptiveBinarize(dest, 15);
imshow(monochrome);
% plot(boundCord(:, 2), boundCord(:, 1));
% hold on;
% plot(corner1(2), corner1(1), "o", "MarkerFaceColor", "blue")
