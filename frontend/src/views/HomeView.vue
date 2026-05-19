<template>
  <!-- Custom Home Content: Full Page Mode (admin override) -->
  <div v-if="homeContent" class="min-h-screen">
    <iframe
      v-if="isHomeContentUrl"
      :src="homeContent.trim()"
      class="h-screen w-full border-0"
      allowfullscreen
    ></iframe>
    <div v-else v-html="homeContent"></div>
  </div>

  <!-- Default Home Page — codex-inspired alternating layout -->
  <div v-else class="hv theme-1node" :class="{ 'hv--dark': isDark }">
    <!-- Ambient backdrop -->
    <div class="hv-bg" aria-hidden="true">
      <div class="hv-bg__blob hv-bg__blob--1"></div>
      <div class="hv-bg__blob hv-bg__blob--2"></div>
      <div class="hv-bg__blob hv-bg__blob--3"></div>
      <div class="hv-bg__blob hv-bg__blob--4"></div>
      <div class="hv-bg__grid"></div>
    </div>

    <!-- Header -->
    <header class="hv-header">
      <nav class="hv-header__inner">
        <a class="hv-brand" href="#top" :aria-label="siteName">
          <span class="hv-brand__mark">
            <span class="hv-brand__ring hv-brand__ring--outer" aria-hidden="true"></span>
            <span class="hv-brand__ring hv-brand__ring--inner" aria-hidden="true"></span>
            <img v-if="siteLogo" :src="siteLogo" alt="" />
            <span v-else class="hv-brand__dot"></span>
          </span>
          <span class="hv-brand__text">{{ siteName }}</span>
        </a>

        <div class="hv-header__actions">
          <LocaleSwitcher />

          <a
            v-if="docUrl"
            :href="docUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="hv-icon-btn"
            :title="t('home.viewDocs')"
            :aria-label="t('home.viewDocs')"
          >
            <Icon name="book" size="md" />
          </a>

          <button
            type="button"
            class="hv-icon-btn"
            @click="toggleTheme"
            :title="isDark ? t('home.switchToLight') : t('home.switchToDark')"
            :aria-label="isDark ? t('home.switchToLight') : t('home.switchToDark')"
          >
            <Icon v-if="isDark" name="sun" size="md" />
            <Icon v-else name="moon" size="md" />
          </button>

          <router-link
            v-if="isAuthenticated"
            :to="dashboardPath"
            class="hv-cta-pill"
          >
            <span class="hv-cta-pill__avatar">{{ userInitial }}</span>
            <span>{{ t('home.dashboard') }}</span>
            <Icon name="arrowRight" size="sm" />
          </router-link>
          <router-link v-else to="/login" class="hv-cta-pill hv-cta-pill--solid">
            {{ t('home.login') }}
            <Icon name="arrowRight" size="sm" />
          </router-link>
        </div>
      </nav>
    </header>

    <main class="hv-main">
      <!-- Hero -->
      <section class="hv-section hv-hero" id="top">
        <div class="hv-section__inner hv-hero__inner">
          <div class="hv-eyebrow-row" data-reveal>
            <span class="hv-eyebrow-row__line"></span>
            <span class="hv-eyebrow-row__brand">{{ siteName }}</span>
            <span class="hv-eyebrow-row__tag">/ AI GATEWAY</span>
          </div>

          <h1 class="hv-hero__title" data-reveal data-reveal-delay="120">
            <span class="hv-hero__title-line">{{ siteName }}</span>
            <span class="hv-hero__title-accent">{{ t('home.heroSubtitle') }}</span>
          </h1>

          <p class="hv-hero__lede-1" data-reveal data-reveal-delay="260">{{ t('home.heroLede') }}</p>
          <p class="hv-hero__lede-2" data-reveal data-reveal-delay="360">{{ t('home.heroDescription') }}</p>

          <div class="hv-hero__ctas" data-reveal data-reveal-delay="480">
            <router-link
              :to="isAuthenticated ? dashboardPath : '/login'"
              class="hv-btn hv-btn--solid"
            >
              <span>{{ isAuthenticated ? t('home.goToDashboard') : t('home.getStarted') }}</span>
              <span class="hv-btn__arrow">→</span>
            </router-link>
            <a
              v-if="docUrl"
              :href="docUrl"
              target="_blank"
              rel="noopener noreferrer"
              class="hv-btn hv-btn--outline"
            >
              <span>{{ t('home.docs') }}</span>
              <span class="hv-btn__arrow">↗</span>
            </a>
          </div>
        </div>
      </section>

      <!-- 00 — Pain points -->
      <section class="hv-section hv-section--bordered hv-pain">
        <div class="hv-section__inner">
          <header class="hv-block-head hv-block-head--center" data-reveal>
            <span class="hv-num-eyebrow hv-num-eyebrow--neutral">
              <span class="hv-num-eyebrow__dot"></span>
              <span>00 / FAMILIAR ?</span>
            </span>
            <h2 class="hv-block-title">{{ t('home.painPoints.title') }}</h2>
          </header>

          <div class="hv-pain__grid">
            <article
              v-for="(item, idx) in painItems"
              :key="item.key"
              class="hv-pain-card"
              :class="`hv-pain-card--${idx + 1}`"
              data-reveal
              :data-reveal-delay="idx * 100"
            >
              <span class="hv-pain-card__icon">
                <Icon :name="item.icon" size="lg" />
              </span>
              <h3 class="hv-pain-card__title">{{ t(`home.painPoints.items.${item.key}.title`) }}</h3>
              <p class="hv-pain-card__desc">{{ t(`home.painPoints.items.${item.key}.desc`) }}</p>
            </article>
          </div>
        </div>
      </section>

      <!-- 01 — Drop-in: text left, terminal right -->
      <section class="hv-section hv-section--bordered hv-feat-section">
        <div class="hv-section__inner hv-feat-grid">
          <div class="hv-feat-text" data-reveal>
            <span class="hv-num-eyebrow hv-num-eyebrow--c2">
              <span class="hv-num-eyebrow__dot"></span>
              <span>01 / INTEGRATE</span>
            </span>
            <h2 class="hv-feat-title">{{ t('home.features.unifiedGateway') }}</h2>
            <p class="hv-feat-tagline">{{ t('home.featureTaglines.integrate') }}</p>
            <p class="hv-feat-body">{{ t('home.features.unifiedGatewayDesc') }}</p>
          </div>

          <div class="hv-feat-visual" data-reveal data-reveal-delay="120">
            <span class="hv-feat-visual__halo" aria-hidden="true"></span>
            <div class="hv-terminal">
              <div class="hv-terminal__bar">
                <span class="hv-terminal__dot"></span>
                <span class="hv-terminal__dot"></span>
                <span class="hv-terminal__dot"></span>
                <span class="hv-terminal__title">curl ~ chat.completion</span>
              </div>
              <pre class="hv-terminal__body"><code><span class="t-cmd">curl</span> <span class="t-url">https://{{ apiHost }}/v1/chat/completions</span> \
  <span class="t-flag">-H</span> <span class="t-str">"Authorization: Bearer $SUB2API_KEY"</span> \
  <span class="t-flag">-H</span> <span class="t-str">"Content-Type: application/json"</span> \
  <span class="t-flag">-d</span> <span class="t-str">'{
    "model": "gpt-5.5",
    "messages": [{"role":"user","content":"Hi"}]
  }'</span></code></pre>
            </div>
          </div>
        </div>
      </section>

      <!-- 02 — Reliable: visual left, text right -->
      <section class="hv-section hv-section--bordered hv-feat-section">
        <div class="hv-section__inner hv-feat-grid hv-feat-grid--reverse">
          <div class="hv-feat-visual" data-reveal>
            <span class="hv-feat-visual__halo" aria-hidden="true"></span>
            <div class="hv-signal-panel">
              <div class="hv-signal-panel__label">service / signal</div>
              <svg viewBox="0 0 400 80" class="hv-signal-panel__wave" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="hvSigGrad" x1="0" y1="0" x2="1" y2="0">
                    <stop offset="0%" stop-color="#F5A5B8" />
                    <stop offset="50%" stop-color="#5DBED6" />
                    <stop offset="100%" stop-color="#F4C95D" />
                  </linearGradient>
                </defs>
                <path d="M0,40 L30,40 L40,30 L55,50 L70,38 L90,40 L120,40 L130,28 L145,52 L160,40 L200,40 L215,32 L228,48 L245,40 L290,40 L300,34 L315,46 L330,40 L400,40"
                      fill="none" stroke="url(#hvSigGrad)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              <div class="hv-signal-panel__pills">
                <div class="hv-signal-pill">
                  <span class="hv-signal-pill__title">Always-On</span>
                  <span class="hv-signal-pill__sub">always-on</span>
                </div>
                <div class="hv-signal-pill">
                  <span class="hv-signal-pill__title">Multi-Route</span>
                  <span class="hv-signal-pill__sub">multi-route</span>
                </div>
                <div class="hv-signal-pill">
                  <span class="hv-signal-pill__title">Maintained</span>
                  <span class="hv-signal-pill__sub">maintained</span>
                </div>
              </div>
              <div class="hv-signal-panel__rows">
                <div class="hv-signal-row" v-for="(row, ri) in signalRows" :key="ri">
                  <span class="hv-signal-row__name">{{ row.name }}</span>
                  <span class="hv-signal-row__status">
                    <span class="hv-signal-row__dot"></span>
                    <span class="hv-signal-row__latency">{{ row.latency }}</span>
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class="hv-feat-text" data-reveal data-reveal-delay="120">
            <span class="hv-num-eyebrow hv-num-eyebrow--c1">
              <span class="hv-num-eyebrow__dot"></span>
              <span>02 / RELIABLE</span>
            </span>
            <h2 class="hv-feat-title">{{ t('home.features.multiAccount') }}</h2>
            <p class="hv-feat-tagline">{{ t('home.featureTaglines.reliable') }}</p>
            <p class="hv-feat-body">{{ t('home.features.multiAccountDesc') }}</p>
          </div>
        </div>
      </section>

      <!-- 03 — Metered: text left, billing visual right -->
      <section class="hv-section hv-section--bordered hv-feat-section">
        <div class="hv-section__inner hv-feat-grid">
          <div class="hv-feat-text" data-reveal>
            <span class="hv-num-eyebrow hv-num-eyebrow--c3">
              <span class="hv-num-eyebrow__dot"></span>
              <span>03 / METERED</span>
            </span>
            <h2 class="hv-feat-title">{{ t('home.features.balanceQuota') }}</h2>
            <p class="hv-feat-tagline">{{ t('home.featureTaglines.metered') }}</p>
            <p class="hv-feat-body">{{ t('home.features.balanceQuotaDesc') }}</p>
          </div>

          <div class="hv-feat-visual" data-reveal data-reveal-delay="120">
            <span class="hv-feat-visual__halo" aria-hidden="true"></span>
            <div class="hv-billing-panel">
              <div class="hv-billing-panel__head">
                <span class="hv-billing-panel__label">usage / current cycle</span>
                <span class="hv-billing-panel__period">2026-05</span>
              </div>
              <div class="hv-billing-panel__balance">
                <span class="hv-billing-panel__balance-currency">¥</span>
                <span class="hv-billing-panel__balance-num">142.18</span>
                <span class="hv-billing-panel__balance-cap">/ 500.00</span>
              </div>
              <div class="hv-billing-panel__bar">
                <span class="hv-billing-panel__bar-fill"></span>
              </div>
              <ul class="hv-billing-panel__rows">
                <li v-for="(row, ri) in billingRows" :key="ri" class="hv-billing-row">
                  <span class="hv-billing-row__model">{{ row.model }}</span>
                  <span class="hv-billing-row__tokens">{{ row.tokens }}</span>
                  <span class="hv-billing-row__price">{{ row.price }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>
    </main>

    <!-- Footer -->
    <footer class="hv-footer">
      <div class="hv-section__inner hv-footer__inner">
        <p class="hv-footer__copy">
          &copy; {{ currentYear }} {{ siteName }}. {{ t('home.footer.allRightsReserved') }}
        </p>
        <a
          v-if="docUrl"
          :href="docUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="hv-footer__link"
        >
          {{ t('home.docs') }}
        </a>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore, useAppStore } from '@/stores'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import Icon from '@/components/icons/Icon.vue'
