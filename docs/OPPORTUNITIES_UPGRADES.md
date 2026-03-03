# CORET — Opportunities & Upgrades

Strukturert oversikt over alt som kan gjøre CORET bedre eller større.
To kategorier: **Produkt** (direkte verdi i appen) og **Business** (markedsposisjon, inntekt, konkurransefortrinn).

---

## Del 1 — Produkt: Direkte verdi i appen

Forbedringer som gjør appen mer nyttig, mer levende, og mer sticky for eksisterende brukere.

---

### 1.1 Onboarding-friksjon

**Problemet:** Manuell input på 40 plagg tar 60–90 minutter. Appen er minst nyttig akkurat
når brukeren er mest motivert. Cold-start-problemet er den høyeste enkelt-barrieren for konvertering.

#### A — Progressiv onboarding
Start med 5 kjerneplagg. Gap-analysen er faktisk mer motiverende med lite data —
anbefalingene er umiddelbare og konkrete. Brukeren ser verdien før de har lagt inn alt.

| | |
|--|--|
| **Verdi** | Dramatisk lavere drop-off ved install |
| **Teknisk** | Bare UX — ingen ny engine-logikk |
| **Kompleksitet** | Lav |
| **Når** | V1 — høyeste prioritet |

#### B — Kamera + on-device AI-klassifikasjon
Hold plagget foran kamera 2–3 sekunder. iOS Vision + Core ML foreslår `category`,
`colorTemperature`, `dominantColor`, `baseGroup`, `silhouette`. Bruker bekrefter eller
justerer ett felt. 40 plagg på 8–12 min istedenfor 90.

Teknisk flyt:
- `VNGenerateForegroundInstanceMaskRequest` isolerer plagg fra bakgrunn
- K-means clustering på maskerte piksler → `dominantColor`
- Luminans-filtrering ekskluderer spekulære høylys (blanke materialer)
- Confidence-score per felt — under 65% vises som "trykk for å bekrefte", ikke auto-fylt
- Bounding box-sjekk: < 35% av rammen → "kom nærmere"

Dårlige forhold og fallbacks:
- Dårlig lys → Core Image white balance-korreksjon + advarsel "hold nær vindu"
- Stripete plagg → K-means, ikke median (største kluster vinner)
- Mørk bakgrunn = mørk farge → foreground mask løser dette
- Sort vs navy → feil hex, men `colorTemperature` (cool) er riktig — det er det enginen bruker

`image`-feltet og `source: .camera` er allerede i `Garment`-modellen.

| | |
|--|--|
| **Verdi** | Eliminerer mesteparten av manuell input-friksjon |
| **Teknisk** | Core ML + Vision framework, on-device |
| **Kompleksitet** | Middels — 2 uker |
| **Når** | V1.5 |

#### C — E-post kvitteringsparser
Lesetilgang til Gmail/Outlook. Parser Zalando, H&M, ASOS, Arket-kvitteringer fra
siste 12–24 måneder. Utleder kategori, farge og baseGroup fra produktnavn (~80–90%
treffsikkerhet). Bruker godkjenner batch — én gjennomgang, ikke 40 enkelt-inputs.

`.zalando` og `.hm` er allerede i `ImportSource`-enumen.

| | |
|--|--|
| **Verdi** | Høyest friksjon-reduksjon av alle tilnærminger |
| **Teknisk** | Mail-integrasjon + regex/parsing + batch-UI |
| **Kompleksitet** | Middels — 3 uker |
| **Når** | V2 |

#### D — Legg til ved bruk
Start med tom garderobe. App spør morgen/kveld: "Hva har du på deg?" Tre felt,
20 sekunder. Garderobe bygges organisk over 2–3 uker. `usageCount` er korrekt
fra dag én — data gjenspeiler faktisk bruk, ikke hva som henger bakerst.

| | |
|--|--|
| **Verdi** | Lavest terskel av alle tracks — null krav ved install |
| **Teknisk** | Enkel logging + lokal notifikasjon |
| **Kompleksitet** | Lav — 1 uke |
| **Når** | V1.5 (alternativ onboarding-track) |

---

### 1.2 ML Lag 1 — Appen lærer av deg (V1.5)

Ny engine-fil: `core-v2/Engines/BehaviouralEngine.swift`
Ny SwiftData-entitet: `WearLogEntity` (dato + garmentID per bruk)

#### Arketype-drift deteksjon
Brukeren sier `tailored`, men `usageCount`-data viser at de konsekvent tar street-plagg.
CORET oppdager divergensen og foreslår stille: "Din faktiske bruksatferd ligner mer street.
Vil du recalibrere?" Appen vet hvem du faktisk er, ikke bare hvem du tror du er.

