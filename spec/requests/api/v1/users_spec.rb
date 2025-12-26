require 'swagger_helper'
require 'support/jwt_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  path '/api/v1/users' do
    get 'List all users' do
      tags 'Users'
      security [ { bearer_auth: [] } ]
      produces 'application/json'

      response '200', 'users listed' do
        let(:user_record) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }

        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string, format: :uuid },
                  type: { type: :string },
                  attributes: {
                    type: :object,
                    properties: {
                      name: { type: :string },
                      email: { type: :string },
                      phone: { type: :string, nullable: true },
                      email_confirmed: { type: :boolean },
                      phone_confirmed: { type: :boolean },
                      profile: { type: :object },
                      roles: {
                        type: :array,
                        items: { type: :string },
                        description: 'Array of role names assigned to the user'
                      },
                      created_at: { type: :string, format: 'date-time' },
                      updated_at: { type: :string, format: 'date-time' }
                    }
                  }
                }
              }
            }
          }

        example "application/json", :success, {
          data: [
            {
              id: "550e8400-e29b-41d4-a716-446655440000",
              type: "user",
              attributes: {
                name: "John Doe",
                email: "john@example.com",
                phone: "+1234567890",
                email_confirmed: true,
                phone_confirmed: true,
                profile: {
                  "bio" => "Software developer",
                  "location" => "San Francisco"
                },
                roles: [ "user" ],
                created_at: "2024-01-01T00:00:00.000Z",
                updated_at: "2024-01-01T00:00:00.000Z"
              }
            },
            {
              id: "550e8400-e29b-41d4-a716-446655440001",
              type: "user",
              attributes: {
                name: "Jane Smith",
                email: "jane@example.com",
                phone: "+1987654321",
                email_confirmed: true,
                phone_confirmed: false,
                profile: {},
                roles: [ "user", "facilitator" ],
                created_at: "2024-01-02T00:00:00.000Z",
                updated_at: "2024-01-02T00:00:00.000Z"
              }
            }
          ]
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/users/me' do
    get 'Get current user information' do
      tags 'Users'
      security [ { bearer_auth: [] } ]
      produces 'application/json'

      response '200', 'current user found' do
        let(:user_record) { create(:user, name: 'Current User', email: 'current@example.com') }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }

        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: { type: :string, format: :uuid },
                type: { type: :string },
                attributes: {
                  type: :object,
                  properties: {
                    name: { type: :string },
                    email: { type: :string },
                    phone: { type: :string, nullable: true },
                    email_confirmed: { type: :boolean },
                    phone_confirmed: { type: :boolean },
                    profile: { type: :object },
                    roles: {
                      type: :array,
                      items: { type: :string },
                      description: 'Array of role names assigned to the user'
                    },
                    created_at: { type: :string, format: 'date-time' },
                    updated_at: { type: :string, format: 'date-time' }
                  }
                }
              }
            }
          }

        example "application/json", :success, {
          data: {
            id: "uuid",
            type: "user",
            attributes: {
              name: "Current User",
              email: "current@example.com",
              phone: "+1234567890",
              organization_id: "550e8400-e29b-41d4-a716-446655440000",
              email_confirmed: true,
              phone_confirmed: false,
              is_profile_complete: false,
              require_password_change: false,
              profile: {},
              roles: [ "user", "facilitator" ],
              created_at: "2024-01-01T00:00:00.000Z",
              updated_at: "2024-01-01T00:00:00.000Z"
            }
          }
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('Current User')
          expect(json['data']['attributes']['email']).to eq('current@example.com')
          expect(json['data']['id']).to eq(user_record.id)
          expect(json['data']['attributes']).to have_key('roles')
          expect(json['data']['attributes']['roles']).to be_an(Array)
          expect(json['data']['attributes']).to have_key('profile')
          expect(json['data']['attributes']['profile']).to be_a(Hash)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'invalid' }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :unauthorized, {
          error: "No token provided"
        }

        run_test!
      end

      response '401', 'expired token' do
        let(:user_record) { create(:user) }
        let(:expired_token) do
          JWT.encode({ user_id: user_record.id, exp: 1.hour.ago.to_i }, Rails.application.credentials.jwt_secret, "HS256")
        end
        let(:Authorization) { "Bearer #{expired_token}" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :expired, {
          error: "Token has expired"
        }

        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    get 'Get a user' do
      tags 'Users'
      security [ { bearer_auth: [] } ]
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'user found' do
        let(:user_record) { create(:user, name: 'Test User', email: 'test@example.com') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }

        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: { type: :string, format: :uuid },
                type: { type: :string },
                attributes: {
                  type: :object,
                  properties: {
                    name: { type: :string },
                    email: { type: :string },
                    phone: { type: :string, nullable: true },
                    email_confirmed: { type: :boolean },
                    phone_confirmed: { type: :boolean },
                    profile: { type: :object },
                    roles: {
                      type: :array,
                      items: { type: :string },
                      description: 'Array of role names assigned to the user'
                    },
                    created_at: { type: :string, format: 'date-time' },
                    updated_at: { type: :string, format: 'date-time' }
                  }
                }
              }
            }
          }

        example "application/json", :success, {
          data: {
            id: "550e8400-e29b-41d4-a716-446655440000",
            type: "user",
            attributes: {
              name: "Test User",
              email: "test@example.com",
              phone: "+1234567890",
              email_confirmed: true,
              phone_confirmed: true,
              profile: {
                "bio" => "Test user bio",
                "location" => "Test City"
              },
              roles: [ "user" ],
              created_at: "2024-01-01T00:00:00.000Z",
              updated_at: "2024-01-01T00:00:00.000Z"
            }
          }
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('Test User')
          expect(json['data']['attributes']['email']).to eq('test@example.com')
        end
      end

      response '401', 'unauthorized' do
        let(:id) { 'invalid' }
        let(:Authorization) { 'invalid' }
        run_test!
      end

      response '404', 'user not found' do
        let(:user_record) { create(:user) }
        let(:id) { '00000000-0000-0000-0000-000000000000' }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    patch 'Update a user' do
      tags 'Users'
      security [ { bearer_auth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      description 'Updates user profile information including name, phone, organization, and custom profile data. Phone number changes automatically trigger SMS verification.'

      parameter name: :id, in: :path, type: :string, required: true, description: 'User ID'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              name: {
                type: :string,
                description: 'Full name of the user',
                example: 'John Doe'
              },
              phone: {
                type: :string,
                description: 'Phone number in international format. Changing this will reset phone confirmation and send verification SMS.',
                example: '+15551234567'
              },
              profile: {
                type: :object,
                description: 'Custom profile data stored as JSON. Can contain any user-defined fields.',
                properties: {
                  bio: { type: :string, description: 'User biography', example: 'Software developer with 5 years experience' },
                  department: { type: :string, description: 'Department name', example: 'Engineering' },
                  job_title: { type: :string, description: 'Job title', example: 'Senior Software Developer' },
                  skills: {
                    type: :array,
                    items: { type: :string },
                    description: 'List of skills',
                    example: [ 'JavaScript', 'Ruby', 'React' ]
                  },
                  location: { type: :string, description: 'Work location', example: 'San Francisco, CA' },
                  hire_date: { type: :string, format: :date, description: 'Date of hire', example: '2020-01-15' }
                },
                example: {
                  bio: 'Software developer with 5 years experience',
                  department: 'Engineering',
                  job_title: 'Senior Software Developer',
                  skills: [ 'JavaScript', 'Ruby', 'React' ],
                  location: 'San Francisco, CA',
                  hire_date: '2020-01-15'
                }
              }
            }
          }
        }
      }

      response '200', 'phone number updated' do
        let(:user_record) { create(:user, phone: '5551234567', phone_confirmed: false) }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { phone: '5559876543' } } }

        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: { type: :string, format: :uuid },
                type: { type: :string },
                attributes: {
                  type: :object,
                  properties: {
                    name: { type: :string },
                    email: { type: :string },
                    phone: { type: :string, nullable: true },
                    email_confirmed: { type: :boolean },
                    phone_confirmed: { type: :boolean },
                    profile: { type: :object },
                    roles: {
                      type: :array,
                      items: { type: :string },
                      description: 'Array of role names assigned to the user'
                    },
                    created_at: { type: :string, format: 'date-time' },
                    updated_at: { type: :string, format: 'date-time' }
                  }
                }
              }
            }
          }

        example "application/json", :success, {
          data: {
            id: "550e8400-e29b-41d4-a716-446655440000",
            type: "user",
            attributes: {
              name: "John Doe",
              email: "john.doe@example.com",
              phone: "+15559876543",
              organization_id: "550e8400-e29b-41d4-a716-446655440000",
              email_confirmed: true,
              phone_confirmed: false,
              is_profile_complete: true,
              require_password_change: false,
              profile: {
                bio: "Software developer with 5 years experience",
                department: "Engineering",
                job_title: "Senior Software Developer",
                skills: [ "JavaScript", "Ruby", "React" ],
                location: "San Francisco, CA",
                hire_date: "2020-01-15"
              },
              roles: [ "user" ],
              created_at: "2024-01-01T00:00:00.000Z",
              updated_at: "2024-01-01T00:00:00.000Z"
            }
          }
        }

        before do
          allow(SmsService).to receive(:send_verification_code).and_return(true)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['phone']).to eq('+15559876543')
          expect(json['data']['attributes']['phone_confirmed']).to be false
        end
      end

      response '200', 'phone number updated with automatic verification code' do
        let(:user_record) { create(:user, phone: '5551234567', phone_confirmed: true) }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { phone: '5559876543' } } }

        before do
          allow(SmsService).to receive(:send_verification_code).and_return(true)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['phone']).to eq('+15559876543')
          expect(json['data']['attributes']['phone_confirmed']).to be false
          # Note: A verification code is automatically sent to the new phone number
        end
      end

      response '200', 'user updated' do
        let(:user_record) { create(:user, name: 'Old Name') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { name: 'New Name' } } }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('New Name')
        end
      end

      response '200', 'user profile updated with comprehensive data' do
        let(:user_record) { create(:user, name: 'John Doe', profile: { bio: 'Old bio' }) }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) {
          {
            user: {
              name: 'John Smith',
              profile: {
                bio: 'Experienced software developer with expertise in web technologies',
                department: 'Engineering',
                job_title: 'Senior Software Developer',
                skills: [ 'JavaScript', 'Ruby', 'React', 'Node.js' ],
                location: 'San Francisco, CA',
                hire_date: '2020-01-15',
                manager_email: 'manager@example.com',
                emergency_contact: {
                  name: 'Jane Smith',
                  phone: '+15551234567',
                  relationship: 'Spouse'
                }
              }
            }
          }
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('John Smith')

          profile = json['data']['attributes']['profile']
          expect(profile['bio']).to eq('Experienced software developer with expertise in web technologies')
          expect(profile['department']).to eq('Engineering')
          expect(profile['job_title']).to eq('Senior Software Developer')
          expect(profile['skills']).to eq([ 'JavaScript', 'Ruby', 'React', 'Node.js' ])
          expect(profile['location']).to eq('San Francisco, CA')
          expect(profile['hire_date']).to eq('2020-01-15')
          expect(profile['emergency_contact']['name']).to eq('Jane Smith')
        end
      end

      response '401', 'unauthorized' do
        let(:id) { 'invalid' }
        let(:Authorization) { 'invalid' }
        let(:user) { { user: { name: 'New Name' } } }
        run_test!
      end

      response '422', 'unprocessable entity' do
        let(:user_record) { create(:user, name: 'Old Name') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { name: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}/password' do
    patch 'Update a user password' do
      tags 'Users'
      security [ { bearer_auth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      description 'Updates user password. Requires current password verification for security. Password must be at least 6 characters long.'

      parameter name: :id, in: :path, type: :string, required: true, description: 'User ID'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              current_password: {
                type: :string,
                description: 'Current password for verification',
                example: 'currentpassword123'
              },
              password: {
                type: :string,
                description: 'New password (minimum 6 characters)',
                example: 'newpassword123'
              },
              password_confirmation: {
                type: :string,
                description: 'Confirmation of new password (must match password)',
                example: 'newpassword123'
              }
            },
            required: %w[current_password password password_confirmation]
          }
        }
      }

      response '200', 'password updated' do
        let(:user_record) { create(:user, password: 'oldpassword', password_confirmation: 'oldpassword') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { current_password: 'oldpassword', password: 'newpassword', password_confirmation: 'newpassword' } } }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Password updated successfully')
        end
      end

      response '422', 'invalid current password' do
        let(:user_record) { create(:user, password: 'oldpassword', password_confirmation: 'oldpassword') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { current_password: 'wrongpassword', password: 'newpassword', password_confirmation: 'newpassword' } } }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['errors']).to include('Current password is incorrect')
        end
      end

      response '422', "passwords do not match" do
        let(:user_record) { create(:user, password: 'oldpassword', password_confirmation: 'oldpassword') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { current_password: 'oldpassword', password: 'newpassword', password_confirmation: 'differentpassword' } } }
        run_test!
      end

      response '422', 'validation error' do
        let(:user_record) { create(:user, password: 'oldpassword', password_confirmation: 'oldpassword') }
        let(:id) { user_record.id }
        let(:Authorization) { "Bearer #{generate_jwt_token(user_record)}" }
        let(:user) { { user: { current_password: 'oldpassword', password: '', password_confirmation: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    delete 'Deletes a user' do
      tags 'Users'

      parameter name: :id, in: :path, type: :string, description: 'User ID (UUID)'

      response '204', 'user deleted' do
        let(:admin_user) { create(:user, :admin) }
        let(:user_to_delete) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt_token(admin_user)}" }
        let(:id) { user_to_delete.id }
        run_test!
      end

      response '403', 'forbidden' do
        let(:regular_user) { create(:user) }
        let(:user_to_delete) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt_token(regular_user)}" }
        let(:id) { user_to_delete.id }
        run_test!
      end

      response '404', 'user not found' do
        let(:admin_user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_token(admin_user)}" }
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
