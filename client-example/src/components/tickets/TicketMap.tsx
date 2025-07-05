import { useEffect, useRef } from 'react';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import OSM from 'ol/source/OSM';
import VectorSource from 'ol/source/Vector';
import { fromLonLat } from 'ol/proj';
import 'ol/ol.css';
import GeoJSON from 'ol/format/GeoJSON';
import { Style, Fill, Stroke } from 'ol/style';
import { isEmpty } from 'ol/extent';
import { Geometry as OLGeometry } from 'ol/geom';

// Define a basic GeoJSON Feature type
interface GeoJSONFeature {
  type: 'Feature';
  geometry: OLGeometry | null;
  properties: Record<string, unknown>;
}

interface TicketMapProps {
  ticket: GeoJSONFeature | null;
}

const TicketMap = ({ ticket }: TicketMapProps) => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<Map | null>(null);
  const ticketVectorSource = useRef(new VectorSource({ wrapX: false }));

  // Initialize map on first render
  useEffect(() => {
    if (!mapRef.current) {
      return;
    }

    const minnesotaCenter = fromLonLat([-94.6859, 46.7296]);

    const ticketVectorLayer = new VectorLayer({
      source: ticketVectorSource.current,
      style: new Style({
        stroke: new Stroke({
          color: 'red',
          width: 3,
        }),
        fill: new Fill({
          color: 'rgba(255, 0, 0, 0.1)',
        }),
      }),
    });

    const map = new Map({
      target: mapRef.current,
      layers: [
        new TileLayer({
          source: new OSM(),
        }),
        ticketVectorLayer,
      ],
      view: new View({
        center: minnesotaCenter,
        zoom: 6,
      }),
    });

    mapInstance.current = map;
    map.updateSize();

    return () => {
      map.setTarget(undefined);
      mapInstance.current = null;
    };
  }, []);

  // Effect to display the searched ticket
  useEffect(() => {
    if (!mapInstance.current) return;
    ticketVectorSource.current.clear();

    if (ticket && ticket.geometry) {
      try {
        const geojsonFormat = new GeoJSON();
        const olFeature = geojsonFormat.readFeature(ticket, {
          dataProjection: 'EPSG:4326',
          featureProjection: mapInstance.current.getView().getProjection().getCode(),
        });
        ticketVectorSource.current.addFeature(olFeature);

        const geometry = olFeature.getGeometry();
        if (geometry) {
          const extent = geometry.getExtent();
          if (!isEmpty(extent)) {
            mapInstance.current.getView().fit(extent, {
              padding: [50, 50, 50, 50],
              duration: 1000,
              maxZoom: 15,
            });
          }
        }
      } catch (e) {
        console.error('Error parsing GeoJSON feature:', e);
      }
    }
  }, [ticket]);

  return <div ref={mapRef} style={{ width: '100%', height: '400px', marginTop: '1rem' }}></div>;
};

export default TicketMap;
