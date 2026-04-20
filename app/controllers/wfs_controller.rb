# frozen_string_literal: true

class WfsController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :authenticate

  def index
    request_type = params[:REQUEST] || params[:request]
    service = params[:SERVICE] || params[:service]

    # Validate that this is a WFS request
    unless service&.upcase == 'WFS'
      return render_exception('InvalidParameterValue', 'SERVICE parameter must be WFS')
    end

    case request_type&.upcase
    when 'GETCAPABILITIES'
      handle_get_capabilities
    when 'DESCRIBEFEATURETYPE'
      handle_describe_feature_type
    when 'GETFEATURE'
      handle_get_feature
    else
      render_exception('OperationNotSupported', "REQUEST #{request_type} is not supported")
    end
  rescue StandardError => e
    Rails.logger.error("WFS Error: #{e.message}\n#{e.backtrace.join("\n")}")
    render_exception('NoApplicableCode', e.message)
  end

  private

  def authenticate
    expected_username = ENV['WFS_USERNAME']
    expected_password = ENV['WFS_PASSWORD']

    unless expected_username.present? && expected_password.present?
      Rails.logger.error('WFS authentication credentials not configured in environment variables')
      render_authentication_error('WFS service is not properly configured')
      return
    end

    authenticate_or_request_with_http_basic('WFS Service') do |username, password|
      # Use secure comparison to prevent timing attacks
      ActiveSupport::SecurityUtils.secure_compare(username, expected_username) &&
        ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
    end
  end

  def render_authentication_error(message)
    xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |builder|
      builder['ows'].ExceptionReport(
        'xmlns:ows' => 'http://www.opengis.net/ows/1.1',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.opengis.net/ows/1.1 http://schemas.opengis.net/ows/1.1.0/owsExceptionReport.xsd',
        'version' => '2.0.0'
      ) do
        builder['ows'].Exception('exceptionCode' => 'NoApplicableCode') do
          builder['ows'].ExceptionText message
        end
      end
    end

    render xml: xml.to_xml, status: :internal_server_error, content_type: 'application/xml'
  end

  def handle_get_capabilities
    base_url = request.base_url + request.path
    xml_response = WfsService.get_capabilities(base_url)
    render xml: xml_response, content_type: 'application/xml'
  end

  def handle_describe_feature_type
    type_names = params[:TYPENAMES] || params[:typeNames] || params[:typenames] || params[:TYPENAME] || params[:typeName] || params[:typename]
    xml_response = WfsService.describe_feature_type(type_names: type_names)
    render xml: xml_response, content_type: 'application/gml+xml; version=3.2'
  end

  def handle_get_feature
    # Parse parameters (case-insensitive)
    bbox = params[:BBOX] || params[:bbox]
    count = params[:COUNT] || params[:count]
    result_type = params[:RESULTTYPE] || params[:resultType] || params[:resulttype]
    type_names = params[:TYPENAMES] || params[:typeNames] || params[:typenames]
    base_url = request.base_url + request.path

    xml_response = WfsService.get_feature(
      bbox: bbox,
      count: count,
      result_type: result_type,
      type_names: type_names,
      base_url: base_url
    )
    render xml: xml_response, content_type: 'application/gml+xml; version=3.2'
  end

  def render_exception(code, message)
    xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |builder|
      builder['ows'].ExceptionReport(
        'xmlns:ows' => 'http://www.opengis.net/ows/1.1',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.opengis.net/ows/1.1 http://schemas.opengis.net/ows/1.1.0/owsExceptionReport.xsd',
        'version' => '2.0.0'
      ) do
        builder['ows'].Exception('exceptionCode' => code) do
          builder['ows'].ExceptionText message
        end
      end
    end

    render xml: xml.to_xml, status: :bad_request, content_type: 'application/xml'
  end
end
