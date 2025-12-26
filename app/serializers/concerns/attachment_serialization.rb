module AttachmentSerialization
  extend ActiveSupport::Concern

  module ClassMethods
    # Defines both {name}_url and {name}_info attributes for an attachment
    # @param name [Symbol] The name of the attachment (e.g., :file, :proof, :avatar)
    # @param attachment_method [Symbol] The method name on the record to get the attachment (defaults to name)
    # @param preview_attachment [Symbol] The method name for the preview attachment (defaults to :"{name}_preview")
    def has_attachment(name, attachment_method: name, preview_attachment: nil)
      preview_attachment ||= :"#{name}_preview"

      # For backwards compatibility: if preview_attachment is :preview_image, use preview_image_url/preview_image_info
      # Otherwise use {name}_preview_url/{name}_preview_info
      preview_url_name = (preview_attachment == :preview_image) ? :preview_image_url : :"#{name}_preview_url"
      preview_info_name = (preview_attachment == :preview_image) ? :preview_image_info : :"#{name}_preview_info"

      attribute "#{name}_url".to_sym do |record|
        attachment = record.send(attachment_method)
        attachment.attached? ? Rails.application.routes.url_helpers.rails_blob_url(attachment) : nil
      end

      attribute "#{name}_info".to_sym do |record|
        attachment = record.send(attachment_method)
        if attachment.attached?
          {
            filename: attachment.filename.to_s,
            content_type: attachment.content_type,
            byte_size: attachment.byte_size,
            checksum: attachment.blob.checksum
          }
        end
      end

      # Add preview URL attribute with fallback logic
      attribute preview_url_name do |record|
        # Check if preview attachment method exists on the model
        preview = record.respond_to?(preview_attachment) ? record.send(preview_attachment) : nil
        source = record.send(attachment_method)

        if preview&.attached?
          Rails.application.routes.url_helpers.rails_blob_url(preview)
        elsif source.attached? && source.image?
          Rails.application.routes.url_helpers.rails_blob_url(source)
        elsif source.attached? && source.previewable?
          begin
            source.preview(resize_to_limit: [ 300, 300 ]).processed.url
          rescue ActiveStorage::UnpreviewableError => e
            Rails.logger.error "Failed to generate preview for #{record.class.name} #{record.id}: #{e.message}"
            nil
          end
        else
          nil
        end
      end

      # Add preview info attribute with metadata
      attribute preview_info_name do |record|
        # Check if preview attachment method exists on the model
        preview = record.respond_to?(preview_attachment) ? record.send(preview_attachment) : nil
        source = record.send(attachment_method)

        if preview&.attached?
          {
            filename: preview.filename.to_s,
            content_type: preview.content_type,
            byte_size: preview.byte_size,
            checksum: preview.blob.checksum,
            source: "uploaded"
          }
        elsif source.attached? && source.image?
          {
            filename: source.filename.to_s,
            content_type: source.content_type,
            byte_size: source.byte_size,
            checksum: source.blob.checksum,
            source: "original_image"
          }
        elsif source.attached? && source.previewable?
          begin
            # Try to generate preview to check if it's actually possible
            source.preview(resize_to_limit: [ 300, 300 ])
            {
              filename: "#{source.filename.base}.jpg",
              content_type: "image/jpeg",
              byte_size: nil, # Size not available for generated previews
              checksum: "#{source.blob.checksum}_preview", # Suffix distinguishes from original file checksum
              source: "generated_preview"
            }
          rescue ActiveStorage::UnpreviewableError => e
            Rails.logger.error "Failed to generate preview for #{record.class.name} #{record.id}: #{e.message}"
            nil
          end
        else
          nil
        end
      end
    end
  end
end
