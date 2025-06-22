export interface UserDocument {
  filename: string;
  content_type: string;
  byte_size: number;
}

export interface UserProfileData {
  id: number;
  email_address: string;
  documents: UserDocument[];
}

interface ProfileProps {
  profile: UserProfileData | null;
  error: string | null;
  isLoading: boolean;
}

function Profile({ profile, error, isLoading }: ProfileProps) {
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
                </tr>
            </thead>
            <tbody>
            {profile.documents.map((doc, index) => (
                <tr key={index} style={{ borderBottom: '1px solid #eee' }}>
                    <td style={{ padding: '8px' }}>{doc.filename}</td>
                    <td style={{ padding: '8px' }}>{doc.content_type}</td>
                    <td style={{ padding: '8px' }}>{doc.byte_size}</td>
                </tr>
            ))}
            </tbody>
        </table>
      ) : (
        <p>No documents found.</p>
      )}
    </div>
  );
}

export default Profile;
