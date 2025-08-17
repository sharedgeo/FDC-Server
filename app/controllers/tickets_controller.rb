# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :authenticate_request!

  def show
    ticket = Ticket.find(params[:id])
    ticket.decorate(current_user)
    render json: ticket_to_geojson(ticket)
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Ticket not found' }, status: :not_found
  end

  def search
    ticket = Ticket.find_by(ticket_no: params[:ticket_no])
    if ticket
      ticket.decorate(current_user)
      render json: ticket_to_geojson(ticket)
    else
      render json: { status: 'error', message: 'Ticket not found' }, status: :not_found
    end
  end

  private

  def ticket_to_geojson(ticket)
    proj4_4326 = '+proj=longlat +datum=WGS84 +no_defs'

    factory_4326 = RGeo::Geographic.spherical_factory(
      srid: 4326,
      proj4: proj4_4326
    )

    geom_4326 = RGeo::Feature.cast(
      ticket.geom,
      factory: factory_4326,
      project: true
    )
    geometry = RGeo::GeoJSON.encode(geom_4326)
    properties = ticket.api_attributes

    {
      type: 'Feature',
      geometry: geometry,
      properties: properties
    }
  end
end
