# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1',
        description: 'API supports both Bearer token authentication (via Authorization header) and cookie-based authentication (via HTTP cookies) for web applications.'
      },
      paths: {},
      security: [
        {
          bearer_auth: []
        },
        {
          cookie_auth: []
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT token in Authorization header (Bearer token) - suitable for mobile apps and explicit token passing'
          },
          cookie_auth: {
            type: :apiKey,
            in: :cookie,
            name: 'jwt_token',
            description: 'JWT token stored in HTTP cookie - suitable for web applications'
          }
        }
      },
      servers: [
        {
          url: 'https://api.example.com/',
          description: 'Production'
        },
        {
          url: '{protocol}://{defaultHost}',
          variables: {
            protocol: {
              default: 'http'
            },
            defaultHost: {
              default: 'localhost:3000'
            }
          }
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
