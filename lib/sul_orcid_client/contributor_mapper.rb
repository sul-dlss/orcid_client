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

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def name_from_structured_value(structured_value)
      forename = structured_value.find { |name_part| name_part.type == 'forename' }&.value
      surname = structured_value.find { |name_part| name_part.type == 'surname' }&.value

      if forename.present? || surname.present?
        [forename, surname].compact.join(' ')
      else
        # take first value for the Stanford University organization. Do not map the department/institute suborganization for now.
        structured_value.first&.value
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    IDENTIFIER_TYPES = %w[ORCID ROR].freeze

    def map_orcid
      if contributor.name.first&.structuredValue.present?
        # there could be an identifier in the structuredValue if it has a suborganization
        if contributor.name.first.structuredValue.first&.identifier.present?
          orcid_from_structured_value
        else
          orcid_from_contributor
        end
      else
        orcid_from_contributor
      end
    end

    def identifier_from_structured_value(structured_value)
      structured_value.identifier.find { |identifier| IDENTIFIER_TYPES.include?(identifier.type) }
    end

    # the identifier in the structuredValue has the uri in a different properties than a top-level contributor.identifier
    def map_orcid_from_structured_value(identifier)
      {
        uri: identifier.uri || identifier.value,
        path: URI(identifier.uri).path.split('/').last,
        host: identifier.type == 'ORCID' ? 'orcid.org' : 'ror.org'
      }
    end

    def map_orcid_from_contributor(identifier)
      {
        uri: URI.join(identifier.source.uri, identifier.value).to_s,
        path: identifier.value,
        host: identifier.type == 'ORCID' ? 'orcid.org' : 'ror.org'
      }
    end

    # find and map an orcid from a contributor.identifier
    def orcid_from_contributor
      identifier = contributor.identifier.find { |check_identifier| IDENTIFIER_TYPES.include?(check_identifier.type) }
      return unless identifier

      map_orcid_from_contributor(identifier)
    end

    # find and map an orcid from a contributor.structuredValue.identifier
    def orcid_from_structured_value
      identifier = identifier_from_structured_value(contributor.name.first.structuredValue.first)
      map_orcid_from_structured_value(identifier)
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
