import './globals.css';
import { Providers } from './providers';
import Footer from './components/Footer';

export const metadata = {
  title: 'EmpowerTours Galactic',
  description: 'Intergalactic Web3 Pixel Game on Monad',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-black text-white min-h-screen flex flex-col">
        <Providers>
          <main className="flex-1">{children}</main>
          <Footer />
        </Providers>
      </body>
    </html>
  );
}
