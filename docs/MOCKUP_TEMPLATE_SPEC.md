# CORET Mockup Template — Complete Spec for Claude AI

> Copy this entire document as context when asking Claude AI to create new CORET screens.
> It contains everything needed: working HTML skeleton, complete CSS, all components, and real examples.

---

## What is CORET?

CORET is a wardrobe operating system. It measures structural cohesion (called "Clarity") and guides optimization. Dark, warm, premium aesthetic — NOT a fashion app, NOT a shopping platform.

**Language:** Norwegian (Bokmål) for all UI copy.

**Screens (tab order):** Pulse | Wardrobe | Studio | Optimize | Evolution
Profile exists but is accessed via menu, not tab bar.

---

## 1. Complete HTML Skeleton

Every CORET screen uses this exact structure. Copy it, then fill in screen-specific content.

```html
<!DOCTYPE html>
<html lang="no">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=375, initial-scale=1.0">
<title>CORET — [Screen Name]</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Instrument+Serif:ital@0;1&display=swap" rel="stylesheet">
<style>
  /* ═══ TOKENS ═══ */
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
    --amber: #C4944A;
    --r: 18px;
    --r-sm: 10px;
  }

  /* ═══ RESET ═══ */
  * { margin: 0; padding: 0; box-sizing: border-box; }

  /* ═══ BODY ═══ */
  body {
    font-family: 'DM Sans', sans-serif;
    background: #0e0c0a;
    color: var(--text);
    display: flex;
    justify-content: center;
    padding: 40px 20px 60px;
    -webkit-font-smoothing: antialiased;
  }

  /* ═══ PHONE FRAME ═══ */
  .phone {
    width: 393px;
    height: 852px;
    background:
      radial-gradient(circle at 20% 10%, rgba(255,255,255,0.04), transparent 40%),
      radial-gradient(circle at 80% 90%, rgba(201,169,110,0.05), transparent 50%),
      #1A1714;
    border-radius: 44px;
    border: 2.5px solid #2a2520;
    overflow: hidden;
    position: relative;
    box-shadow: 0 40px 100px rgba(0,0,0,0.5);
  }

  /* Cinematic lighting overlay */
  .phone::before {
    content: '';
    position: absolute;
    inset: 0;
    pointer-events: none;
    z-index: 0;
    background: radial-gradient(circle at 20% 10%, rgba(255,255,255,0.04), transparent 50%);
  }

  /* Film grain texture (subtle) */
  .scr::after {
    content: '';
    position: fixed;
    inset: 0;
    opacity: 0.012;
    pointer-events: none;
    z-index: 100;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  }

  /* ═══ SCROLL CONTAINER ═══ */
  .scr {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    scrollbar-width: none;
  }
  .scr::-webkit-scrollbar { display: none; }

  /* ═══ STATUS BAR ═══ */
  .sb {
    padding: 14px 24px 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 15px;
    font-weight: 600;
    color: var(--text-2);
    flex-shrink: 0;
  }

  /* ═══ BRAND ═══ */
  .brand {
    font-family: 'Instrument Serif', serif;
    font-size: 14px;
    letter-spacing: 2px;
    color: var(--gold-dim);
    padding: 8px 20px 0;
    text-shadow: 0 0 18px rgba(201,169,110,0.2);
  }

  /* ═══ PAGE HEADER ═══ */
  .tab-header {
    padding: 10px 20px 4px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }
  .tab-title {
    font-family: 'Instrument Serif', serif;
    font-size: 30px;
    font-weight: 400;
    line-height: 1.25;
  }
  .tab-meta {
    padding: 0 20px 10px;
    font-size: 12px;
    color: var(--text-3);
    letter-spacing: 0.5px;
    flex-shrink: 0;
  }

  /* ═══ SECTION LABEL WITH GOLD LINE ═══ */
  .section-label {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 14px 20px 0;
  }
  .section-label span:first-child {
    font-size: 9px;
    letter-spacing: 3px;
    text-transform: uppercase;
    color: var(--text-3);
    font-weight: 500;
    white-space: nowrap;
  }
  .section-label span:last-child {
    flex: 1;
    height: 1px;
    background: linear-gradient(90deg, rgba(201,169,110,0.15), transparent);
  }

  /* ═══ VIEW TOGGLE TABS ═══ */
  .view-tabs {
    display: flex;
    gap: 24px;
    padding: 0 20px 14px;
    flex-shrink: 0;
  }
  .vt-tab {
    font-size: 14px;
    font-weight: 400;
    color: var(--text-4);
    cursor: pointer;
    padding-bottom: 6px;
    border: none;
    border-bottom: 1.5px solid transparent;
    background: none;
    font-family: inherit;
    letter-spacing: 0.3px;
    transition: all 0.3s;
  }
  .vt-tab.active { color: var(--gold); border-bottom-color: var(--gold); }
  .vt-tab:not(.active):hover { color: var(--text-3); }

  /* ═══ SHADOW TIERS ═══ */
  /*
    L1 (subtle):  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
    L2 (cards):   box-shadow: 0 16px 48px rgba(0,0,0,0.45), 0 0 0 1px rgba(255,255,255,0.03) inset;
    L3 (hero):    box-shadow: 0 28px 90px rgba(0,0,0,0.65);
  */

  /* ═══ CARD MATERIAL (frosted glass) ═══ */
  .glass-card {
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid var(--border);
    border-radius: var(--r);
    box-shadow: 0 16px 48px rgba(0,0,0,0.45), 0 0 0 1px rgba(255,255,255,0.03) inset;
  }

  /* Gold-border variant for hero/feedback cards */
  .glass-card-gold {
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid rgba(201,169,110,0.10);
    border-radius: var(--r);
    box-shadow: 0 16px 48px rgba(0,0,0,0.45), 0 0 0 1px rgba(255,255,255,0.03) inset;
  }

  /* ═══ METRICS BAR ═══ */
  .metrics {
    display: flex;
    margin: 0 16px 14px;
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid var(--border);
    border-radius: var(--r);
    overflow: hidden;
    box-shadow: 0 8px 24px rgba(0,0,0,0.3);
  }
  .metric {
    flex: 1;
    text-align: center;
    padding: 14px 6px;
    border-right: 1px solid var(--border);
  }
  .metric:last-child { border-right: none; }
  .metric-val {
    font-family: 'Instrument Serif', serif;
    font-size: 22px;
    color: var(--text);
    margin-bottom: 2px;
    text-shadow: 0 0 14px rgba(201,169,110,0.15);
  }
  .metric-label {
    font-size: 8px;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: var(--text-3);
  }

  /* ═══ GARMENT CARD ═══ */
  .g-card {
    border-radius: 12px;
    overflow: hidden;
    cursor: pointer;
    transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
    position: relative;
    border: 1.5px solid rgba(255,255,255,0.04);
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    animation: fadeUp 0.45s ease-out backwards;
    flex: 0 0 140px;
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
    height: 140px;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
    border-radius: 12px 12px 0 0;
  }
  .g-visual::before {
    content: '';
    position: absolute;
    inset: 0;
    pointer-events: none;
  }
  .g-visual::after {
    content: '';
    position: absolute;
    inset: 0;
    pointer-events: none;
    background:
      linear-gradient(180deg, transparent 50%, rgba(26,23,20,0.8) 100%),
      radial-gradient(ellipse at 50% 0%, rgba(255,255,255,0.03), transparent 70%);
  }

  /* Image-ready */
  .g-visual img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    position: relative;
    z-index: 0;
  }

  /* SVG floating effect */
  .g-visual svg {
    position: relative;
    z-index: 1;
    filter: drop-shadow(0 4px 12px rgba(0,0,0,0.4));
    transform: translateY(-2px);
    transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
  }
  .g-card:hover .g-visual svg { transform: translateY(-5px); }

  /* Badges */
  .sil-tag {
    position: absolute;
    bottom: 8px;
    left: 8px;
    z-index: 2;
    font-size: 8px;
    letter-spacing: 0.8px;
    text-transform: uppercase;
    padding: 3px 7px;
    border-radius: 4px;
    background: rgba(0,0,0,0.3);
    backdrop-filter: blur(8px);
    border: 1px solid rgba(255,255,255,0.06);
  }
  .anchor-star {
    position: absolute;
    top: 8px;
    right: 8px;
    z-index: 2;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: rgba(201,169,110,0.15);
    border: 1px solid rgba(201,169,110,0.25);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 9px;
    color: var(--gold);
  }

  .g-info {
    padding: 12px 12px 14px;
    background: rgba(35,28,24,0.9);
  }
  .g-name {
    font-size: 12px;
    font-weight: 500;
    color: var(--text);
    margin-bottom: 2px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .g-meta {
    font-size: 9px;
    letter-spacing: 0.5px;
    color: var(--text-4);
  }
  .g-meta .hl { color: var(--gold-dim); }

  /* ═══ GARMENT COLOR GRADIENTS ═══ */
  .g-brown .g-visual { background: linear-gradient(155deg, #2E1F16 0%, #261A14 50%, #1E1510 100%); }
  .g-brown .g-visual::before { background: radial-gradient(ellipse at 45% 35%, rgba(160,95,50,0.18) 0%, transparent 55%), radial-gradient(ellipse at 65% 70%, rgba(120,70,30,0.10) 0%, transparent 50%); }
  .g-brown .sil-tag { color: #C4976A; }

  .g-navy .g-visual { background: linear-gradient(155deg, #161C28 0%, #121822 50%, #0E141C 100%); }
  .g-navy .g-visual::before { background: radial-gradient(ellipse at 40% 30%, rgba(44,62,100,0.18) 0%, transparent 55%), radial-gradient(ellipse at 60% 70%, rgba(30,50,80,0.10) 0%, transparent 50%); }
  .g-navy .sil-tag { color: #7B9AB8; }

  .g-black .g-visual { background: linear-gradient(155deg, #1C1C20 0%, #18181C 50%, #141416 100%); }
  .g-black .g-visual::before { background: radial-gradient(ellipse at 48% 32%, rgba(120,120,140,0.08) 0%, transparent 50%), radial-gradient(ellipse at 55% 70%, rgba(80,80,100,0.06) 0%, transparent 50%); }
  .g-black .sil-tag { color: #9090A0; }

  .g-olive .g-visual { background: linear-gradient(155deg, #1C2416 0%, #182014 50%, #141C10 100%); }
  .g-olive .g-visual::before { background: radial-gradient(ellipse at 38% 28%, rgba(90,130,55,0.18) 0%, transparent 55%), radial-gradient(ellipse at 62% 68%, rgba(60,90,30,0.10) 0%, transparent 50%); }
  .g-olive .sil-tag { color: #8AAB6E; }

  .g-charcoal .g-visual { background: linear-gradient(155deg, #1A1C20 0%, #18191D 50%, #141518 100%); }
  .g-charcoal .g-visual::before { background: radial-gradient(ellipse at 44% 32%, rgba(80,90,100,0.10) 0%, transparent 55%), radial-gradient(ellipse at 58% 65%, rgba(60,65,75,0.08) 0%, transparent 50%); }
  .g-charcoal .sil-tag { color: #8A919A; }

  .g-white .g-visual { background: linear-gradient(155deg, #1E2024 0%, #1A1C20 50%, #16181C 100%); }
  .g-white .g-visual::before { background: radial-gradient(ellipse at 45% 30%, rgba(210,220,235,0.10) 0%, transparent 55%), radial-gradient(ellipse at 55% 68%, rgba(180,195,210,0.07) 0%, transparent 50%); }
  .g-white .sil-tag { color: #B0BCC8; }

  .g-beige .g-visual { background: linear-gradient(155deg, #24201A 0%, #201C16 50%, #1C1812 100%); }
  .g-beige .g-visual::before { background: radial-gradient(ellipse at 42% 32%, rgba(196,185,154,0.12) 0%, transparent 55%), radial-gradient(ellipse at 60% 68%, rgba(160,140,110,0.08) 0%, transparent 50%); }
  .g-beige .sil-tag { color: #C4B89A; }

  .g-burgundy .g-visual { background: linear-gradient(155deg, #261618 0%, #201214 50%, #1A0E10 100%); }
  .g-burgundy .g-visual::before { background: radial-gradient(ellipse at 40% 30%, rgba(140,40,55,0.16) 0%, transparent 55%), radial-gradient(ellipse at 62% 70%, rgba(100,25,40,0.10) 0%, transparent 50%); }
  .g-burgundy .sil-tag { color: #B8707A; }

  .g-rust .g-visual { background: linear-gradient(155deg, #281A14 0%, #221610 50%, #1C120E 100%); }
  .g-rust .g-visual::before { background: radial-gradient(ellipse at 38% 30%, rgba(180,90,50,0.16) 0%, transparent 55%), radial-gradient(ellipse at 64% 68%, rgba(140,60,30,0.10) 0%, transparent 50%); }
  .g-rust .sil-tag { color: #C8886A; }

  .g-blue .g-visual { background: linear-gradient(155deg, #161E2A 0%, #121A24 50%, #0E161E 100%); }
  .g-blue .g-visual::before { background: radial-gradient(ellipse at 42% 28%, rgba(100,140,190,0.14) 0%, transparent 55%), radial-gradient(ellipse at 60% 68%, rgba(70,110,160,0.08) 0%, transparent 50%); }
  .g-blue .sil-tag { color: #8AB0D0; }

  .g-grey .g-visual { background: linear-gradient(155deg, #222226 0%, #1E1E22 50%, #1A1A1E 100%); }
  .g-grey .g-visual::before { background: radial-gradient(ellipse at 44% 30%, rgba(140,140,160,0.08) 0%, transparent 55%), radial-gradient(ellipse at 58% 68%, rgba(100,100,120,0.06) 0%, transparent 50%); }
  .g-grey .sil-tag { color: #9A9AA0; }

  .g-cream .g-visual { background: linear-gradient(155deg, #2C2820 0%, #28241C 50%, #222018 100%); }
  .g-cream .g-visual::before { background: radial-gradient(ellipse at 44% 32%, rgba(220,210,190,0.10) 0%, transparent 55%), radial-gradient(ellipse at 58% 68%, rgba(180,170,150,0.07) 0%, transparent 50%); }
  .g-cream .sil-tag { color: #C8C0A8; }

  /* Gap card variant */
  .g-card.gap {
    border: 1.5px dashed rgba(201,169,110,0.15);
    background: rgba(201,169,110,0.02);
    flex: 0 0 140px;
  }
  .g-card.gap .g-visual {
    background: transparent;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 6px;
  }
  .g-card.gap .g-visual::before,
  .g-card.gap .g-visual::after { display: none; }
  .g-card.gap .g-info { background: transparent; }
  .g-card.gap:hover {
    border-color: rgba(201,169,110,0.3);
    background: rgba(201,169,110,0.04);
  }
  .gap-plus {
    font-size: 22px;
    color: var(--gold-dim);
    opacity: 0.4;
    font-weight: 300;
  }
  .gap-label {
    font-size: 9px;
    color: var(--text-4);
    letter-spacing: 0.5px;
    text-align: center;
  }

  /* ═══ GARMENT GRID (horizontal scroll) ═══ */
  .garment-grid {
    display: flex;
    gap: 14px;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    -webkit-overflow-scrolling: touch;
    padding: 0 16px 6px;
    scrollbar-width: none;
  }
  .garment-grid::-webkit-scrollbar { display: none; }

  /* ═══ LAYER HEADERS ═══ */
  .layer-section { padding: 0; margin-bottom: 14px; }
  .layer-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 4px 20px 10px;
  }
  .layer-left { display: flex; align-items: center; gap: 8px; }
  .layer-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--gold);
    opacity: 0.5;
  }
  .layer-name {
    font-size: 9px;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: var(--text-3);
    font-weight: 500;
  }
  .layer-count { font-size: 10px; color: var(--text-4); }

  /* ═══ OUTFIT CARD ═══ */
  .o-card {
    border-radius: 16px;
    overflow: hidden;
    margin-bottom: 14px;
    cursor: pointer;
    transition: all 0.35s;
    position: relative;
    border: 1px solid rgba(255,255,255,0.05);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    animation: fadeUp 0.5s ease-out backwards;
  }
  .o-card:hover {
    transform: translateY(-3px) scale(1.01);
    box-shadow: 0 16px 48px rgba(0,0,0,0.45);
    border-color: rgba(255,255,255,0.08);
  }
  .o-card:active { transform: scale(.98); }
  .o-card::before {
    content: '';
    position: absolute;
    inset: 0;
    pointer-events: none;
    z-index: 0;
  }
  .o-visual {
    height: 150px;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    z-index: 1;
  }
  .o-info {
    padding: 4px 18px 6px;
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    position: relative;
    z-index: 1;
  }
  .o-info-left { display: flex; flex-direction: column; gap: 6px; }
  .o-name {
    font-family: 'Instrument Serif', serif;
    font-size: 19px;
    font-weight: 400;
    font-style: italic;
  }
  .o-pills { display: flex; gap: 5px; }
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
  .o-status {
    font-family: 'Instrument Serif', serif;
    font-size: 13px;
    font-weight: 400;
    font-style: italic;
    padding: 4px 12px;
    border-radius: 6px;
    white-space: nowrap;
    letter-spacing: 0.3px;
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

  /* Outfit gradient themes */
  .o-winter { background: linear-gradient(155deg, #352218 0%, #241A24 40%, #1C1622 100%); }
  .o-winter::before { background: radial-gradient(ellipse at 38% 30%, rgba(160,95,50,0.16) 0%, transparent 50%), radial-gradient(ellipse at 68% 65%, rgba(44,62,80,0.12) 0%, transparent 45%); }

  .o-summer { background: linear-gradient(155deg, #1E2430 0%, #1A2236 40%, #18202E 100%); }
  .o-summer::before { background: radial-gradient(ellipse at 42% 22%, rgba(170,195,230,0.14) 0%, transparent 50%), radial-gradient(ellipse at 62% 72%, rgba(140,170,200,0.08) 0%, transparent 45%); }

  .o-street { background: linear-gradient(155deg, #1E2816 0%, #1A2214 40%, #141C12 100%); }
  .o-street::before { background: radial-gradient(ellipse at 32% 28%, rgba(100,130,60,0.16) 0%, transparent 48%), radial-gradient(ellipse at 68% 68%, rgba(40,55,30,0.12) 0%, transparent 45%); }

  .o-black { background: linear-gradient(155deg, #1E1E22 0%, #1A1A1E 40%, #161618 100%); }
  .o-black::before { background: radial-gradient(ellipse at 48% 25%, rgba(190,190,210,0.07) 0%, transparent 48%), radial-gradient(ellipse at 52% 72%, rgba(120,120,140,0.05) 0%, transparent 45%); }

  /* Soft divider (replaces border-top for sections) */
  .soft-divider {
    border-top: none;
    background-image: linear-gradient(to right, transparent, rgba(255,255,255,0.06), transparent);
    background-size: 100% 1px;
    background-repeat: no-repeat;
    background-position: top;
  }

  /* ═══ FEEDBACK CARD (Studio) ═══ */
  .feedback-card {
    margin: 10px 16px 16px;
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
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
    text-shadow: 0 0 14px rgba(201,169,110,0.15);
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

  /* ═══ SUGGESTION CARD ═══ */
  .suggestion-card {
    margin: 0 16px 16px;
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid var(--border);
    border-radius: var(--r);
    padding: 18px 20px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.35);
    cursor: pointer;
    transition: all .35s cubic-bezier(.16,1,.3,1);
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  .suggestion-card:hover {
    border-color: var(--border-light);
    transform: translateY(-2px);
  }
  .gap-impact-chip {
    display: inline-flex;
    align-items: center;
    gap: 3px;
    padding: 3px 8px;
    background: var(--green-soft);
    border-radius: 4px;
    font-size: 10px;
    color: var(--green);
    flex-shrink: 0;
  }

  /* ═══ OUTFIT SLOTS (Studio) ═══ */
  .outfit-canvas {
    margin: 14px 16px 16px;
    border-radius: var(--r);
    background: rgba(38,32,28,0.9);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    box-shadow: 0 28px 90px rgba(0,0,0,0.65);
    padding: 24px 20px 22px;
  }
  .slots-row { display: flex; gap: 8px; margin-bottom: 14px; }
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
    position: relative;
    overflow: hidden;
  }
  .slot.filled {
    border: 1px solid rgba(201,169,110,0.10);
    background: var(--card);
  }
  .slot.empty {
    border: 1.5px dashed rgba(201,169,110,0.15);
    background: transparent;
  }
  .slot:hover { border-color: var(--border-light); transform: translateY(-2px); }
  .slot:active { transform: scale(0.96); }
  .slot svg { width: 34px; height: 34px; color: var(--text-2); }
  .slot.empty svg { width: 18px; height: 18px; color: var(--text-4); }
  .slot-label { font-size: 9px; color: var(--text-3); letter-spacing: 0.3px; }

  /* ═══ GAP CARD (Optimize) ═══ */
  .gap-card {
    margin: 0 16px 14px;
    background: rgba(35,28,24,0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
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
  .gap-card.expanded { border-color: rgba(201,169,110,0.2); }
  .gap-top { display: flex; align-items: center; gap: 14px; padding: 18px; }
  .gap-priority {
    width: 40px; height: 40px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    position: relative;
  }
  .gap-priority.high { background: var(--red-soft); }
  .gap-priority.medium { background: var(--gold-soft); }
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
    text-shadow: 0 0 14px rgba(201,169,110,0.15);
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
  .gap-expand {
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.4s cubic-bezier(0.16, 1, 0.3, 1);
  }
  .gap-card.expanded .gap-expand { max-height: 400px; }

  /* ═══ CLARITY RING ═══ */
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
  .pulse-ring-area svg {
    width: 80px;
    height: 80px;
    transform: rotate(-90deg);
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
  .pulse-ring-center {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  .pulse-score {
    font-family: 'Instrument Serif', serif;
    font-size: 28px;
    color: var(--text);
    line-height: 1;
    text-shadow: 0 0 14px rgba(201,169,110,0.15);
  }

  /* ═══ NAV BAR ═══ */
  .bn {
    display: flex;
    justify-content: space-around;
    align-items: center;
    padding: 8px 16px 28px;
    background: linear-gradient(transparent, rgba(26,23,20,0.92) 30%);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border-top: 1px solid rgba(201,169,110,0.06);
    flex-shrink: 0;
  }
  .ni {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 3px;
    opacity: 0.25;
    position: relative;
  }
  .ni.a { opacity: 1; }
  .ni.a::before {
    content: '';
    position: absolute;
    top: -4px;
    left: 50%;
    transform: translateX(-50%);
    width: 36px;
    height: 36px;
    background: radial-gradient(circle, rgba(201,169,110,0.12) 0%, transparent 70%);
    pointer-events: none;
    border-radius: 50%;
  }
  .ni svg {
    width: 20px;
    height: 20px;
    stroke: var(--text-2);
    fill: none;
    stroke-width: 1.5;
    stroke-linecap: round;
    stroke-linejoin: round;
    position: relative;
    z-index: 1;
  }
  .ni.a svg { stroke: var(--gold); }
  .nl {
    font-size: 8.5px;
    letter-spacing: 0.8px;
    text-transform: uppercase;
    color: var(--text-4);
    position: relative;
    z-index: 1;
  }
  .ni.a .nl { color: var(--gold-dim); }

  /* ═══ ANIMATIONS ═══ */
  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(14px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes up {
    from { opacity: 0; transform: translateY(12px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes ringGlow {
    0% { opacity: 0.6; transform: scale(0.95); }
    100% { opacity: 1; transform: scale(1.05); }
  }
  @keyframes ringFill {
    to { stroke-dashoffset: 47; }
  }
  @keyframes ringPulse {
    0% { opacity: 0.5; transform: scale(0.95); }
    100% { opacity: 0; transform: scale(1.15); }
  }
  @keyframes gapPulse {
    0%, 100% { opacity: 0.5; transform: scale(1); }
    50% { opacity: 1; transform: scale(1.4); }
  }
  @keyframes systemPulse {
    0%, 100% { transform: scale(1); opacity: 0.85; }
    50% { transform: scale(1.02); opacity: 1; }
  }

  /* Stagger delays */
  .g-card:nth-child(1) { animation-delay: 0s; }
  .g-card:nth-child(2) { animation-delay: 0.04s; }
  .g-card:nth-child(3) { animation-delay: 0.08s; }
  .g-card:nth-child(4) { animation-delay: 0.12s; }
  .g-card:nth-child(5) { animation-delay: 0.16s; }
  .g-card:nth-child(6) { animation-delay: 0.20s; }
</style>
</head>
<body>

<div class="phone"><div class="scr">

  <!-- STATUS BAR -->
  <div class="sb">
    <span>9:41</span>
    <span style="font-size:11px; opacity:0.3;">●●●●  📶  🔋</span>
  </div>
  <div style="padding: 8px 20px 0;">
    <span class="brand">CORET</span>
  </div>

  <!-- PAGE HEADER -->
  <div class="tab-header">
    <div class="tab-title">[Screen Name]</div>
  </div>
  <div class="tab-meta">[subtitle / meta info]</div>

  <!-- CONTENT GOES HERE -->

  <!-- NAV BAR -->
  <div class="bn">
    <div class="ni">
      <svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
      <span class="nl">Pulse</span>
    </div>
    <div class="ni">
      <svg viewBox="0 0 24 24"><path d="M21 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v3"/><path d="M21 16v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3"/><rect x="1" y="8" width="22" height="8" rx="2"/></svg>
      <span class="nl">Wardrobe</span>
    </div>
    <div class="ni">
      <svg viewBox="0 0 24 24"><polygon points="12,2 15,9 22,9 16,14 18,21 12,17 6,21 8,14 2,9 9,9"/></svg>
      <span class="nl">Studio</span>
    </div>
    <div class="ni">
      <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
      <span class="nl">Optimize</span>
    </div>
    <div class="ni">
      <svg viewBox="0 0 24 24"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
      <span class="nl">Evolution</span>
    </div>
  </div>

</div></div>

</body>
</html>
```

