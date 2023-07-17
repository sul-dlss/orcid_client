# frozen_string_literal: true

RSpec.describe SulOrcidClient::ContributorMapper do
  let(:orcid_contributor) { described_class.new(contributor: contributor).map }

  context "when full mapping" do
    let(:contributor) do
      Cocina::Models::Contributor.new(
        name: [
          {
            structuredValue: [
              {
                value: "Justin",
                type: "forename"
              },
              {
                value: "Littman",
                type: "surname"
              }
            ]
          }
        ],
        type: "person",
        role: [
          {
            value: "author",
            code: "aut",
            uri: "http://id.loc.gov/vocabulary/relators/aut",
            source: {
              code: "marcrelator",
              uri: "http://id.loc.gov/vocabulary/relators/"
            }
          }
        ],
        identifier: [
          {
            value: "0000-0003-3437-349X",
            type: "ORCID",
            source: {
              uri: "https://sandbox.orcid.org"
            }
          }
        ]
      )
    end

    it "maps" do
      expect(orcid_contributor).to eq(
        {
          "credit-name": {
            value: "Justin Littman"
          },
          "contributor-orcid": {
            uri: "https://sandbox.orcid.org/0000-0003-3437-349X",
            path: "0000-0003-3437-349X",
            host: "orcid.org"
          },
          "contributor-attributes": {
            "contributor-role": "author"
          }
        }
      )
    end
  end

  context "when minimal mapping" do
    let(:contributor) do
      Cocina::Models::Contributor.new
    end

    it "maps" do
      expect(orcid_contributor).to eq({})
    end
  end

  context "when name is a simple value" do
    let(:contributor) do
      Cocina::Models::Contributor.new(
        name: [
          {
            value: "Justin Littman"
          }
        ],
        type: "person"
      )
    end

    it "maps" do
      expect(orcid_contributor).to eq(
        {
          "credit-name": {
            value: "Justin Littman"
          }
        }
      )
    end
  end

  context "when contributor is not cited" do
    let(:contributor) do
      Cocina::Models::Contributor.new(
        name: [
          {
            structuredValue: [
              {
                value: "Justin",
                type: "forename"
              },
              {
                value: "Littman",
                type: "surname"
              }
            ]
          }
        ],
        type: "person",
        note: [
          {
            value: "false",
            type: "citation status"
          }
        ]
      )
    end

    it "returns nil" do
      expect(orcid_contributor).to be_nil
    end
  end

  context "when an organization" do
    let(:contributor) do
      Cocina::Models::Contributor.new(
        name: [
          {
            value: "Stanford University"
          }
        ],
        type: "organization",
        role: [
          {
            value: "degree granting institution",
            code: "dgg",
            uri: "http://id.loc.gov/vocabulary/relators/dgg",
            source: {
              code: "marcrelator",
              uri: "http://id.loc.gov/vocabulary/relators/"
            }
          }
        ],
        identifier: [
          {
            value: "00f54p054",
            type: "ROR",
            source: {
              uri: "https://ror.org"
            }
          }
        ]
      )
    end

    it "maps" do
      expect(orcid_contributor).to eq(
        {
          "credit-name": {
            value: "Stanford University"
          },
          "contributor-orcid": {
            uri: "https://ror.org/00f54p054",
            path: "00f54p054",
            host: "ror.org"
          }
        }
      )
    end
  end
end
