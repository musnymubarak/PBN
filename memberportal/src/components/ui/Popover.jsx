import React, { useEffect, useRef, useState } from 'react';
import { cx } from './classNames';

export function Popover({
  trigger,
  align = 'right',
  width = 280,
  offset = 8,
  className,
  children,
}) {
  const [open, setOpen] = useState(false);
  const wrapRef = useRef(null);

  useEffect(() => {
    function onDoc(e) {
      if (wrapRef.current && !wrapRef.current.contains(e.target)) setOpen(false);
    }
    document.addEventListener('mousedown', onDoc);
    return () => document.removeEventListener('mousedown', onDoc);
  }, []);

  return (
    <div ref={wrapRef} style={{ position: 'relative' }}>
      {React.cloneElement(trigger, {
        onClick: (e) => {
          e.stopPropagation();
          trigger.props.onClick?.(e);
          setOpen(o => !o);
        },
      })}
      {open && (
        <div
          className={cx('ds-popover', className)}
          style={{
            position: 'absolute',
            top: `calc(100% + ${offset}px)`,
            [align]: 0,
            width,
            zIndex: 1000,
          }}
          onClick={e => e.stopPropagation()}
        >
          {typeof children === 'function' ? children({ close: () => setOpen(false) }) : children}
        </div>
      )}
    </div>
  );
}

export default Popover;
