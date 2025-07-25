import { useEffect, useRef } from 'react';
import { Routes, Route, Link, useNavigate } from 'react-router-dom';
import { useAuth } from 'react-oidc-context';
import { ProtectedRoute } from './ProtectedRoute';
import ProfilePage from './pages/ProfilePage';

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

// Helper hook to get the previous value of a prop or state.
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T | undefined>(undefined);
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
      navigate(import.meta.env.BASE_URL);
    };

    auth.events.addSilentRenewError(onSilentRenewError);

    // Cleanup the event listener on component unmount.
    return () => {
      auth.events.removeSilentRenewError(onSilentRenewError);
    };
  }, [auth, navigate]);

  // This effect handles redirection after a successful login by detecting
  // a change in the authentication state from false to true.
  useEffect(() => {
    if (!wasAuthenticated && auth.isAuthenticated) {
      navigate(`${import.meta.env.BASE_URL}profile`);
    }
  }, [wasAuthenticated, auth.isAuthenticated, navigate, auth]);

  return (
    <div>
      <nav style={{ borderBottom: '1px solid #ccc', paddingBottom: '10px', marginBottom: '10px' }}>
        <Link to={import.meta.env.BASE_URL}>Home</Link> | <Link to={`${import.meta.env.BASE_URL}profile`}>Profile</Link>
      </nav>

      <Routes>
        <Route path={import.meta.env.BASE_URL} element={<Home />} />
        <Route
          path={`${import.meta.env.BASE_URL}profile`}
          element={
            <ProtectedRoute>
              <ProfilePage />
            </ProtectedRoute>
          }
        />
      </Routes>
    </div>
  );
}

export default App;
