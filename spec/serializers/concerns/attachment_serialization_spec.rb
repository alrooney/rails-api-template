require 'rails_helper'

RSpec.describe AttachmentSerialization, type: :concern do
  # Create a test serializer that uses the concern
  let(:test_serializer_class) do
    Class.new do
      include JSONAPI::Serializer
      include AttachmentSerialization

      set_type :user

      def self.name
        'TestSerializer'
      end
    end
  end

  # Use User model for basic tests since it has avatar attachment
  let(:user) { create(:user) }
  let(:serializer) { test_serializer_class.new(user) }
  let(:serialized) { serializer.serializable_hash[:data][:attributes] }

  describe '.has_attachment' do
    context 'with default parameters' do
      before do
        test_serializer_class.has_attachment :avatar
      end

      context 'when no attachment is attached' do
        it 'returns nil for avatar_url' do
          expect(serialized[:avatar_url]).to be_nil
        end

        it 'returns nil for avatar_info' do
          expect(serialized[:avatar_info]).to be_nil
        end

        it 'returns nil for avatar_preview_url' do
          expect(serialized[:avatar_preview_url]).to be_nil
        end

        it 'returns nil for avatar_preview_info' do
          expect(serialized[:avatar_preview_info]).to be_nil
        end
      end

      context 'when an attachment is attached' do
        before do
          user.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
            filename: 'avatar.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'returns an avatar_url' do
          expect(serialized[:avatar_url]).to be_present
          expect(serialized[:avatar_url]).to include('rails/active_storage/blobs')
        end

        it 'returns avatar_info with correct details' do
          expect(serialized[:avatar_info]).to be_present
          expect(serialized[:avatar_info][:filename]).to eq('avatar.jpg')
          expect(serialized[:avatar_info][:content_type]).to eq('image/jpeg')
          expect(serialized[:avatar_info][:byte_size]).to be > 0
          expect(serialized[:avatar_info][:checksum]).to be_present
        end

        it 'returns avatar_preview_url from source image (fallback)' do
          expect(serialized[:avatar_preview_url]).to be_present
          expect(serialized[:avatar_preview_url]).to include('rails/active_storage/blobs')
        end

        it 'returns avatar_preview_info with source: original_image' do
          expect(serialized[:avatar_preview_info]).to be_present
          expect(serialized[:avatar_preview_info][:filename]).to eq('avatar.jpg')
          expect(serialized[:avatar_preview_info][:source]).to eq('original_image')
        end
      end
    end

    context 'with custom attachment_method' do
      before do
        test_serializer_class.has_attachment :document, attachment_method: :avatar
      end

      context 'when attachment is attached' do
        before do
          user.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
            filename: 'test.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'uses the custom attachment_method to get the attachment' do
          expect(serialized[:document_url]).to be_present
          expect(serialized[:document_info][:filename]).to eq('test.jpg')
        end
      end
    end

    context 'with preview_attachment set to :preview_image (backwards compatibility)' do
      before do
        # Dynamically add preview_image attachment to User for this test
        User.class_eval do
          has_one_attached :preview_image unless respond_to?(:preview_image)
        end

        test_serializer_class.has_attachment :avatar, preview_attachment: :preview_image
      end

      after do
        # Clean up the dynamically added attachment
        User.class_eval do
          if respond_to?(:preview_image)
            # Remove the association - this is a bit tricky, but we'll just leave it
            # as it won't affect other tests
          end
        end
      end

      context 'when preview_image is attached' do
        before do
          user.preview_image.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
            filename: 'preview_image.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'uses preview_image_url attribute name (not avatar_preview_url)' do
          expect(serialized[:preview_image_url]).to be_present
          expect(serialized[:preview_image_url]).to include('rails/active_storage/blobs')
          expect(serialized[:avatar_preview_url]).to be_nil
        end

        it 'uses preview_image_info attribute name (not avatar_preview_info)' do
          expect(serialized[:preview_image_info]).to be_present
          expect(serialized[:preview_image_info][:filename]).to eq('preview_image.jpg')
          expect(serialized[:preview_image_info][:source]).to eq('uploaded')
          expect(serialized[:avatar_preview_info]).to be_nil
        end
      end
    end

    context 'with custom preview_attachment parameter' do
      before do
        # Dynamically add avatar_preview attachment to User for this test
        User.class_eval do
          has_one_attached :avatar_preview unless respond_to?(:avatar_preview)
        end

        test_serializer_class.has_attachment :avatar, preview_attachment: :avatar_preview
      end

      context 'when preview attachment exists and is attached' do
        before do
          user.avatar_preview.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
            filename: 'preview.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'returns preview_url from preview attachment' do
          expect(serialized[:avatar_preview_url]).to be_present
          expect(serialized[:avatar_preview_url]).to include('rails/active_storage/blobs')
        end

        it 'returns preview_info from preview attachment with source: uploaded' do
          expect(serialized[:avatar_preview_info]).to be_present
          expect(serialized[:avatar_preview_info][:filename]).to eq('preview.jpg')
          expect(serialized[:avatar_preview_info][:source]).to eq('uploaded')
        end
      end

      context 'when preview attachment does not exist but source is an image' do
        before do
          user.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
            filename: 'image.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'falls back to source image for preview_url' do
          expect(serialized[:avatar_preview_url]).to be_present
          expect(serialized[:avatar_preview_url]).to include('rails/active_storage/blobs')
        end

        it 'falls back to source image for preview_info with source: original_image' do
          expect(serialized[:avatar_preview_info]).to be_present
          expect(serialized[:avatar_preview_info][:filename]).to eq('image.jpg')
          expect(serialized[:avatar_preview_info][:source]).to eq('original_image')
        end
      end
    end

    context 'when preview attachment method does not exist on model' do
      before do
        test_serializer_class.has_attachment :avatar, preview_attachment: :nonexistent_preview
      end

      context 'when source is an image' do
        before do
          user.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test_img.jpg')),
            filename: 'image.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'falls back to source image for preview' do
          expect(serialized[:avatar_preview_url]).to be_present
          expect(serialized[:avatar_preview_info][:source]).to eq('original_image')
        end
      end
    end

    context 'with previewable source file' do
      before do
        test_serializer_class.has_attachment :avatar
      end

      context 'when source is previewable but not an image' do
        before do
          # Attach a text file
          user.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test.txt')),
            filename: 'test.txt',
            content_type: 'text/plain'
          )

          # Mock the blob to be previewable and mock the preview object
          blob = user.avatar.blob
          allow(blob).to receive(:previewable?).and_return(true)
          allow(blob).to receive(:image?).and_return(false)

          # Mock the preview object with processed and url methods
          preview_object = double('preview')
          processed_preview = double('processed_preview')
          allow(processed_preview).to receive(:url).and_return('http://example.com/preview.jpg')
          allow(preview_object).to receive(:processed).and_return(processed_preview)
          # Use allow_any_instance_of to handle the keyword arguments properly
          allow_any_instance_of(ActiveStorage::Blob).to receive(:preview).and_return(preview_object)
        end

        it 'attempts to generate preview' do
          # This tests the previewable? branch
          expect(serialized[:avatar_preview_url]).to be_present
          expect(serialized[:avatar_preview_url]).to eq('http://example.com/preview.jpg')
        end
      end
    end

    context 'error handling' do
      before do
        test_serializer_class.has_attachment :avatar
      end

      context 'when preview generation fails' do
        before do
          user.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test.txt')),
            filename: 'test.txt',
            content_type: 'text/plain'
          )

          # Mock previewable? to return true but preview generation to fail
          blob = user.avatar.blob
          allow(blob).to receive(:previewable?).and_return(true)
          allow(blob).to receive(:image?).and_return(false)
          allow(blob).to receive(:preview).and_raise(ActiveStorage::UnpreviewableError.new('Preview failed'))
        end

        it 'handles preview errors gracefully and returns nil' do
          # The error is logged twice (once for preview_url, once for preview_info)
          expect(Rails.logger).to receive(:error).with(/Failed to generate preview/).at_least(:once)
          expect(serialized[:avatar_preview_url]).to be_nil
          expect(serialized[:avatar_preview_info]).to be_nil
        end
      end
    end
  end
end
