import type { UserProfileData } from '../../types';

interface ProfileProps {
  profile: UserProfileData | null;
  error: string | null;
  isLoading: boolean;
  onDeleteFeature: (featureId: number) => void;
  onDeleteDocument: (signedId: string) => void;
}

function Profile({ profile, error, isLoading, onDeleteFeature, onDeleteDocument }: ProfileProps) {
  if (isLoading) {
    return <div>Loading user details...</div>;
  }

  if (error) {
    return <div style={{ color: 'red', marginTop: '1rem' }}>Error loading user details: {error}</div>;
  }

  if (!profile) {
    return <div>No user details found.</div>;
  }

  return (
    <div style={{ textAlign: 'left', marginTop: '2rem', borderTop: '1px solid #ccc', paddingTop: '1rem' }}>
      <h2>User Details</h2>
      <p>
        <strong>Email:</strong> {profile.email_address}
      </p>
      <h3>My Tickets</h3>
      {profile.tickets.length > 0 ? (
        profile.tickets.map(ticket => (
          <div key={ticket.id} style={{ border: '1px solid #ddd', padding: '1rem', marginBottom: '1rem' }}>
            <h4>Ticket #{ticket.ticket_no}</h4>
            <h5>Documents</h5>
            {ticket.documents.length > 0 ? (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid #ccc' }}>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Filename</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {ticket.documents.map((doc) => (
                    <tr key={doc.signed_id} style={{ borderBottom: '1px solid #eee' }}>
                      <td style={{ padding: '8px' }}>{doc.filename}</td>
                      <td style={{ padding: '8px' }}>
                        <button onClick={() => onDeleteDocument(doc.signed_id)}>Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : <p>No documents for this ticket.</p>}

            <h5 style={{ marginTop: '1rem' }}>Features</h5>
            {ticket.features.length > 0 ? (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid #ccc' }}>
                    <th style={{ textAlign: 'left', padding: '8px' }}>ID</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {ticket.features.map((feature) => (
                    <tr key={feature.id} style={{ borderBottom: '1px solid #eee' }}>
                      <td style={{ padding: '8px' }}>{feature.id}</td>
                      <td style={{ padding: '8px' }}>
                        <button onClick={() => onDeleteFeature(feature.id)}>Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : <p>No features for this ticket.</p>}
          </div>
        ))
      ) : (
        <p>No tickets found.</p>
      )}
    </div>
  );
}

export default Profile;
