import { Geometry as OLGeometry } from 'ol/geom';

export interface UserDocument {
  filename: string;
  content_type: string;
  byte_size: number;
  signed_id: string;
}

export interface UserFeature {
  id: number;
  geom: string;
  ticket_id: number;
}

export interface Ticket {
  id: number;
  ticket_no: string;
  features: UserFeature[];
  documents: UserDocument[];
}

export interface UserProfileData {
  id: number;
  email_address: string;
  tickets: Ticket[];
}

export interface GeoJSONFeature {
  type: 'Feature';
  geometry: OLGeometry | null;
  properties: Record<string, unknown>;
}
