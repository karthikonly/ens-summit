class ConfigurationController < ApplicationController

  skip_before_action :verify_authenticity_token

  def get
    config = JSON.parse(File.read("#{Rails.root.to_s}/config.json"))
    serial_number = params[:serial_number]
    activation = Activation.or({'provisioned.accb': serial_number}, {'discovered.accb': serial_number}).first
    unless activation
      activation = Activation.new
      activation.discovered = {}
      activation.discovered['accb'] = [serial_number]
      activation.save!
    end
    comm_settings = config['comm_settings']
    comm_settings['site_id'] = activation.siteid
    comm_settings['mqtt_command_stream'] = "gateways/command-stream/#{serial_number}"
    comm_settings['mqtt_response_stream'] = "gateways/response-stream/#{serial_number}"
    comm_settings['mqtt_live_stream'] = "gateways/live-stream/#{serial_number}"
    comm_settings['mqtt_ca_cert'] = File.read("#{Rails.root.to_s}/public/verisign-root-ca.pem")
    comm_settings['mqtt_client_cert'] = File.read("#{Rails.root.to_s}/public/0001-cert.pem")
    comm_settings['mqtt_private_key'] = File.read("#{Rails.root.to_s}/public/0001-private.key")
    activation.provisioned.each do |type, list|
      config['devices'][type] ||= {}
      list.each do |serial|
        config['devices'][type][serial] = { admin_state: "Provisioned"}
      end
    end
    render json: config
  end
end
