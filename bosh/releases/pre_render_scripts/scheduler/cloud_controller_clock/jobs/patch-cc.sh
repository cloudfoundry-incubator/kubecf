#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_clock/templates/bin/cloud_controller_clock.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -2,4 +2,6 @@

 source /var/vcap/jobs/cloud_controller_clock/bin/ruby_version.sh
 cd /var/vcap/packages/cloud_controller_ng/cloud_controller_ng
+patch -p0 < /var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/yaml-anchor.patch
+
 exec bundle exec rake clock:start
EOT

sha256sum "${target}" > "${sentinel}"

cat <<'EOT' > /var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/yaml-anchor.patch
diff --git app/controllers/v3/app_manifests_controller.rb app/controllers/v3/app_manifests_controller.rb
index ed3ca78a6..9828cd7ed 100644
--- app/controllers/v3/app_manifests_controller.rb
+++ app/controllers/v3/app_manifests_controller.rb
@@ -70,7 +70,7 @@ class AppManifestsController < ApplicationController
   def validate_content_type!
     if !request_content_type_is_yaml?
       logger.error("Context-type isn't yaml: #{request.content_type}")
-      invalid_request!('Content-Type must be yaml')
+      bad_request!('Content-Type must be yaml')
     end
   end

@@ -79,10 +79,10 @@ class AppManifestsController < ApplicationController
   end

   def parsed_app_manifest_params
-    parsed_application = params[:body]['applications'] && params[:body]['applications'].first
+    parsed_application = parsed_yaml['applications'] && parsed_yaml['applications'].first

-    raise invalid_request!('Invalid app manifest') unless parsed_application.present?
+    raise bad_request!('Invalid app manifest') unless parsed_application.present?

-    parsed_application.to_unsafe_h
+    parsed_application
   end
 end
diff --git app/controllers/v3/application_controller.rb app/controllers/v3/application_controller.rb
index 8221b866d..1a7e57757 100644
--- app/controllers/v3/application_controller.rb
+++ app/controllers/v3/application_controller.rb
@@ -30,6 +30,10 @@ module V3ErrorsHelper
     raise CloudController::Errors::ApiError.new_from_details('BadRequest', message)
   end

+  def message_parse_error!(message)
+    raise CloudController::Errors::ApiError.new_from_details('MessageParseError', message)
+  end
+
   def service_unavailable!(message)
     raise CloudController::Errors::ApiError.new_from_details('ServiceUnavailable', message)
   end
@@ -80,6 +84,17 @@ class ApplicationController < ActionController::Base
     JSON.parse(request.body.string)
   end

+  def parsed_yaml
+    return @parsed_yaml if @parsed_yaml
+
+    allow_yaml_aliases = false
+    yaml = YAML.safe_load(request.body.string, [], [], allow_yaml_aliases)
+    message_parse_error!('invalid request body') if !yaml.is_a? Hash
+    @parsed_yaml = yaml
+  rescue Psych::BadAlias
+    bad_request!('Manifest does not support Anchors and Aliases')
+  end
+
   def roles
     VCAP::CloudController::SecurityContext.roles
   end
diff --git app/controllers/v3/space_manifests_controller.rb app/controllers/v3/space_manifests_controller.rb
index 3f9f0db48..b213925bb 100644
--- app/controllers/v3/space_manifests_controller.rb
+++ app/controllers/v3/space_manifests_controller.rb
@@ -15,7 +15,7 @@ class SpaceManifestsController < ApplicationController
     space_not_found! unless space && permission_queryer.can_read_from_space?(space.guid, space.organization.guid)
     unauthorized! unless permission_queryer.can_write_to_space?(space.guid)

-    messages = parsed_app_manifests.map(&:to_unsafe_h).map { |app_manifest| NamedAppManifestMessage.create_from_yml(app_manifest) }
+    messages = parsed_app_manifests.map { |app_manifest| NamedAppManifestMessage.create_from_yml(app_manifest) }
     errors = messages.each_with_index.flat_map { |message, i| errors_for_message(message, i) }
     compound_error!(errors) unless errors.empty?

@@ -49,6 +49,10 @@ class SpaceManifestsController < ApplicationController

     parsed_manifests = parsed_app_manifests.map(&:to_hash)

+    messages = parsed_app_manifests.map { |app_manifest| NamedAppManifestMessage.create_from_yml(app_manifest) }
+    errors = messages.each_with_index.flat_map { |message, i| errors_for_message(message, i) }
+    compound_error!(errors) unless errors.empty?
+
     diff = SpaceDiffManifest.generate_diff(parsed_manifests, space)

     render status: :created, json: { diff: diff }
@@ -79,7 +83,7 @@ class SpaceManifestsController < ApplicationController
   def validate_content_type!
     if !request_content_type_is_yaml?
       logger.error("Content-type isn't yaml: #{request.content_type}")
-      invalid_request!('Content-Type must be yaml')
+      bad_request!('Content-Type must be yaml')
     end
   end

@@ -88,13 +92,13 @@ class SpaceManifestsController < ApplicationController
   end

   def check_version_is_supported!
-    version = params[:body]['version']
+    version = parsed_yaml['version']
     raise unprocessable!('Unsupported manifest schema version. Currently supported versions: [1].') unless !version || version == 1
   end

   def parsed_app_manifests
     check_version_is_supported!
-    parsed_applications = params[:body].permit!['applications']
+    parsed_applications = parsed_yaml['applications']
     raise unprocessable!("Cannot parse manifest with no 'applications' field.") unless parsed_applications.present?

     parsed_applications
diff --git config/application.rb config/application.rb
index a86039f69..d75394bf7 100644
--- config/application.rb
+++ config/application.rb
@@ -2,18 +2,6 @@ require 'action_controller/railtie'

 class Application < ::Rails::Application
   config.exceptions_app = self.routes
-
-  # For Rails 5 / Rack 2 - this is how to add a new parser
-  original_parsers = ActionDispatch::Request.parameter_parsers
-
-  allow_yaml_aliases = true
-  yaml_parser = lambda { |body| YAML.safe_load(body, [], [], allow_yaml_aliases).with_indifferent_access }
-  new_parsers = original_parsers.merge({
-    Mime::Type.lookup('application/x-yaml') => yaml_parser,
-    Mime::Type.lookup('text/yaml') => yaml_parser,
-  })
-  ActionDispatch::Request.parameter_parsers = new_parsers
-
   config.middleware.delete ActionDispatch::Session::CookieStore
   config.middleware.delete ActionDispatch::Cookies
   config.middleware.delete ActionDispatch::Flash
EOT
