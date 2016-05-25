// RUN: %target-swift-ide-test(mock-sdk: %clang-importer-sdk) -I %t -I %S/Inputs/custom-modules -enable-swift-newtype -print-module -source-filename %s -module-to-print=Newtype > %t.printed.A.txt
// RUN: FileCheck %s -check-prefix=PRINT -strict-whitespace < %t.printed.A.txt
// REQUIRES: objc_interop

// PRINT-LABEL: struct ErrorDomain : RawRepresentable {
// PRINT-NEXT:    init(rawValue: String)
// PRINT-NEXT:    var _rawValue: NSString
// PRINT-NEXT:    var rawValue: String { get }
// PRINT-NEXT:  }
// PRINT-NEXT:  extension ErrorDomain {
// PRINT-NEXT:    func process()
// PRINT-NEXT:    static let one: ErrorDomain
// PRINT-NEXT:    static let errTwo: ErrorDomain
// PRINT-NEXT:    static let three: ErrorDomain
// PRINT-NEXT:    static let fourErrorDomain: ErrorDomain
// PRINT-NEXT:    static let stillAMember: ErrorDomain
// PRINT-NEXT:  }
// PRINT-NEXT:  struct Foo {
// PRINT-NEXT:    init()
// PRINT-NEXT:  }
// PRINT-NEXT:  extension Foo {
// PRINT-NEXT:    static let err: ErrorDomain
// PRINT-NEXT:  }
// PRINT-NEXT:  struct ClosedEnum : RawRepresentable {
// PRINT-NEXT:    init(rawValue: String?)
// PRINT-NEXT:    var _rawValue: NSString?
// PRINT-NEXT:    var rawValue: String? { get }
// PRINT-NEXT:  }
// PRINT-NEXT:  extension ClosedEnum {
// PRINT-NEXT:    static let firstClosedEntryEnum: ClosedEnum
// PRINT-NEXT:    static let secondEntry: ClosedEnum
// PRINT-NEXT:    static let thirdEntry: ClosedEnum
// PRINT-NEXT:  }
// PRINT-NEXT:  struct IUONewtype : RawRepresentable {
// PRINT-NEXT:    init(rawValue: String?)
// PRINT-NEXT:    var _rawValue: NSString?
// PRINT-NEXT:    var rawValue: String? { get }
// PRINT-NEXT:  }
// PRINT-NEXT:  struct MyFloat : RawRepresentable {
// PRINT-NEXT:    init(rawValue: Float)
// PRINT-NEXT:    let rawValue: Float
// PRINT-NEXT:  }
// PRINT-NEXT:  extension MyFloat {
// PRINT-NEXT:    static let globalFloat: MyFloat
// PRINT-NEXT:  }

// RUN: %target-parse-verify-swift -I %S/Inputs/custom-modules -enable-swift-newtype
import Newtype

func tests() {
	let errOne = ErrorDomain.one
	errOne.process()

	let fooErr = Foo.err
	fooErr.process()
	Foo().process() // expected-error{{value of type 'Foo' has no member 'process'}}

	let thirdEnum = ClosedEnum.thirdEntry
	thirdEnum.process()
	  // expected-error@-1{{value of type 'ClosedEnum' has no member 'process'}}

	let _ = ErrorDomain(rawValue: thirdEnum.rawValue!)
	let _ = ClosedEnum(rawValue: errOne.rawValue)

}
