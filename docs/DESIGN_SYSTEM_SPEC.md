# CORET Design System — Complete Specification

> This document defines every visual rule, component, and pattern used across CORET's UI mockups. Use this as the single source of truth when creating new screens or templates.

---

## 1. Foundations

### 1.1 Color Tokens

```css
:root {
  /* Base */
  --bg: #1a1714;
  --card: #221f1a;
  --card-raised: #282420;
  --border: #2e2a22;
  --border-light: #3a3530;

  /* Text */
  --text: #EAE5DE;
  --text-2: #B0A99E;
  --text-3: #6B625C;
  --text-4: #4a4540;

  /* Accent */
  --gold: #C9A96E;
  --gold-dim: rgba(201,169,110,0.55);
  --gold-soft: rgba(201,169,110,0.10);
  --gold-glow: rgba(201,169,110,0.04);
  --green: #7A9A6E;
  --green-soft: rgba(122,154,110,0.10);
  --red: #B4705A;
  --red-soft: rgba(180,90,70,0.10);
  --amber: #C4944A;

  /* Radius */
  --r: 18px;
  --r-sm: 10px;
}
```

### 1.1b Light Theme Color Tokens

Dark is default. Light is user-selectable. Same semantic tokens, different values.

```css
:root[data-theme="light"] {
  /* Base */
  --bg: #fdfaf6;
  --card: #f5f0e8;
  --card-raised: #ede6d8;
  --border: rgba(30,20,5,0.07);
  --border-light: rgba(30,20,5,0.12);

  /* Text */
  --text: #18140c;
  --text-2: #5a5040;
  --text-3: #8a7d68;
  --text-4: #b0a590;

  /* Accent */
  --gold: #b8860b;
  --gold-dim: rgba(184,134,11,0.55);
  --gold-soft: rgba(184,134,11,0.09);
  --gold-glow: rgba(184,134,11,0.04);
  --green: #5a8a5e;
  --green-soft: rgba(90,138,94,0.09);
  --red: #a05040;
  --red-soft: rgba(160,80,64,0.09);
  --amber: #b8860b;

  /* Radius — unchanged */
  --r: 18px;
  --r-sm: 10px;
}
```

