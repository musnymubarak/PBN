import React, { useState, useEffect, useRef } from 'react';
import { IconChevronDown, IconSearch } from '@tabler/icons-react';
import { cx } from './classNames';

/**
 * Drop-in replacement for the legacy CustomSelect / SearchableSelect.
 *
 * Props:
 *  - value, onChange(id)
 *  - options: [{ id, name, label?, email? }]
 *  - placeholder
 *  - searchable: boolean
 *  - disabledOptions: string[] of ids
 *  - size: 'sm' | 'md' | 'lg'
 *  - allowClear: boolean
 */
export function Select({
  value,
  onChange,
  options = [],
  placeholder = 'Select…',
  searchable = false,
  disabledOptions = [],
  size = 'md',
  allowClear = false,
  className,
  style,
  disabled = false,
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const ref = useRef(null);

  useEffect(() => {
    function onDocClick(e) {
      if (ref.current && !ref.current.contains(e.target)) setIsOpen(false);
    }
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, []);

  const selected = options.find(o => String(o.id) === String(value));
  const filtered = searchable && search
    ? options.filter(o =>
        (o.name || o.label || '').toLowerCase().includes(search.toLowerCase()) ||
        (o.email || '').toLowerCase().includes(search.toLowerCase()),
      )
    : options;

  return (
    <div ref={ref} className={cx('ds-select', className)} style={style}>
      <button
        type="button"
        disabled={disabled}
        className={cx(
          'ds-select-trigger',
          size !== 'md' && `ds-select-trigger--${size}`,
          isOpen && 'is-open',
        )}
        onClick={() => setIsOpen(o => !o)}
      >
        <span
          className={cx(
            'ds-select-trigger__value',
            !selected && 'ds-select-trigger__value--placeholder',
          )}
        >
          {selected ? (selected.name || selected.label) : placeholder}
        </span>
        <IconChevronDown size={16} className="ds-select-trigger__chevron" />
      </button>

      {isOpen && (
        <div className="ds-select-menu" role="listbox">
          {searchable && (
            <div className="ds-select-search">
              <div className="ds-input-group ds-input-group--with-left">
                <span className="ds-input-group__icon ds-input-group__icon--left">
                  <IconSearch size={14} />
                </span>
                <input
                  className="ds-input ds-input--sm"
                  placeholder="Search…"
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                  autoFocus
                  onClick={e => e.stopPropagation()}
                />
              </div>
            </div>
          )}

          {allowClear && (
            <div
              className="ds-select-option"
              onClick={() => { onChange(''); setIsOpen(false); setSearch(''); }}
            >
              <span style={{ color: 'var(--fg-muted)' }}>{placeholder}</span>
            </div>
          )}

          {filtered.length === 0 ? (
            <div className="ds-select-empty">No results</div>
          ) : (
            filtered.map(opt => {
              const isDisabled = disabledOptions.includes(String(opt.id));
              const isSelected = String(value) === String(opt.id);
              return (
                <div
                  key={opt.id}
                  role="option"
                  aria-selected={isSelected}
                  className={cx(
                    'ds-select-option',
                    isSelected && 'is-selected',
                    isDisabled && 'is-disabled',
                  )}
                  onClick={() => {
                    if (isDisabled) return;
                    onChange(opt.id);
                    setIsOpen(false);
                    setSearch('');
                  }}
                >
                  <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {opt.name || opt.label}
                    </span>
                    {opt.email && (
                      <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                        {opt.email}
                      </span>
                    )}
                  </span>
                  {isDisabled && <span className="ds-select-option__hint">Occupied</span>}
                </div>
              );
            })
          )}
        </div>
      )}
    </div>
  );
}

export default Select;