---

## 2. SVG Garment Silhouettes

Use these exact SVGs for garment types. They use `stroke="currentColor"` so they inherit color from parent.

### T-shirt / Overdel
```html
<svg width="34" height="42" viewBox="0 0 34 40" fill="none">
  <path d="M9 4C9 2 25 2 25 4L27 8C27 10 32 10 34 14V16C32 18 28 18 27 16V34C27 38 7 38 7 34V16C6 18 2 18 0 16V14C2 10 7 10 7 8L9 4Z" stroke="currentColor" stroke-width="1.2" opacity="0.6"/>
</svg>
```

### Skjorte (shirt with center line)
```html
<svg width="34" height="42" viewBox="0 0 40 52" fill="none">
  <path d="M11 4C11 2 29 2 29 4L31 12C31 14 38 14 40 18V46C40 50 36 52 32 52H8C4 52 0 50 0 46V18C2 14 9 14 9 12L11 4Z" stroke="currentColor" stroke-width="1.3" opacity="0.6"/>
  <line x1="20" y1="4" x2="20" y2="52" stroke="currentColor" stroke-width="0.5" opacity="0.25"/>
</svg>
```

### Bukse / Pants
```html
<svg width="28" height="42" viewBox="0 0 32 48" fill="none">
  <path d="M3 0H29C31 0 32 2 32 4V20L23 48H18L16 24L14 48H9L0 20V4C0 2 1 0 3 0Z" stroke="currentColor" stroke-width="1.3" opacity="0.5"/>
</svg>
```

