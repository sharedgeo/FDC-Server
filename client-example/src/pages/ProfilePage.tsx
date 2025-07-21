import { useState, useEffect, useCallback } from 'react';
import { useAuth } from 'react-oidc-context';
import TicketSearch from '../components/tickets/TicketSearch';
import DocumentManager from '../components/documents/DocumentManager';
import FeaturesMap from '../components/map/FeaturesMap';
import Profile from '../components/profile/Profile';
import { useProfile } from '../components/profile/useProfile';
import { useFeatures } from '../components/map/useFeatures';
import { useDocuments } from '../components/documents/useDocuments';
import TicketDetails from '../components/tickets/TicketDetails';
import type { GeoJSONFeature } from '../types';

export default function ProfilePage() {
  const auth = useAuth();
  const [activeTicket, setActiveTicket] = useState<GeoJSONFeature | null>(null);
  const { profile, isLoading: isProfileLoading, error: profileError, refetch } = useProfile();
  const { saveFeatures, deleteFeature } = useFeatures(refetch);
  const { deleteDocument } = useDocuments(refetch);

  const fetchTicketById = useCallback(async (ticketId: string) => {
    if (!auth.user?.access_token) return;

    try {
      const response = await fetch(`/v1/tickets/${ticketId}`, {
        headers: {
          Authorization: `Bearer ${auth.user.access_token}`,
        },
      });
      if (!response.ok) {
        throw new Error('Failed to fetch ticket');
      }
      const ticketData: GeoJSONFeature = await response.json();
      setActiveTicket(ticketData);
    } catch (error) {
      console.error("Error fetching ticket by ID:", error);
      sessionStorage.removeItem('activeTicketId');
    }
  }, [auth.user?.access_token]);

  useEffect(() => {
    const activeTicketId = sessionStorage.getItem('activeTicketId');
    if (activeTicketId && !activeTicket) {
      fetchTicketById(activeTicketId);
    }
  }, [auth.isAuthenticated, fetchTicketById, activeTicket]);

  const handleSaveFeatures = (feature: { geom: object }) => {
    if (!activeTicket || !activeTicket.properties?.id) {
      alert('Please select a ticket before saving features.');
      return;
    }
    saveFeatures(feature, activeTicket.properties.id as number);
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

      <Profile
        profile={profile}
        isLoading={isProfileLoading}
        error={profileError}
        onDeleteFeature={deleteFeature}
        onDeleteDocument={deleteDocument}
      />

      <TicketSearch onTicketFound={setActiveTicket} activeTicket={activeTicket} />

      {activeTicket ? (
        <div style={{ border: '1px solid #ccc', padding: '1rem', marginTop: '1rem' }}>
          <h3>Active Ticket: {activeTicket.properties?.ticket_no as string}</h3>
          <TicketDetails properties={activeTicket.properties} />
          <DocumentManager onUploadSuccess={refetch} ticketId={activeTicket.properties?.id as number} />
          <hr style={{ margin: '20px 0' }} />
          <h3>Features for Active Ticket</h3>
          <FeaturesMap
            features={profile?.tickets.find(t => t.id === activeTicket?.properties?.id)?.features}
            onSaveFeatures={handleSaveFeatures as (feature: { geom: object }) => void}
          />
        </div>
      ) : (
        <div style={{ border: '1px solid #ccc', padding: '1rem', marginTop: '1rem', backgroundColor: '#f5f5f5' }}>
          <p>Please search for and select a ticket to manage its documents and features.</p>
        </div>
      )}
    </div>
  );
}
