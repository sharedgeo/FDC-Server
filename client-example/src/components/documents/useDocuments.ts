import { useState } from 'react';
import { useAuth } from 'react-oidc-context';

export function useDocuments(refetchProfile: () => void) {
  const auth = useAuth();
  const [error, setError] = useState<string | null>(null);

  const deleteDocument = async (signedId: string) => {
    if (!auth.user?.access_token) {
      setError("Not authenticated or access token not available.");
      return;
    }
    setError(null);

    try {
      const response = await fetch(`${import.meta.env.BASE_URL}v1/documents/${signedId}`, {
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
        refetchProfile(); // Refresh profile to get updated document list
      } else {
        throw new Error(result.message || "Failed to delete document.");
      }
    } catch (e) {
      if (e instanceof Error) {
        setError(e.message);
      } else {
        setError("An unknown error occurred while deleting the document.");
      }
    }
  };

  return { deleteDocument, error };
}