### Shorts
```html
<svg width="30" height="28" viewBox="0 0 34 30" fill="none">
  <path d="M3 0H31C33 0 34 2 34 4V14L25 30H20L17 16L14 30H9L0 14V4C0 2 1 0 3 0Z" stroke="currentColor" stroke-width="1.3" opacity="0.5"/>
</svg>
```

### Sko / Shoe
```html
<svg width="30" height="14" viewBox="0 0 34 16" fill="none">
  <path d="M2 7C2 4 5 1 10 1H13L16 0H18L21 1H24C29 1 32 4 32 7V10C32 13 29 16 24 16H10C5 16 2 13 2 10V7Z" stroke="currentColor" stroke-width="1.3" opacity="0.55"/>
</svg>
```

### Frakk / Coat (large, with center line)
```html
<svg width="46" height="58" viewBox="0 0 52 66" fill="none">
  <path d="M13 7C13 3 39 3 39 7L42 18C42 20 50 22 52 26V52C52 56 48 58 44 58H39V62C39 66 13 66 13 62V58H8C4 58 0 56 0 52V26C2 22 10 20 10 18L13 7Z" stroke="currentColor" stroke-width="1.2" opacity="0.6"/>
  <line x1="26" y1="7" x2="26" y2="62" stroke="currentColor" stroke-width="0.5" opacity="0.3"/>
</svg>
```

