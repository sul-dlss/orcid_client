class SulOrcidClient
  # Helper methods for working with Orcid in Cocina
  class CocinaSupport
    # @param [Cocina::Models::Contributor] contributor to check
    # @return [Boolean] true unless the contributor has a citation status of false
    def self.cited?(contributor)
      contributor.note.none? { |note| note.type == "citation status" && note.value == "false" }
    end

    # @param [Cocina::Models::Contributor] contributor to check
    # @return [String, nil] orcid id including host if present
    def self.orcidid(contributor)
      identifier = contributor.identifier.find { |identifier| identifier.type == "ORCID" }
      return unless identifier

      URI.join(identifier.source.uri, identifier.value).to_s
    end

    # @param [Cocina::Models::Description] description containing contributors to check
    # @return [Array<String>] orcid ids including host if present
    # Note that non-cited contributors are excluded.
    def self.cited_orcidids(description)
      cited_contributors = description.contributor.select { |contributor| cited?(contributor) }
      cited_contributors.map { |contributor| orcidid(contributor) }.compact
    end
  end
end
