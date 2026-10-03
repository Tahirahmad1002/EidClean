// src/components/ui/Select.jsx
import { forwardRef, useId } from 'react'
import { ChevronDown } from 'lucide-react'
import { cn } from '../../lib/utils'

const Select = forwardRef(
  (
    {
      label,
      error,
      hint,
      leftIcon: LeftIcon,
      placeholder,
      options,
      required,
      disabled,
      className,
      wrapperClassName,
      id,
      children,
      ...props
    },
    ref
  ) => {
    const generatedId = useId()
    const selectId = id || generatedId
    const messageId = `${selectId}-message`
    const hasError = Boolean(error)

    return (
      <div className={cn('w-full', wrapperClassName)}>
        {label && (
          <label
            htmlFor={selectId}
            className="mb-1.5 block text-sm font-medium text-slate-900"
          >
            {label}
            {required && <span className="ml-0.5 text-red-500">*</span>}
          </label>
        )}

        <div className="relative">
          {LeftIcon && (
            <span
              className={cn(
                'pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5',
                hasError ? 'text-red-400' : 'text-slate-500'
              )}
            >
              <LeftIcon className="h-4 w-4" aria-hidden="true" />
            </span>
          )}

          <select
            ref={ref}
            id={selectId}
            disabled={disabled}
            required={required}
            aria-invalid={hasError}
            aria-describedby={error || hint ? messageId : undefined}
            className={cn(
              'block w-full appearance-none rounded-lg border bg-white py-2.5 pr-10 text-sm text-slate-900 shadow-sm transition-colors duration-150',
              'focus:outline-none focus:ring-2 focus:ring-offset-0',
              'disabled:cursor-not-allowed disabled:bg-slate-50 disabled:text-slate-500',
              LeftIcon ? 'pl-10' : 'pl-3.5',
              hasError
                ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20'
                : 'border-slate-200 hover:border-slate-300 focus:border-emerald-500 focus:ring-emerald-500/20',
              className
            )}
            {...props}
          >
            {placeholder && (
              <option value="" disabled>
                {placeholder}
              </option>
            )}
            {options
              ? options.map((option) => (
                  <option
                    key={option.value}
                    value={option.value}
                    disabled={option.disabled}
                  >
                    {option.label}
                  </option>
                ))
              : children}
          </select>

          <span
            className={cn(
              'pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3.5',
              hasError ? 'text-red-500' : 'text-slate-500'
            )}
          >
            <ChevronDown className="h-4 w-4" aria-hidden="true" />
          </span>
        </div>

        {(error || hint) && (
          <p
            id={messageId}
            className={cn(
              'mt-1.5 text-xs',
              hasError ? 'text-red-500' : 'text-slate-500'
            )}
          >
            {error || hint}
          </p>
        )}
      </div>
    )
  }
)

Select.displayName = 'Select'

export default Select