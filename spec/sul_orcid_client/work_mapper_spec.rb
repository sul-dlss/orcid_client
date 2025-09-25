# frozen_string_literal: true

RSpec.describe SulOrcidClient::WorkMapper do
  describe '.map' do
    context 'when full record' do
      let(:description) do
        Cocina::Models::Description.new(
          title: [
            {
              value: 'Strategies for Digital Library Migration'
            }
          ],
          purl: 'https://purl.stanford.edu/hj302gv2126',
          note: [{
            value: 'A migration of the datastore and data model for Stanford Digital Repositorys digital object metadata was recently completed.',
            type: 'abstract'
          }, {
            # rubocop:disable Layout/LineLength
            value: 'Littman, J. and Giarlo, M. (2023). Strategies for Digital Library Migration. Stanford Digital Repository. Available at https://sul-purl-stage.stanford.edu/ny296bw4297. https://doi.org/10.80343/ny296bw4297.',
            # rubocop:enable Layout/LineLength
            type: 'preferred citation'
          }],
          contributor: [
            {
              name: [
                {
                  value: 'Justin Littman'
                }
              ],
              type: 'person'
            }
          ],
          event: [
            {
              type: 'deposit',
              date: [
                {
                  value: '2023-03-02',
                  type: 'publication',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            },
            {
              type: 'publication',
              date: [
                {
                  value: '2023-02-06',
                  type: 'publication',
                  status: 'primary',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ],
          form: [
            {
              structuredValue: [
                {
                  value: 'Text',
                  type: 'type'
                },
                {
                  value: 'Article',
                  type: 'subtype'
                }
              ],
              type: 'resource type',
              source: {
                value: 'Stanford self-deposit resource types'
              }
            },
            {
              value: 'text',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        )
      end

      let(:work) do
        described_class.map(description:, doi: '10.25740/hj302gv2126')
      end

      it 'maps' do
        # rubocop:disable Layout/LineLength
        expect(work).to eq(
          title: {
            title: {
              value: 'Strategies for Digital Library Migration'
            }
          },
          'short-description': 'A migration of the datastore and data model for Stanford Digital Repositorys digital object metadata was recently completed.',
          citation: {
            'citation-type': 'formatted-unspecified',
            'citation-value': 'Littman, J. and Giarlo, M. (2023). Strategies for Digital Library Migration. Stanford Digital Repository. Available at https://sul-purl-stage.stanford.edu/ny296bw4297. https://doi.org/10.80343/ny296bw4297.'
          },
          type: 'journal-article',
          'publication-date': {
            year: {
              value: '2023'
            },
            month: {
              value: '02'
            },
            day: {
              value: '06'
            }
          },
          'external-ids': {
            'external-id': [
              {
                'external-id-type': 'uri',
                'external-id-value': 'https://purl.stanford.edu/hj302gv2126',
                'external-id-url': {
                  value: 'https://purl.stanford.edu/hj302gv2126'
                },
                'external-id-relationship': 'self'
              },
              {
                'external-id-type': 'doi',
                'external-id-value': '10.25740/hj302gv2126',
                'external-id-url': {
                  value: 'https://doi.org/10.25740/hj302gv2126'
                },
                'external-id-relationship': 'self'
              }
            ]
          },
          url: 'https://purl.stanford.edu/hj302gv2126',
          contributors: {
            contributor: [
              {
                'credit-name': {
                  value: 'Justin Littman'
                }
              }
            ]
          },
          'language-code': 'en',
          country: {
            value: 'US'
          }
        )
        # rubocop:enable Layout/LineLength
      end

      it 'is accepted by orcid api' do
        # To update this, you need the real client id and secret, as
        # well as a real token (which can be retrieved from MAIS.)
        client = SulOrcidClient.configure(
          client_id: FAKE_CLIENT_ID,
          client_secret: FAKE_CLIENT_SECRET,
          base_url: 'https://api.sandbox.orcid.org',
          base_public_url: 'https://pub.sandbox.orcid.org',
          base_auth_url: 'https://sandbox.orcid.org'
        )

        VCR.use_cassette('Work_Mapper/_map/accepted_by_orcid_api') do
          expect(client.add_work(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', work:,
                                 token: 'FAKE-294e-4bc8-8afd-96315b06ae04')).to eq('1755750')
        end
      end
    end

    context 'when minimal record' do
      let(:description) do
        Cocina::Models::Description.new(
          title: [
            {
              value: 'Strategies for Digital Library Migration'
            }
          ],
          purl: 'https://purl.stanford.edu/hj302gv2126'
        )
      end

      it 'maps' do
        expect(described_class.map(description:)).to eq(
          title: {
            title: {
              value: 'Strategies for Digital Library Migration'
            }
          },
          type: 'other',
          'external-ids': {
            'external-id': [
              {
                'external-id-type': 'uri',
                'external-id-value': 'https://purl.stanford.edu/hj302gv2126',
                'external-id-url': {
                  value: 'https://purl.stanford.edu/hj302gv2126'
                },
                'external-id-relationship': 'self'
              }
            ]
          },
          url: 'https://purl.stanford.edu/hj302gv2126',
          'language-code': 'en',
          country: {
            value: 'US'
          }
        )
      end
    end

    context 'with a structured title' do
      let(:description) do
        Cocina::Models::Description.new(
          title: [
            {
              structuredValue: [
                {
                  value: 'The',
                  type: 'nonsorting characters'
                },
                {
                  value: 'code4lib journal',
                  type: 'main title'
                }
              ]
            }
          ],
          purl: 'https://purl.stanford.edu/hj302gv2126'
        )
      end

      let(:work) do
        described_class.map(description:)
      end

      it 'maps' do
        expect(work).to eq(
          country: { value: 'US' },
          'external-ids': {
            'external-id': [
              {
                'external-id-relationship': 'self',
                'external-id-type': 'uri',
                'external-id-url': {
                  value: 'https://purl.stanford.edu/hj302gv2126'
                },
                'external-id-value': 'https://purl.stanford.edu/hj302gv2126'
              }
            ]
          },
          'language-code': 'en',
          title: { title: { value: 'code4lib journal' } },
          type: 'other',
          url: 'https://purl.stanford.edu/hj302gv2126'
        )
      end
    end
  end

  # Testing certain private methods independently.
  describe '.parse_date' do
    let(:mapper) { described_class.new(description: nil) }

    it 'parses' do
      expect(mapper.send(:parse_date, '2021-08-31')).to eq(%w[2021 08 31])
      expect(mapper.send(:parse_date, '202?-08-31')).to eq([nil, nil, nil])
      expect(mapper.send(:parse_date, '2021-08')).to eq(['2021', '08', nil])
      expect(mapper.send(:parse_date, '2021')).to eq(['2021', nil, nil])
    end
  end

  describe '.map_h2_resource_types' do
    let(:mapper) { described_class.new(description: nil) }

    context 'when does not match subtype' do
      let(:form) do
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              value: 'Code',
              type: 'type'
            },
            {
              value: 'CAD',
              type: 'subtype'
            }
          ]
        )
      end

      it 'maps type' do
        expect(mapper.send(:map_h2_resource_types, form)).to eq('software')
      end
    end

    context 'when does not match subtype or type' do
      let(:form) do
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              value: 'Sound',
              type: 'type'
            },
            {
              value: 'Broadcast',
              type: 'subtype'
            }
          ]
        )
      end

      it 'returns other' do
        expect(mapper.send(:map_h2_resource_types, form)).to eq('other')
      end
    end
  end
end
