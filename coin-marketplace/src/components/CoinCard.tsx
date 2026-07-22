import Link from 'next/link';
import type { Coin } from '@/lib/types';
import { CoinMedallion } from '@/components/CoinMedallion';
import { formatUsd } from '@/lib/pricing';

export function CoinCard({ coin }: { coin: Coin }) {
  const discount =
    coin.compareAtPrice && coin.compareAtPrice > coin.price
      ? Math.round((1 - coin.price / coin.compareAtPrice) * 100)
      : 0;

  return (
    <Link
      href={`/coins/${coin.slug}`}
      className="card group relative flex flex-col overflow-hidden transition-all duration-300 hover:-translate-y-1 hover:border-gold-400/30 hover:shadow-gold-glow"
    >
      {/* Badges */}
      <div className="absolute left-3 top-3 z-10 flex flex-col gap-1.5">
        {coin.isNew && (
          <span className="rounded-full bg-gold-sheen px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-ink-950">
            New
          </span>
        )}
        {coin.featured && !coin.isNew && (
          <span className="rounded-full border border-gold-400/40 bg-ink-950/70 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-gold-200">
            Featured
          </span>
        )}
      </div>
      {discount > 0 && (
        <span className="absolute right-3 top-3 z-10 rounded-full bg-emerald-500/90 px-2.5 py-1 text-[10px] font-bold text-white">
          Save {discount}%
        </span>
      )}

      {/* Medallion */}
      <div className="coin-shine relative flex aspect-square items-center justify-center overflow-hidden bg-gradient-to-b from-ink-800 to-ink-900 p-8">
        {coin.images.length > 0 ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={coin.images[0].url}
            alt={coin.images[0].alt}
            className="h-full w-full object-contain transition-transform duration-500 group-hover:scale-105"
          />
        ) : (
          <CoinMedallion
            coin={coin}
            className="h-full w-full drop-shadow-2xl transition-transform duration-500 group-hover:scale-105 group-hover:rotate-[4deg]"
          />
        )}
      </div>

      {/* Body */}
      <div className="flex flex-1 flex-col p-4">
        <div className="mb-2 flex flex-wrap items-center gap-1.5">
          <span className="chip !py-0.5 text-[10px]">{coin.gradingService}</span>
          <span className="chip !py-0.5 text-[10px]">{coin.grade}</span>
        </div>
        <h3 className="font-serif text-[15px] font-semibold leading-snug text-silver-100 transition-colors group-hover:text-white">
          {coin.title}
        </h3>
        <p className="mt-1 text-xs text-silver-400">
          {coin.series}
          {coin.mint ? ` · ${coin.mint} Mint` : ''}
        </p>

        <div className="mt-auto flex items-end justify-between pt-4">
          <div>
            <div className="text-lg font-bold text-gold-200">{formatUsd(coin.price)}</div>
            {coin.compareAtPrice && coin.compareAtPrice > coin.price && (
              <div className="text-xs text-silver-400 line-through">
                {formatUsd(coin.compareAtPrice)}
              </div>
            )}
          </div>
          <span className="text-xs font-semibold text-gold-300 opacity-0 transition-opacity group-hover:opacity-100">
            View →
          </span>
        </div>
      </div>
    </Link>
  );
}

export function CoinGrid({ coins }: { coins: Coin[] }) {
  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
      {coins.map((coin) => (
        <CoinCard key={coin.id} coin={coin} />
      ))}
    </div>
  );
}
