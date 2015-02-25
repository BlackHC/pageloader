/*
 * Copyright 2014 Google Inc. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
library pageloader.test.html_no_shadow_dom;

import 'page_objects.dart';
import 'pageloader_test.dart' as plt;

import 'package:pageloader/html.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:unittest/unittest.dart';

import 'dart:html' as html;

void main() {
  useHtmlEnhancedConfiguration();

  setUp(() {
    var body = html.document.getElementsByTagName('body').first;
    const bodyHtml = '''
        <style>
          .class1 { background-color: #00FF00; }
        </style>
        <table id='table1' non-standard='a non standard attr'
            class='class1 class2 class3' style='color: #800080;'>
          <tr>
            <td>r1c1</td>
            <td>r1c2</td>
          </tr>
          <tr>
            <td>r2c1</td>
            <td>r2c2</td>
          </tr>
        </table>
        <div id='div' style='display: none; background-color: red;'>
          some not displayed text</div>
        <div id='mouse'>area for mouse events</div>
        <input type='text' id='text' />
        <input type='text' readonly id='readonly' disabled />
        <input type='checkbox' class='with-class-test class1 class2' />
        <input type='radio' name='radio' value='radio1' />
        <input type='radio' name='radio' value='radio2' />
        <a href="test.html" id="anchor">test</a>
        <img src="test.png">
        <select id='select1'>
          <option id='option1' value='value 1'>option 1</option>
          <option id='option2' value='value 2'>option 2</option>
        </select>
        <textarea id='textarea'></textarea>
        <div class="outer-div">
          outer div 1
          <a-custom-tag><button id="inner">some </button></a-custom-tag>
        </div>
        <div class="outer-div">
          outer div 2
          <div class="inner-div">
            inner div 1
          </div>
          <div class="inner-div special">
            inner div 2
          </div>
        </div>
        <a-custom-tag id="button-1">
          <button id="inner">some button 1</button>
        </a-custom-tag>
        <a-custom-tag id="button-2">
          <button id="inner">some button 2</button>
        </a-custom-tag>
        <p id="nbsp">   &nbsp; &nbsp;   </p>''';

    var div = body.querySelectorAll('div[id=testdocument]');
    if (div.length == 1) {
      div = div[0];
    } else {
      div = new html.DivElement();
      div.id = 'testdocument';
      body.append(div);
    }
    div.setInnerHtml(bodyHtml, validator: new NoOpNodeValidator());

    var displayedDiv = html.document.getElementById('mouse');
    displayedDiv.onMouseDown.listen((evt) {
      displayedDiv.text = displayedDiv.text +
          " MouseDown: ${evt.client.x}, ${evt.client.y}; "
          "${evt.screen.x}, ${evt.screen.y}";
    });
    displayedDiv.onMouseUp.listen((evt) {
      displayedDiv.text = displayedDiv.text +
          " MouseUp: ${evt.client.x}, ${evt.client.y}; "
          "${evt.screen.x}, ${evt.screen.y}";
    });
    displayedDiv.onMouseMove.listen((evt) {
      displayedDiv.text = displayedDiv.text +
          " MouseMove: ${evt.client.x}, ${evt.client.y}; "
          "${evt.screen.x}, ${evt.screen.y}";
    });

    plt.loader = new HtmlPageLoader(div, useShadowDom: false);
  });

  group('html specific tests', () {
    test('value on text', () {
      var page = plt.loader.getInstance(PageForAttributesTests);
      var handlerCalled = false;
      var node = (page.text as HtmlPageLoaderElement).node as html.InputElement;
      node.onInput.listen((event) {
        handlerCalled = true;
      });
      expect(page.text.attributes['value'], '');
      page.text.type('some text');
      expect(page.text.attributes['value'], 'some text');
      expect(handlerCalled, isTrue);
    });

    test('keypress events', () {
      var data = 'my data';
      var list = [];
      html.document.body.onKeyPress.listen((evt) => list.add(evt.charCode));
      plt.loader.globalContext.type(data);
      expect(new String.fromCharCodes(list), equals(data));
    });
  });

  plt.runTests();
}

class NoOpNodeValidator implements html.NodeValidator {
  bool allowsAttribute(
      html.Element element, String attributeName, String value) => true;
  bool allowsElement(html.Element element) => true;
}
