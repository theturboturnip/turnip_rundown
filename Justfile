set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

default:
    @just --list

# We don't use SQlite on the web anymore
# setup-web:
#     dart run sqflite_common_ffi_web:setup

# Always use the same port so that we keep the same cache
dbg-web:
    flutter run -d Chrome --web-port 50427

rel-web:
    flutter build web --release --source-maps

dbg-windows:
    flutter run -d Windows

dbg-android:
    flutter run -d RZ8

dbg-macos:
    flutter run -d macos

# doesn't run
# dbg-ipad:
#     flutter run -d mac-designed-for-ipad

rel-android:
    flutter run -d RZ8 --release

run-build-runner:
    dart run build_runner build