import React, { useId } from 'react';
import { cx } from './classNames';

/**
 * Tiny SVG sparkline / area chart. No external deps.
 *
 *   points    — array of numbers (one Y value per bucket)
 *   color     — stroke color; the fill is a fade of the same color
 *   height    — pixel height of the rendered chart (width = 100% of parent)
 *   showFill  — fill the area under the line (default true)
 *   strokeWidth
 */
export function Sparkline({
  points = [],
  color = 'var(--brand-blue)',
  height = 80,
  showFill = true,
  strokeWidth = 1.75,
  className,
  ariaLabel,
}) {
  const gradientId = useId();

  if (!points.length) return null;

  const W = 100; // virtual viewBox width; preserveAspectRatio="none" stretches it
  const PAD_Y = 4;
  const max = Math.max(...points);
  const min = Math.min(...points);
  const range = max - min || 1;
  const stepX = points.length > 1 ? W / (points.length - 1) : 0;
  const innerH = height - PAD_Y * 2;

  const coords = points.map((p, i) => [
    points.length === 1 ? W / 2 : i * stepX,
    PAD_Y + (1 - (p - min) / range) * innerH,
  ]);

  const linePath = coords
    .map(([x, y], i) => `${i === 0 ? 'M' : 'L'} ${x.toFixed(2)} ${y.toFixed(2)}`)
    .join(' ');

  const lastX = coords[coords.length - 1][0].toFixed(2);
  const areaPath =
    linePath +
    ` L ${lastX} ${height} L ${coords[0][0].toFixed(2)} ${height} Z`;

  return (
    <svg
      className={cx('ds-sparkline', className)}
      viewBox={`0 0 ${W} ${height}`}
      preserveAspectRatio="none"
      width="100%"
      height={height}
      role="img"
      aria-label={ariaLabel}
    >
      <defs>
        <linearGradient id={gradientId} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.22" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      {showFill && <path d={areaPath} fill={`url(#${gradientId})`} />}
      <path
        d={linePath}
        fill="none"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinejoin="round"
        strokeLinecap="round"
        vectorEffect="non-scaling-stroke"
      />
    </svg>
  );
}

export default Sparkline;
