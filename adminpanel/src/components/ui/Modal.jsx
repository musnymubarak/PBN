import React, { useEffect } from 'react';
import { IconX } from '@tabler/icons-react';
import { IconButton } from './IconButton';
import { cx } from './classNames';

/**
 * Modern modal primitive.
 *
 * Compose with <Modal.Header>, <Modal.Body>, <Modal.Footer> or pass children directly.
 */
export function Modal({
  open = true,
  onClose,
  size = 'md',
  className,
  closeOnBackdrop = true,
  children,
}) {
  useEffect(() => {
    if (!open) return;
    function onKey(e) {
      if (e.key === 'Escape' && onClose) onClose();
    }
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="ds-modal-overlay"
      onClick={(e) => {
        if (closeOnBackdrop && e.target === e.currentTarget && onClose) onClose();
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        className={cx('ds-modal', `ds-modal--${size}`, className)}
        onClick={e => e.stopPropagation()}
      >
        {children}
      </div>
    </div>
  );
}

function ModalHeader({ title, subtitle, onClose, actions, children }) {
  return (
    <header className="ds-modal__header">
      <div style={{ minWidth: 0, flex: 1 }}>
        {children || (
          <>
            {title && <h2 className="ds-modal__title">{title}</h2>}
            {subtitle && <p className="ds-modal__subtitle">{subtitle}</p>}
          </>
        )}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
        {actions}
        {onClose && (
          <IconButton onClick={onClose} aria-label="Close">
            <IconX size={18} />
          </IconButton>
        )}
      </div>
    </header>
  );
}

function ModalBody({ className, children }) {
  return <div className={cx('ds-modal__body', className)}>{children}</div>;
}

function ModalFooter({ className, children }) {
  return <footer className={cx('ds-modal__footer', className)}>{children}</footer>;
}

Modal.Header = ModalHeader;
Modal.Body = ModalBody;
Modal.Footer = ModalFooter;

export default Modal;
