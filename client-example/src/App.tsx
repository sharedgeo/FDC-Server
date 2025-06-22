import { useState, useEffect, useRef } from 'react';
import { Routes, Route, Link, useNavigate } from 'react-router-dom';
import { useAuth } from 'react-oidc-context';
import { ProtectedRoute } from './ProtectedRoute';
import DocumentUploader from './DocumentUploader';
import Profile, { type UserProfileData } from './Profile';

// A component for the public home page
function Home() {
  const auth = useAuth();
  return (
    <>
      <h1>OIDC Login Demo</h1>
      <p>This is the public home page. Anyone can see this.</p>
      {/* Show login button if not authenticated */}
      {!auth.isAuthenticated && (
        <button onClick={() => auth.signinRedirect()}>Log In</button>
      )}
    </>
  );
}

interface ApiResponse {
    status: 'success' | 'error';
    data?: UserProfileData;
    message?: string;
}

// A component for the protected profile page
function UserProfile() {
  const auth = useAuth();
  const [apiResponse, setApiResponse] = useState<string | null>(null);
  const [apiError, setApiError] = useState<string | null>(null);

  const [profile, setProfile] = useState<UserProfileData | null>(null);
  const [profileError, setProfileError] = useState<string | null>(null);
  const [isProfileLoading, setIsProfileLoading] = useState<boolean>(true);

  const fetchProfile = async () => {
    if (!auth.user?.access_token) {
      setIsProfileLoading(false);
      setProfileError("Not authenticated or access token not available.");
      return;
    }

    setIsProfileLoading(true);
    setProfileError(null);

    try {
      const response = await fetch("http://localhost:3000/user/me", {
        headers: {
          Authorization: `Bearer ${auth.user.access_token}`,
        },
      });

      const result: ApiResponse = await response.json();

      if (!response.ok) {
          throw new Error(result.message || `HTTP error! status: ${response.status}`);
      }

      if (result.status === 'success' && result.data) {
          setProfile(result.data);
      } else {
          throw new Error(result.message || "Failed to fetch profile data.");
      }
    } catch (e) {
      if (e instanceof Error) {
          setProfileError(e.message);
      } else {
          setProfileError("An unknown error occurred.");
      }
    } finally {
      setIsProfileLoading(false);
    }
  };

  useEffect(() => {
    if (auth.isAuthenticated) {
        fetchProfile();
    }
  }, [auth.isAuthenticated, auth.user?.access_token]);

  const callApi = async () => {
    setApiResponse(null);
    setApiError(null);
    if (auth.user?.access_token) {
      try {
        const response = await fetch('http://localhost:3000/debug_jwt', {
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

  const handleUploadSuccess = () => {
    fetchProfile();
  };

  return (
    <>
      <h2>User Profile</h2>
      <p>This page is protected. You can only see it if you are logged in.</p>
      {/* Display user's preferred username if available */}
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
      <DocumentUploader onUploadSuccess={handleUploadSuccess} />

      <Profile
        profile={profile}
        isLoading={isProfileLoading}
        error={profileError}
      />
    </>
  );
}

// Helper hook to get the previous value of a prop or state.
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => {
    ref.current = value;
  });
  return ref.current;
}

// Main App component with routing and navigation
function App() {
  const auth = useAuth();
  const navigate = useNavigate();
  const wasAuthenticated = usePrevious(auth.isAuthenticated);

  useEffect(() => {
    // This function is called when a silent renew error occurs.
    const onSilentRenewError = (error: Error) => {
      console.error('Silent renew failed:', error);
      // Invalidate the session and redirect to home page on silent renew error.
      auth.removeUser();
      navigate('/');
    };

    auth.events.addSilentRenewError(onSilentRenewError);

    // Cleanup the event listener on component unmount.
    return () => {
      auth.events.removeSilentRenewError(onSilentRenewError);
    };
  }, [auth.events, auth.removeUser, navigate]);

  // This effect handles redirection after a successful login by detecting
  // a change in the authentication state from false to true.
  useEffect(() => {
    if (!wasAuthenticated && auth.isAuthenticated) {
      navigate('/profile');
    }
  }, [wasAuthenticated, auth.isAuthenticated, navigate]);

  return (
    <div>
      <nav style={{ borderBottom: '1px solid #ccc', paddingBottom: '10px', marginBottom: '10px' }}>
        <Link to="/">Home</Link> | <Link to="/profile">Profile</Link>
      </nav>

      <Routes>
        <Route path="/" element={<Home />} />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <UserProfile />
            </ProtectedRoute>
          }
        />
      </Routes>
    </div>
  );
}

export default App;
