import React from 'react'

interface CardProps {
  title: string
  icon?: string
  href?: string
  children?: React.ReactNode
}

interface CardGroupProps {
  cols?: number
  children?: React.ReactNode
}

export function Card({ title, href, children }: CardProps) {
  const inner = (
    <div style={{
      border: '1px solid var(--vocs-color_border)',
      borderRadius: '8px',
      padding: '16px 20px',
      display: 'flex',
      flexDirection: 'column',
      gap: '6px',
      height: '100%',
      transition: 'border-color 0.15s, background 0.15s',
    }}>
      <div style={{ fontWeight: 600, fontSize: '0.9rem' }}>{title}</div>
      {children && (
        <div style={{ fontSize: '0.85rem', opacity: 0.75, lineHeight: 1.5 }}>
          {children}
        </div>
      )}
    </div>
  )

  if (href) {
    return (
      <a
        href={href}
        style={{ textDecoration: 'none', color: 'inherit', display: 'block' }}
        onMouseEnter={(e) => {
          const div = e.currentTarget.firstChild as HTMLElement
          if (div) div.style.borderColor = 'var(--vocs-color_accentText)'
        }}
        onMouseLeave={(e) => {
          const div = e.currentTarget.firstChild as HTMLElement
          if (div) div.style.borderColor = 'var(--vocs-color_border)'
        }}
      >
        {inner}
      </a>
    )
  }

  return <div>{inner}</div>
}

export function CardGroup({ cols = 2, children }: CardGroupProps) {
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: `repeat(${cols}, 1fr)`,
      gap: '12px',
      margin: '20px 0',
    }}>
      {children}
    </div>
  )
}
