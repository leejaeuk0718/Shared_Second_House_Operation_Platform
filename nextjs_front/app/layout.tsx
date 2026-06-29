import type { Metadata } from 'next';
import './globals.css';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import FloatingChatbot from './components/FloatingChatbot';

export const metadata: Metadata = {
  title: '세컨하우스',
  description: '나만의 두 번째 집',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body>
        <Navbar />
        <main>{children}</main>
        <Footer />
        <FloatingChatbot />
      </body>
    </html>
  );
}
