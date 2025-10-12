# frozen_string_literal: true

class WfsService
  NAMESPACE = 'http://fdc.example.com/features'
  FEATURE_TYPE_NAME = 'unknown_features'
  FEATURE_TYPE_TITLE = 'Unknown Features'
  SRS_NAME = 'urn:ogc:def:crs:EPSG::6344'
  GML_VERSION = '3.2.1'
  WFS_VERSION = '2.0.0'
  DEFAULT_COUNT = 1000

  def self.get_capabilities(base_url)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml['wfs'].WFS_Capabilities(
        'xmlns:wfs' => 'http://www.opengis.net/wfs/2.0',
        'xmlns:ows' => 'http://www.opengis.net/ows/1.1',
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:fes' => 'http://www.opengis.net/fes/2.0',
        'version' => WFS_VERSION,
        'xsi:schemaLocation' => 'http://www.opengis.net/wfs/2.0 http://schemas.opengis.net/wfs/2.0/wfs.xsd'
      ) do
        # Service Identification
        xml['ows'].ServiceIdentification do
          xml['ows'].Title 'FDC WFS Service'
          xml['ows'].Abstract 'Web Feature Service for FDC Unknown Features'
          xml['ows'].ServiceType('codeSpace' => 'OGC') { xml.text 'WFS' }
          xml['ows'].ServiceTypeVersion WFS_VERSION
        end

        # Service Provider
        xml['ows'].ServiceProvider do
          xml['ows'].ProviderName 'FDC'
        end

        # Operations Metadata
        xml['ows'].OperationsMetadata do
          # GetCapabilities operation
          xml['ows'].Operation('name' => 'GetCapabilities') do
            xml['ows'].DCP do
              xml['ows'].HTTP do
                xml['ows'].Get('xlink:href' => base_url)
                xml['ows'].Post('xlink:href' => base_url)
              end
            end
            xml['ows'].Parameter('name' => 'AcceptVersions') do
              xml['ows'].AllowedValues do
                xml['ows'].Value '2.0.0'
              end
            end
            xml['ows'].Parameter('name' => 'AcceptFormats') do
              xml['ows'].AllowedValues do
                xml['ows'].Value 'text/xml'
              end
            end
          end

          # DescribeFeatureType operation
          xml['ows'].Operation('name' => 'DescribeFeatureType') do
            xml['ows'].DCP do
              xml['ows'].HTTP do
                xml['ows'].Get('xlink:href' => base_url)
                xml['ows'].Post('xlink:href' => base_url)
              end
            end
            xml['ows'].Parameter('name' => 'outputFormat') do
              xml['ows'].AllowedValues do
                xml['ows'].Value 'application/gml+xml; version=3.2'
              end
            end
          end

          # GetFeature operation
          xml['ows'].Operation('name' => 'GetFeature') do
            xml['ows'].DCP do
              xml['ows'].HTTP do
                xml['ows'].Get('xlink:href' => base_url)
                xml['ows'].Post('xlink:href' => base_url)
              end
            end
            xml['ows'].Parameter('name' => 'resultType') do
              xml['ows'].AllowedValues do
                xml['ows'].Value 'results'
                xml['ows'].Value 'hits'
              end
            end
            xml['ows'].Parameter('name' => 'outputFormat') do
              xml['ows'].AllowedValues do
                xml['ows'].Value 'application/gml+xml; version=3.2'
              end
            end
            xml['ows'].Constraint('name' => 'CountDefault') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue DEFAULT_COUNT.to_s
            end
          end

          # Conformance constraints
          xml['ows'].Constraint('name' => 'ImplementsBasicWFS') do
            xml['ows'].NoValues
            xml['ows'].DefaultValue 'TRUE'
          end
          xml['ows'].Constraint('name' => 'ImplementsTransactionalWFS') do
            xml['ows'].NoValues
            xml['ows'].DefaultValue 'FALSE'
          end
          xml['ows'].Constraint('name' => 'ImplementsLockingWFS') do
            xml['ows'].NoValues
            xml['ows'].DefaultValue 'FALSE'
          end
          xml['ows'].Constraint('name' => 'KVPEncoding') do
            xml['ows'].NoValues
            xml['ows'].DefaultValue 'TRUE'
          end
          xml['ows'].Constraint('name' => 'XMLEncoding') do
            xml['ows'].NoValues
            xml['ows'].DefaultValue 'FALSE'
          end
        end

        # FeatureTypeList
        xml['wfs'].FeatureTypeList do
          xml['wfs'].FeatureType do
            xml['wfs'].Name FEATURE_TYPE_NAME
            xml['wfs'].Title FEATURE_TYPE_TITLE
            xml['wfs'].DefaultCRS SRS_NAME
            xml['ows'].WGS84BoundingBox do
              xml['ows'].LowerCorner '-180 -90'
              xml['ows'].UpperCorner '180 90'
            end
          end
        end

        # Filter Capabilities
        xml['fes'].Filter_Capabilities do
          # Conformance
          xml['fes'].Conformance do
            xml['fes'].Constraint('name' => 'ImplementsQuery') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'TRUE'
            end
            xml['fes'].Constraint('name' => 'ImplementsAdHocQuery') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'TRUE'
            end
            xml['fes'].Constraint('name' => 'ImplementsResourceId') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'TRUE'
            end
            xml['fes'].Constraint('name' => 'ImplementsMinStandardFilter') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'TRUE'
            end
            xml['fes'].Constraint('name' => 'ImplementsStandardFilter') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'FALSE'
            end
            xml['fes'].Constraint('name' => 'ImplementsMinSpatialFilter') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'TRUE'
            end
            xml['fes'].Constraint('name' => 'ImplementsSpatialFilter') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'TRUE'
            end
            xml['fes'].Constraint('name' => 'ImplementsMinTemporalFilter') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'FALSE'
            end
            xml['fes'].Constraint('name' => 'ImplementsTemporalFilter') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'FALSE'
            end
            xml['fes'].Constraint('name' => 'ImplementsVersionNav') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'FALSE'
            end
            xml['fes'].Constraint('name' => 'ImplementsSorting') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'FALSE'
            end
            xml['fes'].Constraint('name' => 'ImplementsExtendedOperators') do
              xml['ows'].NoValues
              xml['ows'].DefaultValue 'FALSE'
            end
          end

          # ID Capabilities
          xml['fes'].Id_Capabilities do
            xml['fes'].ResourceIdentifier('name' => 'fes:ResourceId')
          end

          # Scalar Capabilities
          xml['fes'].Scalar_Capabilities do
            xml['fes'].LogicalOperators
            xml['fes'].ComparisonOperators do
              xml['fes'].ComparisonOperator('name' => 'PropertyIsEqualTo')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsNotEqualTo')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsLessThan')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsGreaterThan')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsLessThanOrEqualTo')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsGreaterThanOrEqualTo')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsLike')
              xml['fes'].ComparisonOperator('name' => 'PropertyIsNull')
            end
          end

          # Spatial Capabilities
          xml['fes'].Spatial_Capabilities do
            xml['fes'].GeometryOperands do
              xml['fes'].GeometryOperand('name' => 'gml:Envelope')
              xml['fes'].GeometryOperand('name' => 'gml:Point')
              xml['fes'].GeometryOperand('name' => 'gml:MultiPoint')
              xml['fes'].GeometryOperand('name' => 'gml:LineString')
              xml['fes'].GeometryOperand('name' => 'gml:MultiLineString')
              xml['fes'].GeometryOperand('name' => 'gml:Polygon')
              xml['fes'].GeometryOperand('name' => 'gml:MultiPolygon')
            end
            xml['fes'].SpatialOperators do
              xml['fes'].SpatialOperator('name' => 'BBOX')
              xml['fes'].SpatialOperator('name' => 'Intersects')
              xml['fes'].SpatialOperator('name' => 'Within')
              xml['fes'].SpatialOperator('name' => 'Contains')
              xml['fes'].SpatialOperator('name' => 'Disjoint')
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def self.describe_feature_type
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml['xsd'].schema(
        'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:fdc' => NAMESPACE,
        'targetNamespace' => NAMESPACE,
        'elementFormDefault' => 'qualified',
        'version' => '1.0'
      ) do
        xml['xsd'].import('namespace' => 'http://www.opengis.net/gml/3.2',
                          'schemaLocation' => 'http://schemas.opengis.net/gml/3.2.1/gml.xsd')

        # Define the feature type
        xml['xsd'].element('name' => FEATURE_TYPE_NAME, 'type' => "fdc:#{FEATURE_TYPE_NAME}Type",
                           'substitutionGroup' => 'gml:AbstractFeature')

        xml['xsd'].complexType('name' => "#{FEATURE_TYPE_NAME}Type") do
          xml['xsd'].complexContent do
            xml['xsd'].extension('base' => 'gml:AbstractFeatureType') do
              xml['xsd'].sequence do
                xml['xsd'].element('name' => 'id', 'type' => 'xsd:integer', 'minOccurs' => '1')
                xml['xsd'].element('name' => 'label', 'type' => 'xsd:string', 'minOccurs' => '0')
                xml['xsd'].element('name' => 'notes', 'type' => 'xsd:string', 'minOccurs' => '0')
                xml['xsd'].element('name' => 'feature_class_id', 'type' => 'xsd:string', 'minOccurs' => '1')
                xml['xsd'].element('name' => 'created_at', 'type' => 'xsd:dateTime', 'minOccurs' => '1')
                xml['xsd'].element('name' => 'updated_at', 'type' => 'xsd:dateTime', 'minOccurs' => '1')
                xml['xsd'].element('name' => 'geom', 'type' => 'gml:MultiSurfacePropertyType', 'minOccurs' => '1')
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def self.get_feature(bbox: nil, count: nil, result_type: nil, type_names: nil, base_url: nil)
    features = Feature.where(unknown: false)

    # Apply bounding box filter if provided
    if bbox.present?
      coords = bbox.split(',').map(&:to_f)
      if coords.length == 4
        minx, miny, maxx, maxy = coords
        bbox_wkt = "POLYGON((#{minx} #{miny}, #{maxx} #{miny}, #{maxx} #{maxy}, #{minx} #{maxy}, #{minx} #{miny}))"
        features = features.where('ST_Intersects(geom, ST_GeomFromText(?, ?))', bbox_wkt, 6344)
      end
    end

    # Get total count
    number_matched = features.count

    # Apply count limit if provided
    count_limit = count.present? ? count.to_i : DEFAULT_COUNT
    features = features.limit(count_limit)

    # Handle result type
    result_type = result_type&.downcase || 'results'

    # If hits, return just the count
    if result_type == 'hits'
      return build_hits_response(number_matched)
    end

    # Build schema location with dynamic base URL
    schema_location = if base_url.present?
                        "#{NAMESPACE} #{base_url}?service=WFS&version=2.0.0&request=DescribeFeatureType&typeName=#{FEATURE_TYPE_NAME}"
                      else
                        "#{NAMESPACE} #{NAMESPACE}/schema"
                      end

    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml['wfs'].FeatureCollection(
        'xmlns:wfs' => 'http://www.opengis.net/wfs/2.0',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:fdc' => NAMESPACE,
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => "#{schema_location} http://www.opengis.net/wfs/2.0 http://schemas.opengis.net/wfs/2.0/wfs.xsd http://www.opengis.net/gml/3.2 http://schemas.opengis.net/gml/3.2.1/gml.xsd",
        'timeStamp' => Time.now.utc.iso8601,
        'numberMatched' => number_matched.to_s,
        'numberReturned' => features.count.to_s
      ) do
        features.find_each do |feature|
          xml['wfs'].member do
            xml['fdc'].send(FEATURE_TYPE_NAME, 'gml:id' => "feature.#{feature.id}") do
              xml['fdc'].id feature.id
              xml['fdc'].label feature.label if feature.label.present?
              xml['fdc'].notes feature.notes if feature.notes.present?
              xml['fdc'].feature_class_id feature.feature_class_id
              xml['fdc'].created_at feature.created_at.utc.iso8601
              xml['fdc'].updated_at feature.updated_at.utc.iso8601
              xml['fdc'].geom do
                build_gml_geometry(xml, feature.geom)
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def self.build_hits_response(number_matched)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml['wfs'].FeatureCollection(
        'xmlns:wfs' => 'http://www.opengis.net/wfs/2.0',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.opengis.net/wfs/2.0 http://schemas.opengis.net/wfs/2.0/wfs.xsd',
        'timeStamp' => Time.now.utc.iso8601,
        'numberMatched' => number_matched.to_s,
        'numberReturned' => '0'
      )
    end
    builder.to_xml
  end

  def self.build_gml_geometry(xml, geom)
    return unless geom

    geometry_type = geom.geometry_type.to_s

    case geometry_type
    when 'MultiPolygon'
      build_gml_multipolygon(xml, geom)
    when 'Polygon'
      build_gml_polygon(xml, geom)
    when 'Point', 'MultiPoint'
      build_gml_point(xml, geom)
    when 'LineString', 'MultiLineString'
      build_gml_linestring(xml, geom)
    else
      # Fallback for unknown geometry types - render as empty placeholder
      Rails.logger.warn("Unknown geometry type for WFS: #{geometry_type}")
      xml['gml'].comment "Unsupported geometry type: #{geometry_type}"
    end
  end

  def self.build_gml_multipolygon(xml, geom)
    xml['gml'].MultiSurface('srsName' => SRS_NAME) do
      geom.each do |polygon|
        xml['gml'].surfaceMember do
          build_gml_polygon_interior(xml, polygon)
        end
      end
    end
  end

  def self.build_gml_polygon(xml, geom)
    xml['gml'].Surface('srsName' => SRS_NAME) do
      xml['gml'].patches do
        xml['gml'].PolygonPatch do
          build_gml_polygon_rings(xml, geom)
        end
      end
    end
  end

  def self.build_gml_polygon_interior(xml, polygon)
    xml['gml'].Polygon do
      build_gml_polygon_rings(xml, polygon)
    end
  end

  def self.build_gml_polygon_rings(xml, polygon)
    # Exterior ring
    exterior_ring = polygon.exterior_ring
    if exterior_ring
      xml['gml'].exterior do
        xml['gml'].LinearRing do
          coords = exterior_ring.points.map { |pt| "#{pt.x} #{pt.y}" }.join(' ')
          xml['gml'].posList coords
        end
      end
    end

    # Interior rings (holes)
    polygon.interior_rings.each do |interior_ring|
      xml['gml'].interior do
        xml['gml'].LinearRing do
          coords = interior_ring.points.map { |pt| "#{pt.x} #{pt.y}" }.join(' ')
          xml['gml'].posList coords
        end
      end
    end
  end

  def self.build_gml_point(xml, geom)
    if geom.geometry_type.to_s == 'MultiPoint'
      xml['gml'].MultiPoint('srsName' => SRS_NAME) do
        geom.each do |point|
          xml['gml'].pointMember do
            xml['gml'].Point do
              xml['gml'].pos "#{point.x} #{point.y}"
            end
          end
        end
      end
    else
      xml['gml'].Point('srsName' => SRS_NAME) do
        xml['gml'].pos "#{geom.x} #{geom.y}"
      end
    end
  end

  def self.build_gml_linestring(xml, geom)
    if geom.geometry_type.to_s == 'MultiLineString'
      xml['gml'].MultiCurve('srsName' => SRS_NAME) do
        geom.each do |line|
          xml['gml'].curveMember do
            xml['gml'].LineString do
              coords = line.points.map { |pt| "#{pt.x} #{pt.y}" }.join(' ')
              xml['gml'].posList coords
            end
          end
        end
      end
    else
      xml['gml'].Curve('srsName' => SRS_NAME) do
        xml['gml'].segments do
          xml['gml'].LineStringSegment do
            coords = geom.points.map { |pt| "#{pt.x} #{pt.y}" }.join(' ')
            xml['gml'].posList coords
          end
        end
      end
    end
  end
end
