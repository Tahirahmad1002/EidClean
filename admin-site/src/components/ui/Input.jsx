// src/components/ui/Input.jsx
import { forwardRef, useId } from 'react'
import { AlertCircle } from 'lucide-react'
import { cn } from '../../lib/utils'

const Input = forwardRef(
  (
    {
      label,
      error,
      hint,
      leftIcon: LeftIcon,
      rightIcon: RightIcon,
      required,
      disabled,
      className,
      wrapperClassName,
      id,
      type = 'text',
      ...props
    },
    ref
  ) => {
    const generatedId = useId()
    const inputId = id || generatedId
    const messageId = `${inputId}-message`
    const hasError = Boolean(error)

    return (
      <div className={cn('w-full', wrapperClassName)}>
        {label && (
          <label
            htmlFor={inputId}
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

          <input
            ref={ref}
            id={inputId}
            type={type}
            disabled={disabled}
            required={required}
            aria-invalid={hasError}
            aria-describedby={error || hint ? messageId : undefined}
            className={cn(
              'block w-full rounded-lg border bg-white py-2.5 text-sm text-slate-900 shadow-sm transition-colors duration-150',
              'placeholder:text-slate-400',
              'focus:outline-none focus:ring-2 focus:ring-offset-0',
              'disabled:cursor-not-allowed disabled:bg-slate-50 disabled:text-slate-500',
              LeftIcon ? 'pl-10' : 'pl-3.5',
              RightIcon || hasError ? 'pr-10' : 'pr-3.5',
              hasError
                ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20'
                : 'border-slate-200 hover:border-slate-300 focus:border-emerald-500 focus:ring-emerald-500/20',
              className
            )}
            {...props}
          />

          {(RightIcon || hasError) && (
            <span
              className={cn(
                'pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3.5',
                hasError ? 'text-red-500' : 'text-slate-500'
              )}
            >
              {hasError ? (
                <AlertCircle className="h-4 w-4" aria-hidden="true" />
              ) : (
                <RightIcon className="h-4 w-4" aria-hidden="true" />
              )}
            </span>
          )}
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

Input.displayName = 'Input'

export default Input