// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class DocumentsQuery: GraphQLQuery {
  public static let operationName: String = "Documents"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query Documents { resourceQuery: resources { __typename ...Resource } }"#,
      fragments: [Resource.self]
    ))

  public init() {}

  public struct Data: ResourcesGraphQL.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { ResourcesGraphQL.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("resources", alias: "resourceQuery", [ResourceQuery].self),
    ] }

    /// An array relationship
    public var resourceQuery: [ResourceQuery] { __data["resourceQuery"] }

    /// ResourceQuery
    ///
    /// Parent Type: `Resources`
    public struct ResourceQuery: ResourcesGraphQL.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { ResourcesGraphQL.Objects.Resources }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(Resource.self),
      ] }

      public var id: ResourcesGraphQL.Uuid { __data["id"] }
      public var updated_at: ResourcesGraphQL.Timestamptz { __data["updated_at"] }
      public var created_at: ResourcesGraphQL.Timestamptz { __data["created_at"] }
      public var documentName: String { __data["documentName"] }
      public var documentNumber: String { __data["documentNumber"] }
      public var s3_key: String { __data["s3_key"] }
      public var thumbnail_s3_key: String { __data["thumbnail_s3_key"] }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var resource: Resource { _toFragment() }
      }
    }
  }
}