```swift
BehaviouralEngine.behaviouralArchetype(items:recentWear:) -> Archetype
BehaviouralEngine.detectDrift(profile:items:wearLog:) -> Double  // 0–1
```

| | |
|--|--|
| **Verdi** | Holder profilen og scoren i sync med virkeligheten |
| **Endringer** | BehaviouralEngine.swift, WearLogEntity.swift, ProfileViewModel |
| **Kompleksitet** | Lav — 1 uke |

#### Rotasjons-prediksjon
Exponential smoothing på wear-historikk per plagg →
"Du rekker sannsynligvis for denne jakka 3 ganger neste uke."
`unusedRisk`-score identifiserer plagg som er i ferd med å bli glemt.

```swift
BehaviouralEngine.predictNextWear(garment:wearLog:) -> Date?
BehaviouralEngine.unusedRisk(garment:wearLog:) -> Double
```

| | |
|--|--|
| **Verdi** | Gjør rotasjonsinnsikt proaktiv og konkret |
| **Endringer** | Bygger på WearLogEntity — ingen nye filer |
| **Kompleksitet** | Lav — 3 dager |

#### Personlig sesong-modell
Aggreger `ClaritySnapshotEntity` per måned over tid. Finn brukerens historiske
sesongmønstre — juster SeasonalEngineV2-vekter deretter. Geografisk sesong er
generisk; personlig sesong er din.

| | |
|--|--|
| **Verdi** | Sesongkalibrering som faktisk passer deg |
| **Endringer** | BehaviouralEngine + EngineCoordinator |
| **Kompleksitet** | Lav teknisk — cold start, først nyttig etter 12 mnd |

---

### 1.3 ML Lag 2 — Visuell intelligens (V1.5–V2)

Ny engine-fil: `core-v2/Engines/SimilarityEngine.swift`
Ny felt på `GarmentEntity`: `imageEmbedding: Data?`

Bruker **MobileCLIP** (Apple, on-device Core ML). Konverterer garment-bilde
til 512-float embedding-vektor. Lagres én gang per bilde, ~2KB.

#### Duplikat-deteksjon
Cosinus-similaritet mellom embeddings → duplikat-kandidater over ~0.92 terskel.

> "Du har 3 plagg som fyller samme strukturelle rolle. To er redundante."

```swift
SimilarityEngine.duplicates(among:embeddings:) -> [[Garment]]
SimilarityEngine.cosineSimilarity(_:_:) -> Float
```

| | |
|--|--|
| **Verdi** | Avdekker ubevisst redundans — direkte relevant for OptimizeEngine |
| **Endringer** | SimilarityEngine.swift, GarmentEntity (ny felt), WardrobeViewModel |
| **Kompleksitet** | Middels — 2 uker |

#### Wear-logging fra kamera
Gjenbruk embedding-infrastrukturen. Ta bilde om morgenen → generer embedding →
match mot eksisterende garderobe → logg bruk automatisk. `usageCount` oppdateres
uten at brukeren tenker på det.

| | |
|--|--|
| **Verdi** | Rotasjonsdata uten manuell input — gjør RotationScore levende |
| **Endringer** | EngineCoordinator (én ny funksjon), kamera-sheet i UI |
| **Kompleksitet** | Lav gitt duplikat-infrastruktur — 1 uke på toppen |

---

### 1.4 ML Lag 3 — Naturlig språk-grensesnitt (V2)

Nye filer: `ios_app/Networking/COREAssistant.swift`, `ios_app/ViewModels/AssistantViewModel.swift`

Engine-output er allerede strukturert og rik. COREAssistant pakker det som kontekst
til en LLM og svarer på naturlige spørsmål:

> "Hva bør jeg ha på meg til et klientmøte fredag?"
> "Jeg reiser til London i november, hva mangler jeg?"
> "Hvorfor er Density-scoren min lav?"

```swift
struct WardrobeContext {
    let clarity: ClaritySnapshot      // scores + band
    let identity: WardrobeIdentity    // label, tags, prose
    let gaps: GapResult               // strukturelle hull
    let journey: JourneySnapshot      // fase + narrativ
    let profile: UserProfile
}

COREAssistant.ask(_ question: String, context: WardrobeContext) async -> String
```

**Nøkkelinnsikt:** CORET's deterministiske engine er det perfekte grunnlaget for en LLM
fordi den gir faktisk, pålitelig strukturdata. LLMen gjetter ikke — den har ekte tall.
Det løser hallusinasjons-problemet som gjør AI-assistenter upålitelige i andre apper.

