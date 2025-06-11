# frozen_string_literal: true

RSpec.describe SulOrcidClient::CocinaSupport do
  describe '.orcidid' do
    context 'when no orcidid' do
      let(:contributor) do
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Justin Littman'
            }
          ],
          type: 'person'
        )
      end

      it 'returns nil' do
        expect(described_class.orcidid(contributor)).to be_nil
      end
    end

    context 'when orcidid' do
      let(:contributor) do
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Justin Littman'
            }
          ],
          type: 'person',
          identifier: [
            {
              value: '0000-0003-3437-349X',
              type: 'ORCID',
              source: {
                uri: 'https://sandbox.orcid.org'
              }
            }
          ]
        )
      end

      it 'returns the orcidid' do
        expect(described_class.orcidid(contributor)).to eq('https://sandbox.orcid.org/0000-0003-3437-349X')
      end
    end

    context 'when alternate orcidid format' do
      let(:contributor) do
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Justin Littman'
            }
          ],
          type: 'person',
          identifier: [
            {
              value: '0000-0003-3437-349X',
              type: 'ORCID',
              source: {
                code: 'orcid'
              }
            }
          ]
        )
      end

      it 'returns the orcidid' do
        expect(described_class.orcidid(contributor)).to eq('https://orcid.org/0000-0003-3437-349X')
      end
    end

    context 'when another alternate orcidid format' do
      let(:contributor) do
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Justin Littman'
            }
          ],
          type: 'person',
          identifier: [
            {
              uri: 'https://sandbox.orcid.org/0000-0003-3437-349X',
              type: 'ORCID',
              source: {
                code: 'orcid'
              }
            }
          ]
        )
      end

      it 'returns the orcidid' do
        expect(described_class.orcidid(contributor)).to eq('https://sandbox.orcid.org/0000-0003-3437-349X')
      end
    end
  end
end
