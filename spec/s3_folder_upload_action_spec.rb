describe Fastlane::Actions::S3FolderUploadAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The s3_folder_upload plugin is working!")

      Fastlane::Actions::S3FolderUploadAction.run(nil)
    end
  end
end
