# frozen_string_literal: true

require 'test_helper'

class WfsTest < ActionDispatch::IntegrationTest
  fixtures :all

  # GetCapabilities Tests
  test 'GetCapabilities returns valid XML with correct structure' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

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

    # Check for Feature Type
    feature_type_name = xml.at_xpath('//wfs:FeatureType/wfs:Name',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil feature_type_name
    assert_equal 'unknown_features', feature_type_name.text

    # Check for CRS
    default_crs = xml.at_xpath('//wfs:FeatureType/wfs:DefaultCRS',
                               'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil default_crs
    assert_equal 'urn:ogc:def:crs:EPSG::6344', default_crs.text
  end

  test 'GetCapabilities works with lowercase parameters' do
    get '/wfs', params: { service: 'wfs', request: 'getcapabilities' }

    assert_response :success
    xml = Nokogiri::XML(response.body)
    capabilities = xml.at_xpath('//wfs:WFS_Capabilities',
                                'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil capabilities
  end

  test 'GetCapabilities works via POST' do
    post '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

    assert_response :success
    xml = Nokogiri::XML(response.body)
    capabilities = xml.at_xpath('//wfs:WFS_Capabilities',
                                'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil capabilities
  end

  # DescribeFeatureType Tests
  test 'DescribeFeatureType returns valid XSD schema' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'DescribeFeatureType' }

    assert_response :success
    assert_match %r{application/gml\+xml}, response.content_type

    xml = Nokogiri::XML(response.body)
    assert xml.errors.empty?, "XML should be valid: #{xml.errors.inspect}"

    # Check for schema root element (no namespace prefix on root element)
    schema = xml.at_xpath('//schema') || xml.at_xpath('//xsd:schema',
                         'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil schema, 'Should have schema root element'

    # Check for feature element definition
    feature_element = xml.at_xpath('//xsd:element[@name="unknown_features"]',
                                   'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil feature_element, 'Should define unknown_features element'

    # Check for required attributes in the schema
    required_fields = %w[id label notes feature_class_id created_at updated_at geom]
    required_fields.each do |field|
      element = xml.at_xpath("//xsd:element[@name='#{field}']",
                            'xsd' => 'http://www.w3.org/2001/XMLSchema')
      assert_not_nil element, "Should define #{field} element"
    end
  end

  test 'DescribeFeatureType works with lowercase parameters' do
    get '/wfs', params: { service: 'wfs', request: 'describefeaturetype' }

    assert_response :success
    xml = Nokogiri::XML(response.body)
    # The schema element is the root, search without namespace prefix
    schema = xml.at_xpath('//schema') || xml.at_xpath('//xsd:schema',
                         'xsd' => 'http://www.w3.org/2001/XMLSchema')
    assert_not_nil schema
  end

  # GetFeature Tests
  test 'GetFeature returns GML FeatureCollection with unknown features only' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature' }

    assert_response :success
    assert_match %r{application/gml\+xml}, response.content_type

    xml = Nokogiri::XML(response.body)
    assert xml.errors.empty?, "XML should be valid: #{xml.errors.inspect}"

    # Check for FeatureCollection root element
    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil feature_collection, 'Should have FeatureCollection root element'

    # Check number of features returned
    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 3, members.count, 'Should return 3 unknown features'

    # Verify numberMatched and numberReturned attributes
    assert_equal '3', feature_collection['numberMatched']
    assert_equal '3', feature_collection['numberReturned']

    # Check that features have proper structure
    namespace = 'http://fdc.example.com/features'
    features = xml.xpath('//fdc:unknown_features',
                        'fdc' => namespace)
    assert_equal 3, features.count

    # Verify first feature has all expected elements
    first_feature = features.first
    assert_not_nil first_feature.at_xpath('fdc:id', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:feature_class_id', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:created_at', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:updated_at', 'fdc' => namespace)
    assert_not_nil first_feature.at_xpath('fdc:geom', 'fdc' => namespace)

    # Verify geometry contains GML
    geom_element = first_feature.at_xpath('fdc:geom', 'fdc' => namespace)
    gml_element = geom_element.at_xpath('.//gml:MultiSurface',
                                       'gml' => 'http://www.opengis.net/gml/3.2')
    assert_not_nil gml_element, 'Geometry should contain GML MultiSurface'

    # Verify CRS
    assert_equal 'urn:ogc:def:crs:EPSG::6344', gml_element['srsName']
  end

  test 'GetFeature does not return features with unknown=false' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature' }

    assert_response :success
    xml = Nokogiri::XML(response.body)

    # We have 3 unknown features and 2 known features in fixtures
    # Should only return the 3 unknown ones
    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 3, members.count

    # Verify none of the returned features are the "known" ones
    namespace = 'http://fdc.example.com/features'
    labels = xml.xpath('//fdc:label',
                      'fdc' => namespace).map(&:text)

    assert_not_includes labels, 'Known Survey Feature'
    assert_not_includes labels, 'Known Electric Feature'
  end

  test 'GetFeature with BBOX filters features spatially' do
    # BBOX that should only include the first unknown feature (100-200 range)
    bbox = '50,50,250,250'
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', BBOX: bbox }

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
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', BBOX: bbox }

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
    get '/wfs', params: { service: 'wfs', request: 'getfeature' }

    assert_response :success
    xml = Nokogiri::XML(response.body)
    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_not_nil feature_collection
  end

  # Error Handling Tests
  test 'returns error for missing SERVICE parameter' do
    get '/wfs', params: { REQUEST: 'GetCapabilities' }

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
    assert_equal 'InvalidParameterValue', exception['exceptionCode']
  end

  test 'returns error for invalid SERVICE parameter' do
    get '/wfs', params: { SERVICE: 'WMS', REQUEST: 'GetCapabilities' }

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
    assert_equal 'InvalidParameterValue', exception['exceptionCode']
  end

  test 'returns error for unsupported REQUEST operation' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'UnsupportedOperation' }

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
    assert_equal 'OperationNotSupported', exception['exceptionCode']
  end

  test 'returns error for missing REQUEST parameter' do
    get '/wfs', params: { SERVICE: 'WFS' }

    assert_response :bad_request
    xml = Nokogiri::XML(response.body)
    exception = xml.at_xpath('//ows:Exception',
                            'ows' => 'http://www.opengis.net/ows/1.1')
    assert_not_nil exception
  end

  # Enhanced WFS 2.0 Tests
  test 'GetCapabilities includes conformance constraints' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

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
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

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
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

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
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

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
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetCapabilities' }

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
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', COUNT: 2 }

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')

    # numberMatched should be total (3)
    assert_equal '3', feature_collection['numberMatched']

    # numberReturned should be limited (2)
    assert_equal '2', feature_collection['numberReturned']

    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 2, members.count
  end

  test 'GetFeature with resultType=hits returns count only' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature', RESULTTYPE: 'hits' }

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0')

    # Should have count but no features
    assert_equal '3', feature_collection['numberMatched']
    assert_equal '0', feature_collection['numberReturned']

    members = xml.xpath('//wfs:member',
                       'wfs' => 'http://www.opengis.net/wfs/2.0')
    assert_equal 0, members.count
  end

  test 'GetFeature includes schema location pointing to DescribeFeatureType' do
    get '/wfs', params: { SERVICE: 'WFS', REQUEST: 'GetFeature' }

    assert_response :success
    xml = Nokogiri::XML(response.body)

    feature_collection = xml.at_xpath('//wfs:FeatureCollection',
                                     'wfs' => 'http://www.opengis.net/wfs/2.0',
                                     'xsi' => 'http://www.w3.org/2001/XMLSchema-instance')

    schema_location = feature_collection.attribute_with_ns('schemaLocation', 'http://www.w3.org/2001/XMLSchema-instance')
    assert_not_nil schema_location
    assert_match(/DescribeFeatureType/, schema_location.value)
  end
end
