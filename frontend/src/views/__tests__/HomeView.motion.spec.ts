import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

import { describe, expect, it } from 'vitest'

const testDir = dirname(fileURLToPath(import.meta.url))
const homeViewSource = readFileSync(resolve(testDir, '../HomeView.vue'), 'utf8')
const themeSource = readFileSync(resolve(testDir, '../../styles/theme-1node.css'), 'utf8')

describe('HomeView reduced-motion motion policy', () => {
  it('keeps scroll reveal transitions active on the marketing homepage', () => {
    expect(homeViewSource).not.toMatch(
      /@media\s*\(prefers-reduced-motion:\s*reduce\)[\s\S]*?\.hv\s+\[data-reveal\]\s*\{[^}]*transition\s*:\s*none/
    )
  })

  it('does not let the 1Node reduced-motion guard disable HomeView animations', () => {
    expect(themeSource).toContain('.theme-1node:not(.hv) *')
    expect(themeSource).not.toMatch(/\.theme-1node\s+\*,/)
  })
})

describe('HomeView pointer-only hover policy', () => {
  it('gates .hv-pain-card hover effects behind (hover: hover) and (pointer: fine)', () => {
    // The three :hover rules must live inside a hover-capable media query
    // to avoid iOS Safari sticky-hover keeping the ::before teal halo visible.
    expect(homeViewSource).toMatch(
      /@media\s*\(hover:\s*hover\)\s+and\s+\(pointer:\s*fine\)\s*\{[\s\S]*?\.hv-pain-card:hover\s*\{[\s\S]*?\.hv-pain-card:hover::before[\s\S]*?\.hv-pain-card:hover\s+\.hv-pain-card__icon[\s\S]*?\}\s*\}/
    )
  })

  it('does not leave any .hv-pain-card:hover rule outside a hover-capable media query', () => {
    // Find every .hv-pain-card:hover occurrence and confirm each one is
    // preceded (within the file) by an opening `@media (hover: hover) ... {`
    // that has not yet been closed.
    const lines = homeViewSource.split('\n')
    let inHoverGate = 0 // depth counter
    let openBraces = 0
    let lineIdx = 0
    for (const line of lines) {
      lineIdx++
      if (/@media\s*\(hover:\s*hover\)\s+and\s+\(pointer:\s*fine\)\s*\{/.test(line)) {
        inHoverGate++
        // Count braces on the same line so single-line blocks like
        // `@media (hover: hover) and (pointer: fine) { .x:hover {} }` close cleanly.
        openBraces += (line.match(/\{/g) || []).length
        openBraces -= (line.match(/\}/g) || []).length
        if (openBraces <= 0) {
          inHoverGate--
          openBraces = 0
        }
        continue
      }
      if (inHoverGate > 0) {
        openBraces += (line.match(/\{/g) || []).length
        openBraces -= (line.match(/\}/g) || []).length
        if (openBraces <= 0) {
          inHoverGate--
          openBraces = 0
        }
      }
      if (/\.hv-pain-card:hover/.test(line)) {
        expect(inHoverGate, `line ${lineIdx} has .hv-pain-card:hover outside hover-gated @media`).toBeGreaterThan(0)
      }
    }
  })
})
