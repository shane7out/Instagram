/** Brand mark: a stylized gold coin with an "R" monogram. */
export function Logo({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 48 48" className={className} role="img" aria-label="RareCoinsForSale logo">
      <defs>
        <radialGradient id="logo-face" cx="38%" cy="32%" r="75%">
          <stop offset="0%" stopColor="#f7e9b0" />
          <stop offset="55%" stopColor="#d4af37" />
          <stop offset="100%" stopColor="#8a6a1c" />
        </radialGradient>
      </defs>
      <circle cx="24" cy="24" r="23" fill="url(#logo-face)" stroke="#b8912b" strokeWidth="1.5" />
      <circle cx="24" cy="24" r="19" fill="none" stroke="#5c4711" strokeOpacity="0.35" strokeWidth="1" />
      <text
        x="24"
        y="32"
        textAnchor="middle"
        fontSize="24"
        fontWeight="800"
        fill="#5c4711"
        style={{ fontFamily: 'Georgia, serif' }}
      >
        R
      </text>
    </svg>
  );
}
