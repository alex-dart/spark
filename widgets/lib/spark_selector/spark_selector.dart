// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark_widgets.selector;

import 'dart:html';

import 'package:polymer/polymer.dart';

import 'package:spark_widgets/common/spark_widget.dart';
import 'package:spark_widgets/spark_selection/spark_selection.dart';

// Ported from Polymer Javascript to Dart code.

/**
 * Sets and tracks selected element(s) in a list.
 *
 * Default is to use the index of the item element.
 *
 * If you want a specific attribute value of the element to be
 * used instead of index, set "valueattr" to that attribute name.
 *
 * Example:
 *
 *     <polymer-selector valueattr="label" selected="foo">
 *       <div label="foo"></div>
 *       <div label="bar"></div>
 *       <div label="zot"></div>
 *     </polymer-selector>
 *
 * In multi-selection this should be an array of values.
 *
 * Example:
 *
 *     <polymer-selector id="selector" valueattr="label" multi>
 *       <div label="foo"></div>
 *       <div label="bar"></div>
 *       <div label="zot"></div>
 *     </polymer-selector>
 *
 *     ($['selector'] as SparkSelector).selected = ['foo', 'zot'];
 */
@CustomTag("spark-selector")
class SparkSelector extends SparkSelection {
  /// The initially selected elements. This can be any of the following:
  /// 1)...
  /// [selected] can also be used after the initial instantiation to force a
  /// particular selection.
  @published dynamic selected;

  /// If true, multiple selections are allowed.
  @published bool multi = false;

  /// The attribute to be used as an item's "value".
  @published String valueattr = 'name';

  /// The CSS selector to choose the selectable subset of elements passed from
  /// the light DOM into the <content> insertion point.
  @published String selectableFilter;

  /// The CSS class to add to the selected element.
  @published String selectedClass = '';
  /// The attribute to set on the selected element.
  @published String selectedProperty = '';


  // TODO(terry): Should be tap when PointerEvents are supported.
  @published String activateEvent = 'click';

  List<Element> _items;
  SparkSelection _selection;

  SparkSelector.created() : super.created();

  @override
  void enteredView() {
    super.enteredView();

    _items = SparkWidget.expandCascadingContentNodes($['items']);
//    _items = ($['items'] as ContentElement).getDistributedNodes();
    if (selectableFilter != null) {
      _items.removeWhere((Element e) => !e.matches(selectableFilter));
    }

    _selection = $['selection'] as SparkSelection;

    addEventListener(activateEvent, onActivate);

    selectedChanged();
  }

  void selectedChanged() {
    if (multi) {
      _selection.clear();
      for (var s in selected) {
        _updateSelection(s);
      }
    } else {
      _updateSelection(selected);
    }
  }

  void clearSelection() {
    selected = null;
  }

  void _updateSelection(var value) {
    final index = _valueToIndex(value);
    if (index >= 0) {
      // [_selection] will fire 1 or 2 [onSelectSelected] calls in response
      // to this. 1 call will be fired either when [multi] is on, corresponding
      // to the just-toggled item, or when [multi] is off and the previously
      // selected single item has just got unselected; 2 calls will be fired
      // when [multi] is off and the just-selected item is different from the
      // previous one (1st call for the unselected, 2nd call for the selected).
      _selection.select(_items[index]);
    }
  }

  int _valueToIndex(var value) {
    // Find an item with value == value and return it's index:
    for (var i = 0; i < _items.length; i++) {
      if (_valueForNode(_items[i]) == value) {
        return i;
      }
    }
    // If no item found, the value itself is probably the index:
    return (value is num) ? value : (value is String) ? int.parse(value) : -1;
  }

  String _valueForNode(Element node) =>
      node.attributes.containsKey(valueattr) ? node.attributes[valueattr] : null;

  // Events fired from <polymer-selection> object.
  void onSelectionSelect(e, detail) {
    _renderSelection(detail['item'], detail['isSelected']);
    asyncFire('activate', detail: detail, canBubble: true);
  }

  void _renderSelection(Element item, bool isSelected) {
    if (selectedClass.isNotEmpty) {
      item.classes.toggle(selectedClass, isSelected);
    }
    if (selectedProperty.isNotEmpty) {
      if (isSelected) {
        item.attributes[selectedProperty] = '';
      } else {
        item.attributes.remove(selectedProperty);
      }
    }
  }

  // Event fired from host.
  void onActivate(Event e) {
    var i = _items.indexOf(e.target);
    if (i >= 0) {
      final String value = _valueForNode(_items[i]);
      // By name or by id.
      final s = value != null ? value : i;
      _addRemoveSelected(s);
    }
  }

  void _addRemoveSelected(value) {
    // All changes to [selected] below will trigger [selectedChanged()].
    if (multi) {
      if (selected == null) {
        selected = [value];
      } else {
        final int i = selected.indexOf(value);
        if (i >= 0) {
          selected.remove(i);
        } else {
          selected.add(value);
        }
      }
    } else {
      selected = value;
    }
  }
}
