'use client';
import { PrivyProvider } from '@privy-io/react-auth';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider, createConfig, http } from 'wagmi';
import { monadTestnet } from './chain';

const queryClient = new QueryClient();
const wagmiConfig = createConfig({
  chains: [monadTestnet],
  transports: { [monadTestnet.id]: http() },
});

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <PrivyProvider appId="cmaoduqox005ole0nmj1s4qck" config={{ loginMethods: ['email', 'wallet'] }}>
      <QueryClientProvider client={queryClient}>
        <WagmiProvider config={wagmiConfig}>
          {children}
        </WagmiProvider>
      </QueryClientProvider>
    </PrivyProvider>
  );
}
