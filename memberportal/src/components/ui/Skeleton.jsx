import React from 'react';
import { cx } from './classNames';

export function Skeleton({ width, height = 12, radius, className, style }) {
  return (
    <span
      className={cx('ds-skeleton', className)}
      style={{
        width: width || '100%',
        height,
        borderRadius: radius,
        ...style,
      }}
    />
  );
}

export function SkeletonRow({ columns = 5 }) {
  return (
    <tr>
      {Array.from({ length: columns }).map((_, i) => (
        <td key={i}>
          <Skeleton height={14} />
        </td>
      ))}
    </tr>
  );
}

export default Skeleton;
