# frozen_string_literal: true

RSpec.describe SulOrcidClient::CocinaSupport do
  describe '.cited?' do
    context 'when no citation note' do
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

      it 'return true' do
        expect(described_class.cited?(contributor)).to be true
      end
    end

    context 'when citation note' do
      let(:contributor) do
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Justin Littman'
            }
          ],
          type: 'person',
          note: [
            {
              value: 'false',
              type: 'citation status'
            }
          ]
        )
      end

      it 'return false' do
        expect(described_class.cited?(contributor)).to be false
      end
    end
  end

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

  describe '.cited_orcidids' do
    let(:description) { instance_double(Cocina::Models::Description, contributor: contributors) }

    let(:contributors) do
      [
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
        ),
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Jim Littman'
            }
          ],
          type: 'person',
          identifier: [
            {
              value: '0000-0003-3437-1234',
              type: 'ORCID',
              source: {
                uri: 'https://sandbox.orcid.org'
              }
            }
          ],
          note: [
            {
              value: 'false',
              type: 'citation status'
            }
          ]
        ),
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Joe Littman'
            }
          ],
          type: 'person'
        )
      ]
    end

    it 'returns the cited orcidids' do
      expect(described_class.cited_orcidids(description)).to eq(['https://sandbox.orcid.org/0000-0003-3437-349X'])
    end
  end
end
