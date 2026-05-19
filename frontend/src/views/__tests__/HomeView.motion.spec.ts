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