import { useScrollReveal } from '@/composables/useScrollReveal'

const { t } = useI18n()

const authStore = useAuthStore()
const appStore = useAppStore()

const siteName = computed(
  () => appStore.cachedPublicSettings?.site_name || appStore.siteName || 'Sub2API'
)
const siteLogo = computed(
  () => appStore.cachedPublicSettings?.site_logo || appStore.siteLogo || ''
)
const docUrl = computed(
  () => appStore.cachedPublicSettings?.doc_url || appStore.docUrl || ''
)
const homeContent = computed(() => appStore.cachedPublicSettings?.home_content || '')

const isHomeContentUrl = computed(() => {
  const content = homeContent.value.trim()
  return content.startsWith('http://') || content.startsWith('https://')
})

const isDark = ref(document.documentElement.classList.contains('dark'))

// Display the real deployment host in the curl example. Falls back to a
// generic placeholder during SSR / unusual environments.
const apiHost = typeof window !== 'undefined' ? window.location.host : 'your-domain.com'

const isAuthenticated = computed(() => authStore.isAuthenticated)
const isAdmin = computed(() => authStore.isAdmin)
const dashboardPath = computed(() => (isAdmin.value ? '/admin/dashboard' : '/dashboard'))
const userInitial = computed(() => {
  const user = authStore.user
  if (!user || !user.email) return ''
  return user.email.charAt(0).toUpperCase()
})

