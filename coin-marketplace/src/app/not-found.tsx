import Link from 'next/link';
import { Logo } from '@/components/Logo';

export default function NotFound() {
  return (
    <div className="container-page flex min-h-[60vh] flex-col items-center justify-center py-20 text-center">
      <Logo className="h-16 w-16" />
      <h1 className="mt-6 font-serif text-4xl font-bold text-white">Page Not Found</h1>
      <p className="mt-3 max-w-md text-silver-300">
        This coin may have already found a new home. Let’s get you back to the collection.
      </p>
      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <Link href="/" className="btn-gold">
          Back to Home
        </Link>
        <Link href="/coins" className="btn-outline">
          Browse All Coins
        </Link>
      </div>
    </div>
  );
}