### Jakke / Jacket
```html
<svg width="42" height="52" viewBox="0 0 48 56" fill="none">
  <path d="M12 6C12 3 36 3 36 6L38 14C38 16 46 16 48 20V44C48 48 44 50 40 50H36V52C36 56 12 56 12 52V50H8C4 50 0 48 0 44V20C2 16 10 16 10 14L12 6Z" stroke="currentColor" stroke-width="1.3" opacity="0.55"/>
</svg>
```

### Hoodie (with hood detail)
```html
<svg width="36" height="44" viewBox="0 0 38 46" fill="none">
  <path d="M10 6C10 2 28 2 28 6L30 10C30 12 36 12 38 16V18C36 20 32 20 30 18V40C30 44 8 44 8 40V18C6 20 2 20 0 18V16C2 12 8 12 8 10L10 6Z" stroke="currentColor" stroke-width="1.3" opacity="0.55"/>
  <path d="M14 2C14 2 16 8 19 8C22 8 24 2 24 2" stroke="currentColor" stroke-width="0.7" opacity="0.3"/>
</svg>
```

### Cargo Pants (with pocket details)
```html
<svg width="30" height="42" viewBox="0 0 34 48" fill="none">
  <path d="M3 0H31C33 0 34 2 34 4V20L25 48H20L17 24L14 48H9L0 20V4C0 2 1 0 3 0Z" stroke="currentColor" stroke-width="1.3" opacity="0.5"/>
  <rect x="4" y="18" width="5" height="5" rx="1" stroke="currentColor" stroke-width="0.5" opacity="0.25"/>
  <rect x="25" y="18" width="5" height="5" rx="1" stroke="currentColor" stroke-width="0.5" opacity="0.25"/>
</svg>
```