const currentYear = computed(() => new Date().getFullYear())

const painItems = [
  { key: 'expensive', icon: 'creditCard' as const },
  { key: 'complex', icon: 'grid' as const },
  { key: 'unstable', icon: 'bolt' as const },
  { key: 'noControl', icon: 'chart' as const }
]

const signalRows = [
  { name: 'GPT-5.5', latency: '3.14 ms' },
  { name: 'GPT-5.4', latency: 'healthy' },
  { name: 'Claude Opus 4.7', latency: 'healthy' },
  { name: 'Claude Sonnet 4.6', latency: 'healthy' }
]

const billingRows = [
  { model: 'GPT-5.5', tokens: '1,820 tok', price: '¥0.18' },
  { model: 'GPT-5.4', tokens: '3,210 tok', price: '¥0.21' },
  { model: 'Claude Opus 4.7', tokens: '980 tok', price: '¥0.42' },
  { model: 'Claude Sonnet 4.6', tokens: '2,140 tok', price: '¥0.16' }
]

function toggleTheme() {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
  localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
}

function initTheme() {
  isDark.value = document.documentElement.classList.contains('dark')
}

useScrollReveal()

onMounted(() => {
  initTheme()
  authStore.checkAuth()
  if (!appStore.publicSettingsLoaded) {
    appStore.fetchPublicSettings()
  }
})
</script>

<style scoped>
/* ============================================================
   HomeView — codex-inspired editorial layout.
   Tokens come from theme-1node.css.
   ============================================================ */

.hv {
  position: relative;
  min-height: 100vh;
  overflow-x: clip;
  color: var(--t-txt-200);
  background: var(--t-bg);
  font-family: var(--f-body);
}
.hv-main { position: relative; z-index: 10; }

/* ----- Scroll-reveal primitives ----- */
.hv [data-reveal] {
  opacity: 0;
  transform: translateY(28px);
  transition:
    opacity 0.8s var(--ease-out),
    transform 0.8s var(--ease-spring);
  will-change: opacity, transform;
}
.hv [data-reveal].is-revealed {
  opacity: 1;
  transform: none;
}

