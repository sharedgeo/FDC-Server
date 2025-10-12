module Geom4326
  extend ActiveSupport::Concern

  def geom_as_4326
    proj4_4326 = '+proj=longlat +datum=WGS84 +no_defs'

    factory_4326 = RGeo::Geographic.spherical_factory(
      srid: SridConstants::SRID_4326,
      proj4: proj4_4326
    )

    RGeo::Feature.cast(
      geom,
      factory: factory_4326,
      project: true
    )
  end
end
