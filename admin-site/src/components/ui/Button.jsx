import { forwardRef } from 'react'
import { LoaderCircle } from 'lucide-react'
import { cn } from '../../lib/utils'

const base =
  'inline-flex items-center justify-center gap-2 whitespace-nowrap select-none ' +
  'rounded-md border border-transparent font-medium transition-colors duration-150 ' +
  'focus-visible:outline-none focus-visible:shadow-focus ' +
  'disabled:cursor-not-allowed disabled:opacity-50'

const variants = {
  primary:
    'bg-primary text-white shadow-sm hover:bg-primary-dark active:bg-primary-700',
  secondary:
    'bg-secondary text-white shadow-sm hover:bg-secondary-dark active:bg-secondary-dark',
  outline:
    'border-border bg-surface text-text hover:border-slate-300 hover:bg-slate-50 active:bg-slate-100',
  danger:
    'bg-danger text-white shadow-sm hover:bg-danger-dark active:bg-danger-dark',
  ghost: 'text-text-muted hover:bg-slate-100 hover:text-text active:bg-slate-200',
}

const sizes = {
  sm: 'h-8 px-3 text-xs',
  md: 'h-10 px-4 text-sm',
  lg: 'h-12 px-6 text-base',
}

const iconSizes = {
  sm: 'h-3.5 w-3.5',
  md: 'h-4 w-4',
  lg: 'h-5 w-5',
}

const Button = forwardRef(function Button(
  {
    variant = 'primary',
    size = 'md',
    leftIcon: LeftIcon,
    rightIcon: RightIcon,
    loading = false,
    fullWidth = false,
    className,
    disabled,
    children,
    ...props
  },
  ref
) {
  const iconClass = iconSizes[size] ?? iconSizes.md

  return (
    <button
      ref={ref}
      disabled={disabled || loading}
      className={cn(
        base,
        variants[variant] ?? variants.primary,
        sizes[size] ?? sizes.md,
        fullWidth && 'w-full',
        className
      )}
      {...props}
    >
      {loading ? (
        <LoaderCircle className={cn(iconClass, 'animate-spin')} aria-hidden="true" />
      ) : (
        LeftIcon && <LeftIcon className={iconClass} aria-hidden="true" />
      )}
      {children}
      {!loading && RightIcon && (
        <RightIcon className={iconClass} aria-hidden="true" />
      )}
    </button>
  )
})

export default Button