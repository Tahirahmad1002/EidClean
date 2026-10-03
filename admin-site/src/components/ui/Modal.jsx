// src/components/ui/Modal.jsx
import { forwardRef, useCallback, useEffect, useId, useRef } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import { cn } from '../../lib/utils'

const sizes = {
  sm: 'max-w-sm',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
}

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled]):not([type="hidden"])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(',')

const Modal = forwardRef(
  (
    {
      open = false,
      onClose,
      title,
      description,
      size = 'md',
      closeOnBackdrop = true,
      closeOnEscape = true,
      showCloseButton = true,
      initialFocusRef,
      className,
      children,
      ...props
    },
    ref
  ) => {
    const titleId = useId()
    const descriptionId = useId()
    const panelRef = useRef(null)
    const previousFocusRef = useRef(null)
    const onCloseRef = useRef(onClose)

    // Keep the latest onClose without re-running the open/close effect
    useEffect(() => {
      onCloseRef.current = onClose
    }, [onClose])

    const setRefs = useCallback(
      (node) => {
        panelRef.current = node
        if (typeof ref === 'function') ref(node)
        else if (ref) ref.current = node
      },
      [ref]
    )

    // Scroll lock + focus management
    useEffect(() => {
      if (!open) return undefined

      previousFocusRef.current = document.activeElement
      const previousOverflow = document.body.style.overflow
      document.body.style.overflow = 'hidden'

      const frame = requestAnimationFrame(() => {
        const panel = panelRef.current
        if (!panel) return
        const target =
          initialFocusRef?.current ||
          panel.querySelector(FOCUSABLE_SELECTOR) ||
          panel
        target.focus()
      })

      return () => {
        cancelAnimationFrame(frame)
        document.body.style.overflow = previousOverflow
        const previous = previousFocusRef.current
        if (previous && typeof previous.focus === 'function') previous.focus()
      }
    }, [open, initialFocusRef])

    // Escape key + focus trap
    useEffect(() => {
      if (!open) return undefined

      const handleKeyDown = (event) => {
        if (event.key === 'Escape' && closeOnEscape) {
          event.stopPropagation()
          onCloseRef.current?.()
          return
        }

        if (event.key !== 'Tab') return

        const panel = panelRef.current
        if (!panel) return

        const focusable = Array.from(
          panel.querySelectorAll(FOCUSABLE_SELECTOR)
        ).filter((el) => el.offsetParent !== null)

        if (focusable.length === 0) {
          event.preventDefault()
          panel.focus()
          return
        }

        const first = focusable[0]
        const last = focusable[focusable.length - 1]
        const active = document.activeElement

        if (event.shiftKey && (active === first || active === panel)) {
          event.preventDefault()
          last.focus()
        } else if (!event.shiftKey && active === last) {
          event.preventDefault()
          first.focus()
        }
      }

      document.addEventListener('keydown', handleKeyDown)
      return () => document.removeEventListener('keydown', handleKeyDown)
    }, [open, closeOnEscape])

    if (!open) return null

    return createPortal(
      <div className="fixed inset-0 z-50 flex items-end justify-center p-4 sm:items-center">
        <div
          className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm"
          aria-hidden="true"
          onMouseDown={() => closeOnBackdrop && onCloseRef.current?.()}
        />

        <div
          ref={setRefs}
          role="dialog"
          aria-modal="true"
          aria-labelledby={title ? titleId : undefined}
          aria-describedby={description ? descriptionId : undefined}
          tabIndex={-1}
          className={cn(
            'relative flex max-h-[calc(100vh-2rem)] w-full flex-col rounded-xl border border-slate-200 bg-white shadow-xl focus:outline-none',
            sizes[size] ?? sizes.md,
            className
          )}
          {...props}
        >
          {showCloseButton && (
            <button
              type="button"
              onClick={() => onCloseRef.current?.()}
              aria-label="Close dialog"
              className="absolute right-4 top-4 rounded-lg p-1.5 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/30"
            >
              <X className="h-5 w-5" aria-hidden="true" />
            </button>
          )}

          {(title || description) && (
            <div className="border-b border-slate-200 px-6 py-5 pr-14">
              {title && (
                <h2
                  id={titleId}
                  className="text-lg font-semibold tracking-tight text-slate-900"
                >
                  {title}
                </h2>
              )}
              {description && (
                <p
                  id={descriptionId}
                  className="mt-1 text-sm text-slate-500"
                >
                  {description}
                </p>
              )}
            </div>
          )}

          {children}
        </div>
      </div>,
      document.body
    )
  }
)

Modal.displayName = 'Modal'

export const ModalBody = forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex-1 overflow-y-auto px-6 py-5', className)}
    {...props}
  />
))

ModalBody.displayName = 'ModalBody'

export const ModalFooter = forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'flex items-center justify-end gap-3 rounded-b-xl border-t border-slate-200 bg-slate-50/60 px-6 py-4',
      className
    )}
    {...props}
  />
))

ModalFooter.displayName = 'ModalFooter'

export default Modal