---

## 3. Norwegian UI Vocabulary

| English | Norwegian |
|---------|-----------|
| Clarity | Clarity (kept) |
| Garment | Plagg |
| Outfit | Antrekk |
| Upper body | Overdel |
| Lower body | Underdel |
| Shoes | Sko |
| Outer layer | Ytterlag |
| Mid layer | Mellomlag |
| Base layer | Base |
| Accessory | Tilbehør |
| Compatibility | Kompatibilitet |
| Archetype | Arketype |
| Swap | Bytt |
| Key garment | Nøkkelplagg |
| Combinations | Kombinasjoner |
| Gap detected | Gap oppdaget |
| Network analysis | Nettverksanalyse |
| Build and analyze | Bygg og analyser |
| Suggested swap | Foreslått bytte |
| New combination | Ny Kombinasjon |
| View wardrobe map | Se garderobekart |
| Pants | Bukser |
| Structured | Strukturert |
| Neutral | Nøytral |
| Warm | Varm |
| Cool | Kjølig |

---

## 4. Design Rules

1. **Card material**: Always use `rgba(35,28,24,0.85)` + `backdrop-filter: blur(20px)` + `border: 1px solid var(--border)`
2. **Shadows**: L1 for small elements, L2 for standard cards, L3 for hero sections only
3. **Gold accent**: Use sparingly — borders at `rgba(201,169,110,0.10)`, text-shadow for glow
4. **Hover**: Always `transform: translateY(-3px) scale(1.01)` with `cubic-bezier(.16,1,.3,1)`
5. **Press**: Always `transform: scale(.98)`
6. **Typography**: Instrument Serif for titles, scores, names. DM Sans for everything else.
7. **Section labels**: 9px, 3px letter-spacing, uppercase, gold gradient line after text
8. **Garment visuals**: Always use dark gradient backgrounds matching garment color — NOT flat colors
9. **SVGs float**: `filter: drop-shadow(0 4px 12px rgba(0,0,0,0.4))` + `transform: translateY(-2px)` on rest, `-5px` on hover
10. **No flat borders**: Use gradient dividers or semi-transparent borders
11. **Active tab**: `.ni.a` class, gold stroke on SVG, gold-dim label, radial glow behind icon
12. **Stagger animations**: Each child gets +0.04s–0.06s delay

