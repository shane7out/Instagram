import type { Coin } from '@/lib/types';

/**
 * A self-contained SVG "coin" rendered from a coin's own attributes (metal,
 * series, year, denomination). Used as the listing image for sample inventory
 * and as a graceful fallback whenever a real sourced photo is missing — so the
 * site always looks finished with zero external image dependencies.
 */

const METAL_GRADIENTS: Record<string, { a: string; b: string; c: string; ring: string; ink: string }> = {
  Gold: { a: '#f7e9b0', b: '#d4af37', c: '#8a6a1c', ring: '#b8912b', ink: '#5c4711' },
  Silver: { a: '#f4f5f7', b: '#c7cbd2', c: '#8a9099', ring: '#aeb4bd', ink: '#3c4149' },
  Platinum: { a: '#eef1f4', b: '#cfd6dc', c: '#9aa3ab', ring: '#bcc4cc', ink: '#414952' },
  Copper: { a: '#f0c9a0', b: '#c07d43', c: '#7a4a22', ring: '#a86a37', ink: '#4d2f16' },
  Nickel: { a: '#eef0f2', b: '#c3c7cc', c: '#8f949b', ring: '#adb2b9', ink: '#3f444b' },
  Bronze: { a: '#e6c98f', b: '#a97f3f', c: '#6d4f22', ring: '#8f6a34', ink: '#463218' },
  Bimetallic: { a: '#f4e6b0', b: '#c7cbd2', c: '#8a6a1c', ring: '#b8912b', ink: '#4a4a52' },
};

function initials(series: string): string {
  const words = series.replace(/[^A-Za-z\s]/g, '').split(/\s+/).filter(Boolean);
  if (words.length === 0) return 'RC';
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

export function CoinMedallion({ coin, className }: { coin: Coin; className?: string }) {
  const g = METAL_GRADIENTS[coin.metal] ?? METAL_GRADIENTS.Silver;
  const id = coin.slug.replace(/[^a-z0-9]/g, '').slice(0, 24);
  const label = coin.series || coin.denomination || 'Rare Coin';
  const yearText = coin.year ? String(coin.year) : 'ANCIENT';
  const monogram = initials(label);
  // Decorative dentils around the rim
  const dentils = Array.from({ length: 60 }, (_, i) => {
    const angle = (i / 60) * Math.PI * 2;
    const r1 = 88;
    const r2 = 94;
    const x1 = 100 + Math.cos(angle) * r1;
    const y1 = 100 + Math.sin(angle) * r1;
    const x2 = 100 + Math.cos(angle) * r2;
    const y2 = 100 + Math.sin(angle) * r2;
    return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke={g.ring} strokeWidth={1.4} opacity={0.6} />;
  });

  return (
    <svg
      viewBox="0 0 200 200"
      className={className}
      role="img"
      aria-label={`${coin.title} — illustrative ${coin.metal.toLowerCase()} coin`}
    >
      <defs>
        <radialGradient id={`face-${id}`} cx="38%" cy="32%" r="75%">
          <stop offset="0%" stopColor={g.a} />
          <stop offset="55%" stopColor={g.b} />
          <stop offset="100%" stopColor={g.c} />
        </radialGradient>
        <linearGradient id={`rim-${id}`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={g.a} />
          <stop offset="50%" stopColor={g.c} />
          <stop offset="100%" stopColor={g.b} />
        </linearGradient>
        <path id={`top-${id}`} d="M100,100 m-70,0 a70,70 0 0,1 140,0" fill="none" />
        <path id={`bot-${id}`} d="M100,100 m-66,0 a66,66 0 0,0 132,0" fill="none" />
      </defs>

      {/* Outer rim */}
      <circle cx="100" cy="100" r="97" fill={`url(#rim-${id})`} />
      <circle cx="100" cy="100" r="90" fill={`url(#face-${id})`} stroke={g.ring} strokeWidth="1.5" />
      {dentils}
      {/* Inner beaded ring */}
      <circle cx="100" cy="100" r="78" fill="none" stroke={g.ink} strokeWidth="1" opacity="0.35" />

      {/* Series name arc (top) and year arc (bottom) */}
      <text fill={g.ink} fontSize="11" fontWeight="700" letterSpacing="2" opacity="0.85">
        <textPath href={`#top-${id}`} startOffset="50%" textAnchor="middle">
          {label.toUpperCase().slice(0, 22)}
        </textPath>
      </text>
      <text fill={g.ink} fontSize="11" fontWeight="700" letterSpacing="3" opacity="0.85">
        <textPath href={`#bot-${id}`} startOffset="50%" textAnchor="middle">
          {`★ ${coin.country.toUpperCase().slice(0, 16)} ★`}
        </textPath>
      </text>

      {/* Central monogram */}
      <circle cx="100" cy="96" r="34" fill="none" stroke={g.ink} strokeWidth="1.2" opacity="0.4" />
      <text
        x="100"
        y="104"
        textAnchor="middle"
        fontSize="34"
        fontWeight="800"
        fill={g.ink}
        opacity="0.9"
        style={{ fontFamily: 'Georgia, serif' }}
      >
        {monogram}
      </text>
      <text x="100" y="150" textAnchor="middle" fontSize="15" fontWeight="800" letterSpacing="2" fill={g.ink} opacity="0.85">
        {yearText}
      </text>
    </svg>
  );
}
