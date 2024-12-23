set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

default:
    @just --list

setup-web:
    dart run sqflite_common_ffi_web:setup

dbg-web:
    flutter run -d Chrome

dbg-windows:
    flutter run -d Windows

dbg-android:
    flutter run -d RZ8

rel-android:
    flutter run -d RZ8 --release

run-build-runner:
    dart run build_runner build