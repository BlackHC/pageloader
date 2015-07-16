// Copyright 2014 Google Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// PageLoader WebDriver provides the necessary bindings to support using
/// PageLoader in WebDriver-based tests.
library pageloader.async.webdriver;

import 'dart:async';

import 'package:webdriver/core.dart' as wd;

import 'src/core.dart';
import 'src/interfaces.dart';
export 'src/interfaces.dart';

class WebDriverPageLoader extends BasePageLoader {
  final wd.WebDriver driver;
  WebDriverPageLoaderElement _globalContext;
  var _mouse;
  @override
  _WebDriverMouse get mouse => _mouse;

  WebDriverPageLoader(wd.SearchContext globalContext, {bool useShadowDom: true,
      SyncedExecutionFn executeSyncedFn: noOpExecuteSyncedFn})
      : this.driver = globalContext.driver,
        super(useShadowDom: useShadowDom, executeSyncedFn: executeSyncedFn) {
    this._mouse = new _WebDriverMouse(this);
    this._globalContext = new WebDriverPageLoaderElement(globalContext, this);
  }

  @override
  WebDriverPageLoaderElement get globalContext => _globalContext;

  @override
  Future getInstance(Type type, [dynamic context]) async {
    if (context != null) {
      if (context is wd.SearchContext) {
        context = new WebDriverPageLoaderElement(context, this);
      } else if (context is! WebDriverPageLoaderElement) {
        throw new PageLoaderException('Invalid context: $context');
      }
    }
    return getInstanceInternal(type, context);
  }
}

class _WebDriverMouse implements PageLoaderMouse {
  final WebDriverPageLoader loader;
  wd.WebDriver get driver => loader.driver;

  _WebDriverMouse(this.loader);

  @override
  Future down(int button,
      {_WebElementPageLoaderElement eventTarget, bool sync: true}) => loader
      .executeSynced(() {
    if (eventTarget == null) {
      return driver.mouse.down(button);
    } else {
      return _fireEvent(eventTarget, 'mousedown', button);
    }
  }, sync);

  @override
  Future moveTo(_WebElementPageLoaderElement element, int xOffset, int yOffset,
      {bool sync: true}) => loader.executeSynced(() => driver.mouse.moveTo(
          element: element.context, xOffset: xOffset, yOffset: yOffset), sync);

  @override
  Future up(int button,
      {_WebElementPageLoaderElement eventTarget, bool sync: true}) => loader
      .executeSynced(() {
    if (eventTarget == null) {
      return driver.mouse.up(button);
    } else {
      return _fireEvent(eventTarget, 'mouseup', button);
    }
  }, sync);

  Future _fireEvent(
          _WebElementPageLoaderElement eventTarget, String type, int button) =>
      driver.execute("arguments[0].dispatchEvent(new MouseEvent(arguments[1], "
          "{'button' : arguments[2]}));", [eventTarget.context, type, button]);
}

abstract class WebDriverPageLoaderElement implements PageLoaderElement {
  wd.SearchContext get context;
  @override
  final WebDriverPageLoader loader;

  factory WebDriverPageLoaderElement(
      wd.SearchContext context, WebDriverPageLoader loader) {
    if (context is wd.WebDriver) {
      return new _WebDriverPageLoaderElement(context, loader);
    }
    if (context is wd.WebElement) {
      return new _WebElementPageLoaderElement(context, loader);
    }
    throw new PageLoaderException(
        'Unable to create PageLoaderElement for $context');
  }

  WebDriverPageLoaderElement._(this.loader);

  @override
  Stream<WebDriverPageLoaderElement> getElementsByCss(String selector) =>
      _fromContextStream(context.findElements(new wd.By.cssSelector(selector)));

  Stream<WebDriverPageLoaderElement> _fromContextStream(Stream contexts) =>
      contexts.map((e) => new WebDriverPageLoaderElement(e, loader));

  @override
  int get hashCode => context.hashCode;

  @override
  bool operator ==(Object other) => other != null &&
      other.runtimeType == runtimeType &&
      (other as WebDriverPageLoaderElement).context == context &&
      (other as WebDriverPageLoaderElement).loader == loader;

  @override
  String toString() => '$runtimeType<${context.toString()}>';

  @override
  PageLoaderAttributes get attributes => new _EmptyAttributes();

  @override
  Stream<String> get classes async* {}

  @override
  Future clear({bool sync: true}) async =>
      throw new PageLoaderException('$runtimeType.clear() is unsupported');

  @override
  Future click({bool sync: true}) async =>
      throw new PageLoaderException('$runtimeType.click() is unsupported');

  @override
  Future type(String keys, {bool sync: true}) async =>
      throw new PageLoaderException('$runtimeType.type() is unsupported');

  @override
  PageLoaderAttributes get computedStyle => new _EmptyAttributes();

