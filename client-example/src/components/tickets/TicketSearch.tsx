import { useState } from 'react';
import { useAuth } from 'react-oidc-context';
import TicketMap from './TicketMap';
import type { GeoJSONFeature } from '../../types';

interface TicketSearchProps {
  onTicketFound: (ticket: GeoJSONFeature | null) => void;
  activeTicket: GeoJSONFeature | null;
}

const TicketSearch = ({ onTicketFound, activeTicket }: TicketSearchProps) => {
  const auth = useAuth();
  const [ticketNo, setTicketNo] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSearch = async () => {
    if (!ticketNo.trim()) {
      setError('Please enter a ticket number.');
      return;
    }

    if (!auth.user?.access_token) {
      setError('You must be logged in to search for tickets.');
      return;
    }

    setIsLoading(true);
    setError(null);
    onTicketFound(null);

    try {
      const response = await fetch(`/v1/tickets/${encodeURIComponent(ticketNo)}`, {
        headers: {
          Authorization: `Bearer ${auth.user.access_token}`,
        },
      });

      if (response.status === 404) {
        const errorResult = await response.json();
        throw new Error(errorResult.message || 'Ticket not found.');
      }

      if (!response.ok) {
        const errorResult = await response.json();
        throw new Error(errorResult.message || `API error: ${response.statusText}`);
      }

      const foundTicket: GeoJSONFeature = await response.json();
      onTicketFound(foundTicket);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An unknown error occurred.';
      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  const handleClear = () => {
    setTicketNo('');
    setError(null);
    onTicketFound(null);
  };

  return (
    <div>
      <hr style={{ margin: '20px 0' }} />
      <h3>Search for a Ticket</h3>
      <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
        <input
          type="text"
          value={ticketNo}
          onChange={(e) => setTicketNo(e.target.value)}
          placeholder="Enter Ticket Number"
          disabled={isLoading || !auth.isAuthenticated}
          style={{ padding: '0.6em 1.2em', fontSize: '1em' }}
        />
        <button onClick={handleSearch} disabled={isLoading || !auth.isAuthenticated}>
          {isLoading ? 'Searching...' : 'Search'}
        </button>
        <button onClick={handleClear} disabled={isLoading}>
          Clear
        </button>
      </div>
      {error && <p style={{ color: 'red' }}>{error}</p>}
      {activeTicket && (
        <div>
          <TicketMap ticket={activeTicket} />
        </div>
      )}
    </div>
  );
};

export default TicketSearch;
