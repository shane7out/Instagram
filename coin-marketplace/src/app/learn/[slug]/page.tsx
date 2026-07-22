import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { guides, getGuide } from '@/data/guides';
import { site } from '@/lib/site';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { ArticleJsonLd, FaqJsonLd } from '@/components/JsonLd';

export function generateStaticParams() {
  return guides.map((g) => ({ slug: g.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const guide = getGuide(slug);
  if (!guide) return { title: 'Guide Not Found' };
  return {
    title: guide.title,
    description: guide.description,
    alternates: { canonical: `/learn/${guide.slug}` },
    openGraph: {
      type: 'article',
      title: guide.title,
      description: guide.description,
      publishedTime: guide.updated,
    },
  };
}

const DATE_FMT = new Intl.DateTimeFormat('en-US', {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
});

export default async function GuidePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const guide = getGuide(slug);
  if (!guide) notFound();

  const others = guides.filter((g) => g.slug !== guide.slug).slice(0, 3);

  return (
    <div className="container-page py-8">
      <ArticleJsonLd
        headline={guide.title}
        description={guide.description}
        slug={guide.slug}
        datePublished={guide.updated}
      />
      <FaqJsonLd faqs={guide.faqs} />
      <Breadcrumbs
        items={[
          { name: 'Home', url: '/' },
          { name: 'Coin Guides', url: '/learn' },
          { name: guide.title, url: `/learn/${guide.slug}` },
        ]}
      />

      <article className="mx-auto mt-6 max-w-3xl">
        <span className="chip border-gold-400/30 text-gold-200">{guide.kicker}</span>
        <h1 className="mt-4 font-serif text-4xl font-bold leading-tight text-white sm:text-[2.75rem]">
          {guide.title}
        </h1>
        <p className="mt-4 text-xs text-silver-400">
          Updated {DATE_FMT.format(new Date(guide.updated))} · {guide.readingMinutes} min read · By the{' '}
          {site.name} numismatic team
        </p>

        <div className="mt-6 space-y-4 border-l-2 border-gold-400/30 pl-5 text-lg leading-relaxed text-silver-200">
          {guide.intro.map((p, i) => (
            <p key={i}>{p}</p>
          ))}
        </div>

        {guide.sections.map((section) => (
          <section key={section.heading} className="mt-10">
            <h2 className="font-serif text-2xl font-bold text-white">{section.heading}</h2>
            <div className="mt-3 space-y-3 text-[15px] leading-relaxed text-silver-300">
              {section.body.map((p, i) => (
                <p key={i}>{p}</p>
              ))}
            </div>
            {section.list && (
              <ul className="mt-4 space-y-2">
                {section.list.map((item) => (
                  <li key={item} className="flex items-start gap-2.5 text-[15px] text-silver-200">
                    <span className="mt-2 h-1.5 w-1.5 flex-shrink-0 rounded-full bg-gold-400" />
                    {item}
                  </li>
                ))}
              </ul>
            )}
          </section>
        ))}

        {/* FAQ */}
        {guide.faqs.length > 0 && (
          <section className="mt-12">
            <h2 className="font-serif text-2xl font-bold text-white">Frequently Asked Questions</h2>
            <div className="mt-4 space-y-3">
              {guide.faqs.map((f) => (
                <details key={f.q} className="card group p-5">
                  <summary className="flex cursor-pointer list-none items-center justify-between font-semibold text-silver-100">
                    {f.q}
                    <span className="text-gold-400 transition-transform group-open:rotate-45">+</span>
                  </summary>
                  <p className="mt-3 text-sm leading-relaxed text-silver-300">{f.a}</p>
                </details>
              ))}
            </div>
          </section>
        )}

        {/* Related links / internal linking */}
        <section className="mt-12 rounded-2xl border border-gold-400/20 bg-gold-400/[0.05] p-6">
          <h2 className="font-serif text-lg font-bold text-white">Keep exploring</h2>
          <div className="mt-3 flex flex-wrap gap-2">
            {guide.related.map((r) => (
              <Link key={r.href} href={r.href} className="chip hover:bg-white/5">
                {r.label} →
              </Link>
            ))}
          </div>
        </section>

        {/* CTA */}
        <div className="mt-10 flex flex-wrap gap-3">
          <Link href="/coins" className="btn-gold">
            Shop Certified Coins
          </Link>
          <Link href="/sell" className="btn-outline">
            Sell Your Coins
          </Link>
        </div>
      </article>

      {/* More guides */}
      <section className="mx-auto mt-16 max-w-5xl">
        <h2 className="font-serif text-2xl font-bold text-white">More Coin Guides</h2>
        <div className="mt-6 grid gap-5 sm:grid-cols-3">
          {others.map((g) => (
            <Link
              key={g.slug}
              href={`/learn/${g.slug}`}
              className="card group p-5 transition-all hover:border-gold-400/30"
            >
              <span className="text-xs font-semibold uppercase tracking-wider text-gold-300">
                {g.kicker}
              </span>
              <h3 className="mt-2 font-serif text-base font-semibold text-white group-hover:text-gold-100">
                {g.title}
              </h3>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}
