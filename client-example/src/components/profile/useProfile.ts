import { useState, useEffect, useCallback } from 'react';
import { useAuth } from 'react-oidc-context';
import { type UserProfileData } from './Profile';

interface ApiResponse {
  status: 'success' | 'error';
  data?: UserProfileData;
  message?: string;
}

export function useProfile() {
  const auth = useAuth();
  const [profile, setProfile] = useState<UserProfileData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const fetchProfile = useCallback(async () => {
    if (!auth.user?.access_token) {
      setIsLoading(false);
      setError("Not authenticated or access token not available.");
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch("http://localhost:3000/v1/profile", {
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
        setError(e.message);
      } else {
        setError("An unknown error occurred.");
      }
    } finally {
      setIsLoading(false);
    }
  }, [auth.user?.access_token]);

  useEffect(() => {
    if (auth.isAuthenticated) {
      fetchProfile();
    }
  }, [auth.isAuthenticated, fetchProfile]);

  return { profile, error, isLoading, refetch: fetchProfile };
}
