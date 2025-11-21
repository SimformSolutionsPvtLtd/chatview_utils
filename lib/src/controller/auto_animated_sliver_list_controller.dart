import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import '../values/typedefs.dart';

class ItemState<T> {
  ItemState({
    required this.moveController,
    required this.item,
    required this.currentIndex,
    this.isMoving = false,
    this.isRemoving = false,
  });

  final AnimationController moveController;
  T item;
  int currentIndex;
  double? moveOffset;
  bool isMoving;
  bool isRemoving;
}

class AutoAnimateSliverListController<T> {
  AutoAnimateSliverListController({
    required List<T> items,
    required AutoAnimateItemExtractor<T> itemKeyExtractor,
    Duration animationDuration = const Duration(milliseconds: 400),
    bool enableMoveAnimation = true,
  })  : _enableMoveAnimation = enableMoveAnimation,
        _items = items,
        _itemKeyExtractor = itemKeyExtractor,
        _animationDuration = animationDuration;

  final AutoAnimateItemExtractor<T> _itemKeyExtractor;
  final Duration _animationDuration;
  final bool _enableMoveAnimation;

  List<T> _items = [];

  final _itemStates = <String, ItemState<T>>{};
  final _itemKeys = <String, GlobalKey>{};
  final _removingItems = <String>{};

  late var _currentItems = List<T>.from(_items);
  var _isNewItemAddedAtTop = false;
  var _newItemHeight = 0.0;
  var _isAddingItem = false;
  var _isRemovingItem = false;

  List<T> get items => _items;

  String getItemKey(T item) => _itemKeyExtractor(item);

  GlobalKey? getItemGlobalKey(String key) => _itemKeys[key];

  ItemState<T>? getState(String key) => _itemStates[key];

  List<T> get currentItems => _currentItems;

  bool get isAddedAtTop => _isNewItemAddedAtTop;

  double get itemHeight => _newItemHeight;

  final StreamController<void> _updateController =
      StreamController<void>.broadcast();

  Stream<void> get updateStream => _updateController.stream;

  TickerProvider? _tickerProvider;

  /// Adds a new chat item, considering pinned items at the top
  /// If there are pinned items, the new item will be added after
  /// them without animation If no pinned items, it will be added
  /// at top with animation
  void addItem(T newItem, {required bool Function(T item) isPinned}) {
    // Count pinned items at the top
    var pinnedCount = 0;

    final currentItemsLength = _currentItems.length;
    for (var i = 0; i < currentItemsLength; i++) {
      if (isPinned(_currentItems[i])) {
        pinnedCount++;
      } else {
        // Stop at first non-pinned item
        break;
      }
    }

    // If there are pinned items, add after them without animation
    // If no pinned items, add at top with animation
    final shouldAnimate = pinnedCount == 0;
    _onAddItem(newItem, position: pinnedCount, shouldAnimate: shouldAnimate);
  }

  /// Adds a new item with animation at the specified
  /// position (typically at top)
  void _onAddItem(T newItem, {int position = 0, bool shouldAnimate = true}) {
    _isAddingItem = true;

    final newItems = List<T>.from(_currentItems)..insert(position, newItem);

    final key = _itemKeyExtractor(newItem);

    // Only animate if adding at top AND shouldAnimate is true
    _isNewItemAddedAtTop = position == 0 && shouldAnimate;
    _newItemHeight = 0.0;

    // Only setup animation parameters if adding at top and should animate
    if (_isNewItemAddedAtTop && _currentItems.isNotEmpty) {
      // Estimate new item height based on existing items
      final firstOldKey = _itemKeyExtractor(_currentItems[0]);
      final renderBox =
          _itemKeys[firstOldKey]?.currentContext?.findRenderObject();
      if (renderBox is RenderBox && renderBox.hasSize) {
        _newItemHeight = renderBox.size.height;
      } else {
        _newItemHeight = 80.0;
      }
    }

    // Update the list immediately so new item is rendered
    _currentItems = newItems;

    final provider = _tickerProvider;
    if (provider == null) {
      Future.microtask(() => _isAddingItem = false);
      return;
    }

    // Create animation controller for new item
    final moveController = AnimationController(
      duration: _animationDuration,
      vsync: provider,
    );

    _addItemState(
      key: key,
      item: newItem,
      currentIndex: position,
      tickerProvider: provider,
      moveController: moveController,
    );

    // Update indices for existing items after the insertion point
    for (var i = position + 1; i < _currentItems.length; i++) {
      final itemKey = _itemKeyExtractor(_currentItems[i]);
      final itemState = _itemStates[itemKey];
      if (itemState != null) {
        itemState.currentIndex = i;
      }
    }

    _updateController.add(null);

    if (!_isNewItemAddedAtTop) {
      // No animation for items added at other positions or
      // when shouldAnimate is false
      moveController.value = 1;
    } else {
      // Animate new item at top
      moveController
        ..value = 0
        ..forward();

      // Animate all existing items down when new item added at top
      for (var i = position + 1; i < _currentItems.length; i++) {
        final itemKey = _itemKeyExtractor(_currentItems[i]);
        final itemState = _itemStates[itemKey];
        if (itemState != null) {
          itemState.moveController
            ..value = 0
            ..forward();
        }
      }
    }

    // Reset the flag after a brief delay to allow any pending widget updates
    Future.microtask(() => _isAddingItem = false);
  }

