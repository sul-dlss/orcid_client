# frozen_string_literal: true

class SulOrcidClient
  # Helper methods for working with Orcid in Cocina
  class CocinaSupport
    # @param [Cocina::Models::Contributor] contributor to check
    # @return [String, nil] orcid id including host if present
    # rubocop:disable Metrics/AbcSize
    def self.orcidid(contributor)
      identifier = contributor.identifier.find { |check_identifier| check_identifier.type == 'ORCID' }
      return unless identifier

      # some records have the full ORCID URI in the data, just return it if so, e.g. druid:gf852zt8324
      return identifier.uri if identifier.uri
      return identifier.value if identifier.value.start_with?('https://orcid.org/')

      # some records have just the ORCIDID without the URL prefix, add it if so, e.g. druid:tp865ng1792
      return URI.join('https://orcid.org/', identifier.value).to_s if identifier.source.uri.blank?

      URI.join(identifier.source.uri, identifier.value).to_s
    end
    # rubocop:enable Metrics/AbcSize
  end
end
