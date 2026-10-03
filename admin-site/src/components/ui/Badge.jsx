// src/components/ui/Badge.jsx
import { forwardRef } from 'react'
import { cn } from '../../lib/utils'

const variants = {
  green: 'bg-emerald-50 text-emerald-700 ring-emerald-600/20',
  red: 'bg-red-50 text-red-700 ring-red-600/20',
  yellow: 'bg-amber-50 text-amber-700 ring-amber-600/20',
  blue: 'bg-blue-50 text-blue-700 ring-blue-600/20',
  gray: 'bg-slate-100 text-slate-700 ring-slate-500/20',
  outline: 'bg-transparent text-slate-700 ring-slate-200',
}

const dotColors = {
  green: 'bg-emerald-500',
  red: 'bg-red-500',
  yellow: 'bg-amber-500',
  blue: 'bg-blue-500',
  gray: 'bg-slate-400',
  outline: 'bg-slate-400',
}

const sizes = {
  sm: 'px-2 py-0.5 text-xs',
  md: 'px-2.5 py-1 text-xs',
  lg: 'px-3 py-1 text-sm',
}

const Badge = forwardRef(
  (
    { variant = 'gray', size = 'md', dot = false, className, children, ...props },
    ref
  ) => {
    return (
      <span
        ref={ref}
        className={cn(
          'inline-flex items-center gap-1.5 whitespace-nowrap rounded-full font-medium ring-1 ring-inset',
          variants[variant] ?? variants.gray,
          sizes[size] ?? sizes.md,
          className
        )}
        {...props}
      >
        {dot && (
          <span
            className={cn(
              'h-1.5 w-1.5 rounded-full',
              dotColors[variant] ?? dotColors.gray
            )}
            aria-hidden="true"
          />
        )}
        {children}
      </span>
    )
  }
)

Badge.displayName = 'Badge'

export default Badge