  /// Removes an item by its key with animation
  void removeItem(String key, {bool shouldAnimate = true}) {
    final item = _currentItems.cast<T?>().firstWhereOrNull(
          (item) => item != null && _itemKeyExtractor(item) == key,
        );
    if (item == null) return;

    _onRemoveItem(item, shouldAnimate: shouldAnimate);
  }

  /// Removes an item with a smooth animation
  /// The item will fade out, scale down, and slide up before being removed
  void _onRemoveItem(T item, {bool shouldAnimate = true}) {
    final key = _itemKeyExtractor(item);
    final itemState = _itemStates[key];

    if (itemState == null) {
      // Item doesn't exist, nothing to remove
      return;
    }

    final itemIndex = _currentItems.indexWhere(
      (i) => _itemKeyExtractor(i) == key,
    );
    if (itemIndex == -1) {
      return;
    }

    if (!shouldAnimate) {
      // Remove immediately without animation
      _currentItems.removeAt(itemIndex);
      final currentItemsLength = _currentItems.length;
      _cleanupRemovedItems(
        {
          for (var i = 0; i < currentItemsLength; i++)
            if (_currentItems[i] case final item) _itemKeyExtractor(item),
        },
      );
      _updateController.add(null);
      return;
    }

    _isRemovingItem = true;
    _removingItems.add(key);

    // Mark item as removing
    itemState.isRemoving = true;

    // Start removal animation
    itemState.moveController
      ..reset()
      ..forward().then((_) {
        // if (!mounted) return;

        // Remove the item from the list
        final newItems = List<T>.from(_currentItems)
          ..removeWhere((i) => _itemKeyExtractor(i) == key);
        _currentItems = newItems;

        // Update indices for remaining items
        final currentItemsLength = _currentItems.length;
        for (var i = 0; i < currentItemsLength; i++) {
          final itemKey = _itemKeyExtractor(_currentItems[i]);
          final state = _itemStates[itemKey];
          if (state != null) {
            state.currentIndex = i;
          }
        }

        // Cleanup the removed item
        _removingItems.remove(key);
        _itemStates[key]?.moveController.dispose();
        _itemStates.remove(key);
        _itemKeys.remove(key);

        // Reset the removing flag
        _isRemovingItem = _removingItems.isNotEmpty;

        _updateController.add(null);
      });

    _updateController.add(null);
  }

  void _addItemState({
    required String key,
    required T item,
    required int currentIndex,
    required TickerProvider tickerProvider,
    AnimationController? moveController,
  }) {
    final controller = moveController ??
        AnimationController(
          value: 1,
          duration: _animationDuration,
          vsync: tickerProvider,
        );

    _itemStates[key] = ItemState<T>(
      item: item,
      moveController: controller,
      currentIndex: currentIndex,
    );
    _itemKeys[key] = GlobalKey();
  }

  void _animateItemMove(
    String key,
    ItemState<T> itemState,
    int oldIndex,
    int newIndex, {
    required double itemHeight,
    VoidCallback? onAnimationEnd,
  }) {
    // Calculate how many positions this item moved
    final positionDiff = newIndex - oldIndex;
    final moveOffset = positionDiff * itemHeight;

    itemState
      ..moveOffset = moveOffset
      ..isMoving = true;

    // Two-phase animation: first go on top, then come back behind
    itemState.moveController
      ..reset()
      ..forward().then((_) {
        itemState
          ..isMoving = false
          ..moveOffset = null;
        onAnimationEnd?.call();
        _updateController.add(null);
      });
  }

  /// Do not use this method directly
  void updateItems(List<T> updatedItems) {
    _items = updatedItems;
    // Added ticket provider null check to avoid unnecessary updates
    // during animations or when calling updateItemsWithAnimation
    if (_tickerProvider == null && !listEquals(_items, _currentItems)) {
      _currentItems = List.from(_items);
    }
  }

