# RSpec ROX Client

**RSpec client for [ROX Center](https://github.com/lotaris/rox-center).**

[![Gem Version](https://badge.fury.io/rb/rox-client-rspec.png)](http://badge.fury.io/rb/rox-client-rspec)

## Requirements

* RSpec 3.1 (0.4.0+)
  * *RSpec 2.14 is supported up to version 0.3.1*

## Installation

In your Gemfile:

```rb
gem 'rox-client-rspec', '~> 0.4.0'
```

Manually:

    gem install rox-client-rspec

## Usage

If you haven't done it already, follow the [setup procedure](#setup) below.

To track a test, you must assign it a ROX test key generated from your ROX Center server.

**NOTE: currently, all the tests in your test suite must be assigned a test key for the client to work.**

Test keys are assigned to test using RSpec metadata:

```rb
it "should work", rox: { key: 'abcdefghijkl' } do
  expect(true).to be(true)
end

it(nil, rox: { key: 'bcdefghijklm' }){ should validate_presence_of(:name) }
```

<a name="setup"></a>
## Setup

You must first set up the configuration file(s) for the project.
This procedure is described in the [rox-client](https://github.com/lotaris/rox-client) repository:

* [ROX Center Client Configuration](https://github.com/lotaris/rox-client#setup-procedure)

You must then enable the client in your spec helper file (e.g. `spec/spec_helper.rb`).

```yml
RoxClient::RSpec.configure do |config|

  # Optional ROX Center category to add to all the tests sent with this client.
  config.project.category = 'RSpec'
end
```

The next time you run your test suite, the RSpec ROX Client will send the results to your ROX Center server.

## Contributing

* [Fork](https://help.github.com/articles/fork-a-repo)
* Create a topic branch - `git checkout -b my_feature`
* Push to your branch - `git push origin my_feature`
* Create a [pull request](http://help.github.com/pull-requests/) from your branch

Please add a [changelog](CHANGELOG.md) entry with your name for new features and bug fixes.

## License

The RSpec ROX Client is licensed under the [MIT License](http://opensource.org/licenses/MIT).
See [LICENSE.txt](LICENSE.txt) for the full license.
