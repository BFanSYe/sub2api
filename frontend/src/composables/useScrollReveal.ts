import { onBeforeUnmount, onMounted } from 'vue'

/**
 * Lightweight scroll-reveal composable.
 *
 * On mount, finds every descendant with `[data-reveal]` inside the host scope
 * (defaults to the document) and toggles `.is-revealed` on it the first time
 * the element enters the viewport. Pair with CSS like:
 *
 *   [data-reveal]      { opacity: 0; transform: translateY(24px);
 *                        transition: opacity .7s var(--ease-spring),
 *                                    transform .7s var(--ease-spring); }
 *   [data-reveal].is-revealed { opacity: 1; transform: none; }
 *
 * `data-reveal-delay="120"` adds a per-element delay in ms.
 * `data-reveal-once="false"` keeps the element observable (re-reveals on
 * re-entry); default behavior is observe-once.
 */
export function useScrollReveal(rootSelector?: string) {
  let observer: IntersectionObserver | null = null

  function scan() {
    const root: ParentNode = rootSelector
      ? document.querySelector(rootSelector) ?? document
      : document
    const nodes = root.querySelectorAll<HTMLElement>('[data-reveal]')
    nodes.forEach((el) => observer?.observe(el))
  }

  onMounted(() => {
    if (typeof IntersectionObserver === 'undefined') {
      // Fallback: just reveal everything immediately.
      document
        .querySelectorAll<HTMLElement>('[data-reveal]')
        .forEach((el) => el.classList.add('is-revealed'))
      return
    }

    observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          const el = entry.target as HTMLElement
          const delay = Number(el.dataset.revealDelay ?? '0')
          if (delay > 0) {
            window.setTimeout(() => el.classList.add('is-revealed'), delay)
          } else {
            el.classList.add('is-revealed')
          }
          if (el.dataset.revealOnce !== 'false') {
            observer?.unobserve(el)
          }
        })
      },
      // Reveal modestly before the card is fully inside the viewport. This
      // keeps large homepage sections from looking blank while preserving a
      // visible fade-in as the user scrolls into the content.
      { threshold: 0.08, rootMargin: '0px 0px 5% 0px' }
    )

    scan()
  })

  onBeforeUnmount(() => {
    observer?.disconnect()
    observer = null
  })
}
