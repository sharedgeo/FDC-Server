import { useState } from "react";
import { useAuth } from "react-oidc-context";
import { useDirectUpload, type ActiveStorageFileUpload } from "@docflow/react-activestorage-provider";

interface DocumentUploaderProps {
  onUploadSuccess: () => void;
  ticketId: number | undefined;
}

const DocumentUploader = ({ onUploadSuccess, ticketId }: DocumentUploaderProps) => {
  const auth = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const handleSuccess = async (signedIds: string[]) => {
    if (!auth.user?.access_token) {
      const errorMessage = "Authentication error: No access token found.";
      console.error(errorMessage);
      setError(errorMessage);
      return;
    }

    if (!ticketId) {
      const errorMessage = "No active ticket selected.";
      console.error(errorMessage);
      setError(errorMessage);
      return;
    }

    setError(null);
    setSuccessMessage(null);

    try {
      const response = await fetch("http://localhost:3000/v1/documents", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${auth.user.access_token}`,
        },
        body: JSON.stringify({ ticket_id: ticketId, document_signed_ids: signedIds }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || "Failed to attach documents.");
      }

      console.log("Attachment successful:", result);
      setSuccessMessage(`Successfully uploaded and attached ${signedIds.length} document(s).`);
      onUploadSuccess();
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "An unknown error occurred.";
      console.error("Error attaching documents:", errorMessage);
      setError(errorMessage);
    }
  };

  const {
    handleUpload,
    uploads,
    ready,
  } = useDirectUpload({
    directUploadsPath: "http://localhost:3000/rails/active_storage/direct_uploads",
    onSuccess: handleSuccess,
    onBeforeBlobRequest: ({ xhr }) => {
      if (auth.user?.access_token) {
        xhr.setRequestHeader("Authorization", `Bearer ${auth.user.access_token}`);
      }
    },
  });

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setError(null);
      setSuccessMessage(null);
      handleUpload(e.target.files);
    }
  }

  return (
    <div>
      <hr style={{ margin: '20px 0' }} />
      <h3>Upload Documents</h3>
      <p>
        Select one or more files to upload. They will be attached to the active ticket.
      </p>
      <input
        type="file"
        multiple
        disabled={!ready || !auth.isAuthenticated || !ticketId}
        onChange={handleFileChange}
      />
      {!ticketId && <p style={{ color: 'orange' }}>Please select a ticket to enable document uploads.</p>}

      {!ready && uploads.length > 0 && <p>Uploading...</p>}

      {uploads.map((upload: ActiveStorageFileUpload) => {
        switch (upload.state) {
          case "waiting":
            return <p key={upload.id}>Waiting to upload {upload.file.name}</p>;
          case "uploading":
            return (
              <div key={upload.id}>
                <p>Uploading {upload.file.name}: {upload.progress}%</p>
                <progress value={upload.progress} max="100" style={{ width: '100%' }} />
              </div>
            );
          case "error":
            return (
              <p key={upload.id} style={{ color: 'red' }}>
                Error uploading {upload.file.name}: {upload.error}
              </p>
            );
          case "finished":
            return (
              <p key={upload.id} style={{ color: 'green' }}>Finished uploading {upload.file.name}</p>
            );
        }
        return null;
      })}

      {error && <p style={{ color: 'red' }}>{error}</p>}
      {successMessage && <p style={{ color: 'green' }}>{successMessage}</p>}
    </div>
  );
};

export default DocumentUploader;
