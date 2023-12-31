# frozen_string_literal: true

class SulOrcidClient
  # Helper methods for working with Orcid in Cocina
  # NOTE: there is similar code in dor_indexing_app which fetches
  # ORCIDs out of cocina.  Consider consolidating at some point or keeping in sync.
  # see https://github.com/sul-dlss/dor_indexing_app/blob/main/app/services/orcid_builder.rb
  # and https://github.com/sul-dlss/dor_indexing_app/issues/1022
  class CocinaSupport
    # @param [Cocina::Models::Contributor] contributor to check
    # @return [Boolean] true unless the contributor has a citation status of false
    def self.cited?(contributor)
      contributor.note.none? { |note| note.type == 'citation status' && note.value == 'false' }
    end

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

    # @param [Cocina::Models::Description] description containing contributors to check
    # @return [Array<String>] orcid ids including host if present
    # Note that non-cited contributors are excluded.
    def self.cited_orcidids(description)
      cited_contributors = description.contributor.select { |contributor| cited?(contributor) }
      cited_contributors.filter_map { |contributor| orcidid(contributor) }
    end
  end
end
