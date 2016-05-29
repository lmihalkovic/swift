// RUN: not %swift -parse -target %target-triple %s -emit-fixits-path %t.remap
// RUN: c-arcmt-test %t.remap | arcmt-test -verify-transformed-files %s.result

class Base {}
class Derived : Base {}

var b : Base
b as Derived
b as Derived

b as! Base

var opti : Int?
// Add bang.
var i : Int = opti
// But remove unnecessary bang.
var i2 : Int = i!

struct MyMask : OptionSet {
  init(_ rawValue: UInt) {}
  init(rawValue: UInt) {}
  init(nilLiteral: ()) {}

  var rawValue: UInt { return 0 }

  static var allZeros: MyMask { return MyMask(0) }
  static var Bingo: MyMask { return MyMask(1) }
}

func supported() -> MyMask {
  return Int(MyMask.Bingo.rawValue)
}

struct MyEventMask2 : OptionSet {
  init(rawValue: UInt64) {}
  var rawValue: UInt64 { return 0 }
}
func sendIt(_: MyEventMask2) {}
func testMask1(a: Int) {
  sendIt(a)
}
func testMask2(a: UInt64) {
  sendIt(a)
}
func testMask3(a: MyEventMask2) {
  testMask1(a: a)
}
func testMask4(a: MyEventMask2) {
  testMask2(a: a)
}

func goo(var e : ErrorProtocol) {
}
func goo2(var e: ErrorProtocol) {}
func goo3(var e: Int) { e = 3 }
protocol A {
  func bar(var s: Int)
}
extension A {
  func bar(var s: Int) {
    s += 5
  }
}

func baz(var x: Int) {
  x += 10
}
func foo(let y: String, inout x: Int) {
  
}

struct Test1 : OptionSet {
  init(rawValue: Int) {}
  var rawValue: Int { return 0 }
}

print("", false)

func ftest1() {
  // Don't replace the variable name with '_'
  let myvar = 0
}

func ftest2(x x: Int -> Int) {}

protocol SomeProt {
  func protMeth(p: Int)
}
@objc protocol SomeObjCProt {
  func objcprotMeth(p: Int)
}
class Test2 : SomeProt, SomeObjCProt {
  func protMeth(_ p: Int) {}

  func instMeth(p: Int) {}
  func instMeth2(p: Int, p2: Int) {}
  func objcprotMeth(_ p: Int) {}
}
@objc class Test3 : SomeObjCProt {
  func objcprotMeth(_ p: Int) {}
}
class SubTest2 : Test2 {
  override func instMeth(_ p: Int) {}
}
Test2().instMeth(0)
Test2().instMeth2(0, p2:1)
