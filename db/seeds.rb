# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

[{
  ticket_no: 'fake-1',
  ticket_type: 'normal',
  ticket_url: '/api/tickets/fake-1/report',
  geom: 'SRID=6344;MULTIPOLYGON(((478985.7606470574 4934039.700007791,478985.76064680715 4934218.983840358,479646.69952611014 4934218.983841292,479646.6995263645 4934039.700008718,478985.7606470574 4934039.700007791)))',
  publish_date: Time.zone.now,
  purge_date: Time.zone.now + 1,
  created_at: Time.zone.now
},
 {
   ticket_no: 'fake-2',
   ticket_type: 'normal',
   ticket_url: '/api/tickets/fake-2/report',
   geom: 'SRID=6344;MULTIPOLYGON(((494674.84283961 4933100.295173284,494674.84283790056 4933943.293922424,494933.5271951324 4933943.2939229505,494933.5271968525 4933100.295173806,494674.84283961 4933100.295173284)))',
   publish_date: Time.zone.now,
   purge_date: Time.zone.now + 1,
   created_at: Time.zone.now
 },
 {
   ticket_no: 'fake-3',
   ticket_type: 'normal',
   ticket_url: '/api/tickets/fake-3/report',
   geom: 'SRID=6344;MULTIPOLYGON(((492001.60969452193 4935641.035108107,492001.60969308746 4936377.047662341,492225.65378908644 4936377.047662779,492225.6537905271 4935641.035108545,492001.60969452193 4935641.035108107)))',
   publish_date: Time.zone.now,
   purge_date: Time.zone.now + 1,
   created_at: Time.zone.now
 },
 {
   ticket_no: 'fake-4',
   ticket_type: 'normal',
   ticket_url: '/api/tickets/fake-4/report',
   geom: 'SRID=6344;MULTIPOLYGON(((492407.89072143834 4931365.115743881,492407.89072076645 4931716.073457374,492487.76719061605 4931716.073457529,492487.7671912867 4931365.115744035,492407.89072143834 4931365.115743881)))',
   publish_date: Time.zone.now,
   purge_date: Time.zone.now + 1,
   created_at: Time.zone.now
 },
 {
   ticket_no: 'fake-5',
   ticket_type: 'normal',
   ticket_url: '/api/tickets/fake-5/report',
   geom: 'SRID=6344;MULTIPOLYGON(((490914.9793431745 4926027.860046534,490914.9793420023 4926683.929067359,491760.57512953837 4926683.929068891,491760.57513073506 4926027.860048054,490914.9793431745 4926027.860046534)))',
   publish_date: Time.zone.now,
   purge_date: Time.zone.now + 1,
   created_at: Time.zone.now
 }].each do |t|
  tmp = Ticket.find_or_create_by(ticket_no: t[:ticket_no])
  tmp.update(t)
end

[{
  id: 'survey',
  code: 'SUR',
  name: 'Survey',
  color_mapserv: '243 176 196',
  color_hex: '#f3b0c4'
},
 {
   id: 'electric',
   code: 'ELE',
   name: 'Electric',
   color_mapserv: '255 0 0',
   color_hex: '#ff0000'
 },
 {
   id: 'oil_gas_steam',
   code: 'OGS',
   name: 'Oil, Gas & Steam',
   color_mapserv: '248 239 0',
   color_hex: '#f8ef00'
 },
 {
   id: 'comm_cable_conduit',
   code: 'COM',
   name: 'Communication, Cable, Conduit',
   color_mapserv: '211 114 46',
   color_hex: '#d3722e'
 },
 {
   id: 'potable_water',
   code: 'WAT',
   name: 'Potable Water',
   color_mapserv: '17 108 179',
   color_hex: '#116cb3'
 },
 {
   id: 'reclaimed_water',
   code: 'REC',
   name: 'Reclaimed Water',
   color_mapserv: '150 69 125',
   color_hex: '#96457d'
 },
 {
   id: 'sewers_drains',
   code: 'SEW',
   name: 'Sewers, Drains',
   color_mapserv: '49 145 58',
   color_hex: '#31913a'
 },
 {
   id: 'reference',
   code: 'REF',
   name: 'Reference',
   color_mapserv: '128 128 128',
   color_hex: '#808080'
 },
 {
   id: 'proposed_excavation',
   code: 'PEL',
   name: 'Proposed Excavation Limits or Route',
   color_mapserv: '255 255 255',
   color_hex: '#ffffff'
 },
 {
   id: 'unknown',
   code: 'UNK',
   name: 'Unknown',
   color_mapserv: '0 0  0',
   color_hex: '#000000'
 }].each do |fc|
  FeatureClass.find_or_create_by(id: fc[:id]) do |feature_class|
    feature_class.assign_attributes(fc)
  end
end
