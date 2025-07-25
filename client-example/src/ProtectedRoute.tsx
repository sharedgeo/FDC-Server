import { useAuth } from 'react-oidc-context';
import { Navigate } from 'react-router-dom';
import React from 'react';

export const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const auth = useAuth();

  // While the authentication state is loading, show a loading message
  if (auth.isLoading) {
    return <div>Loading...</div>;
  }

  // If the user is authenticated, render the protected content
  if (auth.isAuthenticated) {
    return children;
  }

  // If the user is not authenticated, redirect them to the home page
  return <Navigate to={import.meta.env.BASE_URL} replace />;
};
