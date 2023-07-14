class SulOrcidClient
  # Maps a Cocina Description to an Orcid Work.

  # Note that this mapping is currently based on a description generated
  # from an H2 work. However, it could be extended to more completely map descriptions.
  class WorkMapper
    # Error raised by WorkMapper
    class WorkMapperError < StandardError; end

    def self.map(description:, doi: nil)
      new(description: description, doi: doi).map
    end

    # @param [Cocina::Models::Description] description to map
    # @param [String] doi from identification.doi
    def initialize(description:, doi: nil)
      @description = description
      @doi = doi
    end

    def map
      {
        title: map_title,
        "short-description": map_short_description,
        citation: map_citation,
        type: map_type,
        "publication-date": map_publication_date,
        "external-ids": map_external_ids,
        url: description.purl,
        contributors: map_contributors,
        "language-code": "en",
        country: {
          value: "US"
        }
      }.compact
    end

    private

    attr_reader :description, :doi

    def map_title
      title = description.title.first&.value
      raise WorkMapperError, "Title not mapped" unless title

      {
        title: {
          value: title.truncate(500) # ORCID has a max length for this field
        }
      }
    end

    def map_short_description
      description.note.find { |note| note.type == "abstract" }&.value
    end

    def map_citation
      citation = description.note.find { |note| note.type == "preferred citation" }&.value
      return unless citation

      {
        "citation-type": "formatted-unspecified",
        "citation-value": citation
      }
    end

    def map_external_ids
      {"external-id":
        [
          map_external_id("uri", description.purl, description.purl)
        ].tap do |ids|
          ids << map_external_id("doi", doi, "https://doi.org/#{doi}") if doi
        end}
    end

    def map_external_id(type, value, url)
      {
        "external-id-type": type,
        "external-id-value": value,
        "external-id-url": {
          value: url
        },
        "external-id-relationship": "self"
      }
    end

    def map_publication_date
      date = event_value("publication") || event_value("deposit")
      return unless date

      year, month, day = parse_date(date)
      return unless year

      {
        year: {
          value: year
        }
      }.tap do |publication_date|
        publication_date[:month] = {value: month} if month
        publication_date[:day] = {value: day} if month && day
      end
    end

    def parse_date(date)
      matcher = date.match(/(\d{4})-?(\d{2})?-?(\d{2})?/)
      return [nil, nil, nil] unless matcher

      matcher[1..3]
    end

    def event_value(type)
      description&.event&.find { |event| event.type == type }&.date&.first&.value
    end

    H2_TERM_MAP = {
      "Data" => "data-set",
      "Software/Code" => "software",
      "Article" => "journal-article",
      "Book" => "book",
      "Book chapter" => "book-chapter",
      "Code" => "software",
      "Conference session" => "lecture-speech",
      "Course/instructional materials" => "manual",
      "Database" => "data-set",
      "Dramatic performance" => "artistic-performance",
      "Geospatial data" => "data-set",
      "Journal/periodical issue" => "journal-issue",
      "Performance" => "artistic-performance",
      "Poetry reading" => "artistic-performance",
      "Poster" => "conference-poster",
      "Preprint" => "preprint",
      "Presentation recording" => "lecture-speech",
      "Questionnaire" => "research-technique",
      "Report" => "report",
      "Software" => "software",
      "Speech" => "lecture-speech",
      "Statistical model" => "research-technique",
      "Syllabus" => "manual",
      "Tabular data" => "data-set",
      "Technical report" => "report",
      "Text corpus" => "data-set",
      "Thesis" => "dissertation-thesis",
      "Working paper" => "working-paper"
    }

    def map_type
      # See https://info.orcid.org/ufaqs/what-work-types-does-orcid-support/
      # For now, only mapping H2 terms; if there is not an H2 term, using "other".

      h2_form = description.form.find { |form| form.source&.value == "Stanford self-deposit resource types" }
      return "other" unless h2_form

      map_h2_resource_types(h2_form)
    end

    def map_h2_resource_types(form)
      # Try to match subtypes first, then type
      subtype_terms = form.structuredValue.select { |term| term.type == "subtype" }.map(&:value)
      type_term = form.structuredValue.find { |term| term.type == "type" }&.value
      matching_term = (subtype_terms + [type_term]).find { |term| H2_TERM_MAP.key?(term) }
      return "other" unless matching_term

      H2_TERM_MAP[matching_term]
    end

    def map_contributors
      contributors = description.contributor.map do |contributor|
        ContributorMapper.map(contributor: contributor)
      end.compact.presence
      return unless contributors
      {
        contributor: contributors
      }
    end
  end
end
