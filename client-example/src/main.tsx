import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { AuthProvider } from 'react-oidc-context';
import { BrowserRouter } from 'react-router-dom';

// --- Keycloak OIDC Configuration ---
// You must have a Keycloak realm and client configured.
// See Keycloak documentation for details.
const oidcConfig = {
  authority: 'https://sso.sharedgeo.org/realms/SharedGeo', // Replace with your realm URL
  client_id: 'fdc-demo-localhost', // Replace with your client ID
  redirect_uri: window.location.origin + import.meta.env.BASE_URL,
  onSigninCallback: () => {
    // Removes the auth state from the URL after a successful login
    window.history.replaceState({}, document.title, window.location.pathname);
  },
};

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <AuthProvider {...oidcConfig}>
        <App />
      </AuthProvider>
    </BrowserRouter>
  </React.StrictMode>
);
