# ShipItWidget（WidgetKit拡張）ターゲットを Runner.xcodeproj に追加する。
# CocoaPods 同梱の xcodeproj gem を使う（Xcode GUI 不要）。
# 冪等：既にターゲットがあれば何もしない。
#
# 実行: ruby tools/add_widget_target.rb
require 'xcodeproj'

PROJ_PATH = File.expand_path('../ios/Runner.xcodeproj', __dir__)
proj = Xcodeproj::Project.open(PROJ_PATH)

if proj.targets.any? { |t| t.name == 'ShipItWidget' }
  puts 'ShipItWidget target already exists — nothing to do'
  exit 0
end

runner = proj.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner

# --- 1) 拡張ターゲットを作成（iOS 16.0〜。アプリ本体は 13.0 のままで問題ない） ---
widget = proj.new_target(:app_extension, 'ShipItWidget', :ios, '16.0')

# --- 2) ソースとグループ ---
group = proj.main_group.new_group('ShipItWidget', 'ShipItWidget')
swift_ref = group.new_file('ShipItWidget.swift')
group.new_file('Info.plist')
group.new_file('ShipItWidget.entitlements')
widget.add_file_references([swift_ref])

# --- 3) ビルド設定 ---
# バージョンは Flutter の Generated.xcconfig（FLUTTER_BUILD_NAME/NUMBER）から
# 取るため、拡張のベース構成にも Generated.xcconfig を割り当てる
# （アプリとウィジェットのバージョン不一致を防ぐ）。
generated_ref = proj.files.find { |f| f.path&.end_with?('Generated.xcconfig') }

widget.build_configurations.each do |c|
  c.base_configuration_reference = generated_ref if generated_ref
  bs = c.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'jp.co.shipitenglish.app.widget'
  bs['INFOPLIST_FILE'] = 'ShipItWidget/Info.plist'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['CODE_SIGN_ENTITLEMENTS'] = 'ShipItWidget/ShipItWidget.entitlements'
  bs['SWIFT_VERSION'] = '5.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  bs['DEVELOPMENT_TEAM'] = 'XX24WCN326'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['SKIP_INSTALL'] = 'YES'
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end

# --- 4) Runner に依存関係と「Embed App Extensions」フェーズを追加 ---
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(widget.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# --- 5) Runner 本体にも App Group entitlements を割り当てる ---
runner_ent = proj.main_group.find_subpath('Runner', false)&.new_file('Runner.entitlements')
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

proj.save
puts 'ShipItWidget target added OK'
