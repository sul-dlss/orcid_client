# frozen_string_literal: true

class SulOrcidClient
  # Helper methods for working with Orcid in Cocina
  class CocinaSupport
    # @param [Cocina::Models::Contributor] contributor to check
    # @return [String, nil] orcid id including host if present
    def self.orcidid(contributor)
      contributor.identifier.find { |check_identifier| check_identifier.type == 'ORCID' }&.uri
    end
  end
end
