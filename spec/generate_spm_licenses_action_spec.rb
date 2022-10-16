describe Fastlane::Actions::GenerateSpmLicensesAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The generate_spm_licenses plugin is working!")

      Fastlane::Actions::GenerateSpmLicensesAction.run(nil)
    end
  end
end
