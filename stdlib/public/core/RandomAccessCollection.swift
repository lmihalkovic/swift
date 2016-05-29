//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A collection that supports efficient random access index traversal.
///
/// - Important: In most cases, it's best to ignore this protocol and use
///   `RandomAccessCollection` instead, as it has a more complete interface.
public protocol RandomAccessIndexable : BidirectionalIndexable {
  // FIXME(ABI)(compiler limitation): there is no reason for this protocol
  // to exist apart from missing compiler features that we emulate with it.
  //
  // This protocol is almost an implementation detail of the standard
  // library.
}

/// A collection that supports efficient random access index traversal.
///
/// - Note: the fundamental difference between
///   `RandomAccessCollection` and `BidirectionalCollection` is that
///   the following are O(N) in `BidirectionalCollection` but O(1) in
///   `RandomAccessCollection`:
///
///   - `c.count`
///   - `c.index(i, offsetBy: n)`
///   - `c.index(i, offsetBy: n, limitedBy: l)`
///   - `c.distance(from: i, to: j)`
public protocol RandomAccessCollection :
  RandomAccessIndexable, BidirectionalCollection
{

  associatedtype SubSequence : RandomAccessIndexable, BidirectionalCollection
    = RandomAccessSlice<Self>
  // FIXME(compiler limitation):
  // associatedtype SubSequence : RandomAccessCollection

  associatedtype Indices : RandomAccessIndexable, BidirectionalCollection
    = DefaultRandomAccessIndices<Self>
  // FIXME(compiler limitation):
  // associatedtype Indices : RandomAccessCollection
}

/// Supply the default "slicing" `subscript` for `RandomAccessCollection`
/// models that accept the default associated `SubSequence`,
/// `RandomAccessSlice<Self>`.
extension RandomAccessCollection where SubSequence == RandomAccessSlice<Self> {
  public subscript(bounds: Range<Index>) -> RandomAccessSlice<Self> {
    _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
    return RandomAccessSlice(base: self, bounds: bounds)
  }
}

/// Default implementation for random access collections.
extension RandomAccessIndexable {
  /// Returns an index that is the specified distance from the given index,
  /// unless that distance is beyond a given limiting index.
  ///
  /// The following example obtains an index advanced four positions from an
  /// array's starting index and then prints the element at that position. The
  /// operation doesn't require going beyond the limiting `numbers.endIndex`
  /// value, so it succeeds.
  ///
  ///     let numbers = [10, 20, 30, 40, 50]
  ///     let i = numbers.index(numbers.startIndex, offsetBy: 4)
  ///     print(numbers[i])
  ///     // Prints "50"
  ///
  /// The next example attempts to retrieve an index ten positions from
  /// `numbers.startIndex`, but fails, because that distance is beyond the index
  /// passed as `limit`.
  ///
  ///     let j = numbers.index(numbers.startIndex,
  ///                           offsetBy: 10,
  ///                           limitedBy: numbers.endIndex)
  ///     print(j)
  ///     // Prints "nil"
  ///
  /// Advancing an index beyond a collection's ending index or offsetting it
  /// before a collection's starting index may trigger a runtime error. The
  /// value passed as `n` must not result in such an operation.
  ///
  /// - Parameters:
  ///   - i: A valid index of the array.
  ///   - n: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `n > 0`,
  ///     `limit` should be greater than `i` to have any effect. Likewise, if
  ///     `n < 0`, `limit` should be less than `i` to have any effect.
  /// - Returns: An index offset by `n` from the index `i`, unless that index
  ///   would be beyond `limit` in the direction of movement. In that case,
  ///   the method returns `nil`.
  ///
  /// - Complexity: O(1)
  public func index(
    _ i: Index, offsetBy n: IndexDistance, limitedBy limit: Index
  ) -> Index? {
    // FIXME: swift-3-indexing-model: tests.
    let l = distance(from: i, to: limit)
    if n > 0 ? l >= 0 && l < n : l <= 0 && n < l {
      return nil
    }
    return index(i, offsetBy: n)
  }
}

extension RandomAccessCollection
where Index : Strideable, 
      Index.Stride == IndexDistance,
      Indices == CountableRange<Index> {

  /// The indices that are valid for subscripting the collection, in ascending
  /// order.
  ///
  /// A collection's `indices` property can hold a strong reference to the
  /// collection itself, causing the collection to be non-uniquely referenced.
  /// If you mutate the collection while iterating over its indices, a strong
  /// reference can cause an unexpected copy of the collection. To avoid the
  /// unexpected copy, use the `index(after:)` method starting with
  /// `startIndex` to produce indices instead.
  ///
  ///     var c = MyFancyCollection([10, 20, 30, 40, 50])
  ///     var i = c.startIndex
  ///     while i != c.endIndex {
  ///         c[i] /= 5
  ///         i = c.index(after: i)
  ///     }
  ///     // c == MyFancyCollection([2, 4, 6, 8, 10])
  public var indices: CountableRange<Index> {
    return startIndex..<endIndex
  }

  internal func _validityChecked(_ i: Index) -> Index {
    _precondition(i >= startIndex && i <= endIndex, "index out of range")
    return i
  }
  
  /// Returns the position immediately after the given index.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be less than
  ///   `endIndex`.
  /// - Returns: The index value immediately after `i`.
  public func index(after i: Index) -> Index {
    return _validityChecked(i.advanced(by: 1))
  }

  /// Returns the position immediately after the given index.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be greater than
  ///   `startIndex`.
  /// - Returns: The index value immediately before `i`.
  public func index(before i: Index) -> Index {
    return _validityChecked(i.advanced(by: -1))
  }

  /// Returns an index that is the specified distance from the given index.
  ///
  /// The following example obtains an index advanced four positions from an
  /// array's starting index and then prints the element at that position.
  ///
  ///     let numbers = [10, 20, 30, 40, 50]
  ///     let i = numbers.index(numbers.startIndex, offsetBy: 4)
  ///     print(numbers[i])
  ///     // Prints "50"
  ///
  /// Advancing an index beyond a collection's ending index or offsetting it
  /// before a collection's starting index may trigger a runtime error. The
  /// value passed as `n` must not result in such an operation.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - n: The distance to offset `i`.
  /// - Returns: An index offset by `n` from the index `i`. If `n` is positive,
  ///   this is the same value as the result of `n` calls to `index(after:)`.
  ///   If `n` is negative, this is the same value as the result of `-n` calls
  ///   to `index(before:)`.
  ///
  /// - Precondition:
  ///   - If `n > 0`, `n <= self.distance(from: i, to: self.endIndex)`
  ///   - If `n < 0`, `n >= self.distance(from: i, to: self.startIndex)`
  /// - Complexity: O(1)
  public func index(_ i: Index, offsetBy n: Index.Stride) -> Index {
    return _validityChecked(i.advanced(by: n))
  }
  
  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If `end` is equal to
  ///     `start`, the result is zero.
  /// - Returns: The distance between `start` and `end`.
  ///
  /// - Complexity: O(1)
  public func distance(from start: Index, to end: Index) -> Index.Stride {
    return start.distance(to: end)
  }
}
