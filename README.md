PageLoader
==========

[![Build Status](https://travis-ci.org/google/pageloader.svg?branch=master)](https://travis-ci.org/google/pageloader)
[![pub package](https://img.shields.io/pub/v/pageloader.svg)](https://pub.dartlang.org/packages/pageloader)

A framework for creating page objects for in-browser tests or
tests using https://github.com/google/dart-sync-webdriver.

When using with WebDriver, you must build the native extension for
https://github.com/google/dart-sync-socket
This can be done by running the following after running pub get or upgrade:
```
  # ./packages/sync_socket/../tool/build.sh
```
