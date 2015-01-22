# OrionVM API Client Generator

Generate HTTP clients for API in any target language (powered by .erb templates) from JSON schema.

Based on [Heroics](http://github.com/interagent/heroics)

## Installation

This tool is meant to be used as a command only, not as an imported gem

Therefore it can be used from inside the project directory like so:
```
bundle install --path vendor
bundle exec bin/ovm-generate ....
```

Or it can be installed to the system so the executable is in your path always:
```
sudo bundle install
ovm-generate ...
```

## Usage

### Generating a client

Usage: ovm-generate schema_filepath view output_folder module_name company_name homepage version

Generates an HTTP client from a JSON schema that describes your API.
Look at [prmd](https://github.com/interagent/prmd) for tooling to help write a
JSON schema.  When you have a JSON schema prepared you can generate a client
for your API:

```
bin/ovm-generate schema.json python ~/python-client OrionVM "OrionVM Pty. Ltd." http://www.orionvm.com 0.3
```

Option          | Meaning
--------------- | -------------------------------------------------
schema_filepath | path to the JSON schema file
view            | absolute path to a view/template folder, or path relative to the project's lib/heroics/views folder
output_folder   | path to where the resulting generated files will be saved. The directory will be created if it doesn't exist
module_name     | Variable available to templating engine
company_name    | ""
homepage        | ""
version         | ""

