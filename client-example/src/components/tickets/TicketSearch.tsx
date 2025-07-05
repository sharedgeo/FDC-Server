import { useState } from 'react';
import { useAuth } from 'react-oidc-context';
import TicketMap from './TicketMap';
import TicketDetails from './TicketDetails';
import { Geometry as OLGeometry } from 'ol/geom';

interface GeoJSONFeature {
  type: 'Feature';
  geometry: OLGeometry | null;
  properties: Record<string, unknown>;
}

const TicketSearch = () => {
  const auth = useAuth();
  const [ticketNo, setTicketNo] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [ticket, setTicket] = useState<GeoJSONFeature | null>(null);
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
    setTicket(null);

    try {
      const response = await fetch(`http://localhost:3000/v1/tickets/${encodeURIComponent(ticketNo)}`, {
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
      setTicket(foundTicket);
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
    setTicket(null);
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
      {ticket && (
        <div>
          <TicketMap ticket={ticket} />
          <TicketDetails properties={ticket.properties} />
        </div>
      )}
    </div>
  );
};

export default TicketSearch;
