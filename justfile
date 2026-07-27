import? 'ignore/scripts.just'

[default]
_list:
  @just --list --unsorted

build_time := datetime('%Y_%m_%d–%H:%M')
is_disable_download_plugins := env('is_disable_download_plugins', '0')

[group('dev')]
run version='debug' platform=os():
    IS_LINUX_LOG=1 flutter run \
        --{{version}} \
        --dart-define=build_mode=dev \
        --dart-define=datetime={{build_time}} \
        --dart-define=is_disable_download_plugins={{is_disable_download_plugins}} \
        -d {{platform}}

[group('dev')]
build target:
    flutter build {{target}} \
        --dart-define=build_mode=prod \
        --dart-define=datetime={{build_time}} \
        --dart-define=is_disable_download_plugins={{is_disable_download_plugins}}

# copy/zip+copy target
[group('dev')]
release target:
    dart run cmd.dart {{target}}_release

