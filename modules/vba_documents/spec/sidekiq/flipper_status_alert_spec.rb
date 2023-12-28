# frozen_string_literal: true

require 'rails_helper'
require 'flipper/utilities/bulk_feature_checker'

describe VBADocuments::FlipperStatusAlert, type: :job do
  include FixtureHelpers

  before { Sidekiq::Job.clear_all }

  describe '#perform' do
    let(:messenger_instance) { instance_double(VBADocuments::Slack::Messenger) }
    let(:config_file_path) { VBADocuments::Engine.root.join('config', 'flipper', 'enabled_features.yml') }

    let(:warning_emoji) { described_class::WARNING_EMOJI }
    let(:traffic_light_emoji) { described_class::TRAFFIC_LIGHT_EMOJI }

    let(:missing_file_message) { "#{warning_emoji} #{described_class} features file does not exist." }
    let(:flag_message) { "#{warning_emoji} One or more features expected to be enabled were found to be disabled." }

    before do
      allow(VBADocuments::Slack::Messenger).to receive(:new).and_return(messenger_instance)
      allow(messenger_instance).to receive(:notify!)
    end

    it 'notifies Slack of missing config file when no config file found' do
      allow(File).to receive(:exist?).and_return(false)
      expected_notify = { warning: missing_file_message, file_path: config_file_path.to_s }
      expect(VBADocuments::Slack::Messenger).to receive(:new).with(expected_notify).and_return(messenger_instance)
      expect(messenger_instance).to receive(:notify!).once

      described_class.new.perform
    end

    it 'fetches enabled status of common and current env features when config file contains both' do
      allow(YAML).to receive(:load_file).and_return({ 'common' => %w[feature1], 'production' => %w[feature2] })
      bulk_checker_result = { enabled: [], disabled: %w[feature1 feature2] }
      expect(Flipper::Utilities::BulkFeatureChecker)
        .to receive(:enabled_status).with(%w[feature1 feature2]).and_return(bulk_checker_result)

      with_settings(Settings, vsp_environment: 'production') do
        described_class.new.perform
      end
    end

    it 'fetches enabled status of common features only when config file contains no current env features' do
      allow(YAML).to receive(:load_file).and_return({ 'common' => %w[feature1], 'development' => nil })
      bulk_checker_result = { enabled: [], disabled: %w[feature1] }
      expect(Flipper::Utilities::BulkFeatureChecker)
        .to receive(:enabled_status).with(%w[feature1]).and_return(bulk_checker_result)

      with_settings(Settings, vsp_environment: 'development') do
        described_class.new.perform
      end
    end

    it 'fetches enabled status of current env features only when config file contains no common features' do
      allow(YAML).to receive(:load_file).and_return({ 'common' => nil, 'staging' => %w[feature1] })
      bulk_checker_result = { enabled: [], disabled: %w[feature1] }
      expect(Flipper::Utilities::BulkFeatureChecker)
        .to receive(:enabled_status).with(%w[feature1]).and_return(bulk_checker_result)

      with_settings(Settings, vsp_environment: 'staging') do
        described_class.new.perform
      end
    end

    it 'does not notify Slack when all features are enabled' do
      allow(YAML).to receive(:load_file).and_return({ 'common' => %w[feature1 feature2] })
      bulk_checker_result = { enabled: %w[feature1 feature2], disabled: [] }
      allow(Flipper::Utilities::BulkFeatureChecker).to receive(:enabled_status).and_return(bulk_checker_result)
      expect(VBADocuments::Slack::Messenger).not_to receive(:new)

      described_class.new.perform
    end

    it 'notifies Slack when some features are disabled' do
      allow(YAML).to receive(:load_file).and_return({ 'common' => %w[feature1 feature2 feature3] })
      bulk_checker_result = { enabled: %w[feature1], disabled: %w[feature2 feature3] }
      allow(Flipper::Utilities::BulkFeatureChecker).to receive(:enabled_status).and_return(bulk_checker_result)
      expected_notify = {
        class: described_class.name,
        warning: flag_message,
        disabled_flags: "#{traffic_light_emoji} feature2, feature3 #{traffic_light_emoji}"
      }
      expect(VBADocuments::Slack::Messenger).to receive(:new).with(expected_notify).and_return(messenger_instance)
      expect(messenger_instance).to receive(:notify!).once

      described_class.new.perform
    end
  end
end
