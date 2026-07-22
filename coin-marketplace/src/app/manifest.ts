import type { MetadataRoute } from 'next';
import { site } from '@/lib/site';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: site.name,
    short_name: 'Christensen',
    description: site.shortDescription,
    start_url: '/',
    display: 'standalone',
    background_color: '#0a0a0b',
    theme_color: '#d4af37',
  };
}