/* ----- Backdrop ----- */
.hv-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 0;
  overflow: hidden;
}
.hv-bg__blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(120px);
  opacity: 0.25;
}
.hv--dark .hv-bg__blob { opacity: 0.35; }
.hv-bg__blob--1 { top: 5%;   left: 10%;   width: 26rem; height: 26rem; background: var(--c4-d); animation: t-float 18s ease-in-out infinite; }
.hv-bg__blob--2 { top: 15%;  right: 15%;  width: 20rem; height: 20rem; background: var(--c3-a); animation: t-float 22s ease-in-out -6s infinite; }
.hv-bg__blob--3 { bottom: 8%;  left: -6rem;  width: 28rem; height: 28rem; background: var(--c4-d); opacity: 0.18; animation: t-float 26s ease-in-out -12s infinite; }
.hv-bg__blob--4 { bottom: 2%;  right: -4rem; width: 24rem; height: 24rem; background: var(--c1-a); opacity: 0.2; animation: t-float 20s ease-in-out -3s infinite; }
.hv--dark .hv-bg__blob--3 { opacity: 0.28; }
.hv--dark .hv-bg__blob--4 { opacity: 0.32; }

.hv-bg__grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(148, 163, 184, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(148, 163, 184, 0.05) 1px, transparent 1px);
  background-size: 64px 64px;
  mask-image: radial-gradient(ellipse at center, black 30%, transparent 75%);
}

/* ----- Header ----- */
.hv-header {
  position: sticky;
  top: 0;
  z-index: 50;
  backdrop-filter: blur(20px) saturate(140%);
  -webkit-backdrop-filter: blur(20px) saturate(140%);
  background: color-mix(in srgb, var(--t-bg) 72%, transparent);
  border-bottom: 1px solid var(--t-line);
}
.hv-header__inner {
  max-width: 1152px;
  margin: 0 auto;
  padding: 14px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.hv-brand {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  color: var(--t-txt-100);
  text-decoration: none;
  font-family: var(--f-display);
  font-weight: 600;
  letter-spacing: -0.01em;
}
.hv-brand__mark {
  position: relative;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.hv-brand__mark img {
  position: relative;
  z-index: 1;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  object-fit: contain;
}
.hv-brand__dot {
  position: relative;
  z-index: 1;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--c1-a), var(--c2-a));
  box-shadow: 0 0 14px var(--c2-a);
}
.hv-brand__ring {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border: 1px dashed var(--t-line-3);
  pointer-events: none;
  transition: border-color var(--dur-med) ease, box-shadow var(--dur-med) ease;
}
.hv-brand__ring--outer { animation: t-spin 14s linear infinite; }
.hv-brand__ring--inner {
  inset: 4px;
  border-style: dotted;
  border-color: color-mix(in srgb, var(--c2-a) 55%, transparent);
  animation: t-spin-r 18s linear infinite;
}
.hv-brand:hover .hv-brand__ring--outer {
  animation-duration: 7s;
  border-color: color-mix(in srgb, var(--c2-a) 60%, transparent);
}
.hv-brand:hover .hv-brand__ring--inner {
  animation-duration: 9s;
  border-color: var(--c2-a);
  box-shadow: 0 0 12px color-mix(in srgb, var(--c2-a) 50%, transparent);
}
.hv-brand__text { transition: color var(--dur-fast) ease; }
.hv-brand:hover .hv-brand__text { color: var(--c2-text); }
.hv--dark .hv-brand:hover .hv-brand__text { color: var(--c2-a); }
.hv-brand__text { font-size: 15px; }

.hv-header__actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.hv-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
  border-radius: 10px;
  color: var(--t-txt-400);
  border: 1px solid transparent;
  background: transparent;
  cursor: pointer;
  transition:
    color var(--dur-fast) ease,
    background var(--dur-fast) ease,
    border-color var(--dur-fast) ease,
    transform var(--dur-fast) var(--ease-out);
}
.hv-icon-btn:hover {
  color: var(--t-txt-100);
  background: var(--t-glass);
  border-color: var(--t-line-2);
  transform: translateY(-1px);
}
.hv-icon-btn:active { transform: translateY(0); }

.hv-cta-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px 6px 6px;
  border-radius: 100px;
  border: 1px solid var(--t-line-2);
  background: var(--t-glass);
  color: var(--t-txt-100);
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  transition: transform var(--dur-fast) var(--ease-out), border-color var(--dur-fast) ease, background var(--dur-fast) ease;
}
.hv-cta-pill:hover { transform: translateY(-1px); border-color: var(--t-line-3); }
.hv-cta-pill__avatar {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--c1-a), var(--c2-a));
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: 700;
  color: #fff;
  font-family: var(--f-mono);
}
.hv-cta-pill--solid {
  padding: 8px 16px;
  border: 0;
  background: var(--t-txt-100);
  color: var(--t-bg);
}
.hv-cta-pill--solid:hover {
  background: color-mix(in srgb, var(--t-txt-100) 88%, var(--c2-a));
}

/* ----- Section primitives ----- */
.hv-section {
  position: relative;
}
.hv-section__inner {
  max-width: 1152px;
  margin: 0 auto;
  padding: clamp(80px, 11vw, 144px) 24px;
}
.hv-section--bordered { border-top: 1px solid var(--t-line); }

