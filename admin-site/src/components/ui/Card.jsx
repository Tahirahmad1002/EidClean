import { forwardRef } from 'react'
import { cn } from '../../lib/utils'

const paddings = {
  none: '',
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8',
}

export function CardHeader({ title, description, action, className, children, ...props }) {
  return (
    <div
      className={cn(
        'flex items-center justify-between gap-4 border-b border-border px-6 py-4',
        className
      )}
      {...props}
    >
      {children ?? (
        <>
          <div className="min-w-0">
            {title && (
              <h3 className="truncate text-base font-semibold tracking-tight text-text">
                {title}
              </h3>
            )}
            {description && (
              <p className="mt-0.5 text-sm text-text-muted">{description}</p>
            )}
          </div>
          {action && <div className="flex shrink-0 items-center gap-2">{action}</div>}
        </>
      )}
    </div>
  )
}

export function CardBody({ className, children, ...props }) {
  return (
    <div className={cn('p-6', className)} {...props}>
      {children}
    </div>
  )
}

export function CardFooter({ className, children, ...props }) {
  return (
    <div
      className={cn(
        'flex items-center justify-end gap-3 border-t border-border bg-slate-50/70 px-6 py-4',
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

const Card = forwardRef(function Card(
  { header, footer, padding = 'md', hoverable = false, className, children, ...props },
  ref
) {
  const padClass = paddings[padding] ?? paddings.md
  const hasSections = Boolean(header || footer)

  return (
    <div
      ref={ref}
      className={cn(
        'rounded-lg border border-border bg-surface shadow-card',
        hoverable &&
          'transition-shadow duration-150 hover:border-slate-300 hover:shadow-card-hover',
        hasSections ? 'overflow-hidden' : padClass,
        className
      )}
      {...props}
    >
      {hasSections ? (
        <>
          {header &&
            (typeof header === 'string' ? <CardHeader title={header} /> : header)}
          <div className={padClass}>{children}</div>
          {footer && footer}
        </>
      ) : (
        children
      )}
    </div>
  )
})

export default Card