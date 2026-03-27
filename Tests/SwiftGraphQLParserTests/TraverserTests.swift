import XCTest
@testable import SwiftGraphQLParser

class TraverserTests: XCTestCase {
	func testSubscriptionRootDoesNotGetTypename() throws {
		let query = """
		subscription TestSub {
			someField
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let traverser = GraphQLTraverser(document: document, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["someField"], "Subscription root should not have __typename injected")
	}

	func testQueryRootGetsTypename() throws {
		let query = """
		query TestQuery {
			someField
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let traverser = GraphQLTraverser(document: document, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["__typename", "someField"], "Query root should have __typename injected")
	}

	func testSubscriptionInlineFragmentDoesNotGetTypename() throws {
		let query = """
		subscription TestSub {
			... on Subscription {
				someField
			}
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let traverser = GraphQLTraverser(document: document, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["someField"], "Inline fragment at subscription root should not have __typename injected")
	}

	func testQueryInlineFragmentGetsTypename() throws {
		let query = """
		query TestQuery {
			... on Query {
				someField
			}
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let traverser = GraphQLTraverser(document: document, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["__typename", "__typename", "someField"], "Inline fragment in query should have __typename injected at both levels")
	}

	func testFragmentOnSubscriptionTypeDoesNotGetTypename() throws {
		let query = """
		fragment SubFields on Subscription {
			someField
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let config = GraphQLTraverser.Config(subscriptionTypeName: "Subscription")
		let traverser = GraphQLTraverser(document: document, config: config, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["someField"], "Fragment on subscription type should not have __typename injected")
	}

	func testFragmentOnNonSubscriptionTypeGetsTypename() throws {
		let query = """
		fragment QueryFields on Query {
			someField
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let config = GraphQLTraverser.Config(subscriptionTypeName: "Subscription")
		let traverser = GraphQLTraverser(document: document, config: config, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["__typename", "someField"], "Fragment on non-subscription type should still have __typename injected")
	}

	func testFragmentWithoutSubscriptionTypeNameConfigGetsTypename() throws {
		let query = """
		fragment SubFields on Subscription {
			someField
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let traverser = GraphQLTraverser(document: document, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["__typename", "someField"], "Without subscriptionTypeName config, fragment on Subscription should still get __typename")
	}

	func testSubscriptionWithBothInlineFragmentAndFragmentSpreadDoesNotGetTypename() throws {
		let query = """
		fragment SubFields on Subscription {
			fieldFromFragment
		}

		subscription TestSub {
			... on Subscription {
				fieldFromInline
			}
			...SubFields
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let config = GraphQLTraverser.Config(subscriptionTypeName: "Subscription")
		let traverser = GraphQLTraverser(document: document, config: config, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["fieldFromFragment", "fieldFromInline"], "Neither fragment definitions nor inline fragments at subscription root should have __typename injected")
	}

	func testPrependTypenameDisabledSkipsInjection() throws {
		let query = """
		query TestQuery {
			someField
		}
		"""
		let document = try parse(query)
		let visitor = FieldRecordingVisitor()
		let config = GraphQLTraverser.Config(prependTypename: false)
		let traverser = GraphQLTraverser(document: document, config: config, with: visitor)
		try traverser.traverse()

		XCTAssertEqual(visitor.visitedFields, ["someField"], "With prependTypename disabled, no __typename should be injected")
	}
}

private class FieldRecordingVisitor: GraphQLBaseVisitor {
	var visitedFields: [String] = []

	override func visitField(field: Field) throws {
		visitedFields.append(field.name)
	}
}
