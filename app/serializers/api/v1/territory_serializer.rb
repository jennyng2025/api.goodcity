module Api::V1

  class TerritorySerializer < ApplicationSerializer
    # embed :ids, include: true
    attributes :id, :name

    has_many :DistrictSerializer, serializer: DistrictSerializer

    def name__sql
      "name_#{current_language}"
    end
  end

end
