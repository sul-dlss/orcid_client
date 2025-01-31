[![Gem Version](https://badge.fury.io/rb/sul_orcid_client.svg)](https://badge.fury.io/rb/sul_orcid_client)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/sul-dlss/orcid_client/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/sul-dlss/orcid_client/tree/main)
[![codecov](https://codecov.io/github/sul-dlss/orcid_client/graph/badge.svg?token=1TWAEP8SWM)](https://codecov.io/github/sul-dlss/orcid_client)

# orcid_client
API client for accessing ORCID API and for mapping to ORCID works.

Note: the *gem* name is `sul_orcid_client`;  the git repo's name is `orcid_client`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add sul_orcid_client

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install sul_orcid_client

## Usage

For one-off requests:

```ruby
require "sul_orcid_client"

# NOTE: The settings below live in the consumer, not in the gem.
client = SulOrcidClient.configure(
  client_id: Settings.orcid.client_id,
  client_secret: Settings.orcid.client_secret,
  base_url: Settings.orcid.base_url,
  base_public_url: Settings.orcid.base_public_url,
  base_auth_url: Settings.orcid.base_auth_url
)
client.fetch_works(orcidid: 'https://sandbox.orcid.org/0000-0002-7262-6251')
```

You can also invoke methods directly on the client class, which is useful in a
Rails application environment where you might initialize the client in an
initializer and then invoke client methods in many other contexts where you want
to be sure configuration has already occurred, e.g.:

```ruby
# config/initializers/sul_orcid_client.rb
SulOrcidClient.configure(
  client_id: Settings.orcid.client_id,
  client_secret: Settings.orcid.client_secret,
  base_url: Settings.orcid.base_url,
  base_public_url: Settings.orcid.base_public_url,
  base_auth_url: Settings.orcid.base_auth_url
)

# app/services/my_orcid_service.rb
# ...
def get_works
  client.fetch_works(orcidid: 'https://sandbox.orcid.org/0000-0002-7262-6251')

end
# ...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## VCR Cassettes

VCR gem is used to record the results of the API calls for the tests.  If you need to
record or re-create existing cassettes, you may need to adjust expectations in the tests
as the results coming back from the API may be different than when the cassettes were
recorded.

To record new cassettes:
1. Temporarily adjust the configuration at the top of `spec/sul_orcid_client_spec.rb` so it matches the Orcid sandbox environment.
2. Add your new spec with a new cassette name (or delete a cassette to re-create it).
3. Run just that new spec.
4. You should get a new cassette with the name you specified in the spec.
5. The cassette should have access tokens and secrets sanitized by the config in `spec_helper.rb`, but you can double check, EXCEPT for user access tokens in the user response.  These should be sanitized manaully (e.g. "access_token":"8d13b8bb-XXXX-YYYY-b7d6-87aecd5a8975")
6. Set your configuration at the top of the spec back to the fake client_id and client_secret values.
7. Re-run all the specs - they should pass now without making real calls.