/* ----- Numbered eyebrow ----- */
.hv-num-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-family: var(--f-mono);
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.2em;
  text-transform: uppercase;
}
.hv-num-eyebrow__dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
  box-shadow: 0 0 10px currentColor;
  animation: t-pulse 2.4s ease-in-out infinite;
}
.hv-num-eyebrow--neutral { color: var(--t-txt-500); }
.hv-num-eyebrow--neutral .hv-num-eyebrow__dot { box-shadow: none; background: var(--t-txt-500); animation: t-pulse 3.2s ease-in-out infinite; }
.hv-num-eyebrow--c1 { color: var(--c1-text); }
.hv-num-eyebrow--c2 { color: var(--c2-text); }
.hv-num-eyebrow--c3 { color: var(--c3-text); }
.hv-num-eyebrow--c4 { color: var(--c4-text); }

/* ----- Hero (centered editorial) ----- */
.hv-hero .hv-section__inner {
  padding-top: clamp(72px, 9vw, 128px);
  padding-bottom: clamp(96px, 13vw, 168px);
}
.hv-hero__inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}
.hv-eyebrow-row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: var(--f-mono);
  font-size: 11px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  margin-bottom: 32px;
}
.hv-eyebrow-row__line {
  display: block;
  height: 1px;
  width: 40px;
  background: linear-gradient(90deg, var(--c3-a), var(--c4-d));
  background-size: 200% 100%;
  animation: hv-shimmer 5s linear infinite;
  transition: width var(--dur-med) var(--ease-out);
}
.hv-eyebrow-row:hover .hv-eyebrow-row__line { width: 64px; }
.hv-eyebrow-row__brand { color: var(--t-txt-200); font-weight: 600; }
.hv-eyebrow-row__tag   { color: var(--t-txt-500); font-weight: 500; }

@keyframes hv-shimmer {
  0%   { background-position: 0% 0; }
  100% { background-position: 200% 0; }
}

.hv-hero__title {
  font-family: var(--f-display), var(--f-zh);
  font-weight: 700;
  letter-spacing: -0.025em;
  line-height: 1.04;
  margin: 0 0 28px;
  font-size: clamp(46px, 8vw, 104px);
  color: var(--t-txt-100);
}
.hv-hero__title-line { display: block; }
.hv-hero__title-accent {
  display: block;
  font-family: var(--f-zh), var(--f-display);
  font-weight: 700;
  font-size: 0.6em;
  line-height: 1.15;
  margin-top: 0.08em;
  letter-spacing: -0.01em;
  background: linear-gradient(135deg, var(--c3-a) 0%, var(--c4-d) 50%, var(--c1-deep) 100%);
  -webkit-background-clip: text;
          background-clip: text;
  color: transparent;
}
.hv--dark .hv-hero__title-accent {
  background: linear-gradient(135deg, #F0A862 0%, #BAE6FD 50%, #F5A5B8 100%);
  -webkit-background-clip: text;
          background-clip: text;
  color: transparent;
}
.hv-hero__lede-1 {
  margin: 0 0 8px;
  font-family: var(--f-zh), var(--f-body);
  font-size: clamp(16px, 1.4vw, 20px);
  line-height: 1.55;
  color: var(--t-txt-300);
  max-width: 36rem;
}
.hv-hero__lede-2 {
  margin: 0 0 40px;
  font-family: var(--f-zh), var(--f-body);
  font-size: clamp(13px, 1vw, 15px);
  line-height: 1.7;
  color: var(--t-txt-500);
  max-width: 36rem;
}
.hv-hero__ctas {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  justify-content: center;
}

/* ----- Buttons (hero CTAs, editorial) ----- */
.hv-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 14px 26px;
  border-radius: 100px;
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
  border: 1px solid transparent;
  overflow: hidden;
  transition: transform var(--dur-fast) var(--ease-out),
              border-color var(--dur-fast) ease,
              background var(--dur-fast) ease,
              box-shadow var(--dur-fast) ease;
}
.hv-btn__arrow {
  display: inline-block;
  transition: transform var(--dur-fast) var(--ease-out);
}
.hv-btn:hover .hv-btn__arrow { transform: translateX(4px); }

/* Sheen sweep on hover for both button types. */
.hv-btn::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    115deg,
    transparent 30%,
    rgba(255, 255, 255, 0.35) 50%,
    transparent 70%
  );
  transform: translateX(-110%);
  pointer-events: none;
  transition: transform 0.7s var(--ease-out);
}
.hv-btn:hover::before { transform: translateX(110%); }
.hv--dark .hv-btn--solid::before {
  background: linear-gradient(
    115deg,
    transparent 30%,
    rgba(255, 255, 255, 0.55) 50%,
    transparent 70%
  );
}

.hv-btn--solid {
  background: var(--t-txt-100);
  color: var(--t-bg);
  box-shadow: 0 12px 32px color-mix(in srgb, var(--t-txt-100) 16%, transparent);
}
.hv-btn--solid:hover {
  transform: translateY(-2px);
  background: color-mix(in srgb, var(--t-txt-100) 90%, var(--c2-a));
  box-shadow: 0 18px 40px color-mix(in srgb, var(--t-txt-100) 22%, transparent),
              0 0 0 1px color-mix(in srgb, var(--c2-a) 30%, transparent);
}
.hv-btn--outline {
  color: var(--t-txt-100);
  background: transparent;
  border-color: var(--t-line-3);
}
.hv-btn--outline:hover {
  transform: translateY(-2px);
  border-color: var(--t-txt-200);
  background: var(--t-glass);
}

