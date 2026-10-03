// src/components/ui/Table.jsx
import { createContext, forwardRef, useContext } from 'react'
import { ArrowDown, ArrowUp, ChevronsUpDown } from 'lucide-react'
import { cn } from '../../lib/utils'
import EmptyState from './EmptyState'

const TableContext = createContext({
  striped: false,
  hoverable: true,
  dense: false,
})

const SectionContext = createContext('body')

const Table = forwardRef(
  (
    {
      striped = false,
      hoverable = true,
      dense = false,
      wrapperClassName,
      className,
      children,
      ...props
    },
    ref
  ) => {
    return (
      <TableContext.Provider value={{ striped, hoverable, dense }}>
        <div
          className={cn(
            'w-full overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-sm',
            wrapperClassName
          )}
        >
          <table
            ref={ref}
            className={cn('w-full border-collapse text-left', className)}
            {...props}
          >
            {children}
          </table>
        </div>
      </TableContext.Provider>
    )
  }
)

Table.displayName = 'Table'

export const TableHeader = forwardRef(({ className, ...props }, ref) => (
  <SectionContext.Provider value="head">
    <thead
      ref={ref}
      className={cn('border-b border-slate-200 bg-slate-50', className)}
      {...props}
    />
  </SectionContext.Provider>
))

TableHeader.displayName = 'TableHeader'

export const TableBody = forwardRef(({ className, ...props }, ref) => (
  <SectionContext.Provider value="body">
    <tbody
      ref={ref}
      className={cn('divide-y divide-slate-200', className)}
      {...props}
    />
  </SectionContext.Provider>
))

TableBody.displayName = 'TableBody'

export const TableRow = forwardRef(({ className, ...props }, ref) => {
  const { striped, hoverable } = useContext(TableContext)
  const section = useContext(SectionContext)
  const isBody = section === 'body'

  return (
    <tr
      ref={ref}
      className={cn(
        'transition-colors duration-150',
        isBody && striped && 'even:bg-slate-50/70',
        isBody && hoverable && 'hover:bg-emerald-50/50',
        className
      )}
      {...props}
    />
  )
})

TableRow.displayName = 'TableRow'

const sortIcons = {
  asc: ArrowUp,
  desc: ArrowDown,
}

const ariaSort = {
  asc: 'ascending',
  desc: 'descending',
}

export const TableHead = forwardRef(
  (
    {
      sortable = false,
      sortDirection = null,
      onSort,
      align = 'left',
      className,
      children,
      ...props
    },
    ref
  ) => {
    const { dense } = useContext(TableContext)
    const SortIcon = sortIcons[sortDirection] ?? ChevronsUpDown

    const alignment = {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    }[align]

    const justify = {
      left: 'justify-start',
      center: 'justify-center',
      right: 'justify-end',
    }[align]

    return (
      <th
        ref={ref}
        scope="col"
        aria-sort={sortable ? ariaSort[sortDirection] ?? 'none' : undefined}
        className={cn(
          'whitespace-nowrap px-4 text-xs font-semibold uppercase tracking-wide text-slate-500',
          dense ? 'py-2.5' : 'py-3',
          alignment,
          className
        )}
        {...props}
      >
        {sortable ? (
          <button
            type="button"
            onClick={onSort}
            className={cn(
              'group inline-flex w-full items-center gap-1.5 rounded uppercase tracking-wide transition-colors hover:text-slate-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30',
              justify,
              sortDirection && 'text-slate-900'
            )}
          >
            {children}
            <SortIcon
              className={cn(
                'h-3.5 w-3.5 shrink-0 transition-colors',
                sortDirection
                  ? 'text-emerald-600'
                  : 'text-slate-400 group-hover:text-slate-600'
              )}
              aria-hidden="true"
            />
          </button>
        ) : (
          children
        )}
      </th>
    )
  }
)

TableHead.displayName = 'TableHead'

export const TableCell = forwardRef(
  ({ align = 'left', className, ...props }, ref) => {
    const { dense } = useContext(TableContext)

    const alignment = {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    }[align]

    return (
      <td
        ref={ref}
        className={cn(
          'px-4 text-sm text-slate-700',
          dense ? 'py-2.5' : 'py-3.5',
          alignment,
          className
        )}
        {...props}
      />
    )
  }
)

TableCell.displayName = 'TableCell'

export const TableEmpty = forwardRef(
  (
    { colSpan = 1, icon, title = 'No results found', description, className, children, ...props },
    ref
  ) => (
    <tr ref={ref} {...props}>
      <td colSpan={colSpan} className={cn('px-4', className)}>
        <EmptyState
          icon={icon}
          title={title}
          description={description}
          bordered={false}
          size="md"
        >
          {children}
        </EmptyState>
      </td>
    </tr>
  )
)

TableEmpty.displayName = 'TableEmpty'

export default Table