**API:** Claude Haiku for raske spørsmål (~$0.001/query), Sonnet for komplekse (~$0.01).
20 spørsmål per bruker per måned = $0.02–0.20. Triviell kostnad.

**Personvern:** Ingen bilder sendes. Kun strukturell data — scores, kategorier, labels.

| | |
|--|--|
| **Verdi** | Transformerer appen fra dashboard til personlig rådgiver |
| **Endringer** | 2 nye filer, `EngineCoordinator.buildContext()` |
| **Kompleksitet** | Middels — 2 uker (API-integrasjon + prompt-engineering) |
| **Når** | V2 |

---

### 1.5 Virtual Try-On (V1.5 Pro)

**Fashn.ai API** — $0.075 per generering, høyvolum-rabatt ned mot $0.04.
Ingen Doppl API (Google Labs, consumer-only, ingen developer-tilgang).

Flyt:
1. Bruker laster opp ett referansebilde av seg selv (én gang, i profil-onboarding)
2. Velger outfit-kombinasjon i appen
3. Trykker "Preview on me"
4. App sender: referansebilde + garment-bilder → Fashn.ai
5. Returnerer generert bilde på 2–5 sekunder

**CORET-posisjonering:** Ikke "se kul ut" — men "se om kombinasjonen fungerer strukturelt."
Brukes som bevis på struktur, ikke moteinspirasjon. Avhengig av god garment-bildekvalitet
(kamera-onboarding er en forutsetning).

**Kostnad ved skala:**

| Brukere | Try-ons/mnd | Kostnad/mnd |
|---------|-------------|-------------|
| 1 000 | 5 000 | ~$375 |
| 5 000 | 25 000 | ~$1 875 |
| 10 000 | 50 000 | ~$3 750 |

Ved 10 000 brukere med 30% Pro ($10/mnd) → $30 000 inntekt mot $1 125 kostnad.

| | |
|--|--|
| **Verdi** | Sterk Pro-hook, gjør structural proof visuell og konkret |
| **Endringer** | Networking-lag, referansebilde-onboarding, preview-sheet |
| **Kompleksitet** | Middels — 2 uker |
| **Når** | V1.5 Pro |

---

## Del 2 — Business: Markedsposisjon og inntekt

Muligheter som gjør CORET sterkere som selskap, ikke bare som produkt.

---

### 2.1 B2B — Personlig stylist-verktøy

**Muligheten:** Freelance wardrobe consultants gjør alt manuelt i dag. CORET gir dem
et profesjonelt måleverktøy som differensierer dem fra "en venn med god smak."

**Hva stylisten får:**
- Strukturell rapport per klient — ikke meninger, men et system med tall
- Before/after dokumentasjon — `ClaritySnapshot` + `JourneySnapshot` er allerede klar
- Tidsbesparelse — automatisk gap-analyse erstatter manuell telling
- Oversikt over alle klienter — hvem trenger oppfølging, hvem er i hvilken fase

**Hva som må bygges:**

| Feature | Engine-arbeid | UI-arbeid | Kompleksitet |
|---------|--------------|-----------|-------------|
| Multi-klient (flere profiler + garderober) | Lite — V2+ i spec | Middels | Middels |
| Stylist-dashboard | Ingen | Nytt skjerm | Middels |
| PDF/rapport-eksport | Ingen — data er klar | Presentasjonslag | Lav |
| Delt klient-visning (read-only) | Ingen | Krever backend | Høy |

**Forretningsmodell:**

| Modell | Beskrivelse | Estimert ARR (500 stylister) |
|--------|-------------|------------------------------|
| Stylist Pro-tier | $60–80/mnd, multi-klient + rapport | $360–480k |
| Per-klient-sete | $8–12 per aktiv klient/mnd | Variabelt, høyere tak |
| Marketplace | CORET kobler kunder + stylister, 10–15% cut | Høyest — men krever backend |

**Distribusjonseffekten:** Overbevis 200 stylister → de selger inn til 30 kunder hver
= 6 000 brukere med høy tillit og lav churn. Lavere CAC, høyere LTV enn konsument-SaaS.
Stylisten blir markedsføringskanal — kunder spør "hva er dette?" og laster ned selv.

| | |
|--|--|
| **Inntektspotensial** | $360–480k ARR fra 500 stylister |
| **Strategisk verdi** | Distribusjon + troverdighet + høy LTV |
| **Når** | V1.5 (multi-profil + rapport). Marketplace V2+. |