/* ----- Block head (for pain points / providers) ----- */
.hv-block-head {
  margin-bottom: 56px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-width: 720px;
}
.hv-block-head--center {
  margin-left: auto;
  margin-right: auto;
  align-items: center;
  text-align: center;
}
.hv-block-title {
  font-family: var(--f-display), var(--f-zh);
  font-weight: 700;
  letter-spacing: -0.02em;
  line-height: 1.1;
  font-size: clamp(32px, 4.4vw, 56px);
  color: var(--t-txt-100);
  margin: 0;
}
.hv-block-desc {
  margin: 0;
  font-family: var(--f-zh), var(--f-body);
  font-size: 15px;
  color: var(--t-txt-400);
  line-height: 1.7;
}

/* ----- Pain points ----- */
.hv-pain__grid {
  display: grid;
  grid-template-columns: repeat(1, minmax(0, 1fr));
  gap: 12px;
}
@media (min-width: 640px) { .hv-pain__grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (min-width: 1024px) { .hv-pain__grid { grid-template-columns: repeat(4, minmax(0, 1fr)); } }

.hv-pain-card {
  position: relative;
  padding: 28px 24px;
  border-radius: 18px;
  background: var(--t-glass);
  border: 1px solid var(--t-line-2);
  backdrop-filter: blur(18px) saturate(140%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  overflow: hidden;
  transition:
    transform var(--dur-med) var(--ease-out),
    border-color var(--dur-fast) ease,
    box-shadow var(--dur-med) ease;
}
.hv-pain-card::before {
  content: '';
  position: absolute;
  top: -40%;
  right: -40%;
  width: 70%;
  height: 70%;
  border-radius: 50%;
  filter: blur(40px);
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--dur-med) ease;
}
.hv-pain-card--1::before { background: var(--c1-a); }
.hv-pain-card--2::before { background: var(--c3-a); }
.hv-pain-card--3::before { background: var(--c2-a); }
.hv-pain-card--4::before { background: var(--c4-d); }
.hv--dark .hv-pain-card--4::before { background: var(--c4-a); }

.hv-pain-card:hover {
  transform: translateY(-5px);
  border-color: var(--t-line-3);
  box-shadow: 0 18px 40px color-mix(in srgb, var(--t-bg) 80%, transparent);
}
.hv-pain-card:hover::before { opacity: 0.45; }
.hv-pain-card:hover .hv-pain-card__icon {
  transform: translateY(-2px) scale(1.08);
}
.hv-pain-card__icon {
  position: relative;
  display: inline-flex;
  width: 38px;
  height: 38px;
  border-radius: 10px;
  align-items: center;
  justify-content: center;
  transition: transform var(--dur-med) var(--ease-spring);
}
.hv-pain-card--1 .hv-pain-card__icon { color: var(--c1-text); background: color-mix(in srgb, var(--c1-a) 16%, transparent); }
.hv-pain-card--2 .hv-pain-card__icon { color: var(--c3-text); background: color-mix(in srgb, var(--c3-a) 16%, transparent); }
.hv-pain-card--3 .hv-pain-card__icon { color: var(--c2-text); background: color-mix(in srgb, var(--c2-a) 16%, transparent); }
.hv-pain-card--4 .hv-pain-card__icon { color: var(--c4-text); background: color-mix(in srgb, var(--c4-d) 16%, transparent); }
.hv--dark .hv-pain-card--3 .hv-pain-card__icon { color: var(--c2-c); }
.hv--dark .hv-pain-card--4 .hv-pain-card__icon { color: var(--c4-a); }

.hv-pain-card__title {
  font-family: var(--f-display), var(--f-zh);
  font-weight: 600;
  font-size: 16px;
  color: var(--t-txt-100);
  margin: 18px 0 8px;
  letter-spacing: 0;
  line-height: 1.4;
}
.hv-pain-card__desc {
  font-family: var(--f-zh), var(--f-body);
  font-size: 13px;
  color: var(--t-txt-400);
  line-height: 1.7;
  margin: 0;
}

/* ----- Feature alternating sections ----- */
.hv-feat-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 56px;
  align-items: center;
}
@media (min-width: 960px) {
  .hv-feat-grid { grid-template-columns: 1fr 1fr; gap: 80px; }
  .hv-feat-grid--reverse > .hv-feat-text   { order: 2; }
  .hv-feat-grid--reverse > .hv-feat-visual { order: 1; }
}

.hv-feat-text { /* animation handled by [data-reveal] */ }
.hv-feat-title {
  margin: 18px 0 12px;
  font-family: var(--f-display), var(--f-zh);
  font-weight: 700;
  letter-spacing: -0.02em;
  line-height: 1.12;
  font-size: clamp(32px, 4vw, 52px);
  color: var(--t-txt-100);
}
.hv-feat-tagline {
  margin: 0 0 18px;
  font-family: var(--f-zh), var(--f-body);
  font-size: 14px;
  color: var(--t-txt-500);
  line-height: 1.6;
}
.hv-feat-body {
  margin: 0;
  font-family: var(--f-zh), var(--f-body);
  font-size: 15px;
  line-height: 1.75;
  color: var(--t-txt-300);
  max-width: 28rem;
}

