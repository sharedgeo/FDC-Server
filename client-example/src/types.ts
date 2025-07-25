import { Geometry as OLGeometry } from 'ol/geom';
import type { FeatureCollection } from 'geojson';

export interface UserDocument {
  filename: string;
  content_type: string;
  byte_size: number;
  signed_id: string;
}

export interface Ticket {
  id: number;
  ticket_no: string;
  features: FeatureCollection;
  documents: UserDocument[];
}

export interface UserProfileData {
  id: number;
  email_address: string;
  tickets: Ticket[];
}

export interface GeoJSONFeature<P = Record<string, unknown>> {
  type: 'Feature';
  geometry: OLGeometry | null;
  properties: P;
}

export interface TicketProperties {
  id: number;
  ticket_no: string;
  [key: string]: unknown;
}
