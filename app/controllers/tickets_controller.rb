# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :authenticate_request!

  def show
    ticket = Ticket.find_by(ticket_no: params[:ticket_no])

    if ticket
      render json: ticket_to_geojson(ticket)
    else
      render json: { status: 'error', message: 'Ticket not found' }, status: :not_found
    end
  end

  private

  def ticket_to_geojson(ticket)
    geometry = RGeo::GeoJSON.encode(ticket.geom_as_4326)

    properties = ticket.attributes.except('geom')

    {
      type: 'Feature',
      geometry: geometry,
      properties: properties
    }
  end
end