.hv-feat-visual {
  position: relative;
  /* animation handled by [data-reveal] */
}
.hv-feat-visual__halo {
  position: absolute;
  inset: -4px;
  border-radius: 24px;
  background: linear-gradient(135deg,
              color-mix(in srgb, var(--c3-a) 22%, transparent),
              color-mix(in srgb, var(--c4-d) 14%, transparent),
              color-mix(in srgb, var(--c1-a) 22%, transparent));
  opacity: 0.5;
  filter: blur(28px);
  pointer-events: none;
  z-index: 0;
  animation: t-halo-pulse 5s ease-in-out infinite;
  transition: opacity var(--dur-med) ease, filter var(--dur-med) ease;
}
.hv-feat-visual:hover .hv-feat-visual__halo {
  opacity: 0.85;
  filter: blur(36px);
}

/* ----- Terminal (in section 01) ----- */
.hv-terminal {
  position: relative;
  z-index: 1;
  border-radius: 18px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: linear-gradient(160deg, #0d1020 0%, #07090f 100%);
  box-shadow: 0 40px 80px rgba(0, 0, 0, 0.35),
              inset 0 1px 0 rgba(255, 255, 255, 0.05);
  transition:
    transform var(--dur-med) var(--ease-out),
    box-shadow var(--dur-med) ease,
    border-color var(--dur-fast) ease;
}
.hv-terminal:hover {
  transform: translateY(-4px);
  border-color: color-mix(in srgb, var(--c2-a) 35%, rgba(255, 255, 255, 0.1));
  box-shadow: 0 50px 96px rgba(0, 0, 0, 0.45),
              0 0 0 1px color-mix(in srgb, var(--c2-a) 22%, transparent),
              0 0 50px color-mix(in srgb, var(--c2-a) 16%, transparent),
              inset 0 1px 0 rgba(255, 255, 255, 0.08);
}
.hv-terminal__bar {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 11px 18px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(255, 255, 255, 0.02);
}
.hv-terminal__dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: #3F3F46;
  transition: background var(--dur-med) ease, box-shadow var(--dur-med) ease;
}
.hv-terminal:hover .hv-terminal__dot:nth-child(1) {
  background: #ef4444;
  box-shadow: 0 0 8px rgba(239, 68, 68, 0.5);
}
.hv-terminal:hover .hv-terminal__dot:nth-child(2) {
  background: #eab308;
  box-shadow: 0 0 8px rgba(234, 179, 8, 0.5);
  transition-delay: 60ms;
}
.hv-terminal:hover .hv-terminal__dot:nth-child(3) {
  background: #22c55e;
  box-shadow: 0 0 8px rgba(34, 197, 94, 0.5);
  transition-delay: 120ms;
}
.hv-terminal__title {
  margin-left: 8px;
  font-family: var(--f-mono);
  font-size: 11px;
  color: #71717A;
  letter-spacing: 0.04em;
}
.hv-terminal__body {
  margin: 0;
  padding: 20px 22px;
  font-family: var(--f-mono);
  font-size: 12.5px;
  line-height: 1.85;
  color: #D4D4D8;
  white-space: pre;
  overflow-x: auto;
}
.t-c   { color: #71717A; }
.t-cmd { color: #FBB280; }
.t-url { color: #D4D4D8; }
.t-flag{ color: #BAE6FD; }
.t-str { color: #F5A5B8; }

/* ----- Signal panel (section 02) ----- */
.hv-signal-panel {
  position: relative;
  z-index: 1;
  padding: 28px;
  border-radius: 20px;
  background: var(--t-glass);
  border: 1px solid var(--t-line-2);
  backdrop-filter: blur(18px) saturate(140%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  transition: transform var(--dur-med) var(--ease-out), border-color var(--dur-fast) ease;
}
.hv-signal-panel:hover {
  transform: translateY(-4px);
  border-color: var(--t-line-3);
}
.hv-signal-panel__label {
  font-family: var(--f-mono);
  font-size: 11px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--t-txt-500);
}
.hv-signal-panel__wave {
  display: block;
  margin-top: 22px;
  height: 80px;
  width: 100%;
}
.hv-signal-panel__wave path {
  stroke-dasharray: 1200;
  stroke-dashoffset: 1200;
  transition: stroke-dashoffset 1.8s var(--ease-out);
}
[data-reveal].is-revealed .hv-signal-panel__wave path { stroke-dashoffset: 0; }

.hv-signal-panel__pills {
  margin-top: 22px;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}
.hv-signal-pill {
  padding: 12px 10px;
  border-radius: 10px;
  border: 1px solid var(--t-line);
  background: var(--t-glass);
  text-align: center;
  transition:
    transform var(--dur-fast) var(--ease-out),
    border-color var(--dur-fast) ease,
    background var(--dur-fast) ease;
}
.hv-signal-pill:hover {
  transform: translateY(-2px);
  border-color: color-mix(in srgb, var(--c2-a) 45%, transparent);
  background: var(--t-glass-2);
}
.hv-signal-pill__title {
  display: block;
  font-family: var(--f-zh), var(--f-display);
  font-size: 13px;
  font-weight: 600;
  color: var(--t-txt-100);
}
.hv-signal-pill__sub {
  display: block;
  margin-top: 4px;
  font-family: var(--f-mono);
  font-size: 10px;
  letter-spacing: 0.15em;
  color: var(--t-txt-500);
  text-transform: uppercase;
}

.hv-signal-panel__rows { margin-top: 22px; display: flex; flex-direction: column; gap: 4px; }
.hv-signal-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-family: var(--f-mono);
  font-size: 12px;
  color: var(--t-txt-300);
  padding: 8px 8px;
  border-radius: 8px;
  transition: background var(--dur-fast) ease;
}
.hv-signal-row:hover { background: var(--t-glass-2); }
.hv-signal-row__name { color: var(--t-txt-200); }
.hv-signal-row__status { display: inline-flex; align-items: center; gap: 8px; color: var(--t-txt-500); }
.hv-signal-row__dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--t-success);
  box-shadow: 0 0 8px var(--t-success);
  animation: t-pulse 1.8s ease-in-out infinite;
}
.hv-signal-row:nth-child(2) .hv-signal-row__dot { animation-delay: -0.4s; }
.hv-signal-row:nth-child(3) .hv-signal-row__dot { animation-delay: -0.8s; }
.hv-signal-row:nth-child(4) .hv-signal-row__dot { animation-delay: -1.2s; }
.hv-signal-row__latency { font-size: 11px; }

/* ----- Billing panel (section 03) ----- */
.hv-billing-panel {
  position: relative;
  z-index: 1;
  padding: 28px;
  border-radius: 20px;
  background: var(--t-glass);
  border: 1px solid var(--t-line-2);
  backdrop-filter: blur(18px) saturate(140%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  transition: transform var(--dur-med) var(--ease-out), border-color var(--dur-fast) ease;
}
.hv-billing-panel:hover {
  transform: translateY(-4px);
  border-color: var(--t-line-3);
}
.hv-billing-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-family: var(--f-mono);
  font-size: 11px;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: var(--t-txt-500);
}
.hv-billing-panel__balance {
  margin-top: 22px;
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-family: var(--f-display);
}
.hv-billing-panel__balance-currency { font-size: 22px; color: var(--t-txt-400); }
.hv-billing-panel__balance-num {
  font-size: clamp(40px, 5vw, 56px);
  font-weight: 700;
  color: var(--t-txt-100);
  letter-spacing: -0.02em;
  font-feature-settings: 'tnum' on, 'lnum' on;
}
.hv-billing-panel__balance-cap { font-size: 14px; color: var(--t-txt-500); font-family: var(--f-mono); }

.hv-billing-panel__bar {
  margin-top: 18px;
  height: 6px;
  border-radius: 100px;
  background: var(--t-glass-2);
  overflow: hidden;
}
.hv-billing-panel__bar-fill {
  display: block;
  height: 100%;
  width: 0;
  border-radius: 100px;
  background: linear-gradient(90deg, var(--c3-a), var(--c2-a));
  box-shadow: 0 0 14px color-mix(in srgb, var(--c2-a) 50%, transparent);
  transition: width 1.6s 0.25s var(--ease-out);
}
[data-reveal].is-revealed .hv-billing-panel__bar-fill { width: 28.4%; }

.hv-billing-panel__rows {
  margin: 26px 0 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
}
.hv-billing-row {
  display: grid;
  grid-template-columns: 1.4fr 1fr auto;
  gap: 12px;
  padding: 10px 8px;
  border-radius: 6px;
  font-family: var(--f-mono);
  font-size: 12px;
  border-top: 1px solid var(--t-line);
  transition: background var(--dur-fast) ease;
}
.hv-billing-row:first-child { border-top: 0; }
.hv-billing-row:hover { background: var(--t-glass-2); }
.hv-billing-row__model  { color: var(--t-txt-200); }
.hv-billing-row__tokens { color: var(--t-txt-500); }
.hv-billing-row__price  { color: var(--t-txt-100); text-align: right; }

/* ----- Providers ----- */
.hv-providers__row {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
.hv-chip {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 8px 14px 8px 8px;
  border-radius: 100px;
  background: var(--t-glass);
  border: 1px solid var(--t-line-2);
  backdrop-filter: blur(12px);
  font-size: 13px;
  color: var(--t-txt-200);
  transition: transform var(--dur-fast) var(--ease-out), border-color var(--dur-fast) ease;
}
.hv-chip:hover { transform: translateY(-1px); border-color: var(--t-line-3); }
.hv-chip--soon { opacity: 0.55; }
.hv-chip__brand {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  color: #fff;
  font-family: var(--f-mono);
}
.hv-chip__name { font-weight: 500; }
.hv-chip__status {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: var(--t-txt-500);
  padding-left: 8px;
  border-left: 1px solid var(--t-line-2);
}
.hv-chip__dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--t-success);
  box-shadow: 0 0 8px var(--t-success);
  animation: t-pulse 1.8s ease-in-out infinite;
}
.hv-chip__dot--soon { background: var(--t-txt-500); box-shadow: none; animation: none; }

/* ----- Footer (centered) ----- */
.hv-footer {
  position: relative;
  z-index: 10;
  border-top: 1px solid var(--t-line);
}
.hv-footer__inner {
  padding-top: 32px !important;
  padding-bottom: 32px !important;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  gap: 10px;
}
.hv-footer__copy {
  font-size: 13px;
  color: var(--t-txt-500);
  margin: 0;
  font-family: var(--f-mono);
  letter-spacing: 0.04em;
}
.hv-footer__link {
  font-family: var(--f-mono);
  font-size: 12px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--t-txt-400);
  text-decoration: none;
  transition: color var(--dur-fast) ease;
}
.hv-footer__link:hover { color: var(--t-txt-100); }
</style>
