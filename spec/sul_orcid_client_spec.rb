# frozen_string_literal: true

RSpec.describe SulOrcidClient do
  let(:client) do
    described_class.configure(
      client_id: FAKE_CLIENT_ID,
      client_secret: FAKE_CLIENT_SECRET,
      base_url: 'https://api.sandbox.orcid.org',
      base_public_url: 'https://pub.sandbox.orcid.org',
      base_auth_url: 'https://sandbox.orcid.org'
    )
  end

  let(:work) do
    {
      title: {
        title: {
          value: 'Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias'
        },
        subtitle: nil,
        'translated-title': nil
      },
      'journal-title': {
        value: 'The International Journal of Press/Politics'
      },
      'short-description': nil,
      citation: {
        'citation-type': 'bibtex',
        # rubocop:disable Layout/LineLength
        'citation-value': "@article{Usher_2018,\n\tdoi = {10.1177/1940161218781254},\n\turl = {https://doi.org/10.1177%2F1940161218781254},\n\tyear = 2018,\n\tmonth = {jun},\n\tpublisher = {{SAGE} Publications},\n\tvolume = {23},\n\tnumber = {3},\n\tpages = {324--344},\n\tauthor = {Nikki Usher and Jesse Holcomb and Justin Littman},\n\ttitle = {Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias},\n\tjournal = {The International Journal of Press/Politics}\n}"
        # rubocop:enable Layout/LineLength
      },
      type: 'journal-article',
      'publication-date': {
        year: {
          value: '2018'
        },
        month: {
          value: '07'
        },
        day: {
          value: '24'
        }
      },
      'external-ids': {
        'external-id': [
          {
            'external-id-type': 'doi',
            'external-id-value': '10.1177/1940161218781254',
            'external-id-normalized': {
              value: '10.1177/1940161218781254',
              transient: true
            },
            'external-id-normalized-error': nil,
            'external-id-url': {
              value: 'https://doi.org/10.1177/1940161218781254'
            },
            'external-id-relationship': 'self'
          }
        ]
      },
      url: {
        value: 'https://doi.org/10.1177/1940161218781254'
      },
      contributors: {
        contributor: [
          {
            'contributor-orcid': nil,
            'credit-name': {
              value: 'Nikki Usher'
            },
            'contributor-email': nil,
            'contributor-attributes': {
              'contributor-sequence': nil,
              'contributor-role': 'author'
            }
          },
          {
            'contributor-orcid': nil,
            'credit-name': {
              value: 'Jesse Holcomb'
            },
            'contributor-email': nil,
            'contributor-attributes': {
              'contributor-sequence': nil,
              'contributor-role': 'author'
            }
          },
          {
            'contributor-orcid': nil,
            'credit-name': {
              value: 'Justin Littman'
            },
            'contributor-email': nil,
            'contributor-attributes': {
              'contributor-sequence': nil,
              'contributor-role': 'author'
            }
          }
        ]
      },
      'language-code': nil,
      country: nil
    }
  end

  describe '#fetch_name' do
    let(:fetch_name_response) { client.fetch_name(orcidid: 'https://sandbox.orcid.org/0000-0002-2230-4756') }
    let(:bogus_fetch_name_response) { client.fetch_name(orcidid: 'bogus') }

    it 'retrieves a name given an orcid' do
      VCR.use_cassette('Sul_Orcid_Client/_fetch_name/retrieve name') do
        expect(fetch_name_response).to eq %w[Peter Test]
      end
    end

    it 'raises an exception for an invalid orcidid' do
      expect { bogus_fetch_name_response }.to raise_error('invalid orcidid provided')
    end
  end

  describe '#search' do
    context 'when a regular search' do
      let(:search_response) { client.search(query: '(ringgold-org-id:6429)') }
      let(:big_search_response) { client.search(query: 'test') }

      it 'runs a search with one page of results' do
        VCR.use_cassette('Sul_Orcid_Client/_search/search') do
          expect(search_response['num-found']).to be > 1
          expect(search_response['num-found']).to be < 1000
          expect(search_response['result'].size).to eq search_response['num-found']
          expect(search_response['result'][0]['orcid-identifier']).to include('uri')
        end
      end

      it 'runs a search with many pages of results' do
        VCR.use_cassette('Sul_Orcid_Client/_search/big_search') do
          expect(big_search_response['result'].size).to be > 1000
          expect(big_search_response['result'][0]['orcid-identifier']).to include('uri')
        end
      end
    end

    context 'when an expanded search' do
      let(:search_response) { client.search(query: '(ringgold-org-id:6429)', expanded: true) }
      let(:big_search_response) { client.search(query: 'test', expanded: true) }

      it 'runs a search with one page of results using the expanded search that includes name' do
        VCR.use_cassette('Sul_Orcid_Client/_search/expanded-search') do
          expect(search_response['num-found']).to be > 1
          expect(search_response['num-found']).to be < 1000
          expect(search_response['expanded-result'].size).to eq search_response['num-found']
          expect(search_response['expanded-result'][0]['orcid-id']).to include('0000-0003-4722-8312')
          expect(search_response['expanded-result'][0]['family-names']).to include('Chan')
        end
      end

      it 'runs a search with many pages of results' do
        VCR.use_cassette('Sul_Orcid_Client/_search/expended-big_search') do
          expect(big_search_response['expanded-result'].size).to be > 1000
          expect(big_search_response['expanded-result'][0]['orcid-id']).to include('0000-0001-6458-199X')
          expect(big_search_response['expanded-result'][0]['family-names']).to include('Smith')
        end
      end
    end
  end

  describe '#fetch_works' do
    let(:works_response) { client.fetch_works(orcidid: 'https://sandbox.orcid.org/0000-0002-7262-6251') }

    it 'retrieves works summary' do
      VCR.use_cassette('Sul_Orcid_Client/_fetch_works/retrieves works summary') do
        expect(works_response[:group].size).to eq(157)
      end
    end

    context 'when server returns 500' do
      it 'raises' do
        VCR.use_cassette('Sul_Orcid_Client/_fetch_works/raises') do
          expect { works_response }.to raise_error('ORCID.org API returned 500')
        end
      end
    end
  end

  describe '#add_work' do
    let(:put_code) { client.add_work(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', work:, token: 'FAKE29cb-194e-4bc3-8afg-99315b06be04') }

    context 'when creating work the first time' do
      it 'adds works' do
        VCR.use_cassette('Sul_Orcid_Client/_add_work/adds work') do
          expect(put_code).to eq('1250170')
        end
      end
    end

    context 'when work already exists' do
      it 'handles conflict' do
        VCR.use_cassette('Sul_Orcid_Client/_add_work/adds work again') do
          expect(put_code).to eq('1250170')
        end
      end
    end
  end

  describe '#update_work' do
    it 'updates works' do
      VCR.use_cassette('Sul_Orcid_Client/_update_work/updates work') do
        expect(client.update_work(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', put_code: '1754266', work:,
                                  token: 'FAKE29cb-194e-4bc3-8afg-99315b06be0468cf29cb-294e-4bc8-8afd-96315b06ae04')).to be true
      end
    end

    context 'when server returns a 404 error' do
      it 'raises with 404-specific message' do
        VCR.use_cassette('Sul_Orcid_Client/_update_work/raises_404') do
          expect do
            client.update_work(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', put_code: '12300000', work:,
                               token: 'FAKE29cb-194e-4bc3-8afg-99315b06be0468cf29cb-294e-4bc8-8afd-96315b06ae04')
          end.to raise_error(StandardError,
                             'ORCID.org API returned 404 when updating 12300000 for https://sandbox.orcid.org/0000-0003-3437-349X. The author may ' \
                             'have previously deleted this work from their ORCID profile.')
        end
      end
    end

    context 'when server returns an error' do
      it 'raises' do
        VCR.use_cassette('Sul_Orcid_Client/_update_work/raises') do
          expect do
            client.update_work(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', put_code: '1754266', work:,
                               token: 'FAKE29cb-194e-4bc3-8afg-99315b06be0468cf29cb-294e-4bc8-8afd-96315b06ae04')
          end.to raise_error(StandardError)
        end
      end
    end
  end

  describe '#fetch_work' do
    let(:work_response) { client.fetch_work(orcidid: 'https://orcid.org/0000-0003-1527-0030', put_code: '15473562') }

    it 'retrieves work' do
      VCR.use_cassette('Sul_Orcid_Client/_fetch_work/retrieves work') do
        expect(work_response[:title][:title][:value]).to eq('Actualized preservation threats: Practical lessons from chronicling America')
      end
    end
  end

  describe '#delete_work' do
    let(:work_deleted) { client.delete_work(orcidid: 'https://sandbox.orcid.org/0000-0002-2230-4756', put_code: '1253255', token: 'c4a9b3a4-f868-4cd1-8d7f-1d5rfd9f4bdb') }

    it 'deletes works and returns true' do
      VCR.use_cassette('Sul_Orcid_Client/_delete_work/deletes work') do
        expect(work_deleted).to be true
      end
    end

    context 'when server returns 404' do
      it 'returns false' do
        VCR.use_cassette('Sul_Orcid_Client/_delete_work/returns true') do
          expect(work_deleted).to be false
        end
      end
    end
  end
end
