import { useState } from 'react';
import { useAuth } from 'react-oidc-context';
import TicketSearch from '../components/tickets/TicketSearch';
import DocumentManager from '../components/documents/DocumentManager';
import FeaturesMap from '../components/map/FeaturesMap';
import Profile from '../components/profile/Profile';
import { useProfile } from '../components/profile/useProfile';
import { useFeatures } from '../components/map/useFeatures';
import { useDocuments } from '../components/documents/useDocuments';

export default function ProfilePage() {
  const auth = useAuth();
  const { profile, isLoading: isProfileLoading, error: profileError, refetch } = useProfile();
  const { saveFeatures, deleteFeature } = useFeatures(refetch);
  const { deleteDocument } = useDocuments(refetch);

  const [apiResponse, setApiResponse] = useState<string | null>(null);
  const [apiError, setApiError] = useState<string | null>(null);

  const callApi = async () => {
    setApiResponse(null);
    setApiError(null);
    if (auth.user?.access_token) {
      try {
        const response = await fetch('http://localhost:3000/v1/debug_jwt', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${auth.user.access_token}`,
          },
        });
        if (response.ok) {
          const data = await response.json();
          setApiResponse(JSON.stringify(data, null, 2));
        } else {
          setApiError(`API returned ${response.status}: ${response.statusText}`);
        }
      } catch (error) {
        if (error instanceof Error) {
          setApiError(error.message);
        } else {
          setApiError('An unknown error occurred.');
        }
      }
    }
  };

  return (
    <div>
      <h2>User Profile</h2>
      <p>This page is protected. You can only see it if you are logged in.</p>
      {auth.user?.profile && (
        <p>
          Hello, <strong>{auth.user.profile.preferred_username}</strong>!
        </p>
      )}
      <button onClick={() => auth.signoutRedirect()}>Log Out</button>

      <hr style={{ margin: '20px 0' }} />
      <h3>API Call</h3>
      <p>
        Once logged in, you can use your access token to call a protected API.
      </p>
      <button onClick={callApi}>Call API</button>
      {apiResponse && (
        <div>
          <h4>API Response:</h4>
          <pre
            style={{
              border: '1px solid #ccc',
              padding: '10px',
              background: '#f9f9f9',
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-all',
            }}
          >
            <code>{apiResponse}</code>
          </pre>
        </div>
      )}
      {apiError && (
        <div>
          <h4>API Error:</h4>
          <p style={{ color: 'red' }}>{apiError}</p>
        </div>
      )}

      <TicketSearch />
      <DocumentManager onUploadSuccess={refetch} />
      <hr style={{ margin: '20px 0' }} />
      <h3>My Features Map</h3>
      <FeaturesMap
        features={profile?.features}
        onSaveFeatures={saveFeatures}
      />
      <Profile
        profile={profile}
        isLoading={isProfileLoading}
        error={profileError}
        onDeleteFeature={deleteFeature}
        onDeleteDocument={deleteDocument}
      />
    </div>
  );
}
