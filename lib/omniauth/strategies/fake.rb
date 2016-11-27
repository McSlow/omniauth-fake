require 'omniauth'
require 'yaml'

module OmniAuth
  module Strategies
    class Fake
      include OmniAuth::Strategy

      option :dotfiles, [File.join(ENV['HOME'], '.omniauth-fake')]

      def request_phase
        load_identities

        f = OmniAuth::Form.new(:title => "Identity Selection", :url => callback_path, :method => 'get' )
        f.html %Q{\n<select id="identity" name="uid"/>}
        @@identities.each do |uid,data|
          f.html %Q{\n<option value="#{uid}">#{uid} - #{data['info']['name']}</option>}
        end
        f.html %Q{</select>}
        f.button "Sign In"
        f.to_response
      end

      def callback_phase
        return fail!(:missing_credentials) if request['uid'].nil? || request['uid'].empty?
        return fail!(:invalid_credentials) if @@identities[request['uid']].nil?
        @identity = @@identities[request['uid']]
        super
      end

      uid { @identity['uid'] }
      info { @identity['info'] }
      credentials { @identity['credentials'] || {} }
      extra {
        { :raw_info => @identity['raw_info'] }
      }

      private

      def load_identities
        @@identities = {}
        [@options[:dotfiles]].flatten.each do |file|
          YAML.load(open(file).read).each do |uid,attributes|
            @@identities[uid] = {
              'uid' => uid,
              'info' => {},
              'raw_info'  => {
                'uid' => uid
              }
            }
            attributes.each do |k,v|
              case k
              when 'raw_info'
                @@identities[uid]['raw_info'].merge!(v)
              when 'credentials'
                @@identities[uid]['credentials'] = v
                @@identities[uid]['raw_info'][k] = v
              else
                @@identities[uid]['info'][k] = v
              end
            end
            @@identities[uid]['raw_info'].merge!(@@identities[uid]['info'])
          end
        end
      end # load identities

    end
  end
end
