import { useState } from 'react';
import { useAuth } from 'react-oidc-context';

export function useFeatures(refetchProfile: () => void) {
  const auth = useAuth();
  const [error, setError] = useState<string | null>(null);

  const saveFeatures = async (features: { geom: string }[]) => {
    if (!auth.user?.access_token) {
      setError("Not authenticated or access token not available.");
      return;
    }
    setError(null);

    try {
      const response = await fetch("http://localhost:3000/v1/features", {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${auth.user.access_token}`,
        },
        body: JSON.stringify({ features }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || `HTTP error! status: ${response.status}`);
      }

      if (result.status === 'success') {
        refetchProfile(); // Refresh profile to get new feature list
      } else {
        throw new Error(result.message || "Failed to save features.");
      }
    } catch (e) {
      if (e instanceof Error) {
        setError(e.message);
      } else {
        setError("An unknown error occurred while saving features.");
      }
    }
  };

  const deleteFeature = async (featureId: number) => {
    if (!auth.user?.access_token) {
      setError("Not authenticated or access token not available.");
      return;
    }
    setError(null);

    try {
      const response = await fetch(`http://localhost:3000/v1/features/${featureId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${auth.user.access_token}`,
        },
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || `HTTP error! status: ${response.status}`);
      }

      if (result.status === 'success') {
        refetchProfile(); // Refresh profile to get updated feature list
      } else {
        throw new Error(result.message || "Failed to delete feature.");
      }
    } catch (e) {
      if (e instanceof Error) {
        setError(e.message);
      } else {
        setError("An unknown error occurred while deleting the feature.");
      }
    }
  };

  return { saveFeatures, deleteFeature, error };
}
