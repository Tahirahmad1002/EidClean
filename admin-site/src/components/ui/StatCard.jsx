// src/components/ui/StatCard.jsx
import { forwardRef } from 'react'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { cn } from '../../lib/utils'

const iconVariants = {
  green: 'bg-emerald-50 text-emerald-600',
  teal: 'bg-teal-50 text-teal-600',
  yellow: 'bg-amber-50 text-amber-600',
  red: 'bg-red-50 text-red-600',
  blue: 'bg-blue-50 text-blue-600',
  gray: 'bg-slate-100 text-slate-600',
}

const trendStyles = {
  up: { icon: TrendingUp, color: 'text-emerald-600' },
  down: { icon: TrendingDown, color: 'text-red-600' },
  neutral: { icon: Minus, color: 'text-slate-500' },
}

const StatCard = forwardRef(
  (
    {
      label,
      value,
      icon: Icon,
      variant = 'green',
      trend,
      trendLabel,
      description,
      loading = false,
      className,
      ...props
    },
    ref
  ) => {
    const direction = trend?.direction ?? 'neutral'
    const TrendIcon = (trendStyles[direction] ?? trendStyles.neutral).icon
    const trendColor = (trendStyles[direction] ?? trendStyles.neutral).color

    return (
      <div
        ref={ref}
        className={cn(
          'rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-shadow duration-150 hover:shadow-md',
          className
        )}
        {...props}
      >
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium text-slate-500">
              {label}
            </p>

            {loading ? (
              <div className="mt-2 h-8 w-24 animate-pulse rounded-md bg-slate-100" />
            ) : (
              <p className="mt-1.5 text-3xl font-semibold tracking-tight text-slate-900">
                {value}
              </p>
            )}
          </div>

          {Icon && (
            <div
              className={cn(
                'flex h-11 w-11 shrink-0 items-center justify-center rounded-lg',
                iconVariants[variant] ?? iconVariants.green
              )}
            >
              <Icon className="h-5 w-5" aria-hidden="true" />
            </div>
          )}
        </div>

        {(trend || description) && !loading && (
          <div className="mt-4 flex items-center gap-2 text-xs">
            {trend && (
              <span
                className={cn(
                  'inline-flex items-center gap-1 font-medium',
                  trendColor
                )}
              >
                <TrendIcon className="h-3.5 w-3.5" aria-hidden="true" />
                {trend.value}
              </span>
            )}
            {(trendLabel || description) && (
              <span className="truncate text-slate-500">
                {trendLabel || description}
              </span>
            )}
          </div>
        )}
      </div>
    )
  }
)

StatCard.displayName = 'StatCard'

export default StatCard