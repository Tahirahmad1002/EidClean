// src/components/ui/EmptyState.jsx
import { forwardRef } from 'react'
import { Inbox } from 'lucide-react'
import { cn } from '../../lib/utils'

const sizes = {
  sm: {
    wrapper: 'px-4 py-8',
    iconBox: 'h-10 w-10',
    icon: 'h-5 w-5',
    title: 'text-sm',
    description: 'text-xs',
  },
  md: {
    wrapper: 'px-6 py-12',
    iconBox: 'h-12 w-12',
    icon: 'h-6 w-6',
    title: 'text-base',
    description: 'text-sm',
  },
  lg: {
    wrapper: 'px-8 py-16',
    iconBox: 'h-16 w-16',
    icon: 'h-8 w-8',
    title: 'text-lg',
    description: 'text-sm',
  },
}

const iconVariants = {
  green: 'bg-emerald-50 text-emerald-600',
  yellow: 'bg-amber-50 text-amber-600',
  red: 'bg-red-50 text-red-600',
  blue: 'bg-blue-50 text-blue-600',
  gray: 'bg-slate-100 text-slate-500',
}

const EmptyState = forwardRef(
  (
    {
      icon: Icon = Inbox,
      title,
      description,
      variant = 'gray',
      size = 'md',
      bordered = true,
      className,
      children,
      ...props
    },
    ref
  ) => {
    const sizeConfig = sizes[size] ?? sizes.md

    return (
      <div
        ref={ref}
        className={cn(
          'flex flex-col items-center justify-center rounded-xl text-center',
          bordered && 'border border-dashed border-slate-200 bg-white',
          sizeConfig.wrapper,
          className
        )}
        {...props}
      >
        <div
          className={cn(
            'flex items-center justify-center rounded-full',
            sizeConfig.iconBox,
            iconVariants[variant] ?? iconVariants.gray
          )}
        >
          <Icon className={sizeConfig.icon} aria-hidden="true" />
        </div>

        {title && (
          <h3
            className={cn(
              'mt-4 font-semibold text-slate-900',
              sizeConfig.title
            )}
          >
            {title}
          </h3>
        )}

        {description && (
          <p
            className={cn(
              'mt-1.5 max-w-sm text-slate-500',
              sizeConfig.description
            )}
          >
            {description}
          </p>
        )}

        {children && (
          <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
            {children}
          </div>
        )}
      </div>
    )
  }
)

EmptyState.displayName = 'EmptyState'

export default EmptyState