  @override
  Future<PageLoaderElement> get shadowRoot =>
      throw new PageLoaderException('$runtimeType.shadowRoot() is unsupported');

  @override
  PageLoaderAttributes get style => new _EmptyAttributes();
}

class _WebElementPageLoaderElement extends WebDriverPageLoaderElement {
  final wd.WebElement context;
  final PageLoaderAttributes attributes;
  final PageLoaderAttributes computedStyle;
  final PageLoaderAttributes style;

  _WebElementPageLoaderElement(
      wd.WebElement _context, WebDriverPageLoader loader)
      : super._(loader),
        this.context = _context,
        this.attributes = new _ElementAttributes(_context),
        this.computedStyle = new _ElementComputedStyle(_context),
        this.style = new _ElementStyle(_context);

  @override
  Future<WebDriverPageLoaderElement> get shadowRoot async {
    if (loader.useShadowDom) {
      if ((await context.driver.execute(
          'return arguments[0].shadowRoot != null', [context]))) {
        return new _ShadowRootPageLoaderElement(context, loader);
      }
      throw new PageLoaderException('$this does not have a shadowRoot');
    }
    return this;
  }

  @override
  Future<String> get name => context.name;

  @override
  Future<String> get innerText async => (await context.driver.execute(
      'return arguments[0].textContent;', [context])).trim();

  @override
  Future<String> get visibleText => context.text;

  @override
  Future<bool> get displayed => context.displayed;

  @override
  Stream<String> get classes async* {
    String classAttr = await attributes['class'];
    if (classAttr != null && classAttr != '') {
      yield* new Stream.fromIterable(classAttr.split(' '));
    }
  }

  @override
  Future clear({bool sync: true}) => loader.executeSynced(context.clear, sync);

  @override
  Future click({bool sync: true}) => loader.executeSynced(context.click, sync);
  @override
  Future type(String keys, {bool sync: true}) =>
      loader.executeSynced(() => context.sendKeys(keys), sync);
}

class _WebDriverPageLoaderElement extends WebDriverPageLoaderElement {
  final wd.WebDriver context;

  _WebDriverPageLoaderElement(this.context, WebDriverPageLoader loader)
      : super._(loader);

  @override
  Future<String> get name async => '__document__';
  @override
  Future type(String keys, {bool sync: true}) =>
      loader.executeSynced(() => context.keyboard.sendKeys(keys), sync);
  @override
  Future<bool> get displayed async => true;

  @override
  Future<String> get innerText async =>
      (await context.execute('return arguments[0].textContent;', [await _root]))
          .trim();

  @override
  Future<String> get visibleText async => (await _root).text;

  Future<wd.WebElement> get _root =>
      context.findElement(const wd.By.cssSelector(':root'));
}

class _ShadowRootPageLoaderElement extends WebDriverPageLoaderElement {
  final wd.WebElement context;

  _ShadowRootPageLoaderElement(this.context, WebDriverPageLoader loader)
      : super._(loader) {
    assert(loader.useShadowDom);
  }

  @override
  Future<String> get name async => '__shadow_root__';

  @override
  Future<String> get visibleText => context.text;

  @override
  Future<String> get innerText async => (await _execute('.textContent')).trim();

  @override
  Future<bool> get displayed => context.displayed;

  @override
  Stream<PageLoaderElement> getElementsByCss(String selector) async* {
    yield* _fromContextStream(new Stream.fromIterable(
        await _execute('.querySelectorAll("$selector")')));
  }

  Future _execute(String script) {
    return context.driver.execute(
        'return arguments[0].shadowRoot$script;', [context]);
  }
}

class _ElementAttributes extends PageLoaderAttributes {
  final wd.WebElement _node;

  _ElementAttributes(this._node);

  @override
  Future<String> operator [](String name) => _node.attributes[name];
}

class _ElementComputedStyle extends PageLoaderAttributes {
  final wd.WebElement _node;

  _ElementComputedStyle(this._node);

  @override
  Future<String> operator [](String name) => _node.driver.execute(
      'return window.getComputedStyle(arguments[0]).${_cssPropName(name)}',
      [_node]);
}

class _ElementStyle extends PageLoaderAttributes {
  final wd.WebElement _node;

  _ElementStyle(this._node);

  @override
  Future<String> operator [](String name) => _node.driver.execute(
      'return arguments[0].style.${_cssPropName(name)}', [_node]);
}

/// Convert hyphenated-properties to camelCase.
String _cssPropName(String name) => name.splitMapJoin(new RegExp(r'-(\w)'),
    onMatch: (m) => m.group(1).toUpperCase(), onNonMatch: (m) => m);

class _EmptyAttributes extends PageLoaderAttributes {
  @override
  Future<String> operator [](String name) async => null;
}
