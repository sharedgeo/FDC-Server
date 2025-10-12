# frozen_string_literal: true

require 'test_helper'

class WfsTest < ActionDispatch::IntegrationTest
  fixtures :all

  # Helper method for Basic Auth credentials
  def wfs_auth_headers
    username = ENV['WFS_USERNAME'] || 'wfs_user'
    password = ENV['WFS_PASSWORD'] || 'wfs_password'
    {
      'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    }
  end

  # GetCapabilities Tests
  test 'GetCapabilities returns valid XML with correct structure' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    assert_match %r{application/xml}, response.content_type

    xml = Nokogiri::XML(response.body)
    assert xml.errors.empty?, "XML should be valid: #{xml.errors.inspect}"

    # Check for WFS_Capabilities root element
    capabilities = xml.at_xpath('//wfs:WFS_Capabilities',
                                'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil capabilities, 'Should have WFS_Capabilities root element'
    assert_equal '2.0.0', capabilities['version']

    # Check for Service Identification
    service_title = xml.at_xpath('//ows:ServiceIdentification/ows:Title',
                                  'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil service_title
    assert_equal 'FDC WFS Service', service_title.text

    # Check for Operations
    operations = xml.xpath('//ows:Operation/@name',
                          'ows' => 'http://www.opengis.net/ows/1.1')
    operation_names = operations.map(&:value)
    assert_includes operation_names, 'GetCapabilities'
    assert_includes operation_names, 'DescribeFeatureType'
    assert_includes operation_names, 'GetFeature'

    # Check for Feature Types - should have all three geometry-specific types
    feature_type_names = xml.xpath('//wfs:FeatureType/wfs:Name',
                                    'wfs' => 'http://www.opengis.net/wfs/2.0').map(&:text)
    assert_equal 3, feature_type_names.count, 'Should have 3 feature types'
    assert_includes feature_type_names, 'unknown_multipoint'
    assert_includes feature_type_names, 'unknown_multiline'
    assert_includes feature_type_names, 'unknown_multipolygon'

    # Check for CRS
    default_crs = xml.at_xpath('//wfs:FeatureType/wfs:DefaultCRS',
                               'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil default_crs
    assert_equal 'urn:ogc:def:crs:EPSG::6344', default_crs.text
  end

  test 'GetCapabilities works with lowercase parameters' do
    get '/wfs', params: { service: 'wfs', request: 'getcapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)
    capabilities = xml.at_xpath('//wfs:WFS_Capabilities',
                                'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil capabilities
  end

  test 'GetCapabilities works via POST' do
    post '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)
    capabilities = xml.at_xpath('//wfs:WFS_Capabilities',
                                'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil capabilities
  end

  # DescribeFeatureType Tests
  test 'DescribeFeatureType returns valid XSD schema with all three types when no typeNames specified' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'DescribeFeatureType' }, headers: wfs_auth_headers

    assert_response :success
    assert_match %r{application/gml\+xml}, response.content_type

    xml = Nokogiri::XML(response.body)
    assert xml.errors.empty?, "XML should be valid: #{xml.errors.inspect}"

    # Check for schema root element
    schema = xml.at_xpath('//schema') || xml.at_xpath('//xsd:schema',
                         'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil schema, 'Should have schema root element'

    # Check for all three feature element definitions
    multipoint_element = xml.at_xpath('//xsd:element[@name="unknown_multipoint"]',
                                      'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil multipoint_element, 'Should define unknown_multipoint element'

    multiline_element = xml.at_xpath('//xsd:element[@name="unknown_multiline"]',
                                     'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil multiline_element, 'Should define unknown_multiline element'

    multipolygon_element = xml.at_xpath('//xsd:element[@name="unknown_multipolygon"]',
                                       'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil multipolygon_element, 'Should define unknown_multipolygon element'

    # Check for required attributes in one of the schemas (they all have the same structure)
    required_fields = %w[id label notes feature_class_id created_at updated_at geom]
    required_fields.each do |field|
      element = xml.at_xpath("//xsd:element[@name='#{field}']",
                            'xsd' => 'http://www.w3.org/2001/XMLSchema')
      assert_not_nil element, "Should define #{field} element"
    end
  end

  test 'DescribeFeatureType returns single type when typeNames specified' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'DescribeFeatureType', TYPENAMES: 'unknown_multipoint' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # Should have only the requested type
    multipoint_element = xml.at_xpath('//xsd:element[@name="unknown_multipoint"]',
                                      'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil multipoint_element, 'Should define unknown_multipoint element'

    # Should not have the other types
    multiline_element = xml.at_xpath('//xsd:element[@name="unknown_multiline"]',
                                     'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_nil multiline_element, 'Should not define unknown_multiline element'
  end

  test 'DescribeFeatureType works with lowercase parameters' do
    get '/wfs', params: { service: 'wfs', request: 'describefeaturetype' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)
    # The schema element is the root, search without namespace prefix
    schema = xml.at_xpath('//schema') || xml.at_xpath('//xsd:schema',
                         'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil schema
  end

  # GetFeature Tests
  test 'GetFeature returns GML FeatureCollection with all unknown features from all layers' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature' }, headers: wfs_auth_headers

    assert_response :success
    assert_match %r{application/gml\+xml}, response.content_type

    xml = Nokogiri::XML(response.body)
    assert xml.errors.empty?, "XML should be valid: #{xml.errors.inspect}"

    # Check for FeatureCollection root element
    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil feature_collection, 'Should have FeatureCollection root element'

    # Check number of features returned - should be 7 (3 polygons, 2 points, 2 lines)
    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 7, members.count, 'Should return 7 unknown features'

    # Verify numberMatched and numberReturned attributes
    assert_equal '7', feature_collection['numberMatched']
    assert_equal '7', feature_collection['numberReturned']

    # Check that features have proper structure - should have all three types
    namespace = 'http://fdc.example.com/features'

    multipolygon_features = xml.xpath('//fdc:unknown_multipolygon', 'fdc' => namespace)
    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)
    multiline_features = xml.xpath('//fdc:unknown_multiline', 'fdc' => namespace)

    assert_equal 3, multipolygon_features.count, 'Should have 3 multipolygon features'
    assert_equal 2, multipoint_features.count, 'Should have 2 multipoint features'
    assert_equal 2, multiline_features.count, 'Should have 2 multiline features'

    # Verify first feature has all expected elements
    first_feature = members.first.at_xpath('.//*[@gml:id]', 'gml' => 'http://www.opengis.net/gml/3.2')
    assert_not_nil first_feature.at_xpath('fdc:id', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:feature_class_id', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:created_at', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:updated_at', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:geom', 'fdc' => namespace)

    # Verify geometry contains GML (check for any Multi* geometry type)
    geom_element = first_feature.at_xpath('fdc:geom', 'fdc' => namespace)
    multi_geom = geom_element.at_xpath('.//*[local-name()="MultiSurface" or local-name()="MultiPoint" or local-name()="MultiCurve"]',
                                       'gml' => 'http://www.opengis.net/gml/3.2')
    assert_not_nil multi_geom, 'Geometry should contain GML Multi* element'

    # Verify CRS
    assert_equal 'urn:ogc:def:crs:EPSG::6344', multi_geom['srsName']
  end

  test 'GetFeature does not return features with unknown=false' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # We have 7 unknown features and 3 known features in fixtures
    # Should only return the 7 unknown ones
    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 7, members.count

    # Verify none of the returned features are the "known" ones
    namespace = 'http://fdc.example.com/features'
    labels = xml.xpath('//fdc:label',
                      'fdc' => namespace).map(&:text)

    assert_not_includes labels, 'Known Survey Feature'
    assert_not_includes labels, 'Known Electric Feature'
    assert_not_includes labels, 'Known Point Feature'
  end

  test 'GetFeature with BBOX filters features spatially' do
    # BBOX that should only include the first unknown feature (100-200 range)
    bbox = '50,50,250,250'
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', BBOX: bbox }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')

    # Should return at least 1 feature (the one in the BBOX)
    assert members.count >= 1, 'Should return features within BBOX'

    # Verify the returned feature is within the BBOX
    namespace = 'http://fdc.example.com/features'
    labels = xml.xpath('//fdc:label',
                      'fdc' => namespace).map(&:text)

    # The first unknown feature should be included
    assert_includes labels, 'Unknown Survey Feature 1'
  end

  test 'GetFeature with BBOX that excludes all features returns empty collection' do
    # BBOX that doesn't intersect with any features
    bbox = '9000,9000,9100,9100'
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', BBOX: bbox }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal '0', feature_collection['numberReturned']

    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 0, members.count
  end

  test 'GetFeature works with lowercase parameters' do
    get '/wfs', params: { service: 'wfs', request: 'getfeature' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)
    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil feature_collection
  end

  # Error Handling Tests
  test 'returns error for missing SERVICE parameter' do
    get '/wfs', params: { REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
    assert_equal 'InvalidParameterValue', exception['exceptionCode']
  end

  test 'returns error for invalid SERVICE parameter' do
    get '/wfs', params: { SERVICE: 'WMS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
    assert_equal 'InvalidParameterValue', exception['exceptionCode']
  end

  test 'returns error for unsupported REQUEST operation' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'UnsupportedOperation' }, headers: wfs_auth_headers

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
    assert_equal 'OperationNotSupported', exception['exceptionCode']
  end

  test 'returns error for missing REQUEST parameter' do
    get '/wfs', params: { SERVICE: 'WFS' }, headers: wfs_auth_headers

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
  end

  # Enhanced WFS 2.0 Tests
  test 'GetCapabilities includes conformance constraints' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # Check for ImplementsBasicWFS constraint
    constraint = xml.at_xpath('//ows:Constraint[@name="ImplementsBasicWFS"]/ows:DefaultValue',
                             'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil constraint
    assert_equal 'TRUE', constraint.text

    # Check that transactional is FALSE
    constraint = xml.at_xpath('//ows:Constraint[@name="ImplementsTransactionalWFS"]/ows:DefaultValue',
                             'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil constraint
    assert_equal 'FALSE', constraint.text
  end

  test 'GetCapabilities includes operation parameters' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # Check for resultType parameter in GetFeature operation
    result_type = xml.at_xpath('//ows:Operation[@name="GetFeature"]/ows:Parameter[@name="resultType"]',
                               'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil result_type

    # Check for allowed values
    values = xml.xpath('//ows:Operation[@name="GetFeature"]/ows:Parameter[@name="resultType"]//ows:Value',
                      'ows' => 'http://www.opengis.net/ows/1.1').map(&:text)
    assert_includes values, 'results'
    assert_includes values, 'hits'
  end

  test 'GetCapabilities includes Filter Capabilities conformance' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # Check for fes:Conformance section
    conformance = xml.at_xpath('//fes:Filter_Capabilities/fes:Conformance',
                              'fes' => 'http://www.opengis.net/fes/2.0',
                              'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil conformance

    # Check for ImplementsMinSpatialFilter
    constraint = xml.at_xpath('//fes:Conformance/fes:Constraint[@name="ImplementsMinSpatialFilter"]/ows:DefaultValue',
                             'fes' => 'http://www.opengis.net/fes/2.0',
                             'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil constraint
    assert_equal 'TRUE', constraint.text
  end

  test 'GetCapabilities includes scalar capabilities' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # Check for comparison operators
    operators = xml.xpath('//fes:Scalar_Capabilities/fes:ComparisonOperators/fes:ComparisonOperator/@name',
                         'fes' => 'http://www.opengis.net/fes/2.0').map(&:value)

    assert_includes operators, 'PropertyIsEqualTo'
    assert_includes operators, 'PropertyIsLessThan'
    assert_includes operators, 'PropertyIsLike'
  end

  test 'GetCapabilities includes extended spatial operators' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # Check for spatial operators
    operators = xml.xpath('//fes:Spatial_Capabilities/fes:SpatialOperators/fes:SpatialOperator/@name',
                         'fes' => 'http://www.opengis.net/fes/2.0').map(&:value)

    assert_includes operators, 'BBOX'
    assert_includes operators, 'Intersects'
    assert_includes operators, 'Within'
    assert_includes operators, 'Contains'
  end

  test 'GetFeature with count parameter limits results' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', COUNT: 2 }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')

    # numberMatched should be total (7)
    assert_equal '7', feature_collection['numberMatched']

    # numberReturned should be limited (2)
    assert_equal '2', feature_collection['numberReturned']

    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 2, members.count
  end

  test 'GetFeature with resultType=hits returns count only' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', RESULTTYPE: 'hits' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')

    # Should have count but no features
    assert_equal '7', feature_collection['numberMatched']
    assert_equal '0', feature_collection['numberReturned']

    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 0, members.count
  end

  test 'GetFeature includes schema location pointing to DescribeFeatureType' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0',
                                     'xsi' => 'http://www.w3.org/2001/XMLSchema-instance')

    schema_location = feature_collection.attribute_with_ns('schemaLocation', 'http://www.w3.org/2001/XMLSchema-instance')
    assert_not_nil schema_location
    assert_match(/DescribeFeatureType/, schema_location.value)
  end

  # Geometry Type Filtering Tests
  test 'GetFeature with typeNames=unknown_multipoint returns only point features' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', TYPENAMES: 'unknown_multipoint' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    namespace = 'http://fdc.example.com/features'

    # Should have 2 point features
    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)
    assert_equal 2, multipoint_features.count, 'Should return 2 point features'

    # Should not have other types
    multiline_features = xml.xpath('//fdc:unknown_multiline', 'fdc' => namespace)
    multipolygon_features = xml.xpath('//fdc:unknown_multipolygon', 'fdc' => namespace)
    assert_equal 0, multiline_features.count, 'Should not return line features'
    assert_equal 0, multipolygon_features.count, 'Should not return polygon features'

    # Verify geometry is MultiPoint
    geom = multipoint_features.first.at_xpath('.//gml:MultiPoint',
                                              'gml' => 'http://www.opengis.net/gml/3.2')
    assert_not_nil geom, 'Geometry should be MultiPoint'
  end

  test 'GetFeature with typeNames=unknown_multiline returns only line features' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', TYPENAMES: 'unknown_multiline' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    namespace = 'http://fdc.example.com/features'

    # Should have 2 line features
    multiline_features = xml.xpath('//fdc:unknown_multiline', 'fdc' => namespace)
    assert_equal 2, multiline_features.count, 'Should return 2 line features'

    # Should not have other types
    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)
    multipolygon_features = xml.xpath('//fdc:unknown_multipolygon', 'fdc' => namespace)
    assert_equal 0, multipoint_features.count, 'Should not return point features'
    assert_equal 0, multipolygon_features.count, 'Should not return polygon features'

    # Verify geometry is MultiCurve (MultiLineString)
    geom = multiline_features.first.at_xpath('.//gml:MultiCurve',
                                             'gml' => 'http://www.opengis.net/gml/3.2')
    assert_not_nil geom, 'Geometry should be MultiCurve'
  end

  test 'GetFeature with typeNames=unknown_multipolygon returns only polygon features' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', TYPENAMES: 'unknown_multipolygon' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    namespace = 'http://fdc.example.com/features'

    # Should have 3 polygon features
    multipolygon_features = xml.xpath('//fdc:unknown_multipolygon', 'fdc' => namespace)
    assert_equal 3, multipolygon_features.count, 'Should return 3 polygon features'

    # Should not have other types
    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)
    multiline_features = xml.xpath('//fdc:unknown_multiline', 'fdc' => namespace)
    assert_equal 0, multipoint_features.count, 'Should not return point features'
    assert_equal 0, multiline_features.count, 'Should not return line features'

    # Verify geometry is MultiSurface (MultiPolygon)
    geom = multipolygon_features.first.at_xpath('.//gml:MultiSurface',
                                                'gml' => 'http://www.opengis.net/gml/3.2')
    assert_not_nil geom, 'Geometry should be MultiSurface'
  end

  test 'GetFeature with multiple typeNames returns features from both types' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', TYPENAMES: 'unknown_multipoint,unknown_multiline' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    namespace = 'http://fdc.example.com/features'

    # Should have 2 point + 2 line = 4 features
    members = xml.xpath('//wfs:member', 'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 4, members.count, 'Should return 4 features'

    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)
    multiline_features = xml.xpath('//fdc:unknown_multiline', 'fdc' => namespace)
    assert_equal 2, multipoint_features.count, 'Should have 2 point features'
    assert_equal 2, multiline_features.count, 'Should have 2 line features'

    # Should not have polygons
    multipolygon_features = xml.xpath('//fdc:unknown_multipolygon', 'fdc' => namespace)
    assert_equal 0, multipolygon_features.count, 'Should not return polygon features'
  end

  test 'GetFeature casts Point to MultiPoint' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', TYPENAMES: 'unknown_multipoint' }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    namespace = 'http://fdc.example.com/features'

    # All point features should be MultiPoint, even if originally Point
    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)

    multipoint_features.each do |feature|
      # Every feature should have MultiPoint geometry, not Point
      multi_geom = feature.at_xpath('.//gml:MultiPoint',
                                   'gml' => 'http://www.opengis.net/gml/3.2')
      assert_not_nil multi_geom, 'All point geometries should be cast to MultiPoint'

      # Should not find any Point geometry (only MultiPoint)
      point_geom = feature.at_xpath('.//gml:Point[not(ancestor::gml:MultiPoint)]',
                                   'gml' => 'http://www.opengis.net/gml/3.2')
      assert_nil point_geom, 'Should not have standalone Point geometry'
    end
  end

  test 'GetFeature with BBOX and typeNames filters correctly' do
    # BBOX around point features (150, 250, 260 coordinate range)
    get '/wfs', params: {
      SERVICE: 'WFS',
      REQUEST: 'GetFeature',
      TYPENAMES: 'unknown_multipoint',
      BBOX: '100,100,300,300'
    }, headers: wfs_auth_headers

    assert_response :success
    xml = Nokogiri::XML(response.body)

    namespace = 'http://fdc.example.com/features'
    multipoint_features = xml.xpath('//fdc:unknown_multipoint', 'fdc' => namespace)

    # Should have at least one point feature in this BBOX
    assert multipoint_features.count >= 1, 'Should return point features within BBOX'

    # Should only have multipoint features
    multiline_features = xml.xpath('//fdc:unknown_multiline', 'fdc' => namespace)
    assert_equal 0, multiline_features.count, 'Should not return line features when typeNames=unknown_multipoint'
  end
end