**Light theme adjustments:**
- Gold is deeper (#b8860b vs #C9A96E) for sufficient contrast on light backgrounds
- SVG garment silhouette opacity: 0.65–0.70 (vs 0.80–0.85 in dark)
- Drop shadows: rgba(30,20,5,0.06–0.12) instead of rgba(0,0,0,0.35–0.65)
- Card material: no backdrop-filter blur needed — solid warm surfaces
- Moodboard reference: `moodboard/themes/coret-light-theme.html`

### 1.2 Typography

**Fonts:**
- Body: `'DM Sans', sans-serif` — weights 300, 400, 500, 600
- Display: `'Instrument Serif', serif` — normal & italic

**Google Fonts import:**
```html
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=Instrument+Serif:ital@0;1&display=swap" rel="stylesheet">
```

**Scale:**

| Role | Size | Weight | Family | Spacing |
|------|------|--------|--------|---------|
| Page title | 28–30px | 400 | Instrument Serif | — |
| Large score | 48–64px | 400 | Instrument Serif | — |
| Card title | 14–15px | 400–500 | DM Sans | — |
| Body | 12–13px | 400 | DM Sans | — |
| Meta | 11–12px | 400 | DM Sans | 0.5–0.8px |
| Section label | 9px | 500 | DM Sans | 3px, uppercase |
| Tiny label | 8–9px | 500 | DM Sans | 2–3px, uppercase |
| Tab label | 8.5px | 400 | DM Sans | 0.8px, uppercase |

### 1.3 Shadow Tiers

```css
/* L1 — subtle, small elements */
box-shadow: 0 8px 24px rgba(0,0,0,0.35);

/* L2 — standard cards */
box-shadow: 0 16px 48px rgba(0,0,0,0.45),
            0 0 0 1px rgba(255,255,255,0.03) inset;

/* L3 — hero sections, canvas */
box-shadow: 0 28px 90px rgba(0,0,0,0.65);

/* Phone frame */
box-shadow: 0 40px 100px rgba(0,0,0,0.5);
```

### 1.4 Card Material (Frosted Glass)

```css
.card {
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid var(--border);
  border-radius: var(--r);
}

/* Gold-tinted border variant (hero/feedback cards) */
border: 1px solid rgba(201,169,110,0.10);

/* Selected/highlight variant */
border-color: rgba(201,169,110,0.2);
background: rgba(201,169,110,0.03);
```

### 1.5 Spacing

- Horizontal page padding: `0 16px` (cards), `0 20px` (content)
- Section gap: `14px`–`24px`
- Card bottom margin: `14px`–`20px`
- Flex gap (elements): `8px`–`14px`
- Grid based on 8px increments

---

## 2. Page Frame

### 2.1 Phone Container

```css
body {
  margin: 0;
  background: #0e0c0a;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  font-family: 'DM Sans', sans-serif;
  color: var(--text);
  -webkit-font-smoothing: antialiased;
}

.phone {
  width: 375px;
  height: 812px;
  background: var(--bg);
  border-radius: 44px;
  overflow: hidden;
  position: relative;
  border: 2.5px solid #2a2520;
  box-shadow: 0 40px 100px rgba(0,0,0,0.5);
}
```

### 2.2 Cinematic Lighting Overlay

```css
.phone::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 10%, rgba(255,255,255,0.04), transparent 50%),
    radial-gradient(circle at 50% 0%, rgba(201,169,110,0.08), transparent 60%);
  z-index: 1;
  pointer-events: none;
}
```

### 2.3 Scrollable Content Area

```css
.scroll {
  height: calc(100% - 108px); /* top-bar + brand = ~54px, tab-bar = ~68px */
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  position: relative;
  z-index: 2;
}

.scroll::-webkit-scrollbar { display: none; }
```

### 2.4 Top Bar + Brand Row

```html
<div class="top-bar">
  <span>9:41</span>
  <span style="font-size:12px;color:var(--text-3);">●●●●  📶  🔋</span>
</div>
<div class="brand-row">
  <span class="brand">CORET</span>
  <span class="dots">•••</span>
</div>
```

```css
.top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 28px 0;
  font-size: 15px;
  font-weight: 600;
  position: relative;
  z-index: 5;
}

.brand-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 20px 0;
  position: relative;
  z-index: 5;
}

.brand {
  font-family: 'Instrument Serif', serif;
  font-size: 14px;
  letter-spacing: 2px;
  color: var(--gold-dim);
}

.dots {
  color: var(--text-3);
  letter-spacing: 3px;
  font-size: 14px;
  cursor: pointer;
}
```

### 2.5 Tab Bar

```html
<div class="tab-bar">
  <div class="tab"><span class="tab-i">◻</span><span class="tab-l">Pulse</span></div>
  <div class="tab"><span class="tab-i">▦</span><span class="tab-l">Wardrobe</span></div>
  <div class="tab"><span class="tab-i">✦</span><span class="tab-l">Studio</span></div>
  <div class="tab"><span class="tab-i">◎</span><span class="tab-l">Optimize</span></div>
  <div class="tab"><span class="tab-i">◈</span><span class="tab-l">Evolution</span></div>
</div>
```

```css
.tab-bar {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 68px;
  background: #1e1a15;
  border-top: 1px solid var(--border);
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding-bottom: 6px;
  z-index: 10;
}

.tab {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  cursor: pointer;
  padding: 6px 10px;
}

.tab-i { font-size: 17px; opacity: 0.3; }
.tab-l { font-size: 8.5px; letter-spacing: 0.8px; text-transform: uppercase; color: var(--text-4); }

.tab.on .tab-i { opacity: 1; }
.tab.on .tab-l { color: var(--gold-dim); }
```

**Tab order:** Pulse | Wardrobe | Studio | Optimize | Evolution

**Icons:** ◻ ▦ ✦ ◎ ◈

---

## 3. Section Labels

Used to divide content areas. Consistent across all screens.

```html
<div class="section-label">
  <span>SECTION NAME</span>
</div>
```

```css
.section-label {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0 16px;
  margin: 20px 0 12px;
}

.section-label span {
  font-size: 9px;
  letter-spacing: 3px;
  text-transform: uppercase;
  color: var(--text-3);
  font-weight: 500;
  white-space: nowrap;
}

.section-label::after {
  content: '';
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, rgba(201,169,110,0.15), transparent);
}
```

---

## 4. Components

### 4.1 Garment Card

The core visual unit. Used in Wardrobe grid, Studio selector, and Optimize combos.

```html
<div class="g-card g-navy" data-id="navy-skjorte" data-type="upper">
  <div class="g-visual">
    <svg width="60" height="60" viewBox="0 0 60 60" fill="none">
      <!-- garment silhouette SVG -->
    </svg>
  </div>
  <div class="g-info">
    <div class="g-name">Navy Skjorte</div>
    <div class="g-meta">Overdel · Klassisk</div>
  </div>
</div>
```

```css
.g-card {
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
  position: relative;
  border: 1.5px solid rgba(255,255,255,0.04);
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  flex: 0 0 130px;
  scroll-snap-align: start;
}

.g-card:hover {
  transform: translateY(-3px) scale(1.01);
  border-color: rgba(201,169,110,0.15);
  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
}

.g-card:active { transform: scale(.98); }

.g-card.selected {
  border-color: var(--gold);
  box-shadow: 0 0 0 1px var(--gold), 0 6px 18px rgba(201,169,110,0.15);
}

.g-visual {
  height: 130px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  border-radius: 12px 12px 0 0;
}

/* Bottom vignette + top reflection */
.g-visual::after {
  content: '';
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    linear-gradient(180deg, transparent 50%, rgba(26,23,20,0.8) 100%),
    radial-gradient(ellipse at 50% 0%, rgba(255,255,255,0.03), transparent 70%);
}

/* SVG floating effect */
.g-visual svg {
  position: relative;
  z-index: 1;
  filter: drop-shadow(0 4px 12px rgba(0,0,0,0.4));
  transform: translateY(-2px);
  transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}

.g-card:hover .g-visual svg {
  transform: translateY(-5px);
}

/* Image-ready container */
.g-visual img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  position: relative;
  z-index: 0;
}

.g-info {
  padding: 12px 12px 14px;
  background: rgba(35,28,24,0.9);
}

.g-name {
  font-size: 12px;
  font-weight: 500;
  color: var(--text);
}

.g-meta {
  font-size: 10px;
  color: var(--text-3);
  margin-top: 2px;
  letter-spacing: 0.3px;
}
```

**Color gradient backgrounds per garment:**

```css
.g-navy .g-visual    { background: linear-gradient(155deg, #161C28 0%, #121822 50%, #0E141C 100%); }
.g-white .g-visual   { background: linear-gradient(155deg, #2A2A28 0%, #242422 50%, #1E1E1C 100%); }
.g-brown .g-visual   { background: linear-gradient(155deg, #2E1F16 0%, #261A14 50%, #1E1510 100%); }
.g-black .g-visual   { background: linear-gradient(155deg, #1C1C20 0%, #18181C 50%, #141416 100%); }
.g-grey .g-visual    { background: linear-gradient(155deg, #222226 0%, #1E1E22 50%, #1A1A1E 100%); }
.g-olive .g-visual   { background: linear-gradient(155deg, #1E2416 0%, #1A2014 50%, #141C10 100%); }
.g-beige .g-visual   { background: linear-gradient(155deg, #2A2418 0%, #262016 50%, #201C12 100%); }
.g-rust .g-visual    { background: linear-gradient(155deg, #2C1C16 0%, #261814 50%, #1E1410 100%); }
.g-blue .g-visual    { background: linear-gradient(155deg, #162030 0%, #141C28 50%, #101820 100%); }
.g-cream .g-visual   { background: linear-gradient(155deg, #2C2820 0%, #28241C 50%, #222018 100%); }
.g-charcoal .g-visual { background: linear-gradient(155deg, #1E1E22 0%, #1A1A1E 50%, #16161A 100%); }
```

### 4.2 Outfit Card

Used in Wardrobe to show outfit combinations.

```html
<div class="o-card o-winter">
  <div class="o-visual">
    <div class="garment-group">
      <!-- Multiple SVG garments arranged horizontally -->
    </div>
    <div class="source-colors">
      <div class="source-dot" style="background:#8B5537;"></div>
      <div class="source-dot" style="background:#2C3E50;"></div>
    </div>
  </div>
  <div class="o-info">
    <div class="o-info-left">
      <div class="o-name">Vinterstruktur</div>
      <div class="o-pills">
        <span class="pill pill-type">Structured</span>
        <span class="pill pill-count">4 plagg</span>
      </div>
    </div>
    <div class="o-status status-aligned">Aligned</div>
  </div>
</div>
```

```css
.o-card {
  border-radius: 16px;
  overflow: hidden;
  margin-bottom: 14px;
  cursor: pointer;
  transition: all 0.35s;
  position: relative;
  border: 1px solid rgba(255,255,255,0.05);
  backdrop-filter: blur(20px);
}

.o-card:hover {
  transform: translateY(-3px) scale(1.01);
  box-shadow: 0 16px 48px rgba(0,0,0,0.45);
}

.o-visual {
  height: 150px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.o-info {
  padding: 4px 18px 6px;
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
}

.o-name {
  font-family: 'Instrument Serif', serif;
  font-size: 19px;
  font-style: italic;
}

/* Status badges */
.o-status {
  font-family: 'Instrument Serif', serif;
  font-size: 13px;
  font-style: italic;
  padding: 4px 12px;
  border-radius: 6px;
}

.status-aligned {
  color: var(--green);
  background: rgba(122,154,110,0.06);
  border: 1px solid rgba(122,154,110,0.10);
}

.status-gap {
  color: var(--amber);
  background: rgba(196,148,74,0.06);
  border: 1px solid rgba(196,148,74,0.10);
}

/* Pills */
.pill {
  font-size: 9.5px;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  padding: 4px 10px;
  border-radius: 5px;
  font-weight: 500;
}

.pill-type {
  border: 1px solid rgba(255,255,255,0.08);
  color: var(--text-2);
}

.pill-count {
  background: rgba(255,255,255,0.06);
  color: var(--text-2);
  border: 1px solid rgba(255,255,255,0.05);
}

/* Outfit color themes */
.o-winter { background: linear-gradient(155deg, #352218 0%, #241A24 40%, #1C1622 100%); }
.o-summer { background: linear-gradient(155deg, #1E2430 0%, #1A2236 40%, #18202E 100%); }
.o-street { background: linear-gradient(155deg, #1E2816 0%, #1A2214 40%, #141C12 100%); }
.o-black  { background: linear-gradient(155deg, #1E1E22 0%, #1A1A1E 40%, #161618 100%); }
```

### 4.3 Outfit Slots (Studio)

```html
<div class="outfit-canvas">
  <div class="slots-row">
    <div class="slot filled" data-type="upper">
      <svg><!-- garment SVG --></svg>
      <span class="slot-label">Navy Skjorte</span>
    </div>
    <div class="slot empty" data-type="outer">
      <svg><!-- plus icon --></svg>
      <span class="slot-label">Ytterlag</span>
    </div>
  </div>
</div>
```

```css
.outfit-canvas {
  margin: 10px 16px;
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(201,169,110,0.10);
  border-radius: var(--r);
  padding: 20px 16px;
  box-shadow: 0 28px 90px rgba(0,0,0,0.65); /* L3 */
}

.slots-row {
  display: flex;
  gap: 8px;
  margin-bottom: 14px;
}

.slot {
  flex: 1;
  height: 80px;
  border-radius: var(--r-sm);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(.16,1,.3,1);
}

.slot.filled {
  border: 1px solid rgba(201,169,110,0.10);
  background: var(--card);
}

.slot.empty {
  border: 1.5px dashed rgba(201,169,110,0.15);
  background: transparent;
}

.slot:hover {
  border-color: var(--border-light);
  transform: translateY(-2px);
}

.slot:active { transform: scale(0.96); }

.slot-label {
  font-size: 9px;
  color: var(--text-3);
  letter-spacing: 0.3px;
}

/* Slot animations */
@keyframes slotAdd {
  from { opacity: 0; transform: scale(0.85); }
  to { opacity: 1; transform: scale(1); }
}

@keyframes slotRemove {
  to { opacity: 0; transform: scale(0.9); }
}
```

### 4.4 Feedback Card (Studio)

```html
<div class="feedback-card">
  <div class="feedback-metric">
    <div class="feedback-label">Kompatibilitet</div>
    <div class="feedback-value">84</div>
    <div class="feedback-bar-track">
      <div class="feedback-bar-fill" style="width:84%;"></div>
    </div>
  </div>
  <div class="feedback-metric">
    <div class="feedback-label">Arketype</div>
    <div class="feedback-value gold">SC</div>
    <div class="feedback-bar-track">
      <div class="feedback-bar-fill" style="width:87%;"></div>
    </div>
  </div>
</div>
```

```css
.feedback-card {
  margin: 10px 16px 16px;
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(201,169,110,0.10);
  border-radius: var(--r);
  padding: 20px;
  box-shadow: 0 16px 48px rgba(0,0,0,0.45), 0 0 0 1px rgba(255,255,255,0.03) inset;
  display: flex;
  gap: 20px;
}

.feedback-metric { flex: 1; }

.feedback-label {
  font-size: 10px;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: var(--text-3);
  margin-bottom: 6px;
}

.feedback-value {
  font-family: 'Instrument Serif', serif;
  font-size: 32px;
  color: var(--text);
  line-height: 1;
  margin-bottom: 8px;
}

.feedback-value.gold {
  color: var(--gold);
  font-size: 26px;
}

.feedback-bar-track {
  width: 100%;
  height: 4px;
  background: var(--border);
  border-radius: 2px;
  overflow: hidden;
}

.feedback-bar-fill {
  height: 100%;
  border-radius: 2px;
  background: var(--gold);
  transition: width 0.6s ease-out;
}
```

### 4.5 Suggestion Card

```html
<div class="suggestion-card">
  <div class="suggestion-text">Bytt Hoodie → Blazer</div>
  <div class="suggestion-chip">+6 clarity</div>
</div>
```

```css
.suggestion-card {
  margin: 0 16px 16px;
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 16px 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: all 0.35s cubic-bezier(.16,1,.3,1);
  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
}

.suggestion-card:hover {
  border-color: rgba(201,169,110,0.15);
  transform: translateY(-2px);
}

.suggestion-text {
  font-size: 13px;
  color: var(--text);
}

.suggestion-chip {
  font-size: 11px;
  color: var(--green);
  background: var(--green-soft);
  padding: 4px 10px;
  border-radius: 6px;
  font-weight: 500;
}
```

### 4.6 Gap Card (Optimize)

```html
<div class="gap-card">
  <div class="gap-top">
    <div class="gap-priority high">
      <span class="gap-priority-num">1</span>
    </div>
    <div class="gap-info">
      <div class="gap-title">Mellomlag mangler struktur</div>
      <div class="gap-subtitle">Du har 12 overdeler men kun 2 mellomlag</div>
      <span class="gap-severity high-label">HIGH</span>
      <div class="gap-impact-chip">↗ +13 clarity projisert</div>
    </div>
    <span class="gap-arrow">›</span>
  </div>
  <div class="gap-expand">
    <div class="gap-expand-inner">
      <!-- expandable content -->
    </div>
  </div>
</div>
```

```css
.gap-card {
  margin: 0 16px 14px;
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  border: 1px solid var(--border);
  border-radius: var(--r);
  overflow: hidden;
  cursor: pointer;
  transition: all .35s cubic-bezier(.16,1,.3,1);
}

.gap-card:hover {
  border-color: var(--border-light);
  transform: translateY(-3px) scale(1.01);
  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
}

.gap-card.expanded {
  border-color: rgba(201,169,110,0.2);
}

.gap-top {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px;
}

.gap-priority {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.gap-priority.high { background: var(--red-soft); }
.gap-priority.medium { background: var(--gold-soft); }

/* Pulsing ring on high-priority gaps */
.gap-priority.high::after {
  content: '';
  position: absolute;
  inset: -3px;
  border-radius: 13px;
  border: 1px solid var(--red);
  opacity: 0;
  animation: ringPulse 2.5s ease-out infinite;
}

.gap-priority-num {
  font-family: 'Instrument Serif', serif;
  font-size: 20px;
  color: var(--text-2);
}

.gap-priority.high .gap-priority-num { color: var(--red); }
.gap-priority.medium .gap-priority-num { color: var(--gold); }

.gap-severity {
  font-size: 8px;
  letter-spacing: 1.5px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 3px;
  display: inline-block;
  margin-top: 4px;
}

.high-label { color: var(--red); background: var(--red-soft); }
.medium-label { color: var(--gold); background: var(--gold-soft); }

.gap-impact-chip {
  font-size: 11px;
  color: var(--green);
  background: var(--green-soft);
  padding: 3px 8px;
  border-radius: 5px;
  display: inline-block;
  margin-top: 4px;
}

/* Expand/collapse */
.gap-expand {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.gap-card.expanded .gap-expand { max-height: 400px; }

.gap-arrow {
  font-size: 16px;
  color: var(--text-4);
  transition: all 0.3s;
}

.gap-card.expanded .gap-arrow {
  transform: rotate(90deg);
  color: var(--gold-dim);
}
```

### 4.7 X-Ray Hero (Optimize)

Network visualization with clarity score overlay.

```html
<div class="xray-container">
  <div class="xray-network">
    <canvas id="networkCanvas"></canvas>
  </div>
  <div class="xray-glass"></div>
  <div class="xray-content">
    <div class="xray-eyebrow">Nettverksanalyse</div>
    <span class="xray-score">78</span>
    <div class="xray-headline"><em>48</em> kombinasjoner aktive</div>
    <div class="xray-desc">2 strukturelle gap begrenser nettverket</div>
  </div>
  <div class="xray-legend">
    <div class="legend-item"><div class="legend-dot garment"></div> Plagg</div>
    <div class="legend-item"><div class="legend-dot link"></div> Kobling</div>
    <div class="legend-item"><div class="legend-dot gap"></div> Gap</div>
  </div>
</div>
```

```css
.xray-container {
  margin: 14px 16px 24px;
  border-radius: var(--r);
  overflow: hidden;
  position: relative;
  height: 290px;
  background: var(--card-raised);
  box-shadow: 0 28px 90px rgba(0,0,0,0.65); /* L3 */
}

.xray-container::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at 30% 20%, rgba(255,255,255,0.03), transparent 60%);
  z-index: 4;
  pointer-events: none;
}

.xray-glass {
  position: absolute;
  inset: 0;
  z-index: 1;
  background: rgba(26,23,20,0.35);
  backdrop-filter: blur(1.5px);
}

.xray-score {
  font-family: 'Instrument Serif', serif;
  font-size: 48px;
  color: var(--gold);
  line-height: 1;
}

.legend-dot { width: 6px; height: 6px; border-radius: 50%; }
.legend-dot.garment { background: var(--gold); }
.legend-dot.link { background: var(--green); opacity: 0.6; }
.legend-dot.gap { background: var(--red); }
```

### 4.8 Clarity Ring (Dashboard/Evolution)

```html
<div class="pulse-ring-area">
  <svg viewBox="0 0 80 80">
    <circle class="pr-bg" cx="40" cy="40" r="34"/>
    <circle class="pr-fill" cx="40" cy="40" r="34"/>
  </svg>
  <div class="pulse-ring-center">
    <span class="pulse-score">78</span>
    <span class="pulse-score-label">Clarity</span>
  </div>
</div>
```

```css
.pulse-ring-area {
  flex-shrink: 0;
  position: relative;
  width: 80px;
  height: 80px;
}

.pulse-ring-area::before {
  content: '';
  position: absolute;
  inset: -12px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(201,169,110,0.15) 0%, rgba(201,169,110,0.04) 50%, transparent 70%);
  animation: ringGlow 3s ease-in-out infinite alternate;
}

.pr-bg { fill: none; stroke: var(--border); stroke-width: 4; }

.pr-fill {
  fill: none;
  stroke: var(--gold);
  stroke-width: 4;
  stroke-linecap: round;
  stroke-dasharray: 213.6;
  stroke-dashoffset: 213.6;
  animation: ringFill 1.2s ease-out 0.4s forwards;
}

/* 78% fill: dashoffset = 213.6 * (1 - 0.78) = 47 */

.pulse-score {
  font-family: 'Instrument Serif', serif;
  font-size: 28px;
  color: var(--text);
  line-height: 1;
}
```

### 4.9 Milestone Timeline (Evolution)

```html
<div class="milestones">
  <div class="milestone">
    <div class="ms-dot-col"><div class="ms-dot now"></div></div>
    <div class="ms-card highlight">
      <div class="ms-date">Feb 2026</div>
      <div class="ms-title">Balansen snudde</div>
      <div class="ms-desc">Overdel/underdel-ratio gikk fra 3:1 til 1.5:1</div>
      <div class="ms-impact">↗ +14 clarity</div>
    </div>
  </div>
</div>
```

```css
.milestones {
  padding: 0 16px 18px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  position: relative;
}

/* Vertical timeline line */
.milestones::before {
  content: '';
  position: absolute;
  left: 28px;
  top: 12px;
  bottom: 12px;
  width: 1px;
  background: linear-gradient(180deg, var(--gold), var(--border) 70%, transparent);
}

.ms-dot.gold { background: var(--gold); }
.ms-dot.dim { background: var(--border-light); }
.ms-dot.now {
  background: var(--bg);
  border: 2px solid var(--gold);
  box-shadow: 0 0 0 3px var(--gold-soft);
}

.ms-card {
  flex: 1;
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--r-sm);
  padding: 14px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
}

.ms-card.highlight {
  border-color: rgba(201,169,110,0.2);
  background: rgba(201,169,110,0.03);
}

.ms-title {
  font-family: 'Instrument Serif', serif;
  font-size: 15px;
  color: var(--text);
}

.ms-impact {
  font-size: 11px;
  color: var(--green);
  margin-top: 6px;
}
```

### 4.10 Floating Cards (Profile)

```css
.float-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  background: rgba(35,28,24,0.85);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(201,169,110,0.08);
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
  cursor: pointer;
  transition: all .35s cubic-bezier(.16,1,.3,1);
}

.float-card:hover {
  transform: translateX(4px) translateY(-3px) scale(1.01);
  border-color: rgba(201,169,110,0.15);
  box-shadow: 0 16px 48px rgba(0,0,0,0.45);
}
```

---

## 5. Animations

### 5.1 Standard Entrance

```css
@keyframes up {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Usage: stagger with increasing delays */
.element:nth-child(1) { animation: up 0.4s ease-out 0s backwards; }
.element:nth-child(2) { animation: up 0.4s ease-out 0.05s backwards; }
.element:nth-child(3) { animation: up 0.4s ease-out 0.1s backwards; }
```

### 5.2 Breathing / Glow

```css
@keyframes ringGlow {
  0% { opacity: 0.6; transform: scale(0.95); }
  100% { opacity: 1; transform: scale(1.05); }
}
/* Duration: 3s ease-in-out infinite alternate */

@keyframes systemPulse {
  0%, 100% { transform: scale(1); opacity: 0.85; }
  50% { transform: scale(1.02); opacity: 1; }
}
/* Duration: 4s ease-in-out infinite */

@keyframes gapPulse {
  0%, 100% { opacity: 0.5; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.4); }
}
/* Duration: 2s ease-in-out infinite */

@keyframes ringPulse {
  0% { opacity: 0.5; transform: scale(0.95); }
  100% { opacity: 0; transform: scale(1.15); }
}
/* Duration: 2.5s ease-out infinite */
```

### 5.3 Hover Standard

```css
transition: all .35s cubic-bezier(.16,1,.3,1);

/* Card hover */
transform: translateY(-3px) scale(1.01);

/* Card press */
transform: scale(.98);
```

### 5.4 Expand / Collapse

```css
max-height: 0;
overflow: hidden;
transition: max-height 0.4s cubic-bezier(0.16, 1, 0.3, 1);

/* Expanded: */
max-height: 400px;
```

---

## 6. Garment Color Palette

Actual garment colors used across the system:

```
Warm:        #8B6B4A  #8B5537  #C4976A  #C4B08A  #C4AA82  #B8845A
Cool:        #2C3E50  #1A2A3A  #5B7B9A  #7A9AB0  #8AAAC8  #8AB0D0
Neutral:     #1A1A1A  #686870  #808088  #6A6A72  #8A8A8A
Green/Olive: #5A6B3A  #6B8B4A  #7A9B5A  #8AAB6E
Accent:      #B4705A  #B8707A  #C8886A
```

---

## 7. SVG Garment Silhouettes

All garments use simplified SVG silhouettes (60x60 viewBox). Examples:

```html
<!-- T-shirt / Overdel -->
<svg width="60" height="60" viewBox="0 0 60 60" fill="none">
  <path d="M20 15 L15 20 L10 18 L8 25 L15 27 L15 45 L45 45 L45 27 L52 25 L50 18 L45 20 L40 15 Z"
        stroke="currentColor" stroke-width="1.2" fill="none" opacity="0.5"/>
</svg>

<!-- Pants / Underdel -->
<svg width="60" height="60" viewBox="0 0 60 60" fill="none">
  <path d="M18 12 L18 30 L15 48 L25 48 L30 32 L35 48 L45 48 L42 30 L42 12 Z"
        stroke="currentColor" stroke-width="1.2" fill="none" opacity="0.5"/>
</svg>

<!-- Shoe / Sko -->
<svg width="60" height="60" viewBox="0 0 60 60" fill="none">
  <path d="M12 35 L15 25 L40 25 L48 30 L50 35 L48 38 L10 38 Z"
        stroke="currentColor" stroke-width="1.2" fill="none" opacity="0.5"/>
</svg>

<!-- Jacket / Ytterlag -->
<svg width="60" height="60" viewBox="0 0 60 60" fill="none">
  <path d="M18 12 L12 18 L8 15 L5 25 L12 28 L10 48 L28 48 L28 20 L32 20 L32 48 L50 48 L48 28 L55 25 L52 15 L48 18 L42 12 Z"
        stroke="currentColor" stroke-width="1.2" fill="none" opacity="0.4"/>
</svg>
```

SVGs use `currentColor` so they inherit from parent color, or set explicit color with `color: var(--text-3)` on parent.

---

## 8. Screen-Specific Notes

### Pulse (Dashboard)
- Hero: Clarity ring (78) + status text
- Feed items: recent wardrobe events
- Quick actions: links to other screens
- Ambient: warm gold gradient at top

### Wardrobe
- View tabs: Plagg | Antrekk (garments vs outfits)
- Metrics bar: garment count, clarity, archetype
- Map link: "View wardrobe map" with ◎ icon
- 2-column garment grid
- Outfit cards below
- Key garment badge: ★ (anchor-star)

### Studio
- 3 zones: Outfit Canvas → System Feedback → Garment Selector
- Interactive: click garments to fill slots
- Feedback updates live (compatibility + archetype)
- Suggestion card shows swap recommendations

### Optimize
- X-Ray hero with network canvas visualization
- Large clarity number (48px, gold)
- Gap cards with severity (HIGH/MEDIUM) and impact chips
- Archetype profile bars
- Top combos section

### Evolution
- Clarity trend card with SVG sparkline
- Identity shifts timeline
- Seasonal pattern card
- Milestone timeline with dot indicators
- What-If projector card

### Profile
- Identity hero with archetype display
- Floating garment cards (animated entrance)
- Settings/preferences sections
- No active tab (accessed via menu)

---

## 9. Language

All UI copy is in **Norwegian (Bokmål)**. Key terms:

| English | Norwegian |
|---------|-----------|
| Clarity | Clarity (kept English) |
| Garment | Plagg |
| Outfit | Antrekk |
| Upper | Overdel |
| Lower | Underdel |
| Shoes | Sko |
| Outer | Ytterlag |
| Accessory | Tilbehør |
| Compatibility | Kompatibilitet |
| Archetype | Arketype |
| Gap | Gap (kept English) |
| Swap | Bytt |
| Network analysis | Nettverksanalyse |
| Combinations active | Kombinasjoner aktive |
| Suggested swap | Foreslått Bytte |
| New combination | Ny Kombinasjon |
| Build and analyze outfits | Bygg og analyser antrekk |
| System Feedback | System Feedback |
| Garment Selector | Garment Selector |
| View wardrobe map | Se garderobekart |

---

## 10. File Map

```
moodboard/
├── dashboard/coret-dashboard.html      → Pulse screen
├── wardrobe/coret_wardrobe_V3.html     → Wardrobe screen
├── wardrobe/coret-garment-detail.html  → Garment detail screen
├── studio/coret-studio.html            → Studio screen (outfit builder)
├── optimize/coret-optimize.html        → Optimize screen
├── evolution/coret-journey-interactive.html → Evolution screen
├── profile/coret-profile.html          → Profile screen
├── map/                                → Wardrobe map (planned)
└── navigation/                         → Navigation patterns (planned)
```

---

## 11. Creating New Screens

When creating a new CORET screen, use this skeleton:

```html
<!DOCTYPE html>
<html lang="no">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CORET — [Screen Name]</title>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=Instrument+Serif:ital@0;1&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #1a1714;
      --card: #221f1a;
      --card-raised: #282420;
      --border: #2e2a22;
      --border-light: #3a3530;
      --text: #EAE5DE;
      --text-2: #B0A99E;
      --text-3: #6B625C;
      --text-4: #4a4540;
      --gold: #C9A96E;
      --gold-dim: rgba(201,169,110,0.55);
      --gold-soft: rgba(201,169,110,0.10);
      --gold-glow: rgba(201,169,110,0.04);
      --green: #7A9A6E;
      --green-soft: rgba(122,154,110,0.10);
      --red: #B4705A;
      --red-soft: rgba(180,90,70,0.10);
      --r: 18px;
      --r-sm: 10px;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      background: #0e0c0a;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      font-family: 'DM Sans', sans-serif;
      color: var(--text);
      -webkit-font-smoothing: antialiased;
    }

    .phone {
      width: 375px;
      height: 812px;
      background: var(--bg);
      border-radius: 44px;
      overflow: hidden;
      position: relative;
      border: 2.5px solid #2a2520;
      box-shadow: 0 40px 100px rgba(0,0,0,0.5);
    }

    .phone::before {
      content: '';
      position: absolute;
      inset: 0;
      background:
        radial-gradient(circle at 20% 10%, rgba(255,255,255,0.04), transparent 50%),
        radial-gradient(circle at 50% 0%, rgba(201,169,110,0.08), transparent 60%);
      z-index: 1;
      pointer-events: none;
    }

    /* [Top bar, brand row, scroll, tab bar styles from Section 2] */

    /* [Section labels from Section 3] */

    /* [Screen-specific components] */

    /* [Animations from Section 5] */
  </style>
</head>
<body>
  <div class="phone">
    <div class="top-bar">
      <span>9:41</span>
      <span style="font-size:12px;color:var(--text-3);">●●●●  📶  🔋</span>
    </div>
    <div class="brand-row">
      <span class="brand">CORET</span>
      <span class="dots">•••</span>
    </div>

    <div class="scroll">
      <div class="page-title">[Screen Name]</div>
      <div class="page-sub">[Subtitle]</div>

      <!-- Screen content here -->
    </div>

    <div class="tab-bar">
      <div class="tab"><span class="tab-i">◻</span><span class="tab-l">Pulse</span></div>
      <div class="tab"><span class="tab-i">▦</span><span class="tab-l">Wardrobe</span></div>
      <div class="tab on"><span class="tab-i">✦</span><span class="tab-l">Studio</span></div>
      <div class="tab"><span class="tab-i">◎</span><span class="tab-l">Optimize</span></div>
      <div class="tab"><span class="tab-i">◈</span><span class="tab-l">Evolution</span></div>
    </div>
  </div>

  <div class="frame-label">[SCREEN NAME] — [Description]</div>
</body>
</html>
```

---

*This spec is the complete design system as of March 2026. All values are production-ready for mockup creation.*
