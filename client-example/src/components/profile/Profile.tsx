export interface UserDocument {
  filename: string;
  content_type: string;
  byte_size: number;
  signed_id: string;
}

export interface UserFeature {
  id: number;
  geom: string;
}

export interface UserProfileData {
  id: number;
  email_address: string;
  documents: UserDocument[];
  features: UserFeature[];
}

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
      <h3>Documents</h3>
      {profile.documents.length > 0 ? (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
                <tr style={{ borderBottom: '1px solid #ccc' }}>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Filename</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Content Type</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Size (bytes)</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Action</th>
                </tr>
            </thead>
            <tbody>
            {profile.documents.map((doc) => (
                <tr key={doc.signed_id} style={{ borderBottom: '1px solid #eee' }}>
                    <td style={{ padding: '8px' }}>{doc.filename}</td>
                    <td style={{ padding: '8px' }}>{doc.content_type}</td>
                    <td style={{ padding: '8px' }}>{doc.byte_size}</td>
                    <td style={{ padding: '8px' }}>
                      <button onClick={() => onDeleteDocument(doc.signed_id)}>Delete</button>
                    </td>
                </tr>
            ))}
            </tbody>
        </table>
      ) : (
        <p>No documents found.</p>
      )}
      <h3>Features</h3>
      {profile.features && profile.features.length > 0 ? (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
                <tr style={{ borderBottom: '1px solid #ccc' }}>
                    <th style={{ textAlign: 'left', padding: '8px' }}>ID</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Geometry (WKT)</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Action</th>
                </tr>
            </thead>
            <tbody>
            {profile.features.map((feature) => (
                <tr key={feature.id} style={{ borderBottom: '1px solid #eee' }}>
                    <td style={{ padding: '8px' }}>{feature.id}</td>
                    <td style={{ padding: '8px', wordBreak: 'break-all' }}>{feature.geom}</td>
                    <td style={{ padding: '8px' }}>
                      <button onClick={() => onDeleteFeature(feature.id)}>Delete</button>
                    </td>
                </tr>
            ))}
            </tbody>
        </table>
      ) : (
        <p>No features found.</p>
      )}
    </div>
  );
}

export default Profile;
