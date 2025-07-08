# frozen_string_literal: true

class SulOrcidClient
  # Maps a Cocina Contributor to an Orcid Contributor.
  class ContributorMapper
    def self.map(contributor:)
      new(contributor:).map
    end

    # @param [Cocina::Models::Contributor] contributor to map
    def initialize(contributor:)
      @contributor = contributor
    end

    def map
      {
        'credit-name': map_credit_name,
        'contributor-orcid': map_orcid,
        'contributor-attributes': map_attributes
      }.compact
    end

    private

    attr_reader :contributor

    def map_credit_name
      value = if contributor.name.first&.structuredValue.present?
                name_from_structured_value(contributor.name.first.structuredValue)
              else
                contributor.name.first&.value
              end

      return unless value

      {
        value:
      }
    end

    def name_from_structured_value(structured_value)
      forename = structured_value.find { |name_part| name_part.type == 'forename' }&.value
      surname = structured_value.find { |name_part| name_part.type == 'surname' }&.value

      if forename.present? || surname.present?
        [forename, surname].compact.join(' ')
      else
        structured_value.first.value
      end
    end

    # find and map an ORCID from a contributor.identifier
    def map_orcid
      identifier = contributor.identifier.find { |check_identifier| check_identifier.type == 'ORCID' }
      return unless identifier

      {
        uri: URI.join(identifier.source.uri, identifier.value).to_s,
        path: identifier.value,
        host: 'orcid.org'
      }
    end

    def map_attributes
      {
        'contributor-role': map_role
      }.compact.presence
    end

    MARC_RELATOR_MAP = {
      'aut' => 'author',
      'cmp' => 'author',
      'ctb' => 'author',
      'cre' => 'author',
      'edt' => 'editor',
      'rth' => 'principal-investigator'
    }.freeze

    def map_role
      role = contributor.role.find do |check_role|
        check_role.source&.code == 'marcrelator' && MARC_RELATOR_MAP.key?(check_role.code)
      end

      return unless role

      MARC_RELATOR_MAP[role.code]
    end
  end
end
