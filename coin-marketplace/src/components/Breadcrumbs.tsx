import Link from 'next/link';
import { BreadcrumbJsonLd } from '@/components/JsonLd';

export interface Crumb {
  name: string;
  url: string;
}

/** Visible breadcrumb trail + matching BreadcrumbList structured data. */
export function Breadcrumbs({ items }: { items: Crumb[] }) {
  return (
    <>
      <BreadcrumbJsonLd items={items} />
      <nav aria-label="Breadcrumb" className="text-xs text-silver-400">
        <ol className="flex flex-wrap items-center gap-1.5">
          {items.map((item, i) => {
            const last = i === items.length - 1;
            return (
              <li key={item.url} className="flex items-center gap-1.5">
                {last ? (
                  <span className="text-silver-200" aria-current="page">
                    {item.name}
                  </span>
                ) : (
                  <>
                    <Link href={item.url} className="hover:text-gold-200">
                      {item.name}
                    </Link>
                    <span aria-hidden className="text-silver-500">
                      /
                    </span>
                  </>
                )}
              </li>
            );
          })}
        </ol>
      </nav>
    </>
  );
}
