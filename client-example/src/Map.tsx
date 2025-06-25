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

interface UserFeature {
  id: number;
  geom: string;
}

interface MapComponentProps {
  features?: UserFeature[];
  onSaveFeatures?: (features: { geom: string }[]) => void;
}

const MapComponent = ({ features, onSaveFeatures }: MapComponentProps) => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<Map | null>(null);
  const vectorSource = useRef(new VectorSource({ wrapX: false }));
  const drawInteraction = useRef<Draw | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const newFeatures = useRef<Feature<Geometry>[]>([]);

  // Initialize map on first render
  useEffect(() => {
    if (!mapRef.current) {
      return;
    }

    // Coordinates for Minnesota
    const minnesotaCenter = fromLonLat([-94.6859, 46.7296]);

    const vectorLayer = new VectorLayer({
      source: vectorSource.current,
    });

    const map = new Map({
      target: mapRef.current,
      layers: [
        new TileLayer({
          source: new OSM(),
        }),
        vectorLayer,
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

  // Effect to load existing features
  useEffect(() => {
    if (!mapInstance.current) return;
    vectorSource.current.clear();
    newFeatures.current = [];

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

      vectorSource.current.addFeatures(olFeatures);
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
        source: vectorSource.current,
        type: 'Polygon',
      });

      drawInteraction.current.on('drawend', (event) => {
        newFeatures.current.push(event.feature);
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
    newFeatures.current.forEach((feature) => {
      if (vectorSource.current.hasFeature(feature)) {
        vectorSource.current.removeFeature(feature);
      }
    });
    newFeatures.current = [];
  };

  const handleSave = () => {
    if (!onSaveFeatures || newFeatures.current.length === 0) return;

    const wktFormat = new WKT();
    const featuresToSave = newFeatures.current.map((f) => {
      const geom = f.getGeometry();
      if (geom && mapInstance.current) {
        return {
          geom: wktFormat.writeGeometry(geom, {
            dataProjection: 'EPSG:4326',
            featureProjection: mapInstance.current.getView().getProjection().getCode(),
          }),
        };
      }
      return null;
    }).filter((f) => f !== null) as { geom: string }[];

    if (featuresToSave.length > 0) {
      onSaveFeatures(featuresToSave);
      newFeatures.current = [];
    }
  };

  return (
    <div>
      <div style={{ marginBottom: '1rem' }}>
        <button onClick={toggleDrawing}>
          {isDrawing ? 'Stop Drawing' : 'Start Drawing'}
        </button>
        <button onClick={clearDrawing} style={{ marginLeft: '1rem' }}>
          Clear Drawings
        </button>
        {onSaveFeatures && (
          <button onClick={handleSave} style={{ marginLeft: '1rem' }}>
            Save Features
          </button>
        )}
      </div>
      <div ref={mapRef} style={{ width: '100%', height: '400px' }}></div>
    </div>
  );
};

export default MapComponent;
