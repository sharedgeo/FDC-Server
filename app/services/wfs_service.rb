# frozen_string_literal: true

class WfsService
  NAMESPACE = 'http://fdc.example.com/features'
  SRS_NAME = SridConstants::SRS_NAME_6344
  GML_VERSION = '3.2.1'
  WFS_VERSION = '2.0.0'
  DEFAULT_COUNT = 1000
  MAX_COUNT = 1000

  # Feature type definitions
  FEATURE_TYPES = {
    'unknown_multipoint' => {
      name: 'unknown_multipoint',
      title: 'Unknown MultiPoint Features',
      geometry_types: %w[POINT MULTIPOINT],
      gml_type: 'gml:MultiPointPropertyType'
    },
    'unknown_multiline' => {
      name: 'unknown_multiline',
      title: 'Unknown MultiLineString Features',
      geometry_types: %w[LINESTRING MULTILINESTRING],
      gml_type: 'gml:MultiCurvePropertyType'
    },
    'unknown_multipolygon' => {
      name: 'unknown_multipolygon',
      title: 'Unknown MultiPolygon Features',
      geometry_types: %w[POLYGON MULTIPOLYGON],
      gml_type: 'gml:MultiSurfacePropertyType'
    }
  }.freeze

  def self.feature_type_names
    FEATURE_TYPES.keys
  end

  def self.feature_type_config(type_name)
    FEATURE_TYPES[type_name]
  end

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
          FEATURE_TYPES.each do |type_name, config|
            xml['wfs'].FeatureType do
              xml['wfs'].Name config[:name]
              xml['wfs'].Title config[:title]
              xml['wfs'].DefaultCRS SRS_NAME

              # Calculate actual extent for this geometry type
              extent = self.calculate_layer_extent(config[:geometry_types])

              xml['ows'].WGS84BoundingBox do
                xml['ows'].LowerCorner "#{extent[:min_lon]} #{extent[:min_lat]}"
                xml['ows'].UpperCorner "#{extent[:max_lon]} #{extent[:max_lat]}"
              end
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

  def self.describe_feature_type(type_names: nil)
    # Parse type_names parameter - can be comma-separated
    requested_types = if type_names.present?
                        # Limit string length to prevent DoS via large inputs
                        if type_names.length > 1000
                          Rails.logger.warn("typeNames parameter exceeds maximum length")
                          []
                        else
                          # Limit number of splits to prevent DoS
                          type_names.split(',', 10).map(&:strip).select { |t| FEATURE_TYPES.key?(t) }
                        end
                      else
                        feature_type_names
                      end

    # If no valid types requested, default to all types
    requested_types = feature_type_names if requested_types.empty?

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

        # Generate schema for each requested feature type
        requested_types.each do |type_name|
          config = FEATURE_TYPES[type_name]

          # Define the feature type element
          xml['xsd'].element('name' => config[:name], 'type' => "fdc:#{config[:name]}Type",
                             'substitutionGroup' => 'gml:AbstractFeature')

          # Define the feature type complexType
          xml['xsd'].complexType('name' => "#{config[:name]}Type") do
            xml['xsd'].complexContent do
              xml['xsd'].extension('base' => 'gml:AbstractFeatureType') do
                xml['xsd'].sequence do
                  xml['xsd'].element('name' => 'id', 'type' => 'xsd:integer', 'minOccurs' => '1')
                  xml['xsd'].element('name' => 'label', 'type' => 'xsd:string', 'minOccurs' => '0')
                  xml['xsd'].element('name' => 'notes', 'type' => 'xsd:string', 'minOccurs' => '0')
                  xml['xsd'].element('name' => 'feature_class_id', 'type' => 'xsd:string', 'minOccurs' => '1')
                  xml['xsd'].element('name' => 'created_at', 'type' => 'xsd:dateTime', 'minOccurs' => '1')
                  xml['xsd'].element('name' => 'updated_at', 'type' => 'xsd:dateTime', 'minOccurs' => '1')
                  xml['xsd'].element('name' => 'geom', 'type' => config[:gml_type], 'minOccurs' => '1')
                end
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def self.get_feature(bbox: nil, count: nil, result_type: nil, type_names: nil, base_url: nil)
    # Parse type_names parameter - can be comma-separated
    requested_types = if type_names.present?
                        # Limit string length to prevent DoS via large inputs
                        if type_names.length > 1000
                          Rails.logger.warn("typeNames parameter exceeds maximum length")
                          []
                        else
                          # Limit number of splits to prevent DoS
                          type_names.split(',', 10).map(&:strip).select { |t| FEATURE_TYPES.key?(t) }
                        end
                      else
                        feature_type_names
                      end

    # If no valid types requested, default to all types
    requested_types = feature_type_names if requested_types.empty?

    # Start with unknown features
    features = Feature.where(unknown: true)

    # Build geometry type filter for requested types
    all_geometry_types = requested_types.flat_map { |type| FEATURE_TYPES[type][:geometry_types] }
    features = features.where('GeometryType(geom) IN (?)', all_geometry_types)

    # Apply bounding box filter if provided
    if bbox.present?
      # Limit bbox string length to prevent DoS
      if bbox.length > 200
        Rails.logger.warn("BBOX parameter exceeds maximum length")
      else
        coords = bbox.split(',').map(&:to_f)
        # Validate coordinates: must have exactly 4 values and all must be finite numbers
        if coords.length == 4 && coords.all?(&:finite?)
          minx, miny, maxx, maxy = coords
          # Use ST_MakeEnvelope with parameterized query to prevent SQL injection
          features = features.where(
            'ST_Intersects(geom, ST_MakeEnvelope(?, ?, ?, ?, ?))',
            minx, miny, maxx, maxy, SridConstants::SRID_6344
          )
        else
          Rails.logger.warn("Invalid BBOX parameter format or non-finite coordinates")
        end
      end
    end

    # Get total count before applying limit
    number_matched = features.count

    # Apply count limit if provided, enforcing maximum
    if count.present?
      requested_count = count.to_i
      # Enforce maximum count limit to prevent DoS
      if requested_count > MAX_COUNT
        Rails.logger.warn("COUNT parameter #{requested_count} exceeds maximum #{MAX_COUNT}, using maximum")
        count_limit = MAX_COUNT
      elsif requested_count > 0
        count_limit = requested_count
      else
        # Invalid count, use default
        Rails.logger.warn("Invalid COUNT parameter: must be positive, using default")
        count_limit = DEFAULT_COUNT
      end
    else
      count_limit = DEFAULT_COUNT
    end

    features = features.limit(count_limit)

    # Handle result type
    result_type = result_type&.downcase || 'results'

    # If hits, return just the count
    if result_type == 'hits'
      return build_hits_response(number_matched)
    end

    # Use ST_Multi to cast geometries and load features with casted geometry
    features_with_multi_geom = features.select(
      'features.id',
      'features.label',
      'features.notes',
      'features.feature_class_id',
      'features.created_at',
      'features.updated_at',
      'ST_Multi(geom) as geom',
      'GeometryType(geom) as original_geom_type'
    ).to_a

    # Build schema location with all requested types
    schema_location_parts = requested_types.map do |type|
      if base_url.present?
        "#{NAMESPACE} #{base_url}?service=WFS&version=2.0.0&request=DescribeFeatureType&typeName=#{type}"
      else
        "#{NAMESPACE} #{NAMESPACE}/schema"
      end
    end
    schema_location = schema_location_parts.first # Use first one for simplicity

    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml['wfs'].FeatureCollection(
        'xmlns:wfs' => 'http://www.opengis.net/wfs/2.0',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:fdc' => NAMESPACE,
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => "#{schema_location} http://www.opengis.net/wfs/2.0 http://schemas.opengis.net/wfs/2.0/wfs.xsd http://www.opengis.net/gml/3.2 http://schemas.opengis.net/gml/3.2.1/gml.xsd",
        'timeStamp' => Time.now.utc.iso8601,
        'numberMatched' => number_matched.to_s,
        'numberReturned' => features_with_multi_geom.length.to_s
      ) do
        features_with_multi_geom.each do |feature|
          # Determine which feature type this belongs to based on original geometry type
          original_type = feature.original_geom_type
          feature_type_name = requested_types.find do |type|
            FEATURE_TYPES[type][:geometry_types].include?(original_type)
          end

          # Skip if we couldn't determine the type (shouldn't happen with our query)
          next unless feature_type_name

          xml['wfs'].member do
            xml['fdc'].send(feature_type_name, 'gml:id' => "feature.#{feature.id}") do
              xml['fdc'].id feature.id
              xml['fdc'].label feature.label if feature.label.present?
              xml['fdc'].notes feature.notes if feature.notes.present?
              xml['fdc'].feature_class_id feature.feature_class_id
              xml['fdc'].created_at feature.created_at.utc.iso8601
              xml['fdc'].updated_at feature.updated_at.utc.iso8601
              xml['fdc'].geom do
                # feature.geom is already ST_Multi() casted
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

  def self.build_empty_response
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml['wfs'].FeatureCollection(
        'xmlns:wfs' => 'http://www.opengis.net/wfs/2.0',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.opengis.net/wfs/2.0 http://schemas.opengis.net/wfs/2.0/wfs.xsd http://www.opengis.net/gml/3.2 http://schemas.opengis.net/gml/3.2.1/gml.xsd',
        'timeStamp' => Time.now.utc.iso8601,
        'numberMatched' => '0',
        'numberReturned' => '0'
      )
    end
    builder.to_xml
  end

  def self.calculate_layer_extent(geometry_types)
    # Build SQL query to calculate extent for this geometry type
    # ST_Extent is an aggregate function, so we need to use a subquery
    # ST_Extent returns a box with SRID 0, so we need to set it to SRID_6344 before transforming
    sql = <<-SQL
      SELECT
        ST_XMin(ST_Transform(ST_SetSRID(extent_geom, #{SridConstants::SRID_6344}), 4326)) as min_lon,
        ST_YMin(ST_Transform(ST_SetSRID(extent_geom, #{SridConstants::SRID_6344}), 4326)) as min_lat,
        ST_XMax(ST_Transform(ST_SetSRID(extent_geom, #{SridConstants::SRID_6344}), 4326)) as max_lon,
        ST_YMax(ST_Transform(ST_SetSRID(extent_geom, #{SridConstants::SRID_6344}), 4326)) as max_lat
      FROM (
        SELECT ST_Extent(geom)::geometry as extent_geom
        FROM features
        WHERE unknown = true
          AND GeometryType(geom) IN (?)
      ) AS extent_query
    SQL

    # Execute the query
    result = ActiveRecord::Base.connection.select_one(
      ActiveRecord::Base.sanitize_sql_array([sql, geometry_types])
    )

    # If no features exist or extent calculation fails, return world bounds
    if result && result['min_lon'] && result['min_lat'] && result['max_lon'] && result['max_lat']
      # Add a small buffer (0.0001 degrees ~11 meters) to ensure all features fall within
      # the advertised extent after rounding and coordinate transformation
      buffer = 0.0001

      {
        min_lon: (result['min_lon'].to_f - buffer).round(6),
        min_lat: (result['min_lat'].to_f - buffer).round(6),
        max_lon: (result['max_lon'].to_f + buffer).round(6),
        max_lat: (result['max_lat'].to_f + buffer).round(6)
      }
    else
      # Default to world bounds if no features
      {
        min_lon: -180,
        min_lat: -90,
        max_lon: 180,
        max_lat: 90
      }
    end
  rescue StandardError => e
    # Log error and return world bounds as fallback
    Rails.logger.error("Failed to calculate layer extent: #{e.message}")
    {
      min_lon: -180,
      min_lat: -90,
      max_lon: 180,
      max_lat: 90
    }
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
