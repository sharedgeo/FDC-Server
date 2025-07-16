import { useEffect, useRef, useState } from 'react';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import OSM from 'ol/source/OSM';
import VectorSource from 'ol/source/Vector';
import { fromLonLat } from 'ol/proj';
import Draw from 'ol/interaction/Draw';
import 'ol/ol.css';
import WKT from 'ol/format/WKT';
import Feature from 'ol/Feature';
import { Geometry } from 'ol/geom';
import type { UserFeature } from '../../types';

interface MapComponentProps {
  features?: UserFeature[];
  onSaveFeatures?: (feature: { geom: string }) => void;
}

const MapComponent = ({ features, onSaveFeatures }: MapComponentProps) => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<Map | null>(null);
  
  // Source for user's saved features
  const userVectorSource = useRef(new VectorSource({ wrapX: false }));

  const drawInteraction = useRef<Draw | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const newFeature = useRef<Feature<Geometry> | null>(null);

  // Initialize map on first render
  useEffect(() => {
    if (!mapRef.current) {
      return;
    }

    // Coordinates for Minnesota
    const minnesotaCenter = fromLonLat([-94.6859, 46.7296]);

    const userVectorLayer = new VectorLayer({
      source: userVectorSource.current,
    });

    const map = new Map({
      target: mapRef.current,
      layers: [
        new TileLayer({
          source: new OSM(),
        }),
        userVectorLayer,
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

  // Effect to load existing user features
  useEffect(() => {
    if (!mapInstance.current) return;
    userVectorSource.current.clear();
    newFeature.current = null;

    if (features && features.length > 0) {
      const wktFormat = new WKT();
      const olFeatures = features.map((feature) => {
        try {
          return wktFormat.readFeature(feature.geom, {
            dataProjection: 'EPSG:4326',
            featureProjection: mapInstance.current!.getView().getProjection().getCode(),
          });
        } catch (e) {
          console.error('Error parsing WKT geometry:', e);
          return null;
        }
      }).filter(f => f !== null) as Feature<Geometry>[];

      userVectorSource.current.addFeatures(olFeatures);
    }
  }, [features]);

  // Effect to handle adding/removing draw interaction
  useEffect(() => {
    if (!mapInstance.current) return;

    if (drawInteraction.current) {
      mapInstance.current.removeInteraction(drawInteraction.current);
    }

    if (isDrawing) {
      drawInteraction.current = new Draw({
        source: userVectorSource.current,
        type: 'Polygon',
      });

      drawInteraction.current.on('drawend', (event) => {
        if (newFeature.current) {
          userVectorSource.current.removeFeature(newFeature.current);
        }
        newFeature.current = event.feature;
        setIsDrawing(false); // Stop drawing after one feature
      });

      mapInstance.current.addInteraction(drawInteraction.current);
    } else {
      drawInteraction.current = null;
    }

    return () => {
      if (mapInstance.current && drawInteraction.current) {
        mapInstance.current.removeInteraction(drawInteraction.current);
      }
    };
  }, [isDrawing]);

  const toggleDrawing = () => {
    setIsDrawing((prev) => !prev);
  };

  const clearDrawing = () => {
    if (newFeature.current) {
      if (userVectorSource.current.hasFeature(newFeature.current)) {
        userVectorSource.current.removeFeature(newFeature.current);
      }
      newFeature.current = null;
    }
  };

  const handleSave = () => {
    if (!onSaveFeatures || !newFeature.current) return;

    const wktFormat = new WKT();
    const geom = newFeature.current.getGeometry();
    if (geom && mapInstance.current) {
      const featureToSave = {
        geom: wktFormat.writeGeometry(geom, {
          dataProjection: 'EPSG:4326',
          featureProjection: mapInstance.current.getView().getProjection().getCode(),
        }),
      };
      onSaveFeatures(featureToSave);
      newFeature.current = null;
    }
  };

  const canDraw = onSaveFeatures !== undefined;

  return (
    <div>
      <div style={{ marginBottom: '1rem' }}>
        <button onClick={toggleDrawing} disabled={!canDraw || isDrawing}>
          {isDrawing ? 'Drawing...' : 'Draw Feature'}
        </button>
        <button onClick={clearDrawing} style={{ marginLeft: '1rem' }} disabled={!newFeature.current}>
          Clear Drawing
        </button>
        <button onClick={handleSave} style={{ marginLeft: '1rem' }} disabled={!newFeature.current}>
          Save Feature
        </button>
        {!canDraw && <p style={{ color: 'orange', marginTop: '0.5rem' }}>Please select a ticket to enable drawing.</p>}
      </div>
      <div ref={mapRef} style={{ width: '100%', height: '400px' }}></div>
    </div>
  );
};

export default MapComponent;