---

### 2.2 White-label engine / API-lisensiering

COREEngine er et standalone Swift package uten UI-avhengigheter — plattformagnostisk
og klar til lisensiering.

**Potensielle kjøpere:**
- Sustainable fashion-brands (Cos, Arket, Asket) — gi kunder strukturell innsikt ved kjøp
- Fashion tech-startups — kjøper engine istedenfor å bygge selv
- Retailere — "structural fit score" for produktanbefalinger mot eksisterende garderobe

**Modeller:**
- Kvartalsvis lisensavgift (B2B-kontrakt)
- API-kall-basert ($0.005–0.01 per analyse)
- Swift Package Index-publisering (åpen kilde med kommersiell lisens)

**Hva som trengs:** Dokumentasjon, REST API-wrapper, én referansekunde.
Ingen engine-arbeid — enginen er ferdig.

| | |
|--|--|
| **Inntektspotensial** | Enkeltkontrakter $20–100k/år |
| **Strategisk verdi** | Validerer engine som industri-standard |
| **Når** | V2+ — gjør konsumentproduktet bra først |

---

### 2.3 Bærekraft som distribusjonskanal

CORET måler struktur, ikke forbruk — men bieffekten er at brukeren kjøper færre,
bedre plagg. Det er en bærekraft-story uten at appen trenger å moralisere.

**Distribusjon:** Communities og creators i slow fashion, capsule wardrobe og
"buy less, buy better"-bevegelsen søker aktivt etter verktøy. CORET er svaret —
uten å være pekefinger-aktig.

10 YouTube-videoer fra riktige creators i denne nisjen kan drive 10 000 downloads
uten et eneste reklamekrone. Dette er ikke et teknisk problem.

**Partnerskap:** Sustainable brands som Asket eller Arket har samme kundeprofil
som CORET og ingen konkurrerende produkt. Co-marketing er naturlig.

| | |
|--|--|
| **Verdi** | Gratis distribusjon til høy-konverterende målgruppe |
| **Krever** | Innholdsstrategi + creator-relasjoner, ikke kode |
| **Når** | Parallelt med V1-launch |

---

### 2.4 ML Lag 4–5 — Prediktiv og kollektiv intelligens (V3)

#### Anonymisert aggregering
Ingen deler sin garderobe. Men strukturelle mønstre aggregeres anonymt:

> "Brukere med din profil (tailored, fokusert-band, 35 plagg) har typisk
> 1.8 mid-layers per base-layer. Du er under medianen."

Ikke rangering mot andre — statistisk referansepunkt. Som blodprøve mot normalverdier.

#### Kontekstuell bevissthet
- Kalender-integrasjon: "Du har tre formelle møter neste uke og smartCasual-dekning er lav."
- Vær-API: "4 grader og regn torsdag. Layer 1 cool/neutral er sterk. Her er tre outfits."
- Kjøps-intelligens: Ta bilde i butikk → CORET sier "dette fyller mid-layer gap, Density +11."

#### Strukturell forfall-varsling
Score har sunket 8 poeng over 3 måneder uten at brukeren fjernet noe. Årsak:
4 nye plagg som ikke er koherente. Varsler *før* brukeren er bevisst på problemet.

| | |
|--|--|
| **Strategisk verdi** | Gjør CORET uerstattelig — appen vet mer om deg enn du husker |
| **Kompleksitet** | Høy — backend, aggregering, personvern-arkitektur |
| **Når** | V3 |

---

## Prioritert gjennomføringsrekkefølge

### Nå (V1 — ingen Mac nødvendig)
- [ ] Progressiv onboarding-spec og UX-flow
- [ ] Bærekraft/creator distribusjonstrategi

### V1.5 (første Mac-sesjon)
- [ ] Progressiv onboarding implementert
- [ ] Legg-til-ved-bruk track
- [ ] Kamera + fargedeteksjon
- [ ] BehaviouralEngine (drift + rotasjonsprediksjon + WearLogEntity)
- [ ] Virtual try-on via Fashn.ai (Pro)
- [ ] SimilarityEngine + wear-logging fra kamera

### V2
- [ ] E-post kvitteringsparser
- [ ] LLM-grensesnitt (COREAssistant)
- [ ] Multi-profil / stylist-modus
- [ ] PDF rapport-eksport

### V2+ / V3
- [ ] Stylist marketplace
- [ ] White-label API
- [ ] Anonymisert aggregering
- [ ] Kontekstuell bevissthet (kalender, vær, kjøp)

---

*Sist oppdatert: 2026-03-03*
