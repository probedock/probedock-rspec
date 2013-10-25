# RSpec ROX Client

**RSpec client for [ROX Center](https://github.com/lotaris/rox-center).**

[![Gem Version](https://badge.fury.io/rb/rox-client-rspec.png)](http://badge.fury.io/rb/rox-client-rspec)

## Requirements

* RSpec 2.14

## Installation

In your Gemfile:

```rb
gem 'rox-client-rspec', '~> 0.3.0'
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
  expect(true).to be_true
end

it(nil, rox: { key: 'bcdefghijklm' }){ should validate_presence_of(:name) }
```

<a name="setup"></a>
## Setup

ROX clients use [YAML](http://yaml.org) files for configuration.
To use the RSpec ROX Client, you need two configuration files and you must set up the client in your spec helper file.

In your home folder, you must create the `~/.rox/config.yml` configuration file.

```yml
# List of ROX Center servers you can submit test results to.
servers:
  - name: rox.example.com                 # A custom name for your ROX Center server.
                                          # You will use this in the client configuration file.
                                          # We recommend using the domain name where you deployed it.

    apiUrl: https://rox.example.com/api   # The URL of your ROX Center server's API.
                                          # This is the domain where you deployed it with /api.

    apiKeyId: 39fuc7x85lsoy9c0ek2d        # Your user credentials on this server.
    apiKeySecret: mwpqvvmagzoegxnqptxdaxkxonjmvrlctwcrfmowibqcpnsdqd

# If true, test results will be uploaded to ROX Center.
# Set to false to temporarily disable publishing.
# You can change this at runtime from the command line by setting the
# ROX_PUBLISH environment variable to 0 (false) or 1 (true).
publish: true
```

In the project directory where you run RSpec, you must add the `rox.yml` client configuration file:

```yml
# Configuration specific to your project.
project:
  name: My Project
  version: 1.2.3
  apiId: 154sic93pxs0   # The API key of your project in the ROX Center server.

# Where the client should store its temporary files.
# The client will work without it but it is required for some advanced features.
workspace: tmp/rox

# Client advanced features.
payload:
  
  # Saves a copy of the test payload sent to the ROX Center server for debugging.
  # The file will be saved in rspec/servers/<SERVER_NAME>/payload.json.
  save: false

  # If you track a large number of tests (more than a thousand), enabling this
  # will reduce the size of the test payloads sent to ROX Center server by caching
  # test information that doesn't change often such as the name.
  cache: false

  # Prints a copy of the test payload sent to the ROX Center server for debugging.
  # Temporarily enable at runtime by setting the ROX_PRINT_PAYLOAD environment variable to 1.
  print: false

# The name of the ROX Center server to upload test results to.
# This name must be one of the server names in the ~/.rox/config.yml file.
# You can change this at runtime from the command line by setting the
# ROX_SERVER environment variable.
server: rox.example.com
```

Finally, you must enable the client in your spec helper file (usually `spec/spec_helper.rb`).

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

Please add a changelog entry with your name for new features and bug fixes.

## License

The RSpec ROX Client is licensed under the [MIT License](http://opensource.org/licenses/MIT).

    Copyright (c) 2012-2013 Lotaris SA

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
