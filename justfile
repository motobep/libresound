import? 'ignore/scripts.just'

[default]
_list:
  @just --list --unsorted

build_time := datetime('%Y_%m_%d–%H:%M')
is_demo := env('is_demo', '0')

[group('dev')]
run version='debug' platform=os():
    dart run ./bin/check_version.dart
    IS_GST_PLAYER_LOG=1 flutter run \
        --{{version}} \
        --dart-define=build_mode=dev \
        --dart-define=datetime={{build_time}} \
        --dart-define=is_demo={{is_demo}} \
        -d {{platform}}

[group('dev')]
build target:
    dart run ./bin/check_version.dart
    flutter build {{target}} \
        --dart-define=build_mode=prod \
        --dart-define=datetime={{build_time}}

# copy/zip+copy target
[group('dev')]
release target:
    dart run cmd.dart {{target}}_release

