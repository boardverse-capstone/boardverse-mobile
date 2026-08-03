import 'package:flutter/material.dart';

/// A drop-in replacement for [IndexedStack] that only builds the children it
/// has been asked to display at least once.
///
/// Flutter's [IndexedStack] mounts every child eagerly (each runs its
/// `initState` on the first frame), which is the root cause of our tab
/// pages firing their initial GET requests at app launch instead of when
/// the user actually navigates to them.
///
/// Behaviour:
/// - The child matching [index] is always built (if not already built).
/// - When the user taps a different tab, that child is also built the
///   first time the new index is selected.
/// - Once a child has been built, it stays alive in the tree (kept in
///   an internal [IndexedStack]) so subsequent tab switches are
///   instant and preserve state.
/// - Children that have never been selected are never instantiated,
///   so their `initState` never runs and their fetch logic is never
///   triggered.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.sizing = StackFit.loose,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
  });

  /// Currently visible child index.
  final int index;

  /// Children to lazy-build. Must not change at runtime in size or identity
  /// for already-built children.
  final List<Widget> children;

  final StackFit sizing;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _initializedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _markInitialized(widget.index);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      // Defensive: drop tracked indices that no longer exist.
      _initializedIndices.removeWhere((i) => i >= widget.children.length);
    }
    _markInitialized(widget.index);
  }

  void _markInitialized(int index) {
    if (index < 0 || index >= widget.children.length) return;
    if (_initializedIndices.add(index)) {
      // Trigger a rebuild so the newly-tracked child gets built.
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      sizing: widget.sizing,
      textDirection: widget.textDirection,
      children: List<Widget>.generate(widget.children.length, (i) {
        if (!_initializedIndices.contains(i)) {
          // Replace un-built children with an empty placeholder. The widget
          // is never instantiated, so its `initState` / `createState` /
          // fetch logic never runs.
          return const _LazyPlaceholder();
        }
        return widget.children[i];
      }),
    );
  }
}

/// Invisible widget that takes the same space as a built child, so the
/// surrounding layout (SafeArea, AppBar, etc.) keeps its size while the
/// child has not yet been initialised.
class _LazyPlaceholder extends StatelessWidget {
  const _LazyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
