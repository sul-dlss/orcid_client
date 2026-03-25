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

    context 'when orcidid present' do
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
              type: 'ORCID'
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