---

## 5. Existing Screens Reference

| Screen | File | Active Tab |
|--------|------|------------|
| Pulse (Dashboard) | `moodboard/dashboard/coret-dashboard.html` | Pulse |
| Wardrobe | `moodboard/wardrobe/coret_wardrobe_V3.html` | Wardrobe |
| Studio | `moodboard/studio/coret-studio.html` | Studio |
| Optimize | `moodboard/optimize/coret-optimize.html` | Optimize |
| Evolution | `moodboard/evolution/coret-journey-interactive.html` | Evolution |
| Profile | `moodboard/profile/coret-profile.html` | None |
| Garment Detail | `moodboard/wardrobe/coret-garment-detail.html` | Wardrobe |

---

## 6. How to Create a New Screen

1. Copy the HTML skeleton from Section 1
2. Set the active tab: add class `a` to the correct `.ni` element
3. Set page title and subtitle in `.tab-header`
4. Build content using the components above (cards, garment grids, metrics, etc.)
5. Use section labels (`<div class="section-label"><span>TITLE</span><span></span></div>`) to divide content areas
6. Add stagger animation delays to repeated elements
7. Match the visual density of existing screens — not too sparse, not too crowded
8. All text in Norwegian

---

*This is the complete, production-ready spec. Every CSS value, HTML pattern, and SVG is taken directly from the working mockups as of March 2026.*