  /// Do not use this method directly
  void updateItemsWithAnimation({
    required TickerProvider tickerProvider,
    required List<T> updatedItems,
    bool forceUpdate = false,
  }) {
    this._tickerProvider = tickerProvider;
    if (!forceUpdate && (_isAddingItem || _isRemovingItem)) return;

    final newItems = List<T>.from(_items);
    final newItemKeys = <String>{};

    // Create maps for old and new positions
    final oldPositions = <String, int>{};
    final newPositions = <String, int>{};
    final removedKeys = <String>[];

    // Map new positions
    var newItemsLength = newItems.length;
    for (var i = 0; i < newItemsLength; i++) {
      final key = _itemKeyExtractor(newItems[i]);
      newItemKeys.add(key);
      newPositions[key] = i;
    }

    // Map current positions
    final currentItemsLength = _currentItems.length;
    for (var i = 0; i < currentItemsLength; i++) {
      final key = _itemKeyExtractor(_currentItems[i]);
      oldPositions[key] = i;
      if (!newItemKeys.contains(key)) {
        removedKeys.add(key);
      }
    }

    if (removedKeys.isNotEmpty) {
      // If items are removed, update immediately without animating moves
      _currentItems = newItems;
      _cleanupRemovedItems(newItemKeys);
      _updateController.add(null);
      return;
    }

    // Capture current positions before any changes
    final renderBoxes = <String, RenderBox?>{};
    if (_enableMoveAnimation) {
      final entries = _itemKeys.entries.toList();
      final entriesLength = entries.length;
      for (var i = 0; i < entriesLength; i++) {
        final entry = entries[i];
        final renderObject = entry.value.currentContext?.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          renderBoxes[entry.key] = renderObject;
        }
      }
    }

    var needsReorder = false;

    // Process all items
    newItemsLength = newItems.length;
    for (var i = 0; i < newItemsLength; i++) {
      final key = _itemKeyExtractor(newItems[i]);
      final oldIndex = oldPositions[key];
      final newIndex = i;

      if (_itemStates.containsKey(key)) {
        final itemState = _itemStates[key]!;
        // Only animate if item actually moved and
        // not just shifted due to insertion
        if (oldIndex != null &&
                oldIndex != newIndex &&
                _enableMoveAnimation &&
                oldPositions.length == newItemsLength // No new item inserted
            ) {
          needsReorder = true;

          // Calculate the offset this item needs to move
          final renderBox = renderBoxes[key];
          // Default fallback
          var itemHeight = 80.0;

          if (renderBox != null && renderBox.hasSize) {
            itemHeight = renderBox.size.height;
          }

          // This item moved - calculate the offset and animate only this item
          _animateItemMove(
            key,
            itemState,
            oldIndex,
            newIndex,
            itemHeight: itemHeight,
            onAnimationEnd: () {
              _currentItems = List.from(newItems);
              // Apply reorder
              _updateController.add(null);
            },
          );
        }

        itemState
          ..item = newItems[i]
          ..currentIndex = i;
      } else {
        _addItemState(
          key: key,
          currentIndex: i,
          item: newItems[i],
          tickerProvider: this._tickerProvider ?? tickerProvider,
        );
        _updateController.add(null);
      }
    }

    // Clean up removed items
    _cleanupRemovedItems(newItemKeys);

    // If nothing moved, apply immediately
    if (!needsReorder) {
      _currentItems = newItems;
    }
  }

  void _cleanupRemovedItems(Set<String> newItemKeys) {
    final keysToRemove =
        _itemStates.keys.where((key) => !newItemKeys.contains(key)).toList();
    final keysToRemoveLength = keysToRemove.length;
    for (var i = 0; i < keysToRemoveLength; i++) {
      final key = keysToRemove[i];
      _itemStates[key]?.moveController.dispose();
      _itemStates.remove(key);
      _itemKeys.remove(key);
    }
  }

  void initialize({required TickerProvider tickerProvider}) {
    this._tickerProvider = tickerProvider;

    final currentItemsLength = _currentItems.length;
    for (var i = 0; i < currentItemsLength; i++) {
      final item = _currentItems[i];
      final key = _itemKeyExtractor(item);
      if (_itemStates.containsKey(key)) continue;

      _addItemState(
        key: key,
        currentIndex: i,
        item: item,
        tickerProvider: tickerProvider,
      );
    }
  }

  void dispose() {
    final values = _itemStates.values.toList();
    final valuesLength = values.length;
    for (var i = 0; i < valuesLength; i++) {
      values[i].moveController.dispose();
    }
  }

  /// Do not use this method directly
  /// Disposes all AnimationControllers and their tickers without disposing the controller itself.
  void disposeAnimations() {
    final values = _itemStates.values.toList();
    final valuesLength = values.length;
    for (var i = 0; i < valuesLength; i++) {
      final controller = values[i].moveController;
      controller
        ..stop()
        ..dispose();
    }
    // Clear the map to prevent reuse of disposed controllers
    _itemStates.clear();
    _itemKeys.clear();
    _removingItems.clear();
    _items.clear();
    _currentItems = List<T>.from(_items);
    _isNewItemAddedAtTop = false;
    _newItemHeight = 0.0;
    _isAddingItem = false;
    _isRemovingItem = false;
    _tickerProvider = null;
  }
}
