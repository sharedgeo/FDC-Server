# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :authenticate_request!

  def show
    ticket = Ticket.find(params[:id])
    ticket.decorate(current_user)
    render json: ticket.to_geojson
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Ticket not found' }, status: :not_found
  end

  def search
    ticket = Ticket.find_by(ticket_no: params[:ticket_no])
    if ticket
      ticket.decorate(current_user)
      render json: ticket.to_geojson
    else
      render json: { status: 'error', message: 'Ticket not found' }, status: :not_found
    end
  end
end
