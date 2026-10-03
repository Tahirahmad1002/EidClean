// src/components/ui/Avatar.jsx
import { forwardRef, useState } from 'react'
import { User } from 'lucide-react'
import { cn } from '../../lib/utils'

const sizes = {
  xs: { box: 'h-6 w-6 text-[10px]', icon: 'h-3 w-3', status: 'h-1.5 w-1.5' },
  sm: { box: 'h-8 w-8 text-xs', icon: 'h-4 w-4', status: 'h-2 w-2' },
  md: { box: 'h-10 w-10 text-sm', icon: 'h-5 w-5', status: 'h-2.5 w-2.5' },
  lg: { box: 'h-12 w-12 text-base', icon: 'h-6 w-6', status: 'h-3 w-3' },
  xl: { box: 'h-16 w-16 text-lg', icon: 'h-8 w-8', status: 'h-3.5 w-3.5' },
}

const statusColors = {
  online: 'bg-emerald-500',
  busy: 'bg-red-500',
  away: 'bg-amber-500',
  offline: 'bg-slate-400',
}

const tones = [
  'bg-emerald-100 text-emerald-700',
  'bg-teal-100 text-teal-700',
  'bg-amber-100 text-amber-700',
  'bg-blue-100 text-blue-700',
  'bg-red-100 text-red-700',
  'bg-slate-200 text-slate-700',
]

const getInitials = (name = '') => {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return ''
  if (parts.length === 1) return parts[0].charAt(0).toUpperCase()
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase()
}

const getTone = (name = '') => {
  let hash = 0
  for (let i = 0; i < name.length; i += 1) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash)
  }
  return tones[Math.abs(hash) % tones.length]
}

const Avatar = forwardRef(
  ({ src, alt, name, size = 'md', status, className, ...props }, ref) => {
    const [imageFailed, setImageFailed] = useState(false)
    const sizeConfig = sizes[size] ?? sizes.md
    const initials = getInitials(name)
    const showImage = src && !imageFailed

    return (
      <span
        ref={ref}
        className={cn('relative inline-flex shrink-0', className)}
        {...props}
      >
        <span
          className={cn(
            'inline-flex items-center justify-center overflow-hidden rounded-full font-semibold ring-2 ring-white',
            sizeConfig.box,
            !showImage && (initials ? getTone(name) : 'bg-slate-100 text-slate-500')
          )}
        >
          {showImage ? (
            <img
              src={src}
              alt={alt || name || 'Avatar'}
              onError={() => setImageFailed(true)}
              className="h-full w-full object-cover"
            />
          ) : initials ? (
            <span aria-label={name}>{initials}</span>
          ) : (
            <User className={sizeConfig.icon} aria-hidden="true" />
          )}
        </span>

        {status && (
          <span
            className={cn(
              'absolute bottom-0 right-0 rounded-full ring-2 ring-white',
              sizeConfig.status,
              statusColors[status] ?? statusColors.offline
            )}
            aria-label={status}
          />
        )}
      </span>
    )
  }
)

Avatar.displayName = 'Avatar'

export const AvatarGroup = forwardRef(
  ({ avatars = [], max = 4, size = 'md', className, ...props }, ref) => {
    const visible = avatars.slice(0, max)
    const remaining = avatars.length - visible.length
    const sizeConfig = sizes[size] ?? sizes.md

    return (
      <div
        ref={ref}
        className={cn('flex items-center -space-x-2', className)}
        {...props}
      >
        {visible.map((avatar, index) => (
          <Avatar key={avatar.id ?? avatar.name ?? index} size={size} {...avatar} />
        ))}
        {remaining > 0 && (
          <span
            className={cn(
              'inline-flex items-center justify-center rounded-full bg-slate-100 font-semibold text-slate-600 ring-2 ring-white',
              sizeConfig.box
            )}
          >
            +{remaining}
          </span>
        )}
      </div>
    )
  }
)

AvatarGroup.displayName = 'AvatarGroup'

export default Avatar